"""Execute pinned x86 PE JEWEL hitbox/blast, with real arithmetic helpers.
Requires external unicorn==2.1.4. No engine/runtime dependency.
"""
import argparse, hashlib, json, sys, math, random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests/tools/grub_oracle'))
import emu
from emu import UC_X86_REG_ESP
SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'


def make(pe):
    assert hashlib.sha256(pe.read_bytes()).hexdigest() == SHA, 'PE SHA mismatch'
    emu.PE = str(pe)
    e = emu.Emu(); e.init_keys()
    world = e.alloc(0x800000); e.w32(0x5b3484, world)
    e.world = world
    e.set_flag(world + 0x6a7f74, False)
    e.setcell(0xe9ba40, 10); e.setcell(0xe55ab8, 20); e.setcell(0x796aa0, 100)
    e.setcell(world + 0x475c8, 0); e.w8(world + 0x475c4, 0)
    seed = [1]
    def rand(m):
        seed[0] = (seed[0]*0x343fd+0x269ec3)&0xffffffff
        return (seed[0] >> 16)&0x7fff
    e.hook_fn(0x525c4f, rand)
    e.hook_fn(0x52022d, lambda m: m.alloc(m.r32(m.uc.reg_read(UC_X86_REG_ESP)+4)+64))
    e.visual = []
    # Visual damage-number display (fastcall + two stack arguments) only.
    e.hook_fn(0x436860, lambda m: e.visual.append('number'), pop=8)
    vtable = e.alloc(16); pose = emu.STUBS+0x200
    e.w32(vtable+4, pose)
    e.hook_fn(pose, lambda m: e.visual.append('pose'), pop=4)
    e.vtable = vtable
    return e


def run(pe, p):
    e=make(pe)
    jewel=e.alloc(0x2298); shell=e.alloc(0x5000)
    e.w32(jewel,e.vtable); e.w32(jewel+8,0)
    for off,val in ((0x25c,p.get('jx',100)),(0x480,p.get('jy',100)),(0x8c8,p.get('old_damage',0)),(0xd14,p.get('old_owner',7))):
        e.setcell(jewel+off,val)
    e.w8(jewel+0x14,p.get('removed',0))
    e.set_flag(jewel+0x1c18,p.get('dropping',False))
    e.w8(shell+0x3c,p.get('owner',1)); e.set_flag(shell+0x3f98,False)
    for off,val in ((0x139c,p.get('bonus',0)),(0x15c0,p.get('force',0)),(0x17e4,p.get('percent',100))): e.setcell(shell+off,val)
    for w in range(3):
        for off,key,default in ((0x1e54,'power',200),(0x24c0,'dimension',60),(0x2b2c,'aspect',100)):
            e.setcell(shell+off+w*0x224,p.get(key+str(w),p.get(key,default)))
    e.setcell(e.world+0x1a1f48,p.get('stage_coef',0))
    e.setcell(0x796aa0,p.get('scale',100))
    e.set_flag(e.world+0x6a7f74,p.get('global_blocked',False))
    e.call(0x478cb0,args=(jewel,p.get('ix',100),p.get('iy',90)),edi=shell)
    assert not e.unmapped,e.unmapped
    return {'damage':e.getcell(jewel+0x8c8),'owner':e.getcell(jewel+0xd14),'visual':e.visual}


def hit(pe, p):
    e=make(pe); jewel=e.alloc(0x2298)
    e.setcell(jewel+0x25c,100);e.setcell(jewel+0x480,100)
    e.w8(jewel+0x14,p.get('removed',0))
    result=e.call(0x478a80,args=(jewel,p['x'],p['y']))&255
    assert not e.unmapped,e.unmapped
    return bool(result)


def shock(pe, p):
    e=make(pe); jewel=e.alloc(0x2298)
    e.w32(jewel,e.vtable)
    for off,val in ((0x25c,100),(0x480,100),(0x8c8,17),(0xd14,7)):
        e.setcell(jewel+off,val)
    e.w8(jewel+0x14,p.get('removed',0))
    root=e.alloc(0x40); node=e.alloc(0x40)
    e.w32(e.world+0x6a7f8c,root);e.w32(root+0x1c,node)
    e.w32(node+4,0x186a6);e.w32(node+0x10,jewel);e.w32(jewel+0x10,node)
    e.w32(e.world+0x6a7720,1800);e.w32(e.world+0x6a7724,1800)
    args=(p.get('x',100),p.get('y',100),0,p.get('radius',25),20,30,1)
    e.call(p.get('routine',0x43b7a0),args=args)
    assert not e.unmapped,e.unmapped
    return {'damage':e.getcell(jewel+0x8c8),'owner':e.getcell(jewel+0xd14),
      'shock':e.call(0x4065a0,eax=jewel+0xf38)&255,
      'primary':e.getcell(jewel+0xf40),'secondary':e.getcell(jewel+0x1164),
      'radius':e.getcell(jewel+0x1388),'visual':e.visual}


def quotient(a,b):
    return (abs(a)//abs(b))*(-1 if (a<0)!=(b<0) else 1)


def formula(p):
    # Separate reconstruction of ASM, used only to audit the PE-generated fixture.
    scale=p.get('scale',100);m=p.get('stage_coef',0)
    raw=0
    if m in (0,1,2):
        r=quotient(p.get('dimension'+str(m),p.get('dimension',60)),2)+10
        aspect=max(1,p.get('aspect'+str(m),p.get('aspect',100)))
        dx=quotient(scale*(p.get('jx',100)-p.get('ix',100)),aspect)
        dy=p.get('jy',100)-10-p.get('iy',90)
        sq=dx*dx+dy*dy
        if sq<r*r:
            f=int((r-math.sqrt(sq))*1000/r)
            raw=quotient(p.get('power'+str(m),p.get('power',200))*f,1000)
    raw=quotient(p.get('percent',100)*raw,scale or 1)
    raw=quotient((scale+p.get('bonus',0)+quotient(p.get('force',0),2))*raw,scale)
    applied=raw>0 and p.get('removed',0)!=1 and not p.get('global_blocked',False)
    return {'damage':p.get('old_damage',0)+(raw if applied else 0),
            'owner':p.get('owner',1) if applied else p.get('old_owner',7),
            'visual':['number','pose'] if applied else []}


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--pe',type=Path,required=True); ap.add_argument('--output',type=Path,required=True)
    a=ap.parse_args()
    cases=[{}, {'ix':139},{'ix':140},{'ix':141},{'ix':61},{'ix':60},{'ix':59},{'iy':129},{'iy':130},{'iy':131},
           {'ix':127,'iy':113},{'ix':125,'aspect':134},{'ix':75,'aspect':134},
           {'dimension':61},{'dimension':1},{'dimension':0},{'power':201,'ix':107},
           {'power':201,'percent':153,'bonus':12,'force':11,'ix':107},
           {'aspect':0,'ix':101},{'aspect':-5,'ix':101},
           {'old_damage':299},{'power':0},{'power':-1},{'stage_coef':1},{'stage_coef':2},{'stage_coef':3},
           {'scale':99,'ix':111},{'removed':1},{'global_blocked':True}]
    cases += [{'stage_coef':m,'power0':103,'power1':211,'power2':317,'dimension0':21,'dimension1':43,'dimension2':65,'aspect0':81,'aspect1':134,'aspect2':200,'ix':117,'iy':98} for m in (0,1,2)]
    cases += [{'owner':255},{'owner':0,'old_owner':1},{'old_damage':299,'power':501},{'power':1,'ix':139},{'force':-11,'percent':153},{'removed':2},{'dropping':True}]
    rng=random.Random(478)
    for _ in range(300):
        cases.append({'ix':rng.randint(40,160),'iy':rng.randint(35,145),'aspect':rng.randint(20,240),'dimension':rng.randint(1,160),'power':rng.randint(1,850),'percent':rng.randint(1,250),'force':rng.randint(-21,100),'bonus':rng.randint(-20,100),'stage_coef':rng.randrange(3)})
    out={'pe_sha256':SHA,'method':'native 478cb0/478a80; protected helpers and x87 conversion executed, only malloc/rand/critical-section/visual stubs',
         'blast':[{'input':p,'output':run(a.pe,p)} for p in cases],
         'hitbox':[{'input':{'x':x,'y':y,'removed':r},'output':hit(a.pe,{'x':x,'y':y,'removed':r})}
             for x,y in ((89,90),(90,90),(110,90),(111,90),(100,79),(100,80),(100,100),(100,101)) for r in (0,1)]}
    out['shock']=[{'input':p,'output':shock(a.pe,p)} for p in ({},{'x':124},{'x':125},{'x':126},{'removed':1},{'routine':0x43af40},{'routine':0x43af40,'x':125})]
    for row in out['blast']:
        assert row['output']==formula(row['input']), row
    a.output.write_text(json.dumps(out,indent=2)+'\n')
    print(json.dumps({'blast_cases':len(cases),'hitbox_cases':len(out['hitbox']),'output':str(a.output)}))

if __name__=='__main__': main()
