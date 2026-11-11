"""Execute pinned Trico x86 consumers in Unicorn; no port code is imported."""
import hashlib
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/tools/grub_oracle'))
import emu
from emu import UC_X86_REG_ECX, UC_X86_REG_EDX, UC_X86_REG_ESP, Emu

SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
emu.PE = str(ROOT / '.tools/gunbound-client/GunBound.gme')


def machine():
    assert hashlib.sha256(Path(emu.PE).read_bytes()).hexdigest() == SHA
    e = Emu()
    e.init_keys()
    world = e.alloc(0x800000)
    e.w32(0x5b3484, world)
    e.w32(world + 0x6a7720, 1800)
    e.w32(world + 0x6a7724, 1800)
    e.setcell(0xe9bed8, 360)
    e.set_flag(world + 0x6a7f74, True)
    e.hook_fn(0x52022d, lambda m: m.alloc(m.r32(m.uc.reg_read(UC_X86_REG_ESP) + 4) + 64))
    e.hook_fn(0x525c4f, lambda _: 1)
    e.hook_fn(0x406710, lambda _: 0)
    shell = e.alloc(0x5000)
    for off in range(0x40, 0x3f00, 0x224):
        e.setcell(shell + off, 0)
    for off in (0xf42, 0xf45, 0xf4c, 0x3918, 0x391b, 0xf3c):
        e.set_flag(shell + off, False)
    e.setcell(shell + 0x40, 500 * 256)
    e.setcell(shell + 0x264, 400 * 256)
    return e, shell


def t2(theta, index, velocity, acceleration, ticks=55, position=(500, 400)):
    e, shell = machine()
    e.setcell(shell + 0x40, position[0] * 256)
    e.setcell(shell + 0x264, position[1] * 256)
    e.w32(shell, 0x555c34 if index == 2 else 0x5564d0)
    e.w32(shell + 0x3f9c, theta + index * 180)
    e.w32(shell + 0x3fa0, -8 if theta < 91 else 8)
    e.w32(shell + 0x3fa4, 2)
    for off in (0x3fa8, 0x41cc):
        e.setcell(shell + off, -1000000)
    for off in (0x43f0, 0x4614):
        e.setcell(shell + off, 0)
    for off, v in zip((0x488, 0x6ac, 0xaf4, 0xd18), (*velocity, *acceleration)):
        e.setcell(shell + off, v)
    contacts = []
    def contact(m):
        contacts.append({'position_fp': [m.getcell(shell + o) for o in (0x40, 0x264)],
                         'sweep_fp': [m.getcell(shell + o) for o in (0x488, 0x6ac)],
                         'heading': m.getcell(shell + 0x1c2c)})
        return 0
    e.hook_fn(0x455cc0, contact, pop=4)
    rows = []
    for n in range(1, ticks + 1):
        e.call(0x48f1c0 if index == 2 else 0x4a4610, ecx=shell)
        rows.append({'tick': n, 'removed': bool(e.r8(shell + 0x14)), 'center_fp': [e.getcell(shell + o) for o in ((0x40, 0x264) if index == 2 else (0x3fa8, 0x41cc))],
                     'published_fp': [e.getcell(shell + o) for o in (0x40, 0x264)],
                     'velocity_fp': [e.getcell(shell + o) for o in (0x488, 0x6ac)],
                     'phase_after': e.rs32(shell + 0x3f9c), 'radius_after': e.rs32(shell + 0x3fa4),
                     'contact': contacts[-1]})
        if rows[-1]['removed']:
            break
    assert not e.unmapped
    return {'theta': theta, 'index': index, 'position': position, 'velocity': velocity, 'acceleration': acceleration, 'ticks': rows}


def initializer(weapon):
    sys.path.insert(0, str(ROOT / "scripts"))
    import gunbound_xfs
    raw = (ROOT / ".tools/gunbound-client/characterdata.dat").read_bytes()
    assert hashlib.sha256(raw).hexdigest() == "b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf"
    row = struct.unpack_from("<83i", gunbound_xfs.lzhuf(raw, 16 * 332), 3 * 332)
    e, shell = machine()
    world = e.r32(0x5b3484)
    for i, value in enumerate(row):
        e.setcell(world + 0xf0384 + 3 * 0xb1ac + i * 0x224, value)
    e.call(0x41da80, args=[world, shell, 0 if weapon == 2 else weapon, 1 if weapon == 2 else 3, weapon == 2], ecx=3)
    assert not e.unmapped
    return {"weapon": weapon, "width": e.getcell(shell + 0x3198), "power": e.getcell(shell + 0x1e54)}


def ss(position=(500, 400), width=50):
    e, shell = machine()
    e.w32(shell, 0x5565f8)
    e.setcell(shell + 0xf54, position[0])
    e.setcell(shell + 0x1178, position[1])
    e.setcell(shell + 0x3198, width)
    # Native impact initializer; replay mode suppresses only flame allocation.
    e.call(0x4ad230, ecx=shell)
    initial_seed = e.r32(shell + 0x3f9c)
    effects = []
    def blast(m):
        effects.append([struct.unpack('<i', struct.pack('<I', m.uc.reg_read(r)))[0] for r in (UC_X86_REG_EDX, UC_X86_REG_ECX)])
        return 0
    e.hook_fn(0x431d90, blast, pop=32)
    rows = []
    for n in range(1, 23):
        effects.clear()
        e.call(0x4ae0f0, ecx=shell)
        rows.append({'tick': n, 'seed': e.r32(shell + 0x3f9c), 'counter': e.rs32(shell + 0x3fa0),
                     'removed': e.r8(shell + 0x14), 'blasts': effects.copy()})
        if rows[-1]['removed']:
            break
    assert not e.unmapped
    return {'position': position, 'width': width, 'initial_seed': initial_seed, 'ticks': rows}


def contact(start, end, floor):
    e, shell = machine()
    world = e.r32(0x5b3484)
    e.w32(world + 0x6a7720, 400)
    e.w32(world + 0x6a7724, 300)
    cells = bytearray(400 * 300)
    cells[floor * 400:] = bytes([1]) * ((300 - floor) * 400)
    terrain = e.alloc(len(cells))
    e.uc.mem_write(terrain, bytes(cells))
    e.w32(world + 0x6a773c, terrain)
    for axis, (po, vo) in enumerate(((0x40, 0x488), (0x264, 0x6ac))):
        e.setcell(shell + po, end[axis])
        e.setcell(shell + vo, end[axis] - start[axis])
    for va, pop in ((0x436dc0, 12), (0x436ec0, 8), (0x436bd0, 12),
                    (0x4510f0, 4), (0x451030, 4), (0x4511b0, 4)):
        e.hook_fn(va, lambda _: 0, pop=pop)
    e.hook_fn(0x450e10, lambda _: 0, pop=4)  # no mobiles in this terrain probe
    e.call(0x455cc0, ecx=shell, args=[8])
    assert not e.unmapped
    return {'start_fp': start, 'end_fp': end, 'floor': floor,
            'hit': bool(e.call(0x4065a0, eax=shell + 0xf45) & 0xff),
            'point': [e.getcell(shell + o) for o in (0xf54, 0x1178)]}


def main():
    cases = [t2(theta, i, v, a) for theta, v, a in
             ((45, (1800, -1600), (17, 23)), (135, (-1800, -1600), (-17, 23)),
              (90, (0, -1500), (0, 27)), (91, (-20, -1500), (7, 27))) for i in (0, 1, 2)]
    cases += [t2(45, 1, (100, 0), (0, 0), 2, (1, 400)),
              t2(45, 0, (-100, 0), (0, 0), 2, (1799, 400))]
    contacts = []
    for theta, vx in ((45, 1800), (135, -1800)):
        for i in (0, 1, 2):
            sample = t2(theta, i, (vx, 1600), (0, 0), 1)
            start = [200 * 256, 145 * 256]
            end = [v - d for v, d in zip(sample['ticks'][0]['published_fp'], (300 * 256, 255 * 256))]
            for floor in (150, 200):
                c = contact(start, end, floor)
                c.update(theta=theta, index=i, velocity=[vx, 1600])
                contacts.append(c)
    result = {'binary_sha256': SHA, 'contacts': contacts, 'initializers': [initializer(w) for w in (1, 2)], 't2': cases, 'ss': [ss(p, w) for p, w in
              (((500, 400), 50), ((1500, 400), 50), ((5, -100), 51))]}
    (ROOT / 'tests/fixtures/trico_native.json').write_text(json.dumps(result, indent=2) + '\n')
    print('Trico fixtures:', len(cases), 'T2,', len(result['ss']), 'SS')


if __name__ == '__main__':
    main()
