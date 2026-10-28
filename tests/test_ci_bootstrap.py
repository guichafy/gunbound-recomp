"""Security and reproducibility contracts for the CI bootstrap."""
import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

BOOTSTRAP = Path(__file__).resolve().parents[1] / 'scripts/ci/bootstrap.py'


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(BOOTSTRAP.is_file(), 'CI bootstrap must be implemented')
        spec = importlib.util.spec_from_file_location('ci_bootstrap', BOOTSTRAP)
        self.bootstrap = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.bootstrap)

    def test_checksum_rejects_corruption(self):
        with tempfile.TemporaryDirectory() as tmp:
            file = Path(tmp) / 'asset'
            file.write_bytes(b'authorized')
            expected = hashlib.sha256(b'authorized').hexdigest()
            self.bootstrap.verify_digest(file, expected)
            file.write_bytes(b'corrupt')
            with self.assertRaisesRegex(ValueError, 'SHA256'):
                self.bootstrap.verify_digest(file, expected)

    def test_safe_zip_preserves_executable_mode(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = Path(tmp) / 'editor.zip'
            with zipfile.ZipFile(archive, 'w') as output:
                info = zipfile.ZipInfo('Godot.app/Contents/MacOS/Godot')
                info.external_attr = 0o100755 << 16
                output.writestr(info, b'editor')
            destination = Path(tmp) / 'out'
            self.bootstrap.safe_extract(archive, destination)
            target = destination / 'Godot.app/Contents/MacOS/Godot'
            self.assertEqual(target.read_bytes(), b'editor')
            if self.bootstrap.os.name != 'nt':
                self.assertTrue(target.stat().st_mode & 0o100)

    def test_safe_zip_rejects_escape_and_windows_absolute_paths(self):
        for name in ('../escape', '/escape', 'C:/escape', '..\\escape'):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as tmp:
                archive = Path(tmp) / 'bad.zip'
                with zipfile.ZipFile(archive, 'w') as output:
                    output.writestr(name, b'bad')
                with self.assertRaisesRegex(ValueError, 'Unsafe ZIP'):
                    self.bootstrap.safe_extract(archive, Path(tmp) / 'out')
                self.assertFalse((Path(tmp) / 'escape').exists())

    def test_safe_zip_rejects_symlinks(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = Path(tmp) / 'bad.zip'
            with zipfile.ZipFile(archive, 'w') as output:
                info = zipfile.ZipInfo('link')
                info.external_attr = 0o120777 << 16
                output.writestr(info, '../outside')
            with self.assertRaisesRegex(ValueError, 'Unsafe ZIP'):
                self.bootstrap.safe_extract(archive, Path(tmp) / 'out')

    def test_platform_paths_are_exact_and_unsupported_architecture_fails(self):
        self.assertEqual(self.bootstrap.editor_asset('Darwin', 'arm64'),
                         ('Godot_v4.7.2-stable_macos.universal.zip', 'Godot.app/Contents/MacOS/Godot'))
        self.assertEqual(self.bootstrap.editor_asset('Windows', 'AMD64')[1],
                         'Godot_v4.7.2-stable_win64.exe')
        with self.assertRaisesRegex(ValueError, 'Unsupported'):
            self.bootstrap.editor_asset('Linux', 'arm64')

    def test_avatar_reference_files_are_prepared_without_modifying_archive(self):
        self.assertTrue(hasattr(self.bootstrap, 'prepare_avatar_references'),
                        'Bootstrap must prepare avatar reference fixtures')
        # This test isolates filesystem placement from the existing independent
        # decoder; the pinned real archive is also exercised by test_xfs_import.
        import sys
        sys.path.insert(0, str(BOOTSTRAP.parents[1]))
        import read_gunbound_xfs
        raw = b'archive fixture'
        names = ('fb.dat', 'ff.dat', 'fg.dat', 'fh.dat', 'mb.dat', 'mf.dat', 'mg.dat', 'mh.dat')
        entries = {name: {'data': bytes([number])} for number, name in enumerate(names)}
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / 'avatar.xfs'
            source.write_bytes(raw)
            expected_hash = hashlib.sha256(raw).hexdigest()
            with patch.dict(self.bootstrap.CONFIG['client_sha256'], {'avatar.xfs': expected_hash}), \
                    patch.object(read_gunbound_xfs, 'archive', return_value={'version': 280, 'entries': entries}), \
                    patch.object(read_gunbound_xfs, 'extract', side_effect=lambda data, row: row['data']):
                self.bootstrap.prepare_avatar_references(root, source)
            destination = root / 'assets/xfs/reference'
            self.assertEqual((destination / 'avatar.xfs').read_bytes(), raw)
            self.assertEqual(source.read_bytes(), raw)
            self.assertEqual({p.name for p in destination.iterdir()}, {*names, 'avatar.xfs'})
            for name in names:
                self.assertEqual((destination / name).read_bytes(), entries[name]['data'])

    def test_client_source_cannot_overwrite_other_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'repo'
            root.mkdir()
            source = Path(tmp) / 'source'
            source.mkdir()
            (source / 'characterdata.dat').write_bytes(b'wrong client')
            with self.assertRaisesRegex(ValueError, 'SHA256'):
                self.bootstrap.prepare_client(root, source)
            self.assertFalse((root / '.tools/gunbound-client/characterdata.dat').exists())


if __name__ == '__main__':
    unittest.main()
