#!/usr/bin/env python3
"""Prepare the locked Linux Android toolchain exclusively under .tools.

Google publishes SHA1 and size in its official repository metadata; both are
locked, alongside the SHA256 of that metadata snapshot. No sdkmanager latest
resolution occurs. Archives are verified on every invocation and re-extracted
into fresh directories so a partial/poisoned extracted cache is never trusted.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tarfile
import tempfile
import sys
import time
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bootstrap


def validate_package(folder: Path, package: str, revision: str) -> None:
    source = folder / 'source.properties'
    if not source.is_file():
        raise ValueError(f'Incomplete SDK package: {package}')
    values = dict(line.split('=', 1) for line in source.read_text().splitlines()
                  if '=' in line and not line.lstrip().startswith('#'))
    values = {k.strip(): v.strip() for k, v in values.items()}
    if values.get('Pkg.Revision') != revision:
        raise ValueError(f'SDK revision mismatch: {package}')
    # Older archives omit Pkg.Path. The path is fixed by the lock/install map.
    if values.get('Pkg.Path', package) != package:
        raise ValueError(f'SDK package mismatch: {package}')


def register_emulator(folder: Path, revision: str) -> None:
    # Google's archive has source.properties but no installed-package manifest.
    # avdmanager's modern lookup does not discover this generic legacy package.
    validate_package(folder, 'emulator', revision)
    repository = ET.Element('ns2:repository', {
        'xmlns:ns2': 'http://schemas.android.com/repository/android/common/02',
        'xmlns:generic': 'http://schemas.android.com/repository/android/generic/02',
        'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance'})
    package = ET.SubElement(repository, 'localPackage', path='emulator', obsolete='false')
    ET.SubElement(package, 'type-details', {'xsi:type': 'generic:genericDetailsType'})
    version = ET.SubElement(package, 'revision')
    for name, value in zip(('major', 'minor', 'micro'), revision.split('.'), strict=True):
        ET.SubElement(version, name).text = value
    ET.SubElement(package, 'display-name').text = 'Android Emulator'
    ET.ElementTree(repository).write(folder / 'package.xml', encoding='utf-8', xml_declaration=True)


def safe_tar(archive: Path, destination: Path) -> None:
    destination=destination.resolve()
    with tarfile.open(archive) as source:
        # Validate the entire archive BEFORE writing even the first file.
        # Temurin uses legitimate relative links under legal/. Keep those,
        # while data_filter also checks actual link resolution during extract.
        for member in source.getmembers():
            target=destination / member.name
            if (member.isdev() or member.isfifo() or Path(member.name).is_absolute()
                    or ':' in member.name or not target.resolve().is_relative_to(destination)):
                raise ValueError('Unsafe JDK archive member')
            if member.issym() or member.islnk():
                base=target.parent if member.issym() else destination
                if (Path(member.linkname).is_absolute() or ':' in member.linkname
                        or not (base / member.linkname).resolve().is_relative_to(destination)):
                    raise ValueError('Unsafe JDK archive link')
        source.extractall(destination, filter='data')


def prepare(root: Path, emulator: bool = False) -> dict[str, str]:
    if (platform.system(), platform.machine().lower()) != ('Linux', 'x86_64'):
        raise ValueError('Pinned Android CI toolchain requires Linux/x86_64; local SDK must be supplied explicitly')
    config = bootstrap.CONFIG['android']
    cache = root / '.tools/cache/android'
    destination = root / '.tools/android'
    destination.mkdir(parents=True, exist_ok=True)
    jdk = config['java']
    archive = bootstrap.download(jdk['url'], cache / Path(jdk['url']).name, jdk['sha256'])
    with tempfile.TemporaryDirectory(dir=destination) as temp:
        safe_tar(archive, Path(temp))
        trees = list(Path(temp).iterdir())
        if len(trees) != 1 or not (trees[0] / 'bin/java').is_file():
            raise ValueError('Unexpected JDK archive layout')
        java = destination / 'jdk'
        shutil.rmtree(java, ignore_errors=True)
        shutil.move(str(trees[0]), java)
    version = subprocess.check_output([str(java / 'bin/java'), '-version'], stderr=subprocess.STDOUT, text=True)
    if jdk['version'].split('+')[0] not in version:
        raise ValueError('JDK version mismatch')
    sdk = destination / 'sdk'
    sdk.mkdir(exist_ok=True)
    for package in config['packages']:
        name = package['package']
        if not emulator and (name == 'emulator' or name.startswith('system-images;')):
            continue
        archive = bootstrap.download(package['url'], cache / Path(package['url']).name, package.get('sha256',package['sha1']), 'sha256' if package.get('sha256') else 'sha1')
        if archive.stat().st_size != package['size']:
            raise ValueError(f'SDK archive size mismatch: {name}')
        with tempfile.TemporaryDirectory(dir=destination) as temp:
            bootstrap.safe_extract(archive, Path(temp))
            roots = list(Path(temp).iterdir())
            if len(roots) != 1:
                raise ValueError(f'Unexpected SDK archive layout: {name}')
            tree = roots[0]
            validate_package(tree, name, package['revision'])
            target = sdk.joinpath(*name.split(';'))
            # Platform and build-tools archive roots differ from SDK names.
            if name.startswith('platforms;'):
                target = sdk / 'platforms' / name.split(';')[1]
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.rmtree(target, ignore_errors=True)
            shutil.move(str(tree), target)
            if name == 'emulator':
                register_emulator(target, package['revision'])
    build = sdk / 'build-tools' / config['build_tools']
    result = {'JAVA_HOME': str(java), 'ANDROID_SDK_ROOT': str(sdk), 'ANDROID_HOME': str(sdk),
              'GODOT_TEMPLATES': str(root / '.tools/android/templates'),
              'ADB': str(sdk / 'platform-tools/adb'), 'APKSIGNER': str(build / 'apksigner'),
              'ZIPALIGN': str(build / 'zipalign'), 'AAPT': str(build / 'aapt')}
    for key in ('ADB', 'APKSIGNER', 'ZIPALIGN', 'AAPT'):
        if not Path(result[key]).is_file():
            raise ValueError(f'Missing tool: {key}')
    if emulator:
        result['EMULATOR'] = str(sdk / 'emulator/emulator')
        result['AVDMANAGER'] = str(sdk / 'cmdline-tools/19.0/bin/avdmanager')
    return result


def image_package(api: int) -> str:
    if api not in (24,36):
        raise ValueError('Only the pinned API24/API36 emulator matrix is allowed')
    return f'system-images;android-{api};default;x86_64'


def write_modern_avd(sdk: Path, avd_home: Path, api: int) -> None:
    # API36 r02 ships data/ instead of userdata.img. The pinned CLI19 tries to
    # copy that obsolete file; Emulator37 itself creates ext4 from data/.
    image = sdk.joinpath(*image_package(api).split(';'))
    if api != 36 or not (image / 'data/empty_data_disk').is_file():
        raise ValueError('Expected the pinned API36 directory-based userdata image')
    name = f'gunbound-ci-api{api}'
    folder = avd_home / (name + '.avd')
    folder.mkdir(parents=True, exist_ok=True)
    config = {'AvdId': name, 'avd.ini.encoding': 'UTF-8', 'abi.type': 'x86_64',
              'hw.cpu.arch': 'x86_64', 'image.sysdir.1': str(image.relative_to(sdk)).replace('\\', '/')+'/',
              'tag.id': 'default', 'tag.display': 'Default Android System Image',
              'hw.keyboard': 'no', 'hw.gpu.enabled': 'yes', 'hw.gpu.mode': 'auto',
              'disk.dataPartition.size': '6G', 'fastboot.forceColdBoot': 'yes'}
    (folder / 'config.ini').write_text(''.join(f'{key}={value}\n' for key,value in config.items())+
                                     'hw.initialOrientation=landscape\n', encoding='utf-8')
    (avd_home / (name+'.ini')).write_text(f'avd.ini.encoding=UTF-8\npath={folder.resolve()}\ntarget=android-{api}\n', encoding='utf-8')


def boot(root: Path, tools: dict, api: int) -> None:
    image = image_package(api)
    name = f'gunbound-ci-api{api}'
    avd_home = root / '.tools/android/avd'
    avd_home.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(tools, ANDROID_AVD_HOME=str(avd_home), ANDROID_USER_HOME=str(root / '.tools/android/user'))
    if api == 36:
        write_modern_avd(Path(tools['ANDROID_SDK_ROOT']), avd_home, api)
    else:
        subprocess.run([tools['AVDMANAGER'],'create','avd','--force','--name',name,'--package',image,
                        '--path',str(avd_home / (name+'.avd'))],input='no\n',text=True,env=env,check=True,timeout=120)
    config = avd_home / (name+'.avd/config.ini')
    values=dict(line.split('=',1) for line in config.read_text(encoding='utf-8').splitlines()
                if '=' in line and not line.lstrip().startswith('#'))
    values.update({'hw.keyboard':'no','hw.lcd.width':'1280','hw.lcd.height':'800',
                   'hw.lcd.density':'160','hw.initialOrientation':'landscape','hw.ramSize':'4096'})
    config.write_text(''.join(f'{key}={value}\n' for key,value in values.items()),encoding='utf-8')
    # The x86 PC machine also creates a PS/2 controller independently of
    # hw.keyboard. Suppress its keyboard port for this touchscreen fixture.
    # Android's loader appends these parameters to its generated command line.
    evidence = root / f'.tools/android-reports/boot-api{api}'
    evidence.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(config, evidence / 'config.ini')
    # Only one QEMU console can own stdio. Retrieve Logcat separately over ADB.
    console = ['-show-kernel'] if api == 24 else []
    with (root / f'.tools/android/emulator-api{api}.log').open('wb') as log:
        process = subprocess.Popen([tools['EMULATOR'],'-avd',name,'-port','5554','-no-window','-no-audio',
                                   '-no-boot-anim','-no-snapshot','-wipe-data','-gpu','swangle','-debug','init',
                                   *console,
                                   '-qemu','-append','i8042.nokbd'],
                                   env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
    deadline=time.monotonic()+300
    while time.monotonic()<deadline:
        code = process.poll()
        if code is not None:
            raise ValueError(f'API {api} emulator exited with {code}; inspect emulator log')
        try:
            result=subprocess.run([tools['ADB'],'-s','emulator-5554','shell','getprop','sys.boot_completed'],
                                  text=True,capture_output=True,timeout=15,env=env)
            observation = {'returncode': result.returncode, 'value': result.stdout.strip(),
                           'stderr': (result.stderr or '').strip()[:500]}
        except subprocess.TimeoutExpired:
            observation = {'timeout_seconds': 15}
            result = None
        with (evidence / 'boot-polls.jsonl').open('a', encoding='utf-8') as trace:
            trace.write(json.dumps({'unix_time': time.time(), **observation}) + '\n')
        if result is None:
            # ADB may connect before Android's property service responds.
            # Retry only this read within the original overall boot budget.
            time.sleep(2)
            continue
        if result.returncode==0 and result.stdout.strip()=='1':
            hardware = config.parent / 'hardware-qemu.ini'
            if hardware.is_file():
                shutil.copyfile(hardware, evidence / hardware.name)
            observation_status={}
            for filename,args in [('input-devices.txt',['cat','/proc/bus/input/devices']),
                              ('kernel-command-line.txt',['cat','/proc/cmdline']),
                              ('input-service.txt',['dumpsys','input'])]:
                try:
                    observed=subprocess.run([tools['ADB'],'-s','emulator-5554','shell',*args],
                                            text=True,capture_output=True,timeout=30,env=env,check=False)
                    (evidence/filename).write_text(observed.stdout or '',encoding='utf-8')
                    (evidence/(filename+'.stderr')).write_text(observed.stderr or '',encoding='utf-8')
                    observation_status[filename]={'returncode':observed.returncode}
                except subprocess.TimeoutExpired:
                    observation_status[filename]={'returncode':None,'timeout_seconds':30}
            (evidence/'input-observation-status.json').write_text(json.dumps(observation_status,indent=2)+'\n',encoding='utf-8')
            subprocess.run([tools['ADB'],'-s','emulator-5554','shell','input','keyevent','82'],check=True,env=env)
            return
        time.sleep(2)
    # A small bounded snapshot before teardown also records offline/denied/timeout.
    # The serial console remains available even when adbd never comes up.
    try:
        for filename, args in [('transport', ['get-state']),
                               ('properties', ['shell', 'getprop']),
                               ('logcat', ['logcat', '-b', 'all', '-d', '-t', '300'])]:
            with (evidence / (filename + '.txt')).open('wb') as output:
                try:
                    snapshot = subprocess.run([tools['ADB'], '-s', 'emulator-5554', *args],
                                              stdout=output, stderr=subprocess.STDOUT, timeout=4, env=env)
                    output.write(f'\n[exit {snapshot.returncode}]\n'.encode())
                except subprocess.TimeoutExpired:
                    output.write(b'\n[timed out after 4 seconds]\n')
    finally:
        process.terminate()
    raise TimeoutError('Android emulator boot timed out')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--emulator', action='store_true')
    parser.add_argument('--boot-api',type=int,choices=[24,36])
    args = parser.parse_args()
    if args.boot_api:
        values=json.loads((bootstrap.ROOT / '.tools/android-tools.json').read_text())
        boot(bootstrap.ROOT,values,args.boot_api)
        return
    values = prepare(bootstrap.ROOT, args.emulator)
    for key, value in values.items():
        if '\n' in value or '\r' in value:
            raise ValueError('Unsafe environment value')
        print(f'{key}={value}')
    if os.environ.get('GITHUB_ENV'):
        with Path(os.environ['GITHUB_ENV']).open('a') as output:
            output.writelines(f'{key}={value}\n' for key, value in values.items())
    (bootstrap.ROOT / '.tools/android-tools.json').write_text(json.dumps(values, indent=2) + '\n')


if __name__ == '__main__':
    main()
