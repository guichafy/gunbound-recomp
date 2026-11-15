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
        spec = importlib.util.spec_from_file_location('ci_publish', PATH)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def packages(self, root):
        for platform, label, extension in [('macos','macOS','.zip'),('windows','Windows-x86_64','.zip')]:
            archive = root / f'Gunbound-Recomp-1.2.3-{label}{extension}'
            payload = (platform + ' package').encode()
            archive.write_bytes(payload)
            digest = hashlib.sha256(payload).hexdigest()
            archive.with_suffix('.json').write_text(json.dumps({
                'version':'1.2.3','commit':'a'*40,'platform':platform,'file':archive.name,
                'sha256':digest,'size':len(payload),'smoke':'passed'}))
            archive.with_suffix(extension+'.sha256').write_bytes(f'{digest}  {archive.name}\r\n'.encode())

    def complete_packages(self, root):
        self.packages(root)
        archive=root/'Gunbound-Recomp-1.2.3-Android.apk'
        archive.write_bytes(b'android package')
        digest=hashlib.sha256(archive.read_bytes()).hexdigest()
        data=dict(schema=2,godot='4.7.2',version='1.2.3',commit='a'*40,platform='android',file=archive.name,
                  sha256=digest,size=archive.stat().st_size,smoke='passed',abis=['arm64-v8a','x86_64'],
                  package_id='com.chafy.gunboundrecomp',version_code=1002003,min_sdk=24,target_sdk=36,
                  certificate_sha256='e'*64,arm64_acceptance='manual_gate_required',diagnostic='passed',final_x86_64='passed')
        archive.with_suffix('.json').write_text(json.dumps(data))
        archive.with_suffix('.apk.sha256').write_text(f'{digest}  {archive.name}\n')
        return data

    def accepted(self, api, manifest):
        import sys
        sys.path.insert(0,str(PATH.parent))
        from android_acceptance import validate_reviews
        payload=dict(run_id=123,commit='a'*40,apk_sha256=manifest['sha256'],version='1.2.3',device='Lab device',api=36,abi='arm64-v8a',gpu='Mali',evidence_url='https://example.org/qa',results={k:'passed' for k in ('install','solo','jewel','touch','lifecycle','audio','update')})
        review=dict(state='approved',environments=[dict(name='android-device-acceptance')],user=dict(login='trusted',id=42),comment='ANDROID_ACCEPTANCE_V1\n'+json.dumps(payload))
        original=api.request
        def request(method,path,data=None,binary=False):
            if method=='GET' and path=='/actions/runs/123':
                return dict(event='push',head_branch='main',head_sha='a'*40)
            if method=='GET' and path=='/actions/runs/123/approvals':
                return [review]
            return original(method,path,data,binary)
        api.request=request
        return validate_reviews([review],manifest,123,{'trusted'})

    def test_new_publication_is_atomic_three_packages_and_checksums(self):
        api=ReleaseAPI()
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);manifest=self.complete_packages(root)
            acceptance=self.accepted(api,manifest)
            before={p.name:p.read_bytes() for p in root.iterdir()}
            self.module.publish(api,root,'1.2.3','a'*40,acceptance,123,{'trusted'})
            self.assertFalse(api.release['draft'])
            self.assertEqual(set(api.uploads),{'Gunbound-Recomp-1.2.3-macOS.zip','Gunbound-Recomp-1.2.3-Windows-x86_64.zip','Gunbound-Recomp-1.2.3-Android.apk','SHA256SUMS'})
            self.assertIn('ARM64 QA: trusted',api.release['body'])
            self.assertEqual(len(api.uploads['SHA256SUMS'].splitlines()),3)
            self.assertEqual({p.name:p.read_bytes() for p in root.iterdir()},before)
            writes=list(api.writes)
            self.module.publish(api,Path('/nonexistent'),'1.2.3','a'*40)
            self.assertEqual(api.writes,writes)

    def test_failed_upload_stays_draft_and_retry_reuses_tag(self):
        api=ReleaseAPI(fail_upload='SHA256SUMS')
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);manifest=self.complete_packages(root);acceptance=self.accepted(api,manifest)
            with self.assertRaisesRegex(RuntimeError,'upload failed'):
                self.module.publish(api,root,'1.2.3','a'*40,acceptance,123,{'trusted'})
            self.assertTrue(api.release['draft'])
            self.assertNotIn(('PATCH','/releases/1'),api.writes)
            api.fail_upload=None
            api.release['body']='Prior draft notes\nARM64 QA: stale approval for other APK'
            self.module.publish(api,root,'1.2.3','a'*40,acceptance,123,{'trusted'})
            self.assertFalse(api.release['draft'])
            self.assertIn('ARM64 QA: trusted',api.release['body'])
            self.assertNotIn('stale approval',api.release['body'])
            self.assertEqual(api.writes.count(('POST','/releases')),1)
            self.assertEqual(api.writes.count(('POST','/git/refs')),1)

    def test_tampered_package_or_acceptance_blocks_all_writes(self):
        for tamper in ('apk','acceptance'):
            with self.subTest(tamper=tamper),tempfile.TemporaryDirectory() as temp:
                api=ReleaseAPI();root=Path(temp);manifest=self.complete_packages(root);acceptance=self.accepted(api,manifest)
                if tamper=='apk':
                    (root/manifest['file']).write_bytes(b'changed')
                else:
                    acceptance['apk_sha256']='f'*64
                with self.assertRaises(ValueError):
                    self.module.publish(api,root,'1.2.3','a'*40,acceptance,123,{'trusted'})
                self.assertFalse(api.writes)

    def test_legacy_six_assets_are_readonly_without_local_packages(self):
        api=ReleaseAPI();api.ref={'object':{'type':'commit','sha':'a'*40}}
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);self.packages(root)
            api.release=dict(id=1,draft=False,tag_name='v1.2.3',target_commitish='a'*40,html_url='https://example.org',assets=[dict(id=i,name=p.name) for i,p in enumerate(root.iterdir())])
            self.module.publish(api,Path('/nonexistent'),'1.2.3','a'*40)
            self.assertFalse(api.writes)
            api.release['assets'].pop()
            with self.assertRaisesRegex(ValueError,'Published release is incomplete'):
                self.module.publish(api,root,'1.2.3','a'*40)
            self.assertFalse(api.writes)

    def test_wrong_existing_tag_cannot_be_repaired(self):
        api=ReleaseAPI();api.ref={'object':{'type':'commit','sha':'b'*40}}
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaises(ValueError):
                self.module.publish(api,Path(temp),'1.2.3','a'*40)
        self.assertFalse(api.writes)

    def test_nine_inputs_validate_hash_version_commit_and_smoke(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);manifest=self.complete_packages(root)
            self.assertEqual(len(self.module.validate_assets(root,'1.2.3','a'*40)),9)
            for field in ('version','commit','smoke'):
                data=dict(manifest,**{field:'wrong'})
                (root/'Gunbound-Recomp-1.2.3-Android.json').write_text(json.dumps(data))
                with self.assertRaises(ValueError):
                    self.module.validate_assets(root,'1.2.3','a'*40)

    def test_existing_draft_without_tag_reuses_release_after_full_validation(self):
        api=ReleaseAPI()
        api.release=dict(id=1,draft=True,tag_name='v1.2.3',target_commitish='a'*40,
                         assets=[],html_url='https://example.org',upload_url='https://uploads.github.com/release{?name}')
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);manifest=self.complete_packages(root);acceptance=self.accepted(api,manifest)
            self.module.publish(api,root,'1.2.3','a'*40,acceptance,123,{'trusted'})
            self.assertFalse(api.release['draft'])
            self.assertNotIn(('POST','/releases'),api.writes)
            self.assertEqual(api.writes.count(('POST','/git/refs')),1)

    def test_published_release_without_tag_is_never_repaired(self):
        api=ReleaseAPI();api.release=dict(id=1,draft=False,tag_name='v1.2.3',assets=[])
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(ValueError,'Published release has no valid tag'):
                self.module.publish(api,Path(temp),'1.2.3','a'*40)
        self.assertFalse(api.writes)

    def test_desktop_only_draft_cannot_choose_historical_contract(self):
        api=ReleaseAPI();api.release=dict(id=1,draft=True,tag_name='v1.2.3',target_commitish='a'*40,assets=[])
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);self.packages(root)
            with self.assertRaisesRegex(ValueError,'android'):
                self.module.publish(api,root,'1.2.3','a'*40)
        self.assertFalse(api.writes)

    def test_wrong_android_godot_version_blocks_publication(self):
        api=ReleaseAPI()
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);manifest=self.complete_packages(root)
            manifest['godot']='4.7.1'
            (root/'Gunbound-Recomp-1.2.3-Android.json').write_text(json.dumps(manifest))
            with self.assertRaisesRegex(ValueError,'Android manifest'):
                self.module.validate_assets(root,'1.2.3','a'*40)
            self.assertFalse(api.writes)


if __name__ == '__main__':
    unittest.main()
