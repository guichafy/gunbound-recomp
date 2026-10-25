"""Extract Thor's Hammer rank icons without modifying existing assets.

The login decoder adds4 to the signed rank WORD. rank1/rank2 frame24 is GM20.
Evidence and limits: docs/sdd/LOBBY_UI_RANK.md.
"""
import hashlib
import json
from pathlib import Path

from PIL import Image
import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"
SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"


def main():
    if hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() != SHA:
        raise SystemExit("unexpected graphics.xfs identity")
    toc = {e["name"]: e for e in xfs.read_toc(ARCHIVE)}
    output = ROOT / "assets/classic/ranks"
    output.mkdir(parents=True, exist_ok=True)
    catalog = {"archive_sha256": SHA, "rank_to_frame": "signed_WORD + 4", "gm_code": 20, "sheets": {}}
    for name, size in [("rank1", (15, 25)), ("rank2", (25, 15))]:
        raw = xfs.read_entry(ARCHIVE, toc[name + ".img"])
        frames = xfs.frames(raw)
        if len(frames) != 25 or any(f["image"].size != size for f in frames):
            raise SystemExit("unexpected rank frames")
        sheet = Image.new("RGBA", (size[0] * 25, size[1]))
        for i, frame in enumerate(frames):
            sheet.paste(frame["image"], (i * size[0], 0))
        path = output / (name + ".png")
        sheet.save(path)
        catalog["sheets"][name] = {"entry": name + ".img", "entry_sha256": hashlib.sha256(raw).hexdigest(),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "frame_size": list(size), "frames": 25}
    (output / "catalog.json").write_text(json.dumps(catalog, indent=2) + "\n")
    print("rank1/rank2: 25 native frames each; GM20=frame24")


if __name__ == "__main__":
    main()
