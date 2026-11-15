import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]


class AndroidMapPreviews(unittest.TestCase):
    def test_derivatives_preserve_every_pixel_alpha_and_frame_order(self):
        script = ROOT / 'scripts/build_android_map_previews.py'
        self.assertTrue(script.exists(), 'Android-safe exact preview builder must exist')
        spec = importlib.util.spec_from_file_location('android_map_previews', script)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        source = ROOT / 'assets/hd/classic/room_smooth_4x/room/details/maps.png'
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder) / 'previews'
            module.build(source, output)
            catalog = json.loads((output / 'catalog.json').read_text())
            self.assertEqual(catalog['frame_size'], [544, 336])
            self.assertEqual(len(catalog['frames']), 22)
            with Image.open(source) as atlas:
                original = atlas.convert('RGBA')
                for index, frame in enumerate(catalog['frames']):
                    self.assertEqual(frame['index'], index)
                    with Image.open(output / frame['file']) as image:
                        expected = original.crop((index * 544, 0, (index + 1) * 544, 336))
                        self.assertEqual(image.size, (544, 336))
                        self.assertEqual(image.convert('RGBA').tobytes(), expected.tobytes())
                        self.assertIsNone(ImageChops.difference(image.getchannel('A'), expected.getchannel('A')).getbbox())

    def test_source_shape_is_validated_before_output(self):
        script = ROOT / 'scripts/build_android_map_previews.py'
        self.assertTrue(script.exists(), 'Android-safe exact preview builder must exist')
        spec = importlib.util.spec_from_file_location('android_map_previews', script)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / 'invalid.png'
            Image.new('RGBA', (544, 336)).save(source)
            with self.assertRaises(ValueError):
                module.build(source, Path(folder) / 'output')
            self.assertFalse((Path(folder) / 'output').exists())


if __name__ == '__main__':
    unittest.main()
