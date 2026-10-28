#!/usr/bin/env python3
"""Portable equivalent of check.sh, with durable logs and explicit coverage scope."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
ERRORS = re.compile(r'SCRIPT ERROR|Parse Error|Failed to load script|^ERROR:|^FAIL:|FAILURES: [1-9]', re.M)


def suite_names():
    text = (ROOT / 'scripts/check.sh').read_text()
    names = []
    for line in text.splitlines():
        if line.startswith('ALL='):
            names += re.findall(r'\btest_\w+', line)
    return list(dict.fromkeys(names))


def godot_suites():
    return [name for name in suite_names() if (ROOT / f'tests/{name}.gd').exists() and not (ROOT / f'tests/{name}.py').exists()]


def run_logged(command, log, timeout, summary=False, cwd=ROOT, env=None):
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open('w', encoding='utf-8') as output:
        try:
            result = subprocess.run(command, cwd=cwd, env=env, stdout=output, stderr=subprocess.STDOUT, timeout=timeout, check=False)
            status = result.returncode
        except subprocess.TimeoutExpired:
            output.write('\nTIMEOUT\n')
            status = 124
    text = log.read_text(encoding='utf-8', errors='replace')
    has_summary = bool(re.search(r'CHECKS:|MATCHES:', text))
    ok = status == 0 and not ERRORS.search(text) and (not summary or has_summary)
    return {'ok': ok, 'exit': status, 'log': str(log.relative_to(ROOT)) if log.is_relative_to(ROOT) else str(log),
            'checks': sum(map(int, re.findall(r'CHECKS:\s*(\d+)', text)))}


def prepare_test_dirs(root):
    # Existing scene fixtures write directly to these paths. Never create the
    # deliberately missing directories used by rollback/failure-path tests.
    for name in ('lobby-rank', 'room-ui', 'room-contact', 'room-polish', 'room-reference',
                 'classic-buttons-hd', 'hud-layout', 'battle-menu', 'match-loading',
                 'result-port', 'turtle-fix', 'turtle-t2'):
        (root / '.tools' / name).mkdir(parents=True, exist_ok=True)


def python_tests():
    names = [name for name in suite_names() if (ROOT / f'tests/{name}.py').exists()]
    names += [p.stem for p in sorted((ROOT / 'tests').glob('test_ci_*.py'))]
    loader = unittest.TestLoader()
    suite = unittest.TestSuite(loader.discover(str(ROOT / 'tests'), pattern=f'{name}.py') for name in names)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.skipped:
        print('SKIPPED:', [(str(test), reason) for test, reason in result.skipped])
    return 0 if result.wasSuccessful() and not result.skipped else 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--python-tests', action='store_true')
    parser.add_argument('--godot', default=os.environ.get('GODOT', '/Applications/Godot.app/Contents/MacOS/Godot'))
    parser.add_argument('--suites', nargs='*')
    args = parser.parse_args()
    if args.python_tests:
        raise SystemExit(python_tests())
    godot = str(Path(args.godot).resolve())
    prepare_test_dirs(ROOT)
    logs = ROOT / '.tools/check-logs'
    logs.mkdir(parents=True, exist_ok=True)
    results = {}
    with tempfile.TemporaryDirectory(prefix='gunbound-ci-profile-') as profile:
        env = dict(os.environ, HOME=profile, APPDATA=profile, XDG_DATA_HOME=profile, XDG_CONFIG_HOME=profile)
        results['import'] = run_logged([godot, '--headless', '--editor', '--path', str(ROOT), '--import'], logs / 'import.log', 900, env=env)
        if not results['import']['ok']:
            print((logs / 'import.log').read_text(errors='replace')[-6000:])
            raise SystemExit(1)
        if not args.suites:
            for script in sorted(list((ROOT / 'scripts').rglob('*.gd')) + list((ROOT / 'tests').rglob('*.gd'))):
                key = str(script.relative_to(ROOT))
                results[key] = run_logged([godot, '--headless', '--path', str(ROOT), '--check-only', '--script', key], logs / ('parse-' + script.stem + '.log'), 60, env=env)
                if not results[key]['ok']:
                    print('FAIL parse', key, flush=True)
        for name in args.suites or godot_suites():
            results[name] = run_logged([godot, '--headless', '--path', str(ROOT), '--script', f'tests/{name}.gd'], logs / f'{name}.log', int(os.environ.get('SUITE_TIMEOUT', '900')), True, env=env)
            print(('OK' if results[name]['ok'] else 'FAIL'), name, results[name]['checks'], flush=True)
        if not args.suites:
            results['python'] = run_logged([sys.executable, '-m', 'coverage', 'run', '--branch', '--source=scripts', str(Path(__file__).resolve()), '--python-tests'], logs / 'python.log', 900, env=env)
            if not results['python']['ok']:
                print((logs / 'python.log').read_text(encoding='utf-8', errors='replace')[-12000:], flush=True)
            for mode, path in [('xml', '.tools/coverage.xml'), ('html', '.tools/coverage-html')]:
                subprocess.run([sys.executable, '-m', 'coverage', mode, '-o' if mode == 'xml' else '-d', path], cwd=ROOT, check=True)
            coverage = subprocess.run([sys.executable, '-m', 'coverage', 'report', '--include=scripts/ci/*', '--fail-under=40'], cwd=ROOT, check=False)
            results['automation_coverage'] = {'ok': coverage.returncode == 0}
    (logs / 'report.json').write_text(json.dumps({'scope': 'GDScript suite results; line coverage is Python only', 'results': results}, indent=2) + '\n')
    failed = [name for name, value in results.items() if not value['ok']]
    print('FAILED:', failed)
    raise SystemExit(bool(failed))


if __name__ == '__main__':
    main()
