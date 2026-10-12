"""Build the HD item sprites (0.13) from GPT Images remasters of fixed-layout sheets.

Same flow as build_hud_hd.py: `python3 scripts/build_items_hd.py refs` writes
assets/hd/items/source/ref_<sheet>.png; the Codex image_gen output for each is
saved as gen_<sheet>.png; running without arguments crops every piece back from
its known place, resizes it to the target scale and applies the original alpha.

- UI sheets (item buttons, ITEM LOCKED, tab, Select Item popup) sit on the flat
  HUD navy and become 3x the original (the HUD draws 1.6x; Full HD is 2.4x).
- Effect sheets (teleport beacon, teleport flame keyframes) are glows with low
  alpha, composited on black as they look in game. The build divides the
  generated colour by the original alpha (un-premultiply) and applies that
  alpha, so soft edges keep their hue. They become 2x the original (the world
  is drawn 1:1; Full HD is 1.5x).
- Teleport2.png is Teleport1.png played backwards (pixel identical), so one
  keyframe sheet serves both flames.
OpenBound originals in assets/openbound/items are never modified.
"""
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ORIGINALS = ROOT / "assets" / "openbound" / "items"
OUT = ROOT / "assets" / "hd" / "items"
SOURCE = OUT / "source"
NAVY = (22, 30, 46, 255)
BLACK = (0, 0, 0, 255)
# SpecialEffectBuilder.TeleportFlame1: 19 frames of 190x192 at 30 fps.
FLAME_CELL = (190, 192)
FLAME_KEYS = [0, 2, 4, 6, 8, 11, 14, 18]
BEACON_CELL = (43, 39)


def original(name):
    return Image.open(ORIGINALS / name).convert("RGBA")


def cell(name, size, index, columns):
    x, y = (index % columns) * size[0], (index // columns) * size[1]
    return (name, (x, y, x + size[0], y + size[1]))


def whole(name):
    image = original(name)
    return (name, (0, 0, image.width, image.height))


TWO_SLOTS = ["Dual", "DualPlus", "Thunder", "EnergyUp2", "TeamTeleport", "Teleport"]
ONE_SLOT = ["Blood", "BungeShot", "PowerUp", "ChangeWind", "EnergyUp1"]

# Each sheet: canvas, gap, background, output scale, rows of (file, rect).
SHEETS = {
    "items2": {"canvas": (1536, 1024), "gap": 6, "fill": NAVY, "scale": 3,
               "rows": [[whole(f"Item{n}.png")] for n in TWO_SLOTS]},
    "items1": {"canvas": (1024, 1024), "gap": 8, "fill": NAVY, "scale": 3,
               "rows": [[whole(f"Item{n}.png")] for n in ONE_SLOT]
               + [[whole("TabIndex.png")], [("MatchStatus.png", (0, 0, 217, 35))]]},
    "popup": {"canvas": (1024, 1024), "gap": 4, "fill": NAVY, "scale": 3,
              "rows": [[whole("SelectItemBackground.png")]]},
    "beacon": {"canvas": (1536, 1024), "gap": 6, "fill": BLACK, "scale": 2, "glow": True,
               "rows": [[cell("TeleportBullet.png", BEACON_CELL, r * 4 + c, 12) for c in range(4)] for r in range(3)]},
    "flame": {"canvas": (1536, 1024), "gap": 8, "fill": BLACK, "scale": 2, "glow": True,
              "rows": [[cell("Teleport1.png", FLAME_CELL, k, 10) for k in FLAME_KEYS[:4]],
                       [cell("Teleport1.png", FLAME_CELL, k, 10) for k in FLAME_KEYS[4:]]]},
}


def layout(sheet):
    """Places every piece; returns [(file, rect, canvas box)]."""
    gap = sheet["gap"]
    rows = sheet["rows"]
    width = max(sum(r[2] - r[0] for _, r in row) + gap * (len(row) + 1) for row in rows)
    height = sum(max(r[3] - r[1] for _, r in row) for row in rows) + gap * (len(rows) + 1)
    canvas = sheet["canvas"]
    scale = min(canvas[0] / width, canvas[1] / height)
    left = (canvas[0] - width * scale) / 2
    top = (canvas[1] - height * scale) / 2
    placed = []
    y = gap
    for row in rows:
        x = gap
        for name, rect in row:
            w, h = rect[2] - rect[0], rect[3] - rect[1]
            box = (round(left + x * scale), round(top + y * scale), round(left + (x + w) * scale), round(top + (y + h) * scale))
            placed.append((name, rect, box))
            x += w + gap
        y += max(r[3] - r[1] for _, r in row) + gap
    return scale, placed


def unpremultiply(colour, alpha, fallback):
    """Generated glow over black = colour x alpha: recover the colour. Faint
    pixels would amplify the generator's background haze, so below alpha 96 the
    result blends back to the original colour (fully original under 16)."""
    pixels = []
    for (r, g, b, _), a, (fr, fg, fb, _) in zip(colour.getdata(), alpha.getdata(), fallback.getdata()):
        weight = min(1.0, max(0.0, (a - 16) / 80.0))
        if weight <= 0.0:
            pixels.append((fr, fg, fb, a))
            continue
        ur, ug, ub = (min(255, c * 255 // a) for c in (r, g, b))
        pixels.append((round(fr + (ur - fr) * weight), round(fg + (ug - fg) * weight), round(fb + (ub - fb) * weight), a))
    result = Image.new("RGBA", colour.size)
    result.putdata(pixels)
    return result


def write_refs():
    SOURCE.mkdir(parents=True, exist_ok=True)
    for key, sheet in SHEETS.items():
        scale, placed = layout(sheet)
        canvas = Image.new("RGBA", sheet["canvas"], sheet["fill"])
        for name, rect, box in placed:
            piece = Image.new("RGBA", (rect[2] - rect[0], rect[3] - rect[1]), sheet["fill"])
            crop = original(name).crop(rect)
            piece.alpha_composite(crop)
            canvas.paste(piece.resize((box[2] - box[0], box[3] - box[1]), Image.LANCZOS), box[:2])
        canvas.convert("RGB").save(SOURCE / f"ref_{key}.png")
        print("ref", key, sheet["canvas"], f"{scale:.2f}x")


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    report = {"sheets": {}, "sprites": {}}
    canvases = {}
    for key, sheet in SHEETS.items():
        generated = SOURCE / f"gen_{key}.png"
        if not generated.exists():
            report["sheets"][key] = {"status": "pending"}
            continue
        image = Image.open(generated).convert("RGBA").resize(sheet["canvas"], Image.LANCZOS)
        report["sheets"][key] = {"generated": generated.name, "sha256": sha256(generated)}
        _, placed = layout(sheet)
        factor = sheet["scale"]
        for name, rect, box in placed:
            out_name = "TeleportFlame.png" if key == "flame" else name
            src = original(name)
            if key == "flame":
                size = (FLAME_CELL[0] * factor * len(FLAME_KEYS), FLAME_CELL[1] * factor)
            elif name == "MatchStatus.png":
                size = (217 * factor, 35 * factor)
            else:
                size = (src.width * factor, src.height * factor)
            if out_name not in canvases:
                canvases[out_name] = {"image": Image.new("RGBA", size, (0, 0, 0, 0)), "scale": factor, "from": key}
            w, h = (rect[2] - rect[0]) * factor, (rect[3] - rect[1]) * factor
            colour = image.crop(box).resize((w, h), Image.LANCZOS)
            alpha = src.crop(rect).getchannel("A").resize((w, h), Image.BILINEAR)
            if sheet.get("glow"):
                colour = unpremultiply(colour, alpha, src.crop(rect).resize((w, h), Image.LANCZOS))
            else:
                colour.putalpha(alpha)
            if key == "flame":
                target = (FLAME_KEYS.index(rect[0] // FLAME_CELL[0] + rect[1] // FLAME_CELL[1] * 10) * w, 0)
            elif name == "MatchStatus.png":
                target = (0, 0)
            else:
                target = (rect[0] * factor, rect[1] * factor)
            canvases[out_name]["image"].paste(colour, target)
    for name, entry in canvases.items():
        out = OUT / name
        entry["image"].save(out, optimize=True)
        report["sprites"][name] = {"size": list(entry["image"].size), "scale": entry["scale"], "sheet": entry["from"], "sha256": sha256(out)}
    report["flame_keys"] = FLAME_KEYS
    (OUT / "manifest.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: v.get("status", "ok") for k, v in report["sheets"].items()}, indent=2), len(report["sprites"]), "sprites")


if __name__ == "__main__":
    write_refs() if sys.argv[1:] == ["refs"] else build()
