#!/usr/bin/env python3
"""Read-only source/catalog audit. Output must be a new directory.
Uses the project's XFS/IMG decoders; native format evidence is recorded separately.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', required=True, type=Path)
    parser.add_argument('--client', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--pixels', action='store_true', help='Compare every registered native layer/frame and source thumbnail')
    args = parser.parse_args()
    root, client, output = args.project.resolve(), args.client.resolve(), args.output.resolve()
    if output.exists():
        parser.error('Output must not exist; no source or evidence is overwritten')
    sys.path.insert(0, str(root / 'scripts'))
    from read_gunbound_xfs import archive, extract, avatar_rows
    from build_classic_avatar_catalog import identity
    from decode_gunbound_img import frames
    from PIL import Image, ImageDraw, ImageFont
    source_paths = [client / name for name in ('GunBound.gme', 'avatar.xfs', 'graphics.xfs')]
    hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths}
    av = (client / 'avatar.xfs').read_bytes()
    graphics = (client / 'graphics.xfs').read_bytes()
    ai, gi = archive(av), archive(graphics)
    names = {n.lower(): n for n in gi['entries']}
    raw = avatar_rows(av)
    expected = [identity(row) for row in raw]
    native = json.loads((root / 'assets/xfs/avatars/catalog.json').read_text())
    classic = json.loads((root / 'assets/xfs/avatars/classic.json').read_text())
    actual = native['records']
    by_key = {row['key']: row for row in actual}
    problems = []
    if len(by_key) != len(actual):
        problems.append('Duplicate runtime keys')
    if classic['records'] != expected:
        problems.append('classic.json differs from source records')
    if [r['key'] for r in actual] != [r['key'] for r in expected]:
        problems.append('Runtime keys/order differ from source records')
    referenced, pixel_frames, pixel_portraits, layers = set(), 0, 0, 0
    for raw_row, expected_row in zip(raw, expected):
        row = by_key.get(expected_row['key'])
        if row is None:
            problems.append('Missing record: ' + expected_row['key'])
            continue
        fields = ('id', 'name', 'description', 'buyable', 'gender', 'bonuses')
        if any(row[f] != expected_row[f] for f in fields) or row['native_stats'] != expected_row['stats'] or row['gold_price'] != expected_row['gold'] or row['cash_price'] != expected_row['cash']:
            problems.append('Metadata differs: ' + row['key'])
        stem = raw_row['file'][:2] + f"{row['id']:05d}"
        expected_layers = [names[n] for n in (stem + '.img', stem + 'l.img') if n in names]
        if [l['source'].lower() for l in row['layers']] != [n.lower() for n in expected_layers]:
            problems.append('Layer coverage differs: ' + row['key'])
        for layer in row['layers']:
            layers += 1
            referenced.add(layer['source'].lower())
            path = root / layer['atlas'].removeprefix('res://')
            if not path.is_file():
                problems.append('Missing atlas: ' + str(path))
                continue
            if args.pixels:
                decoded = frames(extract(graphics, gi['entries'][names[layer['source'].lower()]]))
                if len(decoded) != len(layer['frames']):
                    problems.append('Frame count differs: ' + row['key'])
                with Image.open(path) as atlas:
                    atlas = atlas.convert('RGBA')
                    for (image, pivot), frame in zip(decoded, layer['frames']):
                        x, y, w, h = frame['region']
                        if list(pivot) != frame['offset'] or image.size != (w, h) or atlas.crop((x, y, x+w, y+h)).tobytes() != image.convert('RGBA').tobytes():
                            problems.append('Frame pixels/pivot differ: ' + row['key'])
                        pixel_frames += 1
        portrait = root / row['portrait'].removeprefix('res://')
        if not portrait.is_file():
            problems.append('Missing portrait: ' + row['key'])
        portrait_name = 's' + stem + '.img'
        if portrait_name in names:
            referenced.add(portrait_name)
            if args.pixels:
                image, pivot = frames(extract(graphics, gi['entries'][names[portrait_name]]))[0]
                with Image.open(portrait) as stored:
                    if stored.size != image.size or stored.convert('RGBA').tobytes() != image.convert('RGBA').tobytes() or list(pivot) != row['portrait_pivot']:
                        problems.append('Portrait pixels/pivot differ: ' + row['key'])
                pixel_portraits += 1
    gfx = {n for n in names if re.fullmatch(r's?[mf][bhgef]\d{5}l?\.img', n)}
    hidden = [r for r in actual if not r['buyable']]
    specials = [r for r in hidden if r['layers'] and r['id'] != 0]
    summary = {
        'source_sha256': hashes, 'xfs_version': ai['version'],
        'dat_counts': {n: {'records': struct.unpack_from('<I', extract(av, e))[0], 'buyable': sum(r['buyable'] for r in raw if r['file'] == n)} for n, e in ai['entries'].items()},
        'records': len(actual), 'buyable': sum(r['buyable'] for r in actual),
        'with_layers': sum(bool(r['layers']) for r in actual), 'layers': layers,
        'hidden': len(hidden), 'hidden_with_layers': sum(bool(r['layers']) for r in hidden),
        'hidden_nondefault_with_layers': len(specials),
        'missing_native_art': native['missing'], 'unlisted_graphics': sorted(gfx - referenced),
        'shop_groups': [{'gender': g, 'category': c, 'items': (n := sum(r['buyable'] and r['gender'] in (g, 2) and r['category'] == c for r in actual)), 'pages': math.ceil(n/9)} for g in (0, 1) for c in range(4)],
        'pixel_frames_compared': pixel_frames, 'pixel_portraits_compared': pixel_portraits,
        'hidden_records': [{'key': r['key'], 'name': r['name'], 'has_layers': bool(r['layers']), 'portrait': r['portrait']} for r in hidden],
        'problems': problems,
    }
    output.mkdir(parents=True)
    (output / 'inventory.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
    # Contact sheet only: existing native thumbnails, no regenerated artwork.
    cols, cw, ch = 6, 200, 115
    sheet = Image.new('RGB', (cols*cw, 60 + math.ceil(len(specials)/cols)*ch), '#202735')
    draw = ImageDraw.Draw(sheet)
    font_path = Path('/System/Library/Fonts/Menlo.ttc')
    font = ImageFont.truetype(str(font_path), 12) if font_path.exists() else ImageFont.load_default()
    draw.text((12, 10), '67 native records already migrated, hidden by buyable=0' if len(specials)==67 else f'{len(specials)} hidden native records with art', fill='white', font=font)
    draw.text((12, 30), 'Separate head/body/gender records; not 67 complete outfits.', fill='#b5c4da', font=font)
    for i, row in enumerate(specials):
        x, y = (i % cols)*cw, 60 + (i//cols)*ch
        draw.rectangle((x+2, y+2, x+cw-3, y+ch-3), fill='#323d50')
        with Image.open(root / row['portrait'].removeprefix('res://')) as im:
            im = im.convert('RGBA')
            if im.width > 180 or im.height > 68:
                im.thumbnail((180, 68))
            sheet.paste(im, (x+(cw-im.width)//2, y+3+(68-im.height)//2), im)
        draw.text((x+8,y+74), row['name'][:25], fill='white', font=font)
        draw.text((x+8,y+91), row['key'], fill='#b5c4da', font=font)
    sheet.save(output / 'hidden-native-records.png')
    extra = []
    for name in summary['unlisted_graphics']:
        for image, pivot in frames(extract(graphics, gi['entries'][names[name]])):
            extra.append((name, image, pivot))
            break
    orphan = Image.new('RGB', (600, 180), '#323d50')
    d = ImageDraw.Draw(orphan)
    for i, (name, image, pivot) in enumerate(extra):
        orphan.paste(image, (i*300+100, 25), image)
        d.text((i*300+10,125), name, fill='white', font=font)
        d.text((i*300+10,145), f'pivot={pivot}', fill='white', font=font)
    orphan.save(output / 'unlisted-native-graphics.png')
    summary['source_unchanged'] = hashes == {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths}
    if not summary['source_unchanged']:
        problems.append('Source identity changed during audit')
    (output / 'inventory.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k: v for k, v in summary.items() if k not in ('hidden_records', 'source_sha256', 'shop_groups', 'missing_native_art')}, ensure_ascii=False, indent=2))
    return int(bool(problems))


if __name__ == '__main__':
    sys.exit(main())
