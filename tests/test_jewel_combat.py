"""Material triples independently decoded from the pinned source DAT."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'scripts'))
import gunbound_xfs as xfs

class JewelCombatSource(unittest.TestCase):
    def test_all_materials_in_every_native_weapon(self):
        raw=(ROOT/'.tools/gunbound-client/characterdata.dat').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),'b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf')
        decoded=xfs.lzhuf(raw,16*332)
        self.assertEqual(struct.unpack_from('<3i',decoded),(28,24,0))
        data=json.loads((ROOT/'assets/xfs/jewel/combat.json').read_text())
        for vehicle,native in enumerate([1,4,2,0,3,5,6,7,8,9,10,11,12,13,14,15],1):
            row=struct.unpack_from('<83i',decoded,native*332)
            for weapon,base in enumerate([44,57,70]):
                for name,offset in [('power',0),('dimension',3),('aspect',6)]:
                    expected=list(row[base+offset:base+offset+3])
                    self.assertEqual(data['weapons'][str(vehicle)][weapon][name],expected)
                    self.assertEqual(len(set(expected)),1)
