#!/usr/bin/env python3
"""Publish three verified packages after exact-APK ARM64 approval; failures stay draft."""
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


def validate_assets(folder, version, sha):
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or not re.fullmatch(r'[0-9a-f]{40}', sha):
        raise ValueError('Invalid version or commit')
    assets = []
    for platform, suffix in [('macos', 'macOS'), ('windows', 'Windows-x86_64'), ('android', 'Android')]:
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


def publish(api, folder, version, sha, acceptance=None, run_id=None, trusted_reviewers=None):
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or not re.fullmatch(r'[0-9a-f]{40}', sha):
        raise ValueError('Invalid version or commit')
    desktop_names = {f'Gunbound-Recomp-{version}-{suffix}.zip' for suffix in ('macOS','Windows-x86_64')}
    expected_names = desktop_names | {f'Gunbound-Recomp-{version}-Android.apk', 'SHA256SUMS'}
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
        if names not in (expected_names, desktop_names | {'SHA256SUMS'}, legacy_six):
            raise ValueError('Published release is incomplete; refusing overwrite')
        print('Release already published:', release['html_url'])
        return
    # Every new/draft release must satisfy the nine-entry Android contract.
    # Only GETs above are permitted before local validation AND trusted review.
    validated = validate_assets(folder, version, sha)
    archives = [path for path in validated if path.suffix in ('.zip','.apk')]
    if acceptance is None or run_id is None or not trusted_reviewers:
        raise ValueError('Android acceptance and trusted review history required')
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from android_acceptance import fetch_acceptance
    manifest = json.loads((folder / f'Gunbound-Recomp-{version}-Android.json').read_text())
    verified_acceptance = fetch_acceptance(api,manifest,int(run_id),set(trusted_reviewers))
    if acceptance != verified_acceptance:
        raise ValueError('Android acceptance artifact differs from trusted API history')
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
        notes += ('\n\nARM64 QA: ' + verified_acceptance['reviewer'] + '; APK SHA256 ' + manifest['sha256']
                  + '; device ' + verified_acceptance['device'] + '; evidence ' + verified_acceptance['evidence_url'])
        release = api.request('POST', '/releases', {'tag_name': tag, 'target_commitish': sha,
                              'name': f'Gunbound Recomp {version}', 'body': notes, 'draft': True, 'generate_release_notes': True})
    qa_note=('ARM64 QA: ' + verified_acceptance['reviewer'] + '; APK SHA256 ' + manifest['sha256']
             + '; device ' + verified_acceptance['device'] + '; evidence ' + verified_acceptance['evidence_url'])
    if qa_note not in release.get('body',''):
        body=re.sub(r'(?m)^ARM64 QA:.*$', '', release.get('body','')).rstrip()+'\n\n'+qa_note
        api.request('PATCH',f"/releases/{release['id']}",{'body':body})
    # Keep generated publication files outside the validated input directory so
    # a local retry sees the same nine trusted inputs, even after an upload fails.
    with tempfile.TemporaryDirectory(prefix='gunbound-release-') as temporary:
        checksum = Path(temporary) / 'SHA256SUMS'
        lines = []
        for archive in archives:
            with archive.open('rb') as source:
                digest = hashlib.file_digest(source, 'sha256').hexdigest()
            lines.append(f'{digest}  {archive.name}\n')
        checksum.write_bytes(''.join(lines).encode('utf-8'))
        for asset in release['assets']:
            api.request('DELETE', f"/releases/assets/{asset['id']}")
        upload = release['upload_url'].split('{')[0]
        for path in [*archives, checksum]:
            api.request('POST', upload + '?name=' + urllib.parse.quote(path.name), path.read_bytes(), True)
    final = api.request('GET', f"/releases/{release['id']}")
    if {a['name'] for a in final['assets']} != expected_names:
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
    parser.add_argument('--acceptance', type=Path)
    args = parser.parse_args()
    acceptance = json.loads(args.acceptance.read_text()) if args.acceptance else None
    publish(GitHub(os.environ['GITHUB_REPOSITORY'], os.environ['GH_TOKEN']), args.folder, args.version, args.sha, acceptance,
            int(os.environ['GITHUB_RUN_ID']) if os.environ.get('GITHUB_RUN_ID') else None,
            set(filter(None, os.environ.get('ANDROID_TRUSTED_REVIEWERS','').split(','))))


if __name__ == '__main__':
    main()
