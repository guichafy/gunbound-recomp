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
        self.assertEqual(data['concurrency']['group'], "${{ github.event_name == 'push' && 'desktop-main-releases' || format('desktop-pr-run-{0}', github.run_id) }}")
        self.assertEqual(data['permissions'], {'contents': 'read'})
        jobs = data['jobs']
        for name in ('lint', 'version', 'desktop'):
            policy = jobs[name]['concurrency']
            self.assertEqual(policy['cancel-in-progress'], "${{ github.event_name == 'pull_request' }}")
            self.assertNotIn('queue', policy)  # single is the default; queue requires a literal.
            suffix = ', matrix.platform' if name == 'desktop' else ''
            group = 'desktop-{0}-desktop-{1}' if name == 'desktop' else 'desktop-{0}-' + name
            self.assertEqual(policy['group'], "${{ format('" + group + "', github.event_name == 'pull_request' && github.event.pull_request.number || github.run_id" + suffix + ") }}")
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

    def test_required_checks_and_full_test_command_preserved(self):
        data = yaml.safe_load((ROOT / '.github/workflows/desktop.yml').read_text())
        jobs = data['jobs']
        self.assertEqual(jobs['lint']['name'], 'Lint and automation tests')
        self.assertEqual(jobs['version']['name'], 'Calculate release version')
        self.assertEqual(jobs['desktop']['name'], 'Test, build and smoke (${{ matrix.platform }})')
        self.assertIn('python scripts/ci/check.py', [step.get('run') for step in jobs['desktop']['steps']])


if __name__ == '__main__':
    unittest.main()
