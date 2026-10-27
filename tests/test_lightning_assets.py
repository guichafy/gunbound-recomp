"""Independent Lightning PE/DAT/XFS/PCM audit; never import GDScript."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import unittest
import wave
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
import gunbound_xfs as xfs
from import_lightning_combat import native_row, PE_SHA
from import_aduka_combat import pe_bytes
FOLDER=ROOT/'assets/openbound/lightning'
ARCHIVE=ROOT/'.tools/gunbound-client/graphics.xfs'
class LightningAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pe=(ROOT/'.tools/mobile-animation-port/GunBound.gme').read_bytes()
        assert hashlib.sha256(cls.pe).hexdigest()==PE_SHA
        assert hashlib.sha256(ARCHIVE.read_bytes()).hexdigest()=='a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
        cls.toc={e['name']:e for e in xfs.read_toc(ARCHIVE)}
        cls.meta=json.loads((FOLDER/'frames.json').read_text())
    def sheet(self,filename,info,columns):
        raw=xfs.read_entry(ARCHIVE,self.toc[info['entry']])
        source=xfs.frames(raw); image=Image.open(FOLDER/filename).convert('RGBA')
        w,h=info['cell'];ox,oy=info['origin']
        if 'entry_sha256' in info:self.assertEqual(hashlib.sha256(raw).hexdigest(),info['entry_sha256'])
        for i,frame in enumerate(source):
            expected=Image.new('RGBA',(w,h));expected.paste(frame['image'],(ox+frame['hx'],oy+frame['hy']))
            x,y=i%columns*w,i//columns*h
            self.assertEqual(image.crop((x,y,x+w,y+h)).tobytes(),expected.tobytes(),(filename,i))
        return source
    def test_body_epa_and_pivots(self):
        source=self.sheet('CharacterSpritesheet.png',dict(entry='tank8.img',cell=self.meta['cell'],origin=self.meta['origin']),20)
        self.assertEqual(json.loads((FOLDER/'RiderPivot.json').read_text()),[[f['hx']+f['extra'][2],f['hy']+f['extra'][3]]for f in source])
        states,_=xfs.parse_epa(xfs.read_entry(ARCHIVE,self.toc['tank8.epa']))
        states={s['name']:s for s in states}
        for pose,native in [('idle','normal'),('moving','move'),('destroyed','dead'),('hurt','fdamage'),('recoil_0','fire1'),('recoil_1','fire2'),('recoil_2','sfire')]:
            self.assertEqual(self.meta['poses'][pose],states[native]['frames'])
            self.assertEqual(self.meta['pose_durations'][pose],states[native]['durations'])
    def test_all_shot_and_impact_pixels(self):
        for filename,info in self.meta['sheets'].items():
            self.sheet(filename,info,info['columns'])
            states,_=xfs.parse_epa(xfs.read_entry(ARCHIVE,self.toc[info['epa']]))
            for state in states:
                self.assertEqual(info['states'][state['name']],state['frames'])
                self.assertEqual(info['durations'][state['name']],state['durations'])
        self.assertNotIn('flame83.img',self.toc)
        self.assertEqual(self.meta['sheets']['Bullet3.png']['entry'],'bullet8pl.img')
    def test_lightning_raster_texture(self):
        raw=xfs.read_entry(ARCHIVE,self.toc['Lightning.xtf'])
        w,h,kind=struct.unpack_from('<IIB',raw);self.assertEqual((w,h,kind),(256,256,1))
        actual=list(Image.open(FOLDER/'Lightning.png').convert('RGBA').getdata())
        self.assertEqual(actual,[xfs._argb4444(v)for v, in struct.iter_unpack('<H',raw[9:])])
    def test_dat_fields_are_distinct(self):
        r=native_row();c=json.loads((FOLDER/'combat_native.json').read_text())
        for i,shot in zip([44,57,70],c['weapons']):
            self.assertEqual([shot[k]for k in ['power','dimension','aspect','shock_radius','flags','shock','chain']],[r[i+j]for j in [0,3,6,9,10,11,12]])
        self.assertEqual([r[i]for i in [21,22,23,24,25,40]],[86,750,300,20,47,90])
    def test_native_dispatch_stride_and_geometry(self):
        # Calls to Simulate at different coarse stride:3(T1),8(T2).
        self.assertEqual(pe_bytes(self.pe,0x4825ea,2),bytes.fromhex('6a03'))
        self.assertEqual(pe_bytes(self.pe,0x4a8404,2),bytes.fromhex('6a08'))
        self.assertEqual(pe_bytes(self.pe,0x4a87e2,2),bytes.fromhex('424f'))
        self.assertEqual(pe_bytes(self.pe,0x483fd2,3),bytes.fromhex('83f840'))
        self.assertEqual(pe_bytes(self.pe,0x40d9b8,7),bytes.fromhex('6a0abf40bae900'))
    def test_dead_state_hides_native_avatar_passes(self):
        states,_=xfs.parse_epa(xfs.read_entry(ARCHIVE,self.toc['tank8.epa']))
        self.assertEqual(states[14]['name'],'dead')
        for va in [0x4c34aa,0x4c3742,0x4c3e89,0x4c4139]:
            self.assertEqual(pe_bytes(self.pe,va,4),bytes.fromhex('8378240e'))
            branch=va+(10 if va==0x4c3e89 else 4)
            self.assertEqual(pe_bytes(self.pe,branch,1),b'\x74')
        for va,name in [(0x55565c,b'AvataTexture1'),(0x556914,b'AvataTexture2'),(0x556900,b'AvataEffectTexture1'),(0x5568ec,b'AvataEffectTexture2')]:
            self.assertEqual(pe_bytes(self.pe,va,len(name)+1),name+b'\x00')
    def test_shoot_blast_pcm_matches_original(self):
        archive=ROOT.parent/'GunboundClassic/gunbound-launcher/TestClient/sound.xfs'
        toc={e['name']:e for e in xfs.read_toc(archive)}
        timing=json.loads((ROOT/'assets/openbound/classic/shot_timing.json').read_text())['records']
        for record in timing:
            if record['game_id']!=8:continue
            self.assertEqual(record['spawn_ticks'],[1])
            for role,entry in [('fire','82fire.xes'),('blast','82blast.xes')]:
                info=record['sounds'].get(role,{})
                self.assertTrue(info)
                path=ROOT/info['resource'].removeprefix('res://')
                with wave.open(str(path),'rb')as audio:
                    channels,bits,rate=audio.getnchannels(),audio.getsampwidth()*8,audio.getframerate();align=channels*bits//8
                    actual=struct.pack('<HHIIHH',1,channels,rate,rate*align,align,bits)+audio.readframes(audio.getnframes())
                self.assertEqual(actual,xfs.read_entry(archive,toc[entry]))
if __name__=='__main__':unittest.main()
