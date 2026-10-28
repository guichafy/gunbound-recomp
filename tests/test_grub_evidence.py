"""The versioned Grub evidence (issue #8): manifests, hashes and the matrix stay coherent."""
import hashlib
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/sdd/grub-evidence"
DOC = (ROOT / "docs/sdd/GRUB_CLIENT_FIX.md").read_text()
HASHES = {
    "pe": "4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde",
    "graphics": "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08",
    "sound": "081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023",
    "characterdata": "b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf",
}


class GrubEvidence(unittest.TestCase):
    def test_document_pins_every_source(self):
        for name, value in HASHES.items():
            self.assertIn(value, DOC, name)

    def test_manifests(self):
        names = sorted(p.name for p in EVIDENCE.glob("*.manifest.json"))
        self.assertEqual(len(names), 6)
        for name in names:
            manifest = json.loads((EVIDENCE / name).read_text())
            self.assertEqual(manifest["source_sha256"], HASHES["pe"], name)
            self.assertEqual(manifest["image_base"], "00400000", name)
            run = json.loads((EVIDENCE / name.replace(".manifest", ".run")).read_text())
            self.assertEqual(run["source"]["sha256"], HASHES["pe"], name)
            if name.startswith("run1-"):
                # The issue's command: 0x488780 is a vtable target Ghidra did not recognise.
                missing = [f["requested_va"] for f in manifest["functions"] if f.get("status") != "decompiled"]
                self.assertEqual(missing, ["0x00488780"])
                self.assertFalse(manifest["ok"])
            else:
                self.assertTrue(manifest["ok"], name)
                self.assertTrue(all(f.get("status") == "decompiled" for f in manifest["functions"]), name)

    def test_seeded_entries_have_a_proven_prologue(self):
        manifest = json.loads((EVIDENCE / "run2-seeded.manifest.json").read_text())
        seeded = sorted(f["requested_va"] for f in manifest["functions"] if f.get("seeded"))
        self.assertEqual(seeded, ["0x00458690", "0x00488780", "0x00488880"])

    def test_local_sources_match_when_present(self):
        for relative, key in [(".tools/mobile-animation-port/GunBound.gme", "pe"), (".tools/gunbound-client/graphics.xfs", "graphics"),
                              (".tools/gunbound-client/characterdata.dat", "characterdata")]:
            path = ROOT / relative
            if path.exists():
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), HASHES[key], relative)

    def test_catalog_row_matches_the_dat(self):
        catalog = json.loads((ROOT / "assets/openbound/grub/combat_native.json").read_text())
        self.assertEqual(catalog["binary_sha256"], HASHES["pe"])
        self.assertEqual(catalog["characterdata_sha256"], HASHES["characterdata"])
        self.assertEqual(len(catalog["row"]), 83)
        self.assertEqual([w["secondary"] for w in catalog["weapons"]], [0, 1800, 1600])


if __name__ == "__main__":
    unittest.main()
