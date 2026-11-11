"""Execute isolated Ice consumers in the pinned PE; requires Unicorn 2.1.4.

No Godot imports. UI/network and terrain publication are observation boundaries.
"""
import hashlib
from functools import lru_cache
import json
from pathlib import Path
import sys
import struct

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/tools/grub_oracle'))
import emu  # noqa: E402
from emu import Emu, UC_X86_REG_ESP, UC_X86_REG_EBX, UC_X86_REG_ECX  # noqa: E402
sys.path.insert(0, str(ROOT / 'scripts'))
import gunbound_xfs as xfs  # noqa: E402

SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
DAT_SHA = 'b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf'
PE = ROOT / '.tools/gunbound-client/GunBound.gme'
emu.PE = str(PE)  # Emu opens exactly this validated input, not its legacy path.
FIELDS = (0xb728, 0xb94c, 0xbb70, 0xbd94)


def machine():
    assert hashlib.sha256(Path(emu.PE).read_bytes()).hexdigest() == SHA
    e = Emu()
    e.init_keys()
    world = e.alloc(0x800000)
    e.w32(0x5b3484, world)
    e.hook_fn(0x52022d, lambda em: em.alloc(em.r32(em.uc.reg_read(UC_X86_REG_ESP) + 4) + 64))
    e.hook_fn(0x525c4f, lambda _: 1)
    e.setcell(0x796aa0, 100)
    e.setcell(0xe9ba40, 10)  #40d8e0, native blast radius addition
    e.setcell(0xe55ab8, 20)  # 40d8e0: PUSH14h -> protected setter
    e.set_flag(world + 0x6a7f74, False)
    return e, world


@lru_cache(maxsize=1)
def character_rows():
    raw = (ROOT / '.tools/gunbound-client/characterdata.dat').read_bytes()
    assert hashlib.sha256(raw).hexdigest() == DAT_SHA
    decoded = xfs.lzhuf(raw, 16 * 332)
    return tuple(struct.unpack_from('<83i', decoded, i * 332) for i in range(16))


def target(e, values, alive=True, immune=False, source_type=0, hp=1000, shield=0):
    actor = e.alloc(0x20000)
    for off, value in zip(FIELDS, values):
        e.setcell(actor + off, value)
    for off, value in ((0x90c, 200), (0xb30, 200), (0xf78, 24), (0x13c0, 0),
                       (0x6520, 100), (0x6968, hp), (0x6fd4, shield)):
        e.setcell(actor + off, value)
    e.set_flag(actor + 0x908, alive)
    e.set_flag(actor + 0xbff7, immune)
    e.w32(actor + 0x24, source_type)
    vt = e.alloc(16)
    e.w32(actor, vt)
    e.w32(vt + 4, 0x7d000200)
    e.hook_fn(0x7d000200, lambda _: 0, pop=4)  # pose publication only
    return actor


def initialize(source_type, weapon, attack=0, dig=0):
    e, world = machine()
    rows = character_rows()
    for i, value in enumerate(rows[source_type]):
        e.setcell(world + 0xf0384 + source_type * 0xb1ac + i * 0x224, value)
    shell = e.alloc(0x5000)
    e.w8(shell + 0x3c, 0)
    e.setcell(world + 0x50688, attack)
    e.setcell(world + 0x50464, dig)
    e.call(0x41da80, args=[world, shell, weapon, 1, weapon == 2], ecx=source_type)
    flags = sum((8 >> i) for i in range(4) if e.call(0x4065a0, eax=shell + 0x33bc + i * 3) & 0xff)
    assert not e.unmapped
    return {'source_type': source_type, 'weapon': weapon, 'attack': attack, 'dig': dig,
            'power': e.getcell(shell + 0x1e54), 'dimension': e.getcell(shell + 0x24c0),
            'aspect': e.getcell(shell + 0x2b2c), 'flags': flags}


def damage_probe(values, flags=2, vector=(0, 0, 5, 0), dx=0, power=310,
                 alive=True, immune=False, source_type=0, hp=1000, shield=0, defense_flags=0, bottom=0):
    e, world = machine()
    shell = e.alloc(0x5000)
    actor = target(e, values, alive, immune, source_type, hp, shield)
    e.setcell(actor + 0x13c0, bottom)
    for i in range(3):
        e.set_flag(actor + 0x9ce4 + 3 * i, bool(defense_flags & (8 >> i)))
    for off, value in ((0x1e54, power), (0x2078, power), (0x229c, power),
                       (0x24c0, 56), (0x26e4, 56), (0x2908, 56),
                       (0x2b2c, 124), (0x2d50, 124), (0x2f74, 124),
                       (0x17e4, 100), (0x15c0, 0)):
        e.setcell(shell + off, value)
    for i in range(4):
        e.set_flag(shell + 0x33bc + i * 3, bool(flags & (8 >> i)))
    e.setcell(world + 0x475c8, 0)
    e.setcell(world + 0x1a1f48, 0)  # material0
    e.hook_fn(0x45f300, lambda _: 0, pop=4)
    e.hook_fn(0x45f5d0, lambda _: 0)
    e.hook_fn(0x436860, lambda _: 0, pop=8)  # damage text only
    e.setcell(world + 0x45354, 0)  # offline game mode
    address = e.alloc(16) if vector is not None else 0
    if vector is not None:
        for i, v in enumerate(vector):
            e.w32(address + 4 * i, v)
    computed = []
    e.watch[0x45e758] = lambda em: computed.append(em.uc.reg_read(UC_X86_REG_EBX))
    center_y = 200 - ((24 - bottom) // 2 + bottom)
    e.call(0x45db20, args=[actor, 200 - dx, center_y, 1 if vector else 0, address], ecx=shell)
    assert not e.unmapped
    return {'before': list(values), 'flags': flags, 'vector': vector, 'dx': dx,
            'power': power, 'alive': alive, 'immune': immune, 'source_type': source_type,
            'hp': hp, 'shield': shield, 'defense_flags': defense_flags,
            'damage': computed[0] if computed else 0,
            'after': [e.getcell(actor + off) for off in FIELDS],
            'hp_after': e.getcell(actor + 0x6968), 'shield_after': e.getcell(actor + 0x6fd4)}


def ss_probe(values, distance=0, alive=True, immune=False, source_type=0):
    e, _ = machine()
    shell = e.alloc(0x5000)
    actor = target(e, values, alive, immune, source_type)
    for off, value in ((0xf54, 200 - distance), (0x1178, 190), (0x33c8, 130)):
        e.setcell(shell + off, value)
    e.hook_fn(0x48de60, lambda _: 0)  # base blast precedes this state-only probe
    e.hook_fn(0x4373c0, lambda _: 0, pop=16)  # SS visual flame
    e.hook_fn(0x4372f0, lambda _: 0, pop=20)  # damage number/pose effect record
    # Keep the REAL425ac0 radius calculation; stub only lookup by slot.
    e.hook_fn(0x4206f0, lambda em: actor if em.uc.reg_read(UC_X86_REG_ECX) == 0 else 0, pop=4)
    e.call(0x4759b0, ecx=shell)
    assert not e.unmapped
    return {'before': list(values), 'distance': distance, 'alive': alive,
            'immune': immune, 'source_type': source_type,
            'after': [e.getcell(actor + off) for off in FIELDS]}


def main():
    pe = ROOT / '.tools/gunbound-client/GunBound.gme'
    assert hashlib.sha256(pe.read_bytes()).hexdigest() == SHA
    cases = []
    for values in ((0, 0, 0, 0), (-20, -3, -8, -1), (15, 19, 20, 49),
                   (20, 45, 46, 50), (50, 50, 50, 50)):
        for shield in (0, 10000):
            cases.append(damage_probe(values, shield=shield))
    for kw in ({'dx': 100}, {'power': 0}, {'alive': False}, {'immune': True},
               {'source_type': 14}, {'hp': 1}, {'hp': 0}, {'source_type': 10}):
        cases.append(damage_probe((0, 0, 0, 0), **kw))
    for flags in range(16):
        cases.append(damage_probe((3, 9, 17, 25), flags=flags, vector=None))
    ss = [ss_probe(v, **kw) for v in ((0, 0, 0, 0), (-8, 15, 19, 20), (20, 21, 49, 50))
          for kw in ({}, {'distance': 129}, {'distance': 130}, {'distance': 131},
                     {'alive': False}, {'immune': True}, {'source_type': 14}, {'source_type': 10})]
    masks = [initialize(t, w) for t in range(16) for w in range(3)]
    init = [initialize(10, w, a, d) for w in (1, 2) for a, d in ((0, 0), (-7, -5), (17, 11))]
    body = [damage_probe(v, defense_flags=8, bottom=2, source_type=4, shield=s, dx=dx) for v in ((0, 0, 0, 0), (5, 9, 45, 17))
            for s in (0, 10000) for dx in (0, 10, 45, 100)]
    result = {'binary_sha256': SHA, 'damage': cases, 'ss': ss, 'initializers': init, 'masks': masks, 'body': body}
    (ROOT / 'tests/fixtures/ice_native.json').write_text(json.dumps(result, indent=2) + '\n')
    print(f'Ice oracle: {len(cases)} damage / {len(ss)} SS cases')


if __name__ == '__main__':
    main()
