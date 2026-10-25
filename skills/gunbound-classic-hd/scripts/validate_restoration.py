"""Image-preserving checks with new reports only. Exit 0 never means visual approval."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


def positive(value):
    result = int(value)
    if result < 1:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return result


def describe(path, image):
    return {
        "path": str(path.resolve()),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "size": list(image.size),
        "mode": image.mode,
        "alpha_extrema": list(image.convert("RGBA").getchannel("A").getextrema()),
    }


def cell_metrics(source, candidate, threshold):
    """Measure at registered 4x coordinates; hidden RGB has zero visual weight."""
    expected = source.resize(candidate.size, Image.Resampling.NEAREST)
    source_a = expected.getchannel("A")
    candidate_a = candidate.getchannel("A")
    source_support = source_a.point(lambda a: 255 if a > threshold else 0)
    candidate_support = candidate_a.point(lambda a: 255 if a > threshold else 0)
    changed = ImageChops.difference(source_support, candidate_support)
    histogram = changed.histogram()
    alpha_difference = ImageChops.difference(source_a, candidate_a)
    rgba_channels = ImageChops.difference(expected, candidate).split()
    rgba_difference = rgba_channels[0]
    for channel in rgba_channels[1:]:
        rgba_difference = ImageChops.lighter(rgba_difference, channel)
    # BOX preserves mean premultiplied coverage rather than inventing detail.
    reduced = candidate.resize(source.size, Image.Resampling.BOX)
    weighted_error = 0
    total_weight = 0
    for original, restored in zip(source.getdata(), reduced.getdata()):
        weight = min(original[3], restored[3]) / 255
        weighted_error += sum(abs(original[i] - restored[i]) for i in range(3)) * weight
        total_weight += 3 * weight
    return {
        "rgba_changed_pixels": sum(rgba_difference.histogram()[1:]),
        "max_rgba_delta": rgba_difference.getextrema()[1],
        "alpha_support_changed_pixels": sum(histogram[1:]),
        "alpha_values_changed_pixels": sum(alpha_difference.histogram()[1:]),
        "alpha_mae": round(ImageStat.Stat(alpha_difference).mean[0], 6),
        "visible_rgb_mae": round(weighted_error / total_weight, 6) if total_weight else 0,
        "source_alpha_bbox_native": source.getchannel("A").getbbox(),
        "candidate_alpha_bbox_native": reduced.getchannel("A").getbbox(),
    }


def validate(source_path, candidate_path, scale=4, columns=1, rows=1, threshold=8, exact_pixels=False):
    with Image.open(source_path) as source_file, Image.open(candidate_path) as candidate_file:
        report = {
            "source": describe(source_path, source_file),
            "candidate": describe(candidate_path, candidate_file),
            "scale": scale,
            "grid": [columns, rows],
            "alpha_support_threshold": threshold,
            "target_size": [source_file.width * scale, source_file.height * scale],
            "failures": [],
            "cells": None,
            "exact_pixels_required": exact_pixels,
            "pixel_replication_verified": None,
            "visual_review": "required: identity, geometry, palette, text, frame count/order and halos",
        }
        source = source_file.convert("RGBA")
        candidate = candidate_file.convert("RGBA")
    failures = report["failures"]
    if list(candidate.size) != report["target_size"]:
        failures.append("dimensions")
    if source.width * candidate.height != source.height * candidate.width:
        failures.append("aspect_ratio")
    if source.width % columns or source.height % rows:
        failures.append("source_grid")
    if candidate.width % columns or candidate.height % rows:
        failures.append("candidate_grid")
    if report["source"]["alpha_extrema"] == [255, 255] and report["candidate"]["alpha_extrema"] != [255, 255]:
        failures.append("opaque_alpha_changed")
    if not failures:
        width, height = source.width // columns, source.height // rows
        report["cells"] = []
        for row in range(rows):
            for column in range(columns):
                box = (column * width, row * height, (column + 1) * width, (row + 1) * height)
                scaled_box = tuple(value * scale for value in box)
                metrics = cell_metrics(source.crop(box), candidate.crop(scaled_box), threshold)
                report["cells"].append({"column": column, "row": row, **metrics})
        if any(cell["alpha_support_changed_pixels"] for cell in report["cells"]):
            failures.append("alpha_support_changed")
        if any(cell["alpha_values_changed_pixels"] for cell in report["cells"]):
            failures.append("alpha_values_changed")
        report["pixel_replication_verified"] = not any(cell["rgba_changed_pixels"] for cell in report["cells"])
        if exact_pixels and not report["pixel_replication_verified"]:
            failures.append("pixel_values_changed")
    report["status"] = "rejected" if failures else "pending_visual_review"
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--scale", type=positive, default=4)
    parser.add_argument("--columns", type=positive, default=1)
    parser.add_argument("--rows", type=positive, default=1)
    parser.add_argument("--exact-pixels", action="store_true", help="Reject any RGBA difference against integer pixel repetition")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    if args.report and args.report.exists():
        parser.error("report destination must be new; never overwrite source, candidate or an existing file")
    report = validate(args.source, args.candidate, args.scale, args.columns, args.rows, exact_pixels=args.exact_pixels)
    payload = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if args.report:
        try:
            with args.report.open("x", encoding="utf-8") as output:
                output.write(payload)
        except OSError as error:
            parser.error(str(error))
    print(payload, end="")
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
