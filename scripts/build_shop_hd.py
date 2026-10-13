"""Pack original Shop references, then register generated fixed masters at 4x.

python3 scripts/build_shop_hd.py refs
Generate source/gen_{controls,icons,chrome,scenery}.png with GPT Images.
python3 scripts/build_shop_hd.py
No original is modified. Native windows, alpha and action clocks stay separate
from generated detail. Source layouts/raw generations are excluded from export.
"""
import hashlib
import json
import math
import sys
from pathlib import Path
from PIL import Image, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parents[1]
ORIGINAL = ROOT / "assets/openbound/shop"
OUT = ROOT / "assets/hd/shop"
SOURCE = OUT / "source"
SCALE = 4

CONTROLS = [
    ("AnimatedButtons/AvatarShop/Hat", (49,48), 0, 33),
    ("AnimatedButtons/AvatarShop/Body", (49,39), 0, 31),
    ("AnimatedButtons/AvatarShop/Goggles", (49,46), 0, 36),
    ("AnimatedButtons/AvatarShop/Flag", (56,47), 0, 45),
    ("AnimatedButtons/Exit", (66,66), 0, 39),
    ("AnimatedButtons/LeftArrow", (46,42), 0, 31),
    ("AnimatedButtons/RightArrow", (46,42), 0, 31),
    ("AnimatedButtons/AvatarShop/Gift", (64,69), 0, 71),
    ("AnimatedButtons/AvatarShop/Buy", (64,73), 0, 46),
    ("AnimatedButtons/AvatarShop/Try", (64,72), 13, 71),
]
ICON_IDS = [0,1,2,3,4,5,6,13,17,15,23,9,19,21,11]
ICONS = "StaticButtons/AvatarShop/AvatarButton/"
BACKGROUND = "InGame/Scene/AvatarShop/Background"

def original(path):
    return Image.open(ORIGINAL / (path+".png")).convert("RGBA")

def rect(cell, frame, columns):
    x,y = frame%columns*cell[0],frame//columns*cell[1]
    return [x,y,cell[0],cell[1]]

def box(r):
    return (r[0],r[1],r[0]+r[2],r[1]+r[3])

def regions():
    result = {key: [] for key in ["controls","icons","chrome","scenery"]}
    for path,cell,normal,disabled in CONTROLS:
        result["controls"].append({"path":path,"rect":rect(cell,normal,original(path).width//cell[0]),"cell":cell,"disabled":disabled})
    for index in ICON_IDS:
        result["icons"].append({"path":ICONS+"ButtonIcons","rect":rect((26,17),index,6)})
    for name in ["EquipedIndicator","OwnedCheck","GoldIcon","CashIcon"]:
        im = original(ICONS+name)
        result["icons"].append({"path":ICONS+name,"rect":[0,0,26 if name.endswith("Icon") else im.width,im.height]})
    for index in range(3):
        result["chrome"].append({"path":ICONS+"Background","rect":[105*index,0,105,83]})
    result["chrome"].append({"path":"Popup/Blue/Avatar/Buy","rect":[0,0,228,286]})
    result["scenery"] = [
        {"path":BACKGROUND,"rect":[0,520,800,80]},
        {"path":BACKGROUND,"rect":[225,0,20,600]},
        {"path":"InGame/Scene/AvatarShop/InGamePreview/MiramoTown/Background","rect":[0,0,210,144]},
        {"path":"InGame/Scene/AvatarShop/InGamePreview/MiramoTown/Foreground2","rect":[0,0,210,145]},
    ]
    return result

def refs():
    SOURCE.mkdir(parents=True,exist_ok=True)
    (SOURCE/".gdignore").touch()
    layout = regions()
    # Explicit windows, all in 1536 square reference space. Wide scenery gets
    # its own row, the narrow divider its own strip, and preview layers below.
    for key,entries in layout.items():
        canvas = Image.new("RGBA",(1536,1536))
        if key=="scenery":
            windows = [[40,30,1456,180],[40,250,80,1220],[160,300,640,450],[840,300,640,450]]
        elif key=="chrome":
            windows = [[30,30,460,390],[538,30,460,390],[1046,30,460,390],[400,480,736,1000]]
        else:
            columns = 3 if key=="controls" else 5
            rows = math.ceil(len(entries)/columns)
            cw,ch = 1536//columns,1536//rows
            windows = [[(i%columns)*cw+24,(i//columns)*ch+24,cw-48,ch-48] for i in range(len(entries))]
        for entry,window in zip(entries,windows):
            piece = original(entry["path"]).crop(box(entry["rect"]))
            ratio = min(window[2]/piece.width,window[3]/piece.height)
            w,h = round(piece.width*ratio),round(piece.height*ratio)
            target = [window[0]+(window[2]-w)//2,window[1]+(window[3]-h)//2,w,h]
            canvas.alpha_composite(piece.resize((w,h),Image.Resampling.NEAREST),target[:2])
            entry["window"] = window
            entry["target"] = target
        canvas.save(SOURCE/f"ref_{key}.png")
    (SOURCE/"layout.json").write_text(json.dumps(layout,indent=2)+"\n")
    print("References packed: controls10, icons19, chrome4, scenery4")

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def build():
    layout = json.loads((SOURCE/"layout.json").read_text())
    canvases, report = {}, {"version":1,"scale":SCALE,"sprites":{},"generations":{}}
    for key,entries in layout.items():
        generated = SOURCE/f"gen_{key}.png"
        raw = Image.open(generated).convert("RGBA")
        report["generations"][key] = {"file":str(generated.relative_to(ROOT)),"size":list(raw.size),"sha256":sha(generated)}
        for entry in entries:
            path = entry["path"]
            src = original(path)
            if path not in canvases:
                canvases[path] = Image.new("RGBA",(src.width*SCALE,src.height*SCALE))
            # Read generator coordinates proportionally; never call an enlarged
            # transparent canvas evidence of additional useful pixels.
            r = entry["target"] if key=="scenery" else entry["window"]
            if key=="chrome":
                index = entries.index(entry)
                # The generator shifts bevels a few pixels; whole non-overlapping
                # windows retain the complete master before native registration.
                r = [index*512,0,512,512] if index<3 else [307,512,922,1024]
            region = [round(r[0]*raw.width/1536),round(r[1]*raw.height/1536),round((r[0]+r[2])*raw.width/1536),round((r[1]+r[3])*raw.height/1536)]
            piece = raw.crop(region)
            native = src.crop(box(entry["rect"]))
            if key in ["controls","icons"]:
                alpha_box = piece.getchannel("A").point(lambda a:255 if a>8 else 0).getbbox()
                if alpha_box is None:
                    raise ValueError(f"No generated alpha: {path}")
                piece = piece.crop(alpha_box)
                bounds = native.getchannel("A").point(lambda a:255 if a>8 else 0).getbbox()
                if bounds is None:
                    raise ValueError(f"No native registration: {path}")
                size = ((bounds[2]-bounds[0])*SCALE,(bounds[3]-bounds[1])*SCALE)
                fitted = ImageOps.contain(piece,size,Image.Resampling.LANCZOS)
                registered = Image.new("RGBA",(native.width*SCALE,native.height*SCALE))
                registered.alpha_composite(fitted,(bounds[0]*SCALE+(size[0]-fitted.width)//2,bounds[1]*SCALE+(size[1]-fitted.height)//2))
                piece = registered
                entry["useful_generated_size"] = [alpha_box[2]-alpha_box[0],alpha_box[3]-alpha_box[1]]
            else:
                if key=="chrome":
                    bounds = piece.getchannel("A").point(lambda a:255 if a>8 else 0).getbbox()
                    if bounds is None:
                        raise ValueError(f"No generated chrome: {path}")
                    piece = piece.crop(bounds)
                piece = piece.resize((native.width*SCALE,native.height*SCALE),Image.Resampling.LANCZOS)
                # Preserve alpha windows of UI and scenic layers. Color/detail
                # come from generation, alpha registration from the native asset.
                piece.putalpha(native.getchannel("A").resize(piece.size,Image.Resampling.BILINEAR))
            entry["generated_region"] = region
            if key=="controls":
                cell = entry["cell"]
                count = (src.width//cell[0])*(src.height//cell[1])
                for frame in range(count):
                    painted = piece.copy()
                    if frame==entry["disabled"]:
                        grayscale = ImageOps.grayscale(painted).convert("RGBA")
                        grayscale.putalpha(painted.getchannel("A"))
                        painted = Image.blend(painted,grayscale,0.85)
                    # Stable master; continuous highlights follow the source clock.
                    elif frame != 0:
                        painted = ImageEnhance.Brightness(painted).enhance(1.0+0.075*math.sin(frame*math.pi/20))
                    target = rect(cell,frame,src.width//cell[0])
                    canvases[path].alpha_composite(painted,(target[0]*SCALE,target[1]*SCALE))
            else:
                target = entry["rect"]
                canvases[path].alpha_composite(piece,(target[0]*SCALE,target[1]*SCALE))
    for path,canvas in canvases.items():
        destination = OUT/(path+".png")
        destination.parent.mkdir(parents=True,exist_ok=True)
        canvas.save(destination,optimize=True)
        src = original(path)
        report["sprites"][path] = {"file":"res://"+str(destination.relative_to(ROOT)),"size":list(canvas.size),"native_size":list(src.size),"sha256":sha(destination),"source_sha256":sha(ORIGINAL/(path+".png"))}
    report["registration"] = layout
    (OUT/"catalog.json").write_text(json.dumps(report,indent=2)+"\n")
    print(f"Built {len(canvases)} registered HD UI textures at {SCALE}x; originals intact")

if __name__=="__main__":
    refs() if sys.argv[1:]==["refs"] else build()
