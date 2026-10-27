"""Mage source oracle: native bytes, DAT, atlas registration, EPA and PCM."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import unittest
import wave
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import gunbound_xfs as xfs
from import_aduka_combat import pe_bytes


class MageAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pe = (ROOT / '.tools/mobile-animation-port/GunBound.gme').read_bytes()
        assert hashlib.sha256(cls.pe).hexdigest() == '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
        cls.archive = ROOT / '.tools/gunbound-client/graphics.xfs'
        cls.toc = {e['name']:e for e in xfs.read_toc(cls.archive)}

    def test_native_dispatch_and_attribute_divisor(self):
        for table, animate, simulate in [(0x5560d0,0x47ebc0,0x4572b0),(0x5564f0,0x4a6200,0x4a4950),(0x5562c8,0x48f1c0,0x483ff0)]:
            self.assertEqual(struct.unpack('<I', pe_bytes(self.pe,table+8,4))[0],animate)
            self.assertEqual(struct.unpack('<I', pe_bytes(self.pe,table+24,4))[0],simulate)
        for site, divisor in [(0x488c05,1),(0x488d67,2),(0x488e7e,2),(0x489133,1)]:
            self.assertEqual(pe_bytes(self.pe,site,2), bytes([0x6a,divisor]))
        self.assertEqual(pe_bytes(self.pe,0x4a5cc8,5),bytes.fromhex('3dc8000000'))
        self.assertEqual(pe_bytes(self.pe,0x4a5e6f,3),bytes.fromhex('83f802'))
        self.assertEqual(pe_bytes(self.pe,0x48db72,6),bytes.fromhex('8dbed46f0000'))

    def test_characterdata_parameters(self):
        raw = (ROOT / '.tools/gunbound-client/characterdata.dat').read_bytes()
        decoded = xfs.lzhuf(raw,16*332)
        row = struct.unpack_from('<83i', decoded,332)
        actual = json.loads((ROOT / 'assets/openbound/mage/original/combat_native.json').read_text())
        self.assertEqual([[s[k] for k in ['power','dimension','aspect','flags','emp']] for s in actual['weapons']],
                         [[row[b+i] for i in [0,3,6,9,11]] for b in [44,57,70]])
        self.assertEqual([(s['power'],s['dimension'],s['aspect']) for s in actual['weapons']],[(200,66,143),(186,54,134),(380,60,130)])
        self.assertEqual(row[25],45); self.assertEqual(row[40],90)

    def test_all_pixels_pivots_and_epa(self):
        folder = ROOT / 'assets/openbound/mage/original'
        meta = json.loads((folder / 'frames.json').read_text())
        sheets = {'CharacterSpritesheet.png':dict(entry='tank2.img',**{k:meta[k] for k in ['cell','origin','columns']}),**meta['sheets']}
        count = 0
        for name, info in sheets.items():
            raw = xfs.read_entry(self.archive,self.toc[info['entry']])
            image = Image.open(folder / name).convert('RGBA')
            for index, frame in enumerate(xfs.frames(raw)):
                w,h = info['cell']; ox,oy = info['origin']; x,y = index%info['columns']*w,index//info['columns']*h
                expected = Image.new('RGBA',(w,h)); expected.paste(frame['image'],(ox+frame['hx'],oy+frame['hy']))
                self.assertEqual(image.crop((x,y,x+w,y+h)).tobytes(),expected.tobytes(),(name,index))
                if name=='CharacterSpritesheet.png':
                    self.assertEqual(meta['rider'][index],[frame['hx']+frame['extra'][2],frame['hy']+frame['extra'][3]])
                count+=1
        self.assertEqual(count,489)
        states,_ = xfs.parse_epa(xfs.read_entry(self.archive,self.toc['tank2.epa']))
        for pose, native in [('idle','normal'),('moving','move'),('charging_1','bfire2'),('recoil_1','fire2'),('hurt','fdamage'),('destroyed','dead')]:
            source=next(s for s in states if s['name']==native)
            self.assertEqual(meta['poses'][pose],source['frames']); self.assertEqual(meta['pose_durations'][pose],source['durations'])

    def test_native_pcm_and_laser(self):
        sound = ROOT.parent / 'GunboundClassic/gunbound-launcher/TestClient/sound.xfs'
        toc = {e['name']:e for e in xfs.read_toc(sound)}
        for name in ['21fire','22blast']:
            native = xfs.read_entry(sound,toc[name+'.xes'])
            with wave.open(str(ROOT / ('assets/openbound/classic/'+name+'.wav')),'rb') as audio:
                channels,bits,rate=audio.getnchannels(),audio.getsampwidth()*8,audio.getframerate(); align=channels*bits//8
                self.assertEqual(struct.pack('<HHIIHH',1,channels,rate,rate*align,align,bits)+audio.readframes(audio.getnframes()),native)
        raw = xfs.read_entry(self.archive,self.toc['LaserEffect.xtf'])
        expected=bytes(c for (v,) in struct.iter_unpack('<H',raw[9:]) for c in [((v>>8)&15)*17,((v>>4)&15)*17,(v&15)*17,((v>>12)&15)*17])
        self.assertEqual(Image.open(ROOT / 'assets/openbound/mage/original/LaserEffect.png').convert('RGBA').tobytes(),expected)


if __name__=='__main__':unittest.main()
