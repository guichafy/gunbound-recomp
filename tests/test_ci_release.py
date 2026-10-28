"""Versioning uses real histories, including merges and release retries."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

PATH = Path(__file__).resolve().parents[1] / 'scripts/ci/release.py'


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(PATH.exists(), 'release versioner is not implemented')
        spec = importlib.util.spec_from_file_location('ci_release', PATH)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def test_conventional_bumps(self):
        for messages, expected in [(['fix: a'], '0.20.6'), (['feat(ui): a', 'fix: b'], '0.21.0'),
                                   (['docs: a'], '0.20.6'), (['feat!: a'], '1.0.0'),
                                   (['chore: a\n\nBREAKING CHANGE: old saves removed'], '1.0.0')]:
            self.assertEqual(self.module.next_version('0.20.5', messages), expected)

    def test_rejects_invalid_commit(self):
        with self.assertRaises(ValueError):
            self.module.next_version('0.20.5', ['miscellaneous change'])

    def test_real_history_bootstrap_tag_and_retry(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            def git(*args):
                return subprocess.check_output(['git', '-C', temp, *args], text=True).strip()
            git('init', '-q')
            git('config', 'user.name', 'CI Test')
            git('config', 'user.email', 'test@example.invalid')
            git('commit', '--allow-empty', '-qm', 'legacy history')
            baseline = git('rev-parse', 'HEAD')
            git('tag', 'v0.9.0')
            git('commit', '--allow-empty', '-qm', 'feat: windows')
            config = {'baseline_sha': baseline, 'baseline_version': '0.20.5'}
            self.assertEqual(self.module.plan(root, config)['version'], '0.21.0')
            git('tag', 'v0.21.0')
            self.assertEqual(self.module.plan(root, config)['version'], '0.21.0')
            git('commit', '--allow-empty', '-qm', 'fix: path')
            self.assertEqual(self.module.plan(root, config)['version'], '0.21.1')
            self.assertEqual(self.module.plan(root, config, pr_title='feat: windows')['version'], '0.21.1')
            git('tag', 'v0.21.1')
            self.assertEqual(self.module.plan(root, config)['version'], '0.21.1')
            git('commit', '--allow-empty', '-qm', 'work in progress')
            with self.assertRaisesRegex(ValueError, 'Expected Conventional Commit: work in progress'):
                self.module.plan(root, config, pr_title='feat: windows')

    def test_divergent_baseline_fails_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            subprocess.run(['git', 'init', '-q', temp], check=True)
            subprocess.run(['git', '-C', temp, '-c', 'user.name=CI', '-c', 'user.email=ci@example.invalid', 'commit', '--allow-empty', '-qm', 'baseline'], check=True)
            with self.assertRaises((ValueError, subprocess.CalledProcessError)):
                self.module.plan(Path(temp), {'baseline_sha': '0' * 40, 'baseline_version': '0.20.5'})

    def test_version_applies_only_application(self):
        with tempfile.TemporaryDirectory() as temp:
            project = Path(temp) / 'project.godot'
            project.write_text('[application]\nconfig/version="0.20.5"\n[other]\nconfig/version="x"\n')
            self.module.apply_version(project, '1.2.3')
            self.assertEqual(project.read_text(), '[application]\nconfig/version="1.2.3"\n[other]\nconfig/version="x"\n')


if __name__ == '__main__':
    unittest.main()
