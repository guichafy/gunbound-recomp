import hashlib
import json
from pathlib import Path
import sys
import unittest
import struct
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts'))
from import_mage_weather import decode_stage
import gunbound_xfs as xfs


class NativeStage(unittest.TestCase):
    def test_native_miramo_record(self):
        raw = (ROOT/'.tools/gunbound-client/stage.dat').read_bytes()
        saved = json.loads((ROOT/'assets/openbound/weather/native_stage.json').read_text())
        self.assertEqual(hashlib.sha256(raw).hexdigest(), saved['stage_sha256'])
        stage = next(s for s in decode_stage(raw) if s['name'] == 'MiramoTown')
        self.assertEqual(stage, saved['miramo_town_a'])
        self.assertEqual(stage['weights'], [2,1,2,1,2,0,0])
        self.assertEqual(stage['column_ranges']['tornado'][0], [60,1478])
        self.assertEqual(stage['column_ranges']['force'], [[324,1478]]*8)
        self.assertEqual(stage['column_ranges']['electricity'], [[324,1478]]*8)

    def test_checksum_rejects_corruption(self):
        raw = bytearray((ROOT/'.tools/gunbound-client/stage.dat').read_bytes())
        raw[50] ^= 4
        with self.assertRaisesRegex(ValueError, 'checksum'):
            decode_stage(raw)

    def test_native_column_pixels(self):
        archive=ROOT/'.tools/gunbound-client/graphics.xfs'
        toc={entry['name']:entry for entry in xfs.read_toc(archive)}
        folder=ROOT/'assets/openbound/weather/native'
        metadata=json.loads((folder/'column_art.json').read_text())
        self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(),metadata['archive_sha256'])
        for name,data in metadata['sheets'].items():
            raw=xfs.read_entry(archive,toc[data['entry']])
            self.assertEqual(hashlib.sha256(raw).hexdigest(),data['entry_sha256'])
            expected=bytes(channel for value, in struct.iter_unpack('<H',raw[9:]) for channel in xfs._argb4444(value))
            self.assertEqual(Image.open(folder/data['image']).convert('RGBA').tobytes(),expected)


if __name__ == '__main__':
    unittest.main()
