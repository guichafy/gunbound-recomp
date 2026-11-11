from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[3]
for kind,revision in [('baseline','035d8e172bfdf5a0cf35c2d4683d7d3dbbe3a679'),('current',None)]:
 out=root/f'.tools/bigfoot-native/profile/{kind}'
 files=subprocess.check_output(['git','ls-tree','-r','--name-only',revision or 'HEAD','scripts']).decode().splitlines()
 for f in files:
  if not f.endswith('.gd'):continue
  data=subprocess.check_output(['git','show',f'{revision}:{f}']).decode() if revision else (root/f).read_text()
  data=data.replace('res://scripts/','res://.tools/bigfoot-native/profile/'+kind+'/scripts/')
  if f=='scripts/match.gd':
   data=data.replace('extends RefCounted','extends RefCounted\nstatic var probe_metrics := {"predict_calls":0,"predict_us":0,"tick_calls":0,"tick_us":0,"settle_calls":0,"settle_us":0,"explode_calls":0,"explode_us":0}\nstatic var probe_live_explosions := {}',1)
   for name,signature,args,ret,prefix in [('predict_shot','index: int, angle: float, power: float, weapon: int','index,angle,power,weapon','Dictionary','predict'),('advance_projectile_tick','delta: float','delta','void','tick'),('settle_actors','','','void','settle'),('explode','position: Vector2, collided_actor: int = -1, projectile: Dictionary = {}','position,collided_actor,projectile','void','explode')]:
    marker=f'func {name}('
    data=data.replace(marker,f'func probe_{name}_impl(',1)
    wrapper=f'\nfunc {name}({signature}) -> {ret}:\n\tvar started := Time.get_ticks_usec()\n\tprobe_metrics.{prefix}_calls += 1\n'
    if name=='explode':wrapper+='\tif projectile.has("probe_live_id"):\n\t\tprobe_live_explosions[projectile.probe_live_id]=int(probe_live_explosions.get(projectile.probe_live_id,0))+1\n'
    wrapper+= ('\tvar outcome = ' if ret!='void' else '\t')+f'probe_{name}_impl({args})\n\tprobe_metrics.{prefix}_us += Time.get_ticks_usec()-started\n'
    if ret!='void':wrapper+='\treturn outcome\n'
    data+=wrapper
  if f=='scripts/terrain.gd':
   data=data.replace('extends RefCounted','extends RefCounted\nstatic var probe_metrics := {"carve_calls":0,"carve_us":0,"copy_calls":0,"copy_us":0}',1)
   for name,sig,args,ret,prefix in [('carve_native','spans: Array[Vector3i]','spans','int','carve'),('collision_copy','','','','copy')]:
    data=data.replace('func '+name+'(','func probe_'+name+'_impl(',1)
    data+=f'\nfunc {name}({sig})'+(f' -> {ret}' if ret else '')+':\n\tvar started := Time.get_ticks_usec()\n\tprobe_metrics.'+prefix+'_calls += 1\n\tvar outcome = probe_'+name+'_impl('+args+')\n\tprobe_metrics.'+prefix+'_us += Time.get_ticks_usec()-started\n\treturn outcome\n'
  target=out/f;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(data)
print('Built isolated baseline/current source copies with counters only')
