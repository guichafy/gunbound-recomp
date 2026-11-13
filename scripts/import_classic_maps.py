"""Import all Thor's Hammer map sides; preserve native family/side separation."""

import argparse
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import re
import struct
from PIL import Image
from classic_map_source import (
    family,
    key,
    world_prefix,
    verify,
    validate_land,
    particle_atlas,
)
from decode_gunbound_img import frames
from gunbound_xfs import parse_epa
from import_mage_weather import decode_stage
from read_gunbound_xfs import archive, extract

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/xfs/maps"


def build(client):
    graphics = (client / "graphics.xfs").read_bytes()
    verify("graphics.xfs", graphics)
    stage_raw = (client / "stage.dat").read_bytes()
    verify("stage.dat", stage_raw)
    verify("GunBound.gme", (client / "GunBound.gme").read_bytes())
    entries = archive(graphics)["entries"]

    @lru_cache(maxsize=None)
    def raw(name):
        return extract(graphics, entries[name])

    @lru_cache(maxsize=None)
    def images(name):
        return frames(raw(name))

    published = set()

    def save(image, prefix, name):
        path = OUT / prefix / name
        path.parent.mkdir(parents=True, exist_ok=True)
        # Do not churn an already imported original or its Godot metadata.
        if (
            not path.exists()
            or Image.open(path).convert("RGBA").tobytes() != image.tobytes()
        ):
            image.save(path)
        resource = "res://" + path.relative_to(ROOT).as_posix()
        published.add(resource)
        return resource

    def digest(name):
        return hashlib.sha256(raw(name)).hexdigest()

    stages = decode_stage(stage_raw)
    spawn_source = json.loads(
        (ROOT / "docs/maps-issue-45/server-spawns.json").read_text()
    )
    spawn_rows = {r["map_id"]: r for r in spawn_source["records"]}
    worlds = {}
    for number in range(11):
        prefix = world_prefix(number)
        fg, bg = images(prefix + ".img")
        # 4eb8e0→4ebaf0 rectangularRGB565 blit copies black, unlike sprite color key.
        bg[0].putalpha(255)
        land = raw(prefix + ".lnd")
        w, h = struct.unpack_from("<2I", land)
        validate_land(fg[0], land[8:], w, h)
        atlas, half = particle_atlas(images("p" + prefix + ".img"))
        world = dict(
            mask=save(fg[0], prefix, "foreground.png"),
            background=save(bg[0], prefix, "background.png"),
            particle=save(atlas, prefix, "particle.png"),
            particle_frames=len(images("p" + prefix + ".img")),
            particle_pivot=[half, half],
            world_size=[w, h],
            crop=list(fg[0].getchannel("A").getbbox()),
            alpha_equals_lnd=True,
            world_prefix=prefix,
            scenery_enabled=False,  # 43f122 passes empty optional scenery prefix (551cb1).
            scenery=[],
        )
        for name in entries:
            if not re.fullmatch(re.escape(prefix) + r"\d+\.img", name):
                continue
            decoded = images(name)
            ew = max(im.width for im, _ in decoded)
            eh = max(im.height for im, _ in decoded)
            sheet = Image.new("RGBA", (ew * len(decoded), eh))
            for i, (im, pivot) in enumerate(decoded):
                sheet.alpha_composite(im, (i * ew, 0))
            epa = name[:-4] + ".epa"
            poses = parse_epa(raw(epa))[0] if epa in entries else []
            normal = next(
                (p for p in poses if p["name"].rstrip("\0") == "normal"), None
            )
            world["scenery"].append(
                dict(
                    texture=save(sheet, prefix, name[:-4] + ".png"),
                    cell=[ew, eh],
                    positions=[list(p) for _, p in decoded],
                    frames=normal["frames"] if normal else list(range(len(decoded))),
                    durations=normal["durations"] if normal else [1] * len(decoded),
                    native_epa=bool(normal),
                    loop=bool(normal["flag"]) if normal else False,
                )
            )
        # Preserve mos/catalog.json byte-for-byte, including the earlier provenance.
        if prefix != "mos":
            (OUT / prefix / "catalog.json").write_text(
                json.dumps(
                    dict(
                        world=world,
                        entries={
                            n: digest(n)
                            for n in [
                                prefix + ".img",
                                prefix + ".lnd",
                                "p" + prefix + ".img",
                            ]
                        },
                    ),
                    indent=2,
                )
                + "\n"
            )
        worlds[number] = world
        print("world", number, prefix, "alpha=LND", flush=True)
    save(images("b_ready_bside.img")[0][0], "ui", "bside.png")
    result = []
    for stage in stages:
        index = stage["index"]
        f = family(index)
        side = index // 11
        world = worlds[f]
        requested = "load_stage%02d.img" % index
        preview_entry = requested if requested in entries else "load_stage%02d.img" % f
        preview, mask = images(preview_entry)
        # Frame0 is full RGB565; frame1 remains a nonzero-word scan mask.
        preview[0].putalpha(255)
        if preview[0].size != (748, 209) or mask[0].size != (748, 209):
            raise ValueError("Invalid loading dimensions")
        rows = []
        pixels = mask[0].getchannel("A")
        for x in range(748):
            rows.append(next((y for y in range(209) if pixels.getpixel((x, y))), 209))
        row = dict(
            world,
            id=key(index),
            name=spawn_rows[f]["map_name_en"].replace(" (RANDOM)", ""),
            type="B" if side else "A",
            stage_index=index,
            family=f,
            client_stage=f,
            weather=stage["weights"],
            column_ranges=stage["column_ranges"],
            spawn_ranges=spawn_rows[f][
                "positions_b_side" if side else "positions_a_side"
            ],
            spawn_source_blob=spawn_source["blob_sha"],
            preview=save(
                preview[0],
                world_prefix(index),
                "loading_%s.png" % ("b" if side else "a"),
            ),
            preview_entry=preview_entry,
            preview_size=[748, 209],
            ground_rows=rows,
            preview_adaptation=preview_entry != requested,
            room_frame=index,
        )
        result.append(row)
    (OUT / "catalog.json").write_text(
        json.dumps(
            dict(
                version=1,
                graphics_sha256=hashlib.sha256(graphics).hexdigest(),
                stage_sha256=hashlib.sha256(stage_raw).hexdigest(),
                maps=result,
                png_sha256={
                    resource: hashlib.sha256(
                        (ROOT / resource[6:]).read_bytes()
                    ).hexdigest()
                    for resource in sorted(published)
                },
            ),
            indent=2,
        )
        + "\n"
    )
    print("Imported22sides/11worlds", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--client", type=Path, default=ROOT / ".tools/gunbound-client")
    build(parser.parse_args().client)
