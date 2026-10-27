"""Approved BICUBIC4x finish (ADR-101/103) for the original Avatar Shop frames.

    python3 scripts/build_shop_smooth_hd.py

Reads assets/xfs/shop/catalog.json and writes one derivative per frame under
assets/hd/classic/shop_smooth_4x, plus its catalog and verifier reports. The
font atlas is processed per 8x12 glyph cell. Refuses to overwrite outputs.
"""
import hashlib
import json
from pathlib import Path
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'skills/gunbound-classic-hd/scripts'))
from upscale_conservative import upscale
from validate_restoration import validate


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    native = json.loads((ROOT / 'assets/xfs/shop/catalog.json').read_text())
    destination = ROOT / 'assets/hd/classic/shop_smooth_4x'
    reports = ROOT / 'docs/avatar-shop-original/reports'
    if destination.exists() or reports.exists():
        raise FileExistsError('Output folders must be new; preserve existing derivatives/reports')
    destination.mkdir(parents=True)
    reports.mkdir(parents=True)
    font = native['entries']['font']
    catalog = {'version': 1, 'scale': 4, 'method': 'BICUBIC per frame; native alpha NEAREST',
               'pillow': Image.__version__, 'frames': {}}
    failures = {}
    for key, record in native['frames'].items():
        relative = record['file'].removeprefix('res://assets/xfs/shop/')
        source = ROOT / 'assets/xfs/shop' / relative
        output = destination / relative
        output.parent.mkdir(parents=True, exist_ok=True)
        grid = (font['columns'], 8) if key == 'font:0' else (1, 1)
        size = upscale(source, output, scale=4, columns=grid[0], rows=grid[1])
        report = validate(source, output, scale=4, columns=grid[0], rows=grid[1])
        if report['failures']:
            failures[key] = report['failures']
        (reports / (key.replace(':', '_') + '.json')).write_text(json.dumps(report, indent=2) + '\n')
        catalog['frames'][key] = {'file': relative, 'size': list(size),
                                  'source': {'file': record['file'], 'sha256': record['sha256'],
                                             'size': record['size']},
                                  'sha256': sha(output)}
    if failures:
        raise ValueError(failures)
    (destination / 'catalog.json').write_text(json.dumps(catalog, indent=2) + '\n')
    print(f"{len(catalog['frames'])} PNGs; all alpha/dimension checks passed")


if __name__ == '__main__':
    main()
