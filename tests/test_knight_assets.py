"""Source oracle for the Knight Ion/child sheets (ADR-152).

Each committed frame is compared, pixel for pixel, with the frame decoded from the
pinned graphics.xfs at its hotspot; states/durations come from the .epa entries."""
import hashlib
import json
from pathlib import Path
import sys
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import gunbound_xfs as xfs

ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"
GRAPHICS_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
FOLDER = ROOT / "assets/openbound/knight"
ENTRIES = {"Ion.png": ("knightion.img", "knightion.epa"), "IonLight.png": ("knightionl.img", "knightion.epa"),
           "Child.png": ("knightbullet.img", "knightbullet.epa"), "ChildLight.png": ("knightbulletl.img", "knightbullet.epa")}


@unittest.skipUnless(ARCHIVE.exists(), "graphics.xfs not in .tools/gunbound-client")
class KnightAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() != GRAPHICS_SHA:
            raise unittest.SkipTest("unexpected graphics.xfs")
        cls.toc = {entry["name"]: entry for entry in xfs.read_toc(str(ARCHIVE))}
        cls.catalog = json.loads((FOLDER / "knight_ion.json").read_text(encoding="utf-8"))

    def test_frames_match_the_archive(self):
        columns = int(self.catalog["columns"])
        for name, (image, epa) in ENTRIES.items():
            info = self.catalog["sheets"][name]
            raw = xfs.read_entry(str(ARCHIVE), self.toc[image])
            self.assertEqual(info["entry"], image)
            self.assertEqual(info["entry_sha256"], hashlib.sha256(raw).hexdigest())
            frames = xfs.frames(raw)
            self.assertEqual(info["frames"], len(frames))
            atlas = Image.open(FOLDER / name).convert("RGBA")
            width, height = info["cell"]
            left, top = info["origin"]
            for index, frame in enumerate(frames):
                x = (index % columns) * width + left + frame["hx"]
                y = (index // columns) * height + top + frame["hy"]
                crop = atlas.crop((x, y, x + frame["w"], y + frame["h"]))
                self.assertEqual(crop.tobytes(), frame["image"].tobytes(), "%s frame %d" % (name, index))
            states, _ = xfs.parse_epa(xfs.read_entry(str(ARCHIVE), self.toc[epa]))
            self.assertEqual(info["states"], {state["name"]: state["frames"] for state in states})
            self.assertEqual(info["durations"], {state["name"]: state["durations"] for state in states})

    def test_ion_states(self):
        ion = self.catalog["sheets"]["Ion.png"]["states"]
        self.assertEqual(sorted(ion), ["fire1", "fire2", "move", "normal"])
        self.assertEqual(ion["fire1"], list(range(20, 40)))
        # The client light has fewer frames than the body: later cells are skipped.
        self.assertEqual(self.catalog["sheets"]["IonLight.png"]["frames"], 15)

    def test_ss_guide_light_equals_body(self):
        # bullet15p and bullet15pl differ only in the frame header; the pixels match.
        body = xfs.frames(xfs.read_entry(str(ARCHIVE), self.toc["bullet15p.img"]))
        light = xfs.frames(xfs.read_entry(str(ARCHIVE), self.toc["bullet15pl.img"]))
        self.assertEqual([f["image"].tobytes() for f in body], [f["image"].tobytes() for f in light])


if __name__ == "__main__":
    unittest.main()
