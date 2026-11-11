extends SceneTree
var scene
func _initialize():call_deferred("run")
func run():
 scene=load("res://scenes/main.tscn").instantiate()
 scene.profile=load("res://scripts/profile.gd").new("res://.tools/bigfoot-native/ui-profile.json")
 root.add_child(scene)
 scene.set_process(false)
 scene.sound.muted=true
 scene.match_seed=23
 scene.select_vehicle(1)
 scene.opening=0
 scene.start_match()
 scene.model.pass_turn()
 scene.consume_events()
 scene.model.actors[1].turns=3
 scene.model.weather.queue[0].type="thor"
 scene.model.weather.columns.clear()
 scene.model.weather.add_column("electricity",(scene.model.actors[0].pos.x+scene.model.actors[1].pos.x)/2,1)
 for i in 5:
  scene.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
 var times=[]
 var wall=[]
 var t0=Time.get_ticks_usec()
 var last=t0
 var input_us=-1
 var pause_frames=0
 var pause_model=[]
 var fire=false
 var weapon=-1
 while Time.get_ticks_usec()-t0<15000000:
  var frame_started=Time.get_ticks_usec()
  if times.size()==8:
   var before=Time.get_ticks_usec()
   scene.show_pause()
   input_us=Time.get_ticks_usec()-before
   pause_model=[scene.model.actors.duplicate(true),scene.model.projectiles.duplicate(true),scene.model.spark_tick]
  if times.size()==20:
   assert(pause_model==[scene.model.actors.duplicate(true),scene.model.projectiles.duplicate(true),scene.model.spark_tick])
   scene.close_overlay()
  var started=Time.get_ticks_usec()
  scene._process(1.0/60.0)
  times.append(Time.get_ticks_usec()-started)
  if scene.paused:pause_frames+=1
  if scene.model.phase!="aim":fire=true;weapon=scene.aim.weapon
  scene.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  wall.append(Time.get_ticks_usec()-frame_started)
  if fire:break
 var result={"fired":fire,"cpu_vehicle":scene.model.actors[1].vehicle,"frames":times.size(),"process_us":times,"render_frame_us":wall,"pause_input_us":input_us,"pause_frames":pause_frames,"wall_us":Time.get_ticks_usec()-t0}
 var f=FileAccess.open("res://.tools/bigfoot-native/ui-responsiveness.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(result,"  "))
 print("UI PROBE fired=",fire," frames=",times.size()," max_process_ms=",float(times.max())/1000," pause_input_ms=",float(input_us)/1000," wall_s=",float(result.wall_us)/1000000)
 scene.queue_free()
 await process_frame
 await process_frame
 quit(0 if fire else 1)
