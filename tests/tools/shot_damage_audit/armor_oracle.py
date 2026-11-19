"""Run the pinned Armor T1 numeric consumers with a controlled Bigfoot body."""

import argparse
import importlib.util
import json
from hashlib import sha256
from pathlib import Path
from struct import iter_unpack

ROOT = Path(__file__).resolve().parents[3]
ICE_PATH = ROOT / "tests/tools/ice_oracle/generate.py"


def armor_t1(ice, dx, dy, attack=0, vulnerability=100, force=0, material=0):
    machine, world = ice.machine()
    shell = machine.alloc(0x5000)
    for index, value in enumerate(ice.character_rows()[0]):
        machine.setcell(world + 0xF0384 + index * 0x224, value)
    machine.w8(shell + 0x3C, 0)
    machine.setcell(world + 0x50688, attack)
    machine.setcell(world + 0x50464, 0)
    machine.call(0x41DA80, args=[world, shell, 0, 1, 0], ecx=0)

    actor = ice.target(machine, [0, 0, 0, 0], source_type=4, hp=1100)
    machine.setcell(actor + 0x6520, vulnerability)
    machine.setcell(actor + 0x13C0, 2)  # 24-pixel body, bottom offset 2
    machine.set_flag(actor + 0x9CE4, True)  # defense bit 8
    machine.setcell(shell + 0x17E4, 100)
    machine.setcell(shell + 0x15C0, force)
    machine.setcell(world + 0x475C8, 0)
    machine.setcell(world + 0x1A1F48, material)
    machine.setcell(world + 0x45354, 0)  # SOLO

    # Fix tilt at zero and stub damage text. Damage and HP writes run in the PE.
    machine.hook_fn(0x45F300, lambda _: 0, pop=4)
    machine.hook_fn(0x45F5D0, lambda _: 0)
    machine.hook_fn(0x436860, lambda _: 0, pop=8)
    amounts = []
    machine.watch[0x45E758] = lambda em: amounts.append(em.uc.reg_read(ice.emu.UC_X86_REG_EBX))
    machine.call(0x45DB20, args=[actor, 200 - dx, 187 - dy, 0, 0], ecx=shell)
    assert not machine.unmapped
    return {
        "dx": dx, "dy": dy, "attack": attack, "vulnerability": vulnerability,
        "force": force, "material": material,
        "power": [machine.getcell(shell + offset) for offset in (0x1E54, 0x2078, 0x229C)],
        "dimension": machine.getcell(shell + 0x24C0),
        "aspect": machine.getcell(shell + 0x2B2C),
        "amount": amounts[0] if amounts else 0,
        "hp": machine.getcell(actor + 0x6968),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("client_dir", type=Path, help="Local directory containing the pinned PE and DAT")
    client = parser.parse_args().client_dir.resolve()
    spec = importlib.util.spec_from_file_location("ice_oracle", ICE_PATH)
    ice = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ice)
    ice.emu.PE = str(client / "GunBound.gme")
    raw = (client / "characterdata.dat").read_bytes()
    assert sha256(raw).hexdigest() == ice.DAT_SHA
    rows = tuple(iter_unpack("<83i", ice.xfs.lzhuf(raw, 16 * 332)))
    ice.character_rows = lambda: rows
    results = [armor_t1(ice, 0, 0, material=material) for material in range(3)]
    vectors = ((1, 0), (20, 0), (23, 16), (63, 0), (64, 0), (0, 0, 50),
               (0, 0, 50, 60), (0, 0, 50, 100, 100))
    results.extend(armor_t1(ice, *vector) for vector in vectors)
    print(json.dumps({"pe_sha256": ice.SHA, "dat_sha256": ice.DAT_SHA, "cases": results}, indent=2))


if __name__ == "__main__":
    main()
