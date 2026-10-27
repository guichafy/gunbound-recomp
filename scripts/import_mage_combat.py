"""Reproduce Mage native parameters and independent numeric fixtures from PE/DAT."""
import hashlib
import json
import math
from pathlib import Path
import struct

import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
PE_SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
DAT_SHA = 'b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf'


def mage_row():
    raw = (ROOT / '.tools/gunbound-client/characterdata.dat').read_bytes()
    assert hashlib.sha256(raw).hexdigest() == DAT_SHA
    for offset in [0, 4, 8]:
        try:
            decoded = xfs.lzhuf(raw[offset:], 16 * 332)
            if len(decoded) == 16 * 332 and struct.unpack_from('<3i', decoded) == (28, 24, 0):
                return list(struct.unpack_from('<83i', decoded, 332))
        except (ValueError, IndexError):
            continue
    raise ValueError('Invalid characterdata stream')


def main():
    assert hashlib.sha256((ROOT / '.tools/mobile-animation-port/GunBound.gme').read_bytes()).hexdigest() == PE_SHA
    row = mage_row()
    weapons = []
    for offset in [44, 57, 70]:
        weapons.append(dict(power=row[offset], dimension=row[offset+3], aspect=row[offset+6], flags=row[offset+9], emp=row[offset+11]))
    path = ROOT / 'assets/openbound/mage/original/combat_native.json'
    path.write_text(json.dumps(dict(binary_sha256=PE_SHA, characterdata_sha256=DAT_SHA, weapons=weapons), indent=2)+'\n')
    fixtures = []
    for shot in weapons:
        for dx in range(-70, 71, 7):
            for dy in [-44, -40, -20, -1, 0, 1, 20, 40, 44]:
                x = math.trunc(dx*100/shot['aspect'])
                r = shot['dimension']//2+10
                d2 = x*x+dy*dy
                f = math.trunc((r-math.sqrt(d2))*1000/r) if d2<r*r else 0
                fixtures.append([dx, dy, shot['dimension'], shot['aspect'], f])
    (ROOT / 'tests/fixtures/mage_damage_native.json').write_text(json.dumps(fixtures)+'\n')
    print(f'Mage native: {weapons}; {len(fixtures)} independent falloff fixtures')


if __name__ == '__main__':
    main()
