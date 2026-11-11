#!/usr/bin/env python3
"""Read pinned Thor's Hammer PE/XFS; no GDScript or generated PNG input.

Usage: python tests/tools/projectile_light/evidence.py --output FILE
VAs/bytes were inspected using Ghidra12.2, issue32/ADR165.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'scripts'))
import gunbound_xfs as xfs  # noqa: E402

# kind, game ID, client type, per-weapon vtable. Trico SS has a guarded publisher.
TABLES = [
    ('armor', 4, 0, [0x555c34, 0x555dac, 0x555ac4]),
    ('bigfoot', 2, 4, [0x555c34, 0x555c34, 0x55631c]),
    ('trico', 5, 3, [0x555c34, 0x5564d0, 0x5565f8]),
    ('jd', 9, 8, [0x555e88, 0x555d14, 0x556360]),
    ('asate', 10, 9, [0x556160, 0x556160, 0x555b18]),
    ('ice', 11, 10, [0x555c34, 0x555f38, 0x555f58]),
]


def generate(client, binary):
    config = json.loads((ROOT / '.github/ci-tools.json').read_text())
    hashes = {}
    for name in ['GunBound.gme', 'characterdata.dat', 'graphics.xfs']:
        raw = (binary if name == 'GunBound.gme' else client / name).read_bytes()
        hashes[name] = hashlib.sha256(raw).hexdigest()
        if hashes[name] != config['client_sha256'][name]:
            raise ValueError(f'Unsupported source: {name}')
    pe = binary.read_bytes()
    header = struct.unpack_from('<I', pe, 60)[0]
    section_count = struct.unpack_from('<H', pe, header + 6)[0]
    start = header + 24 + struct.unpack_from('<H', pe, header + 20)[0]
    sections = [struct.unpack_from('<4I', pe, start + index * 40 + 8) for index in range(section_count)]

    def read(va, count):
        for _, rva, size, offset in sections:
            delta = va - 0x400000 - rva
            if 0 <= delta and delta + count <= size:
                return pe[offset + delta:offset + delta + count]
        raise ValueError(f'Unmapped VA: {va:x}')

    # Actual push instructions for SetRenderState, ordered by VA in 4c3020.
    sites = {0x4c4d2b: '6a05', 0x4c4d3e: '6a13', 0x4c4d4b: '6a06',
             0x4c4d4d: '6a14', 0x4c4d53: '6880685500',
             0x4c4f55: '6870685500', 0x4c4f7f: '6a05', 0x4c4f81: '6a13',
             0x4c4f9a: '53', 0x4c4f9b: '6a14', 0x4c4f6b: 'bb02000000',
             0x4c4e90: 'c0e105', 0x4c4e96: '80caff', 0x4c4e99: '2ad1'}
    for va, expected in sites.items():
        if read(va, len(bytes.fromhex(expected))).hex() != expected:
            raise ValueError(f'ASM mismatch: {va:x}')
    toc = {entry['name']: entry for entry in xfs.read_toc(client / 'graphics.xfs')}
    rows = []
    for kind, game_id, client_type, tables in TABLES:
        for weapon, suffix in enumerate(['n', 's', 'p']):
            publisher = struct.unpack('<I', read(tables[weapon] + 12, 4))[0]
            expected = 0x4ae1a0 if (kind, weapon) == ('trico', 2) else 0x458690
            if publisher != expected:
                raise ValueError(f'Publish mismatch: {kind}/{weapon}')
            stem = f'bullet{client_type + 1}{suffix}'
            body = stem + '.img' if stem + '.img' in toc else ''
            light = stem + 'l.img' if stem + 'l.img' in toc else ''
            entries = {}
            for entry in [body, light]:
                if entry:
                    entries[entry] = hashlib.sha256(xfs.read_entry(client / 'graphics.xfs', toc[entry])).hexdigest()
            rows.append({'kind': kind, 'id': game_id, 'weapon': weapon,
                         'vtable': hex(tables[weapon]), 'publish': hex(publisher),
                         'body': body, 'light': light, 'entry_sha256': entries})
    return {'source_sha256': hashes, 'render': {'body': [19, 5, 20, 6],
            'light': [19, 5, 20, 2], 'head_alpha': 255, 'order': ['body', 'light']},
            'asm': {hex(va): value for va, value in sites.items()}, 'consumers': rows}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--client', type=Path, default=ROOT / '.tools/gunbound-client')
    parser.add_argument('--binary', type=Path, default=ROOT / '.tools/gunbound-client/GunBound.gme')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.write_text(json.dumps(generate(args.client, args.binary), indent=2) + '\n')
