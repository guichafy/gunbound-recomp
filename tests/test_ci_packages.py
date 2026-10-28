"""Release packaging contracts, exercised without an installed exporter."""
import configparser
from contextlib import redirect_stdout
import hashlib
import importlib.util
import json
import io
from pathlib import Path
import plistlib
import sys
import struct
import tempfile
import unittest
import zipfile

SPEC = importlib.util.spec_from_file_location('desktop_package', Path(__file__).resolve().parents[1] / 'scripts/ci/package.py')


class DesktopPackages(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        if SPEC is None or SPEC.loader is None or not Path(SPEC.origin).exists():
            self.fail('desktop package implementation is missing')
        self.package = importlib.util.module_from_spec(SPEC)
        sys.modules[SPEC.name] = self.package
        SPEC.loader.exec_module(self.package)

    def windows(self):
        folder = self.root / 'Windows'
        folder.mkdir()
        (folder / 'GunboundRecomp.exe').write_bytes(b'MZ-template')
        (folder / 'GunboundRecomp.pck').write_bytes(b'GDPC-project')
        for name in self.package.NOTICES.values():
            (folder / name).write_text('license')
        return folder

    def test_windows_binary_must_be_a_64bit_pe(self):
        binary = self.root / 'game.exe'
        raw = bytearray(0x100)
        raw[:2] = b'MZ'
        struct.pack_into('<I', raw, 0x3C, 0x80)
        raw[0x80:0x84] = b'PE\0\0'
        struct.pack_into('<H', raw, 0x84, 0x8664)
        binary.write_bytes(raw)
        self.package.verify_architecture(binary, 'windows')
        struct.pack_into('<H', raw, 0x84, 0x014C)
        binary.write_bytes(raw)
        with self.assertRaisesRegex(ValueError, 'x86_64'):
            self.package.verify_architecture(binary, 'windows')

    def test_export_presets_share_resource_and_exclusion_contract(self):
        config = configparser.ConfigParser(interpolation=None)
        config.read(Path(__file__).resolve().parents[1] / 'export_presets.cfg')
        for key in ('include_filter', 'exclude_filter'):
            self.assertEqual(config['preset.0'][key], config['preset.1'][key])
        excluded = config['preset.1']['exclude_filter']
        for name in ('override.cfg', 'export_credentials.cfg', '.tools/*', 'tests/*'):
            self.assertIn(name, excluded)
        self.assertEqual(config['preset.1.options']['binary_format/embed_pck'], 'false')
        self.assertEqual(config['preset.1.options']['binary_format/architecture'], '"x86_64"')

    def test_manifest_cannot_mark_missing_smoke_as_passed(self):
        archive = self.root / 'package.zip'
        archive.write_bytes(b'zip')
        with self.assertRaisesRegex(ValueError, 'passing smoke'):
            self.package.write_manifest(archive, 'windows', '0.20.6', 'a' * 40, '4.7.2.stable', '')
        self.assertFalse(archive.with_suffix('.json').exists())

    def test_missing_legal_notice_blocks_package(self):
        folder = self.windows()
        (folder / 'GODOT_LICENSE.txt').unlink()
        with self.assertRaisesRegex(ValueError, 'GODOT_LICENSE.txt'):
            self.package.validate_layout(folder, 'windows', '0.20.6')

    def test_windows_layout_requires_pck_and_all_licenses(self):
        folder = self.windows()
        self.assertEqual(self.package.validate_layout(folder, 'windows', '0.20.6'), folder / 'GunboundRecomp.exe')
        (folder / 'GunboundRecomp.pck').unlink()
        with self.assertRaisesRegex(ValueError, 'GunboundRecomp.pck'):
            self.package.validate_layout(folder, 'windows', '0.20.6')

    def test_distribution_rejects_certificate_override(self):
        folder = self.windows()
        (folder / 'override.cfg').write_text('local cert path')
        with self.assertRaisesRegex(ValueError, 'override.cfg'):
            self.package.validate_layout(folder, 'windows', '0.20.6')

    def test_macos_metadata_must_match_project_version(self):
        app = self.root / 'Gunbound Recomp.app'
        resources = app / 'Contents/Resources'
        binaries = app / 'Contents/MacOS'
        resources.mkdir(parents=True)
        binaries.mkdir()
        (binaries / 'GunboundRecomp').write_bytes(b'Mach-O')
        (resources / 'GunboundRecomp.pck').write_bytes(b'GDPC')
        for name in self.package.NOTICES.values():
            (resources / name).write_text('license')
        info = {'CFBundleExecutable': 'GunboundRecomp', 'CFBundleShortVersionString': '0.20.5', 'CFBundleVersion': '0.20.5'}
        (app / 'Contents/Info.plist').write_bytes(plistlib.dumps(info))
        with self.assertRaisesRegex(ValueError, 'version'):
            self.package.validate_layout(app, 'macos', '0.20.6')
        self.assertEqual(self.package.validate_layout(app, 'macos', '0.20.5'), binaries / 'GunboundRecomp')

    def test_manifest_hashes_exact_zip_and_records_smoke(self):
        folder = self.windows()
        archive = self.root / 'Gunbound-Recomp-0.20.6-Windows-x86_64.zip'
        self.package.zip_windows(folder, archive)
        result = self.package.write_manifest(archive, 'windows', '0.20.6', 'a' * 40, '4.7.2.stable', 'PACKAGED SMOKE: PASS')
        manifest = json.loads(result.read_text())
        self.assertEqual(manifest['sha256'], hashlib.sha256(archive.read_bytes()).hexdigest())
        self.assertEqual(manifest['version'], '0.20.6')
        self.assertEqual(manifest['commit'], 'a' * 40)
        self.assertEqual(manifest['smoke'], 'passed')
        with zipfile.ZipFile(archive) as zipped:
            self.assertIn('Windows/GunboundRecomp.exe', zipped.namelist())
            self.assertIn('Windows/XFS_ATTRIBUTION.md', zipped.namelist())
        self.assertIn(archive.name, archive.with_suffix('.zip.sha256').read_text())

    def test_windows_smoke_can_use_engine_log_without_stdout(self):
        engine_log = self.root / 'engine.log'
        runner_log = self.root / 'runner.log'
        command = [sys.executable, '-c', 'from pathlib import Path; import sys; Path(sys.argv[1]).write_text("PACKAGED SMOKE: PASS")', str(engine_log)]
        with redirect_stdout(io.StringIO()):
            output = self.package.run_logged(command, self.root, runner_log, 5, engine_log=engine_log)
        self.assertTrue(self.package.smoke_passed(0, output))
        # A previous successful log must never let a later silent process pass.
        with redirect_stdout(io.StringIO()):
            output = self.package.run_logged([sys.executable, '-c', 'pass'], self.root, runner_log, 5, engine_log=engine_log)
        self.assertFalse(self.package.smoke_passed(0, output))
        self.assertFalse(engine_log.exists())

    def test_nonzero_exit_and_script_error_block_package(self):
        for command in ([sys.executable, '-c', 'raise SystemExit(3)'],
                        [sys.executable, '-c', 'print("SCRIPT ERROR: broken")']):
            with redirect_stdout(io.StringIO()), self.assertRaisesRegex(RuntimeError, 'failed'):
                self.package.run_logged(command, self.root, self.root / 'failed.log', 5)

    def test_smoke_requires_success_marker_and_rejects_script_errors(self):
        self.assertTrue(self.package.smoke_passed(0, 'PACKAGED SMOKE: PASS'))
        self.assertFalse(self.package.smoke_passed(0, 'SCRIPT ERROR: failed\nPACKAGED SMOKE: PASS'))
        self.assertFalse(self.package.smoke_passed(0, 'Godot started'))
        self.assertFalse(self.package.smoke_passed(1, 'PACKAGED SMOKE: PASS'))


if __name__ == '__main__':
    unittest.main()
