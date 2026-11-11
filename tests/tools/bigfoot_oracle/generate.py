"""Independent fixtures: run the pinned x86 MainAction, initializer and consumers.

Requires Unicorn 2.1.4 outside the game/CI environment. No Godot imports.
Geometry helpers are flat/zero in the damage probe; stop before HP/audio/network.
"""
import hashlib
import json
import math
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/tools/grub_oracle'))
from emu import Emu, UC_X86_REG_ESP  # noqa: E402

SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
DAT_SHA = 'b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf'
FIELDS = (0x1e54, 0x2078, 0x229c, 0x24c0, 0x26e4, 0x2908,
          0x2b2c, 0x2d50, 0x2f74)
FRAMES = ((5, (3, 7, 12, 17)), (6, (6, 10)),
          (10, (3, 5, 7, 9, 12, 15, 17, 19)))
ROWS = json.loads((ROOT / '.tools/battle-execution/shots-research/characterdata.json').read_text())


def machine():
    e = Emu()
    e.init_keys()
    world = e.alloc(0x800000)
    e.w32(0x5b3484, world)
    e.hook_fn(0x52022d, lambda em: em.alloc(em.r32(em.uc.reg_read(UC_X86_REG_ESP) + 4) + 64))
    e.hook_fn(0x525c4f, lambda _: 1)  # cell obfuscation only
    for cell, value in ((0x796aa0, 100), (0x794e48, 80), (0xe9ba40, 10)):
        e.setcell(cell, value)
    return e, world


def emission(event, frame, theta, power):
    e, _ = machine()
    actor = e.alloc(0x20000)
    for off, value in ((0x4d90, theta), (0x7864, power), (0x90c, 1000),
                       (0xb30, 800), (0x5844, 20), (0x5a68, 10),
                       (0x53fc, 7), (0x5620, 3), (0x5c8c, 23), (0x5eb0, 11)):
        e.setcell(actor + off, value)
    for off in (0xbfbe, 0xbfc1, 0xbfcd):
        e.set_flag(actor + off, False)
    calls = []
    for va, count in ((0x42bbb0, 13), (0x42de70, 12)):
        def spawn(em, address=va, n=count):
            sp = em.uc.reg_read(UC_X86_REG_ESP)
            args = [em.rs32(sp + 4 + 4 * i) for i in range(n)]
            start = 7 if address == 0x42bbb0 else 6
            calls.append({'theta': args[start], 'power': args[start + 1],
                          'divisor': args[-1]})
            return 0
        e.hook_fn(va, spawn, pop=count * 4)
    # All components of the event have been emitted before audio. Stop there.
    e.hook_fn(0x4ee9b0, lambda em: em.uc.emu_stop())
    e.hook_fn(0x43a530, lambda _: 1)
    e.call(0x489580, args=[event, frame], ecx=actor)
    assert not e.unmapped
    return calls


def initialize(weapon, attack, dig):
    e, world = machine()
    shell = e.alloc(0x5000)
    for i, value in enumerate(ROWS['rows'][4]):
        e.setcell(world + 0xf0384 + 4 * 0xb1ac + i * 0x224, value)
    e.w8(shell + 0x3c, 3)
    e.setcell(world + 0x50688 + 3 * 0x1120, attack)
    e.setcell(world + 0x50464 + 3 * 0x1120, dig)
    e.call(0x41da80, args=[world, shell, weapon, (4, 6, 8)[weapon], weapon == 2], ecx=4)
    assert not e.unmapped
    return e, shell


def damage(weapon, attack, dig, dx, dy, percent=100, force=0, vulnerability=100):
    e, shell = initialize(weapon, attack, dig)
    actor = e.alloc(0x20000)
    for off, value in ((0x17e4, percent), (0x15c0, force)):
        e.setcell(shell + off, value)
    # Flat body at hotspot200,200; center200,188, no defense flags/resistance.
    for off, value in ((0x90c, 200), (0xb30, 200), (0xf78, 24),
                       (0x13c0, 0), (0x6520, vulnerability)):
        e.setcell(actor + off, value)
    e.set_flag(actor + 0x908, True)
    e.hook_fn(0x45f300, lambda _: 0, pop=4)
    e.hook_fn(0x45f5d0, lambda _: 0)
    result = []
    def stop(em):
        result.append(em.rs32(em.uc.reg_read(UC_X86_REG_ESP) + 0x14))
        em.uc.emu_stop()
    e.watch[0x45e758] = stop  # final amount, before HP/pose/network side effects
    e.call(0x45db20, args=[actor, 200 - dx, 188 - dy, 0, 0], ecx=shell)
    assert not e.unmapped
    return result[0] if result else 0


def crater(dimension, aspect):
    e, _ = machine()
    terrain = e.alloc(0x1000)
    bitmap = e.alloc(200 * 200)
    e.w32(terrain + 0x18, 200)
    e.w32(terrain + 0x1c, 200)
    e.w32(terrain + 0x34, bitmap)
    e.uc.mem_write(bitmap, bytes([1]) * 40000)
    e.hook_fn(0x4e4bc0, lambda _: 0, pop=4)  # visual blackmask only
    e.call(0x4e4450, args=[100, 100, aspect], eax=dimension, esi=terrain)
    assert not e.unmapped
    pixels = bytes(e.uc.mem_read(bitmap, 40000))
    result = []
    for y in range(200):
        xs = [x for x in range(200) if pixels[y * 200 + x] == 0]
        if xs:
            assert xs == list(range(xs[0], xs[-1] + 1))
            result.append([y - 100, xs[0] - 100, xs[-1] + 1 - 100])
    return result


def main():
    assert hashlib.sha256((ROOT / '.tools/mobile-animation-port/GunBound.gme').read_bytes()).hexdigest() == SHA
    assert hashlib.sha256((ROOT / '.tools/gunbound-client/characterdata.dat').read_bytes()).hexdigest() == DAT_SHA
    assert ROWS['sha256'] == DAT_SHA
    # 42ccfa..42cd42: native float32 sine LUT, _ftol toward zero, SHL8/IDIV10.
    # Independent arithmetic over PE bytes, not the port's copied LUT asset.
    sine = struct.unpack('<360f', Emu().uc.mem_read(0x54c240, 1440))
    output = {'binary_sha256': SHA, 'dat_sha256': DAT_SHA, 'emission': [],
              'initialization': [], 'damage': [], 'craters': []}
    for weapon, (event, frames) in enumerate(FRAMES):
        for theta in (18, 23, 30, 40, 140, 150, 157, 162):
            for power in (1, 210, 420):
                shells = []
                for frame in frames:
                    for call in emission(event, frame, theta, power):
                        angle, strength = call['theta'], call['power']
                        call['velocity_fp'] = [math.trunc((math.trunc(sine[(angle + 90) % 360] * strength) << 8) / 10),
                                               -math.trunc((math.trunc(sine[angle % 360] * strength) << 8) / 10)]
                        shells.append(dict(call, tick=frame))
                assert len(shells) == (4, 6, 8)[weapon]
                output['emission'].append(dict(weapon=weapon, theta=theta, power=power, shells=shells))
        for attack, dig in ((0, 0), (1, 1), (17, 49), (50, 50), (-17, -49), (-50, -50)):
            e, shell = initialize(weapon, attack, dig)
            fields = [e.getcell(shell + off) for off in FIELDS]
            output['initialization'].append(dict(weapon=weapon, attack=attack, dig=dig, fields=fields))
            for dx, dy in ((0, 0), (10, 0), (-10, 5), (48, 0), (0, 36)):
                for percent, force, vulnerability in ((100, 0, 100), (133, 27, 83)):
                    amount = damage(weapon, attack, dig, dx, dy, percent, force, vulnerability)
                    output['damage'].append(dict(weapon=weapon, attack=attack, dig=dig, dx=dx, dy=dy,
                                                percent=percent, force=force, vulnerability=vulnerability, amount=amount))
            dimension, aspect = fields[3], fields[6]
            output['craters'].append(dict(weapon=weapon, attack=attack, dig=dig,
                                          dimension=dimension, aspect=aspect, spans=crater(dimension, aspect)))
    path = ROOT / 'tests/fixtures/bigfoot_native.json'
    path.write_text(json.dumps(output, separators=(',', ':')) + '\n')
    print({key: len(value) for key, value in output.items() if isinstance(value, list)})


if __name__ == '__main__':
    main()
