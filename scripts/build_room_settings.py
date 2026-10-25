"""Extract classic room dialog components; preserve all existing PNGs/catalogs."""
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


def native_font(raw, native):
    # Native ASCII table:128 glyphs,12 row bytes each,8 pixels,most significant bit first.
    assert len(raw) == 0xc0600
    atlas = Image.new('RGBA', (128, 72), (255, 255, 255, 0))
    for index, code in enumerate(range(32, 127)):
        for row, bits in enumerate(raw[code * 12:(code + 1) * 12]):
            for column in range(8):
                if bits & (128 >> column):
                    atlas.putpixel(((index % 16) * 8 + column,
                                    (index // 16) * 12 + row), (255, 255, 255, 255))
    png = native / 'room_text.png'
    atlas.save(png)
    lines = [
        'info face="GunBound Classic ASCII" size=12 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0',
        'common lineHeight=12 base=10 scaleW=128 scaleH=72 pages=1 packed=0',
        'page id=0 file="room_text.png"', 'chars count=95']
    for index, code in enumerate(range(32, 127)):
        lines.append(f'char id={code} x={(index % 16) * 8} y={(index // 16) * 12} width=8 height=12 xoffset=0 yoffset=0 xadvance=8 page=0 chnl=15')
    (native / 'room_text.fnt').write_text('\n'.join(lines) + '\n')
    evidence = {'source_entry': 'font.fnt', 'entry_sha256': hashlib.sha256(raw).hexdigest(),
                'entry_size': len(raw), 'ascii_layout': '128 characters x 12 row bytes; msb first,8x12',
                'exported_codepoints': [32, 126], 'glyphs': 95, 'atlas_size': [128, 72],
                'atlas_sha256': sha(png),
                'unsupported_characters': 'existing room font fallback; no invented glyphs'}
    (ROOT / 'docs/room-settings-classic/font-source.json').write_text(json.dumps(evidence, indent=2) + '\n')


def main():
    archive = ROOT / '.tools/gunbound-client/graphics.xfs'
    assert sha(archive) == ARCHIVE_SHA
    native = ROOT / 'assets/classic/room/settings'
    output = ROOT / 'assets/hd/classic/room_settings_4x'
    reports = ROOT / 'docs/room-settings-classic/reports'
    if any(path.exists() for path in (native, output, reports)):
        raise FileExistsError('Preserve existing outputs')
    for path in (native, output, reports):
        path.mkdir(parents=True)
    toc = {entry['name']: entry for entry in xfs.read_toc(archive)}
    records = {}
    catalog = {'version': 1, 'scale': 4,
               'method': 'BICUBIC per native frame; alpha NEAREST', 'assets': {}}
    specs = [('room_settings_frame', 'ready_back.img', [8]),
             ('room_settings_ok', 'b_ready_ok.img', [0, 1, 2, 3]),
             ('room_settings_cancel', 'b_ready_cancel.img', [0, 1, 2, 3])]
    for key, name, indices in specs:
        raw = xfs.read_entry(archive, toc[name])
        frames = xfs.frames(raw)
        chosen = [frames[index] for index in indices]
        width, height = chosen[0]['w'], chosen[0]['h']
        assert all((frame['w'], frame['h']) == (width, height) for frame in chosen)
        sheet = Image.new('RGBA', (width * len(chosen), height))
        for index, frame in enumerate(chosen):
            sheet.paste(frame['image'], (index * width, 0))
        relative = 'room/settings/' + key + '.png'
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
            'file': relative, 'source': {'file': str(source.relative_to(ROOT)),
                'sha256': sha(source), 'record': record, 'entry': name,
                'img_indices': indices, 'entry_sha256': hashlib.sha256(raw).hexdigest(),
                'hotspots': [[frame['hx'], frame['hy']] for frame in chosen]},
            'size': list(size), 'columns': len(chosen), 'rows': 1,
            'sha256': sha(dest)}
    (native / 'catalog.json').write_text(json.dumps(
        {'archive_sha256': ARCHIVE_SHA, 'assets': records}, indent=2) + '\n')
    (output / 'catalog.json').write_text(json.dumps(catalog, indent=2) + '\n')
    native_font(xfs.read_entry(archive, toc['font.fnt']), native)
    print('3 PNGs / 9 native windows +95 native ASCII glyphs; previous artwork preserved')


if __name__ == '__main__':
    main()
