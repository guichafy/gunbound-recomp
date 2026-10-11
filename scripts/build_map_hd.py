"""Stitch GPT Images map tiles into the HD layers used by the game.

Source tiles (assets/hd/maps/<map>/source) and OpenBound originals
(assets/openbound/maps/<map>) are never modified. The original Foreground alpha
is the collision truth, so the HD foreground always receives that alpha; pixels
the generator left transparent inside the original mask fall back to the
upscaled original colours. Rerun after replacing any source tile.
"""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

# Original-pixel geometry. Tiles are 3:2 (foreground) or 2:3 (background)
# windows over the crop, with overlaps blended by a linear feather.
MAPS = {
    "miramo_town": {
        "foreground": {"file": "ForegroundA.png", "crop": [17, 1344, 1783, 1800],
                       "tiles": [0, 541, 1082], "tile_size": [684, 456],
                       "output": "foreground_a.png", "world_width": 1280, "density": 2},
        "background": {"file": "Background.png", "crop": [0, 260, 1300, 1300],
                       "tiles": [0, 607], "tile_size": [693, 1040],
                       "output": "background.png"},
    }
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def stitch(tiles, offsets, scale, size):
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    previous_end = 0
    for tile, offset in zip(tiles, offsets):
        left = round(offset * scale)
        tile = tile.convert("RGBA").resize((min(tile.width, size[0] - left), size[1]), Image.LANCZOS)
        overlap = max(0, previous_end - left)
        mask = Image.new("L", tile.size, 255)
        for x in range(overlap):
            mask.paste(round(255 * (x + 0.5) / overlap), (x, 0, x + 1, tile.height))
        region = canvas.crop((left, 0, left + tile.width, tile.height))
        canvas.paste(Image.composite(tile, region, mask), (left, 0))
        previous_end = left + tile.width
    return canvas


def premultiplied_resize(image, size):
    return image.convert("RGBa").resize(size, Image.LANCZOS).convert("RGBA")


def build_foreground(name, spec, report):
    source_dir = ROOT / "assets" / "hd" / "maps" / name / "source"
    paths = [source_dir / f"fg_tile{index}.png" for index in range(len(spec["tiles"]))]
    original = Image.open(ROOT / "assets" / "openbound" / "maps" / name / spec["file"]).convert("RGBA")
    strip = original.crop(tuple(spec["crop"]))
    tiles = [Image.open(path) for path in paths]
    scale = tiles[0].width / spec["tile_size"][0]
    size = (round(strip.width * scale), round(strip.height * scale))
    hd = stitch(tiles, spec["tiles"], scale, size)
    base = strip.resize(size, Image.LANCZOS)
    # Generator edges may be transparent where the original is solid; use the
    # original colour underneath so the collision silhouette never shows holes.
    filled = base.copy()
    filled.alpha_composite(hd)
    filled.putalpha(strip.getchannel("A").resize(size, Image.BILINEAR))
    out_width = spec["world_width"] * spec["density"]
    out_size = (out_width, round(strip.height * out_width / strip.width))
    result = premultiplied_resize(filled, out_size)
    out = ROOT / "assets" / "hd" / "maps" / name / spec["output"]
    result.save(out, optimize=True)
    report["foreground"] = {
        "output": out.name, "size": list(out_size), "sha256": sha256(out),
        "stitched_size": list(size), "scale_vs_original": round(out_width / strip.width, 4),
        "crop": spec["crop"], "tile_offsets": spec["tiles"], "tile_size": spec["tile_size"],
        "tiles": {p.name: sha256(p) for p in paths},
        "original": {spec["file"]: sha256(ROOT / "assets" / "openbound" / "maps" / name / spec["file"])},
    }


def build_background(name, spec, report):
    source_dir = ROOT / "assets" / "hd" / "maps" / name / "source"
    paths = [source_dir / f"bg_tile{index}.png" for index in range(len(spec["tiles"]))]
    if not all(path.exists() for path in paths):
        report["background"] = {"status": "pending", "missing": [p.name for p in paths if not p.exists()]}
        return
    crop = spec["crop"]
    tiles = [Image.open(path) for path in paths]
    scale = tiles[0].height / spec["tile_size"][1]
    size = (round((crop[2] - crop[0]) * scale), tiles[0].height)
    result = stitch(tiles, spec["tiles"], scale, size).convert("RGB")
    out = ROOT / "assets" / "hd" / "maps" / name / spec["output"]
    result.save(out, optimize=True)
    report["background"] = {
        "output": out.name, "size": list(size), "sha256": sha256(out),
        "scale_vs_original": round(scale, 4), "crop": crop, "tile_offsets": spec["tiles"],
        "tile_size": spec["tile_size"], "tiles": {p.name: sha256(p) for p in paths},
        "original": {spec["file"]: sha256(ROOT / "assets" / "openbound" / "maps" / name / spec["file"])},
    }


def main():
    for name, spec in MAPS.items():
        report = {"map": name}
        build_foreground(name, spec["foreground"], report)
        build_background(name, spec["background"], report)
        manifest = ROOT / "assets" / "hd" / "maps" / name / "manifest.json"
        manifest.write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
