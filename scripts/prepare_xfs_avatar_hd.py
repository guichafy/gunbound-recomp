#!/usr/bin/env python3
"""Prepare reproducible HD jobs and an honest per-avatar migration dashboard.

Generation is not acceptance: new images only become registered through the
separate accepted.json ledger after identity/registration/render checks.
"""
from pathlib import Path
import csv
import hashlib
import html
import json
import math
import re
from PIL import Image, ImageDraw, ImageChops

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'assets/hd/avatars/xfs/source'
REPORT = ROOT/'docs/avatar-hd-migration'
NAMES = ['Cabeça','Corpo','Óculos','Bandeira']
RENDER_FILES = ['scripts/avatar_art.gd','scripts/avatar_xfs_hd.gd','scripts/avatar_contour_glow.gd','scripts/mobile_rig.gd','scripts/mage_sprite.gd','scripts/bigfoot_sprite.gd']


def renderer_hashes():
    return {name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in RENDER_FILES}


def registration(entry):
    return {name:entry.get(name,default) for name,default in [('sheet',''),('region',[]),('native_rect',[]),('effect',False),('pulsate',False),('reference_state',''),('attachment',{}),('draw_behind',False),('contour_glow',{}),('light_curve',[]),('overlay_base',{})]}


def read(path):
    return json.loads(path.read_text())


def alpha_box(image):
    return image.getchannel('A').point(lambda a:255 if a>8 else 0).getbbox()


def source_piece(row, number):
    layer = row['layers'][number]
    is_effect = layer['source'].lower().endswith('l.img')
    count = len(layer['frames'])
    frame = count//2 if count in (22,44) and row['category']!=1 else 0
    if row['category']==0 and count==22:
        # The first normal frames 11/12 blink. A constant HD head must use
        # the open-eye resting pose, not freeze the blink for the whole game.
        frame=16
    with Image.open(ROOT/layer['atlas'].removeprefix('res://')) as sheet:
        def crop(index):
            x,y,w,h = layer['frames'][index]['region']
            return sheet.crop((x,y,x+w,y+h)).convert('RGBA')
        if is_effect:
            # The largest visible effect phase is a fixed reference, not a
            # per-frame silhouette center used as an anatomical joint.
            def light_pixels(index):
                red,green,blue,alpha=crop(index).split()
                light=ImageChops.lighter(red,ImageChops.lighter(green,blue))
                return sum(ImageChops.multiply(light,alpha).histogram()[9:])
            # Head L sprites have the same Normal/Staring strips as the
            # anatomy. A frontal light can contain two horns while the
            # constant side-view head only has one visible horn.
            candidates=range(11,22) if row['category']==0 and count==22 else range(count)
            frame = max(candidates,key=light_pixels)
        image = crop(frame)
        if not alpha_box(image):
            visible=[i for i in range(count) if alpha_box(crop(i))]
            if visible:
                frame=visible[0]
                image=crop(frame)
    box = alpha_box(image)
    if not box:
        raise ValueError('Empty reference: '+layer['source'])
    ox,oy = layer['frames'][frame]['offset']
    hist=image.getchannel('A').histogram()
    opacity=sum(a*hist[a] for a in range(9,256))/max(1,sum(hist[9:]))/255
    return image, dict(original=layer['atlas'],source_name=layer['source'],
                      source_frame=frame,source_region=layer['frames'][frame]['region'],
                      native_rect=[ox+box[0]-5,oy+box[1]-5,box[2]-box[0],box[3]-box[1]],
                      effect=is_effect,frame_count=count,native_mean_opacity=opacity,pulsate=is_effect and opacity<0.85,
                      reference_state='normal' if row['category']==0 and count==22 else 'cycle')


def create_jobs(rows, aliases, portraits, accepted, only_ids=None, job_start=0):
    variants=[]
    for row in sorted(rows,key=lambda r:(r['category'],r['gender'],r['id'])):
        if not row['layers']:
            continue
        for number,layer in enumerate(row['layers']):
            if number==0 and row['key'] in aliases and not layer['source'].lower().endswith('l.img'):
                continue
            image,meta=source_piece(row,number)
            variants.append(dict(id=row['key']+'|layer:'+str(number),key=row['key'],layer=number,
                                 role='effect' if meta['effect'] else 'wearable',**meta))
        if row['key'] not in portraits:
            variants.append(dict(id=row['key']+'|portrait',key=row['key'],role='portrait',
                                 original=row['portrait'],source_name='s'+row['layers'][0]['source'],
                                 source_frame=0))
    if only_ids is not None:
        variants=[entry for entry in variants if entry['id'] in only_ids]
    jobs=[]
    for first in range(0,len(variants),32):
        cells=variants[first:first+32]
        number=first//32+1+job_start
        columns=4
        lines=math.ceil(len(cells)/columns)
        reference=SOURCE/f'batch_{number:03d}_reference.png'
        canvas=Image.new('RGBA',(columns*256,lines*256),(220,228,230,255))
        drawing=ImageDraw.Draw(canvas)
        descriptions=[]
        for index,entry in enumerate(cells):
            row=next(row for row in rows if row['key']==entry['key'])
            if entry['role']=='portrait':
                with Image.open(ROOT/entry['original'].removeprefix('res://')) as source:
                    image=source.convert('RGBA')
            else:
                image,_=source_piece(row,entry['layer'])
            box=alpha_box(image)
            if not box:
                raise ValueError('Empty source '+entry['id'])
            image=image.crop(box)
            scale=min(198/image.width,198/image.height)
            image=image.resize((max(1,round(image.width*scale)),max(1,round(image.height*scale))),Image.Resampling.NEAREST)
            x,y=(index%columns)*256,(index//columns)*256
            canvas.alpha_composite(image,(x+(256-image.width)//2,y+32+(208-image.height)//2))
            drawing.text((x+8,y+8),f'{index+1:02d} {entry["source_name"]} {entry["role"]}',fill='black')
            entry['cell']=[index%columns,index//columns]
            descriptions.append(f'cell {index+1}, row {index//columns+1} column {index%columns+1}: {row["name"]}, {entry["role"]}, {NAMES[row["category"]]}')
        canvas.save(reference)
        prompt=(
            'Use case: style-transfer. Production Gunbound Classic HD modular sprite atlas. '
            f'Image1 is an identity sheet of EXACTLY {len(cells)} distinct objects in a {columns}-column by {lines}-row grid. '
            'Image2 is approved HD STYLE ONLY. Preserve every object from image1 in its SAME cell, orientation, pose, silhouette, colors and proportions. '
            'Reconstruct as polished classic 2.5D game illustration: clean dark outlines, smooth toy-like volume, crisp material details, upper-left highlights. '
            'Real transparent RGBA background; no labels, text, grid, UI, shadows, vehicles, duplicates or added anatomy. '
            'Each object stays entirely inside its cell with generous transparent margins. Do not merge neighboring objects. '
            'Wearable heads retain their exact face/hair/helmet as shown. Wearable bodies MUST stay headless in the same compact seated pose, preserving arms and legs; never turn them into standing clothes. '
            'Portraits are separate shop assets: when the source shows only an empty helmet or garment, do not add a face or body. '
            'Glasses and flags remain isolated accessories. Effects remain isolated translucent effects, not a new character or backdrop. '
            'Do not copy image2 equipment or its layout. This must remaster image1, not redesign it. '
            'The requested layout and cell identities are: '+ '; '.join(descriptions))
        name=f'batch_{number:03d}'
        (SOURCE/(name+'_prompt.txt')).write_text(prompt+'\n')
        jobs.append(dict(id=name,reference=str(reference.relative_to(ROOT)),columns=columns,rows=lines,
                         prompt=prompt,variants=cells,status='accepted' if all(c['id'] in accepted for c in cells) else 'pending'))
    return jobs


def render_control(rows,aliases,portraits,accepted,jobs):
    generated={entry['id'] for job in jobs if (SOURCE/(job['id']+'_generated.png')).exists() for entry in job['variants']}
    hashes=renderer_hashes()
    runtime_path=REPORT/'qa/runtime-audit.json'
    audit=read(runtime_path) if runtime_path.exists() else {}
    runtime_valid=audit.get('renderer_hashes')==hashes and audit.get('failures',1)==0
    runtime_valid=runtime_valid and audit.get('registrations')=={identity:registration(entry) for identity,entry in accepted.items()}
    for sheet,sha in audit.get('sheet_hashes',{}).items():
        path=ROOT/'assets/hd/avatars/xfs'/(sheet+'.png')
        runtime_valid=runtime_valid and path.exists() and hashlib.sha256(path.read_bytes()).hexdigest()==sha
    covered=set(audit.get('covered',[])) if runtime_valid else set()
    evidence_cache={}
    def state(identity,default):
        entry=accepted.get(identity,{})
        value=entry.get('state',default)
        if value=='qa_passed':
            path=entry.get('evidence','')
            if path not in evidence_cache:
                evidence_cache[path]=read(ROOT/path) if path and (ROOT/path).is_file() else {}
            evidence=evidence_cache[path]
            component=next((c for c in evidence.get('components',[]) if c['id']==identity),{})
            if evidence.get('renderer_hashes')!=hashes or component.get('registration')!=registration(entry) or component.get('sheet_hash')!=entry['sheet_meta']['sha256']:
                value='registered'
        return value
    records=[]
    for row in rows:
        layers=[]
        for i,layer in enumerate(row['layers']):
            identity=row['key']+'|layer:'+str(i)
            reused=i==0 and row['key'] in aliases and not layer['source'].lower().endswith('l.img')
            layers.append(dict(id=identity,source=layer['source'],frames=len(layer['frames']),
                               state=state(identity,'legacy_bridge' if reused else ('generated_unreviewed' if identity in generated else 'pending')),
                               legacy_hd_key=aliases.get(row['key']) if reused else None))
        portrait_state='existing_hd' if row['key'] in portraits else state(row['key']+'|portrait','generated_unreviewed' if row['key']+'|portrait' in generated else 'pending')
        required=bool(layers)
        ready=required and all(layer['state']=='qa_passed' for layer in layers)
        preview=None
        if layers:
            entry=accepted.get(layers[0]['id'],{})
            evidence=entry.get('evidence','')
            if evidence:
                col,line=entry['cell']
                preview=dict(file=evidence.removesuffix('.json')+'-000.png',region=[col*480+180,line*135+18,290,106])
        records.append(dict(key=row['key'],name=row['name'],gender=row['gender'],category=row['category'],
                            buyable=row['buyable'],portrait=portrait_state if required else 'not_applicable',
                            wearable='hd' if ready else ('pending' if required else 'not_applicable'),
                            layers=layers,qa=('qa_passed' if ready and portrait_state in ('existing_hd','qa_passed') and row['key'] in covered else 'pending') if required else 'not_applicable',
                            native_portrait=row['portrait'],preview=preview,
                            reason='' if required else ('Sem acessório (padrão)' if row['empty'] else 'Placeholder sem arte no XFS')))
    summary=dict(records=len(records),wearable_required=sum(bool(r['layers']) for r in records),
                 layers_required=sum(len(r['layers']) for r in records),
                 wearable_hd=sum(r['wearable']=='hd' for r in records),
                 layers_hd=sum(l['state'] in ('existing_hd','qa_passed') for r in records for l in r['layers']),
                 portraits_hd=sum(r['portrait'] in ('existing_hd','qa_passed') for r in records),
                 qa_passed=sum(r['qa']=='qa_passed' for r in records),not_applicable=sum(not r['layers'] for r in records),
                 batches=len(jobs),generated_components=len(generated),registered_components=len(accepted),components_required=sum(len(job['variants']) for job in jobs),legacy_bridges=sum(l['state']=='legacy_bridge' for r in records for l in r['layers']),runtime_audit_valid=runtime_valid)
    report=dict(version=1,summary=summary,records=records)
    (REPORT/'catalog.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    with (REPORT/'migration.csv').open('w',newline='') as target:
        writer=csv.writer(target,lineterminator='\n')
        writer.writerow(['key','nome','genero','categoria','compravel','catalogo_hd','vestivel_hd','camadas_hd','camadas_total','validacao','motivo'])
        for r in records:
            writer.writerow([r['key'],r['name'],['Masculino','Feminino','Compartilhado'][r['gender']],NAMES[r['category']],r['buyable'],r['portrait'],r['wearable'],sum(l['state'] in ('existing_hd','qa_passed') for l in r['layers']),len(r['layers']),r['qa'],r['reason']])
    payload=json.dumps(report,ensure_ascii=False).replace('<','\\u003c')
    page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Migração Avatar HD</title>
<style>body{font:15px system-ui;background:#102532;color:#e8f6ff;margin:32px}h1{margin-bottom:6px}p{max-width:1000px;color:#b9d5df}input,select{padding:10px;margin:8px;background:#e5f5fa;border:0;border-radius:4px}table{width:100%;border-collapse:collapse}th,td{text-align:left;padding:9px;border-bottom:1px solid #315466}th{position:sticky;top:0;background:#174156}img{width:48px;height:45px;object-fit:contain;image-rendering:pixelated;background:#dbe5e5}svg{width:145px;height:53px;border-radius:3px}.stats{font-size:20px;color:#79e3ff}small{color:#c8d9df}a{color:#79e3ff}video{display:block;width:min(960px,100%);border-radius:6px;margin:20px 0}</style>
<h1>Controle da migração de avatares HD</h1><p>Miniatura da loja, peça vestida e validação de animação são etapas separadas. “HD existente” identifica arte aprovada anterior; arquivos novos só contam após aceite e validação. Padrões vazios e placeholders têm motivo N/A.</p><p class="stats" id="summary"></p><p id="progress"></p>
<video controls preload="metadata" poster="motion/0000.png" src="motion.mp4"></video><p><a href="migration.csv">Baixar controle CSV</a> · As prévias abaixo vêm da GPU: avatar vestido e mobile, com link para a comparação completa. A animação usa peças fixas com rig contínuo e efeitos separados.</p>
<input id="query" placeholder="Buscar nome ou ID"><select id="filter"><option value="all">Todos</option><option value="pending">Peça vestível pendente</option><option value="hd">Peça vestível HD</option><option value="not_applicable">N/A</option></select><span id="count"></span>
<table><thead><tr><th>Fonte</th><th>Vestido / mobile HD</th><th>Avatar / ID</th><th>Tipo</th><th>Catálogo</th><th>Peça vestida</th><th>Camadas</th><th>Animação / QA</th><th>Observação</th></tr></thead><tbody id="rows"></tbody></table>
<script id="data" type="application/json">DATA</script><script>
const data=JSON.parse(document.getElementById('data').textContent),s=data.summary;
document.getElementById('summary').textContent=`${s.wearable_hd}/${s.wearable_required} peças vestíveis HD · ${s.layers_hd}/${s.layers_required} camadas HD · ${s.portraits_hd}/${s.wearable_required} miniaturas HD · ${s.qa_passed}/${s.wearable_required} validados · ${s.not_applicable} N/A`;
document.getElementById('progress').textContent=`${s.generated_components}/${s.components_required} componentes gerados · ${s.registered_components} registrados · ${s.batches} lotes · Auditoria de uso real: ${s.runtime_audit_valid?'atualizada':'pendente'}`;
const labels={existing_hd:'HD anterior',qa_passed:'Validado',registered:'Integrado, aguarda QA',generated_unreviewed:'Gerado, aguarda revisão',legacy_bridge:'HD anterior provisório',pending:'Pendente',not_applicable:'N/A',hd:'HD validado'};
const query=document.getElementById('query'),filter=document.getElementById('filter');
function draw(){const rows=data.records.filter(r=>(r.name+' '+r.key).toLowerCase().includes(query.value.toLowerCase())&&(filter.value==='all'||r.wearable===filter.value));document.getElementById('count').textContent=rows.length+' registros';const body=document.getElementById('rows');body.replaceChildren();for(const r of rows){const tr=document.createElement('tr'),pic=document.createElement('td'),img=document.createElement('img');img.src='../../'+r.native_portrait.replace('res://','');img.loading='lazy';pic.append(img);tr.append(pic);const proof=document.createElement('td');if(r.preview){const link=document.createElement('a'),svg=document.createElementNS('http://www.w3.org/2000/svg','svg'),art=document.createElementNS('http://www.w3.org/2000/svg','image');link.href='../../'+r.preview.file;link.title='Ver comparação completa na GPU';svg.setAttribute('viewBox',r.preview.region.join(' '));art.setAttribute('href',link.href);art.setAttribute('width','1920');art.setAttribute('height','1080');svg.append(art);link.append(svg);proof.append(link)}tr.append(proof);for(const value of [r.name+' / '+r.key,['Cabeça','Corpo','Óculos','Bandeira'][r.category],labels[r.portrait],labels[r.wearable],r.layers.filter(l=>['existing_hd','qa_passed'].includes(l.state)).length+'/'+r.layers.length,labels[r.qa],r.reason]){const cell=document.createElement('td');cell.textContent=value;tr.append(cell)}body.append(tr)}}query.oninput=draw;filter.onchange=draw;draw();</script></html>'''
    (REPORT/'index.html').write_text(page.replace('DATA',payload))
    print(json.dumps(summary,ensure_ascii=False))


def main():
    SOURCE.mkdir(parents=True,exist_ok=True)
    (SOURCE/'.gdignore').touch()
    REPORT.mkdir(parents=True,exist_ok=True)
    rows=read(ROOT/'assets/xfs/avatars/catalog.json')['records']
    script=(ROOT/'scripts/avatar_art.gd').read_text()
    block=re.search(r'const XFS_HD_ALIASES := \{(.*?)\}',script,re.S).group(1)
    aliases=dict(re.findall(r'"([^"]+)":"([^"]+)"',block))
    portraits=read(ROOT/'assets/hd/shop/xfs_portraits.json')['regions']
    ledger=SOURCE/'accepted.json'
    accepted=read(ledger) if ledger.exists() else {}
    manifest=SOURCE/'jobs.json'
    if manifest.exists():
        jobs=read(manifest)['jobs']
    else:
        jobs=create_jobs(rows,aliases,portraits,accepted)
    # Keep already-generated job identities stable. Existing C# HD is a bridge,
    # not proof of exact XFS identity/registration, so schedule its native bases
    # too rather than silently claiming their migration is finished.
    existing={entry['id'] for job in jobs for entry in job['variants']}
    extra={row['key']+'|layer:0' for row in rows if row['key'] in aliases}-existing
    if extra:
        jobs+=create_jobs(rows,{},dict.fromkeys(row['key'] for row in rows),accepted,only_ids=extra,job_start=len(jobs))
    manifest.write_text(json.dumps(dict(version=1,jobs=jobs),ensure_ascii=False,indent=2)+'\n')
    render_control(rows,aliases,portraits,accepted,jobs)


if __name__=='__main__':
    main()
