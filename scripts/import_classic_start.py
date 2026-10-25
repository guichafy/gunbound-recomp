"""Add the native blue STARTGAME and its conservative4x strip; keep all prior PNGs."""
import hashlib
import json
from pathlib import Path
import sys

import gunbound_xfs as xfs
from import_classic_lobby import ARCHIVE_SHA, EPA4, EPA4_NAMES, strip_image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'skills/gunbound-classic-hd/scripts'))
from upscale_conservative import upscale
from validate_restoration import validate


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    archive = ROOT / '.tools/gunbound-client/graphics.xfs'
    assert sha(archive) == ARCHIVE_SHA
    key = 'b_ready_startgame'
    relative = 'room/' + key + '.png'
    native = ROOT / 'assets/classic' / relative
    hd_root = ROOT / 'assets/hd/classic/buttons_smooth_4x'
    enlarged = hd_root / relative
    report_path = ROOT / 'docs/room-final-polish/start-restoration.json'
    if any(path.exists() for path in (native, enlarged, report_path)):
        raise FileExistsError('Preserve existing PNGs/reports')
    manifest_path = ROOT / 'assets/classic/manifest.json'
    catalog_path = hd_root / 'catalog.json'
    manifest = json.loads(manifest_path.read_text())
    catalog = json.loads(catalog_path.read_text())
    assert key not in manifest['strips'] and key not in catalog['buttons']
    toc = {entry['name']: entry for entry in xfs.read_toc(archive)}
    raw = xfs.read_entry(archive, toc[key + '.img'])
    sheet, cell = strip_image(xfs.frames(raw), EPA4)
    assert cell == [107, 45]
    sheet.save(native)
    states, _ = xfs.parse_epa(xfs.read_entry(archive, toc[key + '.epa']))
    record = {'file': relative, 'entry': key + '.img',
              'entry_sha256': hashlib.sha256(raw).hexdigest(),
              'img_indices': EPA4, 'order': EPA4_NAMES, 'frame_size': cell,
              'frames': 4, 'epa': key + '.epa',
              'epa_states': {state['name']: state['frames'] for state in states},
              'note': 'START azul no padrão EXIT/CHANGE (ADR-108).'}
    size = upscale(native, enlarged, 4, 4, 1)
    report = validate(native, enlarged, 4, 4, 1)
    assert not report['failures']
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    catalog['buttons'][key] = {
        'file': relative, 'size': list(size), 'frame_size': [428, 180],
        'frames': 4, 'order': EPA4_NAMES,
        'frame_regions': [[i * 428, 0, 428, 180] for i in range(4)],
        'sha256': sha(enlarged), 'alpha_extrema': list(sheet.getchannel('A').getextrema()),
        'source': {'file': str(native.relative_to(ROOT)), 'sha256': sha(native),
                   'size': list(sheet.size), 'record': record},
        'verification': {'method': 'bicubic_per_frame_preserve_native_alpha',
                         'interpolated_colors': True,
                         'alpha_values_changed_pixels': 0,
                         'report': str(report_path.relative_to(ROOT))}}
    manifest['strips'][key] = record
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    catalog['source_manifest_sha256'] = sha(manifest_path)
    catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
    print('Added blue STARTGAME:4states107x45/native+4x; prior PNGs untouched')


if __name__ == '__main__':
    main()
