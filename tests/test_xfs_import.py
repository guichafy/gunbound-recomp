"""Actual version280 archive fixtures, not fabricated catalog records."""
import hashlib,json,struct,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from read_gunbound_xfs import archive,extract,avatar_rows,expand
ROOT=Path(__file__).resolve().parents[1]
class XfsImport(unittest.TestCase):
    def setUp(self):
        self.data=(ROOT/'assets/xfs/reference/avatar.xfs').read_bytes()
    def test_directory_and_original_dat_bytes(self):
        index=archive(self.data)
        self.assertEqual(index['version'],280)
        self.assertEqual(len(index['entries']),8)
        for name,row in index['entries'].items():
            self.assertEqual(extract(self.data,row),(ROOT/'assets/xfs/reference'/name).read_bytes())
    def test_actual_catalog_and_signed_stats(self):
        rows=avatar_rows(self.data)
        self.assertEqual(len(rows),562)
        self.assertEqual(sum(r['buyable'] for r in rows),479)
        head=next(r for r in rows if r['file']=='mh.dat' and r['id']==1)
        self.assertEqual((head['name'],head['gold'],head['cash']),('Space Marine',10000,1000))
        self.assertEqual((head['stats']['defense'],head['stats']['popularity']),(3,3))
        roman=next(r for r in rows if r['file']=='fb.dat' and r['id']==5)
        self.assertEqual(roman['stats']['shot_delay'],-3)
    def test_incomplete_downloads_are_rejected(self):
        for data in [b'',self.data[:10],self.data[:1200],self.data[:-4]]:
            with self.assertRaises((ValueError,struct.error)):archive(data)
        row=archive(self.data)['entries']['mh.dat']
        with self.assertRaises(ValueError):extract(self.data[:row['offset']+50],row)
    def test_corrupt_compressed_block_is_rejected(self):
        row=archive(self.data)['entries']['fb.dat']
        damaged=bytearray(self.data);struct.pack_into('<I',damaged,0,0xFFFFFFFF)
        with self.assertRaises(ValueError):extract(damaged,row)
        with self.assertRaises(ValueError):expand(b'',4096)
    def test_argb4444_keeps_black_when_alpha_is_present(self):
        from decode_gunbound_img import frames
        # A black lens/scar has RGB=0 with nonzero explicit alpha. Treating
        # black as a color key would erase the entire accessory.
        data=struct.pack('<II',0,1)+struct.pack('<HH9i',2,0,2,1,0,0,0,0,0,0,4)+struct.pack('<HH',0xF000,0x0000)
        image,_=frames(data)[0]
        self.assertEqual(image.getpixel((0,0)),(0,0,0,255))
        self.assertEqual(image.getpixel((1,0)),(0,0,0,0))
    def test_runtime_frame_manifest_matches_preserved_images(self):
        from PIL import Image
        manifest=json.loads((ROOT/'assets/xfs/shop/catalog.json').read_text())
        self.assertEqual(manifest['xfs_version'],280)
        for entry in manifest['frames'].values():
            path=ROOT/entry['file'].removeprefix('res://')
            with Image.open(path) as image:
                self.assertEqual(list(image.size),entry['size'])
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),entry['sha256'])
    def test_classic_index_matches_launcher_and_server_codes(self):
        import hashlib
        from build_classic_avatar_catalog import MALE_BIT, identity
        classic=json.loads((ROOT/'assets/xfs/avatars/classic.json').read_text())
        self.assertEqual(classic['avatar_xfs_sha256'], hashlib.sha256(self.data).hexdigest())
        self.assertEqual(classic['string_encoding'], 'cp949')
        self.assertEqual(classic['empty_dats'], ['ff.dat'])
        self.assertEqual(classic['unlisted_graphics'], ['ff00001.img', 'sff00001.img'])
        original=[identity(row) for row in avatar_rows(self.data)]
        self.assertEqual(classic['records'], original)
        self.assertEqual(len(original), 562)
        self.assertEqual(sum(row['buyable'] for row in original), 479)
        stored=json.loads((ROOT/'assets/xfs/avatars/catalog.json').read_text())['records']
        self.assertEqual([row['key'] for row in original], [row['key'] for row in stored])
        panda=next(row for row in original if row['key']=='xfs:1:1:71')
        self.assertTrue(panda['description'].endswith('까꿍사냥꾼'))
        def dword(text):
            raw=bytes.fromhex(text)
            return int.from_bytes(raw, 'little')
        def resolve(text):
            code=dword(text)
            self.assertEqual(code >> 24, 0)
            slot=(code >> 16) & 0xFF
            word=code & 0xFFFF
            item_id=word & 0x7FFF
            gender=0 if word & MALE_BIT else 1
            return next(row for row in original if row['slot']==slot and row['id']==item_id and row['gender'] in (gender, 2))
        self.assertEqual(resolve('01000100')['key'], 'xfs:1:0:1')
        self.assertEqual(resolve('01800300')['name'], 'Blue Flag')
        self.assertEqual(resolve('44800000')['name'], 'Rocker Suit')
        self.assertEqual(resolve('43800100')['name'], 'Rocker Hair')
        self.assertEqual(resolve('24800200')['name'], 'Dizzy Glasses')
        self.assertEqual(resolve('A4800300')['name'], 'Bazooka')
        with self.assertRaises(StopIteration):
            resolve('8F800100')
    def test_hd_landscape_is_real_measured_asset(self):
        from PIL import Image
        meta=json.loads((ROOT/'assets/hd/shop/xfs_landscape.json').read_text())
        path=ROOT/meta['file'].removeprefix('res://')
        with Image.open(path) as image:
            self.assertEqual(list(image.size),meta['size'])
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),meta['sha256'])
    def test_runtime_catalog_matches_every_original_record(self):
        data=json.loads((ROOT/'assets/xfs/avatars/catalog.json').read_text())
        rows=data['records']
        original=avatar_rows(self.data)
        self.assertEqual(len(rows),len(original))
        for row,source in zip(rows,original):
            self.assertEqual((row['name'],row['id'],row['gold_price'],row['cash_price'],row['buyable']),
                             (source['name'],source['id'],source['gold'],source['cash'],source['buyable']))
            self.assertEqual(row['native_stats'],source['stats'])
            self.assertEqual(row['bonuses'],[source['stats'][name] for name in data['bonus_order']])
            if row['buyable']:
                self.assertTrue(row['art_available'] and row['layers'])
                self.assertTrue((ROOT/row['portrait'].removeprefix('res://')).is_file())
        self.assertTrue(all(not row['buyable'] for row in data['missing']))
        ghost=next(row for row in rows if row['key']=='xfs:2:3:132')
        self.assertEqual(ghost['layers'][0]['source'].lower(),'mf00132l.img')
    def test_hd_portrait_windows_do_not_contain_neighboring_sprites(self):
        from PIL import Image
        meta=json.loads((ROOT/'assets/hd/shop/xfs_portraits.json').read_text())
        path=ROOT/meta['file'].removeprefix('res://')
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),meta['sha256'])
        self.assertEqual(len(meta['regions']),18)
        with Image.open(path) as image:
            self.assertEqual(list(image.size),meta['size'])
            for x,y,w,h in meta['regions'].values():
                self.assertGreater(w,200)
                self.assertLessEqual(x+w,image.width)
                self.assertLessEqual(y+h,image.height)
                crop=image.crop((x,y,x+w,y+h))
                self.assertIsNotNone(crop.getbbox())
    def test_migration_jobs_cover_every_real_layer_and_portrait(self):
        rows=json.loads((ROOT/'assets/xfs/avatars/catalog.json').read_text())['records']
        jobs=json.loads((ROOT/'assets/hd/avatars/xfs/source/jobs.json').read_text())['jobs']
        existing=json.loads((ROOT/'assets/hd/shop/xfs_portraits.json').read_text())['regions']
        identities=[v['id'] for j in jobs for v in j['variants']]
        self.assertEqual(len(identities),len(set(identities)))
        expected={r['key']+'|layer:'+str(i) for r in rows for i in range(len(r['layers']))}
        expected|={r['key']+'|portrait' for r in rows if r['layers'] and r['key'] not in existing}
        self.assertEqual(set(identities),expected)
        self.assertEqual((len(identities),sum(bool(r['layers']) for r in rows)),(1161,550))
        self.assertEqual(sum(len(r['layers']) for r in rows),629)
    def test_registered_hd_has_real_pixels_and_preserved_sheet_hashes(self):
        from PIL import Image
        meta=json.loads((ROOT/'assets/hd/avatars/xfs/catalog.json').read_text())
        for sheet in meta['sheets'].values():
            path=ROOT/sheet['file'].removeprefix('res://')
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),sheet['sha256'])
            with Image.open(path) as image:
                self.assertEqual(list(image.size),sheet['size'])
                for entry in list(meta['layers'].values())+list(meta['portraits'].values()):
                    if meta['sheets'][entry['sheet']]!=sheet:continue
                    x,y,w,h=entry['region']
                    self.assertGreaterEqual(x,0);self.assertGreaterEqual(y,0)
                    self.assertLessEqual(x+w,image.width);self.assertLessEqual(y+h,image.height)
                    self.assertGreaterEqual(max(w,h),100)
                    self.assertIsNotNone(image.crop((x,y,x+w,y+h)).getchannel('A').getbbox())
if __name__=='__main__':unittest.main()
