"""Catalog the verified native combat fields; never rewrite source assets.

Field consumers: 41c360/41da80, 45d640, 45db20, 432320. The generated
oracle uses Python arithmetic independently of the GDScript implementation.
"""
import hashlib
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PE = ROOT / '.tools/mobile-animation-port/GunBound.gme'
SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
ROSTER = [(1, 2, 'mage/original'), (2, 5, 'bigfoot/original'), (3, 3, 'nak'),
          (4, 1, 'armor'), (5, 4, 'trico'), (6, 6, 'boomer'), (7, 7, 'raon'),
          (8, 8, 'lightning'), (9, 9, 'jd'), (10, 10, 'asate'), (11, 11, 'ice'),
          (12, 12, 'turtle'), (13, 13, 'grub'), (14, 14, 'dragon'),
          (15, 15, 'knight'), (16, 16, 'aduka')]


def pe_bytes(data, va, size):
    header = struct.unpack_from('<I', data, 0x3c)[0]
    count = struct.unpack_from('<H', data, header + 6)[0]
    optional = struct.unpack_from('<H', data, header + 20)[0]
    for index in range(count):
        at = header + 24 + optional + index * 40
        length, rva, raw_size, offset = struct.unpack_from('<IIII', data, at + 8)
        if rva <= va - 0x400000 < rva + max(length, raw_size):
            start = offset + va - 0x400000 - rva
            return data[start:start + size]
    raise ValueError(hex(va))


def factor(dx, dy, dimension, aspect):
    # x86 IDIV before FILD/FSQRT; _ftol after the entire quotient.
    x = math.trunc(dx * 100 / max(aspect, 1))
    radius = dimension // 2 + 10
    squared = x * x + dy * dy
    return math.trunc((radius - math.sqrt(squared)) * 1000 / radius) if squared < radius * radius else 0


def main():
    data = PE.read_bytes()
    assert hashlib.sha256(data).hexdigest() == SHA
    rows = json.loads((ROOT / '.tools/battle-execution/shots-research/characterdata.json').read_text())['rows']
    catalog = {'binary_sha256': SHA, 'bodies': {}, 'tilt': {}}
    for game, native, folder in ROSTER:
        row = rows[native - 1]
        meta = json.loads((ROOT / 'assets/openbound' / folder / 'frames.json').read_text())
        catalog['bodies'][str(game)] = dict(width=row[0], height=row[1], bottom=row[2],
            vulnerability=row[21], flags=row[35], source_type=native - 1,
            # The existing renderer places the native hotspot at24-contact.
            origin_y=24 - meta.get('contact_feet', 0))
    for name, va, count in [('y', 0x5a960c, 6), ('x_large', 0x5a9624, 7), ('x_small', 0x5a9640, 7)]:
        catalog['tilt'][name] = list(struct.unpack('<' + 'i' * count, pe_bytes(data, va, count * 4)))
    row = rows[15]
    catalog['t1'] = {'power': row[44], 'dimension': row[47], 'aspect': row[50], 'flags': row[53]}
    catalog['thor'] = {'aspect': 150, 'flags': 4, 'percent': 100}
    (ROOT / 'assets/openbound/aduka/combat_native.json').write_text(json.dumps(catalog, indent=2) + '\n')
    fixtures = []
    for dimension, aspect in [(64, 120)] + [(value, 150) for value in [44, 46, 48, 50, 52, 54]]:
        for dx in [-64, -43, -32, -17, -1, 0, 1, 17, 32, 43, 64]:
            for dy in [-43, -32, -1, 0, 1, 16, 32, 43]:
                fixtures.append([dx, dy, dimension, aspect, factor(dx, dy, dimension, aspect)])
    fixtures_path = ROOT / 'tests/fixtures/aduka_damage_native.json'
    fixtures_path.parent.mkdir(parents=True, exist_ok=True)
    fixtures_path.write_text(json.dumps(fixtures) + '\n')
    tornado = []
    # Tick order from4ab012..4ab8d6: move, strict bounds/clamp200, two
    # reflections then exit3; acceleration only in the non-tornado branch.
    for vx, vy in [(2000, -500), (-2000, -500), (0, 700), (-199, 700), (199, 700)]:
        for ax, ay in [(69, 240), (-69, 240), (0, 309), (0, 171)]:
            x, y, dx, dy, active, turns = 100 * 256, 200 * 256, vx, vy, True, 0
            trace = []
            for tick in range(100):
                x, y = x + dx, y + dy
                if active:
                    if abs(dx) < 200:
                        dx = -200 if dx < 0 else 200
                    if x // 256 < 68 or x // 256 > 132:
                        turns += 1
                        if turns < 3:
                            dx = -dx
                        else:
                            active = False
                else:
                    dx, dy = dx + ax, dy + ay
                trace.append([x, y, dx, dy, active, min(turns, 3)])
            tornado.append({'velocity': [vx, vy], 'acceleration': [ax, ay], 'trace': trace})
    (fixtures_path.parent / 'aduka_tornado_native.json').write_text(json.dumps(tornado) + '\n')
    print(f'Aduka native combat:16 bodies,3 tilt LUTs,{len(fixtures)} independent falloff fixtures')


if __name__ == '__main__':
    main()
