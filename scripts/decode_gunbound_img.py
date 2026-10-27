#!/usr/bin/env python3
"""Decode original IMG frames without rescaling; retain native pivots.
Format reference: CarlosX/Img-Tools-Gunbound ImgTools/tool/ImageDecoder.cs.
"""
from pathlib import Path
from PIL import Image
import struct,json
def frames(data):
 magic,count=struct.unpack_from('<II',data);p=8;result=[]
 assert count<10000,(magic,count)
 for i in range(count):
  kind,unused,w,h,px,py,a,b,c,d,n=struct.unpack_from('<HH9i',data,p);p+=40
  assert 0<w<=4096 and 0<h<=4096,(kind,w,h)
  raw=data[p:p+n];p+=n;kind&=255
  pixels=bytearray(w*h*4)
  def put(x,y,v):
   if kind==2:r,g,b,alpha=(v>>8&15)*17,(v>>4&15)*17,(v&15)*17,(v>>12)*17
   else:r,g,b,alpha=(v>>11)*255//31,(v>>5&63)*255//63,(v&31)*255//31,255
   # ARGB4444 has explicit alpha. RLE frames (kind 1) carry transparency in
   # their runs, so black inside a run is an opaque outline: gb-avatar.png
   # shows those pixels black (ADR-130). Only full RGB565 frames (kind 0)
   # use black as the color key.
   if kind==0 and r==g==b==0:alpha=0
   q=(y*w+x)*4;pixels[q:q+4]=bytes([r,g,b,alpha])
  if kind in [0,2]:
   assert len(raw)==w*h*2,(kind,w,h,n)
   for y in range(h):
    for x in range(w):put(x,y,struct.unpack_from('<H',raw,2*(y*w+x))[0])
  elif kind==1:
   rp=0
   for y in range(h):
    length,runs=struct.unpack_from('<HH',raw,rp);rp+=4
    for _ in range(runs):
     x,count=struct.unpack_from('<HH',raw,rp);rp+=4
     assert x+count<=w
     for j in range(count):put(x+j,y,struct.unpack_from('<H',raw,rp)[0]);rp+=2
   assert rp==len(raw),(rp,n)
  else:raise ValueError(('pixel format',kind))
  result.append((Image.frombytes('RGBA',(w,h),bytes(pixels)),(px,py)))
 return result

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    metadata=[]
    for index,(image,pivot) in enumerate(frames(args.source.read_bytes())):
        image.save(args.output/f'{index:03}.png')
        metadata.append(dict(size=list(image.size),pivot=list(pivot)))
    (args.output/'frames.json').write_text(json.dumps(metadata,indent=2)+'\n')
