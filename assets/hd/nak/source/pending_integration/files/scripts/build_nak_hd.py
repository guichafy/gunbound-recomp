"""Catalog selected generated Nak PNGs, registration and flat HUD derivatives.

Only packing/cropping and density preparation occur here; no sprite painting.
The generated PNG bytes remain untouched. Source images are never modified.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/hd/nak'
SOURCE = OUT / 'source'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def rectangle(values):
    x0,y0,x1,y1=values
    return [x0,y0,x1-x0,y1-y0]

def crop_alpha(image, window):
    alpha=image.getchannel('A').point(lambda v:255 if v>8 else 0)
    bounds=alpha.crop(window).getbbox()
    if bounds is None:
        raise ValueError(f'Empty sprite window {window}')
    return rectangle([window[0]+bounds[0],window[1]+bounds[1],window[0]+bounds[2],window[1]+bounds[3]])

def build():
    masters=OUT/'masters.png'; effects=OUT/'effects.png'
    art=Image.open(masters).convert('RGBA')
    # Measured transparent gaps, not equal-cell guesses. No source pixels edited.
    windows={'mobile':[0,0,950,540],'s1':[950,0,1536,520],
             's2':[0,540,768,1024],'ss':[768,540,1536,1024]}
    if art.size != (1536,1024):
        raise ValueError('Selected master changed: inspect and remeasure windows')
    native={'mobile':[-23,-33,51,33],'s1':[-7,-7,15,14],
            's2':[-8,-8,16,17],'ss':[-23,-13,29,25]}
    data={'version':1,'alpha_threshold':8,'registration':{
        'native_cell':[74,57],'native_pivot':[37,50],
        'native_contact_y':53,'native_hull_width':51,
        'native_body_origin':[-4,-19],'native_body_at_support':[-4,-22]},
        'masters':{'path':'res://assets/hd/nak/masters.png','size':list(art.size),'sha256':sha(masters),'sprites':{}},
        'effects':{'path':'res://assets/hd/nak/effects.png','sprites':{}},'hud':{}}
    for key,window in windows.items():
        data['masters']['sprites'][key]={'window':window,'region':crop_alpha(art,window),'native_rect':native[key]}
    fx=Image.open(effects).convert('RGBA')
    data['effects'].update(size=list(fx.size),sha256=sha(effects))
    for row in range(4):
        for col in range(3):
            row_edges=[0,276,537,812,1024]
            window=[col*fx.width//3,row_edges[row],(col+1)*fx.width//3,row_edges[row+1]]
            key=f'impact_{row}_{col}' if row<3 else ['bubble','light_s1','light_s2'][col]
            data['effects']['sprites'][key]={'window':window,'region':crop_alpha(fx,window)}
            if row<3:
                originals=json.loads((ROOT/'assets/openbound/nak/frames.json').read_text())['sheets']
                name=f'Flame{row+1}.png';info=originals[name]
                frame=([0,3,8] if row<2 else [0,6,18])[col]
                w,h=info['cell'];columns=info['columns']
                image=Image.open(ROOT/'assets/openbound/nak'/name).convert('RGBA')
                bounds=image.crop((frame%columns*w,frame//columns*h,(frame%columns+1)*w,(frame//columns+1)*h)).getbbox()
                origin=info['origin']
                data['effects']['sprites'][key]['native_rect']=[bounds[0]-origin[0],bounds[1]-origin[1],bounds[2]-bounds[0],bounds[3]-bounds[1]]
    # Exact flat aim wedges: increased sampling density, not regenerated detail.
    for shot in ['S1','S2','SS']:
        for side in ['Ally','Enemy']:
            name=f'CrosshairNak{shot}{side}.png'
            src=ROOT/'assets/openbound/hud'/name
            im=Image.open(src).convert('RGBA')
            dest=ROOT/'assets/hd/hud'/name
            im.resize((im.width*3,im.height*3),Image.Resampling.LANCZOS).save(dest)
            data['hud'][name]={'method':'flat-source-density-3x','size':[im.width*3,im.height*3],
                               'sha256':sha(dest),'source_sha256':sha(src)}
    (OUT/'catalog.json').write_text(json.dumps(data,indent=2)+'\n')
    provenance={'generator':'built-in image_gen','mode':'transparent-reference-generation',
                'identity':['reference_runtime.png','reference_effects.png'],
                'style':'ref_style.png','selected':['gen_masters_v1.png','gen_effects_v1.png'],
                'prompts':['prompt_masters.txt','prompt_effects.txt'],
                'limitation':'Constant full-anatomy Nak master and procedural transforms; not all native gestures restored.',
                'art_dimensions':{k:data[k]['size'] for k in ['masters','effects']},
                'useful_dimensions':{group:{k:v['region'][2:] for k,v in data[group]['sprites'].items()} for group in ['masters','effects']}}
    (OUT/'GENERATION.json').write_text(json.dumps(provenance,indent=2)+'\n')
    print(json.dumps(provenance['useful_dimensions'],indent=2))

if __name__ == '__main__':
    build()
