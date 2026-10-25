"""Independent original-pixel and UV checks for Aduka's beam texture."""
import hashlib
import json
import struct
import sys
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import gunbound_xfs as xfs


class AdukaThorAssets(unittest.TestCase):
    def test_texture_is_the_original_argb4444_image(self):
        archive = ROOT / ".tools/gunbound-client/graphics.xfs"
        entry = next(row for row in xfs.read_toc(archive) if row["name"] == "LaserEffect.xtf")
        original = xfs.read_entry(archive, entry)
        self.assertEqual(struct.unpack_from("<IIB", original), (256, 256, 1))
        image = Image.open(ROOT / "assets/openbound/aduka/ThorEffect.png").convert("RGBA")
        self.assertEqual(image.size, (256, 256))
        # Read packed channels directly, independently of the importer's helper.
        for native, pixel in zip(struct.iter_unpack("<H", original[9:]), image.getdata()):
            word = native[0]
            self.assertEqual(pixel, tuple(((word >> bit) & 15) * 17 for bit in (8, 4, 0, 12)))

    def test_manifest_has_the_evidenced_resource_and_uv(self):
        folder = ROOT / "assets/openbound/aduka"
        metadata = json.loads((folder / "thor_effect.json").read_text())
        self.assertEqual(metadata["entry"], "LaserEffect.xtf")
        self.assertEqual(metadata["image_sha256"], hashlib.sha256((folder / "ThorEffect.png").read_bytes()).hexdigest())
        self.assertEqual((metadata["columns"], metadata["used_columns"], metadata["rows"]), (16, 8, 1))
        self.assertEqual(metadata["uv"], {"u0": "tick%8 /16", "u1": "(tick%8+1)/16", "v0": 1, "v1": 0})


if __name__ == "__main__":
    unittest.main()
