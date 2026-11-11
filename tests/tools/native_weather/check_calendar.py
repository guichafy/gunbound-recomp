#!/usr/bin/env python3
"""Recheck independent fixtures from PE41ff42..420250 integer instructions.

Run from any directory. No Godot/ported helper imports; each IMUL/ADD wraps
u32 before the unsigned DIV remainder. Existing fixtures predate issue26.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def initial(seed, weights):
    state = seed
    mask = 0xffffffff

    def lcg():
        nonlocal state
        value = (state * 0x343fd + 0x5809315) & mask
        state = (state + ((97 * value + 97) & mask) % 1000001) & mask
        return value

    calendar = [category for category, count in enumerate(weights) for _ in range(count)][:8]
    calendar += [0] * (8 - len(calendar))
    for _ in range(31):
        a, b = lcg() & 7, lcg() & 7
        calendar[a], calendar[b] = calendar[b], calendar[a]
    force, angle = lcg() % 26, lcg() % 360
    next_force, next_delta = (lcg() & 15) - 8, lcg() % 80 - 40
    table = [lcg() for _ in range(1024)]
    return calendar, table[:8], force, angle, next_force, next_delta


def main():
    fixtures = json.loads((ROOT / 'tests/fixtures/mage_weather_native.json').read_text())
    for row in fixtures:
        actual = initial(row['seed'], row['preset'])
        expected = tuple(row[key] for key in ['calendar', 'table8', 'force', 'angle', 'next_force', 'next_delta'])
        assert actual == expected, (row['seed'], actual, expected)
    print(f'Independent PE calendar fixtures: {len(fixtures)} seeds OK')


if __name__ == '__main__':
    main()
