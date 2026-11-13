"""Read-only PE checks for issue46; no Godot or runtime implementation imports."""
import argparse
import hashlib
import json
import struct
from pathlib import Path


def extract(path):
    data = path.read_bytes()
    expected = json.loads((Path(__file__).parent / "sources.json").read_text())["GunBound.gme"]
    if hashlib.sha256(data).hexdigest() != expected:
        raise ValueError("PE SHA-256 mismatch")
    pe = struct.unpack_from("<I", data, 60)[0]
    table = pe + 24 + struct.unpack_from("<H", data, pe + 20)[0]
    sections = [struct.unpack_from("<4I", data, table + 40 * i + 8)
                for i in range(struct.unpack_from("<H", data, pe + 6)[0])]

    def read(va, size):
        for _, rva, length, offset in sections:
            delta = va - 0x400000 - rva
            if 0 <= delta and delta + size <= length:
                return data[offset + delta:offset + delta + size]
        raise ValueError(f"Unmapped VA {va:x}")

    # Confirm instruction opcodes, then decode the immediate operands directly.
    key_ins = read(0x40a44e, 6)
    assert key_ins[:2] == bytes.fromhex("81f6")
    key = struct.unpack_from("<I", key_ins, 2)[0]
    values = []
    for va in [0x47a328, 0x47a340, 0x47a358, 0x47a370]:
        ins = read(va, 5)
        assert ins[0] == 0xb8
        value = struct.unpack_from("<I", ins, 1)[0] ^ key
        values.append(value if value < 2**31 else value - 2**32)
    assert read(0x40daa2, 2) == bytes.fromhex("6a64")
    assert read(0x47a66c, 9) == bytes.fromhex("66c780d40400000042")
    assert values == [25, 10, 5, -5]
    return {"pe_sha256": expected, "xor_key": hex(key), "team_score_by_type": values,
            "startup_score_limit": 100, "end_command": "0x4200",
            "derivation": "PE instructions; not a run of the client or a damage oracle"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pe", type=Path)
    args = parser.parse_args()
    print(json.dumps(extract(args.pe), indent=2))
