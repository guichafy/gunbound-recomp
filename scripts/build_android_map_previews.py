"""Split the approved4x map strip into Android-safe, pixel-identical textures."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/hd/classic/room_smooth_4x/room/details/maps.png'
DESTINATION = ROOT / 'assets/hd/classic/android_map_previews'
FRAME_SIZE = (544, 336)
FRAME_COUNT = 22


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(source=SOURCE, destination=DESTINATION):
    source, destination = Path(source), Path(destination)
    with Image.open(source) as image:
        if image.size != (FRAME_SIZE[0] * FRAME_COUNT, FRAME_SIZE[1]):
            raise ValueError('Expected approved22-frame11968x336 HD map preview strip')
        image = image.convert('RGBA')
        destination.mkdir(parents=True, exist_ok=True)
        frames = []
        for index in range(FRAME_COUNT):
            path = destination / f'map_{index:02d}.png'
            image.crop((index * FRAME_SIZE[0], 0, (index + 1) * FRAME_SIZE[0], FRAME_SIZE[1])).save(path)
            frames.append({'index': index, 'file': path.name, 'sha256': digest(path)})
    catalog = {
        'schema': 1,
        'frame_size': list(FRAME_SIZE),
        'source': {'file': source.relative_to(ROOT).as_posix() if source.is_relative_to(ROOT) else source.name,
                   'sha256': digest(source)},
        'frames': frames,
    }
    (destination / 'catalog.json').write_text(json.dumps(catalog, indent=2) + '\n', encoding='utf-8')
    return catalog


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=SOURCE)
    parser.add_argument('--output', type=Path, default=DESTINATION)
    args = parser.parse_args()
    result = build(args.source, args.output)
    print(f'Android map previews: {len(result["frames"])} exact544x336 RGBA frames')
