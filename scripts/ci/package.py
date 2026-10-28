#!/usr/bin/env python3
"""Build, extract, and smoke the native desktop ZIP before producing its manifest."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import shutil
import subprocess
import struct
import sys
import tempfile
import zipfile

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))
from ci.package_common import NOTICES, project_version  # noqa: E402

ROOT = SCRIPTS.parent
ERRORS = re.compile(r'(?m)^(?:SCRIPT ERROR:|ERROR:|.*Parse Error:|.*Failed to load script)')
BANNED = {'override.cfg', 'export_credentials.cfg', '.tools', '.github', 'tests', '.env'}


def validate_layout(folder: Path, platform: str, version: str) -> Path:
    """Check the extracted distribution, not files in the source checkout."""
    for path in folder.rglob('*'):
        if any(part in BANNED for part in path.relative_to(folder).parts):
            raise ValueError(f'Private/source file in distribution: {path.name}')
    if platform == 'macos':
        resources = folder / 'Contents/Resources'
        binary = folder / 'Contents/MacOS/GunboundRecomp'
        with (folder / 'Contents/Info.plist').open('rb') as source:
            info = plistlib.load(source)
        if any(info.get(key) != version for key in ('CFBundleVersion', 'CFBundleShortVersionString')):
            raise ValueError('macOS bundle version does not match project version')
        if info.get('CFBundleExecutable') != binary.name:
            raise ValueError('macOS executable metadata mismatch')
    elif platform == 'windows':
        resources = folder
        binary = folder / 'GunboundRecomp.exe'
    else:
        raise ValueError(f'Unknown platform: {platform}')
    for path in (binary, resources / 'GunboundRecomp.pck', *(resources / n for n in NOTICES.values())):
        if not path.is_file() or not path.stat().st_size:
            raise ValueError(f'Missing/empty required distribution file: {path.name}')
    return binary



def verify_architecture(binary: Path, platform: str) -> None:
    if platform == 'macos':
        architectures = subprocess.check_output(['lipo', '-archs', str(binary)], text=True).split()
        if set(architectures) != {'x86_64', 'arm64'}:
            raise ValueError(f'Expected universal macOS executable, got {architectures}')
    else:
        with binary.open('rb') as source:
            header = source.read(64)
            if len(header) < 64 or header[:2] != b'MZ':
                raise ValueError('Expected Windows x86_64 PE executable')
            source.seek(struct.unpack_from('<I', header, 0x3C)[0])
            pe = source.read(6)
        if len(pe) != 6 or pe[:4] != b'PE\0\0' or struct.unpack_from('<H', pe, 4)[0] != 0x8664:
            raise ValueError('Expected Windows x86_64 PE executable')


def zip_windows(folder: Path, archive: Path) -> None:
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as output:
        for path in sorted(folder.rglob('*')):
            if path.is_file():
                output.write(path, path.relative_to(folder.parent).as_posix())


def smoke_passed(returncode: int, output: str) -> bool:
    return returncode == 0 and 'PACKAGED SMOKE: PASS' in output and not ERRORS.search(output)


def write_manifest(archive: Path, platform: str, version: str, commit: str,
                   godot_version: str, smoke_output: str) -> Path:
    if not smoke_passed(0, smoke_output):
        raise ValueError('Cannot publish a package without a passing smoke')
    hasher = hashlib.sha256()
    with archive.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            hasher.update(block)
    digest = hasher.hexdigest()
    data = {'schema': 1, 'version': version, 'commit': commit,
            'platform': platform, 'architecture': 'universal' if platform == 'macos' else 'x86_64',
            'godot': godot_version, 'file': archive.name, 'size': archive.stat().st_size,
            'sha256': digest, 'smoke': 'passed',
            'signing': 'ad-hoc, not notarized' if platform == 'macos' else 'unsigned'}
    manifest = archive.with_suffix('.json')
    manifest.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
    archive.with_suffix('.zip.sha256').write_text(f'{digest}  {archive.name}\n', encoding='utf-8')
    return manifest


def run_logged(command: list[str], cwd: Path, log: Path, timeout: int,
               engine_log: Path = None) -> str:
    """A timeout, nonzero exit, or Godot script error fails the package gate."""
    log.parent.mkdir(parents=True, exist_ok=True)
    if engine_log is not None:
        engine_log.unlink(missing_ok=True)
    try:
        result = subprocess.run(command, cwd=cwd, capture_output=True, text=True,
                                encoding='utf-8', errors='replace', timeout=timeout, check=False)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or b''
        if isinstance(output, bytes):
            output = output.decode('utf-8', errors='replace')
        log.write_text(output + '\nTIMEOUT\n', encoding='utf-8')
        raise RuntimeError(f'Package command timed out; see {log}') from error
    output = result.stdout + result.stderr
    # Windows release GUI templates may not inherit the parent's stdout pipes.
    # --log-file is part of the runtime API on every platform and must also be
    # inspected; deleting the previous log above prevents a stale PASS.
    if engine_log is not None and engine_log.is_file():
        output += '\n' + engine_log.read_text(encoding='utf-8', errors='replace')
    log.write_text(output, encoding='utf-8')
    print(output, end='')
    if result.returncode != 0 or ERRORS.search(output):
        raise RuntimeError(f'Package command failed (exit {result.returncode}); see {log}')
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=('macos', 'windows'), required=True)
    parser.add_argument('--godot', default=os.environ.get('GODOT', 'godot'))
    parser.add_argument('--commit', default=None)
    args = parser.parse_args()
    version = project_version(ROOT)
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        raise ValueError('Release version must be a stable X.Y.Z')
    commit = args.commit or subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    if not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise ValueError('Release commit must be a full Git SHA')
    expected_host = 'darwin' if args.platform == 'macos' else 'win32'
    if sys.platform != expected_host:
        raise ValueError(f'{args.platform} packaging/smoke requires its native runner')
    godot_version = subprocess.check_output([args.godot, '--version'], text=True).strip()
    if not godot_version.startswith('4.7.2.stable'):
        raise ValueError(f'Expected Godot 4.7.2.stable; got {godot_version}')
    logs = ROOT / '.tools/package-logs'
    run_logged([sys.executable, str(SCRIPTS / f'build_{args.platform}.py'), '--godot', args.godot],
               ROOT, logs / 'export.log', 1800)
    output = ROOT / 'builds/dist'
    output.mkdir(parents=True, exist_ok=True)
    label = 'macOS' if args.platform == 'macos' else 'Windows-x86_64'
    archive = output / f'Gunbound-Recomp-{version}-{label}.zip'
    if args.platform == 'macos':
        shutil.copy2(ROOT / 'builds/Gunbound-Recomp-macOS.zip', archive)
    else:
        folder = ROOT / 'builds/Windows'
        validate_layout(folder, args.platform, version)
        zip_windows(folder, archive)
    # Execute the copy extracted from the ZIP. The current directory has no
    # project.godot, source assets, imported cache or real user profile.
    with tempfile.TemporaryDirectory(prefix='gunbound-package-') as temporary:
        temp = Path(temporary)
        with zipfile.ZipFile(archive) as source:
            for item in source.namelist():
                path = PurePosixPath(item)
                if path.is_absolute() or '..' in path.parts or any(p in BANNED for p in path.parts):
                    raise ValueError(f'Unsafe archive entry: {item}')
        if args.platform == 'macos':
            subprocess.run(['ditto', '-x', '-k', str(archive), str(temp)], check=True)
            folder = temp / 'Gunbound Recomp.app'
        else:
            with zipfile.ZipFile(archive) as source:
                source.extractall(temp)
            folder = temp / 'Windows'
        binary = validate_layout(folder, args.platform, version)
        verify_architecture(binary, args.platform)
        if args.platform == 'macos':
            subprocess.run(['codesign', '--verify', '--deep', '--strict', str(folder)], check=True)
        profile = temp / 'ci-profile.json'
        smoke_output = run_logged([str(binary), '--headless', '--log-file', str(logs / 'smoke-engine.log'),
                                   '--', '--ci-smoke',
                                   '--ci-version', version, '--ci-profile', str(profile)],
                                  temp, logs / 'smoke.log', 180, engine_log=logs / 'smoke-engine.log')
        if not smoke_passed(0, smoke_output):
            raise RuntimeError('Packaged executable did not report a passing smoke')
        if not profile.is_file():
            raise RuntimeError('Smoke did not exercise the isolated profile')
    write_manifest(archive, args.platform, version, commit, godot_version, smoke_output)
    print('PACKAGE READY:', archive)


if __name__ == '__main__':
    main()
