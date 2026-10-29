#!/usr/bin/env python3
"""Portable equivalent of check.sh, with durable logs and explicit coverage scope."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
ERRORS = re.compile(r'SCRIPT ERROR|Parse Error|Failed to load script|^ERROR:|^FAIL:|FAILURES: [1-9]', re.M)
MATCH_CASES = {'test_matches': list(range(81, 94)), 'test_classic_matches': list(range(1, 17))}
# Suites that time real frames; they run alone once the parallel lanes finish.
ISOLATED_SUITES = ('test_performance',)


class TimedResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.timings = []

    def startTest(self, test):
        self.started = time.perf_counter()
        super().startTest(test)

    def stopTest(self, test):
        self.timings.append({'test': test.id(), 'seconds': round(time.perf_counter() - self.started, 6)})
        super().stopTest(test)


def suite_names():
    text = (ROOT / 'scripts/check.sh').read_text()
    names = []
    for line in text.splitlines():
        if line.startswith('ALL='):
            names += re.findall(r'\btest_\w+', line)
    return list(dict.fromkeys(names))


def godot_suites():
    return [name for name in suite_names() if (ROOT / f'tests/{name}.gd').exists() and not (ROOT / f'tests/{name}.py').exists()]


def run_logged(command, log, timeout, summary=False, cwd=None, env=None):
    started = time.perf_counter()
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open('w', encoding='utf-8') as output:
        try:
            result = subprocess.run(command, cwd=ROOT if cwd is None else cwd, env=env, stdout=output, stderr=subprocess.STDOUT, timeout=timeout, check=False)
            status = result.returncode
        except subprocess.TimeoutExpired:
            output.write('\nTIMEOUT\n')
            status = 124
    text = log.read_text(encoding='utf-8', errors='replace')
    has_summary = bool(re.search(r'CHECKS:|MATCHES:', text))
    ok = status == 0 and not ERRORS.search(text) and (not summary or has_summary)
    return {'ok': ok, 'exit': status, 'seconds': round(time.perf_counter() - started, 3),
            'matches': sum(map(int, re.findall(r'^(?:COMPLETE|CLASSIC) MATCHES:\s*(\d+)', text, re.M))),
            'log': str(log.relative_to(ROOT)) if log.is_relative_to(ROOT) else str(log),
            'checks': sum(map(int, re.findall(r'CHECKS:\s*(\d+)', text)))}


def run_parallel(tasks, workers):
    """Collect every result, even if one worker raises; never hide a failed lane."""
    results = {}
    with ThreadPoolExecutor(max_workers=workers) as pool:
        pending = {pool.submit(task): name for name, task in tasks.items()}
        for future in as_completed(pending):
            name = pending[future]
            try:
                results.update(future.result())
            except Exception as error:
                results[name] = {'ok': False, 'error': repr(error)}
                print('FAIL', name, error, flush=True)
    return results


def validate_matches(result, log, suite, expected):
    text = log.read_text(encoding='utf-8', errors='replace')
    pattern = r'^MATCH seed=(\d+)\b' if suite == 'test_matches' else r'^CLASSIC MATCH id=(\d+)\b'
    cases = list(map(int, re.findall(pattern, text, re.M)))
    result['cases'] = cases
    result['ok'] = result['ok'] and cases == expected and result['matches'] == len(expected)


def isolated_env(profile):
    # Keep each Godot process's user data separate, as in the original runner.
    return dict(os.environ, HOME=str(profile), APPDATA=str(profile),
                XDG_DATA_HOME=str(profile), XDG_CONFIG_HOME=str(profile))


def prepare_test_dirs(root):
    # Existing scene fixtures write directly to these paths. Never create the
    # deliberately missing directories used by rollback/failure-path tests.
    for name in ('lobby-rank', 'room-ui', 'room-contact', 'room-polish', 'room-reference',
                 'classic-buttons-hd', 'hud-layout', 'battle-menu', 'match-loading',
                 'result-port', 'turtle-fix', 'turtle-t2'):
        (root / '.tools' / name).mkdir(parents=True, exist_ok=True)


def python_tests(timings_path=None):
    names = [name for name in suite_names() if (ROOT / f'tests/{name}.py').exists()]
    names += [p.stem for p in sorted((ROOT / 'tests').glob('test_ci_*.py'))]
    loader = unittest.TestLoader()
    suite = unittest.TestSuite(loader.discover(str(ROOT / 'tests'), pattern=f'{name}.py') for name in names)
    result = unittest.TextTestRunner(verbosity=2, resultclass=TimedResult).run(suite)
    if timings_path:
        Path(timings_path).write_text(json.dumps(result.timings, indent=2) + '\n', encoding='utf-8')
    for row in sorted(result.timings, key=lambda row: row['seconds'], reverse=True)[:15]:
        print(f"PYTHON TIME {row['seconds']:.3f}s {row['test']}", flush=True)
    if result.skipped:
        print('SKIPPED:', [(str(test), reason) for test, reason in result.skipped])
    return 0 if result.wasSuccessful() and not result.skipped else 1


def python_lane(logs, profile):
    env = isolated_env(profile)
    # Never accept an earlier run's coverage or timings as this run's evidence.
    env['COVERAGE_FILE'] = str(logs / 'coverage-data')
    Path(env['COVERAGE_FILE']).unlink(missing_ok=True)
    timings = logs / 'python-times.json'
    timings.unlink(missing_ok=True)
    results = {'python': run_logged([sys.executable, '-m', 'coverage', 'run', '--branch', '--source=scripts',
                                    str(Path(__file__).resolve()), '--python-tests', '--python-timings', str(timings)],
                                   logs / 'python.log', 900, env=env)}
    print(('OK' if results['python']['ok'] else 'FAIL'), 'python', results['python']['seconds'], 's', flush=True)
    if not results['python']['ok']:
        print((logs / 'python.log').read_text(encoding='utf-8', errors='replace')[-12000:], flush=True)
    elif timings.is_file():
        for row in sorted(json.loads(timings.read_text(encoding='utf-8')), key=lambda row: row['seconds'], reverse=True)[:15]:
            print(f"PYTHON TIME {row['seconds']:.3f}s {row['test']}", flush=True)
    for mode, path in [('xml', '.tools/coverage.xml'), ('html', '.tools/coverage-html')]:
        results['coverage_' + mode] = run_logged([sys.executable, '-m', 'coverage', mode,
                                                 '-o' if mode == 'xml' else '-d', path],
                                                logs / f'coverage-{mode}.log', 120, env=env)
    results['automation_coverage'] = run_logged([sys.executable, '-m', 'coverage', 'report',
                                                '--include=scripts/ci/*', '--fail-under=40'],
                                               logs / 'coverage-report.log', 120, env=env)
    print((logs / 'coverage-report.log').read_text(encoding='utf-8'), flush=True)
    return results


def godot_lane(godot, logs, profile, suites, parse):
    results = {}
    env = isolated_env(profile)
    if parse:
        for script in sorted(list((ROOT / 'scripts').rglob('*.gd')) + list((ROOT / 'tests').rglob('*.gd'))):
            key = str(script.relative_to(ROOT))
            label = key.replace('/', '-').replace('\\', '-')
            results[key] = run_logged([godot, '--headless', '--log-file', str(logs / f'parse-{label}-engine.log'),
                                       '--path', str(ROOT), '--check-only', '--script', key],
                                      logs / f'parse-{label}.log', 60, env=env)
            if not results[key]['ok']:
                print('FAIL parse', key, flush=True)
    for name in suites:
        results.update(match_or_suite(godot, logs, profile, name))
    return results


def match_or_suite(godot, logs, profile, name, shard=0, shards=1):
    label = name if shards == 1 else f'{name}-{shard + 1}-of-{shards}'
    command = [godot, '--headless', '--log-file', str(logs / f'{label}-engine.log'),
               '--path', str(ROOT), '--script', f'tests/{name}.gd']
    if name in MATCH_CASES:
        command += ['--', f'--match-shard={shard}/{shards}']
    log = logs / f'{label}.log'
    result = run_logged(command, log, int(os.environ.get('SUITE_TIMEOUT', '900')), True, env=isolated_env(profile))
    if name in MATCH_CASES:
        validate_matches(result, log, name, MATCH_CASES[name][shard::shards])
    print(('OK' if result['ok'] else 'FAIL'), label, result['checks'], 'checks', result['matches'], 'matches', result['seconds'], 's', flush=True)
    return {label: result}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--python-tests', action='store_true')
    parser.add_argument('--python-timings')
    parser.add_argument('--workers', type=int, default=min(4, os.cpu_count() or 1))
    parser.add_argument('--godot', default=os.environ.get('GODOT', '/Applications/Godot.app/Contents/MacOS/Godot'))
    parser.add_argument('--suites', nargs='*')
    args = parser.parse_args()
    if args.workers < 1:
        parser.error('--workers must be positive')
    if args.python_tests:
        raise SystemExit(python_tests(args.python_timings))
    godot = str(Path(args.godot).resolve())
    prepare_test_dirs(ROOT)
    logs = ROOT / '.tools/check-logs'
    logs.mkdir(parents=True, exist_ok=True)
    results = {}
    started = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix='gunbound-ci-profile-') as temporary:
        profiles = Path(temporary)
        def profile(name):
            path = profiles / name
            path.mkdir()
            return path
        results['import'] = run_logged([godot, '--headless', '--log-file', str(logs / 'import-engine.log'),
                                        '--editor', '--path', str(ROOT), '--import'],
                                       logs / 'import.log', 900, env=isolated_env(profile('import')))
        if not results['import']['ok']:
            print((logs / 'import.log').read_text(errors='replace')[-6000:])
            raise SystemExit(1)
        suites = args.suites or godot_suites()
        common = [name for name in suites if name not in MATCH_CASES and name not in ISOLATED_SUITES]
        common_profile = profile('godot')
        tasks = {'godot': lambda: godot_lane(godot, logs, common_profile, common, not args.suites)}
        if not args.suites:
            python_profile = profile('python')
            tasks['python'] = lambda: python_lane(logs, python_profile)
        shards = min(4, args.workers)
        for name in suites:
            if name in MATCH_CASES:
                for shard in range(shards):
                    label = f'{name}-{shard}'
                    shard_profile = profile(label)
                    tasks[label] = lambda n=name, s=shard, p=shard_profile: match_or_suite(godot, logs, p, n, s, shards)
        print(f'CI workers: {args.workers}; match groups per suite: {shards}', flush=True)
        results.update(run_parallel(tasks, args.workers))
        for name in suites:
            if name in ISOLATED_SUITES:
                results.update(match_or_suite(godot, logs, common_profile, name))
    report = {'scope': 'GDScript suite results; line coverage is Python only', 'workers': args.workers,
              'seconds': round(time.perf_counter() - started, 3),
              'matches': sum(value.get('matches', 0) for value in results.values()), 'results': results}
    (logs / 'report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    failed = [name for name, value in results.items() if not value['ok']]
    print('FAILED:', failed)
    raise SystemExit(bool(failed))


if __name__ == '__main__':
    main()
