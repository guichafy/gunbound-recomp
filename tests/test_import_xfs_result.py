"""Result window catalog (REQ-50/ADR-139) against an independent XFS decode.

gunbound_xfs.py reads graphics.xfs with its own LZHUF/IMG code, separate
from read_gunbound_xfs/decode_gunbound_img used by the importer.
"""
import hashlib
import json
import sys
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import gunbound_xfs as xfs

ARCHIVE = ROOT / '.tools/gunbound-client/graphics.xfs'


@unittest.skipUnless(ARCHIVE.exists(), 'client graphics.xfs not prepared in .tools/')
class ResultImport(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = json.loads((ROOT / 'assets/xfs/result/catalog.json').read_text())
        cls.toc = {row['name']: row for row in xfs.read_toc(ARCHIVE)}

    def decode(self, name):
        return xfs.frames(xfs.read_entry(ARCHIVE, self.toc[name]))

    def compare(self, key, frame):
        info = self.catalog['frames'][key]
        self.assertEqual(info['size'], [frame['w'], frame['h']], key)
        self.assertEqual(info['pivot'], [frame['hx'], frame['hy']], key)
        path = ROOT / info['file'].replace('res://', '')
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), info['sha256'], key)
        with Image.open(path) as image:
            exported = image.convert('RGBA')
        # Same colours wherever the reference decoder wrote a pixel.
        ref = frame['image']
        for y in range(0, frame['h'], 3):
            for x in range(0, frame['w'], 3):
                expected = ref.getpixel((x, y))
                if expected[3]:
                    self.assertEqual(exported.getpixel((x, y))[:3], expected[:3], (key, x, y))

    def test_archive_pin(self):
        self.assertEqual(self.catalog['graphics_sha256'], hashlib.sha256(ARCHIVE.read_bytes()).hexdigest())

    def test_result_back_and_button(self):
        for name, count in [('result_back', 5), ('b_result_confirm', 4)]:
            decoded = self.decode(name + '.img')
            self.assertEqual(len(decoded), count)
            for index, frame in enumerate(decoded):
                self.compare(f'{name}:{index}', frame)

    def test_numfont_frames_of_the_row(self):
        decoded = self.decode('numfont.img')
        for index in list(range(80, 126)) + [224, 225]:
            self.compare(f'numfont:{index}', decoded[index])

    def test_button_states_follow_the_epa(self):
        states, _ = xfs.parse_epa(xfs.read_entry(ARCHIVE, self.toc['b_result_confirm.epa']))
        self.assertEqual({row['name']: row['frames'] for row in states},
                         {'ready': [0], 'push': [2], 'mouse': [1], 'disable': [3], 'select': [0]})


if __name__ == '__main__':
    unittest.main()
