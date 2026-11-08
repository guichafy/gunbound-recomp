"""Knight Ion and child sheets from the original graphics.xfs (ADR-152).

knightion.img/.epa and knightionl.img are the satellite (SpawnKnightIon 0x438100,
draw 0x47dc00); knightbullet.img/.epa and knightbulletl.img are the children of
the spawner 0x4305c0. Frames are copied pixel for pixel into fixed cells that share
the hotspot, as for the ASate Ion; no resampling. Output: assets/openbound/knight/
Ion.png, IonLight.png, Child.png, ChildLight.png and knight_ion.json.
"""
import hashlib
import json
from pathlib import Path
from PIL import Image
import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / '.tools/gunbound-client/graphics.xfs'
ARCHIVE_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
OUT = ROOT / 'assets/openbound/knight'
SHEETS = {
    'Ion.png': ('knightion.img', 'knightion.epa'),
    'IonLight.png': ('knightionl.img', 'knightion.epa'),
    'Child.png': ('knightbullet.img', 'knightbullet.epa'),
    'ChildLight.png': ('knightbulletl.img', 'knightbullet.epa'),
}
COLUMNS = 10


def sheet(frames):
    left = max(-f['hx'] for f in frames)
    top = max(-f['hy'] for f in frames)
    right = max(f['w'] + f['hx'] for f in frames)
    bottom = max(f['h'] + f['hy'] for f in frames)
    cell = (left + right, top + bottom)
    rows = (len(frames) + COLUMNS - 1) // COLUMNS
    atlas = Image.new('RGBA', (cell[0] * COLUMNS, cell[1] * rows))
    for index, frame in enumerate(frames):
        x = (index % COLUMNS) * cell[0] + left + frame['hx']
        y = (index // COLUMNS) * cell[1] + top + frame['hy']
        atlas.paste(frame['image'], (x, y))
    return atlas, cell, (left, top)


def import_assets(archive=ARCHIVE, out=OUT):
    archive = Path(archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != ARCHIVE_SHA:
        raise ValueError('SHA256 mismatch: graphics.xfs')
    toc = {entry['name']: entry for entry in xfs.read_toc(str(archive))}
    catalog = {'source': 'graphics.xfs', 'source_sha256': ARCHIVE_SHA, 'columns': COLUMNS, 'sheets': {}}
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    for name, (image, epa) in SHEETS.items():
        raw = xfs.read_entry(str(archive), toc[image])
        frames = xfs.frames(raw)
        atlas, cell, origin = sheet(frames)
        atlas.save(out / name)
        states, _ = xfs.parse_epa(xfs.read_entry(str(archive), toc[epa]))
        catalog['sheets'][name] = {
            'entry': image, 'entry_sha256': hashlib.sha256(raw).hexdigest(), 'epa': epa,
            'frames': len(frames), 'cell': list(cell), 'origin': list(origin),
            'states': {state['name']: state['frames'] for state in states},
            'durations': {state['name']: state['durations'] for state in states},
        }
    (out / 'knight_ion.json').write_bytes((json.dumps(catalog, indent=1, sort_keys=True) + '\n').encode('utf-8'))
    return catalog


if __name__ == '__main__':
    result = import_assets()
    print('Knight Ion/child sheets:', ', '.join('%s %d frames' % (k, v['frames']) for k, v in result['sheets'].items()))
