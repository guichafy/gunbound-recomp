import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import test_ci_publish as desktop_tests
ReleaseAPI = desktop_tests.ReleaseAPI

PATH=Path(__file__).resolve().parents[1]/'scripts/ci/publish.py'


class AndroidPublishTests(unittest.TestCase):
    def setUp(self):
        spec=importlib.util.spec_from_file_location('android_publisher_test',PATH)
        self.m=importlib.util.module_from_spec(spec);spec.loader.exec_module(self.m)

    def test_missing_android_cannot_create_new_release_or_tag(self):
        api=ReleaseAPI()
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);desktop_tests.PublishTests.packages(self,root)
            with self.assertRaisesRegex(ValueError,'android'):
                self.m.publish(api,root,'1.2.3','a'*40)
            self.assertFalse(api.writes)

    def test_already_published_historical_release_needs_no_local_packages(self):
        api=ReleaseAPI();api.ref={'object':{'type':'commit','sha':'a'*40}}
        api.release=dict(id=1,draft=False,tag_name='v1.2.3',target_commitish='a'*40,html_url='https://example.org',assets=[dict(name=n) for n in ['Gunbound-Recomp-1.2.3-macOS.zip','Gunbound-Recomp-1.2.3-Windows-x86_64.zip','SHA256SUMS']])
        with tempfile.TemporaryDirectory() as temp:
            self.m.publish(api,Path(temp),'1.2.3','a'*40)
        self.assertFalse(api.writes)

    def test_android_manifest_and_acceptance_are_both_required(self):
        api=ReleaseAPI()
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);desktop_tests.PublishTests.packages(self,root)
            apk=root/'Gunbound-Recomp-1.2.3-Android.apk';apk.write_bytes(b'apk')
            digest=hashlib.sha256(b'apk').hexdigest()
            apk.with_suffix('.json').write_text(json.dumps(dict(schema=2,godot='4.7.2',version='1.2.3',commit='a'*40,platform='android',file=apk.name,size=3,sha256=digest,smoke='passed',abis=['arm64-v8a','x86_64'],package_id='com.chafy.gunboundrecomp',version_code=1002003,min_sdk=24,target_sdk=36,certificate_sha256='e'*64,arm64_acceptance='manual_gate_required',diagnostic='passed',final_x86_64='passed')))
            apk.with_suffix('.apk.sha256').write_text(f'{digest}  {apk.name}\n')
            self.assertEqual(len(self.m.validate_assets(root,'1.2.3','a'*40)),9)
            with self.assertRaisesRegex(ValueError,'acceptance'):
                self.m.publish(api,root,'1.2.3','a'*40)
            self.assertFalse(api.writes)
