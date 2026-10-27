"""Decode original CrashTexture XTF pixels; provenance is pinned to the client.

Force48dd80/Electric481ef0 call quad4ec840. Dispatcher450c20 sets both
categories190003/190004 to SRCALPHA/ONE. No generated or resampled pixels.
"""
import hashlib
import json
from pathlib import Path
import struct
from PIL import Image
import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / '.tools/gunbound-client/graphics.xfs'
PE = ROOT / '.tools/mobile-animation-port/GunBound.gme'
ARCHIVE_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
PE_SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
ENTRY_SHA = '82a67f447474ea5b304e74330ffacfd62e58ab8446a2cfa4123cf2c618fb12ee'


def _verify(path, expected):
    if hashlib.sha256(Path(path).read_bytes()).hexdigest() != expected:
        raise ValueError(f'SHA256 mismatch: {path}')


def import_assets(output_dir, archive=ARCHIVE, pe=PE):
    """Verify both inputs before creating output; return saved provenance."""
    archive = Path(archive)
    _verify(archive, ARCHIVE_SHA)
    _verify(pe, PE_SHA)
    toc = {entry['name']: entry for entry in xfs.read_toc(archive)}
    raw = xfs.read_entry(archive, toc['CrashTexture.xtf'])
    if hashlib.sha256(raw).hexdigest() != ENTRY_SHA:
        raise ValueError('SHA256 mismatch: CrashTexture.xtf')
    if len(raw) != 131081 or struct.unpack_from('<IIB', raw) != (256, 256, 1):
        raise ValueError('Unexpected CrashTexture XTF dimensions/format')
    pixels = [xfs._argb4444(value) for value, in struct.iter_unpack('<H', raw[9:])]
    image = Image.new('RGBA', (256, 256))
    image.putdata(pixels)
    folder = Path(output_dir)
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / 'CrashTexture.png'
    image.save(path)
    metadata = dict(archive_sha256=ARCHIVE_SHA, pe_sha256=PE_SHA,
                    entry='CrashTexture.xtf', entry_sha256=ENTRY_SHA,
                    image=path.name, image_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                    size=[256, 256], format='ARGB4444 -> RGBA8888; channels times17; unchanged pixels',
                    dispatcher='0x450c20', quad='0x4ec840', sine_lut='0x54c240',
                    blend='SRCALPHA/ONE', age=[0, 15], frame_ticks=2,
                    families={'force': dict(spawn='0x436dc0', constructor='0x48dcc0',
                                           animate='0x48dd10', draw='0x48dd80', v=0.25, rotation=1),
                              'electricity': dict(spawn='0x436ec0', constructor='0x481e30',
                                                 animate='0x481e80', draw='0x481ef0', v=0.375, rotation=6)})
    (folder / 'spark_art.json').write_text(json.dumps(metadata, indent=2) + '\n')
    return metadata


if __name__ == '__main__':
    import_assets(ROOT / 'assets/openbound/mage/original')
    print('Native Mage sparks: 65536 original RGBA pixels decoded from CrashTexture.xtf')
