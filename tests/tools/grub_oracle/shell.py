from world import *
import math
W,H=1800,1200
SIZE=[W,H]
class Scn:
    """One emulated shot: terrain bitmap + a Shot2/SS object built by the real spawner."""
    def __init__(self, terrain, kind=1, angle=46, power=305, x=100, y=100, seed=1, mobiles=(), size=None, owner=3):
        e=self.e=make(seed)
        W,H=size or (1800,1200)
        self.mobiles=list(mobiles)   # list of (x0,y0,x1,y1) inclusive boxes for 0x450e10
        w=e.world
        self.W=W; self.H=H
        e.size=(W,H)
        data=e.alloc(W*H+16)
        e.uc.mem_write(data, bytes(terrain))
        t=w+0x6a7708
        e.w32(t+0x18,W); e.w32(t+0x1c,H); e.w32(t+0x34,data)
        def stop_at_registry(emu):
            emu.uc.emu_stop(); return 0
        e.hook_fn(0x4206f0,stop_at_registry,pop=4)
        e.hook_fn(0x4f2fb0,stop_at_registry,pop=0)
        self.objs=[]
        e.watch[{1:0x49e540,2:0x4856d0}[kind]]=lambda emu: self.objs.append(emu.r32(emu.uc.reg_read(UC_X86_REG_ESP)+4))
        self.log=[]
        args=[owner,8,12,kind,0,x,y,angle,power,80,80,80,4 if kind==1 else 1]
        spawner=0x42bbb0 if kind==1 else 0x42de70
        if kind==2: args=[owner,0,12,0,x,y,angle,power,80,80,80,1]
        e.trace_calls=[]
        try:
            e.call(spawner,args=args)
        except Exception as ex:
            print('SPAWN EXC',ex,hex(e.uc.reg_read(UC_X86_REG_EIP)),[(a,hex(b),sz,hex(i)) for a,b,sz,i in e.unmapped[-3:]]); print([hex(t) for _,t in e.trace_calls[-12:] if t]); raise
        e.trace_calls=None
        self.o=self.objs[0]
        e.hooks.pop(0x4206f0); e.hooks.pop(0x4f2fb0)
        # hook the heavy "side effect" callees so we can log them
        def mk(name,pop,n):
            def f(emu):
                esp=emu.uc.reg_read(UC_X86_REG_ESP)
                self.log.append((name,[emu.rs32(esp+4+4*i) for i in range(n)],emu.uc.reg_read(UC_X86_REG_ECX),emu.uc.reg_read(UC_X86_REG_EAX)))
                return 0
            return f
        self.exploded=False
    def cells(self):
        e=self.e;o=self.o
        g=lambda off: e.getcell(o+off)
        return dict(x=g(0x40),y=g(0x264),vx=g(0x488),vy=g(0x6ac),ix=g(0xf54),iy=g(0x1178),ctr=e.rs32(o+0x3f9c),contact=e.r8(o+0x3fa0))

from popinfo import pop_of
SIDE={0x4262d0:'crater',0x432320:'blast',0x43af40:'fx43af40',0x431d90:'fx431d90',0x436b50:'dust',0x450eb0:'fx450eb0',0x436ac0:'fx436ac0',0x4372f0:'fx4372f0',0x437150:'fx437150',0x4e4970:'reg4e4970',0x4e4d00:'reg4e4d00',0x436070:'fx436070',0x4e4fe0:'reg4e4fe0',0x436dc0:'fx436dc0',0x436ec0:'fx436ec0',0x436bd0:'fx436bd0',0x4ee9b0:'snd4ee9b0',0x4e6c90:'net4e6c90'}
def install_side_effects(s):
    e=s.e
    for va,name in SIDE.items():
        n=sorted(pop_of(va))[0]
        def mk(name,n):
            def f(emu):
                esp=emu.uc.reg_read(UC_X86_REG_ESP)
                s.log.append((s.tick_no,name,[emu.rs32(esp+4+4*i) for i in range(n//4)],emu.uc.reg_read(UC_X86_REG_ECX),emu.uc.reg_read(UC_X86_REG_EAX)))
                return 0
            return f
        e.hook_fn(va,mk(name,n),pop=n)
    for va in (0x4510f0,0x451030,0x4511b0): e.hook_fn(va,lambda emu:0,pop=4)
    # 0x450e10: mobile hit test (EBX=x, [esp+4]=y)
    def mob(emu):
        x=emu.uc.reg_read(UC_X86_REG_EBX); esp=emu.uc.reg_read(UC_X86_REG_ESP); y=emu.rs32(esp+4)
        x=x-(1<<32) if x>=1<<31 else x
        return 1 if any(b[0]<=x<=b[2] and b[1]<=y<=b[3] for b in s.mobiles) else 0
    e.hook_fn(0x450e10,mob,pop=4)
Scn.install=install_side_effects
def run_ticks(s,n,animate=0x4a1690):
    s.tick_no=0; install=True
    rows=[]
    for t in range(n):
        s.tick_no=t
        before=len(s.log)
        try:
            s.e.call(animate,ecx=s.o)
        except Exception as ex:
            rows.append(('EXC',str(ex),hex(s.e.uc.reg_read(UC_X86_REG_EIP)),s.e.unmapped[-3:]))
            break
        c=s.cells(); c['t']=t; c['fx']=[l[1] for l in s.log[before:]]
        rows.append(c)
        if any(n in ('blast','crater') for n in c['fx']): break
    return rows
