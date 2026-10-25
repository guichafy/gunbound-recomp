"""Observable contracts: malformed candidates must never receive technical approval."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/validate_restoration.py"


class RestorationValidationTests(unittest.TestCase):
    def test_report_cannot_overwrite_inputs_or_existing_files(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source.png"
            candidate = Path(directory) / "candidate.png"
            existing = Path(directory) / "existing.json"
            Image.new("RGBA", (2, 1), "red").save(source)
            Image.new("RGBA", (8, 4), "red").save(candidate)
            existing.write_bytes(b"previous report")
            before = {path: path.read_bytes() for path in [source, candidate, existing]}
            for target in [source, candidate, existing]:
                with self.subTest(target=target.name):
                    for path, contents in before.items():
                        path.write_bytes(contents)
                    result = subprocess.run([sys.executable, str(SCRIPT), str(source), str(candidate), "--report", str(target)], capture_output=True, text=True)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(target.read_bytes(), before[target])

    def run_case(self, source, candidate, *args):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source.save(root / "source.png")
            candidate.save(root / "candidate.png")
            result = subprocess.run(
                [sys.executable, str(SCRIPT), str(root / "source.png"),
                 str(root / "candidate.png"), *args],
                capture_output=True, text=True, check=False,
            )
            self.assertIn(result.returncode, (0, 1), result.stderr)
            return result.returncode, json.loads(result.stdout)

    def test_exact_pixels_still_require_visual_review(self):
        source = Image.new("RGBA", (8, 4), (20, 50, 90, 255))
        code, report = self.run_case(source, source.resize((32, 16)), "--columns", "2")
        self.assertEqual(code, 0)
        self.assertEqual(report["status"], "pending_visual_review")
        self.assertEqual(len(report["cells"]), 2)
        self.assertEqual(report["cells"][0]["visible_rgb_mae"], 0)

    def test_wrong_size_and_aspect_are_rejected(self):
        source = Image.new("RGB", (8, 4), "red")
        code, report = self.run_case(source, Image.new("RGB", (32, 20), "red"))
        self.assertEqual(code, 1)
        self.assertIn("dimensions", report["failures"])
        self.assertIn("aspect_ratio", report["failures"])
        self.assertIsNone(report["cells"])

    def test_opaque_source_cannot_gain_transparency(self):
        source = Image.new("RGBA", (8, 4), "red")
        candidate = source.resize((32, 16))
        candidate.putpixel((0, 0), (255, 0, 0, 254))
        code, report = self.run_case(source, candidate)
        self.assertEqual(code, 1)
        self.assertIn("opaque_alpha_changed", report["failures"])

    def test_transparent_hole_cannot_be_filled(self):
        source = Image.new("RGBA", (8, 4), "red")
        source.putpixel((2, 1), (0, 0, 0, 0))
        code, report = self.run_case(source, Image.new("RGBA", (32, 16), "red"))
        self.assertEqual(code, 1)
        self.assertIn("alpha_support_changed", report["failures"])
        self.assertEqual(report["cells"][0]["alpha_support_changed_pixels"], 16)

    def test_hidden_rgb_is_not_a_visible_difference(self):
        source = Image.new("RGBA", (8, 4), (0, 0, 0, 0))
        candidate = Image.new("RGBA", (32, 16), (255, 0, 255, 0))
        code, report = self.run_case(source, candidate)
        self.assertEqual(code, 0)
        self.assertEqual(report["cells"][0]["visible_rgb_mae"], 0)

    def test_partial_alpha_cannot_turn_opaque(self):
        source = Image.new("RGBA", (8, 4), (80, 90, 100, 128))
        candidate = Image.new("RGBA", (32, 16), (80, 90, 100, 255))
        code, report = self.run_case(source, candidate)
        self.assertEqual(code, 1)
        self.assertIn("alpha_values_changed", report["failures"])

    def test_faint_halo_below_support_threshold_is_rejected(self):
        source = Image.new("RGBA", (8, 4), (0, 0, 0, 0))
        candidate = Image.new("RGBA", (32, 16), (255, 255, 255, 8))
        code, report = self.run_case(source, candidate)
        self.assertEqual(code, 1)
        self.assertIn("alpha_values_changed", report["failures"])

    def test_invalid_grid_is_rejected(self):
        source = Image.new("RGB", (8, 4), "red")
        code, report = self.run_case(source, source.resize((32, 16)), "--columns", "3")
        self.assertEqual(code, 1)
        self.assertIn("source_grid", report["failures"])

    def test_swapped_states_are_visible_in_cell_measurements(self):
        source = Image.new("RGB", (8, 4), "red")
        source.paste("blue", (4, 0, 8, 4))
        candidate = Image.new("RGB", (32, 16), "blue")
        candidate.paste("red", (16, 0, 32, 16))
        _, report = self.run_case(source, candidate, "--columns", "2")
        self.assertEqual(report["status"], "pending_visual_review")
        self.assertGreater(report["cells"][0]["visible_rgb_mae"], 100)
        self.assertGreater(report["cells"][1]["visible_rgb_mae"], 100)

    def test_exact_mode_accepts_every_rgba_pixel_repeated(self):
        source = Image.new("RGBA", (2, 1), (10, 50, 100, 255))
        source.putpixel((1, 0), (70, 80, 90, 128))
        candidate = source.resize((8, 4), Image.Resampling.NEAREST)
        code, report = self.run_case(source, candidate, "--exact-pixels")
        self.assertEqual(code, 0)
        self.assertTrue(report["pixel_replication_verified"])

    def test_exact_mode_rejects_a_single_changed_color(self):
        source = Image.new("RGBA", (2, 1), (10, 50, 100, 255))
        candidate = source.resize((8, 4), Image.Resampling.NEAREST)
        candidate.putpixel((7, 3), (11, 50, 100, 255))
        code, report = self.run_case(source, candidate, "--exact-pixels")
        self.assertEqual(code, 1)
        self.assertIn("pixel_values_changed", report["failures"])
        self.assertEqual(report["cells"][0]["rgba_changed_pixels"], 1)

    def test_exact_mode_rejects_colors_that_cancel_in_native_average(self):
        source = Image.new("RGBA", (2, 1), (100, 100, 100, 255))
        candidate = source.resize((8, 4), Image.Resampling.NEAREST)
        candidate.putpixel((0, 0), (92, 100, 100, 255))
        candidate.putpixel((1, 0), (108, 100, 100, 255))
        code, report = self.run_case(source, candidate, "--exact-pixels")
        self.assertEqual(code, 1)
        self.assertEqual(report["cells"][0]["visible_rgb_mae"], 0)
        self.assertEqual(report["cells"][0]["rgba_changed_pixels"], 2)
        self.assertFalse(report["pixel_replication_verified"])


if __name__ == "__main__":
    unittest.main()
