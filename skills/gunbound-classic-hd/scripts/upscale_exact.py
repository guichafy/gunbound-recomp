"""Integer pixel replication for an explicitly requested lossless PNG enlargement."""
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


def upscale(source_path, destination_path, scale):
    if source_path.resolve() == destination_path.resolve():
        raise ValueError("source and destination must differ")
    if destination_path.exists():
        raise FileExistsError("destination already exists; choose a new filename")
    if destination_path.suffix.lower() != ".png":
        raise ValueError("destination must be a PNG")
    with Image.open(source_path) as source:
        if source.format != "PNG" or getattr(source, "n_frames", 1) != 1:
            raise ValueError("use a single static PNG; packed sprite sheets are supported")
        metadata = PngImagePlugin.PngInfo()
        if "gamma" in source.info:
            metadata.add(b"gAMA", struct.pack(">I", round(source.info["gamma"] * 100000)))
        if "srgb" in source.info:
            metadata.add(b"sRGB", bytes([source.info["srgb"]]))
        if "chromaticity" in source.info:
            metadata.add(b"cHRM", struct.pack(">8I", *(round(v * 100000) for v in source.info["chromaticity"])))
        # NEAREST is replication at an integer scale, with no interpolation/new colors.
        result = source.convert("RGBA").resize(
            (source.width * scale, source.height * scale), Image.Resampling.NEAREST,
        )
        with destination_path.open("xb") as stream:
            result.save(stream, format="PNG", pnginfo=metadata, icc_profile=source.info.get("icc_profile"))
        return result.size


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--scale", type=positive, default=4)
    args = parser.parse_args()
    try:
        width, height = upscale(args.source, args.destination, args.scale)
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(f"{args.destination.resolve()}: {width}x{height}, exact pixel replication {args.scale}x")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
