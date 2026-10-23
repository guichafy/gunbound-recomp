#!/usr/bin/env python3
"""Register a visually reviewed generated batch; QA is a separate ledger step."""
from collections import deque
from pathlib import Path
from datetime import datetime, timezone
import argparse
import hashlib
import json
import shutil
from PIL import Image
from prepare_xfs_avatar_hd import ROOT,SOURCE,read,renderer_hashes,registration


def regions(image,columns,rows,count,assignment_windows=None):
    width,height=image.size
    mask=bytearray(image.getchannel('A').point(lambda a:255 if a>8 else 0).tobytes())
    groups=[[] for _ in range(count)]
    for first,value in enumerate(mask):
        if not value:
            continue
        queue=deque([first]);mask[first]=0;points=[]
        while queue:
            point=queue.popleft();y,x=divmod(point,width);points.append((x,y))
            for next_point in ([point-1] if x else [])+([point+1] if x<width-1 else [])+([point-width] if y else [])+([point+width] if y<height-1 else []):
                if mask[next_point]:
                    mask[next_point]=0;queue.append(next_point)
        if len(points)<12:
            continue
        x0=min(p[0] for p in points);y0=min(p[1] for p in points)
        x1=max(p[0] for p in points)+1;y1=max(p[1] for p in points)+1
        col=min(columns-1,int((x0+x1)*0.5/width*columns))
        row=min(rows-1,int((y0+y1)*0.5/height*rows))
        index=row*columns+col
        if index<count:
            groups[index].extend(points)
    # Reviewed assignment windows attach disconnected glow particles to their
    # own sprite when they sit near an artificial grid boundary. No pixels or
    # artwork are changed; neighboring source windows must still be disjoint.
    if assignment_windows:
        corrected=[[] for _ in groups]
        for index,points in enumerate(groups):
            for x,y in points:
                target=index
                for cell,rect in assignment_windows.items():
                    if rect[0]<=x<rect[0]+rect[2] and rect[1]<=y<rect[1]+rect[3]:
                        target=int(cell)-1
                        break
                corrected[target].append((x,y))
        groups=corrected
    boxes=[]
    for index,points in enumerate(groups):
        if not points:
            raise ValueError(f'Cell {index+1} is empty; batch requires correction')
        x0=min(p[0] for p in points);y0=min(p[1] for p in points)
        x1=max(p[0] for p in points)+1;y1=max(p[1] for p in points)+1
        if max(x1-x0,y1-y0)<100:
            raise ValueError(f'Insufficient useful pixels in cell {index+1}')
        for other,neighbors in enumerate(groups):
            if other!=index and any(x0<=x<x1 and y0<=y<y1 for x,y in neighbors):
                raise ValueError(f'Cell {index+1} region {[x0,y0,x1,y1]} contains pixels of cell {other+1}')
        boxes.append([x0,y0,x1-x0,y1-y0])
    return boxes


def build_catalog(accepted):
    result=dict(version=1,sheets={},layers={},portraits={})
    for identity,entry in accepted.items():
        if entry['state'] not in ('registered','qa_passed'):
            continue
        result['sheets'][entry['sheet']]=entry['sheet_meta']
        target='portraits' if entry['role']=='portrait' else 'layers'
        key=entry['key'] if target=='portraits' else identity
        result[target][key]={k:v for k,v in entry.items() if k not in ('sheet_meta',)}
    destination=ROOT/'assets/hd/avatars/xfs/catalog.json'
    destination.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('batch')
    parser.add_argument('--component',help='Repair one original job component using a separate generated master')
    parser.add_argument('--image',type=Path,help='Generated repair PNG (preserved alongside the selected atlas)')
    parser.add_argument('--qa',action='store_true',help='After visual review of GPU comparisons, validate the captured batch hashes')
    args=parser.parse_args()
    jobs=read(SOURCE/'jobs.json')['jobs']
    job=next(job for job in jobs if job['id']==args.batch)
    ledger=SOURCE/'accepted.json'
    accepted=read(ledger) if ledger.exists() else {}
    if args.qa:
        folder=ROOT/'docs/avatar-hd-migration/qa'
        report=read(folder/(job['id']+'.json'))
        if report.get('renderer_hashes')!=renderer_hashes():
            raise ValueError('GPU evidence predates the current renderer; recapture before QA')
        if report['size']!=[1920,1080] or {entry['id'] for entry in job['variants']}!={entry['id'] for entry in report['components']}:
            raise ValueError('GPU report does not cover the complete batch')
        for frame in report['frames']:
            with Image.open(folder/f'{job["id"]}-{frame:03d}.png') as capture:
                if capture.size!=(1920,1080):raise ValueError('Invalid GPU capture dimensions')
        for component in report['components']:
            entry=accepted[component['id']]
            if entry['sheet_meta']['sha256']!=component['sheet_hash']:
                raise ValueError('GPU capture used another master: '+component['id'])
            if component.get('registration')!=registration(entry):
                raise ValueError('GPU capture used another registration: '+component['id'])
            entry['state']='qa_passed'
            entry['evidence']=str((folder/(job['id']+'.json')).relative_to(ROOT))
        ledger.write_text(json.dumps(accepted,ensure_ascii=False,indent=2)+'\n')
        build_catalog(accepted)
        print(job['id']+': visual GPU review recorded for '+str(len(report['components']))+' components')
        return
    variants=job['variants']
    sheet_name=job['id']
    if args.component:
        variants=[v for v in variants if v['id']==args.component]
        if len(variants)!=1 or not args.image:
            raise ValueError('A repair requires one known component and --image')
        index=job['variants'].index(variants[0])+1
        sheet_name+=f'_repair_{index:03d}'
    raw=args.image if args.component else SOURCE/(job['id']+'_generated.png')
    with Image.open(raw) as input_image:
        image=input_image.convert('RGBA')
    assignments=SOURCE/'region_assignments.json'
    assignment_windows=read(assignments).get(sheet_name) if assignments.exists() else None
    windows=regions(image,1 if args.component else job['columns'],1 if args.component else job['rows'],len(variants),assignment_windows)
    destination=ROOT/'assets/hd/avatars/xfs'/(sheet_name+'.png')
    shutil.copy2(raw,destination)
    sheet_meta=dict(file='res://'+destination.relative_to(ROOT).as_posix(),size=list(image.size),sha256=hashlib.sha256(destination.read_bytes()).hexdigest())
    for variant,region in zip(variants,windows):
        previous=accepted.get(variant['id'],{})
        state='qa_passed' if previous.get('state')=='qa_passed' and previous.get('sheet_meta')==sheet_meta else 'registered'
        x,y,w,h=region
        hist=image.crop((x,y,x+w,y+h)).getchannel('A').histogram()
        mean_alpha=sum(i*hist[i] for i in range(9,256))/max(1,sum(hist[9:]))/255
        accepted[variant['id']]=dict(**variant,region=region,sheet=sheet_name,sheet_meta=sheet_meta,state=state,generated_mean_opacity=mean_alpha,
                                     registered_at=datetime.now(timezone.utc).isoformat(),
                                     visual_review='identity/layout checked against batch reference before registration')
    overrides=SOURCE/'overrides.json'
    if overrides.exists():
        for identity,override in read(overrides).items():
            if identity not in accepted:
                continue
            source=accepted[override['reuse']]
            accepted[identity].update({name:source[name] for name in ['sheet','sheet_meta','region','generated_mean_opacity']})
            accepted[identity]['visual_review']=override['reason']
    ledger.write_text(json.dumps(accepted,ensure_ascii=False,indent=2)+'\n')
    catalog=build_catalog(accepted)
    print(f'{job["id"]}: registered {len(windows)} components; {image.size}; QA pending')
    print(f'Runtime: {len(catalog["layers"])} wearable/effect layers, {len(catalog["portraits"])} portraits')


if __name__=='__main__':
    main()
