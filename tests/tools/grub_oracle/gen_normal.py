import random, json, sys
from shell import *
def terrain_for(seed,W,H):
    r=random.Random(seed)
    t=bytearray(W*H)
    base=H*3//5
    # sum of sines hills + random steps
    import math
    phases=[(r.uniform(10,40),r.uniform(0.01,0.08),r.uniform(0,6.28)) for _ in range(3)]
    height=[int(base+sum(a*math.sin(f*x+p) for a,f,p in phases)) for x in range(W)]
    for x in range(W):
        for y in range(max(0,height[x]),H): t[y*W+x]=1
    # carve random caves and add floating blocks
    for _ in range(r.randint(2,6)):
        cx,cy,rad=r.randint(0,W-1),r.randint(base-30,H-1),r.randint(6,20)
        for y in range(max(0,cy-rad),min(H,cy+rad+1)):
            for x in range(max(0,cx-rad),min(W,cx+rad+1)):
                if (x-cx)**2+(y-cy)**2<=rad*rad: t[y*W+x]=0
    for _ in range(r.randint(1,4)):
        x0,y0=r.randint(10,W-40),r.randint(20,base-10); w,h=r.randint(4,30),r.randint(4,24)
        for y in range(y0,min(H,y0+h)):
            for x in range(x0,min(W,x0+w)): t[y*W+x]=1
    for y in range(H): t[y*W]=1; t[y*W+W-1]=1   # side walls: scans never run off the buffer
    return t,height
def rle(t,W,H):
    rows=[]
    for y in range(H):
        row=t[y*W:(y+1)*W]; runs=[]; cur=row[0]; n=0
        for v in row:
            if v==cur: n+=1
            else: runs.append([cur,n]); cur=v; n=1
        runs.append([cur,n]); rows.append(runs)
    return rows
OUT=str(__import__('pathlib').Path(__file__).resolve().parents[2]/'fixtures/grub_surface_native.json')
if __name__=='__main__':
    W2,H2=240,160
    out=[]
    r=random.Random(7)
    for seed in range(1,13):
        t,height=terrain_for(seed,W2,H2)
        qs=[]
        for _ in range(60):
            cx=r.randint(2,W2-3)
            if r.random()<0.7:
                cy=height[cx]+r.randint(-3,3)       # near the surface
            else:
                cy=r.randint(4,H2-2)
            cy=max(8,min(H2-2,cy))
            s=Scn(t,kind=1,angle=46,power=305,x=cx,y=cy,size=(W2,H2))
            install_side_effects(s)
            o=s.o
            ret=s.e.call(0x4a1740,args=[o])&0xff
            S=s.e.getcell(o+0x3fa4)
            qs.append([cx,cy,ret,S])
        out.append({'seed':seed,'size':[W2,H2],'terrain':rle(t,W2,H2),'queries':qs})
    json.dump(out,open(OUT,'w'),separators=(',',':'))
    import collections
    print(collections.Counter((q[2],q[3]) for o in out for q in o['queries']).most_common(20))
