"""Observable contracts for per-frame bicubic smoothing."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/upscale_conservative.py"


class ConservativeUpscaleTests(unittest.TestCase):
    def execute(self, source, destination, *args):
        return subprocess.run([sys.executable, str(SCRIPT), str(source), str(destination), *args], capture_output=True, text=True)

    def test_adjacent_frames_never_mix_colors(self):
        with tempfile.TemporaryDirectory() as directory:
            source, dest = Path(directory) / "source.png", Path(directory) / "output.png"
            im = Image.new("RGBA", (4, 2), "red")
            im.paste("blue", (2, 0, 4, 2))
            im.save(source)
            before = source.read_bytes()
            result = self.execute(source, dest, "--columns", "2")
            self.assertEqual(result.returncode, 0, result.stderr)
            with Image.open(dest) as image:
                self.assertEqual(image.size, (16, 8))
                self.assertEqual(list(image.getdata()), ([(255, 0, 0, 255)] * 8 + [(0, 0, 255, 255)] * 8) * 8)
            self.assertEqual(source.read_bytes(), before)

    def test_alpha_keeps_native_coverage_and_invisible_color_does_not_bleed(self):
        with tempfile.TemporaryDirectory() as directory:
            source, dest = Path(directory) / "source.png", Path(directory) / "output.png"
            im = Image.new("RGBA", (2, 1))
            im.putdata([(255, 0, 255, 0), (0, 255, 0, 255)])
            im.save(source)
            result = self.execute(source, dest)
            self.assertEqual(result.returncode, 0, result.stderr)
            with Image.open(dest) as image:
                self.assertEqual(list(image.getchannel("A").getdata()), ([0] * 4 + [255] * 4) * 4)
                self.assertEqual([image.getpixel((x, 0)) for x in range(4, 8)], [(0, 255, 0, 255)] * 4)

    def test_bicubic_interpolates_internal_edge(self):
        with tempfile.TemporaryDirectory() as directory:
            source, dest = Path(directory) / "source.png", Path(directory) / "output.png"
            im = Image.new("RGBA", (2, 1))
            im.putdata([(0, 0, 0, 255), (255, 255, 255, 255)])
            im.save(source)
            result = self.execute(source, dest)
            self.assertEqual(result.returncode, 0, result.stderr)
            with Image.open(dest) as image:
                self.assertTrue(0 < image.getpixel((3, 0))[0] < image.getpixel((4, 0))[0] < 255)

    def test_invalid_grid_does_not_write_output(self):
        with tempfile.TemporaryDirectory() as directory:
            source, dest = Path(directory) / "source.png", Path(directory) / "output.png"
            Image.new("RGBA", (4, 2), "red").save(source)
            result = self.execute(source, dest, "--columns", "3")
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertFalse(dest.exists())

    def test_existing_output_and_source_cannot_be_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            source, dest = Path(directory) / "source.png", Path(directory) / "output.png"
            Image.new("RGBA", (4, 2), "red").save(source)
            before = source.read_bytes()
            dest.write_bytes(b"previous artifact")
            self.assertEqual(self.execute(source, dest).returncode, 1)
            self.assertEqual(dest.read_bytes(), b"previous artifact")
            self.assertEqual(self.execute(source, source).returncode, 1)
            self.assertEqual(source.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
