"""Independent source/pixel checks; never use the importer's decoder as oracle."""
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import gunbound_xfs as xfs

ARCHIVE_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
PE_SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
ENTRY_SHA = '82a67f447474ea5b304e74330ffacfd62e58ab8446a2cfa4123cf2c618fb12ee'
FOLDER = ROOT / 'assets/openbound/mage/original'


class NativeSparks(unittest.TestCase):
    def test_original_pixels_and_provenance(self):
        self.assertTrue((FOLDER / 'spark_art.json').exists(), 'Native spark provenance must be generated')
        saved = json.loads((FOLDER / 'spark_art.json').read_text())
        archive = ROOT / '.tools/gunbound-client/graphics.xfs'
        self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(), ARCHIVE_SHA)
        self.assertEqual(saved['archive_sha256'], ARCHIVE_SHA)
        self.assertEqual(saved['pe_sha256'], PE_SHA)
        self.assertEqual(hashlib.sha256((ROOT / '.tools/mobile-animation-port/GunBound.gme').read_bytes()).hexdigest(), PE_SHA)
        toc = {entry['name']: entry for entry in xfs.read_toc(archive)}
        raw = xfs.read_entry(archive, toc['CrashTexture.xtf'])
        self.assertEqual(hashlib.sha256(raw).hexdigest(), ENTRY_SHA)
        self.assertEqual(saved['entry_sha256'], ENTRY_SHA)
        self.assertEqual(struct.unpack_from('<IIB', raw), (256, 256, 1))
        expected = bytes(channel for value, in struct.iter_unpack('<H', raw[9:])
                         for channel in (((value >> 8) & 15) * 17, ((value >> 4) & 15) * 17,
                                         (value & 15) * 17, ((value >> 12) & 15) * 17))
        picture = Image.open(FOLDER / 'CrashTexture.png').convert('RGBA')
        self.assertEqual(picture.size, (256, 256))
        self.assertEqual(picture.tobytes(), expected)
        self.assertEqual(hashlib.sha256((FOLDER / 'CrashTexture.png').read_bytes()).hexdigest(), saved['image_sha256'])
        self.assertEqual(saved['blend'], 'SRCALPHA/ONE')
        self.assertEqual(saved['dispatcher'], '0x450c20')
        self.assertEqual(saved['families']['force']['draw'], '0x48dd80')
        self.assertEqual(saved['families']['electricity']['draw'], '0x481ef0')

    def test_importer_rejects_changed_sources_before_output(self):
        path = ROOT / 'scripts/import_mage_sparks.py'
        self.assertTrue(path.exists(), 'Reproducible native spark importer must exist')
        spec = importlib.util.spec_from_file_location('mage_spark_import', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            corrupt = root / 'changed.xfs'
            corrupt.write_bytes(b'not the authorized graphics.xfs')
            output = root / 'output'
            with self.assertRaisesRegex(ValueError, 'SHA256'):
                module.import_assets(output, archive=corrupt)
            self.assertFalse(output.exists())
            with self.assertRaisesRegex(ValueError, 'SHA256'):
                module.import_assets(output, pe=corrupt)
            self.assertFalse(output.exists())


if __name__ == '__main__':
    unittest.main()
