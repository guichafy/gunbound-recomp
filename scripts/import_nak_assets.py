"""Extract the original Nak sprites from the Thor's Hammer client (ADR-069).

    python3 scripts/import_nak_assets.py [--xfs .tools/gunbound-client/graphics.xfs]

OpenBound has no Nak atlas. The original client keeps it in graphics.xfs:
tank3.img (392 frames) with its animation table tank3.epa, the shots
bullet3n/bullet3s/bullet3pl with their glow layers, and the impacts
flame31/flame32/ssflame3. Every frame is placed by its own hotspot, so the
pixels are copied unchanged into uniform cells: CharacterSpritesheet.png uses
20 columns like the OpenBound atlases and its pivot is the hotspot origin, the
same origin the fork's Nak RiderPivot.json is measured from. frames.json keeps
cells, origins and the .epa sequences; SOURCE_MANIFEST.json the entry hashes.
"""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "openbound" / "nak"
ARCHIVE_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
# file -> (graphics.xfs entry, animation table, columns)
SHEETS = {
    "CharacterSpritesheet.png": ("tank3.img", "tank3.epa", 20),
    "Bullet1.png": ("bullet3n.img", "bullet3n.epa", 10),
    "Bullet1Light.png": ("bullet3nl.img", None, 10),
    "Bullet2.png": ("bullet3s.img", "bullet3s.epa", 8),
    "Bullet2Light.png": ("bullet3sl.img", None, 8),
    "Bullet3.png": ("bullet3pl.img", "bullet3p.epa", 9),
    "Flame1.png": ("flame31.img", "flame31.epa", 6),
    "Flame2.png": ("flame32.img", "flame32.epa", 6),
    "Flame3.png": ("ssflame3.img", "ssflame3.epa", 5),
}


def find_default_xfs():
    for base in [ROOT, *ROOT.parents]:
        candidate = base / ".tools" / "gunbound-client" / "graphics.xfs"
        if candidate.exists():
            return candidate
    return ROOT / ".tools" / "gunbound-client" / "graphics.xfs"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--xfs", type=Path, default=None)
    path = parser.parse_args().xfs or find_default_xfs()
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != ARCHIVE_SHA:
        raise SystemExit("unexpected graphics.xfs %s (want TestClient %s)" % (digest, ARCHIVE_SHA))
    toc = {entry["name"]: entry for entry in xfs.read_toc(path)}
    OUT.mkdir(parents=True, exist_ok=True)
    manifest_path = ROOT / "assets" / "openbound" / "SOURCE_MANIFEST.json"
    manifest = json.loads(manifest_path.read_text())
    meta = {"source": "jglim/gunbound-launcher TestClient/graphics.xfs", "archive_sha256": ARCHIVE_SHA, "sheets": {}}
    for name, (entry, table, columns) in SHEETS.items():
        raw = xfs.read_entry(path, toc[entry])
        frames = xfs.frames(raw)
        left = min(f["hx"] for f in frames)
        top = min(f["hy"] for f in frames)
        cell = (max(f["hx"] + f["w"] for f in frames) - left, max(f["hy"] + f["h"] for f in frames) - top)
        rows = (len(frames) + columns - 1) // columns
        sheet = Image.new("RGBA", (cell[0] * columns, cell[1] * rows))
        for index, frame in enumerate(frames):
            corner = ((index % columns) * cell[0] + frame["hx"] - left, (index // columns) * cell[1] + frame["hy"] - top)
            sheet.paste(frame["image"], corner)
        sheet.save(OUT / name)
        info = {"entry": entry, "frames": len(frames), "columns": columns, "cell": list(cell), "origin": [-left, -top],
                "entry_sha256": hashlib.sha256(raw).hexdigest()}
        if table:
            states, _ = xfs.parse_epa(xfs.read_entry(path, toc[table]))
            info["states"] = {state["name"]: state["frames"] for state in states}
        if entry == "tank3.img":
            # Rider point per frame (last two unmapped fields + hotspot); equals
            # the fork's RiderPivot.json where that file has data.
            info["rider"] = [[f["extra"][2] + f["hx"], f["extra"][3] + f["hy"]] for f in frames]
        meta["sheets"][name] = info
        manifest["nak/" + name] = {"source": "TestClient/graphics.xfs:" + entry, "sha256": hashlib.sha256((OUT / name).read_bytes()).hexdigest()}
        print("%-26s %-14s %3d frames cell %s origin %s" % (name, entry, len(frames), cell, info["origin"]))
    (OUT / "frames.json").write_text(json.dumps(meta, indent=1) + "\n")
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
