import unittest
from pathlib import Path
import yaml

ROOT=Path(__file__).resolve().parents[1]


class AndroidWorkflowTests(unittest.TestCase):
    def test_android_is_additive_and_publication_waits_for_separate_acceptance(self):
        data=yaml.safe_load((ROOT/'.github/workflows/desktop.yml').read_text());jobs=data['jobs']
        self.assertIn('android',jobs,'Android candidate/sign/smoke job missing')
        self.assertEqual(jobs['android']['permissions'],{'contents':'read'})
        self.assertEqual(jobs['android']['needs'],['lint','version'])
        self.assertEqual(jobs['android-acceptance']['environment'],'android-device-acceptance')
        self.assertIn('android',jobs['release']['needs'])
        self.assertIn('android-acceptance',jobs['release']['needs'])
        for step in jobs['android']['steps']:
            if any('secrets.' in str(value) for value in step.get('env',{}).values()):
                self.assertIn("github.event_name == 'push'",step.get('if',''))
                self.assertIn("refs/heads/main",step.get('if',''))
        self.assertEqual(data['concurrency']['queue'],'max')
        self.assertFalse(data['concurrency']['cancel-in-progress'])
