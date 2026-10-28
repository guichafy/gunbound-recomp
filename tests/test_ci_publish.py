import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import hashlib

PATH = Path(__file__).resolve().parents[1] / 'scripts/ci/publish.py'


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(PATH.exists(), 'publisher missing')
        spec = importlib.util.spec_from_file_location('ci_publish', PATH)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

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
