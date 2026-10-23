#!/usr/bin/env python3
"""Import the real avatar catalog and registered artwork from XFS, read-only."""
import argparse
import hashlib
import json
import math
from pathlib import Path
from PIL import Image
from read_gunbound_xfs import archive, extract, avatar_rows
from decode_gunbound_img import frames

ROOT = Path(__file__).resolve().parents[1]
STAT_ORDER = ['attack', 'health', 'defense', 'shield',
              'shot_delay', 'item_delay', 'bunge', 'popularity']


def save_preserving_previous(image, path):
    if path.exists():
        with Image.open(path) as previous:
            if previous.size!=image.size or previous.convert('RGBA').tobytes()!=image.convert('RGBA').tobytes():
                path=path.with_name(path.stem+'_alpha.png')
    image.save(path)
    return path


def build(graphics_path, avatar_path):
    graphics = graphics_path.read_bytes()
    index = archive(graphics)['entries']
    lookup = {name.lower(): name for name in index}
    output = ROOT / 'assets/xfs/avatars'
    output.mkdir(parents=True, exist_ok=True)
    rows, missing = [], []
    for raw in avatar_rows(avatar_path.read_bytes()):
        stem = raw['file'][:2] + f"{raw['id']:05d}"
        category = {'h': 0, 'b': 1, 'g': 2, 'f': 3}[stem[1]]
        gender = 2 if category == 3 else (0 if stem[0] == 'm' else 1)
        item = dict(key=f"xfs:{gender}:{category}:{raw['id']}", source='xfs',
                    gender=gender, category=category, id=raw['id'], name=raw['name'],
                    description=raw['description'], buyable=raw['buyable'],
                    gold_price=raw['gold'], cash_price=raw['cash'],
                    bonuses=[raw['stats'][name] for name in STAT_ORDER],
                    native_stats=raw['stats'], atlas='', portrait='', frames=[], layers=[])
        empty = raw['id'] == 0 and category in (2, 3)
        decoded = []
        for suffix in ['', 'l']:
            native_name = lookup.get(stem+suffix+'.img')
            if not native_name:
                continue
            layer_frames = frames(extract(graphics, index[native_name]))
            decoded = decoded or layer_frames
            layer = dict(frames=[], source=native_name)
            cw = max(image.width for image, _ in layer_frames)
            ch = max(image.height for image, _ in layer_frames)
            sheet = Image.new('RGBA', (cw*min(11,len(layer_frames)), ch*math.ceil(len(layer_frames)/11)))
            for number, (image, offset) in enumerate(layer_frames):
                xy = ((number % 11)*cw, (number // 11)*ch)
                sheet.paste(image, xy)
                layer['frames'].append(dict(region=[*xy,*image.size], offset=list(offset)))
            file = output / f'{stem}{suffix}.png'
            file=save_preserving_previous(sheet,file)
            layer['atlas'] = 'res://' + file.relative_to(ROOT).as_posix()
            item['layers'].append(layer)
        if item['layers']:
            item['atlas'] = item['layers'][0]['atlas']
            item['frames'] = item['layers'][0]['frames']
        elif not empty:
            missing.append(dict(key=item['key'], asset=stem+'.img', buyable=item['buyable']))
        portrait_name = lookup.get('s'+stem+'.img')
        if portrait_name:
            portrait = frames(extract(graphics,index[portrait_name]))[0][0]
        elif decoded:
            portrait = decoded[min(11,len(decoded)-1)][0]
        else:
            portrait = Image.new('RGBA',(1,1))
        file = output / f's{stem}.png'
        file=save_preserving_previous(portrait,file)
        item['portrait'] = 'res://' + file.relative_to(ROOT).as_posix()
        item['art_available'] = bool(decoded) or empty
        item['empty'] = empty
        rows.append(item)
        if len(rows)%50 == 0:
            print(f'{len(rows)}/562 avatar records imported',flush=True)
    data = dict(version=1,xfs_version=280,decoder='argb4444-alpha-v2',records=rows,missing=missing,
                sources={str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                         for p in [graphics_path,avatar_path]},
                bonus_order=STAT_ORDER)
    (output/'catalog.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    print(f"Imported {len(rows)} records; {sum(r['buyable'] for r in rows)} buyable; {len(missing)} missing artwork")


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--graphics',type=Path,default=ROOT/'.tools/gunbound-client/graphics.xfs')
    parser.add_argument('--avatars',type=Path,default=ROOT/'assets/xfs/reference/avatar.xfs')
    args=parser.parse_args()
    build(args.graphics,args.avatars)
