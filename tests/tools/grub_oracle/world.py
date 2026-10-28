from emu import *
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[3]/'scripts'))
import consts, hashlib, struct
import gunbound_xfs as xfs
from collections import Counter
import json
def character_rows():
    raw=(ROOT/'.tools/gunbound-client/characterdata.dat').read_bytes()
    assert hashlib.sha256(raw).hexdigest()=='b7278385d6ea60af3cdcbccbf6df15a74e857f196adbb87e5e99bea6a0feecaf'
    for off in (0,4,8):
        try:
            d=xfs.lzhuf(raw[off:],16*332)
            if len(d)==16*332 and struct.unpack_from('<3i',d)==(28,24,0):
                return [list(struct.unpack_from('<83i',d,i*332)) for i in range(16)]
        except (ValueError,IndexError): pass
    raise ValueError('Invalid DAT')
def make(seed=1):
    e=Emu(); e.init_keys()
    world=e.alloc(0x800000); e.w32(0x5b3484,world)
    for cell,val in consts.scan().items():
        e.setcell(cell,val)
    e.world=world
    rows=character_rows()
    for t,row in enumerate(rows):
        for i,v in enumerate(row): e.setcell(world+0xf0384+t*0xb1ac+i*0x224,v)
    st={'s':seed}
    def rand(emu):
        st['s']=(st['s']*0x343fd+0x269ec3)&0xffffffff
        return (st['s']>>16)&0x7fff
    e.hook_fn(0x525c4f,rand)
    def malloc(emu):
        esp=emu.uc.reg_read(UC_X86_REG_ESP); n=emu.r32(esp+4)
        return emu.alloc(n+64)
    e.hook_fn(0x52022d,malloc)
    return e
