"""Aduka asset/dispatch oracle: original PE and XFS, not runtime getters."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import unittest
import wave

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import gunbound_xfs as xfs

FOLDER = ROOT / "assets/openbound/aduka"
PE = ROOT / ".tools/mobile-animation-port/GunBound.gme"
ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"


class AdukaAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.binary = PE.read_bytes()
        assert hashlib.sha256(cls.binary).hexdigest() == "4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde"
        assert hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() == "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
        cls.toc = {e["name"]: e for e in xfs.read_toc(ARCHIVE)}
        at = struct.unpack_from("<I", cls.binary, 0x3c)[0]
        count = struct.unpack_from("<H", cls.binary, at + 6)[0]
        optional = struct.unpack_from("<H", cls.binary, at + 20)[0]
        cls.base = struct.unpack_from("<I", cls.binary, at + 52)[0]
        cls.sections = [struct.unpack_from("<IIII", cls.binary, at+24+optional+i*40+8) for i in range(count)]

    def read(self, va, size):
        rva = va-self.base
        for length, start, raw_size, raw in self.sections:
            if start <= rva and rva+size <= start+max(length, raw_size):
                return self.binary[raw+rva-start:raw+rva-start+size]
        self.fail(f"Unmapped VA {va:#x}")

    def test_main_action_calls_and_render_dispatch(self):
        for target, sites in [(0x42bbb0, [0x467175, 0x4672e1, 0x467491]),
                              (0x42de70, [0x467702, 0x467886, 0x467979])]:
            for va in sites:
                raw = self.read(va, 5)
                self.assertEqual(raw[0], 0xe8)
                self.assertEqual(va+5+struct.unpack_from("<i", raw, 1)[0], target)
        self.assertEqual(struct.unpack("<I", self.read(0x5565ac+12, 4))[0], 0x488880)
        self.assertEqual(struct.unpack("<I", self.read(0x555d74+12, 4))[0], 0x488880)
        self.assertEqual(struct.unpack("<I", self.read(0x555e88+12, 4))[0], 0x458690)
        self.assertEqual(self.read(0x4c4f7f, 4), bytes.fromhex("6a056a13"))
        self.assertEqual(self.read(0x4c4f9a, 3), bytes.fromhex("536a14"))

    def test_native_combat_catalog_and_luts(self):
        catalog = json.loads((FOLDER / "combat_native.json").read_text())
        rows = json.loads((ROOT / ".tools/battle-execution/shots-research/characterdata.json").read_text())["rows"]
        for body in catalog["bodies"].values():
            row = rows[body["source_type"]]
            self.assertEqual([body[k] for k in ["width", "height", "bottom", "vulnerability", "flags"]],
                             [row[i] for i in [0, 1, 2, 21, 35]])
        self.assertEqual(catalog["t1"], dict(power=152, dimension=64, aspect=120, flags=70))
        for name, va, count in [("y", 0x5a960c, 6), ("x_large", 0x5a9624, 7), ("x_small", 0x5a9640, 7)]:
            self.assertEqual(catalog["tilt"][name], list(struct.unpack("<" + "i" * count, self.read(va, count * 4))))

    def test_native_damage_and_tornado_operations(self):
        # Source operators, not constants read back from the GDScript port.
        self.assertEqual(self.read(0x45e059, 2), bytes.fromhex("d9fa"))  # FSQRT
        self.assertEqual(struct.unpack("<d", self.read(0x558078, 8))[0], 1000.0)
        self.assertEqual(self.read(0x45df6b, 2), bytes.fromhex("0f8d"))  # JGE: strict radius
        self.assertEqual(self.read(0x4ab6b9, 5), bytes.fromhex("3dc8000000"))  # |vx| minimum200 FP
        self.assertEqual(self.read(0x4ab85b, 1), bytes.fromhex("41"))  # INC crossing count
        self.assertEqual(self.read(0x4ab860, 6), bytes.fromhex("898e500f0000"))
        # Only the no-tornado branch adds both accelerations (+af4/+d18).
        self.assertEqual(self.read(0x4ab8b7, 6), bytes.fromhex("8d96f40a0000"))
        self.assertEqual(self.read(0x4ab8c9, 6), bytes.fromhex("8d86180d0000"))

    def compare_sheet(self, filename, info, columns):
        raw = xfs.read_entry(ARCHIVE, self.toc[info["entry"]])
        self.assertEqual(hashlib.sha256(raw).hexdigest(), info["entry_sha256"])
        source = xfs.frames(raw)
        image = Image.open(FOLDER / filename).convert("RGBA")
        w, h = info["cell"]
        ox, oy = info["origin"]
        for index, frame in enumerate(source):
            expected = Image.new("RGBA", (w, h))
            expected.paste(frame["image"], (ox+frame["hx"], oy+frame["hy"]))
            x, y = index % columns*w, index // columns*h
            self.assertEqual(image.crop((x, y, x+w, y+h)).tobytes(), expected.tobytes(), (filename, index))
        return source

    def test_all_mobile_frames_pivots_and_epa(self):
        metadata = json.loads((FOLDER / "frames.json").read_text())
        raw = xfs.read_entry(ARCHIVE, self.toc["tank16.img"])
        source = xfs.frames(raw)
        self.compare_sheet("CharacterSpritesheet.png", {"entry":"tank16.img", "entry_sha256":hashlib.sha256(raw).hexdigest(),
            "cell":metadata["cell"], "origin":metadata["origin"]}, 20)
        self.assertEqual(json.loads((FOLDER / "RiderPivot.json").read_text()),
            [[f["hx"]+f["extra"][2], f["hy"]+f["extra"][3]] for f in source])
        states, _ = xfs.parse_epa(xfs.read_entry(ARCHIVE, self.toc["tank16.epa"]))
        by_name = {s["name"]:s for s in states}
        for pose, native in [("idle","normal"),("moving","move"),("recoil_0","fire1"),
                             ("recoil_1","fire2"),("recoil_2","sfire"),("charging_1","bfire2")]:
            self.assertEqual(metadata["poses"][pose], by_name[native]["frames"])
            self.assertEqual(metadata["pose_durations"][pose], by_name[native]["durations"])

    def test_all_projectile_and_impact_pixels(self):
        metadata = json.loads((FOLDER / "frames.json").read_text())
        for filename, info in metadata["sheets"].items():
            self.compare_sheet(filename, info, info["columns"])
        self.assertNotIn("bullet16s.img", self.toc)
        self.assertEqual(metadata["sheets"]["Bullet2.png"]["entry"], "bullet16sl.img")
        self.assertNotIn("Flame2.png", metadata["sheets"])
        self.assertNotIn("Flame3.png", metadata["sheets"])

    def test_thor_body_light_and_native_epa(self):
        path = FOLDER / "thor_native.json"
        self.assertTrue(path.exists())
        if not path.exists(): return
        metadata = json.loads(path.read_text())
        for filename, info in metadata["sheets"].items():
            self.compare_sheet(filename, info, metadata["columns"])
        states, _ = xfs.parse_epa(xfs.read_entry(ARCHIVE, self.toc["thor.epa"]))
        for state in states:
            if state["name"] in ("normal", "active", "fire"):
                self.assertEqual(metadata["states"][state["name"]], {"frames":state["frames"], "durations":state["durations"]})

    def test_original_thor_impact_pcm(self):
        sound = ROOT / ".tools/gunbound-client/sound.xfs"
        toc = {e["name"]:e for e in xfs.read_toc(sound)}
        native = xfs.read_entry(sound, toc["22blast.xes"])
        with wave.open(str(ROOT / "assets/openbound/classic/22blast.wav"), "rb") as audio:
            channels, bits, rate = audio.getnchannels(), audio.getsampwidth()*8, audio.getframerate()
            align = channels*bits//8
            actual = struct.pack("<HHIIHH", 1, channels, rate, rate*align, align, bits)+audio.readframes(audio.getnframes())
        self.assertEqual(actual, native)
        self.assertNotIn("23blast.xes", toc)


if __name__ == "__main__":
    unittest.main()
