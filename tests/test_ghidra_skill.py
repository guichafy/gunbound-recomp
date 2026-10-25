"""Public CLI checks for the skill's local analysis runner; no target execution."""
from pathlib import Path
import json
import subprocess
import sys
import tempfile
import time
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

    def test_different_binary_cannot_reuse_analysis(self):
        with tempfile.TemporaryDirectory() as root:
            install = Path(root, "install")
            (install / "support").mkdir(parents=True)
            (install / "Ghidra").mkdir()
            (install / "support/analyzeHeadless").write_text("must not launch")
            (install / "Ghidra/application.properties").write_text("application.version=12.2")
            work = Path(root, "work")
            work.mkdir()
            (work / "source.json").write_text(json.dumps({"sha256": "different", "program": Path(__file__).name}))
            result = subprocess.run([
                sys.executable, str(RUNNER), "--binary", __file__,
                "--ghidra-dir", str(install), "--work-dir", str(work),
                "--output", root + "/output", "--functions", "0x004a6200",
            ], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn("project source identity mismatch", result.stderr)
            self.assertFalse(Path(root, "output").exists())

    def test_timeout_stops_descendant_even_when_launcher_exits_first(self):
        with tempfile.TemporaryDirectory() as root:
            install = Path(root, "install")
            (install / "support").mkdir(parents=True)
            (install / "Ghidra").mkdir()
            (install / "Ghidra/application.properties").write_text("application.version=12.2")
            marker = Path(root, "survived")
            launcher = install / "support/analyzeHeadless"
            launcher.write_text("#!/bin/sh\n(trap '' TERM; sleep 2; printf survived > '" + str(marker) + "') &\nwait\n")
            launcher.chmod(0o755)
            result = subprocess.run([
                sys.executable, str(RUNNER), "--binary", __file__,
                "--ghidra-dir", str(install), "--work-dir", root + "/work",
                "--output", root + "/output", "--functions", "0x004a6200", "--timeout", "1",
            ], capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 1, result.stderr)
            run = json.loads(Path(root, "output/run.json").read_text())
            self.assertIn("timeout", run["error"])
            time.sleep(2.5)
            self.assertFalse(marker.exists(), "A descendant survived the analysis timeout")


if __name__ == "__main__":
    unittest.main()
