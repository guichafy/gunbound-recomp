#!/usr/bin/env python3
"""Rebuild the classic avatar index from the version 280 avatar.xfs.

The XFS is the TestClient copy from jglim/gunbound-launcher. Identity codes
follow jglim/gunbound-server (gameserver.py): a WORD with the item id in the
low 15 bits and male in bit 15, plus a DWORD whose third byte is the slot
(body 0, head 1, eye 2, flag 3). Equipped avatars are four of those WORDs in
the same slot order. Stats stay in the AvatarInfoProcessor order.
"""
import hashlib
import json
import re
from pathlib import Path

from read_gunbound_xfs import STAT_NAMES, avatar_rows

ROOT = Path(__file__).resolve().parents[1]
AVATAR = ROOT / 'assets/xfs/reference/avatar.xfs'
CATALOG = ROOT / 'assets/xfs/avatars/catalog.json'
GRAPHICS = ROOT / 'assets/xfs/reference/graphics-index.json'
OUTPUT = ROOT / 'assets/xfs/avatars/classic.json'

# Attribute order already used by the shop and by Match snapshots.
BONUS_ORDER = ['attack', 'health', 'defense', 'shield',
               'shot_delay', 'item_delay', 'bunge', 'popularity']
SLOT_NAME = {'b': 'body', 'h': 'head', 'g': 'eye', 'f': 'flag'}
SLOT_INDEX = {'body': 0, 'head': 1, 'eye': 2, 'flag': 3}
# Shop category remains head, body, eye, flag. Only the protocol slot changes.
CATEGORY = {'h': 0, 'b': 1, 'g': 2, 'f': 3}
MALE_BIT = 0x8000
FRAME = re.compile(r'^s?([mf][hbgef])(\d{5})l?\.img$', re.I)


def identity(row):
    prefix = row['file'][:2]
    kind, part = prefix[0], prefix[1]
    category = CATEGORY[part]
    gender = 2 if category == 3 else (0 if kind == 'm' else 1)
    slot_name = SLOT_NAME[part]
    return dict(
        key=f'xfs:{gender}:{category}:{row["id"]}',
        dat=row['file'],
        slot=SLOT_INDEX[slot_name],
        slot_name=slot_name,
        gender=gender,
        id=row['id'],
        name=row['name'],
        description=row['description'],
        buyable=row['buyable'],
        gold=row['gold'],
        cash=row['cash'],
        stats=row['stats'],
        bonuses=[row['stats'][name] for name in BONUS_ORDER],
    )


def unlisted_graphics(records):
    """Frames present in graphics.xfs whose id is not a DAT record."""
    if not GRAPHICS.is_file():
        return []
    known = {(row['dat'][:2], row['id']) for row in records}
    names = json.loads(GRAPHICS.read_text())
    extra = []
    for name in names:
        match = FRAME.match(name)
        if not match:
            continue
        prefix, number = match.group(1).lower(), int(match.group(2))
        if (prefix, number) not in known:
            extra.append(name)
    return sorted(extra, key=str.lower)


def build(avatar_path=AVATAR, catalog_path=CATALOG, out_path=OUTPUT):
    rows = avatar_rows(avatar_path.read_bytes())
    records = [identity(row) for row in rows]
    catalog = json.loads(catalog_path.read_text())
    by_key = {row['key']: row for row in catalog['records']}
    if [row['key'] for row in records] != [row['key'] for row in catalog['records']]:
        raise SystemExit('Classic record order diverges from the art catalog')
    for row in records:
        current = by_key[row['key']]
        for left, right in (
            (row['name'], current['name']),
            (row['description'], current['description']),
            (row['buyable'], current['buyable']),
            (row['gold'], current['gold_price']),
            (row['cash'], current['cash_price']),
            (row['stats'], current['native_stats']),
            (row['bonuses'], current['bonuses']),
            (row['id'], current['id']),
            (row['gender'], current['gender']),
        ):
            if left != right:
                raise SystemExit(f'{row["key"]} diverges: {left!r} != {right!r}')
    data = dict(
        version=1,
        xfs_version=280,
        string_encoding='cp949',
        avatar_xfs_sha256=hashlib.sha256(avatar_path.read_bytes()).hexdigest(),
        sources=dict(
            launcher='jglim/gunbound-launcher TestClient/avatar.xfs version 280',
            server='jglim/gunbound-server GunBoundServer/gameserver.py',
            stat_layout='CarlosX/Img-Tools-Gunbound AvatarInfoProcessor',
        ),
        stat_order=STAT_NAMES,
        bonus_order=BONUS_ORDER,
        slots=['body', 'head', 'eye', 'flag'],
        equipped_order=['body', 'head', 'eye', 'flag'],
        gender_bit=MALE_BIT,
        empty_flag_word=0,
        internal_category=['head', 'body', 'eye', 'flag'],
        empty_dats=['ff.dat'],
        unlisted_graphics=unlisted_graphics(records),
        records=records,
    )
    out_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    print(f'Wrote {len(records)} classic records to {out_path.relative_to(ROOT)}')
    return data


if __name__ == '__main__':
    build()
