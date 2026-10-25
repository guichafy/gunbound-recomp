"""Build the Bigfoot original sheets at 4x using the approved skill recipe (ADR-115)."""
import hashlib
import json
from pathlib import Path
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'skills/gunbound-classic-hd/scripts'))
from upscale_conservative import upscale
from validate_restoration import validate

SOURCE = 'assets/openbound/bigfoot/original'
SCALE = 4


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sheets(meta):
    """Every sheet with its measured grid; empty cells are part of the grid."""
    result = {'CharacterSpritesheet.png': {'cell': meta['cell'], 'columns': meta['columns'], 'record': None}}
    for name, info in meta['sheets'].items():
        result[name] = {'cell': info['cell'], 'columns': info['columns'], 'record': info}
    return result


def main():
    destination = ROOT / 'assets/hd/classic/mobiles_smooth_4x/bigfoot'
    reports = ROOT / 'docs/bigfoot-smooth-4x/reports'
    # Refuse a partial overwrite; previous derivatives and reports stay intact.
    if destination.exists() or reports.exists():
        raise FileExistsError('Output folders must be new; preserve existing derivatives/reports')
    meta_path = ROOT / SOURCE / 'frames.json'
    meta = json.loads(meta_path.read_text())
    destination.mkdir(parents=True)
    reports.mkdir(parents=True)
    catalog = {'version': 1, 'scale': SCALE, 'kind': 'bigfoot', 'method': 'BICUBIC per frame; native alpha NEAREST',
               'pillow': Image.__version__, 'frames_json': {'file': f'{SOURCE}/frames.json', 'sha256': sha(meta_path)},
               'sheets': {}}
    for name, info in sheets(meta).items():
        source = ROOT / SOURCE / name
        with Image.open(source) as image:
            width, height = image.size
        cell_w, cell_h = info['cell']
        if width % cell_w or height % cell_h or width // cell_w != info['columns']:
            raise ValueError(f'{name}: {width}x{height} does not match cell {cell_w}x{cell_h}, {info["columns"]} columns')
        columns, rows = width // cell_w, height // cell_h
        output = destination / name
        size = upscale(source, output, scale=SCALE, columns=columns, rows=rows)
        report = validate(source, output, scale=SCALE, columns=columns, rows=rows)
        if report['failures']:
            raise ValueError(f'{name}: {report["failures"]}')
        (reports / f'{Path(name).stem}.json').write_text(json.dumps(report, indent=2) + '\n')
        catalog['sheets'][name] = {'source': {'file': f'{SOURCE}/{name}', 'sha256': sha(source),
                                   'size': [width, height], 'record': info['record']},
                                   'sha256': sha(output), 'size': list(size), 'cell': [cell_w, cell_h],
                                   'columns': columns, 'rows': rows}
    (destination / 'catalog.json').write_text(json.dumps(catalog, indent=2) + '\n')
    print(f'{len(catalog["sheets"])} sheets; all alpha/dimension checks passed')


if __name__ == '__main__':
    main()
