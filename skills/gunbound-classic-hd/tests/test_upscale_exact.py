"""Contract tests for the explicitly requested integer pixel enlargement."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/upscale_exact.py"


class ExactUpscaleTests(unittest.TestCase):
    def run_tool(self, source, destination, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(source), str(destination), *args],
            capture_output=True, text=True, check=False,
        )

    def test_fourfold_enlargement_preserves_pixels_and_source(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, destination = root / "source.png", root / "result.png"
            image = Image.new("RGBA", (2, 1))
            image.putdata([(20, 60, 100, 255), (90, 80, 70, 128)])
            image.save(source)
            before = source.read_bytes()
            result = self.run_tool(source, destination)
            self.assertEqual(result.returncode, 0, result.stderr)
            with Image.open(destination) as enlarged:
                self.assertEqual(enlarged.size, (8, 4))
                row = [(20, 60, 100, 255)] * 4 + [(90, 80, 70, 128)] * 4
                self.assertEqual(list(enlarged.getdata()), row * 4)
            self.assertEqual(source.read_bytes(), before)

    def test_existing_destination_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, destination = root / "source.png", root / "result.png"
            Image.new("RGBA", (2, 1), "red").save(source)
            destination.write_bytes(b"existing deliverable")
            result = self.run_tool(source, destination)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertEqual(destination.read_bytes(), b"existing deliverable")

    def test_source_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source.png"
            Image.new("RGBA", (2, 1), "red").save(source)
            before = source.read_bytes()
            result = self.run_tool(source, source)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertEqual(source.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
