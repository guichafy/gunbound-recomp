"""Read generated alpha and catalog atlas regions. Never alter source PNG pixels."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GRIDS = {"bigfoot": (4, 8), "mage": (4, 8), "rider": (4, 2),
         "shots": (4, 6), "effects": (6, 6), "heroes": (2, 1), "emp": (1, 1), "mobile_parts": (3, 2)}
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
(ROOT / "assets" / "hd" / "atlas_regions.json").write_text(
    json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(f"Cataloged {len(result)} HD sheets; PNG pixels unchanged")
