"""Grub (client type 12) characterdata.dat row -> assets/openbound/grub/combat_native.json.

Cell layout of each 13-cell weapon block (0x41da80, see Lightning/Mage): power
[i..i+2], dimension [i+3..], aspect [i+6..], electric radius [i+9], attack flags
[i+10], shock [i+11], secondary [i+12]. Grub's secondary cell is the constant speed
(24.8 units per tick) of every ricochet of T2 [69] and SS [82] (cell 0x35ec).
"""
import hashlib
import json
from pathlib import Path
import struct
import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
PE_SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
DAT_SHA = 'b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf'
TYPE = 12

def native_rows():
    raw = (ROOT / '.tools/gunbound-client/characterdata.dat').read_bytes()
    assert hashlib.sha256(raw).hexdigest() == DAT_SHA
    for offset in [0, 4, 8]:
        try:
            decoded = xfs.lzhuf(raw[offset:], 16 * 332)
            if len(decoded) == 16 * 332 and struct.unpack_from('<3i', decoded) == (28, 24, 0):
                return [list(struct.unpack_from('<83i', decoded, row * 332)) for row in range(16)]
        except (ValueError, IndexError):
            pass
    raise ValueError('Invalid DAT')

def main():
    assert hashlib.sha256((ROOT / '.tools/mobile-animation-port/GunBound.gme').read_bytes()).hexdigest() == PE_SHA
    row = native_rows()[TYPE]
    weapons = []
    for base in (44, 57, 70):
        assert len(set(row[base:base + 3])) == 1 and len(set(row[base + 3:base + 6])) == 1 and len(set(row[base + 6:base + 9])) == 1
        weapons.append(dict(power=row[base], dimension=row[base + 3], aspect=row[base + 6], electric_radius=row[base + 9],
                            flags=row[base + 10], shock=row[base + 11], secondary=row[base + 12]))
    catalog = dict(binary_sha256=PE_SHA, characterdata_sha256=DAT_SHA, type=TYPE, row=row, weapons=weapons,
                   body=dict(vulnerability=row[21], hp=row[22], shield=row[23], shield_regen=row[24], force=row[25], time_factor=row[29],
                             delay_base=row[28], delay_cost=[row[30], row[31], row[32]], gravity=row[40],
                             aim=[dict(low=row[4], high=row[3]), dict(low=row[10], high=row[9]), dict(low=row[16], high=row[15])]))
    path = ROOT / 'assets/openbound/grub/combat_native.json'
    path.write_text(json.dumps(catalog, indent=2) + '\n')
    print('Grub:', weapons)

if __name__ == '__main__':
    main()
