"""Lightning DAT/PE parameters and an independent geometric/numeric oracle."""
import hashlib
import json
import math
from pathlib import Path
import struct
import gunbound_xfs as xfs
ROOT = Path(__file__).resolve().parents[1]
PE_SHA = '4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
DAT_SHA = 'b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf'

def native_row():
    raw = (ROOT/'.tools/gunbound-client/characterdata.dat').read_bytes()
    assert hashlib.sha256(raw).hexdigest() == DAT_SHA
    for offset in [0,4,8]:
        try:
            decoded = xfs.lzhuf(raw[offset:],16*332)
            if len(decoded)==16*332 and struct.unpack_from('<3i',decoded)==(28,24,0):
                return list(struct.unpack_from('<83i',decoded,7*332))
        except (ValueError,IndexError):
            pass
    raise ValueError('Invalid DAT')

def main():
    assert hashlib.sha256((ROOT/'.tools/mobile-animation-port/GunBound.gme').read_bytes()).hexdigest()==PE_SHA
    row=native_row()
    weapons=[dict(power=row[i],dimension=row[i+3],aspect=row[i+6],shock_radius=row[i+9],flags=row[i+10],shock=row[i+11],chain=row[i+12])for i in [44,57,70]]
    catalog=dict(binary_sha256=PE_SHA,characterdata_sha256=DAT_SHA,weapons=weapons,
        body=dict(width=row[0],height=row[1],vulnerability=row[21],hp=row[22],shield=row[23],regen=row[24],force=row[25],gravity=row[40]))
    (ROOT/'assets/openbound/lightning/combat_native.json').write_text(json.dumps(catalog,indent=2)+'\n')
    fixtures=[]
    for shot in weapons:
        for dx in range(-70,71,7):
            for dy in [-44,-30,-1,0,1,30,44]:
                x=math.trunc(dx*100/shot['aspect']);r=shot['dimension']//2+10;d=x*x+dy*dy
                f=math.trunc((r-math.sqrt(d))*1000/r)if d<r*r else 0
                fixtures.append([dx,dy,shot['dimension'],shot['aspect'],f])
    (ROOT/'tests/fixtures/lightning_damage_native.json').write_text(json.dumps(fixtures)+'\n')
    # 43af40 samples discrete upward points; hit uses native feet, not AABB.
    probes=[]
    for direction in [0,-1,1]:
        radius=70;step=radius if direction==0 else radius*7//10
        samples=[(200+direction*step*k,200-step*k)for k in range(200//step+1)]
        for flags in [2,4,8]:
            hitradius=radius+radius//5 if flags&8 else radius
            for x in range(80,321,15):
                for y in [20,60,100,140,180,220,260]:
                    hit=any(0<=sx<400 and (x-sx)**2+(y-sy)**2<hitradius**2 for sx,sy in samples)
                    probes.append([direction,flags,x,y,hit])
    (ROOT/'tests/fixtures/lightning_shock_native.json').write_text(json.dumps(probes)+'\n')
    # Original raster texture selected by482130/4a6b10.
    from PIL import Image
    archive=ROOT/'.tools/gunbound-client/graphics.xfs'
    toc={e['name']:e for e in xfs.read_toc(archive)}
    raw=xfs.read_entry(archive,toc['Lightning.xtf'])
    w,h,kind=struct.unpack_from('<IIB',raw)
    assert (w,h,kind)==(256,256,1)
    texture=Image.new('RGBA',(w,h))
    texture.putdata([xfs._argb4444(v) for v, in struct.iter_unpack('<H',raw[9:])])
    texture.save(ROOT/'assets/openbound/lightning/Lightning.png')
    (ROOT/'assets/openbound/lightning/lightning_effect.json').write_text(json.dumps(dict(entry='Lightning.xtf',entry_sha256=hashlib.sha256(raw).hexdigest(),size=[w,h],format='ARGB4444',columns=4,blend='additive',alpha='255-24*tick',duration_ticks=10),indent=2)+'\n')
    print(f'Lightning:{weapons};{len(fixtures)}falloff/{len(probes)}shock fixtures')
if __name__=='__main__':main()
