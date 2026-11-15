#!/usr/bin/env python3
"""Export and inspect Android candidates; publication is a separate trusted gate."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import struct
import sys
import tempfile
import uuid
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parent))
from package_common import NOTICES, project_version

ROOT = Path(__file__).resolve().parents[2]
GODOT_VERSION = json.loads((ROOT / '.github/ci-tools.json').read_text())['godot_version']
APP_ID = 'com.chafy.gunboundrecomp'
ABIS = {'arm64-v8a': 183, 'x86_64': 62}
ERRORS = re.compile(r'SCRIPT ERROR:|Parse Error:|FATAL EXCEPTION|ANR in |Fatal signal|Failed to load script|GL[ _]ERROR|GL_INVALID_|(?:width|height)\s*>\s*max_texture_size', re.I)


def version_code(version: str) -> int:
    if not re.fullmatch(r'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)', version):
        raise ValueError('Expected numeric SemVer')
    major, minor, patch = map(int, version.split('.'))
    code = major * 1000000 + minor * 1000 + patch
    if max(major, minor, patch) > 999 or not 0 < code <= 2100000000:
        raise ValueError('Android version components/code out of range')
    return code


def diagnostic_report(output: str, token: str, version: str) -> dict:
    reports = [line.split('ANDROID DIAGNOSTIC JSON: ', 1)[1] for line in output.splitlines()
               if 'ANDROID DIAGNOSTIC JSON: ' in line]
    if (not re.fullmatch('[0-9a-f]{32}', token) or len(reports) != 1
            or 'ANDROID DIAGNOSTIC: PASS' not in output or ERRORS.search(output)):
        raise ValueError('Android diagnostic failed or missing/ambiguous report')
    report = json.loads(reports[0])
    expected = dict(token=token, version=version, cases=dict(shots=48,maps=66,jewel=22,ui=3),
                    failures=0, profile_isolated=True)
    if any(report.get(key) != value for key, value in expected.items()):
        raise ValueError('Android diagnostic report mismatch')
    return report


def signing_config(env: dict, distribution: bool) -> dict:
    if not distribution:
        return {}
    if env.get('GITHUB_EVENT_NAME') != 'push' or env.get('GITHUB_REF') != 'refs/heads/main':
        if env.get('GITHUB_EVENT_NAME'):
            raise ValueError('Distribution signing is restricted to main push')
    required = ('ANDROID_KEYSTORE', 'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD', 'ANDROID_KEYSTORE_PASSWORD', 'ANDROID_CERT_SHA256')
    if any(not env.get(key) for key in required):
        raise ValueError('Persistent Android signing inputs are required; no debug fallback')
    if not re.fullmatch('[0-9a-fA-F]{64}', env['ANDROID_CERT_SHA256']):
        raise ValueError('Invalid signing certificate fingerprint')
    if not Path(env['ANDROID_KEYSTORE']).is_file():
        raise ValueError('Persistent signing keystore missing')
    return {key: env[key] for key in required}


def command(args: list[str], **kwargs) -> str:
    try:
        return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT, timeout=900, **kwargs)
    except subprocess.CalledProcessError as error:
        output=error.output or ''
        for key,value in kwargs.get('env',{}).items():
            if value and ('PASSWORD' in key or 'SECRET' in key or 'TOKEN' in key):
                output=output.replace(value,'[redacted]')
        raise RuntimeError(f'{Path(args[0]).name} failed ({error.returncode}):\n{output[-8000:]}') from None


def validate_entry(name: str) -> None:
    path=PurePosixPath(name)
    if path.is_absolute() or '..' in path.parts or ':' in name or '\\' in name:
        raise ValueError('Unsafe APK entry')
    if (any(part in {'.tools','.github','tests','builds'} for part in path.parts)
            or path.name in {'override.cfg','export_credentials.cfg','.env'}
            or name.startswith('assets/assets/xfs/reference/')):
        raise ValueError(f'Private/source APK entry: {name}')


def validate_manifest_xml(xml: str) -> None:
    orientations=re.findall(r'android:screenOrientation[^\n]*?\(type 0x10\)0x([0-9a-fA-F]+)',xml)
    if orientations!=['b']:
        raise ValueError('APK must declare pinned Godot sensor-landscape mapping: Android userLandscape (11)')


def validate_preview_catalog(catalog: dict, names: set[str]) -> None:
    if (catalog.get('schema')!=1 or catalog.get('frame_size')!=[544,336]
            or catalog.get('source',{}).get('file')!='assets/hd/classic/room_smooth_4x/room/details/maps.png'
            or not re.fullmatch('[0-9a-f]{64}',catalog.get('source',{}).get('sha256',''))):
        raise ValueError('Android map preview catalog metadata invalid')
    frames=catalog.get('frames',[])
    if len(frames)!=22:
        raise ValueError('Android map preview catalog must contain 22 frames')
    for index,frame in enumerate(frames):
        filename=f'map_{index:02d}.png'
        if (frame.get('index')!=index or frame.get('file')!=filename
                or not re.fullmatch('[0-9a-f]{64}',frame.get('sha256',''))
                or f'assets/assets/hd/classic/android_map_previews/{filename}.import' not in names):
            raise ValueError(f'Missing/invalid imported Android map preview: {index}')


def inspect_apk(apk: Path, tools: dict, version: str, app_id: str,
                certificate: str | None = None, diagnostic: bool = False) -> dict:
    """Inspect actual APK bytes, including Godot asset remaps and each ELF ABI."""
    signature = command([tools['APKSIGNER'], 'verify', '--verbose', '--print-certs', str(apk)])
    matches = re.findall(r'Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]+)', signature)
    if len(matches) != 1 or (certificate and matches[0].lower() != certificate.lower()):
        raise ValueError('APK certificate mismatch')
    command([tools['ZIPALIGN'], '-c', '-P', '16', '-v', '4', str(apk)])
    badging = command([tools['AAPT'], 'dump', 'badging', str(apk)])
    validate_manifest_xml(command([tools['AAPT'],'dump','xmltree',str(apk),'AndroidManifest.xml']))
    match = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    if not match or match.groups() != (app_id, str(version_code(version)), version):
        raise ValueError('APK package/version mismatch')
    if "sdkVersion:'24'" not in badging or "targetSdkVersion:'36'" not in badging:
        raise ValueError('APK API mismatch')
    if not diagnostic and 'application-debuggable' in badging:
        raise ValueError('Distribution/candidate APK is debuggable')
    if 'uses-permission:' in badging:
        raise ValueError('Unexpected Android permission')
    with zipfile.ZipFile(apk) as source:
        names = source.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate APK entries')
        for name in names:
            validate_entry(name)
        libraries = [n for n in names if n.startswith('lib/') and n.endswith('.so')]
        if {n.split('/')[1] for n in libraries} != set(ABIS):
            raise ValueError('APK ABI set mismatch')
        for name in libraries:
            with source.open(name) as library:
                header = library.read(20)
            if len(header) != 20 or header[:6] != b'\x7fELF\x02\x01' or int.from_bytes(header[18:20], 'little') != ABIS[name.split('/')[1]]:
                raise ValueError(f'APK ELF architecture mismatch: {name}')
        for notice in NOTICES:
            name = 'assets/assets/licenses/' + NOTICES[notice]
            if name not in names or source.read(name) != (ROOT / notice).read_bytes():
                raise ValueError(f'Missing/changed packaged license: {notice}')
        # APK exports loose Godot resources; remapped imported textures must be
        # inspected through their .remap/.import entries, not source PNG names.
        required = ['assets/project.binary', 'assets/scenes/main.tscn.remap',
                    'assets/assets/hd/classic/android_map_previews/catalog.json',
                    'assets/assets/xfs/maps/catalog.json', 'assets/assets/xfs/avatars/catalog.json']
        for name in required:
            if name not in names or not source.getinfo(name).file_size:
                raise ValueError(f'Missing Android runtime resource: {name}')
        validate_preview_catalog(json.loads(source.read('assets/assets/hd/classic/android_map_previews/catalog.json')),set(names))
        remaps = [n for n in names if n.startswith('assets/') and n.endswith(('.remap','.import'))]
        for name in remaps:
            text = source.read(name).decode('utf-8', errors='replace')
            for target in re.findall(r'"res://([^"\n]+)"', text):
                if 'assets/' + target not in names:
                    raise ValueError(f'Unresolved packaged remap: {target}')
        args = source.read('assets/_cl_') if 'assets/_cl_' in names else b''
        if not diagnostic and any(flag in args for flag in (b'--ci-smoke',b'--ci-run',b'--ci-version',b'android_ci',b'--remote-debug')):
            raise ValueError('Final APK contains diagnostic launch arguments')
    return dict(package_id=app_id, version_code=version_code(version), min_sdk=24, target_sdk=36,
                abis=sorted(ABIS), certificate_sha256=matches[0].lower(), signature='verified',
                alignment='16k-verified', orientation='userLandscape', resources='verified', licenses='verified')


def preset_text(root: Path, version: str, mode: str, token: str) -> str:
    source = (root / 'export_presets.cfg').read_text()
    match = re.search(r'(?ms)^\[preset\.(\d+)\]\nname="Android"\n.*?(?=^\[preset\.\d+\]\n|\Z)', source)
    if not match:
        raise ValueError('Android preset missing')
    preset = match[0]
    preset = re.sub(r'\[preset\.\d+', '[preset.0', preset)
    preset = re.sub(r'version/name="[^"]*"', f'version/name="{version}"', preset)
    preset = re.sub(r'version/code=\d+', f'version/code={version_code(version)}', preset)
    app_id = APP_ID if mode == 'distribution' else APP_ID + '.ci'
    preset = re.sub(r'package/unique_name="[^"]*"', f'package/unique_name="{app_id}"', preset)
    if mode != 'distribution':
        preset = re.sub(r'package/name="[^"]*"', 'package/name="Gunbound Recomp Test"', preset)
    if mode == 'diagnostic':
        preset = preset.replace('custom_features=""', 'custom_features="android_ci"')
        preset = preset.replace('command_line/extra_args=""', f'command_line/extra_args="-- --ci-smoke --ci-version {version} --ci-run {token}"')
    return preset


def normalize_diagnostic_args(payload: bytes, version: str, token: str) -> bytes:
    if len(payload)<4 or len(payload)>65536:
        raise ValueError('Malformed Android command line')
    count=struct.unpack_from('<I',payload)[0]
    args=[];offset=4
    for _ in range(count):
        if offset+4>len(payload):
            raise ValueError('Truncated Android command line')
        length=struct.unpack_from('<I',payload,offset)[0];offset+=4
        if offset+length>len(payload):
            raise ValueError('Truncated Android command line argument')
        args.append(payload[offset:offset+length].decode('utf-8'));offset+=length
    prefix=['--','--ci-smoke','--ci-version',version,'--ci-run',token]
    engine=['--xr_mode_regular','--xr-mode','off','--fullscreen','--background_color','#000000']
    if offset!=len(payload) or args!=prefix+engine:
        raise ValueError('Unexpected pinned Android diagnostic command line')
    # Godot 4.7.2 appends engine options after custom extra_args. Move those
    # before the separator so strict get_cmdline_user_args() stays sandboxed.
    args=engine+prefix
    return struct.pack('<I',len(args))+b''.join(struct.pack('<I',len(arg.encode()))+arg.encode() for arg in args)


def normalize_diagnostic_apk(apk: Path, version: str, token: str) -> None:
    target=apk.with_suffix('.args.apk')
    with zipfile.ZipFile(apk) as source, zipfile.ZipFile(target,'w') as output:
        if source.namelist().count('assets/_cl_')!=1:
            raise ValueError('Missing/ambiguous Android diagnostic command line')
        for entry in source.infolist():
            if entry.filename=='assets/_cl_':
                output.writestr(entry,normalize_diagnostic_args(source.read(entry),version,token))
            else:
                with source.open(entry) as incoming, output.open(entry,'w') as outgoing:
                    shutil.copyfileobj(incoming,outgoing)
    target.replace(apk)


def unsigned_environment(environment: dict) -> dict:
    result = environment.copy()
    for suffix in ('PATH','USER','PASSWORD'):
        result.pop('GODOT_ANDROID_KEYSTORE_DEBUG_' + suffix, None)
        result.pop('GODOT_ANDROID_KEYSTORE_RELEASE_' + suffix, None)
    return result


def verify_editor_version(output: str) -> None:
    # Godot prints <major.minor.patch>.<status>.<build>.<revision>. Require the
    # pinned release before the editor imports/exports any project resources.
    if not re.fullmatch(re.escape(GODOT_VERSION)+r'\.stable\.[A-Za-z0-9_-]+\.[A-Za-z0-9]+',output.strip()):
        raise ValueError(f'Android export requires pinned Godot {GODOT_VERSION}.stable editor')


def editor_settings_text(tools: dict) -> str:
    return ('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
            f'export/android/java_sdk_path = {json.dumps(tools["JAVA_HOME"])}\n'
            f'export/android/android_sdk_path = {json.dumps(tools["ANDROID_SDK_ROOT"])}\n'
            'export/android/shutdown_adb_on_exit = false\n')


def export_apk(root: Path, godot: str, tools: dict, output: Path, mode: str, token: str = '') -> dict:
    if mode not in ('diagnostic','candidate','distribution'):
        raise ValueError('Unknown Android package mode')
    version = project_version(root)
    signing = signing_config(os.environ, mode == 'distribution')
    if mode == 'diagnostic' and not re.fullmatch('[0-9a-f]{32}',token):
        raise ValueError('Diagnostic export needs a fresh token')
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    # Use a disposable project mirror to avoid rewriting the user's preset or
    # credentials and to keep diagnostic feature/args out of final exports.
    with tempfile.TemporaryDirectory(prefix='android-export-', dir=root / '.tools') as temp:
        staging = Path(temp) / 'project'
        staging.mkdir()
        for name in ('assets','locales','scenes','scripts','.godot'):
            if (root / name).exists():
                (staging / name).symlink_to(root / name, target_is_directory=True)
        shutil.copy2(root / 'project.godot', staging / 'project.godot')
        preset = preset_text(root,version,mode,token)
        if tools.get('GODOT_TEMPLATES'):
            for kind in ('debug','release'):
                path = Path(tools['GODOT_TEMPLATES']) / f'android_{kind}.apk'
                if not path.is_file():
                    raise ValueError('Missing Android custom template')
                preset = preset.replace(f'custom_template/{kind}=""', f'custom_template/{kind}={json.dumps(str(path))}')
        (staging / 'export_presets.cfg').write_text(preset)
        # Portable editor copy + _sc_ is Godot's documented self-contained
        # mechanism; works on macOS too and never rewrites user settings.
        editor = Path(temp) / 'editor'
        editor.mkdir()
        local_godot = editor / Path(godot).name
        shutil.copy2(shutil.which(godot) or godot, local_godot)
        if sys.platform == 'darwin':
            # A copied Mach-O may retain an invalid signature on macOS.
            # Sign only this disposable editor, never the installed app.
            command(['codesign', '--force', '--sign', '-', str(local_godot)])
        verify_editor_version(command([str(local_godot),'--version']))
        (editor / '_sc_').write_text('')
        editor_settings = editor / 'editor_data'
        editor_settings.mkdir()
        (editor_settings / 'editor_settings-4.7.tres').write_text(editor_settings_text(tools))
        env = os.environ.copy()
        env.update(tools)
        env = unsigned_environment(env)
        # Export unsigned, then sign with apksigner so no credential enters a
        # preset or log. Candidate gets only a disposable test certificate.
        text = (staging / 'export_presets.cfg').read_text().replace('package/signed=true','package/signed=false')
        (staging / 'export_presets.cfg').write_text(text)
        log = command([str(local_godot),'--headless','--path',str(staging), '--export-debug' if mode=='diagnostic' else '--export-release','Android',str(output)],env=env)
        if ERRORS.search(log) or not output.is_file():
            raise ValueError('Android export failed: ' + log[-2000:])
        if mode=='diagnostic':
            normalize_diagnostic_apk(output,version,token)
        key = signing.get('ANDROID_KEYSTORE')
        if not key:
            key = str(Path(temp) / 'candidate.keystore')
            command([str(Path(tools['JAVA_HOME']) / 'bin/keytool'),'-genkeypair','-keystore',key,
                     '-storepass','android','-keypass','android','-alias','androiddebugkey',
                     '-dname','CN=Gunbound CI Test','-keyalg','RSA','-keysize','2048','-validity','30'])
        env['APK_STORE_PASSWORD'] = signing.get('ANDROID_KEYSTORE_PASSWORD','android')
        env['APK_KEY_PASSWORD'] = signing.get('ANDROID_KEY_PASSWORD','android')
        unsigned = output.with_suffix('.unsigned.apk')
        output.rename(unsigned)
        aligned = output.with_suffix('.aligned.apk')
        command([tools['ZIPALIGN'],'-P','16','-f','4',str(unsigned),str(aligned)],env=env)
        command([tools['APKSIGNER'],'sign','--ks',key,'--ks-key-alias',signing.get('ANDROID_KEY_ALIAS','androiddebugkey'),
                 '--ks-pass','env:APK_STORE_PASSWORD','--key-pass','env:APK_KEY_PASSWORD','--out',str(output),str(aligned)],env=env)
        unsigned.unlink(); aligned.unlink()
    return inspect_apk(output,tools,version,APP_ID if mode=='distribution' else APP_ID+'.ci',
                       signing.get('ANDROID_CERT_SHA256'),mode=='diagnostic')


def write_manifest(apk: Path, inspection: dict, diagnostic: dict, final: dict,
                   version: str, commit: str) -> Path:
    with apk.open('rb') as source:
        digest=hashlib.file_digest(source,'sha256').hexdigest()
    if (not re.fullmatch('[0-9a-f]{40}',commit)
            or final.get('apk_sha256')!=digest or final.get('executed_abi')!='x86_64'
            or final.get('kind')!='final-ui' or final.get('status')!='passed'
            or final.get('version')!=version):
        raise ValueError('Final UI smoke does not identify this APK/version/x86_64 execution')
    result=diagnostic.get('results',{})
    if (diagnostic.get('kind')!='diagnostic' or diagnostic.get('status')!='passed'
            or diagnostic.get('version')!=version or result.get('failures')!=0
            or result.get('profile_isolated') is not True
            or result.get('cases')!=dict(shots=48,maps=66,jewel=22,ui=3)):
        raise ValueError('Android diagnostic evidence incomplete')
    data=dict(inspection,schema=2,platform='android',godot=GODOT_VERSION,version=version,commit=commit,
              file=apk.name,size=apk.stat().st_size,sha256=digest,smoke='passed',
              diagnostic='passed',final_x86_64='passed',arm64_acceptance='manual_gate_required')
    manifest=apk.with_suffix('.json')
    manifest.write_text(json.dumps(data,indent=2)+'\n')
    apk.with_suffix('.apk.sha256').write_text(f'{digest}  {apk.name}\n')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mode',choices=['diagnostic','candidate','distribution'],default='candidate')
    parser.add_argument('--output',type=Path)
    parser.add_argument('--token',default='')
    parser.add_argument('--finalize',action='store_true')
    parser.add_argument('--diagnostic-report',type=Path)
    parser.add_argument('--ui-report',type=Path)
    parser.add_argument('--commit')
    parser.add_argument('--tools',type=Path,default=ROOT / '.tools/android-tools.json')
    args = parser.parse_args()
    tools = json.loads(args.tools.read_text())
    token = args.token or uuid.uuid4().hex
    output = args.output or ROOT / f'builds/android/{args.mode}.apk'
    if args.finalize:
        if not args.output or not args.diagnostic_report or not args.ui_report or not args.commit:
            parser.error('--finalize requires output, both reports and commit')
        signing=signing_config(os.environ,args.mode=='distribution')
        inspection=inspect_apk(output,tools,project_version(ROOT),APP_ID if args.mode=='distribution' else APP_ID+'.ci',signing.get('ANDROID_CERT_SHA256'))
        write_manifest(output,inspection,json.loads(args.diagnostic_report.read_text()),json.loads(args.ui_report.read_text()),project_version(ROOT),args.commit)
        return
    result = export_apk(ROOT,os.environ.get('GODOT','godot'),tools,output,args.mode,token)
    report = dict(result,version=project_version(ROOT),mode=args.mode,token=token,
                  sha256=hashlib.file_digest(output.open('rb'),'sha256').hexdigest())
    output.with_suffix('.inspection.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
