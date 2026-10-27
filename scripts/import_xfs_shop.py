#!/usr/bin/env python3
"""Extract the original Avatar Shop frames from graphics.xfs, read-only.

    python3 scripts/import_xfs_shop.py [--graphics .tools/gunbound-client/graphics.xfs]

Writes one PNG per frame under assets/xfs/shop/<entry>/NNN.png and the
manifest assets/xfs/shop/catalog.json (size, native pivot, SHA-256). Frames
already versioned are kept byte-for-byte when the decoded pixels match.
`font.fnt` contributes its 8x12 ASCII half-width glyphs as one atlas; the
full-width CP949 table is not exported (all 562 catalog names are ASCII).
ADR-130 / AVATAR_SHOP_ORIGINAL.md hold the consumer evidence.
"""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

from read_gunbound_xfs import archive, extract
from decode_gunbound_img import frames

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/xfs/shop'
# Every frame of these entries is exported. Names match the client strings
# referenced by sub_447760 (store loader) and the screenshot oracle.
ENTRIES = [
    'store_back', 'store_avatar', 'store_myavatar', 'store_icon', 'store_window_back',
    'b_store_cap', 'b_store_cloth', 'b_store_glasse', 'b_store_flag',
    'b_store_buy', 'b_store_puton', 'b_store_exit', 'b_store_buddygame',
    'b_store_up', 'b_store_down', 'b_store_cashcharge',
    'b_myavatar_sell', 'b_myavatar_dry', 'b_myavatar_gift',
    'b_storewindow_gold', 'b_storewindow_cash', 'b_storewindow_cancel',
    'b_scroll_up', 'b_scroll_down',
]
# numfont: yellow LCD digits 0-9, white outlined status digits 40-49,
# yellow price digits 50-59, cyan price digits 60-69, commas 279/280.
NUMFONT = list(range(0, 10)) + list(range(40, 70)) + [279, 280]
FONT_CELL = (8, 12)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def same_pixels(path, image):
    if not path.exists():
        return False
    with Image.open(path) as previous:
        return previous.size == image.size and previous.convert('RGBA').tobytes() == image.convert('RGBA').tobytes()


def save(image, relative):
    path = OUT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    if not same_pixels(path, image):
        image.save(path)
    return path


def record(path, image, pivot):
    return {'size': list(image.size), 'pivot': list(pivot),
            'file': 'res://' + path.relative_to(ROOT).as_posix(), 'sha256': sha(path)}


def font_atlas(raw):
    """Half-width table: 256 glyphs x 12 rows, one byte per row, MSB left."""
    if len(raw) < 256 * 12:
        raise ValueError('font.fnt too short for the half-width table')
    atlas = Image.new('RGBA', (16 * FONT_CELL[0], 8 * FONT_CELL[1]), (0, 0, 0, 0))
    for code in range(128):
        ox, oy = (code % 16) * FONT_CELL[0], (code // 16) * FONT_CELL[1]
        for row in range(FONT_CELL[1]):
            bits = raw[code * 12 + row]
            for col in range(FONT_CELL[0]):
                if bits >> (7 - col) & 1:
                    atlas.putpixel((ox + col, oy + row), (255, 255, 255, 255))
    return atlas


def build(graphics_path):
    data = graphics_path.read_bytes()
    index = archive(data)['entries']
    catalog = {'version': 1, 'repository': 'https://github.com/jglim/gunbound-launcher',
               'commit': '2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1',
               'archive': 'TestClient/graphics.xfs', 'xfs_version': 280,
               'graphics_sha256': hashlib.sha256(data).hexdigest(), 'frames': {}, 'entries': {}}
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
