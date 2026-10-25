"""Independent PE/graphics proof for the delimited Raon port; no runtime import."""
import hashlib
from pathlib import Path
import struct
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import gunbound_xfs as xfs

PE = ROOT / ".tools/mobile-animation-port/GunBound.gme"
ARCHIVE = ROOT / ".tools/gunbound-client/graphics.xfs"
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
