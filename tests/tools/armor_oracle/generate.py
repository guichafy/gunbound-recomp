"""Run Armor's pinned x86 tick; effects are recorded stubs, never game code."""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/tools/grub_oracle'))
from emu import Emu, UC_X86_REG_EBX, UC_X86_REG_ESP  # noqa: E402

SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
FIELDS = [0x1e54, 0x2078, 0x229c, 0x24c0, 0x26e4, 0x2908]
EVIDENCE = ROOT / '.tools/armor-t2'


def pop(va):
    paths = list(EVIDENCE.glob(f'evidence-*/0x{va:x}.asm'))
    assert paths, hex(va)
    values = set(re.findall(r'  RET(?: 0x([0-9a-f]+))?$', paths[0].read_text(), re.M))
    assert len(values) == 1, (hex(va), values)
    return int(values.pop() or '0', 16)


def case(direction=1, values=(236, 237, -239, 56, 57, -59), contacts=(1, 4)):
    e = Emu()
    e.init_keys()
    world = e.alloc(0x800000)
    e.w32(0x5b3484, world)
    e.w32(world + 0x6a7720, 1000)
    e.w32(world + 0x6a7724, 1000)
    e.setcell(0xe9ba40, 10)
    shell = e.alloc(0x4000)
    e.w32(shell, 0x555dac)
    e.w32(shell + 0x8, 1)
    e.w32(shell + 0x3f94, 1)
    for off in range(0x40, 0x3f00, 0x224):
        e.setcell(shell + off, 0)
    for off in (0xf42, 0xf45, 0xf4c, 0x3918, 0x391b, 0x33bc, 0x33bf, 0x33c2, 0x33c5, 0x3f98):
        e.set_flag(shell + off, False)
    e.setcell(shell + 0x40, 100 * 256)
    e.setcell(shell + 0x264, 100 * 256)
    e.setcell(shell + 0x488, direction * 2560)
    e.setcell(shell + 0x6ac, 1280)
    e.setcell(shell + 0xaf4, direction * 7)
    e.setcell(shell + 0xd18, 11)
    for off, value in zip(FIELDS, values):
        e.setcell(shell + off, value)
    e.hook_fn(0x525c4f, lambda _: 1)
    e.hook_fn(0x406710, lambda _: 0)
    # Skip presentation, object registry, network, audio and damage. The two
    # explosion branches and six protected arithmetic chains execute unmodified.
    effects = []
    for va in (0x4262d0, 0x4e4970, 0x4e4d00, 0x450eb0, 0x436ac0, 0x4372f0, 0x437150, 0x4ee9b0):
        def record(emu, address=va):
            effects.append(hex(address))
            return 0
        e.hook_fn(va, record, pop=pop(va))
    # Controlled contact producer: exact fixed-point writeback established by
    # 455cc0/458920 ASM. Also run the real producer in contact_case below.
    tick = [0]
    def contact(emu):
        hit = tick[0] in contacts
        emu.set_flag(shell + 0xf45, hit)
        if hit:
            for fp, integer in ((0x40, 0xf54), (0x264, 0x1178)):
                n = emu.getcell(shell + fp) >> 8
                emu.setcell(shell + fp, n << 8)
                emu.setcell(shell + integer, n)
        return 0
    e.hook_fn(0x455cc0, contact, pop=4)
    rows = []
    for n in range(1, 7):
        tick[0] = n
        effects.clear()
        e.call(0x4688b0, ecx=shell)
        rows.append({'tick': n, 'position_fp': [e.getcell(shell + o) for o in (0x40, 0x264)],
                     'velocity_fp': [e.getcell(shell + o) for o in (0x488, 0x6ac)],
                     'phase': e.r8(shell + 0x3f9c), 'removed': e.r8(shell + 0x14),
                     'fields': [e.getcell(shell + o) for o in FIELDS], 'effects': effects.copy()})
        if rows[-1]['removed']:
            break
    assert not e.unmapped
    return {'direction': direction, 'initial_fields': list(values), 'contacts': list(contacts), 'ticks': rows}


def contact_case(start, end, floor=150, boxes=()):
    e = Emu()
    e.init_keys()
    world = e.alloc(0x800000)
    e.w32(0x5b3484, world)
    e.w32(world + 0x6a7720, 400)
    e.w32(world + 0x6a7724, 300)
    terrain = e.alloc(400 * 300)
    cells = bytearray(400 * 300)
    for y in range(floor, 300):
        cells[y*400:(y+1)*400] = bytes([1])*400
    e.uc.mem_write(terrain, bytes(cells))
    e.w32(world + 0x6a773c, terrain)
    shell = e.alloc(0x4000)
    for off in range(0x40, 0x3f00, 0x224):
        e.setcell(shell + off, 0)
    for off in (0xf42, 0xf45, 0xf4c, 0x3918, 0x391b, 0x33bc, 0x33bf, 0x33c2, 0x33c5):
        e.set_flag(shell + off, False)
    for axis, (po, vo) in enumerate(((0x40, 0x488), (0x264, 0x6ac))):
        e.setcell(shell+po, end[axis])
        e.setcell(shell+vo, end[axis]-start[axis])
    e.hook_fn(0x525c4f, lambda _: 1)
    for va in (0x436dc0, 0x436ec0, 0x436bd0, 0x4510f0, 0x451030, 0x4511b0):
        e.hook_fn(va, lambda _: 0, pop=pop(va))
    def mobile(emu):
        x = emu.uc.reg_read(UC_X86_REG_EBX)
        y = emu.rs32(emu.uc.reg_read(UC_X86_REG_ESP)+4)
        return int(any(b[0]<=x<=b[2] and b[1]<=y<=b[3] for b in boxes))
    e.hook_fn(0x450e10, mobile, pop=4)
    e.call(0x455cc0, ecx=shell, args=[8])
    assert not e.unmapped
    return {'start_fp': start, 'end_fp': end, 'floor': floor, 'boxes': boxes,
            'contact': bool(e.call(0x4065a0, eax=shell+0xf45)),
            'position_fp': [e.getcell(shell+off) for off in (0x40, 0x264)],
            'point': [e.getcell(shell+off) for off in (0xf54, 0x1178)]}


if __name__ == '__main__':
    assert hashlib.sha256((ROOT / '.tools/mobile-animation-port/GunBound.gme').read_bytes()).hexdigest() == SHA
    result = {'pe_sha256': SHA, 'tick_va': '0x4688b0', 'fields_offsets': [hex(v) for v in FIELDS],
              'scope': 'Real tick with controlled contact and recorded side effects; not whole-client execution.',
              'cases': [case(d) for d in (1, -1)] + [case(contacts=(1,))],
              'contact_cases': [contact_case([200*256,145*256],[200*256,155*256]),
                                contact_case([200*256,145*256],[202*256,148*256]),
                                contact_case([100*256,100*256],[130*256,110*256],300,[[112,90,118,120]]),
                                contact_case([130*256,100*256],[100*256,110*256],300,[[112,90,118,120]]),
                                contact_case([200*256+99,145*256+17],[201*256+133,155*256+77])]}

    target = ROOT / 'tests/fixtures/armor_t2_native.json'
    target.write_text(json.dumps(result, indent=2) + '\n')
    print(target)
