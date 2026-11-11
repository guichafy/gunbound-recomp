extends SceneTree
func _initialize():call_deferred("run")
func run():
 var args=OS.get_cmdline_user_args()
 var kind=args[0]
 var seed_value=int(args[1]) if args.size()>1 else 81
 var implementation=load("res://.tools/bigfoot-native/profile/"+kind+"/scripts/match.gd")
 var m=implementation.new()
 m.start(1 if seed_value%2 else 2,seed_value%3,seed_value,"miramo_town_a","original",null,[],[],[],m.RANDOM_OPENING)
 var terrain_script=m.terrain.get_script()
 var started=Time.get_ticks_usec()
 var shots=[]
 var events={}
 var frames=0
 var launches=0
 var all_shells=0
 while frames<50000 and m.phase!="finished":
  if m.phase=="aim":
   var t=Time.get_ticks_usec()
   var actor=int(m.active)
   var shot=m.choose_cpu_shot()
   var elapsed=Time.get_ticks_usec()-t
   assert(m.fire(shot.angle,shot.power,shot.weapon))
   shots.append({"actor":actor,"vehicle":int(m.actors[actor].vehicle),"weapon":int(shot.weapon),"cpu_us":elapsed,"hp":[m.actors[0].hp,m.actors[1].hp]})
   for shell in m.projectiles:
    shell.probe_live_id=all_shells
    all_shells+=1
  m.tick(1.0/30.0)
  frames+=1
  for e in m.events:
   events[e.type]=int(events.get(e.type,0))+1
   if e.type=="projectile_launch":launches+=1
  m.events.clear()
 var duplicate=false
 for count in implementation.probe_live_explosions.values():duplicate=duplicate or int(count)>1
 var result={"mode":kind,"seed":seed_value,"finished":m.phase=="finished","winner":m.winner,"frames":frames,"shots":shots,"shells":all_shells,"launches":launches,"events":events,"duplicate_explosion":duplicate,"wall_us":Time.get_ticks_usec()-started,"match":implementation.probe_metrics,"terrain":terrain_script.probe_metrics}
 var file=FileAccess.open("res://.tools/bigfoot-native/profile-"+kind+"-"+str(seed_value)+".json",FileAccess.WRITE)
 file.store_string(JSON.stringify(result,"  "))
 print("PROFILE ",kind," seed",seed_value," shots=",shots.size()," wall_s=",float(result.wall_us)/1000000," duplicate=",duplicate," finished=",result.finished)
 quit(0 if result.finished and not duplicate else 1)
