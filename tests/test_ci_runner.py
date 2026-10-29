import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

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

    def test_commands_report_time_and_match_count(self):
        with tempfile.TemporaryDirectory() as temp:
            result = self.module.run_logged([sys.executable, '-c', 'print("COMPLETE MATCHES: 4 | FAILURES: 0")'], Path(temp)/'log', 5, True)
            self.assertGreater(result.get('seconds', 0), 0)
            self.assertEqual(result.get('matches'), 4)

    def test_parallel_tasks_overlap_and_keep_every_failure(self):
        # A serial runner cannot cross this barrier. No timing threshold or sleep.
        barrier = threading.Barrier(2, timeout=5)
        def task(name, ok):
            def execute():
                barrier.wait()
                return {name: {'ok': ok}}
            return execute
        self.assertTrue(hasattr(self.module, 'run_parallel'), 'bounded parallel runner missing')
        results = self.module.run_parallel({'a': task('first', True), 'b': task('second', False)}, 2)
        self.assertEqual(results, {'first': {'ok': True}, 'second': {'ok': False}})

    def test_worker_exception_does_not_drop_other_results(self):
        self.assertTrue(hasattr(self.module, 'run_parallel'), 'bounded parallel runner missing')
        def broken():
            raise RuntimeError('broken worker')
        results = self.module.run_parallel({'broken': broken, 'other': lambda: {'other': {'ok': True}}}, 1)
        self.assertFalse(results['broken']['ok'])
        self.assertIn('broken worker', results['broken']['error'])
        self.assertTrue(results['other']['ok'])

    def test_match_inventory_rejects_missing_duplicate_or_wrong_cases(self):
        self.assertTrue(hasattr(self.module, 'validate_matches'), 'match inventory gate missing')
        with tempfile.TemporaryDirectory() as temp:
            log = Path(temp)/'log'
            for output, ok in [('MATCH seed=81\nMATCH seed=83\nCOMPLETE MATCHES: 2 | FAILURES: 0', True),
                               ('MATCH seed=81\nCOMPLETE MATCHES: 2 | FAILURES: 0', False),
                               ('MATCH seed=81\nMATCH seed=81\nCOMPLETE MATCHES: 2 | FAILURES: 0', False),
                               ('MATCH seed=81\nMATCH seed=82\nCOMPLETE MATCHES: 2 | FAILURES: 0', False)]:
                log.write_text(output)
                result = {'ok': True, 'matches': 2}
                self.module.validate_matches(result, log, 'test_matches', [81, 83])
                self.assertEqual(result['ok'], ok, output)

    def test_python_timing_records_success_failure_and_skip(self):
        self.assertTrue(hasattr(self.module, 'TimedResult'), 'per-test timings missing')
        class Cases(unittest.TestCase):
            def test_success(self):
                pass
            def test_failure(self):
                self.fail('deliberate')
            @unittest.skip('deliberate')
            def test_skip(self):
                pass
        result = unittest.TextTestRunner(stream=io.StringIO(), resultclass=self.module.TimedResult).run(unittest.defaultTestLoader.loadTestsFromTestCase(Cases))
        self.assertEqual(len(result.timings), 3)
        self.assertTrue(all(row['seconds'] >= 0 for row in result.timings))
        self.assertEqual(len(result.failures), 1)
        self.assertEqual(len(result.skipped), 1)

    def test_full_runner_keeps_29_matches_coverage_and_failing_scene(self):
        # Only replace the external engine: execute real processes and coverage.
        # A missing lane, wrong shard argument, swallowed failure or stale
        # coverage must change the final status/report observed by a caller.
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root/'scripts/ci').mkdir(parents=True)
            (root/'tests').mkdir()
            (root/'scripts/check.sh').write_text('ALL="test_scene test_matches test_classic_matches"\n')
            for name in ['test_scene', 'test_matches', 'test_classic_matches']:
                (root/f'tests/{name}.gd').touch()
            fixture = root/'engine.py'
            fixture.write_text('''import sys
from pathlib import Path
args = sys.argv[1:]
if '--script' in args and '--check-only' not in args:
    name = Path(args[args.index('--script') + 1]).stem
    if name == 'test_scene':
        print('CHECKS: 7 | FAILURES: 0')
        raise SystemExit(3)
    index, count = map(int, args[-1].split('=')[1].split('/'))
    cases = list(range(81, 94)) if name == 'test_matches' else list(range(1, 17))
    for case in cases[index::count]:
        print(('MATCH seed=' if name == 'test_matches' else 'CLASSIC MATCH id=') + str(case))
    print(('COMPLETE' if name == 'test_matches' else 'CLASSIC') + ' MATCHES: ' + str(len(cases[index::count])) + ' | FAILURES: 0')
''')
            python = root/'scripts/ci/check.py'
            python.write_text('''import sys
from pathlib import Path
Path(sys.argv[-1]).write_text('[]')
print('Ran 1 test')
print('OK')
''')
            real_run = subprocess.run
            def engine_command(command, **kwargs):
                if '--headless' in command:
                    command = [sys.executable, str(fixture), *command[1:]]
                return real_run(command, **kwargs)
            with patch.object(self.module, 'ROOT', root), patch.object(self.module, '__file__', str(python)), \
                 patch.object(sys, 'argv', ['check.py', '--godot', sys.executable, '--workers', '2']), \
                 patch.object(self.module.subprocess, 'run', engine_command), redirect_stdout(io.StringIO()), \
                 self.assertRaises(SystemExit) as exit_status:
                self.module.main()
            self.assertEqual(exit_status.exception.code, 1)
            report = json.loads((root/'.tools/check-logs/report.json').read_text())
            self.assertEqual(report['matches'], 29)
            self.assertFalse(report['results']['test_scene']['ok'])
            self.assertTrue(report['results']['python']['ok'])
            self.assertTrue(report['results']['automation_coverage']['ok'])
            self.assertTrue((root/'.tools/coverage.xml').is_file())
            self.assertTrue((root/'.tools/coverage-html/index.html').is_file())


if __name__ == '__main__':
    unittest.main()
