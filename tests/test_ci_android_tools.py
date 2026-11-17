"""Android input locks and target-aware Godot template selection."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

CI = Path(__file__).resolve().parents[1] / 'scripts/ci'
sys.path.insert(0, str(CI))
import bootstrap


class AndroidToolsTests(unittest.TestCase):
    def test_boot_uses_modern_swiftshader_backend_and_confirms_android_ready(self):
        import android_tools
        from unittest.mock import patch
        import subprocess
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);sdk=root/'sdk'
            (sdk/'system-images/android-36/default/x86_64/data').mkdir(parents=True)
            (sdk/'system-images/android-36/default/x86_64/data/empty_data_disk').touch()
            tools=dict(ANDROID_SDK_ROOT=str(sdk),ANDROID_HOME=str(sdk),EMULATOR='emulator',ADB='adb')
            with patch.object(android_tools.subprocess,'Popen') as popen,patch.object(android_tools.subprocess,'run',return_value=subprocess.CompletedProcess([],0,'1\n')) as run:
                popen.return_value.poll.return_value=None
                android_tools.boot(root,tools,36)
                args=popen.call_args.args[0]
                self.assertEqual(args[args.index('-gpu')+1],'swangle','Linux swiftshader still uses legacy GLES; select ANGLE explicitly')
                self.assertTrue(any(call.args[0][-1:] == ['sys.boot_completed'] for call in run.call_args_list))

    def test_modern_image_without_userdata_uses_emulator_data_directory(self):
        import android_tools
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            sdk=root/'sdk'
            image=sdk/'system-images/android-36/default/x86_64'
            (image/'data').mkdir(parents=True)
            (image/'data/empty_data_disk').write_text('')
            avds=root/'avd'
            android_tools.write_modern_avd(sdk,avds,36)
            config=(avds/'gunbound-ci-api36.avd/config.ini').read_text()
            self.assertIn('image.sysdir.1=system-images/android-36/default/x86_64/',config)
            self.assertIn('hw.cpu.arch=x86_64',config)
            self.assertIn('hw.initialOrientation=landscape',config)
            self.assertIn(str(avds/'gunbound-ci-api36.avd'),(avds/'gunbound-ci-api36.ini').read_text())
            self.assertFalse((image/'userdata.img').exists(),'Never fabricate a system image')
            with self.assertRaises(ValueError):android_tools.write_modern_avd(sdk,avds,24)
            (image/'data/empty_data_disk').unlink()
            with self.assertRaises(ValueError):android_tools.write_modern_avd(sdk,avds,36)

    def test_unzipped_emulator_registers_as_an_installed_sdk_package(self):
        import android_tools
        import xml.etree.ElementTree as ET
        with tempfile.TemporaryDirectory() as temp:
            folder=Path(temp)
            (folder/'source.properties').write_text('Pkg.Revision=37.3.9\nPkg.Path=emulator\n')
            android_tools.register_emulator(folder,'37.3.9')
            package=ET.parse(folder/'package.xml').find('localPackage')
            self.assertEqual(package.attrib['path'],'emulator')
            self.assertEqual([n.text for n in package.find('revision')],['37','3','9'])
            with self.assertRaises(ValueError):android_tools.register_emulator(folder,'37.3.8')

    def test_android_templates_are_selected_on_linux(self):
        self.assertTrue(hasattr(bootstrap, 'template_members'), 'target-aware templates missing')
        self.assertEqual(bootstrap.template_members('Linux', 'android'), [
            'templates/version.txt', 'templates/android_debug.apk', 'templates/android_release.apk'])
        self.assertIn('templates/linux_release.x86_64', bootstrap.template_members('Linux'))
        self.assertIn('templates/macos.zip', bootstrap.template_members('Darwin'))
        with self.assertRaises(ValueError):
            bootstrap.template_members('Linux', 'typo')

    def test_sdk_metadata_must_match_exact_package_and_revision(self):
        path = CI / 'android_tools.py'
        self.assertTrue(path.exists(), 'Android tooling missing')
        spec = importlib.util.spec_from_file_location('android_tools_test', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'source.properties').write_text('Pkg.Revision=36.1.0\nPkg.Path=build-tools;36.1.0\n')
            module.validate_package(root, 'build-tools;36.1.0', '36.1.0')
            with self.assertRaises(ValueError):
                module.validate_package(root, 'build-tools;36.1.0', '36.0.0')
            (root / 'source.properties').unlink()
            with self.assertRaises(ValueError):
                module.validate_package(root, 'build-tools;36.1.0', '36.1.0')

    def test_avd_api_matrix_is_pinned_and_rejects_other_images(self):
        import android_tools
        self.assertTrue(hasattr(android_tools,'image_package'),'AVD image selection missing')
        self.assertEqual(android_tools.image_package(24),'system-images;android-24;default;x86_64')
        self.assertEqual(android_tools.image_package(36),'system-images;android-36;default;x86_64')
        with self.assertRaises(ValueError):
            android_tools.image_package(35)

    def test_jdk_tar_allows_internal_links_but_rejects_escape_before_write(self):
        import io,tarfile
        import android_tools
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);archive=root/'jdk.tar'
            with tarfile.open(archive,'w') as out:
                member=tarfile.TarInfo('jdk/legal/java.base/LICENSE');member.size=7
                out.addfile(member,io.BytesIO(b'license'))
                link=tarfile.TarInfo('jdk/legal/java.desktop/LICENSE');link.type=tarfile.SYMTYPE;link.linkname='../java.base/LICENSE';out.addfile(link)
            android_tools.safe_tar(archive,root/'out')
            self.assertEqual((root/'out/jdk/legal/java.desktop/LICENSE').read_bytes(),b'license')
            for target in ('../../../../escape','/etc/passwd'):
                with tarfile.open(archive,'w') as out:
                    member=tarfile.TarInfo('jdk/file');member.size=1;out.addfile(member,io.BytesIO(b'x'))
                    link=tarfile.TarInfo('jdk/link');link.type=tarfile.SYMTYPE;link.linkname=target;out.addfile(link)
                with self.assertRaises(ValueError):
                    android_tools.safe_tar(archive,root/'bad')
                self.assertFalse((root/'bad/jdk/file').exists())
