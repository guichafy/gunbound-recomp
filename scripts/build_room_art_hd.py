"""Extract native room portraits/maps and conservatively enlarge room-only artwork."""
import hashlib
import json
from pathlib import Path
import sys
from PIL import Image
import gunbound_xfs as xfs
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'skills/gunbound-classic-hd/scripts'))
from upscale_conservative import upscale
from validate_restoration import validate
ARCHIVE_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
ITEM_FILES = ['Dual','DualPlus','Thunder','EnergyUp2','TeamTeleport','Teleport','Blood','BungeShot','PowerUp','ChangeWind','EnergyUp1']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 archive=ROOT/'.tools/gunbound-client/graphics.xfs'
 assert sha(archive)==ARCHIVE_SHA
 out=ROOT/'assets/hd/classic/room_smooth_4x'
 native=ROOT/'assets/classic/room/details'
 reports=ROOT/'docs/room-ui/reports'
 if out.exists() or native.exists() or reports.exists():raise FileExistsError('Use new output folders; never overwrite approved/source artwork')
 out.mkdir(parents=True);native.mkdir(parents=True);reports.mkdir(parents=True)
 toc={i['name']:i for i in xfs.read_toc(archive)}
 records={};native_catalog={}
 for key,name,file,count,cell in [('room_maps','ready_selectmap.img','maps.png',22,(136,84)),('room_portraits','ready_selectcharacter.img','portraits.png',17,(113,146))]:
  raw=xfs.read_entry(archive,toc[name]);frames=xfs.frames(raw)
  assert len(frames)==count and all((f['w'],f['h'])==cell for f in frames)
  sheet=Image.new('RGBA',(cell[0]*count,cell[1]))
  for i,f in enumerate(frames):sheet.paste(f['image'],(i*cell[0],0))
  sheet.save(native/file)
  record={'file':'room/details/'+file,'size':list(sheet.size),'frame_size':list(cell),'frames':count}
  native_catalog[key]=record
  records[key]=(record,ROOT/'assets/classic'/record['file'],{'entry':name,'entry_sha256':hashlib.sha256(raw).hexdigest(),'hotspots':[[f['hx'],f['hy']] for f in frames]})
 (native/'catalog.json').write_text(json.dumps({'archive_sha256':ARCHIVE_SHA,'assets':native_catalog},indent=2)+'\n')
 manifest=json.loads((ROOT/'assets/classic/manifest.json').read_text())
 records['room_back']=(manifest['images']['room_back'],ROOT/'assets/classic/room/back.png',{})
 for name in ITEM_FILES:
  relative='items/Item'+name+'.png';source=ROOT/'assets/openbound'/relative
  with Image.open(source) as im:w,h=im.size
  assert h==36 and w%4==0
  records['item_'+name]=({'file':relative,'size':[w,h],'frame_size':[w//4,h],'frames':4},source,{'reference':'OpenBound native button sheet, normal/hover/push/disabled'})
 catalog={'version':1,'scale':4,'method':'BICUBIC per frame; native alpha NEAREST','pillow':Image.__version__,'assets':{}}
 for key,(record,source,extra) in records.items():
  path=out/record['file'];path.parent.mkdir(parents=True,exist_ok=True)
  count=record.get('frames',1);size=upscale(source,path,4,count,1)
  report=validate(source,path,4,count,1);assert not report['failures'],report['failures']
  (reports/(key+'.json')).write_text(json.dumps(report,indent=2)+'\n')
  catalog['assets'][key]={'file':record['file'],'source':{'file':str(source.relative_to(ROOT)),'sha256':sha(source),'record':record,**extra},'size':list(size),'columns':count,'rows':1,'sha256':sha(path)}
 (out/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n')
 print('Generated',len(records),'PNGs;84cells (1+22+17+44); all alpha/dimension checks passed')
if __name__=='__main__':main()
