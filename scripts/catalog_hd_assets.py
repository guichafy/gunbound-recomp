"""Read generated alpha and catalog atlas regions. Never alter source PNG pixels."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GRIDS = {"bigfoot": (4, 8), "mage": (4, 8), "rider": (4, 2),
         "shots": (4, 6), "effects": (6, 6), "heroes": (2, 1), "emp": (1, 1), "mobile_parts": (3, 2), "pilot_seated": (1, 1), "projectile_heads": (3, 2), "pilot_side": (1, 1)}
result = {}
for name, (columns, rows) in GRIDS.items():
    path = ROOT / "assets" / "hd" / f"{name}.png"
    if not path.exists():
        continue
    image = Image.open(path).convert("RGBA")
    # Alpha <= 8/255 is effectively invisible background noise from generation.
    # Store crop metadata only. Actual PNG/alpha are preserved byte for byte.
    alpha = image.getchannel("A").point(lambda value: 255 if value > 8 else 0)
    regions = []
    for row in range(rows):
        for column in range(columns):
            left, top = column * image.width // columns, row * image.height // rows
            right = (column + 1) * image.width // columns
            bottom = (row + 1) * image.height // rows
            # Generator parts slightly overrun equal cells; actual transparent gaps
            # separate them. These windows contain complete, isolated pieces.
            if name == "mobile_parts":
                left, right = [(0, 570), (570, 1040), (1040, image.width)][column]
            bounds = alpha.crop((left, top, right, bottom)).getbbox()
            regions.append([left + bounds[0], top + bounds[1],
                            bounds[2] - bounds[0], bounds[3] - bounds[1]]
                           if bounds else [left, top, 0, 0])
    result[path.name] = {"size": list(image.size), "grid": [columns, rows],
                         "alpha_threshold": 8, "regions": regions,
                         "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
    if name == "pilot_side" and image.size == (1254, 1254):
        # Preserve the approved master's registration frame even though the
        # hidden far leg leaves transparent space at its left edge. No pixel edits.
        result[path.name]["regions"] = [[271, 153, 703, 977]]
# Stable flame-only pieces from the approved old shot artwork. Metadata only;
# exclude the blue/red head at the right boundary, not re-render PNG pixels.
shot_path = ROOT / "assets" / "hd" / "shots.png"
if shot_path.exists():
    shot_image = Image.open(shot_path).convert("RGBA")
    if shot_image.size == (1024, 1536):
        shot_alpha = shot_image.getchannel("A").point(lambda value: 255 if value > 8 else 0)
        result["shots.png"]["components"] = {}
        for key, window in {"t1_flame": (0, 0, 128, 256), "ss_flame": (0, 512, 140, 768)}.items():
            bounds = shot_alpha.crop(window).getbbox()
            if bounds:
                result["shots.png"]["components"][key] = [window[0] + bounds[0], window[1] + bounds[1], bounds[2] - bounds[0], bounds[3] - bounds[1]]
(ROOT / "assets" / "hd" / "atlas_regions.json").write_text(
    json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(f"Cataloged {len(result)} HD sheets; PNG pixels unchanged")
