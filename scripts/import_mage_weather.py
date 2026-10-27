"""Extract native stage weather records (419d90 loader / 41f200 consumers)."""
import hashlib
import json
from pathlib import Path
import struct

from gunbound_xfs import lzhuf

ROOT = Path(__file__).resolve().parents[1]
PE_SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
STAGE_SHA = '103c2b488977e1721becf8cb90496f95477302ec24141f94116d5214a3e6cfca'


def decode_stage(raw):
    # Native loader reads four header bytes, len-5 compressed bytes, checksum.
    if (77 + sum(raw[4:-1])) & 255 != raw[-1]:
        raise ValueError('stage checksum')
    decoded = lzhuf(raw[4:-1], 0x3c80)
    result = []
    for index in range(32):
        row = decoded[index*484:(index+1)*484]
        name = row[:128].split(b'\0')[0].decode('ascii')
        if not name:
            continue
        ranges = {}
        for kind, offset in [('tornado', 292), ('force', 356), ('electricity', 420)]:
            low = struct.unpack_from('<8i', row, offset)
            high = struct.unpack_from('<8i', row, offset+32)
            ranges[kind] = list(map(list, zip(low, high)))
        result.append(dict(index=index, name=name,
                           weights=list(struct.unpack_from('<7i', row, 260)),
                           column_ranges=ranges))
    return result


def main():
    assert hashlib.sha256((ROOT/'.tools/mobile-animation-port/GunBound.gme').read_bytes()).hexdigest() == PE_SHA
    source = ROOT / '.tools/gunbound-client/stage.dat'
    raw = source.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == STAGE_SHA
    stages = decode_stage(raw)
    miramo = next(row for row in stages if row['name'] == 'MiramoTown')
    output = dict(stage_sha256=hashlib.sha256(raw).hexdigest(),
                  native_categories=['force', 'tornado', 'electricity', 'wind', 'thor', 'moon', 'eclipse'],
                  miramo_town_a=miramo)
    path = ROOT / 'assets/openbound/weather/native_stage.json'
    path.write_text(json.dumps(output, indent=2)+'\n')
    print('Native Miramo weather:', miramo['weights'], 'three sets of eight X ranges')


if __name__ == '__main__':
    main()
