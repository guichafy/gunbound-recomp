"""Independent PE/graphics proof for the delimited Raon port; no runtime import."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import gunbound_xfs as xfs

PE = ROOT / ".tools/mobile-animation-port/GunBound.gme"
ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"
CHARACTER = ROOT / ".tools/battle-execution/shots-research/characterdata.json"
SHA = "4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde"
GRAPHICS_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"


@unittest.skipUnless(PE.exists() and ARCHIVE.exists(), "local original PE/XFS required")
class RaonNativeSource(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pe = PE.read_bytes()
        assert hashlib.sha256(cls.pe).hexdigest() == SHA
        assert hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() == GRAPHICS_SHA
        pe_at = struct.unpack_from("<I", cls.pe, 0x3C)[0]
        count = struct.unpack_from("<H", cls.pe, pe_at + 6)[0]
        optional_size = struct.unpack_from("<H", cls.pe, pe_at + 20)[0]
        cls.base = struct.unpack_from("<I", cls.pe, pe_at + 24 + 28)[0]
        cls.sections = []
        for n in range(count):
            at = pe_at + 24 + optional_size + n * 40
            size, rva, raw_size, raw = struct.unpack_from("<IIII", cls.pe, at + 8)
            cls.sections.append((rva, max(size, raw_size), raw))

    def data(self, va, size):
        rva = va - self.base
        for start, length, raw in self.sections:
            if start <= rva and rva + size <= start + length:
                return self.pe[raw + rva - start:raw + rva - start + size]
        raise AssertionError(f"unmapped VA {va:#x}")

    def test_three_actual_main_action_calls(self):
        for va in (0x49C2DC, 0x49C3FC, 0x49C50D):
            data = self.data(va, 5)
            self.assertEqual(data[0], 0xE8)
            self.assertEqual(va + 5 + struct.unpack_from("<i", data, 1)[0], 0x42BBB0)

    def test_phase_step_before_virtual_tick(self):
        # ADD EAX,40; CDQ; IDIV EDI occurs before CALL[EAX+18].
        self.assertEqual(self.data(0x497762, 6).hex(), "83c02899f7ff")
        self.assertEqual(self.data(0x497772, 3).hex(), "ff5018")
        self.assertEqual(self.data(0x42C295, 6).hex(), "81e301000080")
        self.assertEqual(self.data(0x42C2AF, 12).hex(), "69dbb400000089989c3f0000")

    def test_original_radius_and_integer_geometry(self):
        self.assertEqual(struct.unpack("<ff", self.data(0x5580B8, 8)), (-13.0, 13.0))
        # x/y truncate through the same x87 conversion helper, then SHL8.
        for va in (0x4961DE, 0x49621C):
            data = self.data(va, 5)
            self.assertEqual(data[0], 0xE8)
            self.assertEqual(va + 5 + struct.unpack_from("<i", data, 1)[0], 0x53753C)
        self.assertEqual(self.data(0x496236, 3).hex(), "c1e708")
        self.assertEqual(self.data(0x496263, 3).hex(), "c1e108")

    def test_ss_terminal_call100_precedes_movement(self):
        self.assertEqual(self.data(0x492F6E, 18).hex(), "8b961c440000428bc283f86489961c440000")
        self.assertEqual(self.data(0x492F84, 3).hex(), "ff5020")
        # Protected denominator100 is set by WinMain; flat (100-0)*3/100=3.
        self.assertEqual(self.data(0x40DAA2, 7).hex(), "6a64bfa06a7900")
        self.assertEqual(self.data(0x493148, 12).hex(), "b8640000002bc38d044003f8")

    def call_target(self, va):
        data = self.data(va, 5)
        self.assertEqual(data[0], 0xE8)
        return va + 5 + struct.unpack_from("<i", data, 1)[0]

    def test_s1_spawner_indices_are_0_2_3(self):
        # MOV [ESP+x],imm32 for the single shot; Dual uses 8/10/11.
        self.assertEqual(self.data(0x49C219, 8).hex(), "c744241000000000")
        self.assertEqual(self.data(0x49C350, 8).hex(), "c744241402000000")
        self.assertEqual(self.data(0x49C470, 8).hex(), "c744241403000000")
        self.assertEqual(self.data(0x49C346, 8).hex(), "c74424140a000000")

    def test_s2_ss_native_power_offsets(self):
        # WinMain: PUSH 15; MOV EDI,0x794bf0; CALL protected-int setter.
        self.assertEqual(self.data(0x40D9D2, 7).hex(), "6a0fbff04b7900")
        self.assertEqual(self.call_target(0x40D9D9), 0x40A380)
        # 0x40a5f0 adds, 0x40a6e0 subtracts.
        self.assertEqual(self.data(0x40A659, 2).hex(), "03c1")
        self.assertEqual(self.data(0x40A742, 7).hex(), "2b842458020000")
        # S2 shell A: power 0x7864 + [0x794bf0]; shell B: power - [0x794bf0].
        self.assertEqual(self.data(0x49C5C7, 11).hex(), "68f04b79008dae64780000")
        self.assertEqual(self.call_target(0x49C5E1), 0x40A5F0)
        self.assertEqual(self.data(0x49C73B, 5).hex(), "68f04b7900")
        self.assertEqual(self.call_target(0x49C74F), 0x40A6E0)
        # SS: power + [0x794bf0], then SpawnSuperShot.
        self.assertEqual(self.data(0x49CA1F, 5).hex(), "68f04b7900")
        self.assertEqual(self.data(0x49CA36, 6).hex(), "8d8664780000")
        self.assertEqual(self.call_target(0x49CA3D), 0x40A5F0)
        self.assertEqual(self.call_target(0x49CAF6), 0x42DE70)

    def direct_calls(self, start, end):
        body = self.data(start, end - start)
        targets = set()
        for at in range(len(body) - 4):
            if body[at] == 0xE8:
                targets.add(start + at + 5 + struct.unpack_from("<i", body, at + 1)[0])
        return targets

    def test_mine_shells_skip_mobile_hit_test(self):
        # SimulateShot_Bullet7n_9s_7p_9p vs the common Projectile simulate.
        self.assertNotIn(0x450E10, self.direct_calls(0x49AEB0, 0x49C04F))
        self.assertEqual(self.call_target(0x456649), 0x450E10)
        self.assertEqual(self.call_target(0x456F5F), 0x450E10)

    def test_supermine_direction_is_vx_greater_than_zero(self):
        self.assertEqual(self.data(0x49C064, 6).hex(), "8d8688040000")
        self.assertEqual(self.data(0x49C075, 5).hex(), "85c00f9fc0")

    def test_placed_mine_rules(self):
        # AnimateMine 0x498b60: ground probe y-[0x794bf0]=15, bounce CMP 5,
        # bounds y<-200, dead flag mobile+0xbff7 before the radius test.
        self.assertEqual(self.data(0x498BAB, 5).hex(), "b8f04b7900")
        self.assertEqual(self.data(0x498FE1, 3).hex(), "83f805")
        self.assertEqual(self.data(0x4991FE, 5).hex(), "6838ffffff")
        self.assertEqual(self.data(0x4992AB, 6).hex(), "8d87f7bf0000")
        # Slope 0x4986a0: x±[0xe9ba40]=10, cliff +[0xe55ab8]=20, sample y-15.
        self.assertEqual(self.data(0x498832, 5).hex(), "b840bae900")
        self.assertEqual(self.data(0x498A82, 5).hex(), "b8b85ae500")
        self.assertEqual(self.data(0x40D9BA, 5).hex(), "bf40bae900")
        self.assertEqual(self.data(0x40D9B8, 2).hex(), "6a0a")
        self.assertEqual(self.data(0x40D9EC, 7).hex(), "6a14bfb85ae500")
        # ExplodeMine 0x497ad0 lifts the blast by [0xe9ba40]=10.
        self.assertEqual(self.data(0x497B12, 5).hex(), "b840bae900")
        # The weapon copy writes the radius field 0x3198 from block field 9.
        self.assertEqual(self.data(0x41DC6F, 6).hex(), "81c798310000")
        self.assertEqual(self.data(0x41DC77, 6).hex(), "8d86a0ac0f00")
        # RayonTexture quad 0x4ebbc0: cell from -16..15 x -24..7 around the pivot.
        floats = {va: struct.unpack("<f", self.data(va, 4))[0] for va in (0x557FF0, 0x558028, 0x558030, 0x558038, 0x55803C)}
        self.assertEqual(floats, {0x557FF0: 15.0, 0x558028: -15.0, 0x558030: 7.0, 0x558038: -24.0, 0x55803C: -16.0})

    def test_bullet_afterimage_trail(self):
        # Render 0x4c4e90: alpha = 0xff - (level << 5), then the bullet quad.
        self.assertEqual(self.data(0x4C4E90, 3).hex(), "c0e105")
        self.assertEqual(self.data(0x4C4E94, 7).hex(), "33d280caff2ad1")
        self.assertEqual(self.call_target(0x4C4EAE), 0x4EBDD0)
        # PublishProjectileTrackingState writes level0 at ctx+(slot+0x1a35)*20.
        self.assertEqual(self.data(0x458753, 5).hex(), "05351a0000")
        self.assertEqual(self.data(0x458789, 7).hex(), "899c90280c0200")
        # Bullet cell: 64x64 quad, pivot (48,32), atlas step 0.25.
        floats = {va: struct.unpack("<f", self.data(va, 4))[0] for va in (0x557FF4, 0x557FFC, 0x558000, 0x55802C, 0x558054)}
        self.assertEqual(floats, {0x557FF4: 31.0, 0x557FFC: -48.0, 0x558000: -32.0, 0x55802C: 48.0, 0x558054: 0.25})
        # Entry+0x10 (quad V-flip flag read at 0x4c4e84) is always 0 here.
        self.assertEqual(self.data(0x4587BF, 9).hex(), "33db899c97340c0200")
        # Every Raon bullet class draws through slot3 = 0x458690.
        for vtable in (0x555AA4, 0x5563D0, 0x556424):
            self.assertEqual(struct.unpack("<I", self.data(vtable + 12, 4))[0], 0x458690)

    def test_trail_publication_census(self):
        # ADR-119: slot3 of each bullet class picks trail, facing or a custom draw.
        trail, facing = 0x458690, 0x488880
        census = {
            0x555C34: trail, 0x555DAC: trail, 0x555AC4: trail, 0x5563A8: trail,
            0x5564D0: trail, 0x5565F8: 0x4AE1A0, 0x55631C: trail, 0x555BD0: trail,
            0x555BF0: trail, 0x5561A8: trail, 0x556524: trail, 0x5561C8: trail,
            0x555E88: trail, 0x555D14: trail, 0x556360: trail, 0x556160: trail,
            0x555B18: trail, 0x555F38: trail, 0x555F58: trail, 0x55661C: trail,
            0x55649C: trail, 0x556098: trail, 0x556058: trail, 0x556008: trail,
            0x555E30: trail, 0x5562C8: trail,
            0x556284: facing, 0x55620C: facing, 0x5565AC: facing, 0x555D74: facing,
            0x5560D0: 0x47F1C0, 0x5564F0: 0x4A6840, 0x556680: 0x4B30E0,
            0x556660: 0x4B30E0, 0x555EA8: 0x429800,
        }
        for vtable, slot3 in census.items():
            self.assertEqual(struct.unpack("<I", self.data(vtable + 12, 4))[0], slot3, hex(vtable))
        # Facing flag = 90 < angle < 270, stored where the quad reads its V flip.
        self.assertEqual(self.data(0x4889CA, 5).hex(), "837c24105a")
        self.assertEqual(self.data(0x4889E8, 6).hex(), "81ff0e010000")
        self.assertEqual(self.data(0x488A05, 7).hex(), "898c97340c0200")

    @unittest.skipUnless(CHARACTER.exists(), "local characterdata extraction required")
    def test_mine_trigger_radius_is_eight(self):
        rows = json.loads(CHARACTER.read_text())["rows"]
        raon = rows[6]
        self.assertEqual(raon[57 + 9], 8)
        self.assertEqual(raon[70 + 9], 8)
        self.assertEqual(raon[44 + 9], 100)

    def test_extra_ss_asset_is_absent_in_this_archive(self):
        # The PE names an extra light/flame but this exact package lacks it.
        self.assertEqual(self.data(0x554E94, 9), b"ssflame7\x00")
        names = {entry["name"] for entry in xfs.read_toc(ARCHIVE)}
        self.assertIn("flame73.img", names)
        self.assertIn("flame73.epa", names)
        self.assertNotIn("ssflame7.img", names)
        self.assertNotIn("ssflame7.epa", names)


if __name__ == "__main__":
    unittest.main()
