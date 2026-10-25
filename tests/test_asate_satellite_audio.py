"""Independently compare original Ion XES PCM with the delivered WAVs."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import gunbound_xfs as xfs
import import_asate_satellite as importer

ARCHIVE = Path("/Users/guichafy/Workspaces/GunboundClassic/gunbound-launcher/TestClient/sound.xfs")
OUTPUT = ROOT / "assets/openbound/asate"


class SatelliteAudio(unittest.TestCase):
    @unittest.skipUnless(ARCHIVE.exists(), "local original sound.xfs required")
    def test_original_payload_and_wave_parameters(self):
        self.assertEqual(hashlib.sha256(ARCHIVE.read_bytes()).hexdigest(), importer.SOURCE_SHA)
        toc = {entry["name"]: entry for entry in xfs.read_toc(ARCHIVE)}
        for number in (1, 2):
            raw = xfs.read_entry(ARCHIVE, toc[f"10s{number}fire.xes"])
            fmt, channels, rate, byte_rate, align, bits = struct.unpack_from("<HHIIHH", raw)
            self.assertEqual((fmt, channels, rate, byte_rate, align, bits), (1, 2, 22050, 88200, 4, 16))
            with wave.open(str(OUTPUT / f"Satellite{number}.wav"), "rb") as stream:
                self.assertEqual((stream.getnchannels(), stream.getframerate(), stream.getsampwidth()), (2, 22050, 2))
                self.assertEqual(stream.readframes(stream.getnframes()), raw[16:])
        self.assertNotIn("10s3fire.xes", toc)

    def test_manifest_hashes_and_missing_ss(self):
        manifest = json.loads((OUTPUT / "satellite_audio.json").read_text())
        for number, record in enumerate(manifest["records"], 1):
            if number == 3:
                self.assertFalse(record["present"])
                self.assertEqual(record["resource"], "")
                self.assertFalse((OUTPUT / "Satellite3.wav").exists())
                continue
            destination = OUTPUT / f"Satellite{number}.wav"
            self.assertEqual(hashlib.sha256(destination.read_bytes()).hexdigest(), record["wav_sha256"])
            with wave.open(str(destination), "rb") as stream:
                payload = stream.readframes(stream.getnframes())
                self.assertEqual(hashlib.sha256(payload).hexdigest(), record["pcm_sha256"])

    @unittest.skipUnless(ARCHIVE.exists(), "local original sound.xfs required")
    def test_import_is_reproducible(self):
        with tempfile.TemporaryDirectory() as folder:
            importer.extract(ARCHIVE, folder)
            for name in ("Satellite1.wav", "Satellite2.wav", "satellite_audio.json"):
                self.assertEqual((Path(folder) / name).read_bytes(), (OUTPUT / name).read_bytes())


if __name__ == "__main__":
    unittest.main()
