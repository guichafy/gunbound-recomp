import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import hashlib
import urllib.parse
import copy

PATH = Path(__file__).resolve().parents[1] / 'scripts/ci/publish.py'


class ReleaseAPI:
    """In-memory GitHub boundary; package validation and publication stay real."""
    def __init__(self, fail_upload=None):
        self.ref = None
        self.release = None
        self.uploads = {}
        self.writes = []
        self.fail_upload = fail_upload

    def request(self, method, path, data=None, binary=False):
        if method != 'GET':
            self.writes.append((method, path))
        if method == 'GET':
            if path.startswith('/git/ref/'):
                return self.ref
            if path.startswith('/releases/tags/'):
                return copy.deepcopy(self.release) if self.release and not self.release['draft'] else None
            if path.startswith('/releases?'):
                return [copy.deepcopy(self.release)] if self.release else []
            if path == '/releases/1':
                return copy.deepcopy(self.release)
        elif method == 'POST' and path == '/git/refs':
            self.ref = {'object': {'type': 'commit', 'sha': data['sha']}}
            return self.ref
        elif method == 'POST' and path == '/releases':
            self.release = dict(data, id=1, assets=[], html_url='https://github.com/example/release',
                                upload_url='https://uploads.github.com/release{?name}')
            return copy.deepcopy(self.release)
        elif method == 'POST' and path.startswith('https://uploads.github.com/'):
            name = urllib.parse.parse_qs(urllib.parse.urlsplit(path).query)['name'][0]
            if name == self.fail_upload:
                raise RuntimeError('upload failed')
            if not binary or not isinstance(data, bytes):
                raise AssertionError('upload must contain file bytes')
            self.uploads[name] = data
            self.release['assets'].append({'id': len(self.writes), 'name': name})
            return self.release['assets'][-1]
        elif method == 'DELETE' and path.startswith('/releases/assets/'):
            asset_id = int(path.rsplit('/', 1)[1])
            asset = next(a for a in self.release['assets'] if a['id'] == asset_id)
            self.uploads.pop(asset['name'], None)
            self.release['assets'].remove(asset)
            return None
        elif method == 'PATCH' and path == '/releases/1':
            self.release.update(data)
            return self.release
        raise AssertionError(f'Unexpected API request: {method} {path}')


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(PATH.exists(), 'publisher missing')
        spec = importlib.util.spec_from_file_location('ci_publish', PATH)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def packages(self, root):
        for platform, label in [('macos', 'macOS'), ('windows', 'Windows-x86_64')]:
            archive = root / f'Gunbound-Recomp-1.2.3-{label}.zip'
            payload = (platform + ' package').encode()
            archive.write_bytes(payload)
            digest = hashlib.sha256(payload).hexdigest()
            archive.with_suffix('.json').write_text(json.dumps({
                'version': '1.2.3', 'commit': 'a'*40, 'platform': platform,
                'file': archive.name, 'sha256': digest, 'size': len(payload), 'smoke': 'passed'}))
            # Exercise input produced by Windows as well as native LF input.
            archive.with_suffix('.zip.sha256').write_bytes(f'{digest}  {archive.name}\r\n'.encode())

    def test_public_release_has_two_zips_and_one_checksum_file(self):
        api = ReleaseAPI()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.packages(root)
            inputs = {p.name: p.read_bytes() for p in root.iterdir()}
            self.module.publish(api, root, '1.2.3', 'a'*40)
            self.assertFalse(api.release['draft'])
            self.assertEqual(set(api.uploads), {
                'Gunbound-Recomp-1.2.3-macOS.zip',
                'Gunbound-Recomp-1.2.3-Windows-x86_64.zip', 'SHA256SUMS'})
            self.assertEqual(api.uploads['SHA256SUMS'], (
                f'{hashlib.sha256(b"macos package").hexdigest()}  Gunbound-Recomp-1.2.3-macOS.zip\n'
                f'{hashlib.sha256(b"windows package").hexdigest()}  Gunbound-Recomp-1.2.3-Windows-x86_64.zip\n').encode())
            self.assertEqual({p.name: p.read_bytes() for p in root.iterdir()}, inputs)
            # A second invocation must be safe without cleaning generated files.
            writes = list(api.writes)
            self.module.publish(api, root, '1.2.3', 'a'*40)
            self.assertEqual(api.writes, writes)

    def test_failed_checksum_upload_stays_draft_and_retry_preserves_release(self):
        api = ReleaseAPI(fail_upload='SHA256SUMS')
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.packages(root)
            with self.assertRaisesRegex(RuntimeError, 'upload failed'):
                self.module.publish(api, root, '1.2.3', 'a'*40)
            self.assertTrue(api.release['draft'])
            self.assertNotIn(('PATCH', '/releases/1'), api.writes)
            self.assertIsNotNone(api.ref)
            api.fail_upload = None
            self.module.publish(api, root, '1.2.3', 'a'*40)
            self.assertFalse(api.release['draft'])
            self.assertEqual(api.writes.count(('POST', '/releases')), 1)
            self.assertEqual(api.writes.count(('POST', '/git/refs')), 1)
            self.assertEqual({a['name'] for a in api.release['assets']}, set(api.uploads))
            self.assertEqual(len(api.release['assets']), 3)

    def test_tampered_manifest_blocks_all_remote_writes(self):
        api = ReleaseAPI()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.packages(root)
            manifest = root / 'Gunbound-Recomp-1.2.3-Windows-x86_64.json'
            data = json.loads(manifest.read_text())
            data['smoke'] = 'failed'
            manifest.write_text(json.dumps(data))
            with self.assertRaises(ValueError):
                self.module.publish(api, root, '1.2.3', 'a'*40)
            self.assertFalse(api.writes)

    def test_incomplete_public_release_is_not_repaired(self):
        api = ReleaseAPI()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.packages(root)
            self.module.publish(api, root, '1.2.3', 'a'*40)
            api.release['assets'] = [a for a in api.release['assets'] if a['name'] != 'SHA256SUMS']
            writes = list(api.writes)
            with self.assertRaisesRegex(ValueError, 'Published release is incomplete'):
                self.module.publish(api, root, '1.2.3', 'a'*40)
            self.assertEqual(api.writes, writes)

    def test_legacy_six_asset_release_keeps_its_original_files(self):
        api = ReleaseAPI()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.packages(root)
            api.ref = {'object': {'type': 'commit', 'sha': 'a'*40}}
            api.release = {'id': 1, 'draft': False, 'tag_name': 'v1.2.3',
                           'target_commitish': 'a'*40, 'html_url': 'https://github.com/example/release',
                           'assets': [{'id': i, 'name': p.name} for i,p in enumerate(root.iterdir())]}
            original = copy.deepcopy(api.release)
            self.module.publish(api, root, '1.2.3', 'a'*40)
            self.assertFalse(api.writes)
            self.assertEqual(api.release, original)

    def test_published_release_is_not_overwritten(self):
        from unittest.mock import patch
        paths = [Path('a.zip'), Path('b.zip')]
        calls = []
        class API:
            def request(self, method, path, data=None, binary=False):
                calls.append((method, path))
                if '/git/ref/' in path:
                    return {'object': {'type': 'commit', 'sha': 'a'*40}}
                return {'draft': False, 'assets': [{'name': p.name} for p in paths], 'html_url': 'release'}
        with patch.object(self.module, 'validate_assets', return_value=paths):
            self.module.publish(API(), Path('.'), '1.2.3', 'a'*40)
        self.assertTrue(all(method == 'GET' for method, _ in calls))

    def test_upload_failure_leaves_draft_unpublished(self):
        from unittest.mock import patch
        calls = []
        class API:
            def request(self, method, path, data=None, binary=False):
                calls.append((method, path, data))
                if method == 'GET':
                    return None
                if method == 'POST' and path == '/git/refs':
                    return {'object': {'type': 'commit', 'sha': 'a'*40}}
                if method == 'POST' and path == '/releases':
                    return {'id': 1, 'draft': True, 'assets': [], 'upload_url': 'https://uploads.github.com/r{?name}'}
                raise RuntimeError('upload failed')
        with tempfile.TemporaryDirectory() as temp:
            package = Path(temp)/'a.zip'
            package.write_bytes(b'package')
            with patch.object(self.module, 'validate_assets', return_value=[package]):
                with self.assertRaisesRegex(RuntimeError, 'upload failed'):
                    self.module.publish(API(), Path(temp), '1.2.3', 'a'*40)
        self.assertTrue(next(data['draft'] for method, path, data in calls if method == 'POST' and path == '/releases'))
        self.assertFalse(any(method == 'PATCH' for method, _, _ in calls))
        writes = [path for method, path, _ in calls if method == 'POST']
        self.assertEqual(writes[:2], ['/git/refs', '/releases'])

    def test_retry_resumes_draft_even_without_a_git_tag(self):
        from unittest.mock import patch
        calls = []
        class API:
            def request(self, method, path, data=None, binary=False):
                calls.append((method, path))
                if method == 'GET' and path.startswith('/releases?'):
                    return [{'id': 2, 'tag_name': 'v1.2.3', 'target_commitish': 'a'*40,
                             'draft': True, 'assets': [], 'upload_url': 'https://uploads.github.com/r{?name}'}]
                if method == 'GET':
                    return None
                if method == 'POST' and path == '/git/refs':
                    return {'object': {'type': 'commit', 'sha': 'a'*40}}
                if method == 'POST' and path.startswith('https://uploads.github.com/'):
                    raise RuntimeError('resuming upload')
                raise AssertionError('must not create another release')
        with tempfile.TemporaryDirectory() as temp:
            package = Path(temp)/'a.zip'
            package.write_bytes(b'package')
            with patch.object(self.module, 'validate_assets', return_value=[package]):
                with self.assertRaisesRegex(RuntimeError, 'resuming upload'):
                    self.module.publish(API(), Path(temp), '1.2.3', 'a'*40)
        self.assertNotIn(('POST', '/releases'), calls)

    def test_preexisting_tag_with_different_commit_blocks_creation(self):
        from unittest.mock import patch
        mutations = []
        class API:
            def request(self, method, path, data=None, binary=False):
                if method != 'GET':
                    mutations.append((method, path))
                if '/git/ref/' in path:
                    return {'object': {'type': 'commit', 'sha': 'b'*40}}
                return None
        with patch.object(self.module, 'validate_assets', return_value=[]):
            with self.assertRaises(ValueError):
                self.module.publish(API(), Path('.'), '1.2.3', 'a'*40)
        self.assertFalse(mutations)

    def test_requires_both_platforms(self):
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaises(ValueError):
                self.module.validate_assets(Path(temp), '1.2.3', 'a'*40)

    def test_checks_hash_version_commit_and_smoke(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for platform, suffix in [('macos', 'macOS'), ('windows', 'Windows-x86_64')]:
                archive = root / f'Gunbound-Recomp-1.2.3-{suffix}.zip'
                archive.write_bytes(b'package')
                digest = hashlib.sha256(b'package').hexdigest()
                archive.with_suffix('.json').write_text(json.dumps({'version':'1.2.3', 'commit':'a'*40, 'platform':platform, 'file':archive.name,'sha256':digest,'size':7,'smoke':'passed'}))
                archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n')
            self.assertEqual(len(self.module.validate_assets(root, '1.2.3', 'a'*40)), 6)
            archive.write_bytes(b'tampered')
            with self.assertRaises(ValueError):
                self.module.validate_assets(root, '1.2.3', 'a'*40)


if __name__ == '__main__':
    unittest.main()
