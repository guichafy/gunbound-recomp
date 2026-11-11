"""Execute the pinned PE mine ground branches and real byte-column probe."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/tools/grub_oracle'))
import emu  # noqa: E402
from emu import Emu, UC_X86_REG_EAX, UC_X86_REG_EDI, UC_X86_REG_EIP  # noqa: E402

SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
emu.PE = str(ROOT / '.tools/gunbound-client/GunBound.gme')


def case(name, layers, y=100, x=32, falling=False, speed=0, ticks=3, weapon=1):
    assert hashlib.sha256(Path(emu.PE).read_bytes()).hexdigest() == SHA
    e = Emu()
    e.init_keys()
    world = e.alloc(0x800000)
    e.w32(0x5b3484, world)
    terrain = world + 0x6a7708
    width, height = 64, 200
    e.w32(terrain + 0x18, width)
    e.w32(terrain + 0x1c, height)
    mask = bytearray(width * height)
    for lo, hi in layers:
        mask[lo * width:hi * width] = b'\1' * ((hi - lo) * width)
    pixels = e.alloc(len(mask))
    e.uc.mem_write(pixels, bytes(mask))
    e.w32(terrain + 0x34, pixels)
    e.setcell(0x794bf0, 15)  # WinMain initialized, never raw protected bytes
    mine = e.alloc(0x4500)
    for off in range(0x40, 0x3f00, 0x224):
        e.setcell(mine + off, 0)
    e.setcell(mine + 0x40, x)
    e.setcell(mine + 0x264, y)
    e.set_flag(mine + 0x391b, False)
    e.w8(mine + 0x3fb4, falling)
    e.w32(mine + 0x3fb8, speed)
    # Exclude slope/pose/target selection only. The original subtraction,
    # protected reads/writes, branches, probe, fall/bounce and bounds execute.
    e.hook_fn(0x4986a0, lambda _: 0, pop=4)
    e.hook_fn(0x450730, lambda _: 0)
    e.hook_fn(0x498070, lambda _: 0, pop=4)
    stop = 0x499217 if weapon == 1 else 0x492912
    e.watch[stop] = lambda m: m.uc.emu_stop()
    queries = []
    e.watch[0x4e4340] = lambda m: queries.append([signed(m.uc.reg_read(UC_X86_REG_EDI)),
                                               signed(m.uc.reg_read(UC_X86_REG_EAX))])
    for ret in (0x4e4379, 0x4e4380):
        e.watch[ret] = lambda m: queries[-1].append(signed(m.uc.reg_read(UC_X86_REG_EAX)))
    rows = []
    for tick in range(1, ticks + 1):
        queries.clear()
        e.call(0x498b60 if weapon == 1 else 0x4921e0, ecx=mine)
        assert e.uc.reg_read(UC_X86_REG_EIP) == stop
        rows.append({'tick': tick, 'y': e.getcell(mine + 0x264),
                     'falling': bool(e.r8(mine + 0x3fb4)), 'speed': e.rs32(mine + 0x3fb8),
                     'lost': bool(e.r8(mine + 0x14)), 'probes': queries.copy()})
        if rows[-1]['lost']:
            break
    assert not e.unmapped
    return {'name': name, 'weapon': weapon, 'width': width, 'height': height,
            'layers': layers, 'x': x, 'y': y, 'falling': falling, 'speed': speed, 'ticks': rows}


def signed(n):
    return n - (1 << 32) if n >= 1 << 31 else n


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pe', type=Path, default=Path(emu.PE))
    parser.add_argument('--output', type=Path, default=ROOT / 'tests/fixtures/raon_ground_native.json')
    args = parser.parse_args()
    if hashlib.sha256(args.pe.read_bytes()).hexdigest() != SHA:
        raise ValueError('Unexpected PE SHA256')
    emu.PE = str(args.pe)
    cases = []
    scenarios = [
        ('thin', [[90, 91], [140, 200]], {}),
        ('buried_solid30', [[60, 160], [180, 200]], {}),
        ('buried_empty30', [[80, 160], [180, 200]], {}),
        ('empty_below', [[60, 101], [160, 200]], {}),
        ('empty_world', [], {}),
        ('snap14', [[114, 200]], {}), ('snap15', [[115, 200]], {}),
        ('fall16', [[116, 200]], {}),
        ('origin15', [[85, 86], [140, 200]], {}),
        ('origin30', [[70, 71], [85, 86], [140, 200]], {}),
        ('origin30_empty', [[71, 72], [85, 86], [140, 200]], {}),
        ('single_pixel_floor', [[101, 102], [140, 200]], {}),
        ('bounce4', [[116, 200]], {'falling': True, 'speed': 4}),
        ('bounce5', [[116, 200]], {'falling': True, 'speed': 5}),
        ('buried_falling', [[60, 160], [180, 200]], {'falling': True, 'speed': 8}),
        ('above_map', [[1, 2], [40, 200]], {'y': -10}),
        ('top_limit', [], {'y': -201}), ('above_top_limit', [], {'y': -202}),
        ('bottom_limit', [], {'y': 200}),
        ('left_limit', [[100, 200]], {'x': -1}),
        ('right_limit', [[100, 200]], {'x': 64}),
        ('edge', [[100, 200]], {'x': 63}),
        ('crater', [[145, 200]], {'ticks': 15}),
    ]
    for weapon in (1, 2):
        for name, layers, options in scenarios:
            cases.append(case(name, layers, weapon=weapon, **options))
    out = args.output
    out.write_text(json.dumps({'source_sha256': SHA, 'cases': cases}, indent=2) + '\n')
    print(f'{len(cases)} native mine cases')


if __name__ == '__main__':
    main()
