"""Unicorn harness for the pinned GunBound.gme (x86-32): runs the client routines of the
Grub (type 12) T2/SS flight to produce the independent fixtures of tests/fixtures/grub_*."""
import struct, sys
from pathlib import Path
from unicorn import *
from unicorn.x86_const import *

ROOT = Path(__file__).resolve().parents[3]
PE = str(ROOT / '.tools/mobile-animation-port/GunBound.gme')
BASE = 0x400000
STACK_TOP = 0x7ff00000
STACK_SIZE = 0x400000
TIB = 0x7f000000
GDT = 0x7e000000
STUBS = 0x7d000000
RET_SENTINEL = 0x7d000100


class Emu:
    def __init__(self):
        d = open(PE, 'rb').read()
        pe = struct.unpack_from('<I', d, 0x3c)[0]
        n = struct.unpack_from('<H', d, pe + 6)[0]
        opt = struct.unpack_from('<H', d, pe + 20)[0]
        self.size_of_image = struct.unpack_from('<I', d, pe + 24 + 56)[0]
        self.uc = uc = Uc(UC_ARCH_X86, UC_MODE_32)
        uc.mem_map(BASE, (self.size_of_image + 0xfff) & ~0xfff)
        uc.mem_write(BASE, d[:struct.unpack_from('<I', d, pe + 24 + 60)[0]])
        for i in range(n):
            o = pe + 24 + opt + i * 40
            vs, va, rs, ro = struct.unpack_from('<IIII', d, o + 8)
            if rs:
                uc.mem_write(BASE + va, d[ro:ro + min(rs, vs)])
        uc.mem_map(STACK_TOP - STACK_SIZE, STACK_SIZE)
        uc.mem_map(TIB, 0x10000)
        uc.mem_map(GDT, 0x1000)
        uc.mem_map(STUBS, 0x10000)
        uc.mem_map(0x10000000, 0x4000000)  # heap
        self.heap = 0x10000000
        # FS via GDT
        def ent(base, limit, access, flags):
            return struct.pack('<HHBBBB', limit & 0xffff, base & 0xffff, (base >> 16) & 0xff, access,
                               ((limit >> 16) & 0xf) | (flags << 4), (base >> 24) & 0xff)
        gdt = ent(0, 0, 0, 0) + ent(0, 0xfffff, 0x9a, 0xc) + ent(0, 0xfffff, 0x92, 0xc) + ent(TIB, 0xfff, 0xf2, 0x4)
        uc.mem_write(GDT, gdt)
        uc.reg_write(UC_X86_REG_GDTR, (0, GDT, len(gdt) - 1, 0))
        uc.reg_write(UC_X86_REG_CS, 1 << 3)
        uc.reg_write(UC_X86_REG_SS, 2 << 3)
        uc.reg_write(UC_X86_REG_DS, 2 << 3)
        uc.reg_write(UC_X86_REG_ES, 2 << 3)
        uc.reg_write(UC_X86_REG_FS, (3 << 3) | 3)
        uc.mem_write(TIB, struct.pack('<I', 0xffffffff))  # SEH chain terminator
        uc.mem_write(TIB + 0x18, struct.pack('<I', TIB))
        uc.mem_write(RET_SENTINEL, b'\xf4')  # HLT
        # CS = flat 32-bit; make sure the CPU is in protected mode flat
        self.hooks = {}
        self.watch = {}
        self.trace_calls = None
        self.cs_depth = 0
        self.rand_state = 1
        self.enter_stub = STUBS + 0x10
        self.leave_stub = STUBS + 0x20
        uc.mem_write(self.enter_stub, b'\xc2\x04\x00')  # ret 4
        uc.mem_write(self.leave_stub, b'\xc2\x04\x00')
        uc.mem_write(0x5440a0, struct.pack('<I', self.enter_stub))
        uc.mem_write(0x54409c, struct.pack('<I', self.leave_stub))
        uc.hook_add(UC_HOOK_CODE, self._code_hook)
        uc.hook_add(UC_HOOK_MEM_UNMAPPED, self._unmapped)
        self.unmapped = []

    # ---- memory helpers
    def r32(self, a): return struct.unpack('<I', self.uc.mem_read(a, 4))[0]
    def rs32(self, a): return struct.unpack('<i', self.uc.mem_read(a, 4))[0]
    def w32(self, a, v): self.uc.mem_write(a, struct.pack('<I', v & 0xffffffff))
    def r8(self, a): return self.uc.mem_read(a, 1)[0]
    def w8(self, a, v): self.uc.mem_write(a, bytes([v & 0xff]))
    def alloc(self, n, align=16):
        self.heap = (self.heap + align - 1) & ~(align - 1)
        a = self.heap
        self.heap += n
        return a

    # protected cell (stride 0x224); key table zero => plain value in the 4 words
    def setcell(self, a, v):
        for i in range(4):
            self.w32(a + 4 + 4 * i, v)
        self.w32(a + 0x14, 0)

    def getcell(self, a):
        vals = [self.r32(a + 4 + 4 * i) for i in range(4)]
        assert len(set(vals)) == 1, (hex(a), vals)
        v = vals[0]
        return v - (1 << 32) if v >= 1 << 31 else v

    def init_keys(self):
        k = self.alloc(0x1000)
        self.w32(0x79376c, k)
        self.w32(0x793778, 0)

    # ---- flag byte triple (rand-protected bool)
    def set_flag(self, a, bit):
        self.w8(a, 0)
        self.w8(a + 1, (1 << 0) if bit else 0)
        self.w8(a + 2, (0 + (1 if bit else 0) - 0x34) & 0xff)
        # layout: b0=key, b1=value byte with bit (b0&7) set/cleared, b2=(b0+b1-0x34)
        self.w8(a + 1, 1 if bit else 0)
        self.w8(a + 2, (self.r8(a) + self.r8(a + 1) - 0x34) & 0xff)

    # ---- execution
    def _code_hook(self, uc, address, size, user):
        if address in self.watch:
            self.watch[address](self)
        if address in self.hooks:
            self.hooks[address](self)
            return
        if self.trace_calls is not None:
            b = bytes(uc.mem_read(address, min(size, 7)))
            if b[0] == 0xe8:
                tgt = (address + 5 + struct.unpack('<i', b[1:5])[0]) & 0xffffffff
                self.trace_calls.append((address, tgt))
            elif b[0] == 0xff and len(b) > 1 and (b[1] & 0x38) == 0x10:
                self.trace_calls.append((address, None))

    def _unmapped(self, uc, access, address, size, value, user):
        self.unmapped.append((access, address, size, uc.reg_read(UC_X86_REG_EIP)))
        return False

    def ret(self, pop=0):
        esp = self.uc.reg_read(UC_X86_REG_ESP)
        ra = self.r32(esp)
        self.uc.reg_write(UC_X86_REG_ESP, esp + 4 + pop)
        self.uc.reg_write(UC_X86_REG_EIP, ra)

    def hook_fn(self, addr, fn, pop=0):
        def h(emu):
            r = fn(emu)
            if r is not None:
                emu.uc.reg_write(UC_X86_REG_EAX, r & 0xffffffff)
            emu.ret(pop)
        self.hooks[addr] = h

    def call(self, addr, args=(), ecx=None, eax=None, edi=None, ebx=None, esi=None, edx=None, max_insn=20_000_000):
        uc = self.uc
        esp = STACK_TOP - 0x1000
        for a in reversed(args):
            esp -= 4
            self.w32(esp, a)
        esp -= 4
        self.w32(esp, RET_SENTINEL)
        uc.reg_write(UC_X86_REG_ESP, esp)
        for reg, val in ((UC_X86_REG_ECX, ecx), (UC_X86_REG_EAX, eax), (UC_X86_REG_EDI, edi),
                         (UC_X86_REG_EBX, ebx), (UC_X86_REG_ESI, esi), (UC_X86_REG_EDX, edx)):
            if val is not None:
                uc.reg_write(reg, val & 0xffffffff)
        uc.reg_write(UC_X86_REG_EFLAGS, 0x202)
        uc.emu_start(addr, RET_SENTINEL, count=max_insn)
        return uc.reg_read(UC_X86_REG_EAX)


if __name__ == '__main__':
    e = Emu()
    e.init_keys()
    c = e.alloc(0x224)
    e.setcell(c, 1234)
    print('get via native 0x40a2e0:', e.call(0x40a2e0, eax=c))
    e.call(0x40a380, args=[777], edi=c)
    print('after set 777:', e.getcell(c))
    print('unmapped', e.unmapped)
