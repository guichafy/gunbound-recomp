import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

PATH = Path(__file__).resolve().parents[1] / 'scripts/ci/check.py'


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(PATH.exists(), 'portable runner missing')
        spec = importlib.util.spec_from_file_location('ci_check', PATH)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def test_success_requires_summary(self):
        for code, expected in [("print('CHECKS: 5 | FAILURES: 0')", True), ("print('nothing')", False),
                               ("print('CHECKS: 5'); print('SCRIPT ERROR: failed')", False),
                               ("print('CHECKS: 5'); raise SystemExit(2)", False)]:
            with tempfile.TemporaryDirectory() as temp:
                result = self.module.run_logged([sys.executable, '-c', code], Path(temp)/'log', 5, True)
                self.assertEqual(result['ok'], expected, code)

    def test_prepares_fixture_directories_without_creating_failure_targets(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.module.prepare_test_dirs(root)
            self.assertTrue((root / '.tools/lobby-rank').is_dir())
            self.assertTrue((root / '.tools/room-ui').is_dir())
            self.assertFalse((root / '.tools/missing-shop-directory').exists())

    def test_timeout_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            result = self.module.run_logged([sys.executable, '-c', 'import time; time.sleep(10)'], Path(temp)/'log', 0.05, False)
            self.assertFalse(result['ok'])
            self.assertIn('TIMEOUT', (Path(temp)/'log').read_text())

    def test_all_match_suites_preserved(self):
        suites = self.module.godot_suites()
        self.assertIn('test_matches', suites)
        self.assertIn('test_classic_matches', suites)
        self.assertIn('test_scene', suites)
        self.assertEqual(len(suites), len(set(suites)))


if __name__ == '__main__':
    unittest.main()
