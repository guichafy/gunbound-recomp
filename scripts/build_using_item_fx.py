#!/usr/bin/env python3
"""UsingItem aura as its own overlay (OpenBound MobileFlipbook UsingItem).

Bigfoot frames 234–253 and Mage frames 243–262, 20 frames at 19 fps.
The HD mobile keeps one body, so the green diamonds and rising beams are
taken off those frames and redrawn at 4× as smooth shapes. The color-keyed
original pixels stay as the nearest-filter fallback.

A GPT Images pass (diamond + beam, references in /tmp during the session)
was not used: the diamond came back as an enlarged pixel cluster, and the
beam was a JPEG with a baked checkerboard, so neither had a real alpha.
"""

from __future__ import annotations

import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCALE = 4
COLUMNS = 5
FRAMES = 20

MOBILES = {
    "bigfoot": {
        "sheet": os.path.join(ROOT, "assets/openbound/bigfoot/CharacterSpritesheet.png"),
        "cell": (129, 130),
        "start": 234,
    },
    "mage": {
        "sheet": os.path.join(ROOT, "assets/openbound/mage/CharacterSpritesheet.png"),
        "cell": (109, 150),
        "start": 243,
    },
}


def source_frames(spec: dict) -> list[Image.Image]:
    image = Image.open(spec["sheet"]).convert("RGBA")
    width, height = spec["cell"]
    frames = []
    for index in range(FRAMES):
        frame = spec["start"] + index
        column, row = frame % 20, frame // 20
        frames.append(image.crop((column * width, row * height, (column + 1) * width, (row + 1) * height)))
    return frames


def green_map(frame: Image.Image) -> list[list[int]]:
    pixels = frame.load()
    width, height = frame.size
    values = [[0] * width for _ in range(height)]
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 30 and green > 45 and green > red + 8 and green > blue + 6:
                values[y][x] = green
    return values


def keyed_frame(frame: Image.Image) -> Image.Image:
    pixels = frame.load()
    out = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    dest = out.load()
    width, height = frame.size
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 30 and green > 45 and green > red + 8 and green > blue + 6:
                dest[x, y] = (red, green, blue, alpha)
    return out


def peaks(values: list[list[int]], min_dist: int = 11, min_value: int = 110) -> list[tuple[int, int, int]]:
    height = len(values)
    width = len(values[0])
    found = []
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            value = values[y][x]
            if value < min_value:
                continue
            if value >= values[y - 1][x] and value >= values[y + 1][x] and value >= values[y][x - 1] and value >= values[y][x + 1]:
                found.append((x, y, value))
    found.sort(key=lambda item: -item[2])
    kept = []
    for item in found:
        if all((item[0] - other[0]) ** 2 + (item[1] - other[1]) ** 2 >= min_dist * min_dist for other in kept):
            kept.append(item)
    return kept


def beams(values: list[list[int]], min_height: int = 12) -> list[tuple[float, float, float, float]]:
    """One thin column per local run, matching the 1–2 px beams in the atlas."""
    height = len(values)
    width = len(values[0])
    spans = []
    for x in range(width):
        ys = [y for y in range(height) if values[y][x] > 42]
        best: list[int] = []
        run: list[int] = []
        for y in ys:
            if not run or y <= run[-1] + 2:
                run.append(y)
            else:
                if len(run) > len(best):
                    best = run
                run = [y]
        if len(run) > len(best):
            best = run
        spans.append((len(best), best[0], best[-1]) if len(best) >= min_height else None)
    picked = []
    for x, span in enumerate(spans):
        if span is None:
            continue
        length = span[0]
        left = spans[x - 1][0] if x > 0 and spans[x - 1] else 0
        right = spans[x + 1][0] if x + 1 < width and spans[x + 1] else 0
        if length >= left and length >= right:
            picked.append((x, span[1], span[2], length))
    picked.sort(key=lambda item: -item[3])
    kept = []
    for item in picked:
        if all(abs(item[0] - other[0]) >= 4 for other in kept):
            kept.append(item)
    return [(x, x, y0, y1) for x, y0, y1, _length in kept]


def add(buffer: list, x: int, y: int, red: float, green: float, blue: float, alpha: float) -> None:
    height = len(buffer)
    width = len(buffer[0])
    if x < 0 or y < 0 or x >= width or y >= height or alpha <= 0:
        return
    pixel = buffer[y][x]
    pixel[0] += red * alpha
    pixel[1] += green * alpha
    pixel[2] += blue * alpha
    pixel[3] += alpha


def paint_diamond(buffer: list, cx: float, cy: float, radius: float) -> None:
    reach = radius * 1.45
    x0, x1 = int(cx - reach), int(cx + reach) + 1
    y0, y1 = int(cy - reach), int(cy + reach) + 1
    for y in range(y0, y1):
        for x in range(x0, x1):
            distance = abs(x - cx) / (radius * 0.78) + abs(y - cy) / radius
            if distance >= 1.2:
                continue
            if distance < 0.16:
                add(buffer, x, y, 240, 255, 220, 0.92)
            elif distance < 0.42:
                fade = 1.0 - (distance - 0.16) / 0.26
                add(buffer, x, y, 150, 255, 90, 0.55 + 0.35 * fade)
            else:
                fade = max(0.0, 1.0 - (distance - 0.42) / 0.78)
                add(buffer, x, y, 30, 190, 55, 0.62 * fade * fade)


def paint_beam(buffer: list, x0: float, x1: float, y0: float, y1: float) -> None:
    center = (x0 + x1) * 0.5
    half = SCALE * 1.15
    top, bottom = y0, y1
    for y in range(int(top - half), int(bottom + half) + 1):
        if bottom <= top:
            vertical = 0.0
        else:
            vertical = (y - top) / (bottom - top)
        if vertical < 0:
            vend = max(0.0, 1.0 + vertical * 1.4)
        elif vertical > 1:
            vend = max(0.0, 1.0 - (vertical - 1.0) * 1.4)
        else:
            vend = 0.45 + 0.55 * (1.0 - abs(vertical - 0.22))
        for x in range(int(center - half * 2.2), int(center + half * 2.2) + 1):
            horizontal = abs(x - center) / (half * 1.35)
            if horizontal >= 1:
                continue
            alpha = (1.0 - horizontal * horizontal) * vend * 0.9
            add(buffer, x, y, 186, 250, 96, alpha)
            if horizontal < 0.28:
                add(buffer, x, y, 230, 255, 190, alpha * 0.55)


def hd_frame(values: list[list[int]], cell: tuple[int, int]) -> Image.Image:
    width, height = cell
    out_w, out_h = width * SCALE, height * SCALE
    buffer = [[[0.0, 0.0, 0.0, 0.0] for _ in range(out_w)] for _ in range(out_h)]
    for x0, x1, y0, y1 in beams(values):
        paint_beam(
            buffer,
            x0 * SCALE,
            (x1 + 1) * SCALE,
            y0 * SCALE,
            (y1 + 1) * SCALE,
        )
    for x, y, value in peaks(values):
        radius = (5.0 + min(9.0, (value - 110) / 18.0)) * SCALE * 0.72
        paint_diamond(buffer, (x + 0.5) * SCALE, (y + 0.5) * SCALE, radius)
    image = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))
    dest = image.load()
    for y in range(out_h):
        row = buffer[y]
        for x in range(out_w):
            red, green, blue, alpha = row[x]
            if alpha <= 0.01:
                continue
            scale = 1.0 / alpha if alpha > 1.0 else 1.0
            dest[x, y] = (
                max(0, min(255, int(red * scale))),
                max(0, min(255, int(green * scale))),
                max(0, min(255, int(blue * scale))),
                max(0, min(255, int(min(1.0, alpha) * 255))),
            )
    return image


def pack(frames: list[Image.Image], cell: tuple[int, int]) -> Image.Image:
    width, height = cell
    rows = (FRAMES + COLUMNS - 1) // COLUMNS
    sheet = Image.new("RGBA", (width * COLUMNS, height * rows), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        column, row = index % COLUMNS, index // COLUMNS
        sheet.paste(frame, (column * width, row * height), frame)
    return sheet


def build(kind: str, spec: dict) -> None:
    frames = source_frames(spec)
    original = [keyed_frame(frame) for frame in frames]
    hd = [hd_frame(green_map(frame), spec["cell"]) for frame in frames]
    original_sheet = pack(original, spec["cell"])
    hd_cell = (spec["cell"][0] * SCALE, spec["cell"][1] * SCALE)
    hd_sheet = pack(hd, hd_cell)
    name = "UsingItem%s.png" % kind.capitalize()
    original_path = os.path.join(ROOT, "assets/openbound/items", name)
    hd_path = os.path.join(ROOT, "assets/hd/items", name)
    original_sheet.save(original_path)
    hd_sheet.save(hd_path)
    print(kind, "original", original_sheet.size, "hd", hd_sheet.size)


def main() -> None:
    for kind, spec in MOBILES.items():
        build(kind, spec)


if __name__ == "__main__":
    main()
