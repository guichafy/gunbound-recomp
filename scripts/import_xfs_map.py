#!/usr/bin/env python3
"""Extract Miramo Town A from the original client, read-only.

    python3 scripts/import_xfs_map.py [--graphics .tools/gunbound-client/graphics.xfs]

stage.dat record 1 names the stage "MiramoTown" and its graphics prefix "mos".
graphics.xfs holds mos.img (frame 0: 1800x1800 RLE foreground, frame 1:
1300x1300 RGB565 background), mos.lnd (u32 width, u32 height, one byte per
pixel, non-zero = land) and pmos.img (60 ground-particle frames with pivots).

Writes assets/xfs/maps/mos/{foreground,background,particle}.png and
catalog.json. The script refuses to write when mos.lnd disagrees with the
foreground alpha, so the PNG alpha stays the collision truth used by
terrain.gd. particle.png packs the 60 pmos frames on 48x48 cells around the
pivot (cell centre 24,24), 20 per row, the layout weather_art.gd reads.
mos1..mos5 (background animations) are recorded but not exported: no client
consumer was proven for them yet (CLIENT_ASSETS_PORT.md).
"""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

from read_gunbound_xfs import archive, extract
from decode_gunbound_img import frames
from import_mage_weather import decode_stage

ROOT = Path(__file__).resolve().parents[1]
GRAPHICS_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
OUT = ROOT / 'assets/xfs/maps/mos'
LEGACY = ROOT / 'assets/openbound/maps/miramo_town'
STAGE = ROOT / '.tools/gunbound-client/stage.dat'
CELL = 48
COLUMNS = 20


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def same_pixels(path, image):
    if not path.exists():
        return False
    with Image.open(path) as previous:
        return previous.size == image.size and previous.convert('RGBA').tobytes() == image.convert('RGBA').tobytes()


def save(image, name):
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    if not same_pixels(path, image):
        image.save(path)
    return path


def land_mask(raw):
    width = int.from_bytes(raw[0:4], 'little')
    height = int.from_bytes(raw[4:8], 'little')
    if len(raw) != 8 + width * height:
        raise ValueError('mos.lnd size does not match its header')
    return width, height, raw[8:]


def particle_atlas(decoded):
    rows = (len(decoded) + COLUMNS - 1) // COLUMNS
    atlas = Image.new('RGBA', (COLUMNS * CELL, rows * CELL), (0, 0, 0, 0))
    for index, (image, (px, py)) in enumerate(decoded):
        cell = Image.new('RGBA', (CELL, CELL), (0, 0, 0, 0))
        cell.alpha_composite(image, (CELL // 2 + px, CELL // 2 + py))
        atlas.alpha_composite(cell, ((index % COLUMNS) * CELL, (index // COLUMNS) * CELL))
    return atlas


def legacy_match(image, name):
    path = LEGACY / name
    return path.exists() and same_pixels(path, image)


def build(graphics_path):
    data = graphics_path.read_bytes()
    if hashlib.sha256(data).hexdigest() != GRAPHICS_SHA:
        raise ValueError('Unsupported graphics.xfs SHA; expected the authorized Thor client build')
    index = archive(data)['entries']
    stage = next(row for row in decode_stage(STAGE.read_bytes()) if row['name'] == 'MiramoTown')
    raw_img = extract(data, index['mos.img'])
    raw_lnd = extract(data, index['mos.lnd'])
    raw_particle = extract(data, index['pmos.img'])
    (foreground, fg_pivot), (background, bg_pivot) = frames(raw_img)
    if foreground.size != (1800, 1800) or background.size != (1300, 1300):
        raise ValueError('unexpected mos.img frame sizes')
    width, height, land = land_mask(raw_lnd)
    if (width, height) != foreground.size:
        raise ValueError('mos.lnd and the foreground differ in size')
    alpha = foreground.getchannel('A').tobytes()
    mismatches = sum(1 for a, b in zip(alpha, land) if (a > 0) != (b != 0))
    if mismatches:
        raise ValueError(f'mos.lnd disagrees with the foreground alpha in {mismatches} pixels')
    particles = frames(raw_particle)
    atlas = particle_atlas(particles)
    files = {'foreground': save(foreground, 'foreground.png'), 'background': save(background, 'background.png'),
             'particle': save(atlas, 'particle.png')}
    catalog = {
        'version': 1, 'repository': 'https://github.com/jglim/gunbound-launcher',
        'commit': '2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1', 'archive': 'TestClient/graphics.xfs',
        'graphics_sha256': hashlib.sha256(data).hexdigest(), 'stage_sha256': sha(STAGE),
        'stage': {'index': stage['index'], 'name': stage['name'], 'prefix': 'mos'},
        'entries': {
            'mos.img': {'frames': 2, 'entry_sha256': hashlib.sha256(raw_img).hexdigest()},
            'mos.lnd': {'size': [width, height], 'land_values': sorted(set(land)),
                        'entry_sha256': hashlib.sha256(raw_lnd).hexdigest()},
            'pmos.img': {'frames': len(particles), 'entry_sha256': hashlib.sha256(raw_particle).hexdigest()},
        },
        'files': {
            'foreground': {'file': 'res://' + files['foreground'].relative_to(ROOT).as_posix(), 'source': 'mos.img:0',
                           'size': list(foreground.size), 'pivot': list(fg_pivot), 'sha256': sha(files['foreground']),
                           'land_pixels': sum(1 for b in land if b), 'alpha_equals_lnd': True,
                           'crop': list(foreground.getchannel('A').getbbox()),
                           'matches_legacy': legacy_match(foreground, 'ForegroundA.png')},
            'background': {'file': 'res://' + files['background'].relative_to(ROOT).as_posix(), 'source': 'mos.img:1',
                           'size': list(background.size), 'pivot': list(bg_pivot), 'sha256': sha(files['background']),
                           'matches_legacy': legacy_match(background, 'Background.png')},
            'particle': {'file': 'res://' + files['particle'].relative_to(ROOT).as_posix(), 'source': 'pmos.img',
                         'cell': [CELL, CELL], 'columns': COLUMNS, 'frames': len(particles),
                         'pivots': [list(pivot) for _, pivot in particles], 'sha256': sha(files['particle']),
                         'matches_legacy': legacy_match(atlas, 'Particle.png')},
        },
        'not_exported': {},
    }
    for number in range(1, 6):
        name = f'mos{number}.img'
        decoded = frames(extract(data, index[name]))
        catalog['not_exported'][name] = {'frames': len(decoded), 'size': list(decoded[0][0].size),
                                         'position': list(decoded[0][1])}
    (OUT / 'catalog.json').write_text(json.dumps(catalog, indent=2) + '\n')
    print('Miramo Town A from mos.img/mos.lnd/pmos.img:', {key: value['matches_legacy'] for key, value in catalog['files'].items()})


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--graphics', type=Path, default=ROOT / '.tools/gunbound-client/graphics.xfs')
    build(parser.parse_args().graphics)
