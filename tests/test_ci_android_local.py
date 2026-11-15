"""Local macOS flow must never target a phone or mutate an external AVD."""
import importlib.util
from pathlib import Path
import tempfile
import unittest


class LocalAndroidTests(unittest.TestCase):
    def setUp(self):
        path = Path(__file__).resolve().parents[1] / 'scripts/android_local.py'
        spec = importlib.util.spec_from_file_location('android_local', path)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def test_rejects_phone_serial_and_invalid_port(self):
        for serial in ('ABC123', '', 'emulator-0', 'emulator-5555', 'emulator-99999'):
            with self.subTest(serial=serial), self.assertRaises(ValueError):
                self.module.emulator_port(serial)
        self.assertEqual(self.module.emulator_port('emulator-5584'), 5584)

    def test_avd_location_is_always_inside_worktree(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env = self.module.local_environment(root, {'JAVA_HOME': '/jdk'})
            self.assertTrue(Path(env['ANDROID_AVD_HOME']).is_relative_to(root))
            self.assertTrue(Path(env['ANDROID_USER_HOME']).is_relative_to(root))
            self.assertEqual(env['JAVA_HOME'], '/jdk')

    def test_tools_validation_does_not_create_sdk(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            missing = root / 'absent-sdk'
            with self.assertRaises(ValueError):
                self.module.tools_from_sdk(missing, root / 'jdk', root / 'templates', '36.0.0')
            self.assertFalse(missing.exists())

    def test_android_uses_godot_sensor_landscape_enum(self):
        project = (Path(__file__).resolve().parents[1] / 'project.godot').read_text()
        self.assertIn('window/handheld/orientation.android=4', project)


if __name__ == '__main__':
    unittest.main()
