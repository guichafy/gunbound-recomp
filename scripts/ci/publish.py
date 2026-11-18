#!/usr/bin/env python3
"""Publish verified desktop packages with the tested or device-approved Android APK."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import urllib.error
import urllib.parse
import urllib.request


def validate_assets(folder, version, sha, *, include_android=True):
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or not re.fullmatch(r'[0-9a-f]{40}', sha):
        raise ValueError('Invalid version or commit')
    assets = []
    platforms = [('macos', 'macOS'), ('windows', 'Windows-x86_64')]
    if include_android:
        platforms.append(('android', 'Android'))
    for platform, suffix in platforms:
        extension = '.apk' if platform == 'android' else '.zip'
        archive = folder / f'Gunbound-Recomp-{version}-{suffix}{extension}'
        manifest = archive.with_suffix('.json')
        checksum = archive.with_suffix(extension + '.sha256')
        if not all(p.is_file() for p in (archive, manifest, checksum)):
            raise ValueError(f'Incomplete package for {platform}')
        data = json.loads(manifest.read_text())
        with archive.open('rb') as source:
            digest = hashlib.file_digest(source, 'sha256').hexdigest()
        expected = {'version': version, 'commit': sha, 'platform': platform, 'file': archive.name,
                    'size': archive.stat().st_size, 'sha256': digest, 'smoke': 'passed'}
        if any(data.get(k) != v for k, v in expected.items()):
            raise ValueError(f'Manifest mismatch: {platform}')
        if checksum.read_text() != f'{digest}  {archive.name}\n':
            raise ValueError('Checksum mismatch')
        if platform == 'android':
            import sys
            sys.path.insert(0, str(Path(__file__).resolve().parent))
            from android_package import GODOT_VERSION, version_code
            required = dict(schema=2,godot=GODOT_VERSION,abis=['arm64-v8a','x86_64'],package_id='com.chafy.gunboundrecomp',
                            version_code=version_code(version),min_sdk=24,target_sdk=36,
                            arm64_acceptance='manual_gate_required',diagnostic='passed',final_x86_64='passed')
            if (any(data.get(k)!=v for k,v in required.items())
                    or not re.fullmatch('[0-9a-f]{64}',data.get('certificate_sha256',''))):
                raise ValueError('Android manifest validation failed')
        assets += [archive, manifest, checksum]
    if {p.name for p in folder.iterdir()} != {p.name for p in assets}:
        raise ValueError('Unexpected release assets')
    return assets


def validate_test_candidate(folder, version):
    apk = folder / 'candidate.apk'
    inspection = json.loads(apk.with_suffix('.inspection.json').read_text())
    with apk.open('rb') as source:
        digest = hashlib.file_digest(source, 'sha256').hexdigest()
    app = 'com.chafy.gunboundrecomp.ci'
    expected = {'mode': 'candidate', 'package_id': app, 'version': version,
                'sha256': digest, 'abis': ['arm64-v8a', 'x86_64'], 'min_sdk': 24, 'target_sdk': 36}
    if any(inspection.get(key) != value for key, value in expected.items()):
        raise ValueError('Test APK differs from the inspected candidate')
    for api in (24, 36):
        report = json.loads((folder / f'smoke-api{api}.json').read_text())
        expected_report = {'kind': 'final-ui', 'status': 'passed', 'app_id': app,
                           'apk_sha256': digest, 'version': version, 'executed_abi': 'x86_64',
                           'android_api': api}
        if any(report.get(key) != value for key, value in expected_report.items()):
            raise ValueError(f'Test APK has no matching API {api} smoke report')
    return apk


class GitHub:
    def __init__(self, repo, token):
        self.base = f'https://api.github.com/repos/{repo}'
        self.token = token

    def request(self, method, path, data=None, binary=False):
        url = path if path.startswith('https://uploads.github.com/') else self.base + path
        payload = data if binary else json.dumps(data).encode() if data is not None else None
        request = urllib.request.Request(url, data=payload, method=method, headers={
            'Authorization': f'Bearer {self.token}', 'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'Gunbound-Recomp-CI',
            'Content-Type': 'application/octet-stream' if binary else 'application/json'})
        try:
            with urllib.request.urlopen(request, timeout=300) as response:
                body = response.read()
                return json.loads(body) if body else None
        except urllib.error.HTTPError as error:
            if error.code == 404 and method == 'GET':
                return None
            raise


def publish(api, folder, version, sha, acceptance=None, run_id=None, trusted_reviewers=None, *, test_candidate=None):
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or not re.fullmatch(r'[0-9a-f]{40}', sha):
        raise ValueError('Invalid version or commit')
    desktop_names = {f'Gunbound-Recomp-{version}-{suffix}.zip' for suffix in ('macOS','Windows-x86_64')}
    test_mode = test_candidate is not None
    android_label = 'Android-Test' if test_mode else 'Android'
    apk_name = f'Gunbound-Recomp-{version}-{android_label}.apk'
    expected_names = desktop_names | {apk_name, 'SHA256SUMS'}
    tag = f'v{version}'
    release = api.request('GET', f'/releases/tags/{tag}')
    if not release:
        page = 1
        while True:
            batch = api.request('GET', f'/releases?per_page=100&page={page}') or []
            matches = [r for r in batch if r['tag_name'] == tag]
            if matches:
                if len(matches) != 1:
                    raise ValueError('Multiple releases use this tag')
                release = matches[0]
                break
            if len(batch) < 100:
                break
            page += 1
    ref = api.request('GET', f'/git/ref/tags/{tag}')
    if ref and (ref['object']['type'] != 'commit' or ref['object']['sha'] != sha):
        raise ValueError('Release tag does not identify this tested commit')
    if release and release['draft'] and release.get('target_commitish') != sha:
        raise ValueError('Draft target does not identify this tested commit')
    if release and not release['draft'] and not ref:
        raise ValueError('Published release has no valid tag; refusing repair')
    if release and not release['draft']:
        names = {a['name'] for a in release['assets']}
        legacy_six = set()
        for name in desktop_names:
            legacy_six.update((name, name.removesuffix('.zip')+'.json', name+'.sha256'))
        allowed = (expected_names,) if test_mode else (expected_names, desktop_names | {'SHA256SUMS'}, legacy_six)
        if names not in allowed:
            raise ValueError('Published release is incomplete; refusing overwrite')
        print('Release already published:', release['html_url'])
        return
    validated = validate_assets(folder, version, sha, include_android=not test_mode)
    archives = [path for path in validated if path.suffix in ('.zip', '.apk')]
    if test_mode:
        archives.append(validate_test_candidate(test_candidate, version))
        qa_note = ('Android test build with an ephemeral signing key. Installing a later build may '
                   'require uninstalling the previous app and clearing its local profile. '
                   'This APK passed the API 24 and API 36 emulator smoke tests.')
    else:
        if acceptance is None or run_id is None or not trusted_reviewers:
            raise ValueError('Android acceptance and trusted review history required')
        import sys
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from android_acceptance import fetch_acceptance
        manifest = json.loads((folder / apk_name).with_suffix('.json').read_text())
        verified = fetch_acceptance(api, manifest, int(run_id), set(trusted_reviewers))
        if acceptance != verified:
            raise ValueError('Android acceptance artifact differs from trusted API history')
        qa_note = (f"ARM64 QA: {verified['reviewer']}; APK SHA256 {manifest['sha256']}; "
                   f"device {verified['device']}; evidence {verified['evidence_url']}")
    names_by_path = {path: apk_name if path.suffix == '.apk' else path.name for path in archives}
    if not ref:
        ref = api.request('POST', '/git/refs', {'ref': f'refs/tags/{tag}', 'sha': sha})
        if ref['object']['type'] != 'commit' or ref['object']['sha'] != sha:
            raise ValueError('Version reservation verification failed')
    if not release:
        notes = ('Tested desktop and Android packages for commit ' + sha + '.\n\n'
                 'macOS: universal, ad-hoc signed, not notarized. Windows: x86_64, unsigned.\n'
                 'Download a desktop ZIP or the Android APK; SHA256SUMS verifies all three packages.\n'
                 'Build manifests and individual checksums remain in the desktop workflow artifacts.\n'
                 'The Source code archives are repository snapshots. '
                 'Headless smoke does not replace visual/audio QA.')
        notes += '\n\n' + qa_note
        release = api.request('POST', '/releases', {'tag_name': tag, 'target_commitish': sha,
                              'name': f'Gunbound Recomp {version}', 'body': notes, 'draft': True, 'generate_release_notes': True})
    if qa_note not in release.get('body',''):
        body=re.sub(r'(?m)^ARM64 QA:.*$', '', release.get('body','')).rstrip()+'\n\n'+qa_note
        api.request('PATCH',f"/releases/{release['id']}",{'body':body})
    # Keep generated publication files outside the validated input directory so
    # a local retry sees the same nine trusted inputs, even after an upload fails.
    with tempfile.TemporaryDirectory(prefix='gunbound-release-') as temporary:
        checksum = Path(temporary) / 'SHA256SUMS'
        lines = []
        expected_digests = {}
        for archive in archives:
            with archive.open('rb') as source:
                digest = hashlib.file_digest(source, 'sha256').hexdigest()
            expected_digests[names_by_path[archive]] = 'sha256:' + digest
            lines.append(f'{digest}  {names_by_path[archive]}\n')
        checksum.write_bytes(''.join(lines).encode('utf-8'))
        expected_digests[checksum.name] = 'sha256:' + hashlib.sha256(checksum.read_bytes()).hexdigest()
        for asset in release['assets']:
            api.request('DELETE', f"/releases/assets/{asset['id']}")
        upload = release['upload_url'].split('{')[0]
        for path in [*archives, checksum]:
            api.request('POST', upload + '?name=' + urllib.parse.quote(names_by_path.get(path, path.name)), path.read_bytes(), True)
    final = api.request('GET', f"/releases/{release['id']}")
    uploaded = {asset['name']: asset.get('digest') for asset in final['assets']
                if asset.get('state') == 'uploaded'}
    if uploaded != expected_digests or len(final['assets']) != len(expected_names):
        raise ValueError('Release upload incomplete; draft preserved')
    api.request('PATCH', f"/releases/{release['id']}", {'draft': False, 'make_latest': 'legacy'})
    ref = api.request('GET', f'/git/ref/tags/{tag}')
    if not ref or ref['object']['type'] != 'commit' or ref['object']['sha'] != sha:
        raise ValueError('Published tag verification failed')
    print('Published:', final['html_url'])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', required=True)
    parser.add_argument('--sha', required=True)
    parser.add_argument('--folder', type=Path, default=Path('release-assets'))
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--acceptance', type=Path)
    mode.add_argument('--test-candidate', type=Path)
    args = parser.parse_args()
    acceptance = json.loads(args.acceptance.read_text()) if args.acceptance else None
    publish(GitHub(os.environ['GITHUB_REPOSITORY'], os.environ['GH_TOKEN']), args.folder, args.version, args.sha, acceptance,
            int(os.environ['GITHUB_RUN_ID']) if os.environ.get('GITHUB_RUN_ID') else None,
            set(filter(None, os.environ.get('ANDROID_TRUSTED_REVIEWERS','').split(','))), test_candidate=args.test_candidate)


if __name__ == '__main__':
    main()
