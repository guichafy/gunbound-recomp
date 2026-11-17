import unittest
import os
import subprocess
from pathlib import Path
import yaml

ROOT=Path(__file__).resolve().parents[1]

def bash():
    # windows-latest also exposes the WSL launcher as bash.exe. These jobs use
    # Git Bash; neither WSL nor an executable POSIX stub belongs in this test.
    if os.name=='nt':
        return str(Path(os.environ['ProgramFiles'])/'Git/bin/bash.exe')
    return 'bash'


class AndroidWorkflowTests(unittest.TestCase):
    def test_android_installs_locked_python_dependencies_before_bootstrap(self):
        steps=yaml.safe_load((ROOT/'.github/workflows/desktop.yml').read_text())['jobs']['android']['steps']
        installations=[i for i,s in enumerate(steps) if 'python -m pip install -r .github/requirements-ci.txt' in s.get('run','')]
        self.assertTrue(installations,'Clean Android runner needs Pillow before client/bootstrap imports')
        bootstrap=next(i for i,s in enumerate(steps) if 'python scripts/ci/bootstrap.py' in s.get('run',''))
        setup=next(i for i,s in enumerate(steps) if s.get('uses','').startswith('actions/setup-python@'))
        self.assertLess(setup,installations[0]);self.assertLess(installations[0],bootstrap)
        self.assertRegex((ROOT/'.github/requirements-ci.txt').read_text(),r'(?m)^Pillow==[^\s]+$')

    @staticmethod
    def gate(expression,event,publication):
        expression=expression.removeprefix('${{').removesuffix('}}').strip()
        for field,value in [('github.event_name',event),('github.ref','refs/heads/main'),('vars.ANDROID_PUBLICATION_ENABLED',publication)]:
            expression=expression.replace(field,"'"+value+"'")
        result=subprocess.run([bash(),'-c','if [[ '+expression+' ]]; then printf true; else printf false; fi'],capture_output=True,text=True,check=True)
        if result.stdout not in ['true','false']:raise AssertionError(result.stderr or result.stdout)
        return result.stdout=='true'

    def test_pr_and_main_default_to_installable_test_artifacts_without_secrets(self):
        steps=yaml.safe_load((ROOT/'.github/workflows/desktop.yml').read_text())['jobs']['android']['steps']
        candidate=next(s for s in steps if '--mode candidate' in s.get('run',''))
        production=next(s for s in steps if 'ANDROID_KEYSTORE_BASE64' in s.get('env',{}))
        candidate_upload=next(s for s in steps if s.get('with',{}).get('name')=='android-test-candidates-not-for-distribution')
        production_upload=next(s for s in steps if s.get('with',{}).get('name')=='android-package')
        self.assertNotIn('secrets.',str(candidate.get('env',{})))
        for event in ['pull_request','push']:
            for flag in ['', 'false','true']:
                with self.subTest(event=event,publication=flag):
                    official=event=='push' and flag=='true'
                    self.assertEqual(self.gate(candidate['if'],event,flag),not official)
                    self.assertEqual(self.gate(candidate_upload['if'],event,flag),not official)
                    self.assertEqual(self.gate(production['if'],event,flag),official)
                    self.assertEqual(self.gate(production_upload['if'],event,flag),official)

    def test_api24_executes_the_same_test_or_distribution_apk_as_api36(self):
        steps=yaml.safe_load((ROOT/'.github/workflows/desktop.yml').read_text())['jobs']['android']['steps']
        smoke=next(s for s in steps if '--output .tools/android-reports/final-api24' in s.get('run',''))
        for event in ['pull_request','push']:
            for flag in ['', 'false','true']:
                with self.subTest(event=event,publication=flag):
                    official=self.gate(smoke['env']['ANDROID_DISTRIBUTION'],event,flag)
                    env=dict(os.environ,RELEASE_VERSION='0.23.0',ANDROID_DISTRIBUTION=str(official).lower())
                    script='python() { printf "%s\\n" "$@"; }\n'+smoke['run']
                    result=subprocess.run([bash(),'-e','-c',script],env=env,capture_output=True,text=True,check=True)
                    args=result.stdout.splitlines()
                    expected='builds/dist/Gunbound-Recomp-0.23.0-Android.apk' if official else 'builds/android/candidate.apk'
                    self.assertEqual(args[args.index('--apk')+1],expected)
                    self.assertEqual(args[args.index('--app-id')+1],'com.chafy.gunboundrecomp'+('' if official else '.ci'))

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
