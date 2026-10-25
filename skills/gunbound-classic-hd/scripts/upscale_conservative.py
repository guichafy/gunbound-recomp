"""Conservative per-frame BICUBIC enlargement, with native alpha coverage preserved."""
import argparse
from pathlib import Path
import struct
import sys

from PIL import Image, PngImagePlugin


def positive(value):
    result = int(value)
    if result < 1:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return result


def upscale(source_path, destination_path, scale=4, columns=1, rows=1):
    if min(scale, columns, rows) < 1:
        raise ValueError("scale, columns and rows must be positive")
    if source_path.resolve() == destination_path.resolve():
        raise ValueError("source and destination must differ")
    if destination_path.exists():
        raise FileExistsError("destination already exists; choose a new filename")
    if destination_path.suffix.lower() != ".png":
        raise ValueError("destination must be a PNG")
    with Image.open(source_path) as source:
        if source.format != "PNG" or getattr(source, "n_frames", 1) != 1:
            raise ValueError("use a single static PNG; packed sprite sheets are supported")
        if source.width % columns or source.height % rows:
            raise ValueError("source dimensions must be divisible by the measured grid")
        native = source.convert("RGBA")
        width, height = source.width // columns, source.height // rows
        result = Image.new("RGBA", (source.width * scale, source.height * scale))
        for row in range(rows):
            for column in range(columns):
                frame = native.crop((column * width, row * height, (column + 1) * width, (row + 1) * height))
                size = (width * scale, height * scale)
                # Pillow resamples RGBA in premultiplied space; invisible RGB cannot bleed.
                enlarged = frame.resize(size, Image.Resampling.BICUBIC)
                enlarged.putalpha(frame.getchannel("A").resize(size, Image.Resampling.NEAREST))
                # Paste without a mask: retain partial alpha values exactly once.
                result.paste(enlarged, (column * size[0], row * size[1]))
        metadata = PngImagePlugin.PngInfo()
        if "gamma" in source.info:
            metadata.add(b"gAMA", struct.pack(">I", round(source.info["gamma"] * 100000)))
        if "srgb" in source.info:
            metadata.add(b"sRGB", bytes([source.info["srgb"]]))
        if "chromaticity" in source.info:
            metadata.add(b"cHRM", struct.pack(">8I", *(round(v * 100000) for v in source.info["chromaticity"])))
        with destination_path.open("xb") as stream:
            result.save(stream, format="PNG", pnginfo=metadata, icc_profile=source.info.get("icc_profile"))
        return result.size


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--scale", type=positive, default=4)
    parser.add_argument("--columns", type=positive, default=1)
    parser.add_argument("--rows", type=positive, default=1)
    args = parser.parse_args()
    try:
        size = upscale(args.source, args.destination, args.scale, args.columns, args.rows)
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(f"{args.destination.resolve()}: {size[0]}x{size[1]}, BICUBIC per frame, original alpha")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
