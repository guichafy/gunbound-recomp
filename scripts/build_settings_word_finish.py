"""Keep native glyph faces, then finish one shared outline for SETTINGS."""
from pathlib import Path
import hashlib
import json

from PIL import Image, ImageChops, ImageFilter
from build_room_footer_alpha import SPEC, is_face, isolate_letter

ROOT = Path(__file__).resolve().parents[1]
VERTICAL_OFFSETS = {'T': 1}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def outline_alpha(face):
    seed = face.resize((face.width*4, face.height*4), Image.Resampling.NEAREST)
    result = Image.new('L', seed.size)
    # Native START has approximately two pixels of blue around its face.
    # One outline for the assembled word avoids boundaries from crop windows.
    for dy in range(-8, 9):
        for dx in range(-8, 9):
            if dx*dx+dy*dy <= 64:
                result = ImageChops.lighter(result, ImageChops.offset(seed, dx, dy))
    return result.filter(ImageFilter.GaussianBlur(0.6))


def build():
    native = ROOT / 'assets/classic/room/settings/room_settings_word_baseline.png'
    hd_root = ROOT / 'assets/hd/classic/room_settings_4x'
    relative = 'room/settings/room_settings_word_baseline.png'
    hd = hd_root / relative
    report = ROOT / 'docs/settings-baseline/source-baseline.json'
    if any(path.exists() for path in [native, hd, report]):
        raise FileExistsError('Keep previous outputs; select a new derivative name')
    sources = {name: Image.open(ROOT / ('assets/classic/room/b_ready_'+name+'.png')).convert('RGBA')
               for name in ['startgame', 'exit', 'changeteam']}
    glyphs = {}
    for letter, (name, x0, x1) in SPEC.items():
        source = sources[name]
        face = Image.new('L', (107, 45))
        for y in range(17, 28):
            for x in range(x0, x1):
                if is_face(source.getpixel((x, y))):
                    face.putpixel((x, y), 255)
        face = isolate_letter(face)
        core = Image.new('L', face.size)
        for y in range(45):
            for x in range(107):
                if face.getpixel((x, y)) and source.getpixel((x, y))[0] >= 190:
                    core.putpixel((x, y), 255)
        glyphs[letter] = (face, core.getbbox())

    gap = 2
    width = sum(glyphs[k][1][2]-glyphs[k][1][0] for k in 'SETTINGS') + gap*7 + 10
    height = 22
    native_sheet = Image.new('RGBA', (width*4, height))
    hd_sheet = Image.new('RGBA', (width*16, height*4))
    native_face_checks = 0
    states = []
    for state in range(4):
        delta = 1 if state == 2 else 0
        ink = sources['startgame'].getpixel((state*107+43+delta, 16+delta))[:3]
        rgb = Image.new('RGB', (width, height), ink)
        coverage = Image.new('L', rgb.size)
        x = 4
        samples = []
        placements = []
        for letter in 'SETTINGS':
            mask, bounds = glyphs[letter]
            source = sources[SPEC[letter][0]].crop((state*107, 0, (state+1)*107, 45))
            aligned = Image.new('RGBA', source.size)
            aligned.paste(source, (-delta, -delta))
            # The native T has a weaker top row above its strong core bounds.
            # Align that visible flat bar with E/I, rather than core boxes alone.
            optical_y = VERTICAL_OFFSETS.get(letter, 0)
            at = (x-bounds[0]+delta, 5-bounds[1]+delta+optical_y)
            rgb.paste(aligned.convert('RGB'), at, mask)
            coverage.paste(mask, at, mask)
            placements.append({'letter': letter, 'core_x': x+delta, 'core_y': 5+delta+optical_y,
                               'optical_y': optical_y,
                               'source_core_bounds': bounds})
            for sy in range(45):
                for sx in range(107):
                    if mask.getpixel((sx, sy)):
                        samples.append((sx+at[0], sy+at[1], aligned.getpixel((sx, sy))))
            x += bounds[2]-bounds[0]+gap

        alpha = outline_alpha(coverage)
        frame = rgb.resize((width*4, height*4), Image.Resampling.BICUBIC).convert('RGBA')
        frame.putalpha(alpha)
        hd_sheet.paste(frame, (state*width*4, 0))
        fallback = rgb.convert('RGBA')
        fallback_alpha = alpha.resize((width, height), Image.Resampling.BOX)
        fallback.putalpha(ImageChops.lighter(fallback_alpha, coverage))
        for px, py, expected in samples:
            assert fallback.getpixel((px, py)) == expected, (state, px, py, 'native face changed')
            native_face_checks += 1
        for image in [frame, fallback]:
            assert all(image.getpixel((x, y))[3] == 0 for x in range(image.width) for y in [0, image.height-1])
            assert all(image.getpixel((x, y))[3] == 0 for x in [0, image.width-1] for y in range(image.height))
        native_sheet.paste(fallback, (state*width, 0))
        states.append({'state': state, 'ink_rgb': ink, 'placements': placements,
                       'partly_transparent_edge_pixels': sum(0<a<255 for a in alpha.getdata())})

    native_sheet.save(native)
    hd_sheet.save(hd)
    record = {'file': relative, 'size': list(native_sheet.size),
              'frame_size': [width, height], 'frames': 4}
    metadata = {'file': relative, 'size': list(hd_sheet.size), 'columns': 4, 'rows': 1,
                'sha256': sha(hd),
                'source': {'file': str(native.relative_to(ROOT)), 'sha256': sha(native), 'record': record},
                'method': 'Original native RGBA faces; T optical offset +1px; 2px spacing; one START-blue outline radius2px, edge blur0.15px; RGB BICUBIC4x; derived alpha, fallback alpha BOX area coverage without ringing',
                'native_face_rgba_checks': native_face_checks}
    native_catalog = native.parent / 'catalog.json'
    hd_catalog = hd_root / 'catalog.json'
    records = json.loads(native_catalog.read_text())
    catalog = json.loads(hd_catalog.read_text())
    records['assets']['room_settings_word'] = record
    catalog['assets']['room_settings_word'] = metadata
    native_catalog.write_text(json.dumps(records, indent=2)+'\n')
    hd_catalog.write_text(json.dumps(catalog, indent=2)+'\n')
    report.write_text(json.dumps({'asset': metadata, 'states': states,
                                 'native_sources_decoded_rgba_sha256': {name: hashlib.sha256(image.tobytes()).hexdigest()
                                                    for name, image in sources.items()},
                                 'glyph_windows': SPEC, 'spacing': gap,
                                 'vertical_optical_offsets': VERTICAL_OFFSETS}, indent=2)+'\n')
    print('SETTINGS finished', width, height, '4states; original face RGBA checks', native_face_checks)


if __name__ == '__main__':
    build()
