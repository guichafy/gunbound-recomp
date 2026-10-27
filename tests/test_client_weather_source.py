"""Native weather art provenance and independent ARGB4444/IMG pixel oracles."""
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
from decode_gunbound_img import frames as independent_frames

ARCHIVE = ROOT / '.tools/gunbound-client/graphics.xfs'
SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'


class ClientWeatherAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = json.loads((ROOT / 'assets/xfs/weather/catalog.json').read_text())
        cls.toc = {entry['name']: entry for entry in xfs.read_toc(ARCHIVE)}

    def test_identity_and_all_native_fallbacks(self):
        self.assertEqual(hashlib.sha256(ARCHIVE.read_bytes()).hexdigest(), SHA)
        self.assertEqual(self.catalog['archive_sha256'], SHA)
        self.assertEqual(len(self.catalog['files']), 8)
        for key, record in self.catalog['files'].items():
            with self.subTest(key=key):
                path = ROOT / record['file'].removeprefix('res://')
                source = Image.open(path).convert('RGBA')
                fallback = Image.open(ROOT / record['fallback'].removeprefix('res://')).convert('RGBA')
                self.assertEqual(list(source.size), record['size'])
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), record['sha256'])
                self.assertEqual(hashlib.sha256(source.tobytes()).hexdigest(), record['rgba_sha256'])
                self.assertEqual(source.size, fallback.size)
                self.assertEqual(source.tobytes(), fallback.tobytes())
                self.assertTrue(record['matches_native_fallback'])
        self.assertEqual(set(self.catalog['gaps']), {'weakness', 'mirror', 'random'})
        self.assertEqual(set(self.catalog['not_selected']), {'ThorTexture1.xtf', 'ThorTexture2.xtf'})

    def test_six_xtf_sheets_every_original_channel(self):
        for key in ['FirewallTexture', 'LightningTexture', 'TornadoTexture', 'CrashTexture', 'Lightning', 'LaserEffect']:
            with self.subTest(key=key):
                info = self.catalog['files'][key]
                raw = xfs.read_entry(ARCHIVE, self.toc[info['source']])
                self.assertEqual(hashlib.sha256(raw).hexdigest(), info['entry_sha256'])
                self.assertEqual(struct.unpack_from('<IIB', raw), (256, 256, 1))
                expected = bytes(channel for value, in struct.iter_unpack('<H', raw[9:])
                                 for channel in [((value >> 8) & 15) * 17, ((value >> 4) & 15) * 17,
                                                 (value & 15) * 17, ((value >> 12) & 15) * 17])
                picture = Image.open(ROOT / info['file'].removeprefix('res://')).convert('RGBA')
                self.assertEqual(picture.tobytes(), expected)

    def test_thor_112_native_frames_hotspots_and_epa(self):
        for key in ['ThorBody', 'ThorLight']:
            info = self.catalog['files'][key]
            raw = xfs.read_entry(ARCHIVE, self.toc[info['source']])
            self.assertEqual(hashlib.sha256(raw).hexdigest(), info['entry_sha256'])
            decoded = independent_frames(raw)
            self.assertEqual(len(decoded), 56)
            image = Image.open(ROOT / info['file'].removeprefix('res://')).convert('RGBA')
            cw, ch = info['cell']
            ox, oy = info['origin']
            for index, (native, (x, y)) in enumerate(decoded):
                cell = image.crop(((index % 14) * cw, (index // 14) * ch,
                                   (index % 14 + 1) * cw, (index // 14 + 1) * ch))
                expected = Image.new('RGBA', (cw, ch))
                expected.paste(native, (ox + x, oy + y))
                self.assertEqual(cell.tobytes(), expected.tobytes(), f'{key} frame {index}')
                self.assertEqual(info['frame_windows'][index], [x, y, *native.size])
        metadata = json.loads((ROOT / 'assets/xfs/thor/thor_native.json').read_text())
        approved = json.loads((ROOT / 'assets/openbound/aduka/thor_native.json').read_text())
        self.assertEqual(metadata, approved)
        raw = xfs.read_entry(ARCHIVE, self.toc['thor.epa'])
        self.assertEqual(hashlib.sha256(raw).hexdigest(), metadata['epa_sha256'])
        for key, start, end in [('normal', 0, 20), ('active', 20, 40), ('fire', 40, 56)]:
            self.assertEqual(metadata['states'][key]['frames'], list(range(start, end)))
            self.assertEqual(metadata['states'][key]['durations'], [1] * (end - start))

    def test_importer_rejects_unrecognized_archive_without_output(self):
        spec = importlib.util.spec_from_file_location('weather_importer', ROOT / 'scripts/import_xfs_weather.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            bad = Path(directory) / 'invalid.xfs'
            bad.write_bytes(b'unknown source')
            output = Path(directory) / 'output'
            with self.assertRaisesRegex(ValueError, 'SHA256'):
                module.import_assets(output, bad)
            self.assertFalse(output.exists())


if __name__ == '__main__':
    unittest.main()
