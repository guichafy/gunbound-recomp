"""Public CLI checks for the skill's local analysis runner; no target execution."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

RUNNER = Path(__file__).resolve().parents[1] / "skills/gunbound-client-port/scripts/run_ghidra.py"


class GhidraSkillCLI(unittest.TestCase):
    def test_help_exposes_analysis_and_explicit_seeding(self):
        result = subprocess.run([sys.executable, str(RUNNER), "--help"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--seed-known-entries", result.stdout)
        self.assertIn("--data", result.stdout)

    def test_hidden_project_path_rejected_before_launch(self):
        with tempfile.TemporaryDirectory() as root:
            result = subprocess.run([
                sys.executable, str(RUNNER), "--binary", __file__,
                "--ghidra-dir", root, "--work-dir", root + "/.hidden",
                "--output", root + "/output", "--functions", "0x004a6200",
            ], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn("hidden project path", result.stderr)
            self.assertFalse(Path(root, "output").exists())

    def test_existing_output_preserved(self):
        with tempfile.TemporaryDirectory() as root:
            output = Path(root, "output")
            output.mkdir()
            sentinel = output / "evidence.txt"
            sentinel.write_text("keep")
            result = subprocess.run([
                sys.executable, str(RUNNER), "--binary", __file__,
                "--ghidra-dir", root, "--work-dir", root + "/work",
                "--output", str(output), "--functions", "0x004a6200",
            ], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn("output already exists", result.stderr)
            self.assertEqual(sentinel.read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
