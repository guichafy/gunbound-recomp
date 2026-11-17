"""Recognize rendered client raster controls, without fixed screen coordinates."""
from functools import lru_cache
from pathlib import Path
import json
import re

import cv2
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
LABELS=('CREATE','AVATAR','SETTINGS','START','SOLO','JEWEL','OK')
MAX_ERROR=0.04

def bright_panels(image: Image.Image):
    gray=cv2.cvtColor(np.asarray(image.convert('RGB')),cv2.COLOR_RGB2GRAY)
    _,_,stats,_=cv2.connectedComponentsWithStats((gray>120).astype(np.uint8),8)
    return [dict(left=int(x),top=int(y),width=int(w),height=int(h))
            for x,y,w,h,area in stats[1:]
            if w>=80 and h>=20 and area>=w*h*.8 and 2<w/h<12]

def control_regions(image: Image.Image):
    gray=cv2.cvtColor(np.asarray(image.convert('RGB')),cv2.COLOR_RGB2GRAY)
    contours,_=cv2.findContours(cv2.Canny(gray,50,100),cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE)
    candidates=[]
    minimum=max(20,min(image.size)*.025);maximum=min(image.size)*.22
    for contour in contours:
        x,y,w,h=cv2.boundingRect(contour)
        if minimum<w<maximum and minimum<h<maximum and .75<w/h<1.3 and cv2.contourArea(contour)>w*h*.75:
            candidates.append(dict(left=x,top=y,width=w,height=h))
    found=[]
    for region in sorted(candidates,key=lambda item:item['width']*item['height']):
        if not any(overlap(region,item)>.6 for item in found):found.append(region)
    if len(found)>64:raise ValueError('Too many control OCR candidate regions')
    return found

@lru_cache(maxsize=7)
def templates(label):
    if label in ('CREATE','AVATAR','START'):
        meta=json.loads((ROOT/'assets/classic/manifest.json').read_text())['strips']
        key={'CREATE':'b_gamelist_create','AVATAR':'b_gamelist_avatar','START':'b_ready_startgame'}[label]
        row=meta[key];path=ROOT/'assets/hd/classic/buttons_smooth_4x'/row['file']
        cell=row['frame_size'];density=4
        crop=(40,14,89,33) if label=='START' else (7,12,103,35)
    elif label in ('SETTINGS','SOLO'):
        family='settings' if label=='SETTINGS' else 'status'
        meta=json.loads((ROOT/f'assets/classic/room/{family}/catalog.json').read_text())['assets']
        row=meta['room_settings_word' if label=='SETTINGS' else 'room_mode']
        path=ROOT/f'assets/hd/classic/room_{family}_4x'/row['file']
        cell=row['frame_size'];density=4
        crop=(0,0,cell[0],cell[1])
    elif label=='JEWEL':
        meta=json.loads((ROOT/'assets/xfs/jewel/catalog.json').read_text())
        row=meta['sheets']['room_jewel'];cell=row['cell'];density=1
        path=ROOT/'assets/xfs/jewel/room_jewel.png'
        crop=(0,0,cell[0],cell[1])
    elif label=='OK':
        # Byte/pixel-identical native fallback verified by ClassicBattleOptionsArt.
        path=ROOT/'assets/xfs/hud_options_fallback/NativeOptionOK.png'
        meta=json.loads((path.parent/'catalog.json').read_text())
        cell=meta['entries']['b_option_confirm.img']['sizes'][0];density=1
        crop=(20,6,53,24)
    else:raise ValueError('Unsupported native label')
    with Image.open(path) as image:
        source=image.convert('RGBA')
        frames=[]
        # Client state3 is disabled and can never authorize a tap.
        for state in range(3):
            x=state*cell[0]*density
            part=source.crop((x+crop[0]*density,crop[1]*density,x+crop[2]*density,crop[3]*density))
            frames.append((np.asarray(part).copy(),density))
    return frames


def overlap(a,b):
    width=max(0,min(a['left']+a['width'],b['left']+b['width'])-max(a['left'],b['left']))
    height=max(0,min(a['top']+a['height'],b['top']+b['height'])-max(a['top'],b['top']))
    area=width*height
    return area/max(1,a['width']*a['height']+b['width']*b['height']-area)


def targets(image: Image.Image,pattern: str):
    wanted=[label for label in LABELS if re.fullmatch(pattern,label,re.I)]
    if not wanted:return []
    pixels=cv2.cvtColor(np.asarray(image.convert('RGB')),cv2.COLOR_RGB2BGR)
    coarse=cv2.resize(pixels,(image.width//2,image.height//2),interpolation=cv2.INTER_AREA)
    found=[]
    for label in wanted:
        # Battle options use the 800×500 HUD canvas; front screens use 800×600.
        base=min(image.width/800,image.height/(500 if label=='OK' else 600))
        for source,density in templates(label):
            seen=set()
            for step in range(11):
                scale=base*(1-step*.02)/density
                size=(round(source.shape[1]*scale),round(source.shape[0]*scale))
                if size in seen or min(size)<6:continue
                seen.add(size)
                paint=cv2.resize(source,size,interpolation=cv2.INTER_NEAREST)
                mask=(paint[:,:,3]>250).astype(np.uint8)*255
                if np.count_nonzero(mask)<20:continue
                rgb=cv2.cvtColor(paint[:,:,:3],cv2.COLOR_RGB2BGR)
                small=(max(1,size[0]//2),max(1,size[1]//2))
                scores=cv2.matchTemplate(coarse,cv2.resize(rgb,small,interpolation=cv2.INTER_AREA),
                                        cv2.TM_SQDIFF_NORMED,mask=cv2.resize(mask,small,interpolation=cv2.INTER_NEAREST))
                scores=np.nan_to_num(scores,nan=1,posinf=1,neginf=1)
                for _ in range(8):
                    error,_,at,_=cv2.minMaxLoc(scores)
                    if error>0.15:break
                    x,y=at;w,h=size
                    left=max(0,x*2-4);top=max(0,y*2-4)
                    region=pixels[top:min(image.height,y*2+h+5),left:min(image.width,x*2+w+5)]
                    refined=cv2.matchTemplate(region,rgb,cv2.TM_SQDIFF_NORMED,mask=mask)
                    refined=np.nan_to_num(refined,nan=1,posinf=1,neginf=1)
                    error,_,delta,_=cv2.minMaxLoc(refined)
                    scores[max(0,y-small[1]//2):y+small[1]//2+1,max(0,x-small[0]//2):x+small[0]//2+1]=1
                    if error>MAX_ERROR:continue
                    candidate=dict(left=left+delta[0],top=top+delta[1],width=w,height=h,text=label,error=float(error))
                    existing=next((i for i,item in enumerate(found) if item['text']==label and overlap(item,candidate)>.5),None)
                    if existing is None:found.append(candidate)
                    elif error<found[existing]['error']:found[existing]=candidate
    return found


def target(image: Image.Image,pattern: str):
    found=targets(image,pattern)
    if len(found)!=1:raise ValueError('Native raster target '+('missing' if not found else 'ambiguous'))
    return found[0]
