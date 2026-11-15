import importlib.util
from pathlib import Path
import sys
import unittest

CI = Path(__file__).resolve().parents[1] / 'scripts/ci'
sys.path.insert(0, str(CI))


class AndroidPackageTests(unittest.TestCase):
    def module(self):
        path = CI / 'android_package.py'
        self.assertTrue(path.exists(), 'APK inspection/export missing')
        spec = importlib.util.spec_from_file_location('android_package_tests', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_version_code_is_stable_and_bounded(self):
        m = self.module()
        self.assertEqual(m.version_code('0.20.5'), 20005)
        self.assertEqual(m.version_code('1.2.3'), 1002003)
        for value in ('1.2.1000', '1.1000.0', '0.0.0', '2101.0.0', '01.2.3', 'v1.2.3'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                m.version_code(value)

    def test_diagnostic_report_is_bound_to_current_run(self):
        import json
        m = self.module()
        token = 'a' * 32
        report = dict(token=token, version='1.2.3', cases=dict(shots=48,maps=66,jewel=22,ui=3),failures=0,profile_isolated=True)
        output = 'ANDROID DIAGNOSTIC: PASS\nANDROID DIAGNOSTIC JSON: ' + json.dumps(report)
        self.assertEqual(m.diagnostic_report(output, token, '1.2.3'), report)
        for broken in (output.replace(token,'b'*32), output+'\nSCRIPT ERROR: broken',output.replace('48','47')):
            with self.assertRaises(ValueError):
                m.diagnostic_report(broken,token,'1.2.3')

    def test_distribution_signing_never_falls_back_to_debug(self):
        m = self.module()
        with self.assertRaisesRegex(ValueError,'signing'):
            m.signing_config({}, distribution=True)
        with self.assertRaisesRegex(ValueError,'main'):
            m.signing_config(dict(GITHUB_EVENT_NAME='pull_request',GITHUB_REF='refs/heads/main'), distribution=True)

    def test_unsigned_export_clears_all_debug_credentials(self):
        m=self.module()
        env=m.unsigned_environment({'GODOT_ANDROID_KEYSTORE_DEBUG_PATH':'private','GODOT_ANDROID_KEYSTORE_DEBUG_USER':'alias','GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD':'secret','JAVA_HOME':'jdk'})
        self.assertEqual(env,{'JAVA_HOME':'jdk'})

    def test_manifest_requires_exact_final_apk_smoke_and_x86_abi(self):
        import tempfile,hashlib
        m=self.module()
        self.assertTrue(hasattr(m,'write_manifest'),'Android manifest builder missing')
        with tempfile.TemporaryDirectory() as temp:
            apk=Path(temp)/'app.apk';apk.write_bytes(b'apk')
            digest=hashlib.sha256(b'apk').hexdigest()
            final=dict(status='passed',kind='final-ui',apk_sha256=digest,executed_abi='x86_64',version='1.2.3')
            diagnostic=dict(status='passed',kind='diagnostic',version='1.2.3',results=dict(cases=dict(shots=48,maps=66,jewel=22,ui=3),profile_isolated=True,failures=0))
            with self.assertRaises(ValueError):
                m.write_manifest(apk,{},diagnostic,dict(final,apk_sha256='f'*64),'1.2.3','a'*40)
            with self.assertRaises(ValueError):
                m.write_manifest(apk,{},diagnostic,dict(final,executed_abi='arm64-v8a'),'1.2.3','a'*40)

    def test_legacy_preset_uses_template_apis_without_gradle_override(self):
        m=self.module();text=m.preset_text(CI.parents[1],'1.2.3','candidate','')
        self.assertIn('gradle_build/min_sdk=""',text)
        self.assertIn('gradle_build/target_sdk=""',text)

    def test_runtime_room_reference_is_kept_but_oracle_reference_is_banned(self):
        m=self.module()
        self.assertTrue(hasattr(m,'validate_entry'),'Precise APK exclusion validation missing')
        m.validate_entry('assets/assets/classic/room/reference/catalog.json')
        for name in ('assets/assets/xfs/reference/avatar.xfs','assets/tests/test_map.gd','assets/override.cfg','../escape'):
            with self.subTest(name=name),self.assertRaises(ValueError):
                m.validate_entry(name)

    def test_diagnostic_user_args_follow_engine_args_in_exported_apk(self):
        import struct
        m=self.module()
        self.assertTrue(hasattr(m,'normalize_diagnostic_args'),'Diagnostic engine/user arg separation missing')
        prefix=['--','--ci-smoke','--ci-version','1.2.3','--ci-run','a'*32]
        engine=['--xr_mode_regular','--xr-mode','off','--fullscreen','--background_color','#000000']
        def encode(args):
            return struct.pack('<I',len(args))+b''.join(struct.pack('<I',len(arg.encode()))+arg.encode() for arg in args)
        self.assertEqual(m.normalize_diagnostic_args(encode(prefix+engine),'1.2.3','a'*32),encode(engine+prefix))
        for args in (prefix+['--ci-profile','/real/profile'],prefix[:-1]+['b'*32]+engine):
            with self.assertRaises(ValueError):
                m.normalize_diagnostic_args(encode(args),'1.2.3','a'*32)

    def test_apk_manifest_requires_pinned_godot_landscape_mapping(self):
        m=self.module()
        self.assertTrue(hasattr(m,'validate_manifest_xml'),'APK orientation inspection missing')
        m.validate_manifest_xml('A: android:screenOrientation(0x0101001e)=(type 0x10)0xb')
        for value in ('','A: android:screenOrientation(0x0101001e)=(type 0x10)0xd','A: android:screenOrientation(0x0101001e)=(type 0x10)0x6'):
            with self.assertRaises(ValueError):
                m.validate_manifest_xml(value)

    def test_diagnostic_gl_texture_errors_invalidate_pass(self):
        import json
        m=self.module();token='a'*32
        report=dict(token=token,version='1.2.3',cases=dict(shots=48,maps=66,jewel=22,ui=3),failures=0,profile_isolated=True)
        output='ANDROID DIAGNOSTIC: PASS\nANDROID DIAGNOSTIC JSON: '+json.dumps(report)
        for error in ('GL ERROR: GL_INVALID_VALUE','Condition "width > max_texture_size" is true.'):
            with self.subTest(error=error),self.assertRaises(ValueError):
                m.diagnostic_report(output+'\n'+error,token,'1.2.3')

    def test_preview_catalog_requires_all_22_imported_runtime_frames(self):
        m=self.module()
        self.assertTrue(hasattr(m,'validate_preview_catalog'),'Android preview import validation missing')
        catalog=dict(schema=1,frame_size=[544,336],source=dict(file='assets/hd/classic/room_smooth_4x/room/details/maps.png',sha256='a'*64),frames=[dict(index=i,file=f'map_{i:02d}.png',sha256='b'*64) for i in range(22)])
        names={f'assets/assets/hd/classic/android_map_previews/map_{i:02d}.png.import' for i in range(22)}
        m.validate_preview_catalog(catalog,names)
        with self.assertRaises(ValueError):
            m.validate_preview_catalog(dict(catalog,frames=catalog['frames'][:-1]),names)
        with self.assertRaises(ValueError):
            m.validate_preview_catalog(catalog,names-{'assets/assets/hd/classic/android_map_previews/map_21.png.import'})

    def test_all_presets_export_dynamic_android_preview_catalog(self):
        text=(CI.parents[1]/'export_presets.cfg').read_text()
        includes=[line for line in text.splitlines() if line.startswith('include_filter=')]
        self.assertEqual(len(includes),3)
        self.assertTrue(all('assets/hd/classic/android_map_previews/catalog.json' in line for line in includes))

    def test_portable_editor_settings_keep_existing_adb_server_alive(self):
        m=self.module()
        self.assertTrue(hasattr(m,'editor_settings_text'),'Isolated editor settings generator missing')
        text=m.editor_settings_text(dict(JAVA_HOME='/isolated/jdk',ANDROID_SDK_ROOT='/isolated/sdk'))
        self.assertIn('export/android/shutdown_adb_on_exit = false',text)
        self.assertIn('export/android/java_sdk_path = "/isolated/jdk"',text)
        self.assertIn('export/android/android_sdk_path = "/isolated/sdk"',text)

    def test_test_apks_are_visibly_distinct_from_distribution(self):
        m=self.module()
        for mode in ('diagnostic','candidate'):
            text=m.preset_text(CI.parents[1],'1.2.3',mode,'a'*32)
            self.assertIn('package/name="Gunbound Recomp Test"',text)
            self.assertIn('package/unique_name="com.chafy.gunboundrecomp.ci"',text)
        self.assertIn('package/name="Gunbound Recomp"',m.preset_text(CI.parents[1],'1.2.3','distribution',''))

    def test_export_requires_exact_pinned_godot_release(self):
        m=self.module()
        self.assertTrue(hasattr(m,'verify_editor_version'),'Pinned editor version verification missing')
        m.verify_editor_version('4.7.2.stable.official.abcdef123')
        for version in ('4.7.1.stable.official.abc','4.7.2.dev.official.abc','4.8.stable.official.abc','4.7.2.stable-malformed'):
            with self.subTest(version=version),self.assertRaises(ValueError):
                m.verify_editor_version(version)

    def test_android_manifest_records_pinned_godot(self):
        import tempfile,hashlib,json
        m=self.module()
        with tempfile.TemporaryDirectory() as temp:
            apk=Path(temp)/'app.apk';apk.write_bytes(b'apk')
            digest=hashlib.sha256(b'apk').hexdigest()
            final=dict(status='passed',kind='final-ui',apk_sha256=digest,executed_abi='x86_64',version='1.2.3')
            diagnostic=dict(status='passed',kind='diagnostic',version='1.2.3',results=dict(cases=dict(shots=48,maps=66,jewel=22,ui=3),profile_isolated=True,failures=0))
            manifest=m.write_manifest(apk,{},diagnostic,final,'1.2.3','a'*40)
            self.assertEqual(json.loads(manifest.read_text()).get('godot'),'4.7.2')
