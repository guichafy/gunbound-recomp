import json
from pathlib import Path
from emu import *
def run(angle,power,flag651c,dual,event,frame,offs=None):
    e=Emu(); e.init_keys()
    world=e.alloc(0x800000); e.w32(0x5b3484,world)
    for cell,v in ((0x796aa0,100),(0x794e48,80)): e.setcell(cell,v)
    ctx=e.alloc(0x20000)
    cells=dict(a=(0x4d90,angle),p=(0x7864,power),x=(0x90c,1000),y=(0xb30,800),ox=(0x5844,20),oy=(0x5a68,10),ox1=(0x53fc,7),oy1=(0x5620,3),ox2=(0x4d90+0,angle))
    for k,v in cells.items(): e.setcell(ctx+v[0],v[1])
    for a in (0xbfbe,0xbfc1,0xbfcd): e.set_flag(ctx+a,0)
    if dual: e.set_flag(ctx+0xbfbe,1)
    e.w8(ctx+0x651c,flag651c); e.w8(ctx+8,3)
    calls=[]
    def mk(name,n,pop):
        def spawn(emu):
            esp=emu.uc.reg_read(UC_X86_REG_ESP)
            calls.append((name,[emu.rs32(esp+4+4*i) for i in range(n)]))
            return 0
        e.hook_fn({'S':0x42bbb0,'U':0x42de70}[name],spawn,pop=pop)
    mk('S',13,0x34); mk('U',12,0x30)
    try: e.call(0x471fd0,args=[event,frame],ecx=ctx)
    except Exception as ex: pass
    return calls


OUT = Path(__file__).resolve().parents[2] / 'fixtures/grub_emission_native.json'
if __name__ == '__main__':
    rows = []
    for ev, name in ((5, 't1'), (6, 't2'), (10, 'ss')):
        for theta in (30, 45, 60, 90, 91, 120, 135, 150):
            for power in (1, 100, 300, 500):
                calls = run(theta, power, 0, 0, ev, 2)
                rows.append(dict(weapon=name, event=ev, theta=theta, power=power,
                                 shells=[[c[1][7] if c[0] == 'S' else c[1][6], c[1][8] if c[0] == 'S' else c[1][7]] for c in calls]))
    OUT.write_text(json.dumps(rows, separators=(',', ':')))
    print(len(rows), 'MainAction rows')
