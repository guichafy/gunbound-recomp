"""Check the inventory and summarize isolated Godot/PE diagnostics."""

import argparse
from collections import Counter
import csv
from hashlib import sha256
import itertools
import json
from pathlib import Path
import re

WEATHERS = ("neutral", "force", "tornado", "electricity", "wind", "thor", "protection", "ignorance")
DIRECT_MODIFIERS = {"neutral", "force", "electricity", "thor"}
POINTS = (-50, -1, 0, 1, 25, 49, 50)


def read_json(path):
    return json.loads(path.read_text())


def summarize_impacts(path, native):
    catalog = {(row["shooter"], row["weapon"], row["attack"]): row
               for row in native["initializers"]}
    columns = native["damage"]["columns"]
    oracle = {}
    for record in native["damage"]["rows"]:
        row = dict(zip(columns, record))
        if not row["dx"] and not row["dy"] and not row["protection"]:
            key = tuple(row[key] for key in ("shooter", "weapon", "target", "attack", "defense", "force"))
            oracle[key] = max(0, row["amount"])

    inventory = set()
    weather_counts = Counter()
    per_shot = {}
    differing_power = []
    highest_reported = None
    highest_hp_lost = None
    with path.open(newline="") as stream:
        for raw in csv.DictReader(stream):
            row = {key: value if key in ("weather", "sample") else int(value)
                   for key, value in raw.items()}
            shot = (row["shooter"], row["weapon"])
            pair = (*shot, row["target"])
            weather, sample = row["weather"], row["sample"]
            stats = (row["attack"], row["defense"])
            cell = (*pair, weather, sample, *stats)
            if cell in inventory:
                raise ValueError(f"Duplicate impact cell {cell}")
            inventory.add(cell)
            weather_counts[weather] += 1
            if highest_reported is None or row["reported"] > highest_reported["reported"]:
                highest_reported = row
            if highest_hp_lost is None or row["hp_lost"] > highest_hp_lost["hp_lost"]:
                highest_hp_lost = row
            result = per_shot.setdefault(f"{shot[0]}:{shot[1]}", {
                "rows": 0, "reported_600_or_more": 0, "hp_600_or_more": 0, "any_overkill": 0,
                "center_amount_compared": 0, "center_amount_differs": 0,
                "center_comparable_forces": Counter(),
            })
            result["rows"] += 1
            result["reported_600_or_more"] += row["reported"] >= 600
            result["hp_600_or_more"] += row["hp_lost"] >= 600
            result["any_overkill"] += row["overkill"] > 0

            if weather == "neutral" and sample == "center" and row["target"] == 2:
                expected = catalog[(*shot, 0)]["power"][0]
                if row["shell_power"] != expected:
                    differing_power.append({"shooter": shot[0], "weapon": shot[1],
                                            "primary_shell": row["shell_power"], "pe_cell": expected})
            # Center-only numeric comparison with equal Force inputs. Legacy
            # Force mutates shell power and does not expose a comparable value.
            force = row["shell_force"]
            if sample in ("center", "stats") and (weather == "neutral" or (weather == "force" and force == 100)):
                expected = oracle[(*pair, *stats, force)]
                result["center_amount_compared"] += 1
                result["center_amount_differs"] += row["reported"] != expected
                result["center_comparable_forces"][weather] += 1

    for pair in itertools.product(range(1, 17), range(3), range(1, 17)):
        for weather in WEATHERS:
            for sample in ("center", "inner", "edge", "miss"):
                inventory.remove((*pair, weather, sample, 0, 0))
            if weather in DIRECT_MODIFIERS:
                for attack, defense in itertools.product(POINTS, repeat=2):
                    if attack or defense:
                        inventory.remove((*pair, weather, "stats", attack, defense))
    if inventory:
        raise ValueError(f"Unexpected impact cells: {len(inventory)}")
    return {
        "rows": sum(weather_counts.values()),
        "weather_target_shot_cells": 48 * 16 * len(WEATHERS),
        "rows_per_weather": weather_counts,
        "center_amount_compared": sum(r["center_amount_compared"] for r in per_shot.values()),
        "center_amount_differs": sum(r["center_amount_differs"] for r in per_shot.values()),
        "reported_600_or_more": sum(r["reported_600_or_more"] for r in per_shot.values()),
        "hp_600_or_more": sum(r["hp_600_or_more"] for r in per_shot.values()),
        "any_overkill": sum(r["any_overkill"] for r in per_shot.values()),
        "highest_reported": highest_reported,
        "highest_hp_lost": highest_hp_lost,
        "primary_power_differences": differing_power,
        "per_shot": per_shot,
    }


def tagged_rows(path, label):
    prefix = label + " "
    return [json.loads(line[len(prefix):]) for line in path.read_text().splitlines()
            if line.startswith(prefix + "{")]


def summarize_flight(path, full_targets=False, auxiliary=False):
    rows = tagged_rows(path, "WEATHER_ROW")
    (result,) = tagged_rows(path, "WEATHER_CHECKS")
    if result["cases"] != len(rows) or result["failures"]:
        raise ValueError("Weather probe did not complete cleanly")
    if not all(row["snapshot_equal"] and row["terminated"] for row in rows):
        raise ValueError("Weather probe found divergence or nonterminating flight")
    if full_targets:
        observed = {(r["shooter"], r["weapon"], r["target"], r["category"]) for r in rows}
        expected = set(itertools.product(range(1, 17), range(3), range(1, 17), WEATHERS))
        if observed != expected or len(observed) != len(rows):
            raise ValueError("Weather target matrix has missing or duplicate cells")
    if auxiliary:
        maps = {r["map"] for r in rows if r["scenario"] == "native_map"}
        items = {(r["shooter"], r["weapon"], r["turn"]["item"], r["category"])
                 for r in rows if r["scenario"] == "items"}
        expected = set(itertools.product(range(1, 17), range(2),
                       ("dual", "dual_plus", "thunder", "teleport", "bunge_shot"), WEATHERS))
        if len(maps) != 22 or items != expected or len(rows) != len(maps) + len(items):
            raise ValueError("Map/item probe has missing or duplicate cells")
    hits = Counter(row["category"] for row in rows if row["actor_impacts"] > 0)
    high = [row for row in rows if row["target_damage_event_sum"] >= 600]
    if any(not row["high_damage_trace"] for row in high):
        raise ValueError("Missing event trace for high damage")
    peak = max(rows, key=lambda r: r["target_damage_event_sum"])
    fields = ("shooter", "weapon", "category", "facing", "scenario", "target",
              "target_damage_event_sum", "hp_lost", "shield_lost", "target_reported_minus_loss")
    return {
        **result, "cases_per_weather": Counter(r["category"] for r in rows),
        "actor_contact_per_weather": hits, "high_reported": len(high),
        "high_actual_hp_loss": sum(r["hp_lost"] >= 600 for r in rows),
        "max_reported": {key: peak[key] for key in fields if key in peak},
        "max_reported_trace": peak.get("high_damage_trace", []),
        "column_consumed": Counter(r["category"] for r in rows if r["column_hits"]),
        "log_sha256": sha256(path.read_bytes()).hexdigest(),
    }


def summarize_launch(path):
    (grid,) = tagged_rows(path, "LAUNCH GRID")
    if grid != {"boundaries": 7300, "ui_cells": 21900, "velocity_pairs": 394200}:
        raise ValueError("Launch grid did not cover the expected inventory")
    ok = re.search(r"^LAUNCH GRID CHECKS: (\d+) \| FAILURES: 0$", path.read_text(), re.MULTILINE)
    if not ok or int(ok[1]) != sum(grid.values()) + 17:
        raise ValueError("Launch checks are incomplete or failed")
    return {**grid, "checks": int(ok[1])}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("native", "impact", "bridge", "output"):
        parser.add_argument(f"--{name}", required=True, type=Path)
    for name in ("axes", "weather", "weather-targets", "weather-auxiliary", "launch"):
        parser.add_argument(f"--{name}", type=Path)
    args = parser.parse_args()
    native, bridge = read_json(args.native), read_json(args.bridge)
    if bridge["rows"] != len(native["damage"]["rows"]):
        raise ValueError("Consumer comparison omitted observations")
    impacts = summarize_impacts(args.impact, native)
    result = {
        "scope": "Controlled impact and isolated shared consumer. No full-shot parity claim.",
        "source_hashes": {
            "pe": native["pe_sha256"], "characterdata": native["dat_sha256"],
            "native_matrix": sha256(args.native.read_bytes()).hexdigest(),
            "impact_csv": sha256(args.impact.read_bytes()).hexdigest(),
        },
        "native_roster": {
            "numeric_rows": len(native["damage"]["rows"]),
            "armor_rows": len(native["damage"]["armor"]),
            "initializers": len(native["initializers"]), "targets": len(native["targets"]),
        },
        "shared_consumer": bridge,
        "impact_probe": impacts,
    }
    if args.axes:
        axes = read_json(args.axes)
        if axes["rows"] != 48 * 101 * 2:
            raise ValueError("Signed axis comparison omitted observations")
        result["signed_axes_consumer"] = axes
    if args.weather:
        result["weather_flight"] = summarize_flight(args.weather)
    if args.weather_targets:
        result["weather_target_flight"] = summarize_flight(args.weather_targets, full_targets=True)
    if args.weather_auxiliary:
        result["weather_map_item_flight"] = summarize_flight(args.weather_auxiliary, auxiliary=True)
    if args.launch:
        result["launch_grid"] = summarize_launch(args.launch)
    args.output.write_text(json.dumps(result, sort_keys=True, indent=2) + "\n")
    print(f"{impacts['rows']} impact rows | {impacts['center_amount_compared']} center comparisons")


if __name__ == "__main__":
    main()
