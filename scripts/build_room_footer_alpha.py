"""Clean only native button mattes and compose SETTINGS from isolated glyphs."""
from pathlib import Path
import hashlib
import json
import sys

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'skills/gunbound-classic-hd/scripts'))
from upscale_conservative import upscale
from validate_restoration import validate

SPEC = {
    'S': ('startgame', 43, 51),
    'E': ('changeteam', 83, 92),
    'T': ('startgame', 51, 59),
    'I': ('exit', 67, 69),
    'N': ('changeteam', 64, 72),
    'G': ('changeteam', 74, 83),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def is_face(pixel):
    r, g, b, _ = pixel
    a = r / 255
    residual = min(max(abs(g - (89 + 166*a)), abs(b - (164 - 49*a))),
                   max(abs(g - (89 + 166*a)), abs(b - (164 + 91*a))))
    return r >= 49 and residual <= 6.5


def isolate_letter(mask):
    """Discard disconnected fill fragments belonging to neighbouring glyphs."""
    remaining = {(x, y) for y in range(mask.height) for x in range(mask.width)
                 if mask.getpixel((x, y))}
    components = []
    while remaining:
        stack = [remaining.pop()]
        component = set(stack)
        while stack:
            x, y = stack.pop()
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    neighbour = (x+dx, y+dy)
                    if neighbour in remaining:
                        remaining.remove(neighbour)
                        component.add(neighbour)
                        stack.append(neighbour)
        components.append(component)
    result = Image.new('L', mask.size)
    for point in max(components, key=len):
        result.putpixel(point, 255)
    return result


def main():
    source_paths = {name: ROOT / ('assets/classic/room/b_ready_' + name + '.png')
                    for name in ['startgame', 'changeteam', 'exit']}
    sources = {name: Image.open(path).convert('RGBA') for name, path in source_paths.items()}
    native_dir = ROOT / 'assets/classic/room/settings'
    hd_dir = ROOT / 'assets/hd/classic/room_settings_4x'
    report = ROOT / 'docs/room-button-alpha/source-isolated.json'
    outputs = [native_dir / ('room_' + name + '.png')
               for name in ['footer_shell_clear', 'settings_word_isolated']]
    if report.exists():
        raise FileExistsError('Preserve previous report; choose a new derivative name')

    # Use the existing right rounded cap, mirrored at left, and the same clean
    # central column as the approved START. No arrow, text or baked corner scene.
    shell = Image.new('RGBA', (428, 45))
    for state in range(4):
        source = sources['startgame'].crop((state*107, 0, (state+1)*107, 45))
        cap = source.crop((91, 0, 107, 45))
        # Trace the outside of the native black outline row by row. Preserve
        # every pixel inside it; discard the photographed scenery outside.
        for y in range(45):
            edge = max(x for x in range(91, 107)
                       if max(source.getpixel((x, y))[:3]) <= 8)
            for x in range(edge + 1, 107):
                cap.putpixel((x-91, y), (0, 0, 0, 0))
        frame = Image.new('RGBA', (107, 45))
        frame.paste(cap.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (0, 0))
        frame.paste(source.crop((35, 0, 36, 45)).resize((75, 45)), (16, 0))
        frame.paste(cap, (91, 0))
        shell.paste(frame, (state*107, 0))

    glyphs = {}
    for letter, (name, x0, x1) in SPEC.items():
        source = sources[name].crop((0, 0, 107, 45))
        face = Image.new('L', source.size)
        for y in range(17, 28):
            for x in range(x0, x1):
                if is_face(source.getpixel((x, y))):
                    face.putpixel((x, y), 255)
        face = isolate_letter(face)
        core = Image.new('L', source.size)
        for y in range(45):
            for x in range(107):
                if face.getpixel((x, y)) and source.getpixel((x, y))[0] >= 190:
                    core.putpixel((x, y), 255)
        bounds = core.getbbox()
        assert bounds and 9 <= bounds[3]-bounds[1] <= 10, (letter, bounds)
        contour = Image.new('L', source.size)
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if dx*dx + dy*dy <= 5:
                    contour = ImageChops.lighter(contour, ImageChops.offset(face, dx, dy))
        # Keep source outline colours; do not repaint or synthesize the face.
        for y in range(45):
            for x in range(107):
                pixel = source.getpixel((x, y))
                background = sources['startgame'].getpixel((35, y))
                if max(abs(pixel[i]-background[i]) for i in range(3)) <= 8:
                    contour.putpixel((x, y), 0)
                elif not x0 <= x < x1 and is_face(pixel):
                    contour.putpixel((x, y), 0)
        glyphs[letter] = (contour, face, bounds)

    # Three clear native pixels between face bounding boxes. The original blue
    # contours overlap naturally, while yellow/white stems stay independent.
    gap = 3
    width = sum(glyphs[k][2][2]-glyphs[k][2][0] for k in 'SETTINGS') + gap*7 + 8
    height = 20
    word = Image.new('RGBA', (width*4, height))
    exact = 0
    placements = []
    for state in range(4):
        delta = 1 if state == 2 else 0
        frame = Image.new('RGBA', (width, height))
        layers = []
        x = 3
        for letter in 'SETTINGS':
            contour, face, bounds = glyphs[letter]
            source = sources[SPEC[letter][0]].crop((state*107, 0, (state+1)*107, 45))
            aligned = Image.new('RGBA', source.size)
            aligned.paste(source, (-delta, -delta))
            at = (x-bounds[0]+delta, 4-bounds[1]+delta)
            layers.append((aligned, contour, face, at))
            if state == 0:
                placements.append({'letter': letter, 'core_x': x, 'core_y': 4,
                                   'core_width': bounds[2]-bounds[0]})
            x += bounds[2]-bounds[0]+gap
        for pass_index in [1, 2]:
            for source, contour, face, at in layers:
                mask = contour if pass_index == 1 else face
                part = source.copy()
                part.putalpha(mask)
                for y in range(45):
                    for x in range(107):
                        if mask.getpixel((x, y)):
                            assert 0 <= x+at[0] < width and 0 <= y+at[1] < height
                frame.paste(part, at, mask)
        for source, _, face, at in layers:
            for y in range(45):
                for x in range(107):
                    if face.getpixel((x, y)):
                        assert frame.getpixel((x+at[0], y+at[1])) == source.getpixel((x, y))
                        exact += 1
        word.paste(frame, (state*width, 0))
    if outputs[0].exists():
        assert Image.open(outputs[0]).convert('RGBA').tobytes() == shell.tobytes()
    else:
        shell.save(outputs[0])
    if outputs[1].exists():
        assert Image.open(outputs[1]).convert('RGBA').tobytes() == word.tobytes()
    else:
        word.save(outputs[1])

    native_catalog = native_dir / 'catalog.json'
    hd_catalog = hd_dir / 'catalog.json'
    native = json.loads(native_catalog.read_text())
    hd = json.loads(hd_catalog.read_text())
    metadata = {}
    for key, path, size in [('room_footer_shell', outputs[0], [107, 45]),
                            ('room_settings_word', outputs[1], [width, height])]:
        relative = str(path.relative_to(ROOT / 'assets/classic'))
        destination = hd_dir / relative
        if not destination.exists():
            upscale(path, destination, 4, 4, 1)
        validation = validate(path, destination, 4, 4, 1)
        assert not validation['failures']
        record = {'file': relative, 'size': [size[0]*4, size[1]],
                  'frame_size': size, 'frames': 4}
        native['assets'][key] = record
        entry = {'file': relative, 'size': [size[0]*16, size[1]*4],
                 'columns': 4, 'rows': 1, 'sha256': sha(destination),
                 'source': {'file': str(path.relative_to(ROOT)), 'sha256': sha(path),
                            'record': record},
                 'method': 'Native RGBA copy and matte removal; BICUBIC4x/native alpha NEAREST',
                 'restoration_validation': validation}
        hd['assets'][key] = entry
        metadata[key] = entry
    native_catalog.write_text(json.dumps(native, indent=2)+'\n')
    hd_catalog.write_text(json.dumps(hd, indent=2)+'\n')
    report.write_text(json.dumps({'assets': metadata, 'native_sources': {k: sha(p) for k, p in source_paths.items()},
                                 'glyph_windows': SPEC, 'placements': placements,
                                 'native_face_rgba_checks': exact, 'face_spacing': gap}, indent=2)+'\n')
    print('Transparent shell 107x45; SETTINGS', width, height, '; original face checks', exact)


if __name__ == '__main__':
    main()
