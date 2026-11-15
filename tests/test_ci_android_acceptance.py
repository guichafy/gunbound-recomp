import importlib.util
from pathlib import Path
import unittest
import json

PATH = Path(__file__).resolve().parents[1] / 'scripts/ci/android_acceptance.py'


class AndroidAcceptanceTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(PATH.is_file(), 'trusted-review acceptance missing')
        spec=importlib.util.spec_from_file_location('android_acceptance_test',PATH)
        self.m=importlib.util.module_from_spec(spec);spec.loader.exec_module(self.m)
        self.manifest=dict(version='1.2.3',commit='a'*40,sha256='b'*64,arm64_acceptance='manual_gate_required')
        self.payload=dict(run_id=123,commit='a'*40,apk_sha256='b'*64,version='1.2.3',device='Lab Pixel',api=36,abi='arm64-v8a',gpu='Mali',evidence_url='https://example.org/qa/123',results={k:'passed' for k in ('install','solo','jewel','touch','lifecycle','audio','update')})
        self.review=dict(state='approved',environments=[dict(name='android-device-acceptance')],user=dict(login='trusted',id=42),comment='ANDROID_ACCEPTANCE_V1\n'+json.dumps(self.payload))

    def test_acceptance_is_bound_to_run_commit_apk_and_trusted_reviewer(self):
        result=self.m.validate_reviews([self.review],self.manifest,123,{'trusted'})
        self.assertEqual(result['apk_sha256'],'b'*64)
        self.assertEqual(result['reviewer'],'trusted')
        for key,value in [('run_id',124),('commit','c'*40),('apk_sha256','d'*64),('abi','x86_64')]:
            bad=dict(self.payload,**{key:value})
            review=dict(self.review,comment='ANDROID_ACCEPTANCE_V1\n'+json.dumps(bad))
            with self.subTest(key=key),self.assertRaises(ValueError):
                self.m.validate_reviews([review],self.manifest,123,{'trusted'})

    def test_missing_untrusted_rejected_or_wrong_environment_cannot_approve(self):
        for reviews,trusted in [([],{'trusted'}),([self.review],{'other'}),([dict(self.review,state='rejected')],{'trusted'}),([dict(self.review,environments=[dict(name='other')])],{'trusted'})]:
            with self.subTest(reviews=reviews),self.assertRaises(ValueError):
                self.m.validate_reviews(reviews,self.manifest,123,trusted)
