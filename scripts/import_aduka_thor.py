"""Extract Aduka's original beam texture; preserve all existing mobile assets.

PE0x4c45e4 selects LaserEffect, shared with Mage. 0x4c4657..469e selects
u=(tick%8)/16..u+1/16 and v=1..0 over the complete beam length.
"""
import hashlib
import json
import struct
from pathlib import Path

from PIL import Image

import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"
ARCHIVE_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"


def main():
    if hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() != ARCHIVE_SHA:
        raise ValueError("graphics.xfs identity differs from the evidenced client")
    toc = {entry["name"]: entry for entry in xfs.read_toc(ARCHIVE)}
    raw = xfs.read_entry(ARCHIVE, toc["LaserEffect.xtf"])
    width, height, kind = struct.unpack_from("<IIB", raw)
    if (width, height, kind, len(raw)) != (256, 256, 1, 131081):
        raise ValueError("unexpected native LaserEffect format")
    texture = Image.new("RGBA", (width, height))
    texture.putdata([xfs._argb4444(pixel) for pixel, in struct.iter_unpack("<H", raw[9:])])
    folder = ROOT / "assets/openbound/aduka"
    folder.mkdir(parents=True, exist_ok=True)
    image_path = folder / "ThorEffect.png"
    texture.save(image_path)
    metadata = {
        "version": 1,
        "archive": "graphics.xfs",
        "archive_sha256": ARCHIVE_SHA,
        "entry": "LaserEffect.xtf",
        "entry_sha256": hashlib.sha256(raw).hexdigest(),
        "image": "ThorEffect.png",
        "image_sha256": hashlib.sha256(image_path.read_bytes()).hexdigest(),
        "size": [width, height],
        "format": "ARGB4444 -> RGBA8888, channel *17, unchanged pixels",
        "pe_sha256": "4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde",
        "consumer": "0x4c45e4..0x4c46f3",
        "columns": 16,
        "used_columns": 8,
        "rows": 1,
        "uv": {"u0": "tick%8 /16", "u1": "(tick%8+1)/16", "v0": 1, "v1": 0},
        "blend": "native additive SRCALPHA/ONE (render states 19=5,20=2)",
        "notes": "ThorTexture1/2 are not the beam selected by this consumer. Texture is shared with Mage; existing assets preserved.",
    }
    (folder / "thor_effect.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(json.dumps({"image": str(image_path.relative_to(ROOT)), "sha256": metadata["image_sha256"]}))


if __name__ == "__main__":
    main()
