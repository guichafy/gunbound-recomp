"""Extract room status/map plaques without changing existing native or HD assets."""
import hashlib
import json
from pathlib import Path
import sys

from PIL import Image
import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'skills/gunbound-classic-hd/scripts'))
from upscale_conservative import upscale
from validate_restoration import validate

ARCHIVE_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    archive = ROOT / '.tools/gunbound-client/graphics.xfs'
    assert sha(archive) == ARCHIVE_SHA
    native = ROOT / 'assets/classic/room/status'
    output = ROOT / 'assets/hd/classic/room_status_4x'
    reports = ROOT / 'docs/room-card-fidelity/reports'
    if any(path.exists() for path in (native, output, reports)):
        raise FileExistsError('Preserve existing outputs; use new destinations')
    for path in (native, output, reports):
        path.mkdir(parents=True)
    toc = {entry['name']: entry for entry in xfs.read_toc(archive)}
    specs = [('room_status', 'ready_back.img', [3, 4, 5, 6]),
             ('room_master_key', 'ready_back.img', [7])]
    for key, name in [('room_mode', 'solo'), ('room_size', '1vs1'),
                      ('room_map_side', 'aside'), ('room_death', 'nodeath'),
                      ('room_items', 'basicbomb')]:
        specs.append((key, 'b_ready_' + name + '.img', list(range(4))))
    records = {}
    catalog = {'version': 1, 'scale': 4,
               'method': 'BICUBIC per native frame; alpha NEAREST', 'assets': {}}
    for key, name, indices in specs:
        raw = xfs.read_entry(archive, toc[name])
        frames = xfs.frames(raw)
        chosen = [frames[index] for index in indices]
        width, height = chosen[0]['w'], chosen[0]['h']
        assert all((frame['w'], frame['h']) == (width, height) for frame in chosen)
        sheet = Image.new('RGBA', (width * len(chosen), height))
        for index, frame in enumerate(chosen):
            sheet.paste(frame['image'], (index * width, 0))
        relative = 'room/status/' + key + '.png'
        source = ROOT / 'assets/classic' / relative
        sheet.save(source)
        record = {'file': relative, 'size': list(sheet.size),
                  'frame_size': [width, height], 'frames': len(chosen)}
        records[key] = record
        dest = output / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        size = upscale(source, dest, 4, len(chosen), 1)
        report = validate(source, dest, 4, len(chosen), 1)
        assert not report['failures'], report['failures']
        (reports / (key + '.json')).write_text(json.dumps(report, indent=2) + '\n')
        catalog['assets'][key] = {
            'file': relative, 'source': {
                'file': str(source.relative_to(ROOT)), 'sha256': sha(source),
                'record': record, 'entry': name, 'img_indices': indices,
                'entry_sha256': hashlib.sha256(raw).hexdigest(),
                'hotspots': [[frame['hx'], frame['hy']] for frame in chosen]},
            'size': list(size), 'columns': len(chosen), 'rows': 1,
            'sha256': sha(dest)}
    (native / 'catalog.json').write_text(json.dumps(
        {'archive_sha256': ARCHIVE_SHA, 'assets': records}, indent=2) + '\n')
    (output / 'catalog.json').write_text(json.dumps(catalog, indent=2) + '\n')
    print('7 PNGs / 25 native windows validated; source and previous HD preserved')


if __name__ == '__main__':
    main()
