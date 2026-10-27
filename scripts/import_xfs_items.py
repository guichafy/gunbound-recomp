#!/usr/bin/env python3
"""Import original Thor's Hammer items into the existing logical UI windows.

Only native pixels: two client states are repeated for hover/press; transparent
1px margins preserve the current 37x36 / 73x36 hitboxes. Teleport frames retain
native registration in the existing padded cells. No GPT assets are read.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image
from read_gunbound_xfs import archive, extract
from decode_gunbound_img import frames
ROOT = Path(__file__).resolve().parents[1]
GRAPHICS_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
OUT = ROOT / 'assets/xfs/items'
BUTTONS = {'BungeShot': ('item1', 0), 'PowerUp': ('item1', 2), 'Blood': ('item1', 4),
           'EnergyUp1': ('item1', 12), 'ChangeWind': ('item1', 28),
           'Dual': ('item2', 0), 'DualPlus': ('item2', 2), 'Thunder': ('item2', 10),
           'EnergyUp2': ('item2', 12), 'Teleport': ('item2', 18), 'TeamTeleport': ('item2', 20)}

def build(path):
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != GRAPHICS_SHA:
        raise ValueError('Unsupported graphics.xfs SHA; expected the authorized Thor client build')
    index = archive(raw)['entries']; decoded = {}; entries = {}
    for name in ['item1', 'item2', 'teleport1', 'teleport2', 'bulletiteml', 'playmode']:
        payload = extract(raw, index[name + '.img']); decoded[name] = frames(payload)
        entries[name] = {'sha256': hashlib.sha256(payload).hexdigest(), 'frames': len(decoded[name])}
    OUT.mkdir(parents=True, exist_ok=True)
    catalog = {'version': 1, 'graphics_sha256': hashlib.sha256(raw).hexdigest(),
               'archive': 'TestClient/graphics.xfs', 'repository': 'https://github.com/jglim/gunbound-launcher',
               'commit': '2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1', 'entries': entries, 'files': {}}
    def save(name, image, source):
        target = OUT / name
        if not target.exists() or Image.open(target).convert('RGBA').tobytes() != image.tobytes():
            image.save(target)
        old = ROOT / 'assets/openbound/items' / name
        catalog['files'][name] = {'file': 'res://' + target.relative_to(ROOT).as_posix(), 'source': source,
                                  'size': list(image.size), 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                                  'matches_legacy': old.exists() and Image.open(old).convert('RGBA').size == image.size and Image.open(old).convert('RGBA').tobytes() == image.tobytes()}
    for name, (entry, base) in BUTTONS.items():
        width = decoded[entry][base][0].width + 2
        atlas = Image.new('RGBA', (width * 4, 36))
        for state, native in enumerate([base, base, base + 1, base + 1]):
            atlas.alpha_composite(decoded[entry][native][0], (state * width + 1, 1))
        save('Item' + name + '.png', atlas, {'entry': entry, 'frames': [base, base, base+1, base+1], 'margin': [1,1]})
    for entry, name, cell, pivot, cols in [('teleport1','Teleport1.png',(190,192),(95,100),10), ('teleport2','Teleport2.png',(190,192),(95,100),10), ('bulletiteml','TeleportBullet.png',(43,39),(30,18),12)]:
        fs = decoded[entry]; atlas = Image.new('RGBA',(cell[0]*cols, cell[1]*((len(fs)+cols-1)//cols)))
        for number,(image,(px,py)) in enumerate(fs):
            atlas.alpha_composite(image, ((number%cols)*cell[0]+pivot[0]+px, (number//cols)*cell[1]+pivot[1]+py))
        save(name, atlas, {'entry': entry, 'frames': len(fs), 'cell': list(cell), 'pivot': list(pivot), 'native_pivots': [list(p) for _,p in fs]})
    # Preserve the native banner aspect by padding the 35px legacy window to 38px.
    # Runtime keeps the logical hitbox and uses the whole native source region.
    locked = decoded['playmode'][15][0]
    save('MatchStatus.png', locked, {'entry': 'playmode', 'frame': 15})
    (OUT/'catalog.json').write_text(json.dumps(catalog, indent=2)+'\n')
    print('Client items:', len(catalog['files']), 'atlases; identical legacy:', [k for k,v in catalog['files'].items() if v['matches_legacy']])

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--graphics',type=Path,default=ROOT/'.tools/gunbound-client/graphics.xfs')
    build(parser.parse_args().graphics)
