"""Generate isolated Thor's Hammer initialization and common-damage observations.

Run outside Godot with Unicorn 2.1.4 and the original, locally supplied PE/DAT.
No ballistics, weather generation, special-child or item producer is executed.
"""

import argparse
import importlib.util
import itertools
import json
from hashlib import sha256
from pathlib import Path
from struct import iter_unpack

ROOT = Path(__file__).resolve().parents[3]
ICE_PATH = ROOT / "tests/tools/ice_oracle/generate.py"
# Godot IDs 1..16, corresponding to native zero-based types.
NATIVE_TYPES = (1, 4, 2, 0, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
POINTS = (-50, -1, 0, 1, 25, 49, 50)
DAMAGE_COLUMNS = (
    "shooter", "weapon", "target", "attack", "defense", "force", "dx", "dy",
    "material", "shield", "hp", "amount", "hp_after", "shield_after", "protection",
)
# Verified Bigfoot emission divisors and Armor T1 direct one-component case.
# The other raw initializer calls in this probe deliberately use divisor 1.
BIGFOOT_DIVISORS = (4, 6, 8)
MATERIAL_STRIDE = 0x224


def load_helper(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    return helper


def setup(client):
    ice = load_helper("ice_oracle", ICE_PATH)
    pe = client / "GunBound.gme"
    raw = (client / "characterdata.dat").read_bytes()
    if sha256(pe.read_bytes()).hexdigest() != ice.SHA:
        raise ValueError("GunBound.gme does not match the pinned PE")
    if sha256(raw).hexdigest() != ice.DAT_SHA:
        raise ValueError("characterdata.dat does not match the pinned DAT")
    ice.emu.PE = str(pe)
    decoded = ice.xfs.lzhuf(raw, 16 * 332)
    rows = tuple(iter_unpack("<83i", decoded))
    if len(rows) != 16:
        raise ValueError("characterdata.dat did not decode to 16 records")
    return ice, rows


class Oracle:
    def __init__(self, ice, rows):
        self.ice = ice
        self.e, self.world = ice.machine()
        e = self.e
        for kind, row in enumerate(rows):
            for field, value in enumerate(row):
                e.setcell(self.world + 0xF0384 + kind * 0xB1AC + field * MATERIAL_STRIDE, value)
        self.shell = e.alloc(0x5000)
        self.actor = ice.target(e, [0, 0, 0, 0])
        self.actor_vtable = e.r32(self.actor)
        self.transient_heap = e.heap
        self.amounts = []
        # Stub terrain-tilt displacement and visual publication, matching ice_oracle.
        e.hook_fn(0x45F300, lambda _: 0, pop=4)
        e.hook_fn(0x45F5D0, lambda _: 0)
        e.hook_fn(0x436860, lambda _: 0, pop=8)
        e.watch[0x45E758] = lambda em: self.amounts.append(em.uc.reg_read(ice.emu.UC_X86_REG_EBX))
        e.setcell(self.world + 0x475C8, 0)  # Controlled stage index.
        e.setcell(self.world + 0x45354, 0)  # SOLO.
        self.targets = {}
        self.initializers = {}

    def _call(self, va, args, ecx):
        self.e.heap = self.transient_heap
        self.e.call(va, args=args, ecx=ecx)
        if self.e.unmapped or self.e.uc.reg_read(self.ice.emu.UC_X86_REG_EIP) != self.ice.emu.RET_SENTINEL:
            raise ValueError(f"PE routine at {va:#x} did not return cleanly")

    def initialize(self, shooter, weapon, attack):
        key = (shooter, weapon, attack)
        row = self.initializers.get(key)
        if row is None:
            kind = NATIVE_TYPES[shooter - 1]
            divisor = BIGFOOT_DIVISORS[weapon] if shooter == 2 else 1
            e, shell = self.e, self.shell
            e.uc.mem_write(shell, bytes(0x5000))
            e.w8(shell + 0x3C, 0)
            e.setcell(self.world + 0x50688, attack)
            e.setcell(self.world + 0x50464, 0)  # Dig stays fixed.
            self._call(0x41DA80, (self.world, shell, weapon, divisor, weapon == 2), kind)
            row = {
                "shooter": shooter, "weapon": weapon, "source_type": kind,
                "attack": attack, "divisor": divisor,
                "divisor_status": "proved" if shooter == 2 or (shooter, weapon) == (4, 0) else "controlled",
            }
            for name, offset in (("power", 0x1E54), ("dimension", 0x24C0), ("aspect", 0x2B2C)):
                row[name] = [e.getcell(shell + offset + i * MATERIAL_STRIDE) for i in range(3)]
            row["flags"] = sum(
                8 >> i for i in range(4)
                if e.call(0x4065A0, eax=shell + 0x33BC + i * 3) & 0xff
            )
            row["state"] = bytes(e.uc.mem_read(shell, 0x5000))
            self.initializers[key] = row
        return row

    def body(self, target, defense):
        key = (target, defense)
        row = self.targets.get(key)
        if row is None:
            kind = NATIVE_TYPES[target - 1]
            e, actor = self.e, self.actor
            e.uc.mem_write(actor, bytes(0x20000))
            e.w32(actor, self.actor_vtable)
            e.w32(actor + 0x24, kind)
            e.setcell(self.world + 0x508AC, defense)  # Effective defense, slot 0.
            self._call(0x41C360, (self.world, actor), kind)
            row = {
                "target": target, "source_type": kind, "defense": defense,
                "width": e.getcell(actor + 0xD54), "height": e.getcell(actor + 0xF78),
                "bottom": e.getcell(actor + 0x13C0), "vulnerability": e.getcell(actor + 0x6520),
                "flags": sum(
                    8 >> i for i in range(4)
                    if e.call(0x4065A0, eax=actor + 0x9CE4 + i * 3) & 0xff
                ),
            }
            row["state"] = bytes(e.uc.mem_read(actor, 0x20000))
            self.targets[key] = row
        return row

    def hit(self, shot, target, force=0, dx=0, dy=0, material=0, shield=0, hp=1500, protection=False):
        e, shell, actor = self.e, self.shell, self.actor
        e.uc.mem_write(shell, shot["state"])
        e.uc.mem_write(actor, target["state"])
        e.set_flag(actor + 0x908, True)
        e.set_flag(actor + 0xBFF7, False)
        e.set_flag(actor + 0xBFD6, protection)
        e.setcell(actor + 0x90C, 200)
        e.setcell(actor + 0xB30, 200)
        e.setcell(actor + 0x6968, hp)
        e.setcell(actor + 0x6FD4, shield)
        e.setcell(shell + 0x15C0, force)
        e.setcell(shell + 0x17E4, 100)
        e.setcell(self.world + 0x1A1F48, material)
        center = 200 - ((target["height"] - target["bottom"]) // 2 + target["bottom"])
        self.amounts.clear()
        self._call(0x45DB20, (actor, 200 - dx, center - dy, 0, 0), shell)
        amount = self.amounts[0] if self.amounts else 0
        if amount >= 1 << 31:
            amount -= 1 << 32
        return [
            shot["shooter"], shot["weapon"], target["target"], shot["attack"],
            target["defense"], force, dx, dy, material, shield, hp, amount,
            e.getcell(actor + 0x6968), e.getcell(actor + 0x6FD4), protection,
        ]


def focused_armor(oracle):
    # Coordinate replay bridge only: Bigfoot origin (250,474) → center (250,461).
    # Truncating the Godot impact to (237,454) yields offset (13,7).
    neutral = oracle.initialize(4, 0, 0)
    bigfoot = oracle.body(2, 0)
    replay = oracle.hit(neutral, bigfoot, dx=13, dy=7, hp=1100)
    rows = [replay]
    for attack, defense in itertools.product(POINTS, repeat=2):
        shot, target = oracle.initialize(4, 0, attack), oracle.body(2, defense)
        for force in (0, 1, 19, 20, 21, 49, 99, 100):
            rows.append(oracle.hit(shot, target, force, 13, 7, hp=1100))
    for value in range(-50, 51):
        rows.append(oracle.hit(oracle.initialize(4, 0, value), bigfoot))
        rows.append(oracle.hit(neutral, oracle.body(2, value)))
    for material in range(3):
        for dx, dy in ((0, 0), (1, 0), (20, 0), (23, 16), (63, 0), (64, 0), (65, 0)):
            rows.append(oracle.hit(neutral, bigfoot, dx=dx, dy=dy, material=material, hp=1100))
    for shield, hp in itertools.product((0, 100, 210, 300), (1, 1100)):
        rows.append(oracle.hit(neutral, bigfoot, shield=shield, hp=hp))
    rows.append(oracle.hit(neutral, bigfoot, protection=True))
    return replay, rows


def armor_contact(oracle):
    """Feed the historical Godot tick segment to 455cc0 with a controlled target."""
    armor = load_helper("armor_contact", ROOT / "tests/tools/armor_oracle/generate.py")
    # Ghidra RET immediates for the weather query/side-effect stubs.
    pops = {0x436DC0: 12, 0x436EC0: 8, 0x436BD0: 12, 0x4510F0: 4, 0x451030: 4, 0x4511B0: 4}
    armor.pop = pops.__getitem__
    # Translate both endpoints, box and any relevant ground by −200 pixels to
    # fit the reused 400×300 sandbox. The original segment stays above both
    # heights of the historical step, so a flat ground at y=478 suffices here.
    contact = armor.contact_case([60783, 116344 - 200 * 256], [63675, 115858 - 200 * 256],
                                 floor=278, boxes=[[236, 248, 264, 272]])
    x, y = contact["point"]
    point = x, y + 200
    result = oracle.hit(oracle.initialize(4, 0, 0), oracle.body(2, 0),
                        dx=250 - point[0], dy=461 - point[1], hp=1100)
    return {
        "pe_sha256": oracle.ice.SHA, "dat_sha256": oracle.ice.DAT_SHA,
        "scope": "Godot tick segment into 455cc0 with controlled AABB, weather absent.",
        "contact": contact, "original_point": point,
        "native_consumer": dict(zip(DAMAGE_COLUMNS, result)),
    }


def roster_matrix(oracle):
    for shooter, weapon, target in itertools.product(range(1, 17), range(3), range(1, 17)):
        neutral, defender = oracle.initialize(shooter, weapon, 0), oracle.body(target, 0)
        radius = neutral["dimension"][0] // 2 + 10
        for dx, dy in ((0, 0), (10, 5), (0, radius - 1), (0, radius), (0, radius + 1), (128, 128)):
            yield oracle.hit(neutral, defender, dx=dx, dy=dy)
        for attack, defense, force in itertools.product(POINTS, POINTS, (0, 100)):
            if (attack, defense, force) == (0, 0, 0):
                continue  # Already observed at the center above.
            shot = oracle.initialize(shooter, weapon, attack)
            yield oracle.hit(shot, oracle.body(target, defense), force=force)
        yield oracle.hit(neutral, defender, protection=True)


def signed_axis_matrix(oracle):
    """Sweep one signed attribute at a time for each raw weapon state."""
    for shooter, weapon in itertools.product(range(1, 17), range(3)):
        neutral = oracle.initialize(shooter, weapon, 0)
        target = oracle.body(2, 0)
        for value in range(-50, 51):
            yield oracle.hit(oracle.initialize(shooter, weapon, value), target)
            yield oracle.hit(neutral, oracle.body(2, value))

def serializable(rows):
    return [{key: value for key, value in row.items() if key != "state"} for row in rows]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("client_dir", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    scope = parser.add_mutually_exclusive_group()
    scope.add_argument("--armor-only", action="store_true")
    scope.add_argument("--armor-contact-only", action="store_true")
    scope.add_argument("--signed-axes-only", action="store_true")
    args = parser.parse_args()
    ice, rows = setup(args.client_dir)
    oracle = Oracle(ice, rows)
    if args.armor_contact_only:
        args.output.write_text(json.dumps(armor_contact(oracle), separators=(",", ":")) + "\n")
        return
    replay, armor = focused_armor(oracle)
    matrix = signed_axis_matrix if args.signed_axes_only else roster_matrix
    common = [] if args.armor_only else list(matrix(oracle))
    result = {
        "schema": 1,
        "pe_sha256": ice.SHA, "dat_sha256": ice.DAT_SHA,
        "routines": ["41c360", "41da80", "45db20"],
        "stubs": ["protected-cell allocator and seed", "critical section IAT",
                  "zero tilt 45f300/45f5d0", "damage text 436860 and pose publication"],
        "scope": "Direct x86 consumers with controlled contact, Force and protection. No game/trajectory replay.",
        "initializers": serializable(oracle.initializers.values()),
        "targets": serializable(oracle.targets.values()),
        "armor_replay": dict(zip(DAMAGE_COLUMNS, replay)),
        "damage": {"columns": DAMAGE_COLUMNS, "armor": armor, "rows": common},
    }
    args.output.write_text(json.dumps(result, separators=(",", ":")) + "\n")
    print(f"Observed {len(armor)} Armor and {len(common)} common damage cases")


if __name__ == "__main__":
    main()
