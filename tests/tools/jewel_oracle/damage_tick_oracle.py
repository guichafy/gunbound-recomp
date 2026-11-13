"""Native 479ba0/4785f0/450730 oracle; terrain API and presentation stubs only."""
import argparse,json,struct
from pathlib import Path
from damage_oracle import make,SHA,ROOT
from emu import UC_X86_REG_EAX,UC_X86_REG_EDI,UC_X86_REG_ECX,UC_X86_REG_ESP

def scenario(pe,p):
 e=make(pe); j=e.alloc(0x2298);e.w32(j,e.vtable)
 width=320;height=240
 for off,v in ((0x25c,p.get('x',100)),(0x480,p.get('y',0)),(0x6a4,300),(0x8c8,0),(0xd14,p.get('owner',-1)),(0xaf0,0),(0x17d0,0),(0x19f4,p.get('fall',0))):e.setcell(j+off,v)
 e.setcell(0x794bf0,15);e.setcell(e.world+0x62630,3)
 e.setcell(e.world+0x5af88,p.get('wind',0));e.setcell(e.world+0x5b1ac,p.get('wind_angle',0))
 e.w32(e.world+0x6a7720,width);e.w32(e.world+0x6a7724,height)
 battle=e.alloc(0x3000);e.w32(0x5b3424,battle);e.w8(battle+0x2382,1)
 e.set_flag(j+0x1c18,p.get('drop',True))
 def floor(x):
  if p.get('void',False):return 10000
  return 100+int((x-100)*p.get('slope',0))
 def surface(m):
  x=m.uc.reg_read(UC_X86_REG_EDI);x=x-(1<<32) if x>=(1<<31) else x
  y=m.uc.reg_read(UC_X86_REG_EAX);y=y-(1<<32) if y>=(1<<31) else y
  if x<0 or x>=width:return 10000
  answer=max(0,y,floor(x))
  return answer if answer<height else 10000
 e.hook_fn(0x4e4340,surface)
 # Audio-choice RNG is separate from the integer/wind/terrain chain under test.
 e.hook_fn(0x415c60,lambda m:0)
 catalog=json.loads((ROOT/'assets/xfs/jewel/catalog.json').read_text())['sheets']['jewel1']['epa']
 info=e.alloc(24);e.w32(info,1)
 flags=e.alloc(8);counts=e.alloc(20);frames=e.alloc(20);durations=e.alloc(20)
 for k,row in enumerate(catalog):
  e.w8(flags+k,row['flag']);e.w32(counts+4*k,len(row['frames']))
  f=e.alloc(4*len(row['frames']));d=e.alloc(4*len(row['durations']))
  for i,v in enumerate(row['frames']):e.w32(f+4*i,v)
  for i,v in enumerate(row['durations']):e.w32(d+4*i,v)
  e.w32(frames+4*k,f);e.w32(durations+4*k,d)
 for off,v in ((8,flags),(12,counts),(16,frames),(20,durations)):e.w32(info+off,v)
 e.w32(j+0x1c,info);e.w8(j+0x20,1)
 def pose(m):
  esp=m.uc.reg_read(UC_X86_REG_ESP);ptr=m.r32(esp+4)
  name=bytes(m.uc.mem_read(ptr,12)).split(b'\0')[0].decode()
  k=next(i for i,row in enumerate(catalog) if row['name']==name)
  e.w32(j+0x24,k);e.w32(j+0x28,0);e.w32(j+0x2c,0);e.w8(j+0x34,0)
 e.hook_fn(e.r32(e.vtable+4),pose,pop=4)
 e.w32(j+0x24,p.get('pose',1))
 # Verify immutable lookup data really are the PE bytes, not an ideal atan/sin.
 assert bytes(e.uc.mem_read(0x588f80,131072))==(ROOT/'assets/openbound/physics/native-angle-i16.bin').read_bytes()
 assert bytes(e.uc.mem_read(0x54c240,1440))==(ROOT/'assets/openbound/physics/native-sine-f32.bin').read_bytes()
 rows=[]
 for _ in range(p.get('ticks',26)):
  e.call(0x479ba0,ecx=j)
  rows.append({'x':e.getcell(j+0x25c),'y':e.getcell(j+0x480),'fall':e.getcell(j+0x19f4),'drift':e.getcell(j+0x17d0),'angle':e.getcell(j+0xaf0),'drop':bool(e.call(0x4065a0,eax=j+0x1c18)&255),'pose':e.rs32(j+0x24),'frame':e.rs32(j+0x2c),'frame_age':e.rs32(j+0x28),'owner':e.getcell(j+0xd14),'removed':bool(e.r8(j+0x14))})
  if e.r8(j+0x14):break
 assert not e.unmapped,e.unmapped
 return rows

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--pe',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);a=ap.parse_args()
 cases=[{}, {'wind':20,'wind_angle':0},{'wind':20,'wind_angle':180},{'wind':20,'wind_angle':45},{'wind':20,'wind_angle':270},{'y':101,'drop':False,'pose':0},{'y':101,'drop':False,'pose':3},{'y':101,'drop':False,'pose':2},{'slope':0.5,'y':101,'drop':False,'pose':0},{'slope':-0.5,'y':101,'drop':False,'pose':0},{'slope':4,'y':101,'drop':False,'pose':0},{'void':True,'y':101,'drop':False,'pose':0},{'y':99,'fall':4},{'y':99,'fall':5}]
 result={'pe_sha256':SHA,'method':'executed native479ba0/4785f0/450730; terrain API floor columns, pose assignment, audio branch RNG stubs','scenarios':[{'input':p,'ticks':scenario(a.pe,p)} for p in cases]}
 a.output.write_text(json.dumps(result,indent=2)+'\n');print(len(result['scenarios']))
if __name__=='__main__':main()
