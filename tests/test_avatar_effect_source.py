"""State compatibility is independent of constant registration and image density."""
import json,sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from prepare_xfs_avatar_hd import source_piece
class EffectSource(unittest.TestCase):
    def test_every_head_light_uses_normal_anatomy(self):
        rows=json.loads((ROOT/'assets/xfs/avatars/catalog.json').read_text())['records']
        heads=[r for r in rows if r['category']==0 and len(r['layers'])==2]
        self.assertEqual(len(heads),20)
        for row in heads:
            with self.subTest(key=row['key']):
                _,meta=source_piece(row,1)
                self.assertGreaterEqual(meta['source_frame'],11)
                self.assertLess(meta['source_frame'],22)
    def test_devil_reference_has_one_profile_horn(self):
        rows=json.loads((ROOT/'assets/xfs/avatars/catalog.json').read_text())['records']
        row=next(r for r in rows if r['key']=='xfs:0:0:71')
        image,meta=source_piece(row,1)
        self.assertLess(image.width,30,'Normal horn glow is narrow; two frontal horns occupy45px')
        self.assertEqual(meta['reference_state'],'normal')
if __name__=='__main__':unittest.main()
