#!/usr/bin/env python3
"""GunBound Thor's Hammer XFS2 reader, with bounded LZHUF decoding.
Format references: jglim/gunbound-launcher TestClient (version280), and
CarlosX/Img-Tools-Gunbound AvatarInfoProcessor/ImageDecoder. The XFS2 stream
layout here was measured against the preserved archive and exported DATs.
The tool rejects unsupported formats instead of guessing another version.
"""
from pathlib import Path
import struct

# LZHUF format: 4096-byte ring, 314 adaptive-Huffman symbols.
def expand(data, size):
    if not 0 < size <= 131072:
        raise ValueError("Invalid decompressed block size")
    freq=[1]*314+[0]*314
    son=list(range(627,941))+[0]*313
    parent=[0]*941
    for i in range(314): parent[627+i]=i
    for j,i in enumerate(range(314,627)):
        child=j*2; son[i]=child;freq[i]=freq[child]+freq[child+1]
        parent[child]=parent[child+1]=i
    freq[627]=65535; parent[626]=0
    bitpos=0
    def bits(n):
        nonlocal bitpos
        v=0
        for _ in range(n):
            if bitpos//8>=len(data):
                raise ValueError(('truncated',len(out),size,bitpos,len(data)))
            v=v*2+((data[bitpos//8]>>(7-bitpos%8))&1); bitpos+=1
        return v
    code=[]; lens=[]
    lengths=[3]+[4]*3+[5]*8+[6]*12+[7]*24+[8]*16
    for i,n in enumerate(lengths):
        code.extend([i]*(1<<(8-n)));lens.extend([n]*(1<<(8-n)))
    ring=bytearray(b' '*4096);r=4036;out=bytearray()
    while len(out)<size:
        c=son[626]
        while c<627:c=son[c+bits(1)]
        c-=627
        node=parent[c+627]
        while True:
            freq[node]+=1
            f=freq[node]
            if f>freq[node+1]:
                other=node+1
                while f>freq[other+1]:other+=1
                freq[node],freq[other]=freq[other],f
                a,b=son[node],son[other]
                son[node],son[other]=b,a
                parent[a]=other
                if a<627:parent[a+1]=other
                parent[b]=node
                if b<627:parent[b+1]=node
                node=other
            node=parent[node]
            if node==0:break
        if c<256:
            out.append(c);ring[r]=c;r=(r+1)%4096
        else:
            first=bits(8);n=lens[first]-2
            distance=(code[first]<<6)|(((first<<n)|bits(n))&63)
            pos=(r-distance-1)%4096
            for k in range(c-253):
                v=ring[(pos+k)%4096];out.append(v);ring[r]=v;r=(r+1)%4096
    return bytes(out),bitpos

def archive(data):
    """Read XFS2's final directory, rejecting incomplete downloads."""
    if len(data)<12:
        raise ValueError("Truncated XFS")
    footer=struct.unpack_from('<I',data,len(data)-4)[0]
    if not 0<=footer<len(data)-8:
        raise ValueError("Missing XFS directory; download may be incomplete")
    def block(p,size):
        if p+4>len(data)-4:raise ValueError("Truncated directory length")
        n=struct.unpack_from('<I',data,p)[0]
        if n==0 or p+4+n>len(data)-4:raise ValueError("Truncated directory block")
        result,_=expand(data[p+4:p+4+n],size)
        return result[:size],p+4+n
    header,p=block(footer,64)
    if header[:4]!=b'XFS2':raise ValueError("Unsupported XFS signature")
    version,count=struct.unpack_from('<II',header,4)
    if not 0<count<=16384:raise ValueError("Invalid XFS entry count")
    table=bytearray();needed=count*128
    while len(table)<needed:
        decoded,p=block(p,min(131072,needed-len(table)));table.extend(decoded)
    entries={}
    for i in range(count):
        row=table[i*128:(i+1)*128]
        name=row[:112].split(b'\0')[0].decode('cp1252')
        flags,offset,size,disk=struct.unpack_from('<4I',row,112)
        if not name or name in entries or flags!=0 or size>64*1024*1024 or offset+disk>footer:
            raise ValueError("Invalid or unsupported XFS entry: "+name)
        entries[name]=dict(offset=offset,flags=flags,size=size,disk=disk)
    return dict(version=version,footer=footer,entries=entries)


def extract(data,row):
    """Decode independent 4096-byte chunks; never write to the source archive."""
    p=row['offset'];end=p+row['disk'];out=bytearray()
    if p<0 or end>len(data) or row['size']>64*1024*1024:
        raise ValueError("Invalid file bounds")
    while len(out)<row['size']:
        if p+8>end:raise ValueError("Truncated file block")
        n,checksum=struct.unpack_from('<II',data,p);p+=8
        if n==0 or p+n>end:raise ValueError("Truncated compressed file")
        chunk,_=expand(data[p:p+n],4096);p+=n;out.extend(chunk)
    if p!=end:raise ValueError("Inconsistent file length")
    return bytes(out[:row['size']])


STAT_NAMES=['shot_delay','bunge','attack','defense','health','item_delay','shield','popularity']
# Thor's Hammer writes avatar names and descriptions in the Korean code page.
# CP949 keeps ASCII intact and restores the ellipsis (A1 A6) and Hangul that
# CP1252 was showing as mojibake. Every DAT string in version 280 decodes.
def text(blob):
    return blob.split(b'\0')[0].decode('cp949')
def avatar_rows(data):
    info=archive(data);rows=[]
    for name,entry in info['entries'].items():
        if name not in ['fb.dat','ff.dat','fg.dat','fh.dat','mb.dat','mf.dat','mg.dat','mh.dat']:
            continue
        payload=extract(data,entry)
        count=struct.unpack_from('<I',payload)[0]
        if len(payload)!=4+count*132:raise ValueError("Invalid avatar DAT size")
        for i in range(count):
            row=struct.unpack_from('<I23sB10i64s',payload,4+i*132)
            rows.append(dict(file=name,id=row[0],name=text(row[1]),buyable=bool(row[2]),gold=row[3],cash=row[4],stats=dict(zip(STAT_NAMES,row[5:13])),description=text(row[13])))
    return rows


if __name__=='__main__':
    import argparse,json
    parser=argparse.ArgumentParser(description='Read-only GunBound XFS2 index, file extraction and avatar DAT conversion')
    parser.add_argument('archive',type=Path)
    parser.add_argument('--file',help='Exact internal file to extract; requires --out')
    parser.add_argument('--avatars',action='store_true',help='Convert all avatar DAT records to JSON')
    parser.add_argument('--out',type=Path)
    args=parser.parse_args()
    data=args.archive.read_bytes();info=archive(data)
    if args.file:
        if not args.out:parser.error('--file requires --out')
        output=extract(data,info['entries'][args.file])
    else:
        output=(json.dumps(avatar_rows(data) if args.avatars else info,ensure_ascii=False,indent=2)+'\n').encode('utf8')
    if args.out:
        if args.out.resolve()==args.archive.resolve():parser.error('Source archive must be preserved')
        args.out.parent.mkdir(parents=True,exist_ok=True);args.out.write_bytes(output)
    else:
        print(output.decode('utf8'),end='')
