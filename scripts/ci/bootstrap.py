#!/usr/bin/env python3
"""Install pinned CI inputs, validating bytes even on a cache hit.

Godot hashes are the official release asset digests; SHA512-SUMS.txt is also
pinned and verified before its entries are used. The Thor's Hammer TestClient
is read-only evidence for existing tests, never included in an export.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import platform
import shutil
import stat
import struct
import sys
import time
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[2]
CONFIG = json.loads((ROOT / '.github/ci-tools.json').read_text(encoding='utf-8'))


def verify_digest(path: Path, expected: str, algorithm: str = 'sha256') -> None:
    digest = hashlib.new(algorithm)
    with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(block)
    if digest.hexdigest() != expected.lower():
        raise ValueError(f'{algorithm.upper()} mismatch: {path.name}')


def download(url: str, target: Path, expected: str) -> Path:
    """Cache only verified inputs; incomplete downloads cannot become cache hits."""
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_file():
        verify_digest(target, expected)
        return target
    temporary = target.with_name(target.name + '.part')
    for attempt in range(3):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': 'Gunbound-Recomp-CI'})
            with urllib.request.urlopen(request, timeout=120) as response, temporary.open('wb') as out:
                shutil.copyfileobj(response, out)
            verify_digest(temporary, expected)
            temporary.replace(target)
            return target
        except (OSError, ValueError):
            temporary.unlink(missing_ok=True)
            if attempt == 2:
                raise
            time.sleep(attempt + 1)
    raise RuntimeError('Download failed')


def safe_extract(archive: Path, destination: Path, members=None) -> None:
    """Reject traversal, drive paths and symlinks before writing any member."""
    destination = destination.resolve()
    with zipfile.ZipFile(archive) as source:
        selected = source.infolist() if members is None else [source.getinfo(n) for n in members]
        for info in selected:
            name = info.filename.replace('\\', '/')
            path = PurePosixPath(name)
            mode = info.external_attr >> 16
            target = (destination / name).resolve()
            if (path.is_absolute() or '..' in path.parts or ':' in name
                    or not target.is_relative_to(destination) or stat.S_ISLNK(mode)):
                raise ValueError(f'Unsafe ZIP member: {info.filename}')
        for info in selected:
            path = destination / info.filename
            if info.is_dir():
                path.mkdir(parents=True, exist_ok=True)
                continue
            path.parent.mkdir(parents=True, exist_ok=True)
            with source.open(info) as entry, path.open('wb') as out:
                shutil.copyfileobj(entry, out)
            permissions = (info.external_attr >> 16) & 0o777
            if permissions and os.name != 'nt':
                path.chmod(permissions)


def editor_asset(system: str, machine: str) -> tuple[str, str]:
    if system == 'Darwin' and machine.lower() in ('x86_64', 'arm64', 'aarch64'):
        return ('Godot_v4.7.2-stable_macos.universal.zip', 'Godot.app/Contents/MacOS/Godot')
    if system == 'Windows' and machine.lower() in ('amd64', 'x86_64'):
        return ('Godot_v4.7.2-stable_win64.exe.zip', 'Godot_v4.7.2-stable_win64.exe')
    if system == 'Linux' and machine.lower() in ('amd64', 'x86_64'):
        return ('Godot_v4.7.2-stable_linux.x86_64.zip', 'Godot_v4.7.2-stable_linux.x86_64')
    raise ValueError(f'Unsupported runner: {system}/{machine}')


def templates_directory(system: str) -> Path:
    if system == 'Darwin':
        base = Path.home() / 'Library/Application Support'
    elif system == 'Windows':
        base = Path(os.environ['APPDATA'])
    else:
        base = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share')))
    return base / 'Godot/export_templates' / (CONFIG['godot_version'] + '.stable')


def prepare_godot(root: Path, templates: bool = True) -> Path:
    system = platform.system()
    name, executable = editor_asset(system, platform.machine())
    cache = root / '.tools/cache'
    release = CONFIG['godot_release']
    hashes = CONFIG['godot_sha256']
    checksum_file = download(f'{release}/SHA512-SUMS.txt', cache / 'SHA512-SUMS.txt', hashes['SHA512-SUMS.txt'])
    manifest = {}
    for line in checksum_file.read_text(encoding='utf-8').splitlines():
        parts = line.split()
        if len(parts) == 2:
            manifest[parts[1].lstrip('*')] = parts[0]

    def asset(filename):
        path = download(f'{release}/{filename}', cache / filename, hashes[filename])
        if filename not in manifest:
            raise ValueError(f'Asset absent from official checksum manifest: {filename}')
        verify_digest(path, manifest[filename], 'sha512')
        return path

    editor = root / '.tools/godot'
    safe_extract(asset(name), editor)
    binary = editor / executable
    if os.name != 'nt':
        binary.chmod(binary.stat().st_mode | 0o111)
    if templates:
        archive = asset('Godot_v4.7.2-stable_export_templates.tpz')
        selected = ['templates/version.txt']
        if system == 'Darwin':
            selected.append('templates/macos.zip')
        elif system == 'Windows':
            selected += ['templates/windows_release_x86_64.exe', 'templates/windows_debug_x86_64.exe']
        else:
            selected += ['templates/linux_release.x86_64', 'templates/linux_debug.x86_64']
        unpacked = root / '.tools/template-unpack'
        safe_extract(archive, unpacked, selected)
        installed = templates_directory(system)
        installed.mkdir(parents=True, exist_ok=True)
        for entry in selected:
            shutil.copy2(unpacked / entry, installed / Path(entry).name)
        if system == 'Darwin':
            shutil.copy2(installed / 'macos.zip', root / '.tools/macos.zip')
    return binary.resolve()


def prepare_avatar_references(root: Path, source: Path) -> None:
    """Prepare ignored version280 DAT oracles without regenerating runtime art."""
    verify_digest(source, CONFIG['client_sha256']['avatar.xfs'])
    sys.path.insert(0, str(ROOT / 'scripts'))
    from read_gunbound_xfs import archive, extract
    raw = source.read_bytes()
    index = archive(raw)
    names = {'fb.dat', 'ff.dat', 'fg.dat', 'fh.dat', 'mb.dat', 'mf.dat', 'mg.dat', 'mh.dat'}
    if index['version'] != 280 or set(index['entries']) != names:
        raise ValueError('Unsupported avatar reference directory')
    # Decode everything before writing, and allow only the eight fixed names.
    payloads = {name: extract(raw, entry) for name, entry in index['entries'].items()}
    destination = root / 'assets/xfs/reference'
    destination.mkdir(parents=True, exist_ok=True)
    (destination / 'avatar.xfs').write_bytes(raw)
    for name, payload in payloads.items():
        (destination / name).write_bytes(payload)


def prepare_client(root: Path, source: Path | None = None, legacy_sound: bool = True) -> None:
    cache = root / '.tools/gunbound-client'
    revision = CONFIG['client_revision']
    # Validate the complete local input before copying a partial source tree.
    if source is not None:
        for name, digest in CONFIG['client_sha256'].items():
            verify_digest(source / name, digest)
    cache.mkdir(parents=True, exist_ok=True)
    for name, digest in CONFIG['client_sha256'].items():
        target = cache / name
        if source is not None:
            if (source / name).resolve() != target.resolve():
                shutil.copy2(source / name, target)
            verify_digest(target, digest)
        else:
            download(f'https://raw.githubusercontent.com/jglim/gunbound-launcher/{revision}/TestClient/{name}', target, digest)
    prepare_avatar_references(root, cache / 'avatar.xfs')
    pe = root / '.tools/mobile-animation-port/GunBound.gme'
    pe.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(cache / 'GunBound.gme', pe)
    # Keep existing tests that use the historical sibling checkout path working.
    if legacy_sound:
        legacy = root.parent / 'GunboundClassic/gunbound-launcher/TestClient/sound.xfs'
        legacy.parent.mkdir(parents=True, exist_ok=True)
        if legacy.exists():
            verify_digest(legacy, CONFIG['client_sha256']['sound.xfs'])
        else:
            shutil.copy2(cache / 'sound.xfs', legacy)
    sys.path.insert(0, str(ROOT / 'scripts'))
    from gunbound_xfs import lzhuf
    decoded = lzhuf((cache / 'characterdata.dat').read_bytes(), 16 * 332)
    if len(decoded) != 16 * 332 or struct.unpack_from('<3i', decoded) != (28, 24, 0):
        raise ValueError('Unsupported characterdata stream')
    rows = [list(struct.unpack_from('<83i', decoded, index * 332)) for index in range(16)]
    output = root / '.tools/battle-execution/shots-research/characterdata.json'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps({'sha256': CONFIG['client_sha256']['characterdata.dat'], 'rows': rows}, indent=2) + '\n', encoding='utf-8')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--skip-godot', action='store_true', help='Use the installed editor; prepare only test evidence')
    parser.add_argument('--skip-templates', action='store_true', help='Prepare tests without export templates')
    parser.add_argument('--client-source', type=Path, help='Copy verified TestClient inputs from a local directory')
    parser.add_argument('--no-legacy-sound', action='store_true', help='Do not prepare the historical sibling sound path')
    args = parser.parse_args()
    binary = None if args.skip_godot else prepare_godot(ROOT, not args.skip_templates)
    prepare_client(ROOT, args.client_source, not args.no_legacy_sound)
    values = {'GUNBOUND_SOUND_XFS': str((ROOT / '.tools/gunbound-client/sound.xfs').resolve())}
    if binary:
        values['GODOT'] = str(binary)
    for key, value in values.items():
        if '\n' in value or '\r' in value:
            raise ValueError('Environment path contains a newline')
        print(f'{key}={value}')
    if os.environ.get('GITHUB_ENV'):
        with Path(os.environ['GITHUB_ENV']).open('a', encoding='utf-8') as target:
            target.writelines(f'{key}={value}\n' for key, value in values.items())


if __name__ == '__main__':
    main()
