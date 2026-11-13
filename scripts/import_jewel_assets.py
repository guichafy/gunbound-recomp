"""Extract Thor JEWEL images/EPA without resampling or alpha/key changes."""
import hashlib
import json
from pathlib import Path

from PIL import Image
import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"
ARCHIVE_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
OUT = ROOT / "assets/xfs/jewel"
COLUMNS = 10


def sheet(frames):
    left = max(-f["hx"] for f in frames)
    top = max(-f["hy"] for f in frames)
    width = left + max(f["w"] + f["hx"] for f in frames)
    height = top + max(f["h"] + f["hy"] for f in frames)
    atlas = Image.new("RGBA", (width * COLUMNS, height * ((len(frames) + COLUMNS - 1) // COLUMNS)))
    for i, frame in enumerate(frames):
        atlas.paste(frame["image"], ((i % COLUMNS) * width + left + frame["hx"],
                                     (i // COLUMNS) * height + top + frame["hy"]))
    return atlas, [width, height], [left, top]


def import_assets(archive=ARCHIVE, output=OUT):
    archive, output = Path(archive), Path(output)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != ARCHIVE_SHA:
        raise ValueError("SHA256 mismatch: graphics.xfs")
    toc = {e["name"]: e for e in xfs.read_toc(archive)}
    entries = {"room_jewel": ("b_ready_jewel.img", None)}
    for kind in range(1, 5):
        for suffix in ["", "l"]:
            entries[f"jewel{kind}{suffix}"] = (f"jewel{kind}{suffix}.img", f"jewel{kind}.epa")
        entries[f"jflame{kind}"] = (f"jflame{kind}.img", f"jflame{kind}.epa")
    catalog = {"schema": 1, "source_sha256": ARCHIVE_SHA, "columns": COLUMNS, "sheets": {}}
    entries["score_digits"] = ("numfont.img", None)
    payloads = {}
    for name, (image, epa) in entries.items():
        raw = xfs.read_entry(archive, toc[image])
        frames = xfs.frames(raw)
        native_frames = list(range(189, 200)) if name == "score_digits" else None
        if native_frames is not None:
            frames = [frames[i] for i in native_frames]
        atlas, cell, origin = sheet(frames)
        states = xfs.parse_epa(xfs.read_entry(archive, toc[epa]))[0] if epa else []
        catalog["sheets"][name] = {"entry": image, "entry_sha256": hashlib.sha256(raw).hexdigest(),
                                   "cell": cell, "origin": origin, "frames": len(frames), "epa": states}
        if native_frames is not None:
            catalog["sheets"][name]["native_frames"] = native_frames
        payloads[name] = atlas
    output.mkdir(parents=True, exist_ok=True)
    for name, image in payloads.items():
        image.save(output / (name + ".png"))
    (output / "catalog.json").write_text(json.dumps(catalog, indent=1, sort_keys=True) + "\n")
    return catalog


if __name__ == "__main__":
    catalog = import_assets()
    print("JEWEL original sheets:", len(catalog["sheets"]))
