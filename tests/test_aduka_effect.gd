extends "res://tests/support/suite.gd"

const Aduka = preload("res://scripts/aduka_effect.gd")
const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
const Weather = preload("res://scripts/weather.gd")

class TerrainStub extends RefCounted:
	var blocked := false
	var carved_at := Vector2.INF
	func world_size() -> Vector2: return Vector2(1800,1800)
	func native_solid(point: Vector2i) -> bool:
		return blocked and point.y>=350
	func carve_native(spans: Array[Vector3i]) -> int:
		carved_at = Vector2((spans[0].y+spans[0].z)/2,spans[0].x)
		return 3

class ModelStub extends RefCounted:
	var weather = Weather.new()
	var terrain = TerrainStub.new()
	var actors: Array = []
	var events: Array = []
	var battle_effects: Array = []
	var shot_actor := 0

func run() -> void:
	# Expectations transcribed from 0x541f10's PUSH immediates, not computed
	# with implementation formulas. Threshold + equality cases use SETG's ABI.
	var rows := [[100,44,1000,0x00ff00],[140,46,800,0x00c040],
		[180,48,700,0x008080],[220,50,600,0x0040c0],
		[260,52,500,0x0000ff],[300,54,400,0xffffff]]
	for index in rows.size():
		var data := Aduka.parameters(index+1)
		check([data.power,data.dimension,data.period,data.rgb] == rows[index],"Thor native table row%d" % index)
	check(Aduka.parameters(-5).power == 100 and Aduka.parameters(99).power == 300,"Invalid level cannot index outside six native cells")
	# Direct WORD samples from native-angle plus float32 sine bytes. Left/up
	# are179/89, not ideal180/90, and truncate to49px instead of50px.
	for sample in [[Vector2i(600,0),0,Vector2(50,0)],
		[Vector2i(-600,0),179,Vector2(-49,0)],[Vector2i(0,600),270,Vector2(0,50)],
		[Vector2i(0,-600),89,Vector2(0,-49)],[Vector2i(600,600),315,Vector2(35,35)],
		[Vector2i(-600,600),225,Vector2(-35,35)],[Vector2i(1000,-333),18,Vector2(47,-15)],
		[Vector2i(-1000,-333),161,Vector2(-47,-16)]]:
		check(Aduka.target_angle(sample[0]) == sample[1],"Native direct delta heading%s" % sample[0])
		check(Aduka.cannon(Vector2(100,100),Vector2(100,100)+Vector2(sample[0])) == Vector2(100,100)+sample[2],"Native cannon50px truncation%s" % sample[0])
	var stub := ModelStub.new()
	var absent_guide := {"flight":"aduka","weapon":1,"owner":1}
	check(Aduka.impact(stub,absent_guide,Vector2(600,600)),"Thor can be initialized without live climate")
	check(stub.weather.thor.pos == Vector2(900,270) and stub.weather.thor.present,"Offline initial position is deterministic map state")
	check(stub.weather.thor.level == 1 and stub.weather.thor.xp == 0,"Missing contact record cannot invent damage or XP")
	check(stub.events[-1].power == 100 and stub.events[-1].owner == 1 and not stub.events[-1].contact,"A missing contact still publishes the level1 visual ray")
	stub.terrain.blocked = true
	stub.weather.thor.level = 6
	stub.weather.thor.xp = 7000
	var max_guide := {"flight":"aduka","weapon":2,"owner":1}
	check(Aduka.impact(stub,max_guide,Vector2(600,600)),"SS produces its independent effect at level6")
	check(stub.events[-1].contact and stub.events[-1].power == 300 and stub.events[-1].position.y<600,"Native step2 resolves the obstacle before the requested guide target")
	check(stub.terrain.carved_at == stub.events[-1].position,"Beam carves at its recorded contact")
	check(stub.events[-1].level == 6 and stub.events[-1].new_level == 6 and stub.events[-1].rgb == 0xffffff,"Level6 preserves sixth native color")
	var copied_effects: Array = stub.battle_effects.duplicate(true)
	Aduka.tick(stub,copied_effects[0])
	check(copied_effects[0].tick == 0 and stub.battle_effects[0].tick == -1,"Prediction's visual state is deep-copy safe")
	var previous_climate := ModelStub.new()
	previous_climate.weather.thor.pos = Vector2(250,180)
	previous_climate.weather.thor.xp = 1601
	previous_climate.weather.thor.level = 4
	Aduka.ensure_thor(previous_climate)
	check(previous_climate.weather.thor.pos == Vector2(250,180),"A previous Thor weather position survives forced activation")
	check(previous_climate.weather.thor.xp == 1601 and previous_climate.weather.thor.level == 4,"Existing Thor progress is preserved")
	for fixture in [[0,1],[1,1],[199,1],[200,1],[201,2],[599,2],[600,2],
		[601,3],[1599,3],[1600,3],[1601,4],[3599,4],[3600,4],
		[3601,5],[6599,5],[6600,5],[6601,6],[999999,6]]:
		check(Aduka.level_for_xp(fixture[0]) == fixture[1],"Strict XP boundary%d" % fixture[0])
	var shell := {"flight":"aduka","damage":0,"blast_radius":0.0,"weapon":1,"owner":0}
	Aduka.prepare(shell)
	check(Aduka.active(shell) and not Aduka.active({"flight":""}),"Only Aduka guides use the effect")
	check(shell.damage == 0 and shell.blast_radius == 0.0 and not shell.thor,"Guide has no primary blast and no second weather Thor")
	var model := Match.new()
	model.start(16,1,44,"")
	model.weather.thor.active = false
	var target: Vector2 = Combat.box_center(model.actors[1])
	model.weather.thor.pos = target - Vector2(0,150)
	model.weather.thor.present = true
	var before: int = model.actors[1].hp + model.actors[1].shield
	check(Aduka.impact(model,shell,target),"S2 is handled without Thor weather")
	check(not model.weather.thor.active and model.weather.thor.present,"Forced Thor preserves climate but remains visible")
	check(model.actors[1].hp + model.actors[1].shield < before,"Zero-power S2 guide produces a separate damaging Thor")
	check(model.battle_effects.size() == 1,"One guide leaves exactly one visual beam")
	var effect: Dictionary = model.battle_effects[0]
	check(effect.owner == 0 and effect.weapon == 1 and effect.vehicle == 16,"Beam keeps original ownership and weapon")
	var thor_events := model.events.filter(func(event):return str(event.type)=="thor")
	check(thor_events.size() == 1 and thor_events[0].native and thor_events[0].guide_power == 0 and thor_events[0].power == 100,"Event distinguishes guide zero and Thor100")
	var saved: Dictionary = model.weather.thor.duplicate(true)
	check(not Aduka.impact(model,shell,target),"The same guide cannot strike twice")
	check(model.weather.thor == saved,"Duplicate impact does not grant XP")
	var clone = model.weather.copy()
	clone.thor.xp += 999
	check(clone.thor.xp != model.weather.thor.xp,"CPU Thor copy does not mutate live XP")
	# SS has three guides; each requests one strike, not one arbitrary T1 blast.
	for index in 3:
		var guide := {"flight":"aduka","weapon":2,"owner":0,"damage":0,"blast_radius":0.0}
		Aduka.prepare(guide)
		check(Aduka.impact(model,guide,target),"SS guide%d has its own Thor request" % index)
	check(model.battle_effects.size() == 4,"S2 plus three SS guides leave four separate beams")
	for fixture in [[0,16,255,16,255],[2,16,223,8,255],[10,26,95,1,255],[16,41,1,1,135],[19,52,1,1,75]]:
		var layers: Array = Aduka.beam_layers({"level":1,"period":1000,"rgb":0x00ff00},fixture[0])
		check([layers[0].half_width,layers[0].alpha,layers[1].half_width,layers[1].alpha] == fixture.slice(1),"Native two-layer beam raster tick%d" % fixture[0])
	var visual := {"kind":"aduka","tick":-1}
	for index in 20:
		check(Aduka.tick(model,visual),"Native ray remains alive tick%d" % index)
	check(not Aduka.tick(model,visual),"Native ray expires at increment20")
	finish("ADUKA EFFECT CHECKS")
