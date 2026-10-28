import glob,re,os
def pop_of(va):
    name='0x%08x.asm'%va
    for d in sorted(glob.glob(str(__import__('pathlib').Path(__file__).resolve().parents[3]/'.tools/battle-re/grub-evidence*/'))):
        p=os.path.join(d,name)
        if os.path.exists(p):
            rets=set()
            for l in open(p):
                m=re.search(r'\s(c2([0-9a-f]{2})([0-9a-f]{2}))\s+RET 0x([0-9a-f]+)',l)
                if m: rets.add(int(m.group(4),16))
                elif re.search(r'\sc3\s+RET',l): rets.add(0)
            return rets
    return None
if __name__=='__main__':
    for va in (0x4262d0,0x432320,0x43af40,0x431d90,0x436b50,0x450eb0,0x436ac0,0x4372f0,0x437150,0x4ee9b0,0x4e4970,0x4e4d00,0x436070,0x4e4fe0,0x4f2fb0,0x4f1f10,0x4ac4d0,0x4ac400,0x450730,0x45f840,0x43a530,0x458920,0x458a00,0x436dc0,0x436ec0,0x436bd0,0x4510f0,0x451030,0x4511b0,0x4e6c90,0x4e6fc0,0x4e4340):
        print(hex(va),pop_of(va))
