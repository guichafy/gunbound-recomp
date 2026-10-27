#!/usr/bin/env python3
"""Extract shared weather/Thor art from the pinned Thor's Hammer client.

No source artwork is resampled. IMG frames keep their hotspot registration;
XTF ARGB4444 nibbles expand to RGBA8888 by multiplication by 17. Existing
native imports are compared pixel for pixel and remain as validated fallbacks.
Thor's proved beam consumer selects LaserEffect.xtf, not ThorTexture1/2.xtf.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

from PIL import Image
import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / '.tools/gunbound-client/graphics.xfs'
ARCHIVE_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
PE_SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
TEXTURES = {
    'FirewallTexture': ('weather', 'assets/openbound/weather/native/FirewallTexture.png', '0x471550', 'SRCALPHA/INVSRCALPHA'),
    'LightningTexture': ('weather', 'assets/openbound/weather/native/LightningTexture.png', '0x46e020', 'SRCALPHA/ONE'),
    'TornadoTexture': ('weather', 'assets/openbound/weather/native/TornadoTexture.png', '0x4ac760', 'SRCALPHA/INVSRCALPHA'),
    'CrashTexture': ('weather', 'assets/openbound/mage/original/CrashTexture.png', '0x48dd80/0x481ef0', 'SRCALPHA/ONE'),
    'Lightning': ('weather', 'assets/openbound/lightning/Lightning.png', '0x482130/0x4a6b10', 'SRCALPHA/ONE'),
    'LaserEffect': ('thor', 'assets/openbound/aduka/ThorEffect.png', '0x4c45e4..0x4c46f3', 'SRCALPHA/ONE'),
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def pack_frames(frames, columns=14):
    left = min(frame['hx'] for frame in frames)
    top = min(frame['hy'] for frame in frames)
    cell = [max(frame['hx'] + frame['w'] for frame in frames) - left,
            max(frame['hy'] + frame['h'] for frame in frames) - top]
    image = Image.new('RGBA', (columns * cell[0], ((len(frames) + columns - 1) // columns) * cell[1]))
    for index, frame in enumerate(frames):
        image.paste(frame['image'], ((index % columns) * cell[0] + frame['hx'] - left,
                                     (index // columns) * cell[1] + frame['hy'] - top))
    return image, cell, [-left, -top]


def import_assets(output_root=ROOT / 'assets/xfs', archive=ARCHIVE):
    archive = Path(archive)
    if sha(archive.read_bytes()) != ARCHIVE_SHA:
        raise ValueError('SHA256 mismatch: graphics.xfs')
    toc = {entry['name']: entry for entry in xfs.read_toc(archive)}
    output_root = Path(output_root)
    catalog = dict(version=1, repository='https://github.com/jglim/gunbound-launcher',
                   commit='2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1', archive='TestClient/graphics.xfs',
                   archive_sha256=ARCHIVE_SHA, pe_sha256=PE_SHA, files={},
                   gaps={'weakness': 'No equivalent category in this client build; declared inherited adapter remains active.',
                         'mirror': 'No equivalent category in this client build; declared inherited adapter remains active.',
                         'random': 'No equivalent category in this client build; declared inherited adapter remains active.'},
                   not_selected={'ThorTexture1.xtf': 'Proved Thor/Aduka beam consumer selects LaserEffect.xtf.',
                                 'ThorTexture2.xtf': 'Proved Thor/Aduka beam consumer selects LaserEffect.xtf.'})

    def save(image, key, group, fallback, entry, raw, **extra):
        old = Image.open(ROOT / fallback).convert('RGBA')
        if old.size != image.size or old.tobytes() != image.tobytes():
            raise ValueError('Native fallback pixels differ: ' + fallback)
        destination = output_root / group / (key + '.png')
        destination.parent.mkdir(parents=True, exist_ok=True)
        image.save(destination)
        catalog['files'][key] = dict(file=f'res://assets/xfs/{group}/{key}.png', source=entry,
                                    entry_sha256=sha(raw), size=list(image.size), sha256=sha(destination.read_bytes()),
                                    rgba_sha256=sha(image.tobytes()), fallback='res://' + fallback,
                                    matches_native_fallback=True, **extra)

    for name, (group, fallback, consumer, blend) in TEXTURES.items():
        raw = xfs.read_entry(archive, toc[name + '.xtf'])
        if struct.unpack_from('<IIB', raw) != (256, 256, 1) or len(raw) != 131081:
            raise ValueError('Unexpected ARGB4444 XTF format: ' + name)
        image = Image.new('RGBA', (256, 256))
        image.putdata([xfs._argb4444(value) for value, in struct.iter_unpack('<H', raw[9:])])
        save(image, name, group, fallback, name + '.xtf', raw, consumer=consumer, blend=blend,
             format='ARGB4444 -> RGBA8888; each channel times17, unchanged pixels')

    thor = dict(archive_sha256=ARCHIVE_SHA, columns=14, sheets={})
    for entry, name in [('thor.img', 'ThorBody'), ('thorl.img', 'ThorLight')]:
        raw = xfs.read_entry(archive, toc[entry])
        frames = xfs.frames(raw)
        if len(frames) != 56:
            raise ValueError('Unexpected Thor frame count')
        image, cell, origin = pack_frames(frames)
        save(image, name, 'thor', 'assets/openbound/aduka/' + name + '.png', entry, raw,
             frames=56, cell=cell, origin=origin, columns=14,
             frame_windows=[[frame['hx'], frame['hy'], frame['w'], frame['h']] for frame in frames])
        thor['sheets'][name + '.png'] = dict(entry=entry, entry_sha256=sha(raw), frames=56,
                                            cell=cell, origin=origin, image_sha256=catalog['files'][name]['sha256'])
    raw = xfs.read_entry(archive, toc['thor.epa'])
    states, _ = xfs.parse_epa(raw)
    thor['epa_sha256'] = sha(raw)
    thor['states'] = {state['name']: dict(frames=state['frames'], durations=state['durations'])
                      for state in states if state['name'] in ('normal', 'active', 'fire')}
    thor['unusable_states'] = {state['name']: 'EPA references frames beyond this56-frame source'
                              for state in states if any(frame >= 56 for frame in state['frames'])}
    original = json.loads((ROOT / 'assets/openbound/aduka/thor_native.json').read_text())
    if thor != original:
        raise ValueError('Thor EPA/layout differs from the approved native import')
    (output_root / 'thor/thor_native.json').write_text(json.dumps(thor, indent=2) + '\n')
    (output_root / 'weather/catalog.json').write_text(json.dumps(catalog, indent=2) + '\n')
    print(f'CLIENT WEATHER ASSETS: {len(catalog["files"])} sheets; original RGBA, native fallbacks and Thor EPA validated')
    return catalog


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--graphics', type=Path, default=ARCHIVE)
    parser.add_argument('--output', type=Path, default=ROOT / 'assets/xfs')
    args = parser.parse_args()
    import_assets(args.output, args.graphics)
