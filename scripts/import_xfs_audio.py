"""Extract original Thor’s Hammer sound.xfs without transcoding MP3 or PCM.

XES consists of the 16-byte PCM format header (not an 18-byte WAVEFORMATEX)
followed by interleaved samples. A RIFF container is added, leaving PCM exact.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import struct
import wave

import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA = "081c1b9f5751c486512a9df1a894f6db7a5ed891b8ebdad9fbce1b9169901023"
DEFAULT_SOURCE = ROOT / ".tools/gunbound-client/sound.xfs"
OUTPUT = ROOT / "assets/xfs/audio"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def xes_wave(raw):
    if len(raw) < 16:
        raise ValueError("truncated XES format")
    fmt, channels, rate, byte_rate, align, bits = struct.unpack_from("<HHIIHH", raw)
    if (fmt, channels, rate, byte_rate, align, bits) != (1, 2, 22050, 88200, 4, 16):
        raise ValueError("unexpected XES PCM format")
    pcm = raw[16:]
    if len(pcm) % align:
        raise ValueError("partial XES sample frame")
    destination = io.BytesIO()
    with wave.open(destination, "wb") as stream:
        stream.setnchannels(channels)
        stream.setsampwidth(bits // 8)
        stream.setframerate(rate)
        stream.writeframes(pcm)
    return destination.getvalue(), {"channels": channels, "rate": rate, "bits": bits,
        "frames": len(pcm) // align, "pcm_sha256": sha(pcm)}


def extract(source=DEFAULT_SOURCE, output=OUTPUT):
    source, output = Path(source), Path(output)
    archive_sha = sha(source.read_bytes())
    if archive_sha != SOURCE_SHA:
        raise ValueError("unexpected sound.xfs hash: " + archive_sha)
    records = []
    payloads = []
    for entry in xfs.read_toc(source):
        name = entry["name"]
        if Path(name).name != name or Path(name).suffix not in (".mp3", ".xes"):
            raise ValueError("unexpected audio entry: " + name)
        raw = xfs.read_entry(source, entry)
        record = {"entry": name, "offset": entry["offset"], "size": len(raw),
            "entry_sha256": sha(raw), "present": True}
        if name.endswith(".xes"):
            payload, parameters = xes_wave(raw)
            filename = Path(name).stem + ".wav"
            record.update(parameters)
            record["encoding"] = "pcm_s16le"
        else:
            payload, filename = raw, name
            record["encoding"] = "mp3_passthrough"
        record.update({"file": filename, "resource": "res://assets/xfs/audio/" + filename,
            "file_sha256": sha(payload), "file_size": len(payload)})
        records.append(record)
        payloads.append((filename, payload))
    if len(records) != 96 or sum(r["encoding"] == "mp3_passthrough" for r in records) != 11:
        raise ValueError("unexpected sound.xfs inventory")
    output.mkdir(parents=True, exist_ok=True)
    for filename, payload in payloads:
        (output / filename).write_bytes(payload)
        if filename.endswith(".wav"):
            # Default Godot QOA compression changes PCM. Preserve existing UIDs
            # and import settings, but require the uncompressed original payload.
            sidecar = output / (filename + ".import")
            if sidecar.exists():
                settings = sidecar.read_text()
                if "compress/mode=" in settings:
                    settings = re.sub(r"compress/mode=\d+", "compress/mode=0", settings)
                else:
                    if "[params]" not in settings:
                        settings += "\n[params]\n"
                    settings += "\ncompress/mode=0\n"
            else:
                settings = '[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n\n[params]\ncompress/mode=0\n'
            sidecar.write_bytes(settings.encode("utf-8"))
    catalog = {"schema": 1, "source": "jglim/gunbound-launcher/TestClient/sound.xfs",
        "source_commit": "2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1", "source_sha256": archive_sha,
        "records": records,
        "battle_playlist": ["stage%d.mp3" % n for n in range(1, 7)],
        "scheduling": "adaptation: random stage1..6 on battle start and each finished track; sudden is not scheduled"}
    (output / "catalog.json").write_bytes((json.dumps(catalog, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
    return catalog


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    catalog = extract(args.source, args.output)
    print("Original client audio: %d entries (11 MP3 / 85 PCM WAV)" % len(catalog["records"]))
