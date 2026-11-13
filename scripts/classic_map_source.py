"""Pinned Thor's Hammer map identity and lossless raster validation."""

import hashlib
from PIL import Image

GRAPHICS_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
STAGE_SHA = "103c2b488977e1721becf8cb90496f95477302ec24141f94116d5214a3e6cfca"
PE_SHA = "4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde"
NAMES = [
    "cave",
    "miramo_town",
    "nirvana",
    "metropolis",
    "sea_of_hero",
    "adium_root",
    "dragon",
    "cozy_tower",
    "dummy_slope",
    "stardust",
    "meta_mine",
]
PREFIXES = [
    "cave",
    "mos",
    "hok",
    "metro",
    "candy",
    "babo",
    "last",
    "brick",
    "kettle",
    "star",
    "facky",
]


def family(stage):
    if not 0 <= stage < 22:
        raise ValueError("Unknown native stage")
    return stage % 11


def key(stage):
    return NAMES[family(stage)] + ("_a" if stage < 11 else "_b")


def world_prefix(stage):
    # 4d4004..4038 normalizes the packet index;43f108/43f21a use that family
    # alone for the graphics/LND prefix. Side enters41f200 weather separately.
    return PREFIXES[family(stage)]


def verify(name, raw):
    expected = {
        "graphics.xfs": GRAPHICS_SHA,
        "stage.dat": STAGE_SHA,
        "GunBound.gme": PE_SHA,
    }[name]
    if hashlib.sha256(raw).hexdigest() != expected:
        raise ValueError("Unsupported native identity: " + name)


def validate_land(image, land, width, height):
    if image.size != (width, height) or len(land) != width * height:
        raise ValueError("Land dimensions differ from foreground")
    alpha = image.getchannel("A").tobytes()
    if any((a > 0) != (b != 0) for a, b in zip(alpha, land)):
        raise ValueError("Land differs from foreground alpha")


def particle_atlas(decoded):
    half = 24
    for image, (x, y) in decoded:
        box = image.getchannel("A").getbbox()
        if box:
            half = max(half, -(x + box[0]), -(y + box[1]), x + box[2], y + box[3])
    cell = half * 2
    atlas = Image.new("RGBA", (20 * cell, ((len(decoded) + 19) // 20) * cell))
    for index, (image, (x, y)) in enumerate(decoded):
        atlas.alpha_composite(
            image, ((index % 20) * cell + half + x, (index // 20) * cell + half + y)
        )
    return atlas, half
