#!/usr/bin/env python3
"""Extract the original result window frames from graphics.xfs, read-only.

    python3 scripts/import_xfs_result.py [--graphics .tools/gunbound-client/graphics.xfs]

Writes one PNG per frame under assets/xfs/result/<entry>/NNN.png and the
manifest assets/xfs/result/catalog.json (size, native pivot, SHA-256), in the
format of the shop catalog so ClassicShopArt can read it. Frames already
versioned are kept byte-for-byte when the decoded pixels match.
RESULT_SCREEN_NATIVE.md / ADR-139 hold the consumer evidence.
"""
import argparse
import hashlib
import json
from pathlib import Path

from read_gunbound_xfs import archive, extract
from decode_gunbound_img import frames
from import_xfs_shop import font_atlas, same_pixels, sha, FONT_CELL

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/xfs/result'
GRAPHICS_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
# result_back is resource 9001 (FUN_004c8890/FUN_004d0260); b_result_confirm
# is the OK button created by message 0x4413 (FUN_004b4100).
ENTRIES = ['result_back', 'b_result_confirm']
# numfont (resource 500) frames read by FUN_004d0260: P digits 80-89/90-99,
# letter P 100/101, minus 102; team A gold 103-112, G 113; team B gold
# 114-123, G 124; gold minus 224 (A) / 225 (B).
NUMFONT = list(range(80, 126)) + [224, 225]


def save(image, relative):
    path = OUT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    if not same_pixels(path, image):
        image.save(path)
    return path


def record(path, image, pivot):
    return {'size': list(image.size), 'pivot': list(pivot),
            'file': 'res://' + path.relative_to(ROOT).as_posix(), 'sha256': sha(path)}


def build(graphics_path):
    data = graphics_path.read_bytes()
    if hashlib.sha256(data).hexdigest() != GRAPHICS_SHA:
        raise ValueError("graphics.xfs differs from the pinned Thor's Hammer build")
    index = archive(data)['entries']
    catalog = {'version': 1, 'repository': 'https://github.com/jglim/gunbound-launcher',
               'commit': '2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1',
               'archive': 'TestClient/graphics.xfs', 'xfs_version': 280,
               'graphics_sha256': GRAPHICS_SHA, 'frames': {}, 'entries': {}}
    for name in ENTRIES:
        raw = extract(data, index[name + '.img'])
        decoded = frames(raw)
        catalog['entries'][name] = {'frames': len(decoded), 'entry_sha256': hashlib.sha256(raw).hexdigest()}
        for number, (image, pivot) in enumerate(decoded):
            path = save(image, f'{name}/{number:03}.png')
            catalog['frames'][f'{name}:{number}'] = record(path, image, pivot)
    raw = extract(data, index['numfont.img'])
    decoded = frames(raw)
    catalog['entries']['numfont'] = {'frames': len(decoded), 'exported': NUMFONT,
                                     'entry_sha256': hashlib.sha256(raw).hexdigest()}
    for number in NUMFONT:
        image, pivot = decoded[number]
        path = save(image, f'numfont/{number:03}.png')
        catalog['frames'][f'numfont:{number}'] = record(path, image, pivot)
    raw = extract(data, index['font.fnt'])
    atlas = font_atlas(raw)
    path = save(atlas, 'font/ascii.png')
    catalog['entries']['font'] = {'cell': list(FONT_CELL), 'columns': 16, 'glyphs': 128, 'advance': 6,
                                  'entry_sha256': hashlib.sha256(raw).hexdigest()}
    catalog['frames']['font:0'] = record(path, atlas, (0, 0))
    (OUT / 'catalog.json').write_text(json.dumps(catalog, indent=2) + '\n')
    print(f"{len(catalog['frames'])} frames in {len(catalog['entries'])} entries")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--graphics', type=Path, default=ROOT / '.tools/gunbound-client/graphics.xfs')
    build(parser.parse_args().graphics)
