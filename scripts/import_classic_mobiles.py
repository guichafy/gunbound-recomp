"""Extract original Thor's Hammer sheets for the mobiles still missing in Godot.

Mage (tank2), Nak (tank3) and Bigfoot (tank5) already have their own atlases.
This importer follows scripts/import_nak_assets.py: unchanged pixels, hotspot
origin, 20 columns, frames.json with the .epa pose lists.

    python3 scripts/import_classic_mobiles.py
"""
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image

import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / ".tools" / "gunbound-client" / "graphics.xfs"
ARCHIVE_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
AUDIO = ROOT / ".tools" / "source-assets" / "content" / "Audio" / "SFX" / "Tank"
CROSS = ROOT / ".tools" / "source-assets" / "content" / "Interface" / "InGame" / "HUD" / "Crosshair"
HUD = ROOT / "assets" / "openbound" / "hud"

# folder, graphics tank index (client id + 1), crosshair/sound prefix
MOBILES = [
    ("armor", 1, "Armor"),
    ("trico", 4, "Trico"),
    ("boomer", 6, "Boomer"),
    ("raon", 7, "Raon"),
    ("lightning", 8, "Lightning"),
    ("jd", 9, "JD"),
    ("asate", 10, "ASate"),
    ("ice", 11, "Ice"),
    ("turtle", 12, "Turtle"),
    ("grub", 13, "Grub"),
    # These three files are Dragon, Knight and Aduka. Kalsiddon and J.Frog
    # are not in this graphics.xfs.
    ("dragon", 14, "Dragon"),
    ("knight", 15, "Knight"),
    ("aduka", 16, "Aduka"),
]
POSES = {
    "idle": "normal", "idle_low": "wnormal", "moving": "move", "moving_low": "wmove",
    "charging_0": "bfire1", "charging_1": "bfire2", "charging_2": "bsfire",
    "recoil_0": "fire1", "recoil_1": "fire2", "recoil_2": "sfire",
    "hurt": "fdamage", "hurt_2": "bdamage", "falling": "drop", "destroyed": "dead",
    "unable": "unmove", "using_item": "item", "shock": "shock",
}
COLUMNS = 20


def pack(frames, columns):
    left = min(frame["hx"] for frame in frames)
    top = min(frame["hy"] for frame in frames)
    cell = (max(frame["hx"] + frame["w"] for frame in frames) - left,
            max(frame["hy"] + frame["h"] for frame in frames) - top)
    rows = (len(frames) + columns - 1) // columns
    sheet = Image.new("RGBA", (max(cell[0], 1) * columns, max(cell[1], 1) * rows))
    for index, frame in enumerate(frames):
        corner = ((index % columns) * cell[0] + frame["hx"] - left,
                  (index // columns) * cell[1] + frame["hy"] - top)
        sheet.paste(frame["image"], corner)
    return sheet, cell, [-left, -top]


def first_entry(toc, names):
    for name in names:
        if name in toc:
            return name
    return ""


def sheet_names(number, slot):
    """Body image candidates for S1/S2/SS. Some mobiles only ship the glow layer."""
    if slot == 1:
        return [f"bullet{number}n.img", f"bullet{number}nl.img"]
    if slot == 2:
        return [f"bullet{number}s.img", f"bullet{number}c.img", f"bullet{number}sl.img", f"bullet{number}cl.img"]
    return [f"bullet{number}p.img", f"bullet{number}pl.img"]


def light_names(number, slot):
    if slot == 1:
        return [f"bullet{number}nl.img"]
    if slot == 2:
        return [f"bullet{number}sl.img", f"bullet{number}cl.img"]
    return [f"bullet{number}pl.img"]


def table_name(image_name):
    return image_name[:-4] + ".epa" if image_name.endswith(".img") else ""


def save_sheet(toc, path, entry, columns, meta, label):
    if not entry:
        return
    raw = xfs.read_entry(path, toc[entry])
    frames = xfs.frames(raw)
    image, cell, origin = pack(frames, columns)
    image.save(meta["dir"] / label)
    info = {"entry": entry, "frames": len(frames), "columns": columns, "cell": list(cell), "origin": origin,
            "entry_sha256": hashlib.sha256(raw).hexdigest()}
    table = table_name(entry)
    if table in toc:
        states, _ = xfs.parse_epa(xfs.read_entry(path, toc[table]))
        info["states"] = {state["name"]: state["frames"] for state in states}
    meta["sheets"][label] = info


def copy_audio(folder, prefix):
    out = ROOT / "assets" / "openbound" / folder
    for kind, src_dir, dest in (("Shoot", AUDIO / "Shoot", "Shoot"), ("Blast", AUDIO / "Blast", "Blast")):
        for shot in ("S1", "S2", "SS"):
            source = src_dir / f"{prefix}{shot}.mp3"
            if source.exists():
                shutil.copyfile(source, out / f"{dest}{shot}.mp3")


def copy_crosshairs(prefix):
    for shot in ("S1", "S2", "SS"):
        for side in ("Ally", "Enemy"):
            source = CROSS / f"{prefix}{shot}{side}.png"
            if source.exists():
                shutil.copyfile(source, HUD / f"Crosshair{prefix}{shot}{side}.png")


def main():
    digest = hashlib.sha256(ARCHIVE.read_bytes()).hexdigest()
    if digest != ARCHIVE_SHA:
        raise SystemExit("unexpected graphics.xfs")
    toc = {entry["name"]: entry for entry in xfs.read_toc(ARCHIVE)}
    for folder, number, prefix in MOBILES:
        out = ROOT / "assets" / "openbound" / folder
        out.mkdir(parents=True, exist_ok=True)
        raw = xfs.read_entry(ARCHIVE, toc[f"tank{number}.img"])
        frames = xfs.frames(raw)
        image, cell, origin = pack(frames, COLUMNS)
        image.save(out / "CharacterSpritesheet.png")
        states, _ = xfs.parse_epa(xfs.read_entry(ARCHIVE, toc[f"tank{number}.epa"]))
        by_name = {state["name"]: state["frames"] for state in states}
        poses = {pose: by_name[state] for pose, state in POSES.items() if state in by_name and by_name[state]}
        rider = [[frame["extra"][2] + frame["hx"], frame["extra"][3] + frame["hy"]] for frame in frames]
        meta = {"dir": out, "sheets": {}}
        for slot, label in ((1, "Bullet1.png"), (2, "Bullet2.png"), (3, "Bullet3.png")):
            save_sheet(toc, ARCHIVE, first_entry(toc, sheet_names(number, slot)), 8, meta, label)
            save_sheet(toc, ARCHIVE, first_entry(toc, light_names(number, slot)), 8, meta, label.replace(".png", "Light.png"))
        for slot, label in ((1, "Flame1.png"), (2, "Flame2.png"), (3, "Flame3.png")):
            flame = first_entry(toc, [f"flame{number}{slot}.img", f"ssflame{number}.img" if slot == 3 else ""])
            save_sheet(toc, ARCHIVE, flame, 6, meta, label)
        info = {
            "source": "jglim/gunbound-launcher TestClient/graphics.xfs",
            "archive_sha256": ARCHIVE_SHA,
            "tank": number,
            "cell": list(cell),
            "origin": origin,
            "columns": COLUMNS,
            "poses": poses,
            "rider": rider,
            "hull": frames[poses["idle"][0]]["w"] if "idle" in poses else cell[0],
            "contact": frames[poses["idle"][0]]["h"] if "idle" in poses else cell[1],
            "sheets": meta["sheets"],
        }
        (out / "frames.json").write_text(json.dumps(info))
        (out / "RiderPivot.json").write_text(json.dumps(rider))
        copy_audio(folder, prefix)
        copy_crosshairs(prefix)
        print(folder, "frames", len(frames), "sheets", len(meta["sheets"]))


if __name__ == "__main__":
    main()
