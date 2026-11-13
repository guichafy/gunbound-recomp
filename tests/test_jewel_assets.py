"""Independent frame/EPA oracle from the pinned Thor archive, not importer output."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import gunbound_xfs as xfs

ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"
SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
FOLDER = ROOT / "assets/xfs/jewel"


class JewelAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() != SHA:
            raise ValueError("Unexpected source archive")
        cls.toc = {e["name"]: e for e in xfs.read_toc(ARCHIVE)}

    def test_all_frames_and_registration_match_source(self):
        catalog = json.loads((FOLDER / "catalog.json").read_text())
        self.assertEqual(catalog["source_sha256"], SHA)
        for kind in range(1, 5):
            for suffix in ["", "l"]:
                name = f"jewel{kind}{suffix}"
                entry = name + ".img"
                raw = xfs.read_entry(ARCHIVE, self.toc[entry])
                frames = xfs.frames(raw)
                info = catalog["sheets"][name]
                self.assertEqual(info["entry_sha256"], hashlib.sha256(raw).hexdigest())
                self.assertEqual(info["frames"], len(frames))
                atlas = Image.open(FOLDER / (name + ".png")).convert("RGBA")
                width, height = info["cell"]
                ox, oy = info["origin"]
                for i, frame in enumerate(frames):
                    x = (i % catalog["columns"]) * width + ox + frame["hx"]
                    y = (i // catalog["columns"]) * height + oy + frame["hy"]
                    crop = atlas.crop((x, y, x + frame["w"], y + frame["h"]))
                    self.assertEqual(crop.tobytes(), frame["image"].tobytes(), f"{entry}:{i}")

    def test_epa_and_room_control_are_native(self):
        catalog = json.loads((FOLDER / "catalog.json").read_text())
        for kind in range(1, 5):
            states, _ = xfs.parse_epa(xfs.read_entry(ARCHIVE, self.toc[f"jewel{kind}.epa"]))
            self.assertEqual(catalog["sheets"][f"jewel{kind}"]["epa"], states)
            self.assertEqual([s["name"] for s in states], ["normal", "drop", "shock", "damage", "say"])
        native = xfs.frames(xfs.read_entry(ARCHIVE, self.toc["b_ready_jewel.img"]))
        info = catalog["sheets"]["room_jewel"]
        self.assertEqual(info["frames"], len(native))

    def test_score_digits_match_native_189_to_199(self):
        catalog = json.loads((FOLDER / "catalog.json").read_text())
        info = catalog["sheets"]["score_digits"]
        self.assertEqual(info["native_frames"], list(range(189, 200)))
        frames = xfs.frames(xfs.read_entry(ARCHIVE, self.toc["numfont.img"]))
        atlas = Image.open(FOLDER / "score_digits.png").convert("RGBA")
        w, h = info["cell"]
        ox, oy = info["origin"]
        for i, native in enumerate(info["native_frames"]):
            frame = frames[native]
            x = (i % catalog["columns"]) * w + ox + frame["hx"]
            y = (i // catalog["columns"]) * h + oy + frame["hy"]
            self.assertEqual(atlas.crop((x, y, x+frame["w"], y+frame["h"])).tobytes(), frame["image"].tobytes())

    def test_import_rejects_other_archive_before_writing(self):
        import import_jewel_assets
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "wrong.xfs"
            source.write_bytes(b"not Thor")
            target = Path(tmp) / "out"
            with self.assertRaisesRegex(ValueError, "SHA"):
                import_jewel_assets.import_assets(source, target)
            self.assertFalse(target.exists())


if __name__ == "__main__":
    unittest.main()
