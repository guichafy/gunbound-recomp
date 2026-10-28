"""Protected-integer constants written by WinMain (PUSH imm; MOV EDI,cell; CALL 0x40a380)."""
import re, struct
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]

def scan():
    data = (ROOT / '.tools/mobile-animation-port/GunBound.gme').read_bytes()
    text = data[1024:1024 + 1321472]
    found = {}
    for m in re.finditer(rb'(\x6a(.)|\x68(....))\xbf(....)\xe8(....)', text, re.S):
        call_at = m.start() + len(m.group(0)) - 5
        target = (0x401000 + call_at + 5 + struct.unpack('<i', m.group(5))[0]) & 0xffffffff
        if target != 0x40a380:
            continue
        value = struct.unpack('<b', m.group(2))[0] if m.group(2) is not None else struct.unpack('<i', m.group(3))[0]
        cell = struct.unpack('<I', m.group(4))[0]
        if value != 0:
            found.setdefault(cell, value)
    return found
