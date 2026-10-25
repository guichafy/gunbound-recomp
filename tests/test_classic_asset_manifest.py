"""Source contracts recovered from MainAction, EPA and XFS (not C# names)."""
import importlib.util
import json
from pathlib import Path
import unittest
import hashlib
import struct
import wave
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('classic_import', ROOT / 'scripts/import_classic_mobiles.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class ClassicManifest(unittest.TestCase):
    def test_glow_uses_base_epa_and_one_layer(self):
        self.assertEqual(module.table_name('bullet9nl.img'), 'bullet9n.epa')
        self.assertNotIn('bullet14c.img', module.sheet_names(14, 1))
        self.assertNotIn('bullet14c.img', module.sheet_names(14, 2))

    def test_runtime_manifest(self):
        path = ROOT / 'assets/openbound/classic/shot_timing.json'
        self.assertTrue(path.exists(), 'Generated source timing manifest must ship in PCK')
        if not path.exists(): return
        meta = json.loads(path.read_text())
        self.assertEqual(len(meta['records']),48)
        rows={(r['game_id'],r['weapon']):r for r in meta['records']}
        self.assertEqual(rows[14,1]['spawn_ticks'],[1,6,11,16])
        self.assertEqual(rows[13,1]['components_per_spawn'],[4])
        for game_id in range(1,17):
            for weapon in range(3):
                row=rows[game_id,weapon]
                for kind in ['fire','blast']:
                    audio=row['sounds'][kind]
                    if audio['present']:
                        resource = ROOT / audio['resource'].removeprefix('res://')
                        self.assertTrue(resource.exists())
                        with wave.open(str(resource), 'rb') as stream:
                            channels, bits, rate = stream.getnchannels(), stream.getsampwidth()*8, stream.getframerate()
                            align = channels*bits//8
                            header = struct.pack('<HHIIHH',1,channels,rate,rate*align,align,bits)
                            raw = header + stream.readframes(stream.getnframes())
                        self.assertEqual(hashlib.sha256(raw).hexdigest(),audio['sha256'], 'PCM bytes preserve original XES without volume scaling')
                self.assertEqual(sum(row['pose_durations']),row['pose_ticks'])
        self.assertFalse(rows[15,0]['sounds']['blast']['present'])
        self.assertFalse(rows[16,2]['sounds']['blast']['present'])

    def test_imported_composition(self):
        for kind in ['jd','asate','ice','knight','aduka']:
            meta=json.loads((ROOT / f'assets/openbound/{kind}/frames.json').read_text())
            self.assertIn('contact_feet',meta)
            self.assertIn('pose_durations',meta)
            for slot in range(1,4):
                sheets=meta['sheets']; body=sheets.get(f'Bullet{slot}.png',{}); light=sheets.get(f'Bullet{slot}Light.png',{})
                self.assertFalse(body and light and body['entry']==light['entry'], 'Glow-only sheets cannot draw twice')
        dragon=json.loads((ROOT / 'assets/openbound/dragon/frames.json').read_text())
        self.assertNotIn('Bullet1.png',dragon['sheets'])
        self.assertNotIn('Bullet2.png',dragon['sheets'])
        self.assertIn('SSChild.png',dragon['sheets'])
        turtle=json.loads((ROOT / 'assets/openbound/turtle/frames.json').read_text())
        self.assertEqual(turtle['projectile_composition'][0], 'water_ribbon')
        self.assertTrue((ROOT / 'assets/openbound/classic/WaterEffect.png').exists())

if __name__=='__main__': unittest.main()
