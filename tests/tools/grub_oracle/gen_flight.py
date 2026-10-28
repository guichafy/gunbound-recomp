import random, json, sys
from shell import *
from gen_normal import terrain_for, rle
def record(kind, t, size, angle, power, x, y, mobiles, owner=3, max_ticks=400):
    W2,H2=size
    s=Scn(t,kind=kind,angle=angle,power=power,x=x,y=y,size=size,mobiles=mobiles,owner=owner)
    install_side_effects(s)
    e=s.e; o=s.o
    g=lambda off: e.getcell(o+off)
    init=dict(x=g(0x40),y=g(0x264),vx=g(0x488),vy=g(0x6ac),ax=g(0xaf4),ay=g(0xd18),ix=g(0xf54),iy=g(0x1178),speed=g(0x35ec),ctr=e.rs32(o+0x3f9c),
              limit=g(0xe55ab8) if False else None)
    animate={1:0x4a1690,2:0x488780}[kind]
    ticks=[]; end='limit'
    for n in range(max_ticks):
        s.tick_no=n; before=len(s.log)
        crashed=False
        try:
            e.call(animate,ecx=o)
        except Exception as ex:
            crashed=True
            if not any(l[1]=='crater' for l in s.log[before:]): raise
        new=s.log[before:]
        c=s.cells()
        rec=[c['x'],c['y'],c['vx'],c['vy'],c['ix'],c['iy'],c['ctr'],c['contact'],e.r8(o+0x14)]
        names=[l[1] for l in new]
        dmg=[l[2][:2] for l in new if l[1]=='fx450eb0']
        ticks.append({'s':rec,'blast':'crater' in names,'dust':[l[2] for l in new if l[1]=='dust'],'dmg':dmg})
        if 'crater' in names: end='explode'; break
        if e.r8(o+0x14)==1: end='oob'; break
    return dict(kind=kind,size=list(size),init=init,ticks=ticks,end=end,shot=dict(angle=angle,power=power,x=x,y=y),mobiles=[list(m) for m in mobiles])
OUT=str(__import__('pathlib').Path(__file__).resolve().parents[2]/'fixtures/grub_flight_native.json')
if __name__=='__main__':
    out=[]; r=random.Random(11)
    W2,H2=300,200
    count=0
    for seed in range(1,9):
        t,height=terrain_for(seed,W2,H2)
        for kind in (1,2):
            for k in range(10):
                x=r.randint(16,W2-40); y=max(10,height[x]-r.randint(20,90))
                if r.random()<0.5: angle=r.randint(22,80)
                else: angle=r.randint(100,158)
                power=r.randint(120,480)
                mobiles=[]
                if kind==1 and r.random()<0.6:
                    mx=x+r.randint(-120,120); my=height[min(max(mx,2),W2-3)]
                    mobiles=[(mx-14,my-24,mx+14,my)]
                out.append(record(kind,t,(W2,H2),angle,power,x,y,mobiles))
                out[-1]['seed']=seed
                count+=1
    # terrain table once, scenarios refer to seed
    terr={str(seed):rle(terrain_for(seed,W2,H2)[0],W2,H2) for seed in range(1,9)}
    json.dump({'terrain':terr,'scenarios':out},open(OUT,'w'),separators=(',',':'))
    import collections
    print(len(out),collections.Counter((s['kind'],s['end']) for s in out))
    print('avg ticks',sum(len(s['ticks']) for s in out)/len(out))
