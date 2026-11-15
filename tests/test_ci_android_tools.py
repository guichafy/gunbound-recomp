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
