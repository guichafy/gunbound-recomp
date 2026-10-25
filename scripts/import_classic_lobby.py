"""Extract the classic lobby and ready-room chrome from graphics.xfs.

    python3 scripts/import_classic_lobby.py [--xfs .tools/gunbound-client/graphics.xfs]

Writes horizontal EPA strips under assets/classic/lobby and assets/classic/room,
plus assets/classic/manifest.json. Does not copy the archive and does not
export Buddy. Rank/GP on the lobby are the local level and XP; that note lives
in the manifest and in ADR-096.
"""
import argparse
import hashlib
import json
from collections import Counter, deque
from pathlib import Path

from PIL import Image

import gunbound_xfs as xfs

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "classic"
ARCHIVE_SHA = "a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08"
NEAREST = getattr(getattr(Image, "Resampling", Image), "NEAREST")
# ready, mouse, push, disable — img indices, which match the EPA states.
EPA4 = [0, 1, 2, 3]
EPA4_NAMES = ["ready", "mouse", "push", "disable"]
# Filter buttons add frame 4 = active. directgo's EPA omits the state; the
# request still treats frame 4 as active.
EPA5 = [0, 1, 2, 3, 4]
EPA5_NAMES = ["ready", "mouse", "push", "disable", "active"]
# b_ready_start.epa: normal 0, hover 1, push 6, disable 9 (first frame of each).
START = [0, 1, 6, 9]


def find_default_xfs():
    for base in [ROOT, *ROOT.parents]:
        candidate = base / ".tools" / "gunbound-client" / "graphics.xfs"
        if candidate.exists():
            return candidate
    return ROOT / ".tools" / "gunbound-client" / "graphics.xfs"


def entry_bytes(path, toc, name):
    if name not in toc:
        raise SystemExit("missing graphics.xfs entry %s" % name)
    return xfs.read_entry(path, toc[name])


def strip_image(frames, indices):
    chosen = [frames[index] for index in indices]
    cell_w = max(frame["w"] for frame in chosen)
    cell_h = max(frame["h"] for frame in chosen)
    sheet = Image.new("RGBA", (cell_w * len(chosen), cell_h), (0, 0, 0, 0))
    for offset, frame in enumerate(chosen):
        sheet.paste(frame["image"], (offset * cell_w, 0))
    return sheet, [cell_w, cell_h]


def save_strip(path, toc, spec, manifest):
    name, folder, indices, order, note = spec
    img_name = name + ".img"
    raw = entry_bytes(path, toc, img_name)
    frames = xfs.frames(raw)
    sheet, cell = strip_image(frames, indices)
    relative = "%s/%s.png" % (folder, name)
    sheet.save(OUT / relative)
    record = {
        "file": relative,
        "entry": img_name,
        "entry_sha256": hashlib.sha256(raw).hexdigest(),
        "img_indices": list(indices),
        "order": list(order),
        "frame_size": cell,
        "frames": len(indices),
    }
    epa_name = name + ".epa"
    if epa_name in toc:
        states, _end = xfs.parse_epa(entry_bytes(path, toc, epa_name))
        record["epa"] = epa_name
        record["epa_states"] = {state["name"]: state["frames"] for state in states}
    if note:
        record["note"] = note
    manifest["strips"][name] = record
    print("%s %dx%d x%d" % (relative, cell[0], cell[1], len(indices)))


def save_still(path, toc, img_name, folder, file_name, frame_index, manifest, key):
    raw = entry_bytes(path, toc, img_name)
    frames = xfs.frames(raw)
    image = frames[frame_index]["image"]
    relative = "%s/%s" % (folder, file_name)
    image.save(OUT / relative)
    manifest["images"][key] = {
        "file": relative,
        "entry": img_name,
        "frame": frame_index,
        "entry_sha256": hashlib.sha256(raw).hexdigest(),
        "size": [image.width, image.height],
    }
    print("%s %dx%d" % (relative, image.width, image.height))
    return image


def buddy_fill(lobby):
    """The Buddy hole stays empty. Fill it with the frame color beside it."""
    x0, y0, width, height = 163, 551, 107, 45
    image = Image.new("RGBA", (width, height))
    fallback = (156, 190, 197, 255)
    for y in range(height):
        left = lobby.getpixel((x0 - 1, y0 + y))
        right = lobby.getpixel((x0 + width, y0 + y))
        if left[3] < 200:
            left = fallback
        if right[3] < 200:
            right = fallback
        for x in range(width):
            blend = x / float(width - 1)
            image.putpixel((x, y), tuple(int(round(left[channel] + (right[channel] - left[channel]) * blend)) for channel in range(4)))
    relative = "lobby/buddy_fill.png"
    image.save(OUT / relative)
    return relative, [width, height]


def fit_icon(sprite, limit):
    bbox = sprite.getbbox()
    if bbox is None:
        raise SystemExit("mobile icon cell is empty")
    sprite = sprite.crop(bbox)
    scale = min(limit[0] / float(sprite.width), limit[1] / float(sprite.height))
    size = (max(1, int(round(sprite.width * scale))), max(1, int(round(sprite.height * scale))))
    return sprite.resize(size, NEAREST)


def erase_mobile_glyph(frame):
    """Tira o mobile pintado no botão e conserva a borda.

    b_ready_mobile01 já traz o Armor. Knight e Aduka não têm botão no XFS;
    o glifo precisa sair antes de colar o quadro 0 do atlas, senão o Armor
    continua visível em volta do mobile novo.
    """
    image = frame.convert("RGBA")
    width, height = image.size
    source = image.load()
    infinity = 10 ** 6
    edge = [[infinity] * width for _ in range(height)]
    queue = deque()
    for y in range(height):
        for x in range(width):
            touches = source[x, y][3] < 20
            if not touches:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if not (0 <= nx < width and 0 <= ny < height) or source[nx, ny][3] < 20:
                        touches = True
                        break
            if touches or source[x, y][3] < 20:
                edge[y][x] = 0
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < width and 0 <= ny < height and edge[ny][nx] > edge[y][x] + 1:
                edge[ny][nx] = edge[y][x] + 1
                queue.append((nx, ny))
    rim = 2
    samples = [source[x, y] for y in range(height) for x in range(4, 13) if source[x, y][3] == 255 and edge[y][x] > rim]
    if not samples:
        raise SystemExit("mobile button has no flat fill")
    fill = Counter(samples).most_common(1)[0][0]

    def far(color):
        return max(abs(int(color[channel]) - int(fill[channel])) for channel in range(3)) > 28

    cleaned = image.copy()
    output = cleaned.load()
    for y in range(height):
        for x in range(width):
            if source[x, y][3] <= 20 or edge[y][x] <= rim or not far(source[x, y]):
                continue
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < height and 0 <= nx < width and edge[ny][nx] > rim and source[nx, ny][3] > 20:
                        output[nx, ny] = fill
    return cleaned


def save_composite(base_frames, sheet_path, cell, out_name, manifest):
    sheet = Image.open(sheet_path).convert("RGBA")
    icon = fit_icon(sheet.crop((0, 0, cell[0], cell[1])), (51, 35))
    canvases = []
    for frame in base_frames[:5]:
        canvas = erase_mobile_glyph(frame["image"])
        origin = ((canvas.width - icon.width) // 2, (canvas.height - icon.height) // 2 + 1)
        canvas.alpha_composite(icon, origin)
        canvases.append({"image": canvas, "w": canvas.width, "h": canvas.height})
    image, frame_size = strip_image(canvases, list(range(5)))
    relative = "room/%s.png" % out_name
    image.save(OUT / relative)
    manifest["strips"][out_name] = {
        "file": relative,
        "entry": None,
        "order": ["ready", "mouse", "push", "disable", "active"],
        "img_indices": [0, 1, 2, 3, 4],
        "frame_size": frame_size,
        "frames": 5,
        "note": "Quadro 0 de %s (célula %dx%d) sobre o fundo dos cinco quadros de b_ready_mobile01.img, sem o Armor desse botão. O XFS não tem botão de Knight nem de Aduka; mobile15 é RANDOM e não entra." % (sheet_path.name, cell[0], cell[1]),
        "source_sheet": str(sheet_path.relative_to(ROOT)),
        "source_cell": list(cell),
        "background_entry": "b_ready_mobile01.img",
    }
    print("%s %dx%d x5 (composite)" % (relative, frame_size[0], frame_size[1]))


def expect(image, size, label):
    if image.size != size:
        raise SystemExit("%s is %s, expected %s" % (label, image.size, size))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--xfs", type=Path, default=None)
    archive = parser.parse_args().xfs or find_default_xfs()
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    if digest != ARCHIVE_SHA:
        raise SystemExit("unexpected graphics.xfs %s (want TestClient %s)" % (digest, ARCHIVE_SHA))
    toc = {entry["name"]: entry for entry in xfs.read_toc(archive)}
    (OUT / "lobby").mkdir(parents=True, exist_ok=True)
    (OUT / "room").mkdir(parents=True, exist_ok=True)
    manifest = {
        "source": "jglim/gunbound-launcher TestClient graphics.xfs",
        "archive": "graphics.xfs",
        "archive_sha256": ARCHIVE_SHA,
        "note": "Lobby clássico (gamelist_back, não gamelistmode) e sala (ready_back, não readymode). Buddy não é exportado: o buraco do botão é preenchido com a cor da moldura. Rank e GP do cartão são o nível e o XP locais do perfil, não um rank de servidor. mobile15 (RANDOM) fica de fora.",
        "images": {},
        "strips": {},
    }
    lobby = save_still(archive, toc, "gamelist_back.img", "lobby", "back.png", 0, manifest, "lobby_back")
    chat = save_still(archive, toc, "gamelist_chat.img", "lobby", "chat.png", 0, manifest, "lobby_chat")
    channel = save_still(archive, toc, "gamelist_channel.img", "lobby", "channel.png", 0, manifest, "lobby_channel")
    room = save_still(archive, toc, "ready_back.img", "room", "back.png", 0, manifest, "room_back")
    expect(lobby, (800, 600), "gamelist_back")
    expect(chat, (549, 259), "gamelist_chat")
    expect(channel, (207, 259), "gamelist_channel")
    expect(room, (800, 600), "ready_back")
    if lobby.getpixel((50, 570))[3] != 0:
        raise SystemExit("gamelist_back frame 0 has no transparent button hole")
    fill_file, fill_size = buddy_fill(lobby)
    manifest["images"]["lobby_buddy_fill"] = {
        "file": fill_file,
        "entry": "gamelist_back.img",
        "note": "Amostrado da moldura em volta do buraco x=163 y=551 107×45. Não usa b_gamelist_buddy.",
        "size": fill_size,
    }
    inferred = "Sem .epa no XFS. Quadros na ordem ready/mouse/push/disable vista nos botões EPA."
    specs = [
        ("b_gamelist_exit", "lobby", EPA4, EPA4_NAMES, ""),
        ("b_gamelist_ranking", "lobby", EPA4, EPA4_NAMES, ""),
        ("b_gamelist_avatar", "lobby", EPA4, EPA4_NAMES, ""),
        ("b_gamelist_create", "lobby", EPA4, EPA4_NAMES, ""),
        ("b_gamelist_join", "lobby", EPA4, EPA4_NAMES, ""),
        ("b_gamelist_viewall", "lobby", EPA5, EPA5_NAMES, ""),
        ("b_gamelist_wait", "lobby", EPA5, EPA5_NAMES, ""),
        ("b_gamelist_friend", "lobby", EPA5, EPA5_NAMES, "O quadro active mede 82×33; a tira alinha todos em 82."),
        ("b_gamelist_directgo", "lobby", EPA5, EPA5_NAMES, "O EPA não declara active; o quadro 4 entra assim mesmo, como no pedido."),
        ("b_gamelist_prev", "lobby", EPA4, EPA4_NAMES, ""),
        ("b_gamelist_next", "lobby", EPA4, EPA4_NAMES, ""),
        ("b_ready_exit", "room", EPA4, EPA4_NAMES, ""),
        ("b_ready_changeteam", "room", EPA4, EPA4_NAMES, ""),
        ("b_ready_start", "room", START, EPA4_NAMES, "EPA: normal 0, hover 1, push 6, disable 9. A tira guarda o primeiro quadro de cada estado."),
        ("b_ready_mapprev", "room", EPA4, EPA4_NAMES, inferred),
        ("b_ready_mapnext", "room", EPA4, EPA4_NAMES, inferred),
        ("b_ready_solo", "room", EPA4, EPA4_NAMES, inferred + " Mostrado como modo vigente, sem regra extra."),
    ]
    for index in range(1, 9):
        specs.append(("b_gamechat_ch%d" % index, "lobby", EPA5, EPA5_NAMES, inferred + " Quadro 4 é o canal ativo."))
    for index in range(1, 15):
        specs.append(("b_ready_mobile%02d" % index, "room", EPA5, EPA5_NAMES, inferred + " Quadro 4 é o mobile escolhido."))
    for spec in specs:
        save_strip(archive, toc, spec, manifest)
    mobile_frames = xfs.frames(entry_bytes(archive, toc, "b_ready_mobile01.img"))
    # Room order after Grub is Aduka (b_ready_mobile14), not Dragon.
    # Dragon is tank14 and has no room button in this XFS.
    save_composite(mobile_frames, ROOT / "assets/openbound/dragon/CharacterSpritesheet.png", (82, 76), "b_ready_mobile_dragon", manifest)
    save_composite(mobile_frames, ROOT / "assets/openbound/knight/CharacterSpritesheet.png", (81, 72), "b_ready_mobile_knight", manifest)
    save_composite(mobile_frames, ROOT / "assets/openbound/aduka/CharacterSpritesheet.png", (73, 62), "b_ready_mobile_aduka", manifest)
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print("manifest strips=%d images=%d" % (len(manifest["strips"]), len(manifest["images"])))


if __name__ == "__main__":
    main()
