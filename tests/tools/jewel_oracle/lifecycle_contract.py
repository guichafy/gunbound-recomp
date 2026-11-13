#!/usr/bin/env python3
"""ASM-translated lifecycle fixtures. Not a dynamic PE oracle or Godot model.
Reads only the pinned PE; the checked snippets ground constants/control gates.
"""
import argparse, hashlib, json, struct
from pathlib import Path
SHA='4af6283dfd151f5256b9bc0da8d07fff16384950c00da3b2baae825f5fc0fcde'
def generate(path):
    raw=Path(path).read_bytes()
    assert hashlib.sha256(raw).hexdigest()==SHA, 'unexpected client SHA256'
    pe=struct.unpack_from('<I',raw,0x3c)[0]
    n=struct.unpack_from('<H',raw,pe+6)[0]
    opt=struct.unpack_from('<H',raw,pe+20)[0]
    sections=pe+24+opt
    def read(va,size):
        rva=va-0x400000
        for i in range(n):
            base=sections+40*i
            vs,rv,rs,rp=struct.unpack_from('<IIII',raw,base+8)
            if rv<=rva<rv+max(vs,rs):
                return raw[rp+rva-rv:rp+rva-rv+size]
        raise ValueError(hex(va))
    signatures={
      '0x40d9d2':'6a0fbff04b7900', # default kind threshold15
      '0x41fb65':'83f806', # settled count<6 for replenishment
      '0x45e8bd':'0f8558010000', # mode3 bypass HP block
      '0x4ba90f':'83c002', # Jewel respawn due=current turn+2
      '0x4d0d48':'4050', # transition counter increments
      '0x525c57':'69c9fd43030081c1c39e2600', # CRT rand constants
    }
    for addr,wanted in signatures.items():
        assert read(int(addr,16),len(bytes.fromhex(wanted))).hex()==wanted, addr
    def kind(r): return 0 if r<15 else 1 if r<40 else 2 if r<80 else 3
    def rand(s):
        s=(s*214013+2531011)&0xffffffff
        return s,(s>>16)&32767
    rng=[]
    for seed in [0,1,42,0x7fffffff,0xffffffff]:
        s=seed; values=[]
        for _ in range(12): s,v=rand(s); values.append(v)
        rng.append({'seed':seed,'outputs':values,'state_after':s,
                    'initial_six':[{'x':values[i]%1800,'roll':values[i+1]%100,'kind':kind(values[i+1]%100)} for i in range(0,12,2)],
                    'replacement_first':{'roll':values[0]%100,'kind':kind(values[0]%100),'x':values[1]%1800}})
    return {'source_sha256':SHA,'basis':'ASM-translated fixtures with checked PE bytes; not PE execution',
      'checked_signatures':signatures,
      'kind_boundaries':[{'roll':v,'kind':kind(v)} for v in [0,14,15,16,39,40,41,79,80,81,99]],
      'replenishment_count':[{'settled':n,'request_one':n<6} for n in [0,4,5,6,7,8]],
      'respawn_due':[{'scheduled_at':20,'due':22,'turn':t,'ready':t>=22} for t in [21,22,23]],
      'native_rand':rng,
      'constraints':['rand sequence isolated here; client also consumes CRT draws for protected memory and UI',
       'World width1800 in RNG examples only; actual X is WORD rand modulo active width',
       'score transfer during drop is suppressed; physical slots8; settled target6',
       'Respawn X is chosen by user; autonomous offline selection is adaptation']}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('binary');p.add_argument('--output');a=p.parse_args()
    result=json.dumps(generate(a.binary),indent=2)+'\n'
    if a.output: Path(a.output).write_text(result)
    else: print(result,end='')
