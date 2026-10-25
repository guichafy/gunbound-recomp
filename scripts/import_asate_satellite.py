"""Extract ASate Ion emission PCM from the pinned native sound.xfs.

Run: python3 scripts/import_asate_satellite.py [--archive /path/sound.xfs]
10s3fire.xes is absent in this package; its missing state is recorded, not filled.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import wave

import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA = "081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023"
PE_SHA = "4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde"
DEFAULT_ARCHIVE = Path("/Users/guichafy/Workspaces/GunboundClassic/gunbound-launcher/TestClient/sound.xfs")
EXPECTED = {
    "10s1fire.xes": "2300d4652a3e9814f519b9858c38298f653efcb986271296387315f2185edd9b",
    "10s2fire.xes": "6de236b4088f4351df49eb341745417eb9a8d8b8814df842edf729e09fc5f077",
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def pcm(raw):
    if len(raw) < 16:
        raise ValueError("incomplete XES PCM header")
    fmt, channels, rate, byte_rate, align, bits = struct.unpack_from("<HHIIHH", raw)
    if fmt != 1 or channels < 1 or bits not in (8, 16, 24, 32) or align != channels * bits // 8:
        raise ValueError("unsupported XES PCM")
    if byte_rate != rate * align or (len(raw) - 16) % align:
        raise ValueError("inconsistent XES PCM length/rate")
    return channels, rate, bits, raw[16:]


def extract(archive, output):
    archive = Path(archive)
    output = Path(output)
    if sha(archive.read_bytes()) != SOURCE_SHA:
        raise ValueError("unexpected sound.xfs identity")
    toc = {entry["name"]: entry for entry in xfs.read_toc(archive)}
    output.mkdir(parents=True, exist_ok=True)
    records = []
    for number in range(1, 4):
        entry_name = f"10s{number}fire.xes"
        record = {"weapon": number - 1, "entry": entry_name, "present": entry_name in toc,
                  "resource": "", "string_va": f"0x{[0x556140, 0x556130, 0x556150][number-1]:08x}",
                  "trigger": "Ion emission, once per emitted child"}
        if entry_name not in toc:
            record["reason"] = "PE references this name; entry absent from the pinned sound.xfs TOC"
            if (output / f"Satellite{number}.wav").exists():
                raise ValueError("missing source must not have a fabricated Satellite WAV")
            records.append(record)
            continue
        raw = xfs.read_entry(archive, toc[entry_name])
        if sha(raw) != EXPECTED[entry_name]:
            raise ValueError("unexpected original XES bytes")
        channels, rate, bits, payload = pcm(raw)
        destination = output / f"Satellite{number}.wav"
        with wave.open(str(destination), "wb") as stream:
            stream.setnchannels(channels)
            stream.setsampwidth(bits // 8)
            stream.setframerate(rate)
            stream.writeframes(payload)
        record.update({"resource": f"res://assets/openbound/asate/{destination.name}",
                       "source_sha256": sha(raw), "pcm_sha256": sha(payload),
                       "wav_sha256": sha(destination.read_bytes()), "pcm_bytes": len(payload),
                       "channels": channels, "sample_rate": rate, "bits": bits,
                       "frames": len(payload) // (channels * bits // 8)})
        records.append(record)
    manifest = {"version": 1, "source": "jglim/gunbound-launcher TestClient/sound.xfs",
                "source_archive_sha256": SOURCE_SHA, "source_pe_sha256": PE_SHA,
                "consumer_va": "0x00480310", "play_helper_va": "0x004ee9b0",
                "conversion": "XES WAVEFORMAT16 header removed; PCM bytes copied unchanged into WAV",
                "records": records}
    (output / "satellite_audio.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE)
    parser.add_argument("--output", type=Path, default=ROOT / "assets/openbound/asate")
    args = parser.parse_args()
    manifest = extract(args.archive, args.output)
    for record in manifest["records"]:
        print(record["entry"], record["resource"] or "ABSENT (silence)")
