#!/usr/bin/env python3
"""Independent GPU output checks (Pillow); does not call GDScript helpers."""
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'docs/projectile-light'
IDS = ['armor', 'bigfoot', 'trico', 'jd', 'asate', 'ice']


def verify():
    report = {}
    fixture = json.loads((ROOT / 'tests/fixtures/projectile_light_native.json').read_text())
    for tag, background in [('light', (200, 217, 232)), ('dark', (16, 24, 32))]:
        probes = []
        for kind in ['armor', 'jd']:
            for alpha in [1.0, 0.5]:
                image = Image.open(OUT / f'probe-{tag}-{kind}-{alpha}.png').convert('RGB')
                actual = image.getpixel((8, 8))
                # Actual RGBA8 uploaded by Image.fill, separately fixed here.
                expected = []
                for bg, body, light in zip(background, (102, 51, 26), (26, 77, 128)):
                    if kind == 'armor':
                        value = bg * (1 - 128 / 255 * alpha) + body * 128 / 255 * alpha
                        value += light * 64 / 255 * alpha
                    else:
                        value = bg + body * 128 / 255 * alpha
                    expected.append(min(255, round(value)))
                assert max(abs(a - b) for a, b in zip(actual, expected)) <= 2, (tag, kind, alpha, actual, expected)
                empty = Image.open(OUT / f'empty-{tag}-{kind}-{alpha}.png').convert('RGB')
                assert empty.getextrema() == tuple((v, v) for v in background), (tag, kind, 'residual light')
                probes.append({'kind': kind, 'alpha': alpha, 'actual': actual, 'expected': expected})
        # Compare unlit commands in exactly the same viewport/pixel location.
        # Side-by-side translated filtered quads may differ at a boundary texel.
        for kind in ['armor', 'bigfoot', 'asate']:
            for direction in [1, -1]:
                old = Image.open(OUT / f'unlit-{tag}-{kind}-{direction}-legacy.png').convert('RGBA')
                current = Image.open(OUT / f'unlit-{tag}-{kind}-{direction}-current.png').convert('RGBA')
                assert old.tobytes() == current.tobytes(), (tag, kind, direction, 'unlit raster changed')
        frames = ROOT / f'.tools/projectile-light/frames-{tag}'
        pause = [hashlib.sha256(Image.open(frames / f'{n:03d}.png').tobytes()).hexdigest() for n in range(65, 95)]
        assert len(set(pause)) == 1, f'{tag}: pause changes RGBA'
        resume = hashlib.sha256(Image.open(frames / '095.png').tobytes()).hexdigest()
        assert resume != pause[0], f'{tag}: presentation does not resume'
        captures = {n: Image.open(frames / f'{n:03d}.png').convert('RGBA') for n in [12, 36, 64, 120, 180, 240, 300, 360]}
        changes = {}
        for row in fixture['consumers']:
            differences = []
            for direction in range(2):
                column = (direction * 3 + row['weapon']) * 2
                y = IDS.index(row['kind']) * 180
                for n, image in captures.items():
                    before = image.crop((column * 160, y + 45, (column + 1) * 160, y + 180)).convert('RGB')
                    after = image.crop(((column + 1) * 160, y + 45, (column + 2) * 160, y + 180)).convert('RGB')
                    different = ImageChops.difference(before, after).getbbox() is not None
                    assert n != 360 or not different, f'{tag}/{row["kind"]}/{row["weapon"]}: residual pass'
                    differences.append(different)
            if row['light']:
                assert any(differences), f'{tag}/{row["kind"]}/{row["weapon"]}: additive correction absent'
            changes[f'{row["kind"]}/{row["weapon"]}'] = sum(differences)
        manifest = json.loads((OUT / f'capture-{tag}.json').read_text())
        assert manifest['remaining'] == [0] * 36 and manifest['empty_after_clear_identical']
        report[tag] = {'probes': probes, 'pause_frames': 30, 'pause_sha256': pause[0],
                       'resume_sha256': resume, 'changed_samples': changes,
                       'impacts': manifest['impacts'], 'empty_pairs': 36, 'same_position_unlit_pairs': 6}
    return report


if __name__ == '__main__':
    result = verify()
    (OUT / 'verification.json').write_text(json.dumps(result, indent=2) + '\n')
    print('GPU composition: numeric alpha/add probes, 60 paused buffers, 72 empty pairs, and unlit weapons PASS')
