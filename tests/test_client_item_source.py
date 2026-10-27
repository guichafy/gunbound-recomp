"""Independent original-frame oracles for the item window adaptation (REQ-48)."""
import hashlib
import json
from pathlib import Path
import sys
import unittest
import tempfile
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from read_gunbound_xfs import archive, extract
from decode_gunbound_img import frames

class ClientItemSource(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        raw=(ROOT/'.tools/gunbound-client/graphics.xfs').read_bytes()
        cls.raw=raw; idx=archive(raw)['entries']
        cls.source={name:frames(extract(raw,idx[name+'.img'])) for name in ['item1','item2','bulletiteml','teleport1','teleport2','playmode']}
        cls.catalog=json.loads((ROOT/'assets/xfs/items/catalog.json').read_text())
    def test_wrong_build_is_rejected_before_outputs(self):
        from import_xfs_items import build as items
        from import_xfs_map import build as map_build
        with tempfile.TemporaryDirectory() as tmp:
            source=Path(tmp)/'graphics.xfs'
            source.write_bytes(b'not the authorized client build')
            for importer in [items,map_build]:
                with self.assertRaisesRegex(ValueError, 'Unsupported graphics.xfs SHA'):
                    importer(source)

    def test_original_button_pixels_and_states(self):
        # Independent mapping by visual identity of the decoded client frames.
        cases=[('BungeShot','item1',0),('PowerUp','item1',2),('Blood','item1',4),('EnergyUp1','item1',12),('ChangeWind','item1',28),('Dual','item2',0),('DualPlus','item2',2),('Thunder','item2',10),('EnergyUp2','item2',12),('Teleport','item2',18),('TeamTeleport','item2',20)]
        for name,entry,normal in cases:
            sheet=Image.open(ROOT/f'assets/xfs/items/Item{name}.png').convert('RGBA')
            for state,number in enumerate([normal,normal,normal+1,normal+1]):
                native=self.source[entry][number][0]; w=native.width+2
                self.assertEqual(sheet.crop((state*w+1,1,state*w+1+native.width,35)).tobytes(),native.tobytes(),(name,state))
                self.assertIsNone(sheet.crop((state*w,0,(state+1)*w,1)).getbbox())
    def test_teleport_registration_and_reverse_are_exact(self):
        for entry,name,cell,pivot,cols in [('teleport1','Teleport1',(190,192),(95,100),10),('teleport2','Teleport2',(190,192),(95,100),10),('bulletiteml','TeleportBullet',(43,39),(30,18),12)]:
            sheet=Image.open(ROOT/f'assets/xfs/items/{name}.png').convert('RGBA')
            for i,(im,(px,py)) in enumerate(self.source[entry]):
                expected=Image.new('RGBA',cell); expected.alpha_composite(im,(pivot[0]+px,pivot[1]+py))
                x=i%cols*cell[0];y=i//cols*cell[1]
                self.assertEqual(sheet.crop((x,y,x+cell[0],y+cell[1])).tobytes(),expected.tobytes(),(entry,i))
        self.assertEqual([(im.tobytes(),p) for im,p in self.source['teleport2']],[(im.tobytes(),p) for im,p in reversed(self.source['teleport1'])])
    def test_manifest_and_native_locked_banner(self):
        self.assertEqual(hashlib.sha256(self.raw).hexdigest(),self.catalog['graphics_sha256'])
        for name,record in self.catalog['files'].items():
            path=ROOT/record['file'].removeprefix('res://')
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),record['sha256'])
            with Image.open(path) as image:
                self.assertEqual(list(image.size),record['size'])
        self.assertEqual(Image.open(ROOT/'assets/xfs/items/MatchStatus.png').convert('RGBA').tobytes(),self.source['playmode'][15][0].tobytes())

if __name__=='__main__':unittest.main()
