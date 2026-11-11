"""Pin Ice DAT parameters, native attack masks and existing EPA ice frames.

Only writes metadata. No PNG, atlas registration or other importer is changed.
"""
import hashlib
import json
from pathlib import Path
import struct

import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
PIN = json.loads((ROOT / '.github/ci-tools.json').read_text())['client_sha256']
ROSTER = [2, 5, 3, 1, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]


def catalog():
    source = ROOT / '.tools/gunbound-client'
    for name in ('GunBound.gme', 'characterdata.dat', 'graphics.xfs'):
        assert hashlib.sha256((source / name).read_bytes()).hexdigest() == PIN[name]
    raw = xfs.lzhuf((source / 'characterdata.dat').read_bytes(), 16 * 332)
    rows = [struct.unpack_from('<83i', raw, i * 332) for i in range(16)]
    archive = source / 'graphics.xfs'
    toc = {entry['name']: entry for entry in xfs.read_toc(archive)}
    poses = {}
    masks = {}
    for vehicle, tank in enumerate(ROSTER, 1):
        states, _ = xfs.parse_epa(xfs.read_entry(archive, toc[f'tank{tank}.epa']))
        state = next(s for s in states if s['name'] == 'ice')
        poses[str(vehicle)] = {'frames': state['frames'], 'durations': state['durations']}
        masks[str(vehicle)] = [rows[tank - 1][base + 10] for base in (44, 57, 70)]
    row = rows[10]
    weapons = [{'power': row[b], 'dimension': row[b + 3], 'aspect': row[b + 6],
                'flags': row[b + 10], 'effect_radius': row[b + 11]} for b in (44, 57, 70)]
    return {'sources': {n: PIN[n] for n in ('GunBound.gme', 'characterdata.dat', 'graphics.xfs')},
            'weapons': weapons, 'attack_masks': masks, 'poses': poses}


def main():
    path = ROOT / 'assets/classic/ice_effects.json'
    path.write_text(json.dumps(catalog(), indent=2) + '\n')
    print(path.relative_to(ROOT))


if __name__ == '__main__':
    main()
