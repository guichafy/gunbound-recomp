"""Catalog generated constant sprites without altering pixels or native originals."""
from pathlib import Path
import hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/hd/avatars'
def box_for(image):
    return image.getchannel('A').point(lambda a: 255 if a>8 else 0).getbbox()
def main():
    layout=json.loads((OUT/'source/layout.json').read_text())
    original={r['key']:r for r in json.loads((ROOT/'assets/openbound/avatars/catalog.json').read_text())}
    result={'version':1,'sheets':{},'pieces':{}}
    for name,rows in layout.items():
        path=OUT/(name+'.png');master=Image.open(path).convert('RGBA')
        result['sheets'][name]={'file':'res://'+str(path.relative_to(ROOT)),'size':list(master.size),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
        for entry in rows:
            x,y,w,h=entry['cell'];sx=master.width/1024;sy=master.height/1024
            cell=(round(x*sx),round(y*sy),round((x+w)*sx),round((y+h)*sy))
            bounds=box_for(master.crop(cell))
            assert bounds,entry['key']
            region=[bounds[0]+cell[0],bounds[1]+cell[1],bounds[2]-bounds[0],bounds[3]-bounds[1]]
            row=original[entry['key']];atlas=Image.open(ROOT/row['atlas'][6:]).convert('RGBA')
            fw,fh=row['frame_size'];columns=atlas.width//fw;frames=[]
            for frame in range(22):
                col,line=frame%columns,frame//columns
                if line*fh>=atlas.height:
                    frames.append(None);continue
                cut=atlas.crop((col*fw,line*fh,(col+1)*fw,min((line+1)*fh,atlas.height)))
                frames.append(box_for(cut))
            reference=frames[entry['reference_frame']]
            assert reference
            bx,by,ex,ey=reference
            offsets=[]
            for bound in frames:
                if not bound:
                    offsets.append([0,0]);continue
                ox,oy,rx,ry=bound
                offsets.append([((ox+rx)-(bx+ex))/2,((oy+ry)-(by+ey))/2])
            result['pieces'][entry['key']]={'sheet':name,'region':region,'native_rect':[bx,by,ex-bx,ey-by],'native_pivot':row['pivot'],'offsets':offsets}
    (OUT/'catalog.json').write_text(json.dumps(result,indent=2))
    print('Cataloged',len(result['pieces']),'HD sprites with original registration')
if __name__=='__main__':main()
