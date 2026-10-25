"""Finish SETTINGS as one transparent raster word derived from native button glyphs."""
from pathlib import Path
import hashlib,json
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parents[1]

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
 native=ROOT/'assets/classic/room/settings/room_settings_word.png'
 hdroot=ROOT/'assets/hd/classic/room_settings_4x'
 hd=hdroot/'room/settings/room_settings_word.png'
 report=ROOT/'docs/settings-lettering-fix/word-source.json'
 if any(p.exists() for p in [native,hd,report]):raise FileExistsError('Preserve existing assets/reports')
 manifest=ROOT/'assets/classic/room/settings/catalog.json'
 catalogfile=hdroot/'catalog.json'
 records=json.loads(manifest.read_text());catalog=json.loads(catalogfile.read_text())
 key='room_settings_word';assert key not in records['assets'] and key not in catalog['assets']
 spec={'S':('startgame',40,51),'E':('changeteam',82,94),'T':('exit',69,79),'I':('exit',65,70),'N':('changeteam',63,73),'G':('changeteam',72,84)}
 glyphs={}
 for k,(name,x0,x1) in spec.items():
  im=Image.open(ROOT/('assets/classic/room/b_ready_'+name+'.png')).convert('RGBA').crop((x0,15,x1,31));mask=Image.new('L',im.size)
  for y in range(im.height):
   for x in range(im.width):
    r,g,b,_=im.getpixel((x,y));a=r/255
    error=min(max(abs(g-(89+166*a)),abs(b-(164-49*a))),max(abs(g-(89+166*a)),abs(b-(164+91*a))))
    if r>=49 and error<=6.5:mask.putpixel((x,y),r)
  bb=mask.point(lambda p:255 if p>=190 else 0).getbbox();x0,y0,x1,y1=bb;x0=max(0,x0-1);x1=min(mask.width,x1+1)
  glyphs[k]=(mask.crop((x0,0,x1,mask.height)),y0)
 w=sum(glyphs[k][0].width for k in 'SETTINGS')+7+6
 mask=Image.new('L',(w,17));xx=3
 for k in 'SETTINGS':
  glyph,top=glyphs[k];mask.paste(glyph,(xx,3-top));xx+=glyph.width+1
 m=mask.resize((w*4,68),Image.Resampling.BICUBIC)
 sheet=Image.new('RGBA',(w*16,68));source=Image.open(ROOT/'assets/classic/room/b_ready_exit.png')
 for state in range(4):
  fillmask=ImageChops.offset(m,4,4) if state==2 else m
  outline=Image.new('L',m.size)
  for y in range(-5,6):
   for x in range(-5,6):
    if x*x+y*y<=25:outline=ImageChops.lighter(outline,ImageChops.offset(fillmask,x,y))
  stroke=source.getpixel((state*107+66,20))[:3]
  word=Image.new('RGBA',m.size,(*stroke,0));word.putalpha(outline)
  column=state*107+(68 if state==2 else 67)
  ink=source.crop((column,14,column+1,31)).resize(m.size,Image.Resampling.BICUBIC)
  ink.putalpha(fillmask);word.alpha_composite(ink)
  sheet.paste(word,(state*w*4,0))
 native_sheet=Image.new('RGBA',(w*4,17))
 for state in range(4):native_sheet.paste(sheet.crop((state*w*4,0,(state+1)*w*4,68)).resize((w,17),Image.Resampling.LANCZOS),(state*w,0))
 native_sheet.save(native);sheet.save(hd)
 record={'file':'room/settings/room_settings_word.png','size':[w*4,17],'frame_size':[w,17],'frames':4}
 records['assets'][key]=record
 sources={name:sha(ROOT/('assets/classic/room/b_ready_'+name+'.png')) for name in ['startgame','exit','changeteam']}
 metadata={'file':record['file'],'size':list(sheet.size),'columns':4,'rows':1,'sha256':sha(hd),'source':{'file':str(native.relative_to(ROOT)),'sha256':sha(native),'record':record,'native_button_sha256':sources,'glyph_windows':spec},'method':'native fill coverage recovered from ink/gold/white palette; common cap-height; 1px spacing; 1.25px round outline; whole-word BICUBIC4x; alpha is derived, not native coverage'}
 catalog['assets'][key]=metadata
 manifest.write_text(json.dumps(records,indent=2)+'\n');catalogfile.write_text(json.dumps(catalog,indent=2)+'\n')
 report.parent.mkdir(parents=True,exist_ok=True);report.write_text(json.dumps(metadata,indent=2)+'\n')
 print('SETTINGS complete word',w,17,'x4states; alpha separated and continuous outline')
if __name__=='__main__':main()
