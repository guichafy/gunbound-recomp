"""Decode the three native column XTF sheets without changing their pixels.

Consumers: Force471550, Electric46e020, Tornado4ac760.
Renderer4508a0 selects SRCALPHA/INVSRCALPHA except Electric SRCALPHA/ONE.
"""
import hashlib
import json
import struct
from pathlib import Path
from PIL import Image
import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / '.tools/gunbound-client/graphics.xfs'
ARCHIVE_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
PE_SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'


def main():
    assert hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() == ARCHIVE_SHA
    toc = {item['name']: item for item in xfs.read_toc(ARCHIVE)}
    folder = ROOT / 'assets/openbound/weather/native'
    folder.mkdir(parents=True, exist_ok=True)
    sheets = {}
    for name, consumer in [('FirewallTexture', '0x471550'), ('LightningTexture', '0x46e020'), ('TornadoTexture', '0x4ac760')]:
        raw = xfs.read_entry(ARCHIVE, toc[name+'.xtf'])
        assert struct.unpack_from('<IIB', raw) == (256, 256, 1) and len(raw) == 131081
        pixels = [xfs._argb4444(value) for value, in struct.iter_unpack('<H', raw[9:])]
        image = Image.new('RGBA', (256, 256))
        image.putdata(pixels)
        path = folder / (name+'.png')
        image.save(path)
        assert list(Image.open(path).getdata()) == pixels
        sheets[name] = dict(entry=name+'.xtf', entry_sha256=hashlib.sha256(raw).hexdigest(), image=name+'.png',
            image_sha256=hashlib.sha256(path.read_bytes()).hexdigest(), consumer=consumer,
            size=[256, 256], format='ARGB4444 -> RGBA8888, each channel times17; unchanged pixels',
            blend='SRCALPHA/ONE' if name=='LightningTexture' else 'SRCALPHA/INVSRCALPHA')
    metadata = dict(archive_sha256=ARCHIVE_SHA, pe_sha256=PE_SHA, dispatcher='0x4508a0', sheets=sheets)
    (folder/'column_art.json').write_text(json.dumps(metadata, indent=2)+'\n')
    print('Native column textures: 3 sheets, 196608 RGBA pixels verified against XTF')


if __name__ == '__main__':
    main()
