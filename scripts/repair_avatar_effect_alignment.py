#!/usr/bin/env python3
"""Refresh only head-light reference states; generated masters stay preserved."""
import json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from prepare_xfs_avatar_hd import ROOT,SOURCE,read,source_piece
from register_xfs_avatar_hd import build_catalog
# Coordinates measured on the selected HD head's alpha window. The effect
# retains its own fixed aspect/size; these points attach matching features.
ATTACHMENTS={
 'xfs:1:0:2':('lamp', [.065,.32],[.96,.52],1),
 'xfs:1:0:7':('visor', [.47,.39],[.5,.5],1),
 'xfs:1:0:8':('forehead jewel', [.26,.32],[.5,.5],1),
 'xfs:1:0:15':('crown', [.66,.14],[.5,.6],.6),
 'xfs:1:0:20':('veil', [.21,.46],[.35,.44],1),
 'xfs:1:0:22':('halo', [.5,.3],[.5,.6],1),
 'xfs:1:0:25':('cobra tip', [.12,.30],[.5,.5],1),
 'xfs:1:0:35':('feather jewel', [.33,.29],[.5,.5],1),
 'xfs:1:0:38':('gold bangs', [.33,.6],[.5,.5],1),
 'xfs:1:0:41':('silver cap', [.5,.13],[.5,.5],1),
 'xfs:1:0:44':('gold ribbon stars', [.6,.35],[.5,.5],.85),
 'xfs:1:0:45':('silver brim', [.45,.50],[.5,.5],1),
 'xfs:1:0:46':('flower', [.47,.33],[.5,.5],1),
 'xfs:1:0:47':('veil jewels', [.66,.43],[.5,.5],1),
 'xfs:0:0:2':('lamp', [.05,.28],[.96,.5],1),
 'xfs:0:0:4':('red forehead jewel', [.15,.36],[.5,.5],1),
 'xfs:0:0:8':('visor', [.47,.3],[.5,.5],1),
 'xfs:0:0:14':('cobra jewel', [.15,.28],[.5,.5],1),
 'xfs:0:0:45':('front jewel', [.2,.50],[.5,.5],1),
 'xfs:0:0:71':('single profile horn', None,None,None),
}

def main():
    folder=SOURCE/'effect_alignment';folder.mkdir(exist_ok=True)
    jobs=read(SOURCE/'jobs.json');accepted=read(SOURCE/'accepted.json')
    before=folder/'jobs_before_state_fix.json'
    if not before.exists():before.write_text(json.dumps(jobs,ensure_ascii=False,indent=2)+'\n')
    rows=read(ROOT/'assets/xfs/avatars/catalog.json')['records']
    heads=[r for r in rows if r['category']==0 and len(r['layers'])==2]
    updates=[]
    for row in heads:
        _,meta=source_piece(row,1)
        identity=row['key']+'|layer:1';entry=accepted[identity]
        feature,base_uv,effect_uv,scale=ATTACHMENTS[row['key']]
        if row['key']=='xfs:0:0:71':
            # Horn light is derived from the HD horn itself; see
            # build_devil_horn_light.py. Never restore the bent crescent.
            meta['draw_behind']=False
            for name in ('attachment','light_curve','contour_glow'):entry.pop(name,None)
        else:
            meta['attachment']=dict(feature=feature,base_uv=base_uv,effect_uv=effect_uv,scale=scale)
        changed=any(entry.get(k)!=v for k,v in meta.items())
        entry.update(meta)
        entry['normal_reference']='assets/hd/avatars/xfs/source/effect_alignment/reference_effects_normal.png'
        if changed:entry['state']='registered'
        for job in jobs['jobs']:
            for variant in job['variants']:
                if variant['id']==identity:
                    variant.pop('contour_glow',None)
                    if row['key']=='xfs:0:0:71':
                        for name in ('attachment','light_curve'):variant.pop(name,None)
                    variant.update(meta)
        updates.append(dict(id=identity,source_frame=meta['source_frame'],native_rect=meta['native_rect']))
    (SOURCE/'jobs.json').write_text(json.dumps(jobs,ensure_ascii=False,indent=2)+'\n')
    (SOURCE/'accepted.json').write_text(json.dumps(accepted,ensure_ascii=False,indent=2)+'\n')
    (folder/'reference_updates.json').write_text(json.dumps(updates,indent=2)+'\n')
    build_catalog(accepted)
    print('20 head-light Normal references refreshed; anatomical GPU review pending')
if __name__=='__main__':main()
