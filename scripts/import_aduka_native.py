"""Extract Thor IMG/EPA for the Aduka renderer, preserving previous assets."""
import hashlib
import json
from pathlib import Path

import gunbound_xfs as xfs
from import_classic_mobiles import pack

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"
SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"


def main():
    if hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() != SHA:
        raise ValueError("Unexpected source archive")
    toc = {entry["name"]: entry for entry in xfs.read_toc(ARCHIVE)}
    folder = ROOT / "assets/openbound/aduka"
    metadata = {"archive_sha256": SHA, "columns": 14, "sheets": {}}
    for entry, filename in [("thor.img", "ThorBody.png"), ("thorl.img", "ThorLight.png")]:
        raw = xfs.read_entry(ARCHIVE, toc[entry])
        frames = xfs.frames(raw)
        image, cell, origin = pack(frames, 14)
        image.save(folder / filename)
        metadata["sheets"][filename] = {"entry": entry, "entry_sha256": hashlib.sha256(raw).hexdigest(),
            "frames": len(frames), "cell": cell, "origin": origin,
            "image_sha256": hashlib.sha256((folder / filename).read_bytes()).hexdigest()}
    raw = xfs.read_entry(ARCHIVE, toc["thor.epa"])
    states, _ = xfs.parse_epa(raw)
    metadata["epa_sha256"] = hashlib.sha256(raw).hexdigest()
    metadata["states"] = {s["name"]: {"frames": s["frames"], "durations": s["durations"]}
        for s in states if s["name"] in ("normal", "active", "fire")}
    metadata["unusable_states"] = {s["name"]: "EPA references frames beyond this56-frame source"
        for s in states if any(i >= 56 for i in s["frames"])}
    (folder / "thor_native.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print("ADUKA NATIVE ASSETS: thor/thorl56frames, normal20/active20/fire16, native hotspots")


if __name__ == "__main__":
    main()
