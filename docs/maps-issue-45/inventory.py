"""Read-only Thor's Hammer map inventory; writes metadata JSON, never assets."""

import argparse
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import re
import struct
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from gunbound_xfs import lzhuf  # noqa: E402
from import_mage_weather import decode_stage  # noqa: E402
from read_gunbound_xfs import archive, extract  # noqa: E402

PINS = {
    "GunBound.gme": "4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde",
    "graphics.xfs": "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08",
    "stage.dat": "103c2b488977e1721becf8cb90496f95477302ec24141f94116d5214a3e6cfca",
    "sound.xfs": "081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023",
}


def inventory(client):
    files = {name: (client / name).read_bytes() for name in PINS}
    sources = {name: hashlib.sha256(raw).hexdigest() for name, raw in files.items()}
    if sources != PINS:
        raise ValueError("Unsupported client identity; expected pinned Thor's Hammer files")
    graphics = files["graphics.xfs"]
    entries = archive(graphics)["entries"]
    lookup = {name.lower(): name for name in entries}
    stage_raw = files["stage.dat"]
    decoded = lzhuf(stage_raw[4:-1], 0x3C80)

    @lru_cache(maxsize=None)
    def header(name):
        actual = lookup.get(name.lower())
        if actual is None:
            return None
        raw = extract(graphics, entries[actual])
        frames = []
        position = 8
        for _ in range(struct.unpack_from("<I", raw, 4)[0]):
            kind, _, width, height, x, y, _, _, _, _, size = struct.unpack_from("<HH9i", raw, position)
            position += 40 + size
            frames.append(dict(kind=kind, width=width, height=height, pivot=[x, y], bytes=size))
        if position != len(raw):
            raise ValueError(f"Unexpected IMG length: {actual}")
        return dict(entry=actual, sha256=hashlib.sha256(raw).hexdigest(), frames=frames)

    stages = []
    for stage in decode_stage(stage_raw):
        row = decoded[stage["index"] * 484:(stage["index"] + 1) * 484]
        prefix = row[128:256].split(b"\0")[0].decode("ascii")
        stage.update(
            prefix=prefix, flags=list(struct.unpack_from("<2H", row, 256)),
            image=header(prefix + ".img"), particle=header("p" + prefix + ".img"),
            loading=header("load_stage%02d.img" % stage["index"]),
        )
        land_name = lookup.get((prefix + ".lnd").lower())
        stage["land"] = None
        if land_name:
            raw = extract(graphics, entries[land_name])
            width, height = struct.unpack_from("<2I", raw)
            if len(raw) != 8 + width * height:
                raise ValueError(f"Unexpected LND length: {land_name}")
            stage["land"] = dict(
                entry=land_name, width=width, height=height,
                values=sorted(set(raw[8:])), solid=sum(value != 0 for value in raw[8:]),
                sha256=hashlib.sha256(raw).hexdigest(),
            )
        stage["auxiliary"] = [header(name) for name in entries
                              if re.fullmatch(re.escape(prefix) + r"\d+\.img", name, re.I)]
        stages.append(stage)
        print(stage["index"], stage["name"], flush=True)
    ui_names = ["gameliststage.img", "ready_selectmap.img", "selectmap.img", "stage.img", "loadstage.img"]
    return dict(sources=sources, stages=stages, ui={name: header(name) for name in ui_names},
                lands=[name for name in entries if name.endswith(".lnd")])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--client", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists() or output.is_relative_to(args.client.resolve()):
        parser.error("Choose a new output JSON outside the source client directory")
    result = inventory(args.client)
    output.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n")
