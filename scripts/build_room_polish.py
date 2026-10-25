"""Extract native room item catalog and equipment states; upscale each window."""
import hashlib,json,sys
from pathlib import Path
from PIL import Image
import gunbound_xfs as xfs
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'skills/gunbound-classic-hd/scripts'))
from upscale_conservative import upscale
from validate_restoration import validate

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 archive=ROOT/'.tools/gunbound-client/graphics.xfs'
 assert sha(archive)=='a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'
 native=ROOT/'assets/classic/room/polish';out=ROOT/'assets/hd/classic/room_polish_4x';reports=ROOT/'docs/room-polish/reports'
 if any(p.exists() for p in [native,out,reports]):raise FileExistsError('Preserve existing outputs')
 for p in [native,out,reports]:p.mkdir(parents=True)
 toc={i['name']:i for i in xfs.read_toc(archive)};records={};extras={}
 specs=[]
 # Thor item ordering is identical in ready_itemshop and ready_item; each
 # normal frame is followed by its native disabled state (not an invented hover).
 mapping={'blood':(1,4),'bunge_shot':(1,0),'power_up':(1,2),
          'energy_up_1':(1,12),'change_wind':(1,28),'dual':(2,0),
          'dual_plus':(2,2),'thunder':(2,10),'energy_up_2':(2,12),
          'teleport':(2,18),'team_teleport':(2,20)}
 for id,(sheet,index) in mapping.items():
  for kind,prefix in [('catalog','ready_itemshop'),('equipped','ready_item')]:
   specs.append((kind+'_'+id,prefix+str(sheet)+'.img',[index,index+1]))
 for key,entry,indices in specs:
  raw=xfs.read_entry(archive,toc[entry]);frames=xfs.frames(raw);chosen=[frames[i] for i in indices]
  w,h=chosen[0]['w'],chosen[0]['h'];assert all((f['w'],f['h'])==(w,h) for f in chosen)
  sheet=Image.new('RGBA',(w*len(chosen),h))
  for i,f in enumerate(chosen):sheet.paste(f['image'],(i*w,0))
  relative='room/polish/'+key+'.png';sheet.save(ROOT/'assets/classic'/relative)
  records[key]={'file':relative,'size':list(sheet.size),'frame_size':[w,h],'frames':len(chosen)}
  extras[key]={'entry':entry,'img_indices':indices,'entry_sha256':hashlib.sha256(raw).hexdigest(),'hotspots':[[f['hx'],f['hy']] for f in chosen]}
 (native/'catalog.json').write_text(json.dumps({'archive_sha256':sha(archive),'assets':records},indent=2)+'\n')
 catalog={'version':1,'scale':4,'method':'BICUBIC per native frame/window; alpha NEAREST','assets':{}}
 for key,r in records.items():
  source=ROOT/'assets/classic'/r['file'];dest=out/r['file'];dest.parent.mkdir(parents=True,exist_ok=True)
  size=upscale(source,dest,4,r['frames'],1);report=validate(source,dest,4,r['frames'],1);assert not report['failures']
  (reports/(key+'.json')).write_text(json.dumps(report,indent=2)+'\n')
  catalog['assets'][key]={'file':r['file'],'source':{'file':str(source.relative_to(ROOT)),'sha256':sha(source),'record':r,**extras[key]},'size':list(size),'columns':r['frames'],'rows':1,'sha256':sha(dest)}
 (out/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n')
 print('22PNGs,44native frames/windows validated; catalog64x43 and equipment35/71x31')
if __name__=='__main__':main()
