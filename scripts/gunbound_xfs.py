"""Read-only reader for the original GunBound Thor's Hammer client archives.

Own implementation from the reverse-engineered notes of GunBound-Decomp
(FILEFORMATS.md, https://github.com/colemancda/GunBound-Decomp), checked against
the TestClient of https://github.com/jglim/gunbound-launcher (graphics.xfs
SHA-256 a52f9f46...). Correction found here: an entry is a run of independent
blocks of at most 4096 decoded bytes, each [u32 compressed][u32 word checksum]
[LZHUF stream]; decoding an entry as one stream breaks after 4 KB, which is why
large multi-frame .img sheets looked unsolvable. LZHUF is the public-domain
Okumura/Yoshizaki algorithm (N=4096, F=60, THRESHOLD=2).
"""
import struct
from PIL import Image

N, F, THRESHOLD = 4096, 60, 2
N_CHAR = 256 - THRESHOLD + F
T = N_CHAR * 2 - 1
R = T - 1
MAX_FREQ = 0x8000


def _tables():
    # Classic d_code/d_len: upper 6 position bits, grouped by code length.
    code, length, value = [], [], 0
    for values, repeat, bits in [(1, 32, 3), (3, 16, 4), (8, 8, 5), (12, 4, 6), (24, 2, 7), (16, 1, 8)]:
        for _ in range(values):
            code.extend([value] * repeat)
            length.extend([bits] * repeat)
            value += 1
    assert len(code) == 256 and value == 64
    return code, length


D_CODE, D_LEN = _tables()


class LZHUF:
    def __init__(self, data):
        self.data, self.pos, self.buf, self.blen = data, 0, 0, 0
        self.text = bytearray(b" " * (N + F - 1))
        self.r = N - F
        self.freq = [0] * (T + 1)
        self.prnt = [0] * (T + N_CHAR)
        self.son = [0] * T
        for i in range(N_CHAR):
            self.freq[i] = 1
            self.son[i] = i + T
            self.prnt[i + T] = i
        i, j = 0, N_CHAR
        while j <= R:
            self.freq[j] = self.freq[i] + self.freq[i + 1]
            self.son[j] = i
            self.prnt[i] = self.prnt[i + 1] = j
            i += 2
            j += 1
        self.freq[T] = 0xFFFF
        self.prnt[R] = 0

    def _fill(self):
        while self.blen < 9:
            c = self.data[self.pos] if self.pos < len(self.data) else 0
            self.pos += 1
            self.buf |= c << (8 - self.blen)
            self.blen += 8

    def bit(self):
        self._fill()
        b = (self.buf >> 15) & 1
        self.buf = (self.buf << 1) & 0xFFFF
        self.blen -= 1
        return b

    def byte(self):
        self._fill()
        b = (self.buf >> 8) & 0xFF
        self.buf = (self.buf << 8) & 0xFFFF
        self.blen -= 8
        return b

    def _reconst(self):
        freq, son, prnt = self.freq, self.son, self.prnt
        j = 0
        for i in range(T):
            if son[i] >= T:
                freq[j] = (freq[i] + 1) // 2
                son[j] = son[i]
                j += 1
        i = 0
        for j in range(N_CHAR, T):
            f = freq[i] + freq[i + 1]
            freq[j] = f
            k = j - 1
            while f < freq[k]:
                k -= 1
            k += 1
            freq[k + 1:j + 1] = freq[k:j]
            freq[k] = f
            son[k + 1:j + 1] = son[k:j]
            son[k] = i
            i += 2
        for i in range(T):
            k = son[i]
            prnt[k] = i
            if k < T:
                prnt[k + 1] = i

    def _update(self, c):
        freq, son, prnt = self.freq, self.son, self.prnt
        if freq[R] == MAX_FREQ:
            self._reconst()
        c = prnt[c + T]
        while True:
            freq[c] += 1
            k = freq[c]
            l = c + 1
            if l < T and freq[l] < k:
                while l + 1 < T and freq[l + 1] < k:
                    l += 1
                freq[c], freq[l] = freq[l], k
                i = son[c]
                prnt[i] = l
                if i < T:
                    prnt[i + 1] = l
                j = son[l]
                son[l] = i
                prnt[j] = c
                if j < T:
                    prnt[j + 1] = c
                son[c] = j
                c = l
            c = prnt[c]
            if c == 0:
                break

    def decode(self, size):
        out = bytearray()
        text, r = self.text, self.r
        while len(out) < size:
            c = self.son[R]
            while c < T:
                c = self.son[c + self.bit()]
            c -= T
            self._update(c)
            if c < 256:
                out.append(c)
                text[r] = c
                r = (r + 1) & (N - 1)
            else:
                i = self.byte()
                pos = D_CODE[i] << 6
                for _ in range(D_LEN[i] - 2):
                    i = (i << 1) + self.bit()
                i = (r - ((pos | (i & 0x3F))) - 1) & (N - 1)
                for k in range(c - 255 + THRESHOLD):
                    if len(out) >= size:
                        break
                    v = text[(i + k) & (N - 1)]
                    out.append(v)
                    text[r] = v
                    r = (r + 1) & (N - 1)
        self.r = r
        return bytes(out)


def lzhuf(data, size):
    return LZHUF(data).decode(size)


def read_toc(path):
    with open(path, "rb") as f:
        f.seek(-4, 2)
        toc = struct.unpack("<I", f.read(4))[0]
        f.seek(toc)
        size = struct.unpack("<I", f.read(4))[0]
        header = lzhuf(f.read(size), 0x40)
        assert header[:4] == b"XFS2", header[:4]
        count = struct.unpack("<I", header[8:12])[0]
        entries = []
        for chunk in range((count + 1023) // 1024):
            length = struct.unpack("<I", f.read(4))[0]
            data = lzhuf(f.read(length), 0x20000)
            for e in range(min(1024, count - chunk * 1024)):
                rec = data[e * 128:(e + 1) * 128]
                name = rec[:rec.index(b"\0")].decode("latin1")
                mode, offset, dsize, csize = struct.unpack("<IIII", rec[0x70:0x80])
                entries.append({"name": name, "mode": mode, "offset": offset, "size": dsize})
        return entries


def read_entry(path, entry, limit=None):
    """Entries are a sequence of independent blocks of up to 4096 decoded bytes:
    [u32 compressed][u32 checksum = sum of the block's u32 words][LZHUF stream]."""
    size = entry["size"] if limit is None else min(limit, entry["size"])
    with open(path, "rb") as f:
        f.seek(entry["offset"])
        if entry["mode"] == 1:
            return f.read(size)
        out = bytearray()
        while len(out) < size:
            csize, checksum = struct.unpack("<II", f.read(8))
            block = lzhuf(f.read(csize), min(4096, entry["size"] - len(out)))
            # A trailing partial word counts zero-padded.
            words = block + b"\0" * (-len(block) % 4)
            if sum(struct.unpack("<%dI" % (len(words) // 4), words)) & 0xFFFFFFFF != checksum:
                raise ValueError("checksum mismatch in %s at %d" % (entry["name"], len(out)))
            out += block
        return bytes(out[:size])


# .img: i32 kind (low byte 0 RGB565, 1 sparse RGB565 runs, 2 ARGB4444), width,
# height, hotspot x/y, 4 x i32 (the last two + hotspot are the rider point), i32
# pixel byte count, pixels.
def _rgb565(v):
    return ((v >> 11 & 31) * 255 // 31, (v >> 5 & 63) * 255 // 63, (v & 31) * 255 // 31, 255)

def _argb4444(v):
    return ((v >> 8 & 15) * 17, (v >> 4 & 15) * 17, (v & 15) * 17, (v >> 12 & 15) * 17)

def frames(data):
    count = struct.unpack_from("<I", data, 4)[0]
    pos, out = 8, []
    for _ in range(count):
        kind, w, h, hx, hy, u1, u2, u3, u4, n = struct.unpack_from("<10i", data, pos)
        pix = data[pos + 40:pos + 40 + n]
        pos += 40 + n
        kind &= 0xFF
        img = Image.new("RGBA", (w, h))
        px = img.load()
        if kind in (0, 2):
            fn = _rgb565 if kind == 0 else _argb4444
            for i, (v,) in enumerate(struct.iter_unpack("<H", pix[:w * h * 2])):
                px[i % w, i // w] = fn(v)
        else:
            p = 0
            for y in range(h):
                if p + 4 > len(pix):
                    break
                stride, runs = struct.unpack_from("<HH", pix, p)
                q = p + 4
                for _ in range(runs):
                    x0, length = struct.unpack_from("<HH", pix, q)
                    q += 4
                    for k in range(length):
                        if 0 <= x0 + k < w:
                            px[x0 + k, y] = _rgb565(struct.unpack_from("<H", pix, q)[0])
                        q += 2
                if stride == 0:
                    break
                p += stride * 2
        out.append({"kind": kind, "w": w, "h": h, "hx": hx, "hy": hy, "extra": (u1, u2, u3, u4), "image": img})
    assert pos == len(data), (pos, len(data))
    return out


# .epa: u32 state count; per state u32 name length, name, u8 flag, u32 frame
# count, frame indices, per-frame durations in ticks.
def parse_epa(d):
    count = struct.unpack_from("<I", d, 0)[0]
    pos, out = 4, []
    for _ in range(count):
        n = struct.unpack_from("<I", d, pos)[0]; pos += 4
        name = d[pos:pos + n].decode("latin1"); pos += n
        flag = d[pos]; pos += 1
        frames = struct.unpack_from("<I", d, pos)[0]; pos += 4
        idx = list(struct.unpack_from("<%dI" % frames, d, pos)); pos += 4 * frames
        dur = list(struct.unpack_from("<%dI" % frames, d, pos)); pos += 4 * frames
        out.append({"name": name, "flag": flag, "frames": idx, "durations": dur})
    return out, pos
