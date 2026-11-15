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
    build = sdk / 'build-tools' / config['build_tools']
    result = {'JAVA_HOME': str(java), 'ANDROID_SDK_ROOT': str(sdk),
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


def boot(root: Path, tools: dict, api: int) -> None:
    image = image_package(api)
    name = f'gunbound-ci-api{api}'
    avd_home = root / '.tools/android/avd'
    avd_home.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(tools, ANDROID_AVD_HOME=str(avd_home), ANDROID_USER_HOME=str(root / '.tools/android/user'))
    subprocess.run([tools['AVDMANAGER'],'create','avd','--force','--name',name,'--package',image,
                    '--path',str(avd_home / (name+'.avd'))],input='no\n',text=True,env=env,check=True,timeout=120)
    config = avd_home / (name+'.avd/config.ini')
    with config.open('a') as output:
        output.write('\nhw.lcd.width=1280\nhw.lcd.height=800\nhw.lcd.density=160\nhw.initialOrientation=landscape\nhw.ramSize=4096\n')
    log = (root / f'.tools/android/emulator-api{api}.log').open('wb')
    process = subprocess.Popen([tools['EMULATOR'],'-avd',name,'-port','5554','-no-window','-no-audio',
                               '-no-boot-anim','-no-snapshot','-wipe-data','-gpu','swiftshader_indirect'],
                               env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
    deadline=time.monotonic()+300
    while time.monotonic()<deadline:
        if process.poll() is not None:
            raise ValueError('Android emulator exited; inspect emulator log')
        result=subprocess.run([tools['ADB'],'-s','emulator-5554','shell','getprop','sys.boot_completed'],
                              text=True,capture_output=True,timeout=15,env=env)
        if result.returncode==0 and result.stdout.strip()=='1':
            subprocess.run([tools['ADB'],'-s','emulator-5554','shell','input','keyevent','82'],check=True,env=env)
            return
        time.sleep(2)
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
