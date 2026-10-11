"""Build the HD battle HUD from GPT Images remasters of fixed-layout sheets.

`python3 scripts/build_hud_hd.py refs` writes the reference sheets that are
given to the generator (assets/hd/hud/source/ref_<sheet>.png). After saving each
generated image as assets/hd/hud/source/gen_<sheet>.png, `build` crops every
piece back from its known place, resizes it to SCALE times the original and
applies the original alpha, so silhouettes and frame rectangles stay exact.
Flat sprites (meters, aim wedges, frames) are upscaled directly. OpenBound
originals in assets/openbound/hud are never modified.
"""
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ORIGINALS = ROOT / "assets" / "openbound" / "hud"
OUT = ROOT / "assets" / "hd" / "hud"
SOURCE = OUT / "source"
SCALE = 3  # HD pixels per original pixel; the game draws 1.6x (Full HD = 2.4x).
FILL = (22, 30, 46, 255)


def original(name):
    if name == "WeatherIcons.png":
        return Image.open(ROOT / "assets" / "openbound" / "weather" / name).convert("RGBA")
    return Image.open(ORIGINALS / name).convert("RGBA")


def frames(name, width, height, count, columns=None):
    columns = columns or count
    return [(name, ((i % columns) * width, (i // columns) * height, (i % columns + 1) * width, (i // columns + 1) * height)) for i in range(count)]


def whole(name):
    image = original(name)
    return (name, (0, 0, image.width, image.height))


# Each sheet is a list of rows; each row is a list of (file, original rect).
SHEETS = {
    "bar": {"canvas": (1024, 1024), "gap": 15, "rows": [
        [("ActionBar.png", (0, 0, 300, 85))],
        [("ActionBar.png", (250, 0, 550, 85))],
        [("ActionBar.png", (500, 0, 800, 85))],
    ]},
    "buttons": {"canvas": (1536, 1024), "gap": 6, "rows": [
        frames("ShotSelector.png", 37, 37, 15)[0:5],
        frames("ShotSelector.png", 37, 37, 15)[5:10],
        frames("ShotSelector.png", 37, 37, 15)[10:15] + [whole("ShotStrenghtSelector.png")],
        frames("Options.png", 60, 23, 4),
        frames("SkipTurn.png", 60, 23, 4),
    ]},
    "fonts": {"canvas": (1024, 1024), "gap": 5, "rows": [
        [whole("FontCurrentAngle.png")],
        [whole("FontGold.png")],
        [whole("FontDamage.png")],
        [whole("FontCrosshairAngle.png")],
        [whole("FontWindCompass.png")],
        [whole("FontBlueTurnCounter.png")],
        [whole("FontRedTurnCounter.png")],
        [whole("FontPreviousAngle.png"), whole("FontDelay.png")],
    ]},
    "timer": {"canvas": (1536, 1024), "gap": 8, "rows": [[whole("FontTurnTimer.png")]]},
    "misc": {"canvas": (1536, 1024), "gap": 8, "rows": [
        [whole("CompassBackground.png"), whole("CompassForeground.png"), whole("CompassWhiteArrow.png"),
         whole("CompassYellowArrow.png"), whole("CompassRedArrow.png"), whole("CrosshairFrame.png")],
        [whole("TurnCounterBalloon.png"), whole("WeatherFrame.png")],
        [whole("WeatherIcons.png")],
    ]},
}

DIRECT = ["StrenghtMetter.png", "MovementMetter.png", "PreviousShootingStrenghtPointer.png",
          "CrosshairPointer.png", "HealthBarFrame.png"] + [
    f"Crosshair{mob}{shot}{side}.png" for mob in ["Mage", "Bigfoot"] for shot in ["S1", "S2", "SS"] for side in ["Ally", "Enemy"]]
NEAREST = ["SelectedPlayerTurnBG.png"]


def layout(sheet):
    """Places every piece; returns (scale, [(file, rect, canvas box)])."""
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


def write_refs():
    SOURCE.mkdir(parents=True, exist_ok=True)
    for key, sheet in SHEETS.items():
        _, placed = layout(sheet)
        canvas = Image.new("RGBA", sheet["canvas"], FILL)
        for name, rect, box in placed:
            piece = Image.new("RGBA", (rect[2] - rect[0], rect[3] - rect[1]), FILL)
            piece.alpha_composite(original(name).crop(rect))
            canvas.paste(piece.resize((box[2] - box[0], box[3] - box[1]), Image.LANCZOS), box[:2])
        canvas.convert("RGB").save(SOURCE / f"ref_{key}.png")
        print("ref", key, sheet["canvas"])


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def finish(name, colour, report, origin):
    source = original(name)
    size = (source.width * SCALE, source.height * SCALE)
    result = colour.resize(size, Image.LANCZOS) if colour.size != size else colour
    result.putalpha(source.getchannel("A").resize(size, Image.BILINEAR))
    out = OUT / name
    result.save(out, optimize=True)
    report[name] = {"size": list(size), "sha256": sha256(out), "from": origin}


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    report = {"scale": SCALE, "sprites": {}, "sheets": {}}
    canvases = {}
    for key, sheet in SHEETS.items():
        generated = SOURCE / f"gen_{key}.png"
        if not generated.exists():
            report["sheets"][key] = {"status": "pending"}
            continue
        image = Image.open(generated).convert("RGBA").resize(sheet["canvas"], Image.LANCZOS)
        report["sheets"][key] = {"generated": generated.name, "sha256": sha256(generated)}
        _, placed = layout(sheet)
        for name, rect, box in placed:
            src = original(name)
            if name not in canvases:
                canvases[name] = (Image.new("RGBA", (src.width * SCALE, src.height * SCALE), (0, 0, 0, 0)), [])
            canvas, ends = canvases[name]
            piece = image.crop(box).resize(((rect[2] - rect[0]) * SCALE, (rect[3] - rect[1]) * SCALE), Image.LANCZOS)
            target = (rect[0] * SCALE, rect[1] * SCALE)
            # Horizontal overlaps (bar segments) blend with a linear feather.
            overlap = 0
            for (ex, ey0, ey1) in ends:
                if ey0 == target[1] and ex > target[0]:
                    overlap = max(overlap, ex - target[0])
            mask = Image.new("L", piece.size, 255)
            for x in range(overlap):
                mask.paste(round(255 * (x + 0.5) / overlap), (x, 0, x + 1, piece.height))
            region = canvas.crop((target[0], target[1], target[0] + piece.width, target[1] + piece.height))
            canvas.paste(Image.composite(piece, region, mask), target)
            ends.append((target[0] + piece.width, target[1], target[1] + piece.height))
    for name, (canvas, _) in canvases.items():
        finish(name, canvas, report["sprites"], "gpt")
    for name in DIRECT:
        finish(name, original(name).resize((original(name).width * SCALE, original(name).height * SCALE), Image.LANCZOS), report["sprites"], "lanczos")
    for name in NEAREST:
        finish(name, original(name).resize((original(name).width * SCALE, original(name).height * SCALE), Image.NEAREST), report["sprites"], "nearest")
    (OUT / "manifest.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: v.get("status", "ok") for k, v in report["sheets"].items()}, indent=2), len(report["sprites"]), "sprites")


if __name__ == "__main__":
    write_refs() if sys.argv[1:] == ["refs"] else build()
