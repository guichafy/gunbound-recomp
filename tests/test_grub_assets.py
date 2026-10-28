"""Independent source oracle for the Grub (client type 12 / tank13) art, EPA and sound.

Everything is recomputed from the pinned graphics.xfs / sound.xfs and compared with the
exported frames, the per-shot timing and the audio catalog (issue #8)."""
import hashlib
import json
import os
from pathlib import Path
import struct
import sys
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import gunbound_xfs as xfs

GRAPHICS_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
SOUND_SHA = "081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023"
PE = ROOT / ".tools/mobile-animation-port/GunBound.gme"
PE_SHA = "4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde"


def find_sound_xfs():
    """sound.xfs sits in the launcher checkout next to this one (../GunboundClassic/...); a
    worktree is deeper, so look beside every ancestor. GUNBOUND_SOUND_XFS overrides."""
    override = os.environ.get("GUNBOUND_SOUND_XFS")
    candidates = [Path(override)] if override else [ROOT / ".tools/gunbound-client/sound.xfs"]
    candidates += [p.parent / "GunboundClassic/gunbound-launcher/TestClient/sound.xfs" for p in [ROOT, *ROOT.parents]]
    return next((c for c in candidates if c.exists()), None)


def pe_string_at(table: int, index: int) -> str:
    """Pointer table of the client (one char* per type), read from the PE file."""
    data = PE.read_bytes()
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    sections, optional = struct.unpack_from("<H", data, pe + 6)[0], struct.unpack_from("<H", data, pe + 20)[0]
    base = struct.unpack_from("<I", data, pe + 24 + 28)[0]

    def read(va: int, size: int) -> bytes:
        rva = va - base
        for i in range(sections):
            o = pe + 24 + optional + i * 40
            vsize, vaddr, rsize, roff = struct.unpack_from("<IIII", data, o + 8)
            if vaddr <= rva < vaddr + max(vsize, rsize):
                return data[roff + rva - vaddr: roff + rva - vaddr + size]
        raise KeyError(hex(va))

    pointer = struct.unpack("<I", read(table + 4 * index, 4))[0]
    return read(pointer, 40).split(b"\0")[0].decode("latin1")
GRAPHICS = ROOT / ".tools/gunbound-client/graphics.xfs"
GRUB = ROOT / "assets/openbound/grub"
# slot -> (pose state, projectile entry, light entry, impact, secondary impact, fire sound, blast sound)
SHOTS = {
    0: ("fire1", "bullet13n", "bullet13nl", "flame131", None, "131fire", "132blast"),
    1: ("fire2", "bullet13s", "bullet13sl", "flame132", None, "131fire", "132blast"),
    2: ("sfire", "bullet13p", None, "flame133", "ssflame13", "131fire", "11blast"),
}


class GrubAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GRAPHICS.exists():
            raise unittest.SkipTest("Native archive is local")
        assert hashlib.sha256(GRAPHICS.read_bytes()).hexdigest() == GRAPHICS_SHA
        cls.toc = {e["name"]: e for e in xfs.read_toc(GRAPHICS)}
        cls.states, _ = xfs.parse_epa(xfs.read_entry(GRAPHICS, cls.toc["tank13.epa"]))
        cls.timing = [r for r in json.loads((ROOT / "assets/openbound/classic/shot_timing.json").read_text())["records"] if r["game_id"] == 13]

    def test_entries_are_in_the_archive(self):
        for _pose, body, light, impact, secondary, _, _ in SHOTS.values():
            for name in [body, impact, secondary]:
                if name:
                    self.assertIn(name + ".img", self.toc, name)
                    self.assertIn(name + ".epa", self.toc, name)
            if light:
                self.assertIn(light + ".img", self.toc, light)
        for name in ["tank13.img", "tank13.epa", "tank13l.img"]:
            self.assertIn(name, self.toc)

    def test_hull_pixels_and_registration(self):
        meta = json.loads((GRUB / "frames.json").read_text())
        raw = xfs.read_entry(GRAPHICS, self.toc["tank13.img"])
        image = Image.open(GRUB / "CharacterSpritesheet.png").convert("RGBA")
        cell, origin = meta["cell"], meta["origin"]
        frames = xfs.frames(raw)
        self.assertGreater(len(frames), 300)
        for index, frame in enumerate(frames):
            left = (index % meta["columns"]) * cell[0] + origin[0] + frame["hx"]
            top = (index // meta["columns"]) * cell[1] + origin[1] + frame["hy"]
            crop = image.crop((left, top, left + frame["w"], top + frame["h"]))
            self.assertEqual(crop.tobytes(), frame["image"].convert("RGBA").tobytes(), f"hull frame {index}")
            self.assertEqual(meta["rider"][index], [frame["hx"] + frame["extra"][2], frame["hy"] + frame["extra"][3]], f"rider pivot {index}")

    def test_hull_light_pixels_and_registration(self):
        meta = json.loads((GRUB / "frames.json").read_text())
        light_meta = meta["hull_light"]
        raw = xfs.read_entry(GRAPHICS, self.toc["tank13l.img"])
        self.assertEqual(hashlib.sha256(raw).hexdigest(), light_meta["entry_sha256"])
        image = Image.open(GRUB / "CharacterSpritesheetLight.png").convert("RGBA")
        cell, origin = light_meta["cell"], light_meta["origin"]
        frames = xfs.frames(raw)
        self.assertEqual(len(frames), light_meta["frames"])
        self.assertEqual(len(frames), len(xfs.frames(xfs.read_entry(GRAPHICS, self.toc["tank13.img"]))))
        for index, frame in enumerate(frames):
            left = (index % light_meta["columns"]) * cell[0] + origin[0] + frame["hx"]
            top = (index // light_meta["columns"]) * cell[1] + origin[1] + frame["hy"]
            crop = image.crop((left, top, left + frame["w"], top + frame["h"]))
            self.assertEqual(crop.tobytes(), frame["image"].convert("RGBA").tobytes(), f"hull light frame {index}")

    def test_projectile_sheets_and_epa(self):
        meta = json.loads((GRUB / "frames.json").read_text())
        for name, info in meta["sheets"].items():
            raw = xfs.read_entry(GRAPHICS, self.toc[info["entry"]])
            if "entry_sha256" in info:
                self.assertEqual(hashlib.sha256(raw).hexdigest(), info["entry_sha256"], name)
            image = Image.open(GRUB / name).convert("RGBA")
            for index, frame in enumerate(xfs.frames(raw)):
                left = (index % info["columns"]) * info["cell"][0] + info["origin"][0] + frame["hx"]
                top = (index // info["columns"]) * info["cell"][1] + info["origin"][1] + frame["hy"]
                crop = image.crop((left, top, left + frame["w"], top + frame["h"]))
                self.assertEqual(crop.tobytes(), frame["image"].convert("RGBA").tobytes(), f"{name} frame {index}")

    def test_pose_frames_durations_and_spawn_tick(self):
        by_name = {s["name"]: s for s in self.states}
        for weapon, (pose, *_rest) in SHOTS.items():
            record = next(r for r in self.timing if r["weapon"] == weapon)
            self.assertEqual(record["pose_state"], pose)
            self.assertEqual(record["pose_frames"], by_name[pose]["frames"])
            self.assertEqual(record["pose_durations"], by_name[pose]["durations"])
            self.assertEqual(record["pose_ticks"], sum(by_name[pose]["durations"]))
            self.assertEqual(record["spawn_ticks"], [2], "MainAction spawns at frame 2 (0x471fd0)")
            self.assertEqual(record["components_per_spawn"], [4 if weapon == 1 else 1])

    def test_sound_tables_of_the_pe(self):
        if not PE.exists() or hashlib.sha256(PE.read_bytes()).hexdigest() != PE_SHA:
            self.skipTest("pinned GunBound.gme is local")
        # Fire tables S1/S2/SS and blast tables S1/S2/SS at type 12 (client index 12).
        self.assertEqual([pe_string_at(t, 12) for t in (0x56D1D0, 0x56D210, 0x56D250)], ["131fire.xes"] * 3)
        self.assertEqual([pe_string_at(t, 12) for t in (0x56D290, 0x56D2D0, 0x56D310)], ["132blast.xes", "132blast.xes", "11blast.xes"])
        for weapon, (_p, _b, _l, _i, _s, fire, blast) in SHOTS.items():
            self.assertEqual(pe_string_at([0x56D1D0, 0x56D210, 0x56D250][weapon], 12), fire + ".xes")
            self.assertEqual(pe_string_at([0x56D290, 0x56D2D0, 0x56D310][weapon], 12), blast + ".xes")

    def test_no_client_crosshair_for_tank13(self):
        # The inherited CrosshairGrub* stay: graphics.xfs has no crosshair piece to replace them.
        self.assertEqual([n for n in self.toc if "cross" in n.lower()], [])
        self.assertTrue([p for p in (ROOT / "assets/openbound/hud").glob("CrosshairGrub*.png")])

    def test_sounds_exist_in_sound_xfs(self):
        sound = find_sound_xfs()
        if sound is None:
            self.skipTest("sound.xfs is local (set GUNBOUND_SOUND_XFS)")
        self.assertEqual(hashlib.sha256(sound.read_bytes()).hexdigest(), SOUND_SHA)
        toc = {e["name"]: e for e in xfs.read_toc(sound)}
        catalog = {r["entry"]: r for r in json.loads((ROOT / "assets/xfs/audio/catalog.json").read_text())["records"]}
        for _pose, _b, _l, _i, _s, fire, blast in SHOTS.values():
            for name in (fire + ".xes", blast + ".xes"):
                self.assertIn(name, toc)
                self.assertEqual(hashlib.sha256(xfs.read_entry(sound, toc[name])).hexdigest(), catalog[name]["entry_sha256"], name)
        for weapon, (_p, _b, _l, _i, _s, fire, blast) in SHOTS.items():
            record = next(r for r in self.timing if r["weapon"] == weapon)
            self.assertEqual(record["sounds"]["fire"]["entry"], fire + ".xes")
            self.assertEqual(record["sounds"]["blast"]["entry"], blast + ".xes")


if __name__ == "__main__":
    unittest.main()
