"""Independent source/atlas checks for the native HUD repack (REQ-48)."""
import hashlib
import json
import struct
import sys
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import gunbound_xfs as xfs
from decode_gunbound_img import frames


class NativeHudImport(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.folder = ROOT / 'assets/xfs/hud'
        cls.catalog = json.loads((cls.folder / 'catalog.json').read_text())
        cls.archive = ROOT / '.tools/gunbound-client/graphics.xfs'
        cls.toc = {row['name']: row for row in xfs.read_toc(cls.archive)}

    def native_frames(self, name):
        # Reference for complete RGB565 rows, independent of the importer's
        # alpha repair. RLE still uses its pre-existing run decoder.
        raw = xfs.read_entry(self.archive, self.toc[name])
        result = frames(raw)
        offset = 8
        for index, (image, pivot) in enumerate(result):
            kind, _, w, h, *rest = struct.unpack_from('<HH9i', raw, offset)
            offset += 40
            payload = raw[offset:offset+rest[-1]]
            offset += rest[-1]
            if name == 'play_back.img' and kind & 255 == 0:
                pixels = bytes(channel for (word,) in struct.iter_unpack('<H', payload)
                               for channel in ((word >> 11)*255//31,
                                               (word >> 5 & 63)*255//63,
                                               (word & 31)*255//31, 255))
                result[index] = (Image.frombytes('RGBA', (w,h), pixels), pivot)
        return result

    def test_footer_rgb565_is_opaque_including_black(self):
        # Independent raw-word oracle: native 4ebaf0/4eba80 emits complete
        # RGB565 scanlines, unlike the RLE path. 0x0000 is an opaque pixel.
        raw = xfs.read_entry(self.archive, self.toc['play_back.img'])
        offset = 8
        wanted = {1:'NativeFooter.png', 5:'NativeMoveFrame.png',
                  6:'NativeMoveExpanded.png', 9:'NativeSlice.png', 11:'NativeDrag.png'}
        for index in range(12):
            kind, _, w, h, *rest = struct.unpack_from('<HH9i', raw, offset)
            offset += 40
            payload = raw[offset:offset+rest[-1]]
            offset += rest[-1]
            if index not in wanted:
                continue
            self.assertEqual(kind & 255, 0)
            expected = bytes(channel for (word,) in struct.iter_unpack('<H', payload)
                             for channel in ((word >> 11)*255//31,
                                             (word >> 5 & 63)*255//63,
                                             (word & 31)*255//31, 255))
            output = Image.open(self.folder/wanted[index]).convert('RGBA')
            self.assertEqual(output.size, (w,h))
            self.assertEqual(output.tobytes(), expected, wanted[index])

    def test_full_native_bands_and_mode_panels(self):
        decoded = self.native_frames('play_back.img')
        expected = {'NativeHeader.png': decoded[0][0].crop((20,12,820,52)),
                    'NativeFooter.png': decoded[1][0], 'NativeGoldPanel.png': decoded[178][0],
                    'NativeLifePanel.png': decoded[172][0], 'NativeJewelPanel.png': decoded[179][0],
                    'NativeMoveExpanded.png': decoded[6][0], 'NativeStrength.png': decoded[2][0], 'NativeMovement.png': decoded[7][0]}
        for name, native in expected.items():
            path = self.folder/name
            self.assertTrue(path.exists(), 'Missing unscaled native UI: '+name)
            output = Image.open(path).convert('RGBA')
            self.assertEqual(output.size, native.size, name)
            self.assertEqual(output.tobytes(), native.tobytes(), name)

    def test_native_header_digits_keep_registration(self):
        decoded=self.native_frames('numfont.img')
        for name,base,cell in [('NativeGoldDigits.png',135,(19,24)),('NativeAngleDigits.png',179,(8,10))]:
            path=self.folder/name
            self.assertTrue(path.exists(),'Missing native readout '+name)
            output=Image.open(path).convert('RGBA')
            for digit in range(10):
                im,pivot=decoded[base+digit]
                expected=Image.new('RGBA',cell)
                expected.alpha_composite(im,pivot)
                self.assertEqual(output.crop((digit*cell[0],0,(digit+1)*cell[0],cell[1])).tobytes(),expected.tobytes())

    def test_native_timer_and_wind_assets(self):
        decoded=self.native_frames('numfont.img')
        for name,first,cell in [('NativeTimerDigits.png',146,(28,45)),('NativeTimerFraction.png',157,(17,28)),('NativeWindDigits.png',167,(10,17))]:
            path=self.folder/name
            self.assertTrue(path.exists(),'Missing clock/wind resource '+name)
            output=Image.open(path).convert('RGBA')
            for digit in range(10):
                image,pivot=decoded[first+digit]
                expected=Image.new('RGBA',cell);expected.alpha_composite(image,pivot)
                self.assertEqual(output.crop((digit*cell[0],0,(digit+1)*cell[0],cell[1])).tobytes(),expected.tobytes())
        for name,frame in [('NativeTimerDot.png',156),('NativeWindLabel.png',177)]:
            self.assertEqual(Image.open(self.folder/name).convert('RGBA').tobytes(),decoded[frame][0].tobytes())
        path=self.folder/'NativeWindTexture.png'
        self.assertTrue(path.exists(),'Missing full original moon.xtf')
        import struct
        raw=xfs.read_entry(self.archive,self.toc['moon.xtf'])
        w,h,kind=struct.unpack_from('<IIB',raw)
        expected=bytes(c for value, in struct.iter_unpack('<H',raw[9:]) for c in xfs._argb4444(value))
        output=Image.open(path).convert('RGBA')
        self.assertEqual(output.size,(w,h));self.assertEqual(output.tobytes(),expected)

    def test_native_source_identity(self):
        self.assertEqual(hashlib.sha256(self.archive.read_bytes()).hexdigest(), self.catalog['archive_sha256'])
        self.assertEqual(len(self.catalog['entries']), 12)
        for name, entry in self.catalog['entries'].items():
            self.assertEqual(hashlib.sha256(xfs.read_entry(self.archive, self.toc[name])).hexdigest(), entry['entry_sha256'])

    def test_packaged_size_and_hash(self):
        self.assertEqual(len(self.catalog['files']), 56)
        for key, entry in self.catalog['files'].items():
            path = ROOT / entry['file'].removeprefix('res://')
            image = Image.open(path).convert('RGBA')
            self.assertEqual(list(image.size), entry['size'], key)
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), entry['sha256'], key)
            self.assertEqual(hashlib.sha256(image.tobytes()).hexdigest(), entry['rgba_sha256'], key)
            self.assertTrue(entry['operations'], key)
            for operation in entry['operations']:
                self.assertIn(operation['entry'], self.catalog['entries'])
                self.assertIn(operation['mode'], ['fit', 'stretch'])

    def test_native_charge_pixels(self):
        # Frame2 is the native red strength fill; it is 400x22 and the port's
        # original 400px width/19px height slot is preserved with nearest rows.
        native = self.native_frames('play_back.img')[2][0]
        output = Image.open(self.folder/'StrenghtMetter.png').convert('RGBA')
        self.assertEqual(native.size,(400,22))
        self.assertEqual(output.size,(400,19))
        for y in range(19):
            source_y = int((y+0.5)*22/19)
            self.assertEqual(output.crop((0,y,400,y+1)).tobytes(),native.crop((0,source_y,400,source_y+1)).tobytes())

    def test_native_weather_only(self):
        decoded = self.native_frames('playmode.img')
        output = Image.open(self.folder/'WeatherIcons.png').convert('RGBA')
        for index, source in enumerate(range(165,172)):
            native = decoded[source][0].resize((22,22),Image.Resampling.NEAREST)
            for row in range(2):
                self.assertEqual(output.crop((index*22,row*22,index*22+22,row*22+22)).tobytes(),native.tobytes())
        # Three later-version categories have no original frame in this build.
        self.assertEqual(output.crop((154,0,330,44)).getbbox(),None)
        self.assertEqual(self.catalog['weather_gaps'],['weakness','mirror','random'])

    def test_turn_digits_are_zero_based_not_player_labels(self):
        # Visual source inventory: numberfont40..63 are player labels1..8,
        # not decimal strips. The port asks for literal digits0 and1 in1x1.
        # These independently fixed ranges visibly spell0..7 in the client.
        decoded=self.native_frames('numberfont.img')
        for name,first in [('FontBlueTurnCounter.png',152),('FontRedTurnCounter.png',173)]:
            output=Image.open(self.folder/name).convert('RGBA')
            for digit in range(8):
                native=decoded[first+digit][0]
                factor=min(13/native.width,17/native.height)
                size=(round(native.width*factor),round(native.height*factor))
                expected=Image.new('RGBA',(13,17))
                expected.alpha_composite(native.resize(size,Image.Resampling.NEAREST),((13-size[0])//2,(17-size[1])//2))
                self.assertEqual(output.crop((digit*13,0,digit*13+13,17)).tobytes(),expected.tobytes(),f'{name} digit{digit}')

    def test_ss_uses_all_five_native_weapon_faces(self):
        output=Image.open(self.folder/'ShotSelector.png').convert('RGBA')
        decoded=self.native_frames('b_play_weapon3.img')
        self.assertEqual(len(decoded),5)
        for state,(native,_) in enumerate(decoded):
            expected=Image.new('RGBA',(37,37))
            expected.alpha_composite(native.resize((37,36),Image.Resampling.NEAREST),(0,0))
            self.assertEqual(output.crop(((10+state)*37,0,(11+state)*37,37)).tobytes(),expected.tobytes())

    def test_no_generated_pixels_or_invented_faces(self):
        entry_names=set(self.catalog['entries'])
        self.assertFalse(any('openbound' in name or 'hd/' in name for name in entry_names))
        accept=Image.open(self.folder/'PopupAccept.png')
        faces=[accept.crop((i*20,0,i*20+20,25)).tobytes() for i in range(4)]
        self.assertTrue(all(face==faces[0] for face in faces))
        self.assertIn('TurnCounterBalloon.png',self.catalog['gaps'])
        self.assertIn('Crosshair*Ally.png',self.catalog['gaps'])

if __name__ == '__main__':
    unittest.main()
