"""Independent source oracle: exported sprites retain native XFS pixels/hotspots."""
import hashlib
import json
from pathlib import Path
import sys
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import gunbound_xfs as xfs


class OriginalMobileAssets(unittest.TestCase):
    def test_pixels_and_registration(self):
        archive = ROOT / ".tools/gunbound-client/graphics.xfs"
        if not archive.exists():
            self.skipTest("Native archive is local; runtime resource checks run separately")
        self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(),
                         "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08")
        toc = {e["name"]: e for e in xfs.read_toc(archive)}
        for kind, number in [("mage", 2), ("bigfoot", 5)]:
            folder = ROOT / f"assets/openbound/{kind}/original"
            meta = json.loads((folder / "frames.json").read_text())
            states, _ = xfs.parse_epa(xfs.read_entry(archive, toc[f"tank{number}.epa"]))
            self.assertEqual(meta["poses"]["recoil_1"], next(s["frames"] for s in states if s["name"] == "fire2"))
            self.assertEqual(meta["pose_durations"]["recoil_1"], next(s["durations"] for s in states if s["name"] == "fire2"))
            sheets = {"CharacterSpritesheet.png": {"entry": f"tank{number}.img", **{k: meta[k] for k in ["cell", "origin", "columns"]}}, **meta["sheets"]}
            for name, info in sheets.items():
                raw = xfs.read_entry(archive, toc[info["entry"]])
                if "entry_sha256" in info:
                    self.assertEqual(hashlib.sha256(raw).hexdigest(), info["entry_sha256"])
                image = Image.open(folder / name).convert("RGBA")
                for index, frame in enumerate(xfs.frames(raw)):
                    left = (index % info["columns"]) * info["cell"][0] + info["origin"][0] + frame["hx"]
                    top = (index // info["columns"]) * info["cell"][1] + info["origin"][1] + frame["hy"]
                    exported = image.crop((left, top, left + frame["w"], top + frame["h"]))
                    self.assertEqual(exported.tobytes(), frame["image"].convert("RGBA").tobytes(), f"{kind}/{name} frame {index}")
                    if name == "CharacterSpritesheet.png":
                        self.assertEqual(meta["rider"][index], [frame["hx"]+frame["extra"][2], frame["hy"]+frame["extra"][3]])


    def test_native_laser_pixels(self):
        archive = ROOT / ".tools/gunbound-client/graphics.xfs"
        if not archive.exists():
            self.skipTest("Native archive is local")
        import struct
        toc = {e["name"]: e for e in xfs.read_toc(archive)}
        raw = xfs.read_entry(archive, toc["LaserEffect.xtf"])
        width, height, fmt = struct.unpack_from("<IIB", raw)
        self.assertEqual((width,height,fmt),(256,256,1))
        actual = Image.open(ROOT / "assets/openbound/mage/original/LaserEffect.png").convert("RGBA")
        expected = bytes(channel for (value,) in struct.iter_unpack("<H", raw[9:]) for channel in [((value>>8)&15)*17,((value>>4)&15)*17,(value&15)*17,((value>>12)&15)*17])
        self.assertEqual(actual.tobytes(), expected)


if __name__ == "__main__":
    unittest.main()
