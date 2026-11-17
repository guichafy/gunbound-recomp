import importlib.util
from pathlib import Path
import unittest
from PIL import Image,ImageEnhance

ROOT=Path(__file__).resolve().parents[1]
PATH=ROOT/'scripts/ci/android_native_ui.py'
FIXTURE=ROOT/'tests/fixtures/android_ui/lobby_api36.png'

class NativeUITests(unittest.TestCase):
    def test_resuming_options_waits_past_the_stale_popup_frame_before_back(self):
        import tempfile
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('ui_test',ROOT/'scripts/ci/android_ui_smoke.py')
        ui=importlib.util.module_from_spec(spec);spec.loader.exec_module(ui)
        class Device(ui.Device):
            def __init__(self,folder):
                self.output=folder;self.observations=[];self.reads=0;self.taps=[]
                self.frames=iter([(ROOT/'tests/fixtures/android_ui'/file).read_bytes() for file in ['options_api36.png','busy_controls_api36.png']])
            def tap_text(self,pattern,label):self.taps.append(pattern)
            def run(self,*args,**kwargs):
                if args==('exec-out','screencap','-p'):self.reads+=1;return next(self.frames)
                self.assert_back_after_running_frame=args==('shell','input','keyevent','KEYCODE_BACK') and self.reads==2
        with tempfile.TemporaryDirectory() as temp:
            device=Device(Path(temp))
            with patch.object(ui,'ocr_output',return_value='CAMERA'),patch.object(ui,'control_targets',return_value=[dict(text='CAMERA')]),patch.object(ui,'enhanced_ocr',return_value=''),patch.object(ui.time,'sleep'):
                device.resume_options('touch-resume')
            device.run('shell','input','keyevent','KEYCODE_BACK')
            self.assertEqual(device.taps,['OK'])
            self.assertEqual(device.reads,2)
            self.assertTrue(device.assert_back_after_running_frame)

    def test_control_locator_rejects_on_when_requesting_exact_camera_off(self):
        import tempfile
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('ui_test',ROOT/'scripts/ci/android_ui_smoke.py')
        ui=importlib.util.module_from_spec(spec);spec.loader.exec_module(ui)
        import android_native_ui
        header='level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n'
        rows='5\t1\t1\t1\t1\t1\t29\t67\t146\t26\t96\tCAMERA\n5\t1\t1\t1\t2\t1\t73\t120\t52\t25\t96\tON\n'
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/'screen.png';path.write_bytes((ROOT/'tests/fixtures/android_ui/active_controls_api36.png').read_bytes())
            region=dict(left=1064,top=100,width=47,height=48)
            with patch.object(android_native_ui,'control_regions',return_value=[region]),patch.object(ui.subprocess,'check_output',return_value=header+rows):
                self.assertEqual(ui.control_targets(path,r'CAMERA|C[ÂA]MERA'),[])
                self.assertEqual(ui.control_targets(path,r'CAMERA|C[ÂA]MERA',include_camera_state=True)[0]['text'],'CAMERA ON')
                self.assertEqual(ui.control_targets(path,ui.CAMERA_ON_PATTERN)[0]['text'],'CAMERA ON')

    def test_touch_control_regions_survive_busy_backgrounds_and_movement(self):
        m=self.module()
        for file in ['busy_controls_api36.png','active_controls_api36.png']:
            with Image.open(ROOT/'tests/fixtures/android_ui'/file) as image:
                regions=m.control_regions(image)
                self.assertTrue(any(abs(r['left']-1064)<=2 and abs(r['top']-100)<=2 for r in regions))
                moved=Image.new('RGB',image.size,(0,0,0));moved.paste(image.crop((1060,96,1118,155)),(40,200))
                self.assertTrue(any(42<=r['left']<=47 and 202<=r['top']<=207 for r in m.control_regions(moved)))

    def test_resume_panel_is_detected_from_pixels_and_can_move(self):
        m=self.module()
        with Image.open(ROOT/'tests/fixtures/android_ui/resume_api36.png') as image:
            self.assertEqual(m.bright_panels(image),[dict(left=440,top=320,width=400,height=96)])
            moved=Image.new('RGB',image.size,(0,0,0));moved.paste(image.crop((440,320,840,416)),(20,60))
            self.assertEqual(m.bright_panels(moved),[dict(left=20,top=60,width=400,height=96)])

    def test_resume_requires_recognized_text_and_reprojects_the_crop(self):
        import tempfile
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('ui_test',ROOT/'scripts/ci/android_ui_smoke.py')
        ui=importlib.util.module_from_spec(spec);spec.loader.exec_module(ui)
        header='level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n'
        row='5\t1\t1\t1\t1\t1\t519\t126\t180\t42\t95\tResume\n'
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/'screen.png';path.write_bytes((ROOT/'tests/fixtures/android_ui/resume_api36.png').read_bytes())
            with patch.object(ui.subprocess,'check_output',return_value=header+row):
                found=ui.resume_targets(path,ui.RESUME_PATTERN)
                self.assertEqual(found,[dict(left=609,top=358,width=60,height=14,text='Resume')])
            with patch.object(ui.subprocess,'check_output',return_value=header):self.assertEqual(ui.resume_targets(path,ui.RESUME_PATTERN),[])
            self.assertEqual(ui.resume_targets(path,'OK'),[])

    def test_native_options_ok_is_located_and_combines_with_observed_popup_text(self):
        m=self.module()
        fixture=ROOT/'tests/fixtures/android_ui/options_api36.png'
        with Image.open(fixture) as image:
            target=m.target(image,'OK')
            self.assertTrue(328<=target['left']<=333 and 660<=target['top']<=664)
            with self.assertRaisesRegex(ValueError,'missing'):m.target(ImageEnhance.Brightness(image).enhance(.35),'OK')
        with Image.open(ROOT/'assets/xfs/hud_options_fallback/NativeOptionOK.png') as strip:
            screen=Image.new('RGBA',(1280,800),(0,0,0,255))
            screen.alpha_composite(strip.convert('RGBA').crop((246,0,328,33)).resize((131,53),Image.Resampling.NEAREST),(100,100))
            with self.assertRaisesRegex(ValueError,'missing'):m.target(screen,'OK')
        spec=importlib.util.spec_from_file_location('ui_test',ROOT/'scripts/ci/android_ui_smoke.py')
        ui=importlib.util.module_from_spec(spec);spec.loader.exec_module(ui)
        self.assertEqual(ui.native_targets(fixture,ui.OPTIONS_POPUP_PATTERN)[0]['text'],'OK')

    def test_lint_sparse_checkout_contains_every_native_template_dependency(self):
        import tempfile,shutil,yaml
        m=self.module()
        data=yaml.safe_load((ROOT/'.github/workflows/desktop.yml').read_text())
        checkout=next(s for s in data['jobs']['lint']['steps'] if s.get('uses','').startswith('actions/checkout@'))
        with tempfile.TemporaryDirectory() as temp:
            sparse=Path(temp)
            for path in checkout['with']['sparse-checkout'].splitlines():
                if path.startswith('assets/'):
                    shutil.copytree(ROOT/path,sparse/path,dirs_exist_ok=True)
            m.ROOT=sparse
            for label in m.LABELS:
                self.assertEqual(len(m.templates(label)),3,label)

    def test_observer_can_capture_and_tap_a_rendered_button_when_ocr_cannot_read_it(self):
        import tempfile
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('ui_test',ROOT/'scripts/ci/android_ui_smoke.py')
        ui=importlib.util.module_from_spec(spec);spec.loader.exec_module(ui)
        class Device(ui.Device):
            def __init__(self,folder):self.output=folder;self.observations=[];self.actions_attempted=[];self.commands=[]
            def run(self,*args,**kwargs):
                self.commands.append(args)
                return FIXTURE.read_bytes() if args==('exec-out','screencap','-p') else ''
        header='level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n'
        def ocr(args,**kwargs):return header if args[-1]=='tsv' else 'unreadable raster lettering'
        with tempfile.TemporaryDirectory() as temp:
            device=Device(Path(temp))
            with patch.object(ui.subprocess,'check_output',side_effect=ocr),patch.object(ui.time,'monotonic',side_effect=[0,100]):
                self.assertIn('CREATE',device.capture('lobby',r'CREATE|SETTINGS'))
                device.tap_text('CREATE',label='create')
            command=device.commands[-1]
            self.assertEqual(command[:3],('shell','input','tap'))
            self.assertTrue(817<int(command[3])<961 and 735<int(command[4])<795)

    def test_lobby_cannot_be_accepted_as_shop_while_native_create_is_visible(self):
        import tempfile
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('ui_test',ROOT/'scripts/ci/android_ui_smoke.py')
        ui=importlib.util.module_from_spec(spec);spec.loader.exec_module(ui)
        class Device(ui.Device):
            def __init__(self,folder):self.output=folder;self.observations=[]
            def run(self,*args,**kwargs):return FIXTURE.read_bytes()
        with tempfile.TemporaryDirectory() as temp:
            device=Device(Path(temp))
            with patch.object(ui.subprocess,'check_output',return_value='Gold Cash'),patch.object(ui.time,'monotonic',side_effect=[0,100]),patch.object(ui,'enhanced_ocr',side_effect=AssertionError('Native absence already observes these pixels')):
                with self.assertRaises(ui.CaptureTimeout):device.capture('shop','GOLD|CASH',absent='CREATE|SETTINGS')

    def test_observed_camera_state_does_not_require_expensive_full_frame_enhancement(self):
        import tempfile
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('ui_test',ROOT/'scripts/ci/android_ui_smoke.py')
        ui=importlib.util.module_from_spec(spec);spec.loader.exec_module(ui)
        class Device(ui.Device):
            def __init__(self,folder):self.output=folder;self.observations=[]
            def run(self,*args,**kwargs):return (ROOT/'tests/fixtures/android_ui/busy_controls_api36.png').read_bytes()
        with tempfile.TemporaryDirectory() as temp:
            device=Device(Path(temp))
            with patch.object(ui.subprocess,'check_output',return_value='unreadable'),patch.object(ui,'native_targets',return_value=[]),patch.object(ui,'control_targets',return_value=[dict(text='CAMERA')]),patch.object(ui,'enhanced_ocr',side_effect=AssertionError('Control OCR already proves state')):
                self.assertIn('CAMERA',device.capture('camera','CAMERA',absent=ui.CAMERA_ON_PATTERN))

    def test_enhanced_ocr_preserves_original_pixel_coordinates(self):
        import tempfile
        from unittest.mock import patch
        spec=importlib.util.spec_from_file_location('ui_test',ROOT/'scripts/ci/android_ui_smoke.py')
        ui=importlib.util.module_from_spec(spec);spec.loader.exec_module(ui)
        def ocr(args,**kwargs):
            with Image.open(args[1]) as image:
                self.assertEqual(image.size,(3840,2400));self.assertEqual(image.mode,'L')
            self.assertEqual(args[-1],'tsv')
            return 'tsv-result'
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/'screen.png';path.write_bytes(FIXTURE.read_bytes())
            with patch.object(ui.subprocess,'check_output',side_effect=ocr):self.assertEqual(ui.enhanced_ocr(path,tsv=True),'tsv-result')
        target=ui.unscale_target(dict(left=3193,top=361,width=121,height=23,text='CAMERA'),3)
        self.assertEqual(target,dict(left=1064,top=120,width=41,height=8,text='CAMERA'))

    def module(self):
        self.assertTrue(PATH.exists(),'Native raster observer missing')
        spec=importlib.util.spec_from_file_location('native_ui_test',PATH)
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        return module

    def test_real_ci_lobby_identifies_each_button_from_pixels(self):
        m=self.module()
        with Image.open(FIXTURE) as im:
            for label,x in [('CREATE',825),('AVATAR',661),('SETTINGS',343)]:
                target=m.target(im,label)
                self.assertLessEqual(abs(target['left']-x),3)
                self.assertTrue(745<=target['top']<=757)
                self.assertEqual(target['text'],label)
                self.assertLessEqual(target['error'],0.04)
            with self.assertRaisesRegex(ValueError,'missing'):m.target(im,'START')
            with self.assertRaisesRegex(ValueError,'ambiguous'):m.target(im,'CREATE|AVATAR')

    def test_duplicate_and_darkened_buttons_cannot_authorize_a_tap(self):
        m=self.module()
        with Image.open(FIXTURE) as source:
            im=source.convert('RGB')
            duplicate=im.copy();duplicate.paste(im.crop((817,735,961,795)),(300,530))
            with self.assertRaisesRegex(ValueError,'ambiguous'):m.target(duplicate,'CREATE')
            with self.assertRaisesRegex(ValueError,'missing'):m.target(ImageEnhance.Brightness(im).enhance(0.35),'CREATE')

    def test_button_can_move_without_using_a_fixed_screen_point(self):
        m=self.module()
        with Image.open(FIXTURE) as source:
            im=Image.new('RGB',source.size,(0,0,0))
            im.paste(source.crop((817,735,961,795)),(32,123))
            target=m.target(im,'CREATE')
            self.assertLessEqual(abs(target['left']-40),3)
            self.assertTrue(134<=target['top']<=141)

    def test_client_disabled_frame_cannot_match_an_enabled_button(self):
        m=self.module()
        path=ROOT/'assets/hd/classic/buttons_smooth_4x/lobby/b_gamelist_create.png'
        with Image.open(path) as strip:
            disabled=strip.convert('RGBA').crop((1284,0,1712,180)).resize((143,60),Image.Resampling.NEAREST)
            screen=Image.new('RGBA',(1280,800),(0,0,0,255))
            screen.alpha_composite(disabled,(100,100))
            with self.assertRaisesRegex(ValueError,'missing'):m.target(screen,'CREATE')
