import importlib.util
from pathlib import Path
import unittest

PATH=Path(__file__).resolve().parents[1]/'scripts/ci/android_ui_smoke.py'


class AndroidUISmokeTests(unittest.TestCase):
    def test_ocr_has_one_worker_without_changing_the_timeout_or_parent_environment(self):
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        with patch.dict(m.os.environ,{'OMP_THREAD_LIMIT':'8','OCR_TEST_MARKER':'preserved'}),patch.object(m.subprocess,'check_output',return_value='text') as run:
            self.assertEqual(m.ocr_output(['tesseract','screen.png','stdout']),'text')
            self.assertEqual(run.call_args.kwargs['env']['OMP_THREAD_LIMIT'],'1')
            self.assertEqual(run.call_args.kwargs['env']['OCR_TEST_MARKER'],'preserved')
            self.assertEqual(run.call_args.kwargs['timeout'],30)
            self.assertEqual(m.os.environ['OMP_THREAD_LIMIT'],'8')

    def test_ocr_passes_cannot_join_distant_camera_and_on_labels(self):
        import struct,tempfile,re
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        png=(Path(__file__).parent/'fixtures/android_ui/active_controls_api36.png').read_bytes()
        device=object.__new__(m.Device);device.observations=[];device.run=lambda *args,**kwargs:png
        with tempfile.TemporaryDirectory() as temp,patch.object(m.subprocess,'check_output',return_value='CAMERA'),patch.object(m,'enhanced_ocr',return_value='ON'),patch.object(m,'control_targets',return_value=[]):
            device.output=Path(temp)
            text=device.capture('camera',r'CAMERA')
            self.assertIsNone(re.search(m.CAMERA_ON_PATTERN,text,re.I))

    def test_os_onboarding_target_requires_system_package_title_and_unique_button(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        xml='<hierarchy><node package="com.android.systemui" text="Viewing full screen"/><node package="com.android.systemui" text="Got it" clickable="true" enabled="true" bounds="[840,165][916,215]"/></hierarchy>'
        self.assertEqual(m.system_tip_target(xml),dict(left=840,top=165,width=76,height=50,text='Got it'))
        self.assertIsNone(m.system_tip_target(xml.replace('com.android.systemui','com.chafy.gunboundrecomp.ci')))
        self.assertIsNone(m.system_tip_target(xml.replace('Viewing full screen','Game settings')))
        with self.assertRaises(ValueError):m.system_tip_target(xml.replace('</hierarchy>',xml.split('<hierarchy>')[1]))
        with self.assertRaises(ValueError):m.system_tip_target(xml.replace('[840,165][916,215]','[916,215][840,165]'))

    def test_camera_pan_reobserves_a_turn_reset_before_one_bounded_new_gesture(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        class Frames:
            size=(1280,800)
            actions_attempted=[]
            taps=[]
            swipes=[]
            reads=0
            def capture(self,label,pattern,**kwargs):
                self.reads+=1
                if self.reads==3:raise m.CaptureTimeout('Turn reset the camera')
                return 'CAMERA' if self.reads in [1,4] else 'CAMERA\nON'
            def tap_text(self,pattern,label):self.taps.append(pattern)
            def run(self,*args):self.swipes.append(args)
        frames=Frames()
        m.Device.pan_camera(frames,'solo')
        self.assertEqual(len(frames.swipes),2)
        self.assertEqual(len(frames.taps),2)
        self.assertEqual(frames.actions_attempted[-1]['outcome'],'gesture-delivered-camera-mode-visible')
        self.assertEqual(frames.actions_attempted[-1]['attempts'],2)

    def test_camera_on_can_wrap_inside_one_target_without_accepting_distant_words(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        header='level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n'
        camera='5\t1\t1\t1\t1\t1\t100\t100\t60\t16\t95\tCAMERA\n'
        on='5\t1\t2\t1\t1\t1\t120\t122\t20\t16\t95\tON\n'
        target=m.text_target(header+camera+on,m.CAMERA_ON_PATTERN)
        self.assertEqual((target['left'],target['top'],target['width'],target['height']),(100,100,60,38))
        self.assertEqual(m.text_target(header+camera+on,r'CAMERA')['height'],16)
        hinted_camera=camera.replace('\t100\t100\t60\t16\t','\t29\t67\t146\t26\t')
        hinted_on=on.replace('\t120\t122\t20\t16\t','\t73\t120\t52\t25\t')
        self.assertEqual(m.text_target(header+hinted_camera+hinted_on,m.CAMERA_ON_PATTERN)['text'],'CAMERA ON')
        for distant in [on.replace('\t122\t','\t500\t'),on.replace('\t120\t','\t500\t')]:
            with self.assertRaisesRegex(ValueError,'missing'):m.text_target(header+camera+distant,m.CAMERA_ON_PATTERN)
        duplicate=camera.replace('\t100\t100\t','\t500\t100\t')+on.replace('\t120\t','\t520\t')
        with self.assertRaisesRegex(ValueError,'ambiguous'):m.text_target(header+camera+on+duplicate,m.CAMERA_ON_PATTERN)

    def test_api24_logs_preserve_all_application_pids_without_new_cli_flags(self):
        import tempfile
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        class OldAndroid(m.Device):
            def __init__(self,output):self.output=output;self.calls=[]
            def run(self,*args):
                self.calls.append(args)
                if args==('shell','pidof','com.chafy.gunboundrecomp.ci'):return '222\n'
                if args==('shell','getprop','ro.build.version.sdk'):return '24\n'
                if args==('shell','am','get-current-user'):return '0\n'
                if args==('shell','dumpsys','package','com.chafy.gunboundrecomp.ci'):
                    return 'Packages:\n  Package [com.chafy.gunboundrecomp.ci] (abc):\n    userId=10123\n  Package [other.app] (def):\n    userId=10124\n'
                if args==('logcat','-d','-v','threadtime','-v','uid'):
                    return ('--------- beginning of main\n'
                            '11-15 12:00:00.001 10123 111 111 E godot: SCRIPT ERROR: earlier process\n'
                            '11-15 12:00:01.001 10124 333 333 I other: unrelated\n'
                            '11-15 12:00:02.001 10123 222 222 I godot: alive\n')
                raise AssertionError('Unsupported Android7 command: '+str(args))
        with tempfile.TemporaryDirectory() as temp:
            device=OldAndroid(Path(temp))
            with self.assertRaisesRegex(ValueError,'Android runtime error'):device.logs('com.chafy.gunboundrecomp.ci')
            logs=(Path(temp)/'logcat.txt').read_text()
            self.assertIn('earlier process',logs);self.assertIn('alive',logs);self.assertNotIn('unrelated',logs)

    def test_api24_log_parser_rejects_missing_uid_and_scopes_exact_package(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        dump='Packages:\n  Package [other.app] (a):\n    userId=10124\n  Package [wanted.app] (b):\n    userId=10123\nShared users:\n    userId=99999\n'
        self.assertEqual(m.legacy_package_uid(dump,'wanted.app'),'10123')
        with self.assertRaises(ValueError):m.legacy_package_uid(dump,'absent.app')
        with self.assertRaises(ValueError):m.legacy_uid_logs('11-15 12:00:00.001 111 111 I godot: UID missing\n','10123')
        self.assertEqual(m.legacy_uid_logs('--------- beginning of main\n','10123'),'')

    def test_camera_already_off_never_taps_an_obsolete_on_label(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        class Frames:
            actions_attempted=[]
            reads=0
            def capture(self,*args,**kwargs):self.reads+=1;return 'CAMERA\nPAUSE'
            def tap_text(self,*args,**kwargs):raise ValueError('OCR target is missing')
        frames=Frames();m.Device.disable_camera(frames,'solo')
        self.assertEqual(frames.reads,1)
        self.assertEqual(frames.actions_attempted[-1]['attempts'],0)

    def test_camera_off_resynchronizes_visible_state_with_bounded_actions(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        class Frames:
            actions_attempted=[]
            taps=[]
            reads=0
            def capture(self,label,pattern,**kwargs):
                self.reads+=1
                if self.reads==2:raise m.CaptureTimeout('Still CAMERA ON')
                return 'CAMERA ON\nPAUSE' if self.reads in [1,3] else 'CAMERA\nPAUSE'
            def tap_text(self,pattern,label):self.taps.append(pattern)
        frames=Frames()
        m.Device.disable_camera(frames,'solo')
        self.assertEqual(len(frames.taps),2)
        self.assertEqual(frames.actions_attempted[-1]['attempts'],2)

    def test_failed_new_run_cannot_leave_an_old_pass_report(self):
        import tempfile
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        with tempfile.TemporaryDirectory() as temp:
            output=Path(temp);report=output/'report.json';report.write_text('{"status":"passed"}')
            argv=['android_ui_smoke.py','--apk',str(output/'test.apk'),'--app-id','com.chafy.gunboundrecomp.ci','--version','0.20.5','--output',str(output)]
            with patch.object(m.sys,'argv',argv),patch.object(m,'Device',side_effect=RuntimeError('offline')):
                with self.assertRaisesRegex(RuntimeError,'offline'):m.main()
            self.assertFalse(report.exists(),'A failed rerun must remove the previous PASS')

    def test_camera_off_waits_for_rendered_on_label_to_disappear(self):
        import struct,tempfile
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        png=(Path(__file__).parent/'fixtures/android_ui/active_controls_api36.png').read_bytes()
        device=object.__new__(m.Device);device.observations=[]
        device.run=lambda *args,**kwargs:png
        with tempfile.TemporaryDirectory() as temp,patch.object(m.subprocess,'check_output',side_effect=['CAMERA ON\nPAUSE','CAMERA\nPAUSE']) as ocr,patch.object(m.time,'sleep'),patch.object(m,'enhanced_ocr',return_value=''),patch.object(m,'native_targets',return_value=[]),patch.object(m,'control_targets',return_value=[]):
            device.output=Path(temp)
            text=device.capture('camera-off',r'CAMERA',absent=r'CAMERA\s+ON')
            self.assertEqual(text.strip(),'CAMERA\nPAUSE')
            self.assertEqual(ocr.call_count,2)

    def test_smoke_rejects_personal_or_non_emulator_targets(self):
        self.assertTrue(PATH.exists(),'adb final APK smoke missing')
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        m.validate_emulator('emulator-5554','1','gunbound-ci-api36')
        m.validate_emulator('emulator-5590','1','gunbound_android_v1')
        for args in [('phone123','1','gunbound-ci-api36'),('emulator-5554','0','gunbound-ci-api36'),('emulator-5554','1','personal')]:
            with self.subTest(args=args),self.assertRaises(ValueError):
                m.validate_emulator(*args)

    def test_ui_coordinates_fit_uniformly_without_stretch(self):
        self.assertTrue(PATH.exists(),'adb final APK smoke missing')
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        self.assertEqual(m.point(640,400,(1280,800)),(640,400))
        self.assertEqual(m.point(640,400,(1920,1080)),(960,540))

    def test_rendered_screenshot_size_wins_over_physical_portrait(self):
        import struct
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        self.assertTrue(hasattr(m,'png_size'),'rendered screenshot dimensions missing')
        self.assertEqual(m.png_size(b'\x89PNG\r\n\x1a\n'+b'\x00\x00\x00\rIHDR'+struct.pack('>II',2400,1080)),(2400,1080))
        with self.assertRaises(ValueError):
            m.png_size(b'bad')

    def test_tsv_targets_use_rendered_regions_and_reject_absent_or_ambiguous_labels(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        self.assertTrue(hasattr(m,'text_target'),'OCR TSV target selection missing')
        header='level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n'
        tsv=header+'5\t1\t1\t1\t1\t1\t136\t900\t80\t30\t95\tSAVE\n'+'5\t1\t1\t1\t1\t2\t226\t900\t140\t30\t95\tCHANGES\n'
        target=m.text_target(tsv,r'SAVE CHANGES')
        self.assertEqual((target['left'],target['top'],target['width'],target['height']),(136,900,230,30))
        with self.assertRaisesRegex(ValueError,'missing'):
            m.text_target(tsv,r'CREATE')
        repeated=tsv+'5\t1\t2\t1\t1\t1\t700\t900\t80\t30\t95\tSAVE\n'
        with self.assertRaisesRegex(ValueError,'ambiguous'):
            m.text_target(repeated,r'SAVE')
        with self.assertRaises(ValueError):
            m.text_target('text\nCREATE\n',r'CREATE')

    def test_native_pause_popup_requires_option_content_and_ok(self):
        import re
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        self.assertTrue(hasattr(m,'OPTIONS_POPUP_PATTERN'),'Native options pause OCR oracle missing')
        self.assertIsNotNone(re.search(m.OPTIONS_POPUP_PATTERN,'Configuration\nSFX\nOK',re.I))
        self.assertIsNotNone(re.search(m.OPTIONS_POPUP_PATTERN,'Aiming Mode\nScroll\nOK',re.I))
        for text in ('Resume','Configuration','OK','CAMERA PAUSE'):
            self.assertIsNone(re.search(m.OPTIONS_POPUP_PATTERN,text,re.I))

    def test_system_tip_requires_exact_os_onboarding_signature(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        self.assertTrue(hasattr(m,'system_tip_visible'),'Specific OS full-screen onboarding recognition missing')
        self.assertTrue(m.system_tip_visible('Viewing full screen\nTo exit, swipe down from the top of your screen\nGot it'))
        for text in ('OK','Got it','Viewing full screen','SHOP\nTo exit swipe down\nGot it'):
            self.assertFalse(m.system_tip_visible(text))

    def test_system_tip_fade_is_polled_after_one_click(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        before='Viewing full screen\nTo exit, swipe down from the top of your screen\nGot it'
        class Frames:
            actions_attempted=[]
            clicks=[]
            remaining=iter([before,before,'AVATAR SHOP GOLD'])
            def system_tip_target(self):return None
            def capture(self,label):
                return next(self.remaining)
            def tap_text(self,pattern,label):
                self.clicks.append((pattern,label))
        frames=Frames()
        m.Device.dismiss_system_tips(frames)
        self.assertEqual(len(frames.clicks),1)
        self.assertEqual(frames.actions_attempted[-1]['action'],'dismiss-system-fullscreen-onboarding')

    def test_adb_failure_surfaces_output_without_retrying_keyevent(self):
        import subprocess
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        device=object.__new__(m.Device);device.adb='/test/adb';device.serial='emulator-5590'
        error=subprocess.CalledProcessError(1,['adb'],output='error: device offline; transport closed')
        with patch.object(m.subprocess,'check_output',side_effect=error) as boundary:
            with self.assertRaisesRegex(RuntimeError,'device offline; transport closed'):
                device.run('shell','input','keyevent','KEYCODE_BACK')
            self.assertEqual(boundary.call_count,1)

    def test_install_selects_file_transfer_only_for_api24(self):
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        device=object.__new__(m.Device);device.adb='/test/adb';device.serial='emulator-5590'
        apk=Path('builds/android/candidate.apk')
        for api,flags in [('24',['--no-streaming']),('36',[])]:
            with self.subTest(api=api),patch.object(m.subprocess,'check_output',side_effect=[f'{api}\n','Success\n']) as adb:
                device.install(apk)
                self.assertEqual([call.args[0][3:] for call in adb.call_args_list],[
                    ['shell','getprop','ro.build.version.sdk'],['install',*flags,'-r',str(apk)]])
                self.assertEqual(adb.call_args.kwargs['timeout'],120)

    def test_install_reports_partial_timeout_without_retrying(self):
        import subprocess
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        device=object.__new__(m.Device);device.adb='/test/adb';device.serial='emulator-5590'
        error=subprocess.TimeoutExpired(['adb','install'],120,output=b'Performing Push Install\n')
        with patch.object(m.subprocess,'check_output',side_effect=['24\n',error]) as adb:
            with self.assertRaisesRegex(RuntimeError,r'API 24.*120 s[\s\S]*Performing Push Install'):
                device.install(Path('candidate.apk'))
            self.assertEqual(adb.call_count,2)

    def test_constructor_waits_for_transport_before_reading_properties(self):
        from unittest.mock import patch
        import struct,tempfile
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        png=b'\x89PNG\r\n\x1a\n'+b'\x00\x00\x00\rIHDR'+struct.pack('>II',2400,1080)
        calls=[]
        def adb(command,**kwargs):
            args=command[3:];calls.append(args)
            if args==['wait-for-device']:return ''
            if args==['shell','getprop','ro.kernel.qemu']:return '1\n'
            if args==['emu','avd','name']:return 'gunbound_android_v1\nOK\n'
            if args==['exec-out','screencap','-p']:return png
            self.fail(f'Unexpected adb arguments: {args}')
        with tempfile.TemporaryDirectory() as temp,patch.object(m.subprocess,'check_output',side_effect=adb):
            m.Device('/test/adb','emulator-5590',Path(temp))
        self.assertEqual(calls[0],['wait-for-device'])
        calls.clear()
        with tempfile.TemporaryDirectory() as temp,patch.object(m.subprocess,'check_output',side_effect=adb):
            with self.assertRaises(ValueError):m.Device('/test/adb','personal-phone',Path(temp))
        self.assertFalse(calls)

    def test_final_logs_cover_prior_process_errors_for_same_app_uid(self):
        import tempfile
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        class LogHistory:
            def __init__(self,output):self.output=output;self.calls=[]
            def run(self,*args):
                self.calls.append(args)
                if args==('shell','pidof','com.chafy.gunboundrecomp.ci'):return '222\n'
                if args==('shell','getprop','ro.build.version.sdk'):return '36\n'
                if args==('shell','cmd','package','list','packages','-U','com.chafy.gunboundrecomp.ci'):return 'package:com.chafy.gunboundrecomp.ci uid:10123\n'
                if args==('logcat','-d','--uid=10123'):return '111: SCRIPT ERROR: previous process failed\n222: current process alive\n'
                if args==('logcat','-d','--pid=222'):return '222: current process alive\n'
                raise AssertionError(args)
        with tempfile.TemporaryDirectory() as temp:
            history=LogHistory(Path(temp))
            with self.assertRaisesRegex(ValueError,'Android runtime error'):
                m.Device.logs(history,'com.chafy.gunboundrecomp.ci')
            self.assertIn(('logcat','-d','--uid=10123'),history.calls)
            self.assertNotIn(('logcat','-d','--pid=222'),history.calls)

    def test_keyboard_visibility_uses_explicit_input_method_state(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        self.assertTrue(hasattr(m,'keyboard_visible'),'IME visibility synchronization missing')
        self.assertTrue(m.keyboard_visible('mInputShown=true\nmIsInputViewShown=true'))
        self.assertFalse(m.keyboard_visible('mInputShown=false\nmIsInputViewShown=true'))
        self.assertFalse(m.keyboard_visible('mInputShown=false\nmIsInputViewShown=false'))
        with self.assertRaises(ValueError):m.keyboard_visible('unknown state')

    def test_keyboard_dismiss_wait_polls_without_sending_another_back(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        self.assertTrue(hasattr(m.Device,'wait_keyboard'),'IME state polling missing')
        class InputMethod:
            states=iter(['mInputShown=true','mInputShown=false'])
            def run(self,*args):
                if args!=('shell','dumpsys','input_method'):raise AssertionError(args)
                return next(self.states)
        m.Device.wait_keyboard(InputMethod(),False)

    def test_keyboard_wait_retries_only_transient_read_not_input(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        class InputMethod:
            calls=0
            def run(self,*args):
                if args!=('shell','dumpsys','input_method'):raise AssertionError(args)
                self.calls+=1
                if self.calls==1:raise RuntimeError('dumpsys failed while IME connects')
                return 'mInputShown=false'
        source=InputMethod()
        m.Device.wait_keyboard(source,False)
        self.assertEqual(source.calls,2)

    def test_keyboard_open_waits_for_godot_input_connection(self):
        spec=importlib.util.spec_from_file_location('android_ui_test',PATH)
        m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
        class ConnectingInput:
            calls=0
            states=iter(['mInputShown=true\nmServedConnecting=true\nmServedInputConnection=null\nmServedView=org.godotengine.godot.input.GodotEditText',
                         'mInputShown=true\nmServedConnecting=false\nmServedInputConnection=RemoteInputConnection\nmServedView=org.godotengine.godot.input.GodotEditText'])
            def run(self,*args):
                if args!=('shell','dumpsys','input_method'):raise AssertionError(args)
                self.calls+=1
                return next(self.states)
        source=ConnectingInput()
        m.Device.wait_keyboard(source,True)
        self.assertEqual(source.calls,2)
