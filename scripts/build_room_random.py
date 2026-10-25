"""Preserve OpenBound Random body/rider registration and build conservative4x atlas."""
import hashlib,json,sys,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'skills/gunbound-classic-hd/scripts'))
from upscale_conservative import upscale
from validate_restoration import validate
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 source=ROOT/'.tools/source-assets/content/Graphics/Tank/Random/CharacterSpritesheet.png'
 pivot=Path('/Users/guichafy/Workspaces/Gunbound/OpenBound/ContentMetadata/Mobile/Random/RiderPivot.json')
 native=ROOT/'assets/openbound/random';hd=ROOT/'assets/hd/classic/room_random_4x'
 if native.exists() or hd.exists():raise FileExistsError('Preserve prior outputs')
 native.mkdir();hd.mkdir()
 for src in [source,pivot]:shutil.copyfile(src,native/src.name)
 assert Image.open(source).size==(336,47)
 assert json.loads(pivot.read_text())==[[15,-5]]*12
 name='CharacterSpritesheet.png';record={'file':name,'size':[336,47],'frame_size':[28,47],'frames':12}
 size=upscale(native/name,hd/name,4,12,1)
 report=validate(native/name,hd/name,4,12,1);assert not report['failures']
 (ROOT/'docs/room-polish/random-restoration.json').write_text(json.dumps(report,indent=2)+'\n')
 cat={'version':1,'scale':4,'method':'BICUBIC per native frame; alpha NEAREST','assets':{'room_random_mobile':{'file':name,'source':{'file':'assets/openbound/random/'+name,'sha256':sha(native/name),'record':record},'size':list(size),'columns':12,'rows':1,'sha256':sha(hd/name)}}}
 (hd/'catalog.json').write_text(json.dumps(cat,indent=2)+'\n')
 evidence={'image_source':str(source.relative_to(ROOT)),'image_sha256':sha(source),'rider_source':str(pivot),'rider_sha256':sha(pivot),'cell':[28,47],'pivot':[14,23.5],'contact':45,'contact_evidence':'last opaque row of source frame0','registration_evidence':'OpenBound MobileFlipbook.cs Random and RiderPivot.json','scope':'room presentation only; no playable Random ID'}
 (ROOT/'docs/room-polish/random-source.json').write_text(json.dumps(evidence,indent=2)+'\n')
 print('Random12frames preserved and validated4x')
if __name__=='__main__':main()
