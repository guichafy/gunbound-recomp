"""Pinned Thor DAT shell material triples; no runtime or derived expectations."""
import hashlib
import json
from pathlib import Path
from import_grub_combat import native_rows, DAT_SHA

ROOT = Path(__file__).resolve().parents[1]
STAGE_SHA = '103c2b488977e1721becf8cb90496f95477302ec24141f94116d5214a3e6cfca'
# Stable Godot id -> client type. Stable ids 1/2 deliberately differ from tank index.
TYPES = [1, 4, 2, 0, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

def catalog():
    rows = native_rows()
    stages = ROOT / '.tools/gunbound-client/stage.dat'
    if hashlib.sha256(stages.read_bytes()).hexdigest() != STAGE_SHA:
        raise ValueError('stage.dat identity mismatch')
    # Every material triple is identical in this pinned DAT. This is verified,
    # not a claim that terrain material is generally irrelevant.
    assert all(len(set(row[b+j:b+j+3])) == 1 for row in rows for b in [44,57,70] for j in [0,3,6])
    return {'characterdata_sha256': DAT_SHA, 'stage_sha256': STAGE_SHA,
            'weapons': {str(i+1): [{'power': rows[t][b:b+3], 'dimension': rows[t][b+3:b+6],
                                   'aspect': rows[t][b+6:b+9]} for b in [44,57,70]]
                        for i,t in enumerate(TYPES)},
            'material_triples_identical': True}

if __name__ == '__main__':
    data = catalog()
    (ROOT/'assets/xfs/jewel/combat.json').write_text(json.dumps(data, indent=2)+'\n')
