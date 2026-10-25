"""Build the remaining lobby art from native PNGs using the approved skill recipe."""
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


def records():
    manifest = json.loads((ROOT / 'assets/classic/manifest.json').read_text())
    result = {key: value for key, value in manifest['images'].items() if key.startswith('lobby_')}
    ranks = json.loads((ROOT / 'assets/classic/ranks/catalog.json').read_text())
    for key, value in ranks['sheets'].items():
        w, h = value['frame_size']
        result[key] = {'file': f'ranks/{key}.png', 'size': [w * value['frames'], h],
                       'frame_size': [w, h], 'frames': value['frames']}
    return result


def main():
    destination = ROOT / 'assets/hd/classic/lobby_smooth_4x'
    reports = ROOT / 'docs/lobby-art-hd/reports'
    # Refuse a partial overwrite; previous approved derivatives stay intact.
    if destination.exists() or reports.exists():
        raise FileExistsError('Output folders must be new; preserve existing derivatives/reports')
    destination.mkdir(parents=True)
    reports.mkdir(parents=True)
    catalog = {'version': 1, 'scale': 4, 'method': 'BICUBIC per frame; native alpha NEAREST',
               'pillow': Image.__version__, 'assets': {}}
    for key, record in records().items():
        relative = record['file']
        source = ROOT / 'assets/classic' / relative
        output = destination / relative
        output.parent.mkdir(parents=True, exist_ok=True)
        columns = record.get('frames', 1)
        size = upscale(source, output, scale=4, columns=columns)
        report = validate(source, output, scale=4, columns=columns)
        if report['failures']:
            raise ValueError(f'{key}: {report["failures"]}')
        (reports / f'{key}.json').write_text(json.dumps(report, indent=2) + '\n')
        catalog['assets'][key] = {'file': relative, 'source': {'file': 'assets/classic/' + relative,
                                'sha256': sha(source), 'record': record},
                                'sha256': sha(output), 'size': list(size), 'columns': columns, 'rows': 1}
    (destination / 'catalog.json').write_text(json.dumps(catalog, indent=2) + '\n')
    print(f'{len(catalog["assets"])} PNGs; all alpha/dimension checks passed')


if __name__ == '__main__':
    main()
