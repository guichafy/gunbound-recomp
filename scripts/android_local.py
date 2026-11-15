#!/usr/bin/env python3
"""Build/run Android on a disposable macOS AVD; never target a physical phone."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import socket
import subprocess
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ci import android_package, android_tools, bootstrap

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / '.tools/android-v1'
TOOLS = STATE / 'local-tools.json'
AVD_NAME = 'gunbound_android_v1'


def emulator_port(serial: str) -> int:
    if not re.fullmatch(r'emulator-\d+', serial):
        raise ValueError('Only an explicit emulator serial is allowed; phones are rejected')
    port = int(serial.split('-')[1])
    if not 5554 <= port <= 5680 or port % 2:
        raise ValueError('Expected an even Android emulator console port in 5554..5680')
    return port


def local_environment(root: Path, tools: dict) -> dict:
    return dict(os.environ, **tools, ANDROID_AVD_HOME=str(root / '.tools/android-v1/avd'),
                ANDROID_USER_HOME=str(root / '.tools/android-v1/android-user'))


def tools_from_sdk(sdk: Path, jdk: Path, templates: Path, build_tools: str) -> dict:
    if not sdk.is_dir() or not (jdk / 'bin/java').is_file():
        raise ValueError('Provide an installed SDK (read-only) and a JDK17 home; see docs/ANDROID.md')
    build = sdk / 'build-tools' / build_tools
    result = dict(JAVA_HOME=str(jdk.resolve()), ANDROID_SDK_ROOT=str(sdk.resolve()),
                  GODOT_TEMPLATES=str(templates.resolve()), ADB=str(sdk / 'platform-tools/adb'),
                  APKSIGNER=str(build / 'apksigner'), ZIPALIGN=str(build / 'zipalign'),
                  AAPT=str(build / 'aapt'), EMULATOR=str(sdk / 'emulator/emulator'))
    managers = sorted((sdk / 'cmdline-tools').glob('*/bin/avdmanager'))
    if not managers:
        raise ValueError('SDK command-line tools/avdmanager are missing')
    result['AVDMANAGER'] = str(managers[-1])
    for key in ('ADB', 'APKSIGNER', 'ZIPALIGN', 'AAPT', 'EMULATOR'):
        if not Path(result[key]).is_file():
            raise ValueError(f'Missing installed SDK tool: {key}')
    for kind in ('debug', 'release'):
        if not (templates / f'android_{kind}.apk').is_file():
            raise ValueError('Verified Godot Android templates are missing')
    return result


def run(tools: dict, args: list[str], timeout: int = 120) -> str:
    return subprocess.check_output(args, env=local_environment(ROOT, tools), text=True,
                                   stderr=subprocess.STDOUT, timeout=timeout, stdin=subprocess.DEVNULL)


def prepare(args) -> dict:
    STATE.mkdir(parents=True, exist_ok=True)
    lock = json.loads((ROOT / '.github/android-local-tools.json').read_text())
    jdk = args.jdk
    if jdk is None:
        if platform.system() != 'Darwin' or platform.machine().lower() not in ('arm64', 'aarch64'):
            raise ValueError('Pass --jdk JDK17_HOME for this host; automatic JDK is macOS ARM64 only')
        config = lock['jdk_macos_arm64']
        archive = bootstrap.download(config['url'], STATE / 'jdk17.tar.gz', config['sha256'])
        java_dir = STATE / 'java'
        java_dir.mkdir(exist_ok=True)
        # Verify archive before trusting even an already extracted JDK.
        android_tools.safe_tar(archive, java_dir)
        jdk = next(java_dir.glob('*/Contents/Home'))
    config = bootstrap.CONFIG
    template_name = f'Godot_v{config["godot_version"]}-stable_export_templates.tpz'
    archive = bootstrap.download(config['godot_release'] + '/' + template_name,
                                 STATE / 'templates.tpz', config['godot_sha256'][template_name])
    bootstrap.safe_extract(archive, STATE, ['templates/android_debug.apk', 'templates/android_release.apk'])
    tools = tools_from_sdk(args.sdk_root, jdk, STATE / 'templates', lock['build_tools'])
    java_version = run(tools, [str(jdk / 'bin/java'), '-version'])
    if not re.search(r'version "17\.', java_version):
        raise ValueError('JDK17 is required')
    tools['GODOT'] = str(args.godot.resolve())
    if platform.system() == 'Darwin':
        ocr = STATE / 'macos-ocr'
        subprocess.run(['swiftc', '-module-cache-path', str(STATE / 'swift-cache'),
                        str(ROOT / 'scripts/ci/macos_ocr.swift'), '-o', str(ocr)], check=True)
        tools['GUNBOUND_OCR'] = str(ocr)
    TOOLS.write_text(json.dumps(tools, indent=2) + '\n')
    observed = {'host': platform.platform(), 'java': java_version, 'sdk': str(args.sdk_root),
                'build_tools': lock['build_tools'], 'sdk_modified': False,
                'sdk_metadata': {str(p.relative_to(args.sdk_root)): p.read_text()
                                 for p in [args.sdk_root / 'platform-tools/source.properties',
                                           args.sdk_root / 'emulator/source.properties',
                                           args.sdk_root / ('build-tools/' + lock['build_tools'] + '/source.properties')]
                                 if p.is_file()}}
    (STATE / 'local-toolchain.json').write_text(json.dumps(observed, indent=2) + '\n')
    print(f'Prepared isolated tools: {TOOLS}')
    return tools


def assert_avd(tools: dict, serial: str) -> None:
    emulator_port(serial)
    name = run(tools, [tools['ADB'], '-s', serial, 'emu', 'avd', 'name']).splitlines()[0]
    if name != AVD_NAME:
        raise ValueError(f'Expected this task AVD {AVD_NAME}, got {name}; refusing device writes')


def boot(tools: dict, serial: str, visible: bool = False) -> None:
    port = emulator_port(serial)
    # Reuse this AVD only; an occupied port belonging to another task is an error.
    try:
        assert_avd(tools, serial)
        print('Reusing dedicated AVD:', serial)
        return
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        pass
    with socket.socket() as probe:
        probe.bind(('127.0.0.1', port))
    abi = 'arm64-v8a' if platform.machine().lower() in ('arm64', 'aarch64') else 'x86_64'
    image = f'system-images;android-36;google_apis;{abi}'
    sdk_image = Path(tools['ANDROID_SDK_ROOT']).joinpath(*image.split(';'))
    if not sdk_image.is_dir():
        raise ValueError(f'Install {image} in an SDK before boot; this command never changes the supplied SDK')
    avd_home = Path(local_environment(ROOT, tools)['ANDROID_AVD_HOME'])
    avd_home.mkdir(parents=True, exist_ok=True)
    run(tools, [tools['AVDMANAGER'], 'create', 'avd', '--force', '--name', AVD_NAME,
                '--package', image, '--path', str(avd_home / (AVD_NAME + '.avd')), '--device', 'pixel_7'])
    command = [tools['EMULATOR'], '-avd', AVD_NAME, '-port', str(port), '-no-audio',
               '-no-snapshot', '-no-boot-anim', '-gpu', 'swiftshader', '-memory', '2048', '-cores', '2']
    if not visible:
        command.append('-no-window')
    with (STATE / 'emulator.log').open('wb') as output:
        process = subprocess.Popen(command, env=local_environment(ROOT, tools), stdout=output,
                                   stderr=subprocess.STDOUT, start_new_session=True)
    deadline = time.monotonic() + 300
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError('Emulator exited; see .tools/android-v1/emulator.log')
        try:
            if run(tools, [tools['ADB'], '-s', serial, 'shell', 'getprop', 'sys.boot_completed'], 10).strip() == '1':
                assert_avd(tools, serial)
                return
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            pass
        time.sleep(2)
    process.terminate()
    raise TimeoutError('Dedicated AVD did not boot within five minutes')


def open_apk(tools: dict, serial: str, apk: Path) -> dict:
    # An editor export may have stopped adb; wait for read-only reconnect,
    # never replay a mutating tap/Back command after transport failure.
    emulator_port(serial)
    run(tools, [tools['ADB'], '-s', serial, 'wait-for-device'], 30)
    assert_avd(tools, serial)
    package = android_package.APP_ID + '.ci'
    # Disposable CI package only; a new ephemeral certificate requires reinstall.
    badging = run(tools, [tools['AAPT'], 'dump', 'badging', str(apk)])
    if not badging.startswith("package: name='" + package + "'"):
        raise ValueError('Local installer accepts only the isolated CI application ID')
    run(tools, [tools['ADB'], '-s', serial, 'uninstall', package]) if package in run(tools, [tools['ADB'], '-s', serial, 'shell', 'pm', 'list', 'packages', package]) else None
    run(tools, [tools['ADB'], '-s', serial, 'install', str(apk)], 180)
    component = run(tools, [tools['ADB'], '-s', serial, 'shell', 'cmd', 'package', 'resolve-activity', '--brief', package]).strip().splitlines()[-1]
    launch = run(tools, [tools['ADB'], '-s', serial, 'shell', 'am', 'start', '-W', '-n', component])
    report = dict(apk=str(apk.resolve()), sha256=hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest(),
                  serial=serial, package=package, launch=launch,
                  api=run(tools, [tools['ADB'], '-s', serial, 'shell', 'getprop', 'ro.build.version.sdk']).strip(),
                  abi=run(tools, [tools['ADB'], '-s', serial, 'shell', 'getprop', 'ro.product.cpu.abi']).strip())
    (STATE / 'local-launch.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['prepare', 'build', 'boot', 'open', 'check'])
    parser.add_argument('--sdk-root', type=Path, default=Path(os.environ.get('ANDROID_SDK_ROOT', '/opt/homebrew/share/android-commandlinetools')))
    parser.add_argument('--jdk', type=Path)
    parser.add_argument('--godot', type=Path, default=Path('/Applications/Godot.app/Contents/MacOS/Godot'))
    parser.add_argument('--serial', default='emulator-5590')
    parser.add_argument('--visible', action='store_true')
    parser.add_argument('--mode', choices=['candidate', 'diagnostic'], default='candidate')
    parser.add_argument('--apk', type=Path)
    args = parser.parse_args()
    if args.action == 'prepare':
        prepare(args)
        return
    tools = json.loads(TOOLS.read_text())
    apk = args.apk or ROOT / f'builds/android/{args.mode}.apk'
    if args.action == 'build':
        subprocess.run([sys.executable, str(ROOT / 'scripts/build_android.py'), '--mode', args.mode,
                        '--tools', str(TOOLS), '--output', str(apk)], env=dict(os.environ, GODOT=tools['GODOT']), check=True)
    elif args.action == 'boot':
        boot(tools, args.serial, args.visible)
    elif args.action == 'open':
        open_apk(tools, args.serial, apk)
    else:
        run(tools, [tools['ADB'], '-s', args.serial, 'wait-for-device'])
        assert_avd(tools, args.serial)
        subprocess.run([sys.executable, str(ROOT / 'scripts/ci/android_ui_smoke.py'), '--serial', args.serial,
                        '--apk', str(apk), '--adb', tools['ADB'], '--app-id', android_package.APP_ID + '.ci',
                        '--version', android_package.project_version(ROOT),
                        '--output', str(STATE / 'local-ui-smoke')],
                       env=local_environment(ROOT, tools), check=True)


if __name__ == '__main__':
    main()
