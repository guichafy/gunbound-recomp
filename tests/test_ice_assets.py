"""Independent PE initializer fixtures plus pinned DAT/EPA metadata checks."""
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from import_ice_effects import catalog, ROSTER  # noqa: E402


class IceAssets(unittest.TestCase):
    def test_verified_sources_reproduce_runtime_catalog(self):
        self.assertEqual(catalog(), json.loads((ROOT / 'assets/classic/ice_effects.json').read_text()))

    def test_masks_match_executed_pe_initializer(self):
        metadata = catalog()
        oracle = json.loads((ROOT / 'tests/fixtures/ice_native.json').read_text())
        for case in oracle['masks']:
            vehicle = ROSTER.index(case['source_type'] + 1) + 1
            self.assertEqual(metadata['attack_masks'][str(vehicle)][case['weapon']], case['flags'])
        for case in oracle['initializers']:
            if case['attack'] == case['dig'] == 0:
                for field in ('power', 'dimension', 'aspect', 'flags'):
                    self.assertEqual(metadata['weapons'][case['weapon']][field], case[field])

    def test_native_pose_is_single_existing_frame_with_own_clock(self):
        metadata = catalog()
        self.assertEqual(len(metadata['poses']), 16)
        for vehicle, pose in metadata['poses'].items():
            self.assertEqual(len(pose['frames']), 1)
            self.assertEqual(pose['durations'], [1 if vehicle in ('1', '8', '10', '13') else 20])
        self.assertEqual(metadata['poses']['3']['frames'], [114])
        self.assertEqual(metadata['poses']['11']['frames'], [135])


if __name__ == '__main__':
    unittest.main()
