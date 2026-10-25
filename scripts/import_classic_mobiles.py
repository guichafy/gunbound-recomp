"""Extract original Thor's Hammer sheets for the mobiles still missing in Godot.

Mage (tank2), Nak (tank3) and Bigfoot (tank5) already have their own atlases.
This importer follows scripts/import_nak_assets.py: unchanged pixels, hotspot
origin, 20 columns, frames.json with the .epa pose lists.

    python3 scripts/import_classic_mobiles.py
"""
import hashlib
import json
import shutil
import argparse
import struct
import wave
from pathlib import Path

from PIL import Image

import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / ".tools" / "gunbound-client" / "graphics.xfs"
ARCHIVE_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
AUDIO = ROOT / ".tools" / "source-assets" / "content" / "Audio" / "SFX" / "Tank"
CROSS = ROOT / ".tools" / "source-assets" / "content" / "Interface" / "InGame" / "HUD" / "Crosshair"
HUD = ROOT / "assets" / "openbound" / "hud"

# folder, graphics tank index (client id + 1), crosshair/sound prefix
MOBILES = [
    ("armor", 1, "Armor"),
    ("trico", 4, "Trico"),
    ("boomer", 6, "Boomer"),
    ("raon", 7, "Raon"),
    ("lightning", 8, "Lightning"),
    ("jd", 9, "JD"),
    ("asate", 10, "ASate"),
    ("ice", 11, "Ice"),
    ("turtle", 12, "Turtle"),
    ("grub", 13, "Grub"),
    # These three files are Dragon, Knight and Aduka. Kalsiddon and J.Frog
    # are not in this graphics.xfs.
    ("dragon", 14, "Dragon"),
    ("knight", 15, "Knight"),
    ("aduka", 16, "Aduka"),
]
POSES = {
    "idle": "normal", "idle_low": "wnormal", "moving": "move", "moving_low": "wmove",
    "charging_0": "bfire1", "charging_1": "bfire2", "charging_2": "bsfire",
    "recoil_0": "fire1", "recoil_1": "fire2", "recoil_2": "sfire",
    "hurt": "fdamage", "hurt_2": "bdamage", "falling": "drop", "destroyed": "dead",
    "unable": "unmove", "using_item": "item", "shock": "shock",
}
COLUMNS = 20


def pack(frames, columns):
    left = min(frame["hx"] for frame in frames)
    top = min(frame["hy"] for frame in frames)
    cell = (max(frame["hx"] + frame["w"] for frame in frames) - left,
            max(frame["hy"] + frame["h"] for frame in frames) - top)
    rows = (len(frames) + columns - 1) // columns
    sheet = Image.new("RGBA", (max(cell[0], 1) * columns, max(cell[1], 1) * rows))
    for index, frame in enumerate(frames):
        corner = ((index % columns) * cell[0] + frame["hx"] - left,
                  (index // columns) * cell[1] + frame["hy"] - top)
        sheet.paste(frame["image"], corner)
    return sheet, cell, [-left, -top]


def first_entry(toc, names):
    for name in names:
        if name in toc:
            return name
    return ""


def sheet_names(number, slot):
    """Body image candidates for S1/S2/SS. Some mobiles only ship the glow layer."""
    if slot == 1:
        return [f"bullet{number}n.img", f"bullet{number}nl.img"]
    if slot == 2:
        return [f"bullet{number}s.img", f"bullet{number}sl.img"]
    return [f"bullet{number}p.img", f"bullet{number}pl.img"]


def light_names(number, slot):
    if slot == 1:
        return [f"bullet{number}nl.img"]
    if slot == 2:
        return [f"bullet{number}sl.img"]
    return [f"bullet{number}pl.img"]


def table_name(image_name):
    stem = image_name[:-4] if image_name.endswith(".img") else ""
    if stem.startswith("bullet") and stem.endswith("l"):
        stem = stem[:-1]
    return stem + ".epa" if stem else ""


def save_sheet(toc, path, entry, columns, meta, label):
    if not entry:
        return
    raw = xfs.read_entry(path, toc[entry])
    frames = xfs.frames(raw)
    image, cell, origin = pack(frames, columns)
    image.save(meta["dir"] / label)
    info = {"entry": entry, "frames": len(frames), "columns": columns, "cell": list(cell), "origin": origin,
            "entry_sha256": hashlib.sha256(raw).hexdigest()}
    table = table_name(entry)
    if table in toc:
        states, _ = xfs.parse_epa(xfs.read_entry(path, toc[table]))
        info["states"] = {state["name"]: state["frames"] for state in states}
        info["durations"] = {state["name"]: state["durations"] for state in states}
        info["epa"] = table
    meta["sheets"][label] = info


def copy_audio(folder, prefix):
    out = ROOT / "assets" / "openbound" / folder
    for kind, src_dir, dest in (("Shoot", AUDIO / "Shoot", "Shoot"), ("Blast", AUDIO / "Blast", "Blast")):
        for shot in ("S1", "S2", "SS"):
            source = src_dir / f"{prefix if prefix != 'Raon' else 'RaonLauncher'}{shot}.mp3"
            if source.exists():
                shutil.copyfile(source, out / f"{dest}{shot}.mp3")


def copy_crosshairs(prefix):
    for shot in ("S1", "S2", "SS"):
        for side in ("Ally", "Enemy"):
            source = CROSS / f"{prefix}{shot}{side}.png"
            if source.exists():
                shutil.copyfile(source, HUD / f"Crosshair{prefix}{shot}{side}.png")


def import_manifest(matrix_path, sound_archive, water_path):
    matrix = json.loads(matrix_path.read_text())
    sound_toc = {entry["name"]: entry for entry in xfs.read_toc(sound_archive)}
    if hashlib.sha256(sound_archive.read_bytes()).hexdigest() != matrix["source_archives"]["sound.xfs"]:
        raise SystemExit("unexpected sound.xfs")
    folder = ROOT / "assets/openbound/classic"
    folder.mkdir(parents=True, exist_ok=True)
    for record in matrix["records"]:
        for role in ("fire", "blast"):
            entry = record["sounds"][role]
            entry["resource"] = ""
            if not entry["present"]:
                continue
            raw = xfs.read_entry(sound_archive, sound_toc[entry["entry"]])
            if hashlib.sha256(raw).hexdigest() != entry["sha256"]:
                raise SystemExit("unexpected sound bytes")
            fmt, channels, rate, _, align, bits = struct.unpack_from("<HHIIHH", raw)
            if fmt != 1 or align != channels * bits // 8:
                raise ValueError("unsupported XES PCM")
            destination = folder / (Path(entry["entry"]).stem + ".wav")
            with wave.open(str(destination), "wb") as stream:
                stream.setnchannels(channels)
                stream.setsampwidth(bits // 8)
                stream.setframerate(rate)
                stream.writeframes(raw[16:])
            entry["resource"] = "res://" + str(destination.relative_to(ROOT))
    (folder / "shot_timing.json").write_text(json.dumps(matrix, indent=2) + "\n")
    shutil.copyfile(water_path, folder / "WaterEffect.png")
    lines = ["# Matriz audiovisual original — 48 combinações", "",
             "Gerada de graphics.xfs, sound.xfs, EPA e MainAction do cliente. Tipos13/14/15 são Dragon/Knight/Aduka.",
             "Fonte completa com hashes, durações e endereços: `assets/openbound/classic/shot_timing.json`.",
             "Matriz de evidência preenchida; paridade audiovisual integral ainda não validada (partículas Dragon, estágios secundários SS e satélites).", "",
             "| ID / mobile | Arma / tipo | Tank / EPA | Corpo / luz | Impacto / secundário | Spawn ticks × componentes | Pose ticks | Fire / blast | Evidência |",
             "|---|---|---|---|---|---|---|---|---|"]
    for r in matrix["records"]:
        def names(entries):
            return ", ".join(e["entry"] + (" (ausente)" if not e.get("present", False) else "") for e in entries if e["entry"].endswith(".img")) or "—"
        def audio(role):
            a = r["sounds"][role]
            return a["entry"] + (" (silêncio: ausente)" if not a["present"] else "")
        body = (r.get("projectile") or {}).get("entry", "invisível" if r["kind"] == "dragon" and r["weapon"] < 2 else "ausente")
        light = (r.get("projectile_light") or {}).get("entry", "—")
        events = ", ".join(f"{t}×{n}" for t,n in zip(r["spawn_ticks"],r["components_per_spawn"]))
        lines.append(f"| {r['game_id']} {r['kind']} | {r['slot']} / {r['client_type']} | {r['tank_img']['entry']} / {r['pose_state']} | {body} / {light} | {names(r['impact'])} / {names(r['secondary_impact'])} | {events} | {r['pose_ticks']} | {audio('fire')} / {audio('blast')} | {'; '.join(r['sources'])} |")
    lines += ["", "Hashes XFS: " + json.dumps(matrix["source_archives"]), "",
              "Turtle S1/S2: WaterEffect original, histórico16, largura±16, UVfase8, alpha4bit15−segmento; suprime corpo Armor-like. PE0x4b2aa0/0x4b30e0/0x4c480c.",
              "Glow único usa EPA base sem L. Dragon bullet14c/cl é reservado aos filhos SS. Flames primários e ssflame são metadados distintos; somente ativação secundária já comprovada é desenhada.",
              "ASate tanque102fire/101blast; satélite tem sons próprios, porte posterior. Knight151blast/Aduka23blast ausentes preservam silêncio."]
    (ROOT / "docs/sdd/BATTLE_ASSET_MATRIX.md").write_text("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only")
    parser.add_argument("--matrix", type=Path)
    parser.add_argument("--sound", type=Path)
    parser.add_argument("--water", type=Path)
    args = parser.parse_args()
    if args.matrix:
        import_manifest(args.matrix, args.sound, args.water)

    digest = hashlib.sha256(ARCHIVE.read_bytes()).hexdigest()
    if digest != ARCHIVE_SHA:
        raise SystemExit("unexpected graphics.xfs")
    toc = {entry["name"]: entry for entry in xfs.read_toc(ARCHIVE)}
    for folder, number, prefix in MOBILES:
        if args.only and folder != args.only:
            continue
        out = ROOT / "assets" / "openbound" / folder
        out.mkdir(parents=True, exist_ok=True)
        raw = xfs.read_entry(ARCHIVE, toc[f"tank{number}.img"])
        frames = xfs.frames(raw)
        image, cell, origin = pack(frames, COLUMNS)
        image.save(out / "CharacterSpritesheet.png")
        states, _ = xfs.parse_epa(xfs.read_entry(ARCHIVE, toc[f"tank{number}.epa"]))
        by_name = {state["name"]: state["frames"] for state in states}
        pose_durations = {pose: state["durations"] for pose, source in POSES.items() for state in states if state["name"] == source}
        poses = {pose: by_name[state] for pose, state in POSES.items() if state in by_name and by_name[state]}
        rider = [[frame["extra"][2] + frame["hx"], frame["extra"][3] + frame["hy"]] for frame in frames]
        meta = {"dir": out, "sheets": {}}
        for slot, label in ((1, "Bullet1.png"), (2, "Bullet2.png"), (3, "Bullet3.png")):
            save_sheet(toc, ARCHIVE, first_entry(toc, sheet_names(number, slot)), 8, meta, label)
            body = meta["sheets"].get(label, {}).get("entry", "")
            light = first_entry(toc, light_names(number, slot))
            if light != body:
                save_sheet(toc, ARCHIVE, light, 8, meta, label.replace(".png", "Light.png"))
        if number == 7:
            for entry, label in [("rayonmine.img","Mine.png"),("rayonminel.img","MineLight.png"),("srayonmine.img","MineSS.png"),("crystal.img","crystal.png")]:
                save_sheet(toc, ARCHIVE, first_entry(toc,[entry]),8,meta,label)
        if number in (12, 14):
            save_sheet(toc, ARCHIVE, first_entry(toc, [f"bullet{number}c.img"]), 8, meta, "SSChild.png")
            save_sheet(toc, ARCHIVE, first_entry(toc, [f"bullet{number}cl.img"]), 8, meta, "SSChildLight.png")
        for slot, label in ((1, "Flame1.png"), (2, "Flame2.png"), (3, "Flame3.png")):
            flame = first_entry(toc, [f"flame{number}{slot}.img"])
            save_sheet(toc, ARCHIVE, flame, 6, meta, label)
        save_sheet(toc, ARCHIVE, first_entry(toc, [f"ssflame{number}.img"]), 6, meta, "SSFlame.png")
        # Precomputed contact works identically in an imported PCK without raw PNG.
        idle_frame = frames[poses["idle"][0]]
        alpha_box = idle_frame["image"].getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
        feet = idle_frame["hy"] + alpha_box[3] - 1 if alpha_box else 0
        info = {
            "contact_feet": feet,
            "pose_durations": pose_durations,
            "projectile_composition": ["water_ribbon", "water_ribbon", "sprite"] if number == 12 else (["particles", "particles", "sprite"] if number == 14 else ["sprite"] * 3),
            "source": "jglim/gunbound-launcher TestClient/graphics.xfs",
            "archive_sha256": ARCHIVE_SHA,
            "tank": number,
            "cell": list(cell),
            "origin": origin,
            "columns": COLUMNS,
            "poses": poses,
            "rider": rider,
            "hull": frames[poses["idle"][0]]["w"] if "idle" in poses else cell[0],
            "contact": frames[poses["idle"][0]]["h"] if "idle" in poses else cell[1],
            "sheets": meta["sheets"],
        }
        (out / "frames.json").write_text(json.dumps(info))
        (out / "RiderPivot.json").write_text(json.dumps(rider))
        copy_audio(folder, prefix)
        copy_crosshairs(prefix)
        print(folder, "frames", len(frames), "sheets", len(meta["sheets"]))


if __name__ == "__main__":
    main()
