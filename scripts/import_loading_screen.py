#!/usr/bin/env python3
"""Extract the Thor's Hammer match-loading panel from TestClient graphics.xfs.

load_back.img frame 0 is the 800×244 map panel. Frame 1 is the 156×14 red bar.
load_stage01.img frame 0 is the Miramo Town preview (the bitmap is labeled
MIRAMO TOWN). Frame 1 is the ground mask: the client scans each column from
the top for the first non-zero RGB565 pixel (VA 0x004430c0).

The archive is the local TestClient copy, SHA-256
a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from gunbound_xfs import frames, read_entry, read_toc

ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"
EXPECTED = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
OUT = ROOT / "assets/classic/loading"


def first_solid_row(image, x):
    for y in range(image.height):
        pixel = image.getpixel((x, y))
        if pixel[0] or pixel[1] or pixel[2]:
            return y
    return image.height


def main():
    import hashlib
    digest = hashlib.sha256(ARCHIVE.read_bytes()).hexdigest()
    if digest != EXPECTED:
        raise SystemExit("graphics.xfs hash %s != %s" % (digest, EXPECTED))
    entries = {entry["name"]: entry for entry in read_toc(ARCHIVE)}
    back = frames(read_entry(ARCHIVE, entries["load_back.img"]))
    stage = frames(read_entry(ARCHIVE, entries["load_stage01.img"]))
    if back[0]["image"].size != (800, 244) or back[1]["image"].size != (156, 14):
        raise SystemExit("unexpected load_back frames")
    if stage[0]["image"].size != (748, 209) or stage[1]["image"].size != (748, 209):
        raise SystemExit("unexpected load_stage01 frames")
    rows = [first_solid_row(stage[1]["image"], x) for x in range(748)]
    OUT.mkdir(parents=True, exist_ok=True)
    back[0]["image"].save(OUT / "load_back.png")
    back[1]["image"].save(OUT / "load_bar.png")
    stage[0]["image"].save(OUT / "miramo_town.png")
    catalog = {
        "archive_sha256": digest,
        "pe_sha256": "4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde",
        "panel": "load_back.img:0",
        "bar": "load_back.img:1",
        "preview": "load_stage01.img:0",
        "mask": "load_stage01.img:1",
        "preview_width": 748,
        "label_drop": 18,
        "ground_rows": rows,
    }
    (OUT / "catalog.json").write_text(json.dumps(catalog, indent=2) + "\n")
    print("wrote", OUT, "rows", len(rows), "sample", rows[61], rows[374], rows[695])


if __name__ == "__main__":
    main()
