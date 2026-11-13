from pathlib import Path
import sys
import unittest
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import classic_map_source as source


class ClassicMapSourceTests(unittest.TestCase):
    def test_native_family_and_side_are_separate(self):
        self.assertEqual([source.family(i) for i in range(22)], list(range(11)) * 2)
        self.assertEqual(source.key(1), "miramo_town_a")
        self.assertEqual(source.key(12), "miramo_town_b")
        for bad in [-1, 22, 99]:
            with self.assertRaises(ValueError):
                source.family(bad)

    def test_side_uses_same_native_world_resource(self):
        for family in range(11):
            self.assertEqual(
                source.world_prefix(family), source.world_prefix(family + 11)
            )
        self.assertEqual(source.world_prefix(13), "hok")
        self.assertEqual(source.world_prefix(18), "brick")
        self.assertEqual(source.world_prefix(21), "facky")

    def test_land_rejects_mismatch_before_publish(self):
        image = Image.new("RGBA", (2, 2), (255, 0, 0, 255))
        with self.assertRaises(ValueError):
            source.validate_land(image, b"\0" * 4, 2, 2)
        with self.assertRaises(ValueError):
            source.validate_land(image, b"\2" * 4, 4, 1)
        source.validate_land(image, b"\2" * 4, 2, 2)

    def test_particle_atlas_preserves_registered_pixels(self):
        image = Image.new("RGBA", (44, 44), (10, 20, 30, 255))
        atlas, half = source.particle_atlas([(image, (-18, -20))])
        self.assertGreaterEqual(half, 26)
        self.assertEqual(
            atlas.getchannel("A").getbbox(),
            (half - 18, half - 20, half + 26, half + 24),
        )
        self.assertEqual(sum(atlas.getchannel("A").tobytes()), 44 * 44 * 255)

    def test_bad_identity_refused(self):
        with self.assertRaises(ValueError):
            source.verify("graphics.xfs", b"wrong")


if __name__ == "__main__":
    unittest.main()


class ImportedMapCatalogTests(unittest.TestCase):
    def test_catalog_has_every_native_side_and_original_world(self):
        import json

        catalog = json.loads(
            (
                Path(__file__).resolve().parents[1] / "assets/xfs/maps/catalog.json"
            ).read_text()
        )
        self.assertEqual(len(catalog["maps"]), 22)
        for row in catalog["maps"]:
            self.assertEqual(
                row["world_prefix"], source.world_prefix(row["stage_index"])
            )
            self.assertTrue(row["alpha_equals_lnd"])
            self.assertEqual(len(row["weather"]), 7)
            self.assertEqual(len(row["ground_rows"]), 748)
            self.assertEqual(row["preview_size"], [748, 209])


class MapMatchInventoryTests(unittest.TestCase):
    def test_additional_matches_keep_original_inventory(self):
        sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts/ci"))
        import check

        self.assertEqual(check.MATCH_CASES["test_matches"], list(range(81, 94)))
        self.assertEqual(check.MATCH_CASES["test_classic_matches"], list(range(1, 17)))
        self.assertEqual(check.MATCH_CASES["test_map_matches"], list(range(44)))


class NativeBackgroundTests(unittest.TestCase):
    def test_rgb565_background_keeps_black_opaque(self):
        root = Path(__file__).resolve().parents[1]
        for prefix in source.PREFIXES:
            with Image.open(root / f"assets/xfs/maps/{prefix}/background.png") as image:
                self.assertEqual(image.getchannel("A").getextrema(), (255, 255), prefix)


class ImportedHashesTests(unittest.TestCase):
    def test_every_published_png_matches_manifest(self):
        import hashlib
        import json

        root = Path(__file__).resolve().parents[1]
        catalog = json.loads((root / "assets/xfs/maps/catalog.json").read_text())
        self.assertGreater(len(catalog["png_sha256"]), 100)
        for resource, expected in catalog["png_sha256"].items():
            self.assertEqual(
                hashlib.sha256((root / resource[6:]).read_bytes()).hexdigest(),
                expected,
                resource,
            )


class LoadingRasterTests(unittest.TestCase):
    def test_approved_miramo_loading_pixels_preserved(self):
        root = Path(__file__).resolve().parents[1]
        with Image.open(root / "assets/xfs/maps/mos/loading_a.png") as actual:
            with Image.open(
                root / "assets/classic/loading/miramo_town.png"
            ) as expected:
                self.assertEqual(
                    actual.convert("RGBA").tobytes(), expected.convert("RGBA").tobytes()
                )
