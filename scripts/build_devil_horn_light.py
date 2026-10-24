#!/usr/bin/env python3
"""Rebuild the Great Devil Head horn light from the classic L layer.

The classic mh00071l light is the horn's own silhouette, whitened and drawn
over the head: a flat cream/white core (effective alpha 187/255) covering the
whole horn including its outline, and a soft rim fading over ~4 native pixels.
A separately generated crescent never matched the HD horn, so the HD light is
derived here from the selected HD head's horn pixels and that measured
profile. Position and shape therefore match the anatomy by construction.

Original sprites and generated masters are read only. The output is a new PNG
registered pixel-for-pixel on the HD head region (plus padding for the rim).
"""
from collections import deque
from datetime import datetime, timezone
import hashlib
import json
from PIL import Image, ImageFilter, ImageChops
from prepare_xfs_avatar_hd import ROOT, SOURCE, read
from register_xfs_avatar_hd import build_catalog

KEY = 'xfs:0:0:71'
OUTPUT = ROOT/'assets/hd/avatars/xfs/great_devil_horn_light.png'
SHEET = 'great_devil_horn_light'
# Room for the rim where the horn touches the head window (tip and back).
PAD = 20
# Classic core: 187/255 white over the horn and its outline.
CORE = 187
# Rim fitted to the classic ratios to the horn area (outline included): light
# above 20/90/160 covers 1.81/1.43/0.98× the horn and 71% of its energy lies on
# the horn. Growing 4 px and blurring radius 5 gives 1.86/1.36/1.01× and 71%.
RIM_GROW = 4
RIM_BLUR = 5
# Outline of the HD horn is ~3 px; the classic core covers it as well.
OUTLINE = 3
RIM_COLOR = (255, 238, 176)


def gold(head):
    """Saturated gold of the horn; skin, hair and dark outline are excluded."""
    width, height = head.size
    mask = Image.new('L', head.size, 0)
    source, target = head.load(), mask.load()
    for y in range(height):
        for x in range(width):
            r, g, b, a = source[x, y]
            # The horn lives in the upper-left of the profile head window.
            if a > 128 and r > 110 and g > r*0.55 and b < g*0.6 and x < width*0.5 and y < height*0.7:
                target[x, y] = 255
    return mask


def neighbors(point, width, height):
    y, x = divmod(point, width)
    return ([point-1] if x else [])+([point+1] if x < width-1 else [])+([point-width] if y else [])+([point+width] if y < height-1 else [])


def largest(mask):
    width, height = mask.size
    data = bytearray(mask.tobytes())
    best = []
    for first, value in enumerate(data):
        if not value:
            continue
        queue = deque([first])
        data[first] = 0
        points = []
        while queue:
            point = queue.popleft()
            points.append(point)
            for other in neighbors(point, width, height):
                if data[other]:
                    data[other] = 0
                    queue.append(other)
        if len(points) > len(best):
            best = points
    result = bytearray(width*height)
    for point in best:
        result[point] = 255
    return Image.frombytes('L', mask.size, bytes(result))


def fill_holes(mask):
    width, height = mask.size
    data = mask.tobytes()
    outside = bytearray(width*height)
    queue = deque(p for p in range(width*height)
                  if not data[p] and (p < width or p >= width*(height-1) or p % width in (0, width-1)))
    for point in queue:
        outside[point] = 1
    while queue:
        point = queue.popleft()
        for other in neighbors(point, width, height):
            if not data[other] and not outside[other]:
                outside[other] = 1
                queue.append(other)
    return Image.frombytes('L', mask.size, bytes(0 if outside[p] else 255 for p in range(width*height)))


def grow(mask, pixels):
    return mask.filter(ImageFilter.MaxFilter(2*pixels+1))


def shrink(mask, pixels):
    return mask.filter(ImageFilter.MinFilter(2*pixels+1))


def horn_mask(head):
    """Solid horn: segment grooves closed, holes filled, outline included."""
    padded = Image.new('RGBA', (head.width+2*PAD, head.height+2*PAD), (0, 0, 0, 0))
    padded.paste(head, (PAD, PAD))
    closed = shrink(grow(gold(padded), 4), 4)
    return grow(fill_holes(largest(closed)), OUTLINE)


def light(horn):
    rim = grow(horn, RIM_GROW).filter(ImageFilter.GaussianBlur(RIM_BLUR))
    level = ImageChops.lighter(horn, rim)
    # Bright channel stays 255 so the L conversion (alpha × brightest channel)
    # keeps the measured alpha; the rim warms to the classic cream fringe.
    white = Image.new('RGB', horn.size, (255, 255, 255))
    cream = Image.new('RGB', horn.size, RIM_COLOR)
    image = Image.composite(white, cream, horn.filter(ImageFilter.GaussianBlur(2))).convert('RGBA')
    image.putalpha(level.point(lambda v: round(v*CORE/255)))
    return image


def main():
    accepted = read(SOURCE/'accepted.json')
    jobs = read(SOURCE/'jobs.json')
    base = accepted[KEY+'|layer:0']
    x, y, w, h = base['region']
    with Image.open(ROOT/base['sheet_meta']['file'].removeprefix('res://')) as sheet:
        head = sheet.convert('RGBA').crop((x, y, x+w, y+h))
    horn = horn_mask(head)
    image = light(horn)
    image.save(OUTPUT, optimize=True)
    histogram = image.getchannel('A').histogram()
    mean_alpha = sum(i*histogram[i] for i in range(9, 256))/max(1, sum(histogram[9:]))/255
    overlay = dict(feature='single profile horn', base_sheet=base['sheet'], base_region=base['region'],
                   offset=[-PAD, -PAD], derivation='HD horn silhouette + classic mh00071l profile',
                   core_alpha=CORE, rim_grow=RIM_GROW, rim_blur=RIM_BLUR, outline=OUTLINE)
    sheet_meta = dict(file='res://'+OUTPUT.relative_to(ROOT).as_posix(), size=list(image.size),
                      sha256=hashlib.sha256(OUTPUT.read_bytes()).hexdigest())
    identity = KEY+'|layer:1'
    entry = accepted[identity]
    for name in ('attachment', 'light_curve', 'contour_glow'):
        entry.pop(name, None)
    previous = entry.get('sheet_meta')
    entry.update(sheet=SHEET, sheet_meta=sheet_meta, region=[0, 0, image.width, image.height],
                 generated_mean_opacity=mean_alpha, overlay_base=overlay, draw_behind=False,
                 visual_review='derived from the HD horn silhouette; classic L profile measured')
    if previous != sheet_meta or entry.get('state') != 'qa_passed':
        entry['state'] = 'registered'
        entry['registered_at'] = datetime.now(timezone.utc).isoformat()
        entry.pop('evidence', None)
    for job in jobs['jobs']:
        for variant in job['variants']:
            if variant['id'] == identity:
                for name in ('attachment', 'light_curve', 'contour_glow'):
                    variant.pop(name, None)
                variant.update(overlay_base=overlay, draw_behind=False)
    (SOURCE/'jobs.json').write_text(json.dumps(jobs, ensure_ascii=False, indent=2)+'\n')
    (SOURCE/'accepted.json').write_text(json.dumps(accepted, ensure_ascii=False, indent=2)+'\n')
    build_catalog(accepted)
    print(f'{OUTPUT.relative_to(ROOT)}: {image.size}, horn pixels {horn.histogram()[255]}, state {entry["state"]}')


if __name__ == '__main__':
    main()
