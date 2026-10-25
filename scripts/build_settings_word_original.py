"""Compose SETTINGS from original RGBA glyph pixels; only clean matte/junctions."""
from PIL import Image,ImageChops
from pathlib import Path
import json,hashlib,sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'skills/gunbound-classic-hd/scripts'))
from upscale_conservative import upscale
from validate_restoration import validate

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 native=ROOT/'assets/classic/room/settings/room_settings_word_complete.png'
 hdroot=ROOT/'assets/hd/classic/room_settings_4x'
 hd=hdroot/'room/settings/room_settings_word_complete.png'
 report=ROOT/'docs/settings-lettering-original/word-complete-source.json'
 if any(p.exists() for p in [native,hd,report]):raise FileExistsError('Keep existing and rejected outputs')
 spec={'S':('startgame',40,51),'E':('changeteam',82,93),'T':('exit',69,79),'I':('exit',65,70),'N':('changeteam',63,73),'G':('changeteam',72,84)}
 glyphs={}
 background=Image.open(ROOT/'assets/classic/room/b_ready_startgame.png').convert('RGBA')
 for k,(name,x0,x1) in spec.items():
  full=Image.open(ROOT/('assets/classic/room/b_ready_'+name+'.png')).convert('RGBA').crop((0,0,107,45));mask=Image.new('L',(107,45));face=Image.new('L',(107,45))
  for y in range(15,29):
   for x in range(x0,x1):
    r,g,b,_=full.getpixel((x,y));a=r/255;e=min(max(abs(g-(89+166*a)),abs(b-(164-49*a))),max(abs(g-(89+166*a)),abs(b-(164+91*a))))
    if r>=49 and e<=6.5:mask.putpixel((x,y),r)
  bb=mask.point(lambda p:255 if p>=190 else 0).getbbox();dil=Image.new('L',mask.size)
  seed=mask.point(lambda p:255 if p else 0)
  for dy in range(-2,3):
   for dx in range(-2,3):
    if dx*dx+dy*dy<=6:dil=ImageChops.lighter(dil,ImageChops.offset(seed,dx,dy))
  for y in range(45):
   for x in range(107):
    bg=background.getpixel((35,y));px=full.getpixel((x,y))
    if max(abs(px[i]-bg[i]) for i in range(3))<=8:dil.putpixel((x,y),0)
  # exclude neighbour letter fill outside the letter's native window
  for y in range(15,29):
   for x in range(max(0,x0-3),min(107,x1+3)):
    if x0<=x<x1:continue
    r,g,b,_=full.getpixel((x,y));a=r/255;e=min(max(abs(g-(89+166*a)),abs(b-(164-49*a))),max(abs(g-(89+166*a)),abs(b-(164+91*a))))
    if r>=49 and e<=6.5:dil.putpixel((x,y),0)
  glyphs[k]=(full,dil,bb,seed)
 w=sum(glyphs[k][2][2]-glyphs[k][2][0] for k in 'SETTINGS')+14+6
 # Union of every selected pixel in every pointer state, plus transparent edge.
 bounds=[];xx=3
 for letter in 'SETTINGS':
  _,mask,bb,face=glyphs[letter];x0,y0,x1,y1=mask.getbbox()
  for delta in [0,1]:bounds.append((xx-bb[0]+x0+delta,3-bb[1]+y0+delta,xx-bb[0]+x1+delta,3-bb[1]+y1+delta))
  xx+=bb[2]-bb[0]+2
 left=min(0,min(b[0] for b in bounds)-1);top=min(0,min(b[1] for b in bounds)-1)
 right=max(w,max(b[2] for b in bounds)+1);bottom=max(19,max(b[3] for b in bounds)+1)
 shift_x,shift_y=-left,-top;w,h=right-left,bottom-top
 sheet=Image.new('RGBA',(w*4,h));verified_core=0;verified_exclusive=0;bounded_pixels=0
 for state in range(4):
  dx=dy=1 if state==2 else 0
  canvas=Image.new('RGBA',(w,h));layers=[];coverage={};xx=3
  for letter in 'SETTINGS':
   _,mask,bb,face=glyphs[letter];name=spec[letter][0]
   source=Image.open(ROOT/('assets/classic/room/b_ready_'+name+'.png')).convert('RGBA').crop((state*107,0,(state+1)*107,45))
   aligned=Image.new('RGBA',source.size);aligned.paste(source,(-dx,-dy))
   at=(xx-bb[0]+dx+shift_x,3-bb[1]+dy+shift_y);layers.append((aligned,mask,face,at))
   for y in range(mask.height):
    for x in range(mask.width):
     px,py=x+at[0],y+at[1]
     if mask.getpixel((x,y)) or face.getpixel((x,y)):
      assert 0<=px<w and 0<=py<h,(state,px,py,'source pixel clipped');bounded_pixels+=1
     if mask.getpixel((x,y)):coverage[px,py]=coverage.get((px,py),0)+1
   xx+=bb[2]-bb[0]+2
  # Outline first, original letter surfaces last: neighbouring outlines cannot
  # cut a yellow/white stem. Every pasted colour comes directly from source.
  for facepass in [False,True]:
   for aligned,mask,face,at in layers:
    part=aligned.copy();part.putalpha(face if facepass else mask)
    layer=Image.new('RGBA',canvas.size);layer.paste(part,at);canvas.alpha_composite(layer)
  for aligned,mask,face,at in layers:
   for y in range(mask.height):
    for x in range(mask.width):
     px,py=x+at[0],y+at[1]
     if not (mask.getpixel((x,y)) or face.getpixel((x,y))):continue
     expected=aligned.getpixel((x,y))
     if face.getpixel((x,y)) and expected[0]>=190:
      assert canvas.getpixel((px,py))==expected,(state,px,py,'native letter core changed');verified_core+=1
     if mask.getpixel((x,y)) and coverage[px,py]==1:
      assert canvas.getpixel((px,py))==expected,(state,px,py,'unjoined contour changed');verified_exclusive+=1
  sheet.paste(canvas,(state*w,0))
 sheet.save(native)
 upscale(native,hd,4,4,1)
 validation=validate(native,hd,4,4,1);assert not validation['failures']
 record={'file':'room/settings/room_settings_word_complete.png','size':list(sheet.size),'frame_size':[w,h],'frames':4}
 manifest=ROOT/'assets/classic/room/settings/catalog.json';catalogfile=hdroot/'catalog.json'
 records=json.loads(manifest.read_text());catalog=json.loads(catalogfile.read_text())
 key='room_settings_word';records['assets'][key]=record
 meta={'file':record['file'],'size':[sheet.width*4,h*4],'columns':4,'rows':1,'sha256':sha(hd),'source':{'file':str(native.relative_to(ROOT)),'sha256':sha(native),'record':record,'native_button_sha256':{name:sha(ROOT/('assets/classic/room/b_ready_'+name+'.png')) for name in ['startgame','exit','changeteam']},'glyph_windows':spec},'method':'Original RGBA copied directly, no fill/stroke reconstruction; background removal and joins only; original faces over contours; whole-word BICUBIC4x/native alpha NEAREST','bounded_source_pixels':bounded_pixels,'native_core_rgba_checks':verified_core,'exclusive_contour_rgba_checks':verified_exclusive,'restoration_validation':validation}
 catalog['assets'][key]=meta
 manifest.write_text(json.dumps(records,indent=2)+'\n');catalogfile.write_text(json.dumps(catalog,indent=2)+'\n')
 report.parent.mkdir(parents=True,exist_ok=True);report.write_text(json.dumps(meta,indent=2)+'\n')
 print('Original RGBA SETTINGS',w,h,'4states; exact core',verified_core,'exclusive contour',verified_exclusive)
if __name__=='__main__':main()
