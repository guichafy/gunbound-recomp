"""Security and publication gates missing from older actionlint schema."""
from pathlib import Path
import re
import unittest
import yaml

ROOT = Path(__file__).resolve().parents[1]


class WorkflowTests(unittest.TestCase):
    def test_gates_and_queue(self):
        data = yaml.safe_load((ROOT / '.github/workflows/desktop.yml').read_text())
        self.assertIn('edited', data.get('on', data.get(True))['pull_request']['types'])
        self.assertEqual(data['concurrency']['queue'], 'max')
        self.assertFalse(data['concurrency']['cancel-in-progress'])
        self.assertEqual(data['permissions'], {'contents': 'read'})
        jobs = data['jobs']
        self.assertEqual(jobs['release']['permissions'], {'contents': 'write'})
        self.assertEqual(jobs['release']['needs'], ['version', 'desktop'])
        self.assertIn("github.event_name == 'push'", jobs['release']['if'])
        self.assertEqual({x['platform'] for x in jobs['desktop']['strategy']['matrix']['include']}, {'macos','windows'})
        for job in jobs.values():
            for step in job['steps']:
                if 'uses' in step:
                    self.assertRegex(step['uses'], r'^[\w/-]+@[0-9a-f]{40}$')
                    if step['uses'].startswith('actions/checkout@'):
                        self.assertFalse(step['with']['persist-credentials'])
        self.assertNotIn('pull_request_target', (ROOT / '.github/workflows/desktop.yml').read_text())


if __name__ == '__main__':
    unittest.main()
