extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")

func run() -> void:
	var model=Match.new()
	model.start(1,1,42,"")
	model.weather.columns.clear()
	model.terrain.native_cells.fill(0)
	var shell: Dictionary=model.shot_shells(0,35,30,0)[0]
	model.events.clear()
	Shared.projectile_contact(Vector2i(100,100),Vector2i(116,108),model.terrain,[],shell,model)
	var batches: Array=model.events.filter(func(event):return event.type=="mage_spark_samples")
	check(batches.size()==1,"Mage physical scanner publishes one compact visual sample batch")
	if batches.is_empty():
		finish("MAGE SPARKS CHECKS")
		return
	check(batches[0].samples==PackedInt32Array([100,103,0,0,108,107,0,0,116,111,0,0]),"Independent minor-first native coarse points; Force0 trials retained")
	model.weather.add_column("force",100,1.0)
	model.weather.add_column("electricity",100,1.0)
	model.events.clear()
	Shared.projectile_contact(Vector2i(100,100),Vector2i(116,100),model.terrain,[],shell,model)
	batches=model.events.filter(func(event):return event.type=="mage_spark_samples")
	check(batches[0].samples==PackedInt32Array([100,100,20,1,108,100,20,1,116,100,20,1]),"Same coarse point acquires Electric and clamps Force once before visual trial")
	for x in range(104,129):model.terrain.native_cells[100*1280+x]=1
	model.events.clear()
	var contact: Dictionary=Shared.projectile_contact(Vector2i(100,100),Vector2i(116,100),model.terrain,[],shell,model)
	batches=model.events.filter(func(event):return event.type=="mage_spark_samples")
	check(contact.position==Vector2(104,100) and batches[0].samples.size()==8,"Contact refinement creates no extra spark trials")
	model.terrain.native_cells.fill(0)
	for vehicle in [1,2,8,16]:
		model.events.clear()
		shell.vehicle=vehicle
		Shared.projectile_contact(Vector2i(100,100),Vector2i(100,100),model.terrain,[],shell,model)
		check(model.events.filter(func(event):return event.type=="mage_spark_samples").size()==(1 if vehicle==1 else 0),"Decorative sample replacement limited to Mage%d"%vehicle)
	check(ResourceLoader.exists("res://scripts/mage_sparks.gd"),"Native Mage spark lifetime and visual RNG consumer exists")
	if not ResourceLoader.exists("res://scripts/mage_sparks.gd"):
		finish("MAGE SPARKS CHECKS")
		return
	var Sparks=load("res://scripts/mage_sparks.gd")
	var sparks=Sparks.new()
	check(not Sparks.force_passes(0,3,0) and Sparks.force_passes(20,3,59) and not Sparks.force_passes(20,3,60),"Strict nativeForce threshold")
	check(Sparks.electric_passes(3,2) and not Sparks.electric_passes(3,3),"Strict nativeElectric threshold")
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/mage_spark_rng.json"))
	sparks.reset(42)
	sparks.sync(8)
	sparks.accept({"tick":8,"samples":PackedInt32Array(data.samples)})
	check(sparks.random_state==int(data.final_state),"MSVCRT random schedule includes failed Force0 trials and birth draws")
	check(sparks.particles.size()==data.particles.size(),"Independent native probability fixture particle count")
	for i in sparks.particles.size():
		var p: Dictionary=sparks.particles[i]
		var expected: Dictionary=data.particles[i]
		check(p.kind==expected.kind and p.position==Vector2i(expected.position[0],expected.position[1]) and p.angle==int(expected.angle),"Independent birth offsets/angle plus first Animate")
		check(p.tick==1,"Born particle is already updated in the same native step")
	var born: Array=sparks.particles.duplicate(true)
	sparks.sync(22)
	check(sparks.particles.size()==born.size() and sparks.particles.all(func(p):return p.tick==15),"Clock15 still visible")
	for i in sparks.particles.size():check(sparks.particles[i].position==born[i].position,"Sparks stay at fixed birth points")
	sparks.sync(23)
	check(sparks.particles.is_empty(),"Clock16 removed before draw")
	sparks.reset(42)
	sparks.sync(10)
	sparks.accept({"tick":8,"samples":PackedInt32Array(data.samples)})
	check(sparks.particles.all(func(p):return p.tick==3),"Batched simulation steps catch up births without frame dependence")
	sparks.reset(42)
	check(sparks.particles.is_empty() and sparks.tick==0,"Reset clears particles and clock")
	sparks.accept({"tick":8,"samples":PackedInt32Array(data.samples)})
	check(sparks.particles.all(func(p):return p.tick==1),"Direct event delivery advances to its native timestamp")
	for weapon in 3:
		var reference=timeline(weapon,1.0/60,120)
		for timing in [[1.0/30,60],[0.1,20],[0.025,80]]:
			check(reference==timeline(weapon,timing[0],timing[1]),"Mage FX fixed steps independent of frame grouping weapon%d step%s"%[weapon,timing[0]])
	finish("MAGE SPARKS CHECKS")

func timeline(weapon: int, step: float, frames: int) -> Dictionary:
	var model=Match.new()
	model.start(1,1,42,"")
	model.weather.columns.clear()
	model.weather.queue[0].type="wind"
	model.weather.thor.active=false
	model.terrain.native_cells.fill(0)
	model.actors[0].pos=Vector2(650,300)
	model.actors[1].pos=Vector2(1100,700)
	model.wind=Vector2.ZERO
	var shells: Array=model.shot_shells(0,35,30,weapon)
	model.weather.add_column("force",shells[0].pos.x,2.0)
	model.weather.add_column("electricity",shells[0].pos.x,2.0)
	var visual=load("res://scripts/weather_art.gd").new()
	var sound=load("res://scripts/sound.gd").new()
	sound.muted=true
	model.events.clear()
	model.fire(35,30,weapon)
	for frame in frames:
		model.tick(step)
		visual.tick(step,model)
		for event in model.events:visual.react(event,model,sound)
		model.events.clear()
	var result:={"particles":visual.mage_sparks.particles.duplicate(true),"random_state":visual.mage_sparks.random_state,"tick":model.spark_tick,"actors":model.actors.duplicate(true)}
	sound.free()
	return result
