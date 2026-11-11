extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const NativeWeather = preload("res://scripts/aduka_weather.gd")
const Effects = preload("res://scripts/mage_weather_effects.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const STEP := 0.05
const Bigfoot = preload("res://scripts/bigfoot_combat.gd")

func fixture(opponent: int = 4):
	var m = Match.new()
	m.start(2, 1, 42, "", "original", null, [], [], [], 0, opponent)
	m.terrain.cells.fill(0)
	m.terrain.native_cells.fill(0)
	m.actors[0].pos = Vector2(200, 100)
	m.actors[1].pos = Vector2(1100, 200)
	m.actors[0].turns = 3
	m.wind = Vector2.ZERO
	m.weather.columns.clear()
	m.weather.queue = [{"type":"force"}]
	m.events.clear()
	return m

func run() -> void:
	var oracle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/bigfoot_native.json"))
	var m = fixture()
	# Removing the native geometry, per-component bonus divisor or native blast
	# must fail these PE-generated cases; no expected value comes from game code.
	for row in oracle.emission:
		var entries: Array = Mobiles.emission(2, int(row.weapon))
		check(entries.size() == row.shells.size(), "PE component count")
		for i in entries.size():
			var e: Dictionary = entries[i]
			var expected: Dictionary = row.shells[i]
			check(int(row.theta) + int(e.get("native_angle", 0)) == int(expected.theta), "PE theta component %d/%d" % [row.weapon, i])
			check(int(row.power) + int(e.get("native_power", 0)) == int(expected.power) and float(e.power) == 0.0, "PE power is native after quantization")
			check(is_equal_approx(float(e.spawn), float(expected.tick) * STEP), "EPA tick preserved")
		var facing := 1 if int(row.theta)<90 else -1
		var angle := float(row.theta) if facing>0 else 180.0-float(row.theta)
		var limits: Vector2 = Mobiles.aim_limits(2,int(row.weapon))
		if angle>=limits.x and angle<=limits.y:
			m.actors[0].facing=facing
			var shells: Array=m.projectile_parameters(0,angle,float(row.power)*10.0/42.0,int(row.weapon))
			for i in shells.size():
				var velocity: Array=row.shells[i].velocity_fp
				check(shells[i].launch_velocity_fp==Vector2i(int(velocity[0]),int(velocity[1])),"PE LUT launch, minimum/maximum and negative native power, both directions")
	for row in oracle.initialization:
		m.actors[0].attributes = [int(row.attack), 0, 0, 0, 0, 0, int(row.dig), 0]
		var shells: Array = m.projectile_parameters(0, 30, 50, int(row.weapon))
		for shell in shells:
			check(int(shell.damage) == int(row.fields[0]), "PE power includes divided Attack")
			check(int(shell.get("bigfoot_dimension", 0)) == int(row.fields[3]), "PE dimension includes separately truncated Dig")
			check(float(shell.blast_radius) == float(int(row.fields[3]) / 2), "Native integer radius")
	# Controlled native body: consumer oracle uses a flat24px body/vulnerability.
	# Keep geometry explicit so the visual hotspot bridge is not an oracle input.
	var saved: Dictionary = Shared.catalog.bodies["2"].duplicate(true)
	Shared.catalog.bodies["2"] = {"width":28,"height":24,"bottom":0,"origin_y":0,"flags":0,"vulnerability":100}
	var target := {"vehicle":2,"pos":Vector2(200,200),"tilt":0.0,"hp":10000,"shield":0,"attributes":[0,0,0,0,0,0,0,0]}
	for row in oracle.damage:
		m.actors[0].attributes = [int(row.attack),0,0,0,0,0,int(row.dig),0]
		var shell: Dictionary = m.projectile_parameters(0,30,50,int(row.weapon))[0]
		Shared.catalog.bodies["2"].vulnerability = int(row.vulnerability)
		var data := {"power":int(shell.damage),"dimension":int(shell.get("bigfoot_dimension",0)),
			"aspect":[134,124,126][int(row.weapon)],"flags":8,"percent":int(row.percent),"weather_bonus":int(row.force)}
		check(Shared.amount(target,Vector2i(200-int(row.dx),188-int(row.dy)),data) == int(row.amount), "Final PE damage, signs/percent/Force/vulnerability")
	Shared.catalog.bodies["2"] = saved
	for row in oracle.craters:
		m.actors[0].attributes = [int(row.attack),0,0,0,0,0,int(row.dig),0]
		m.actors[0].invulnerable = true
		m.actors[1].invulnerable = true
		m.terrain.cells.fill(1)
		m.terrain.native_cells.fill(1)
		var shell: Dictionary = m.projectile_parameters(0,30,50,int(row.weapon))[0]
		m.explode(Vector2(100,100),-1,shell)
		var expected := {}
		for span in row.spans:
			for x in range(int(span[1]),int(span[2])):
				expected[Vector2i(100+x,100+int(span[0]))] = true
		var same := true
		for y in range(55,145):
			for x in range(45,155):
				same = same and (not m.terrain.native_solid(Vector2i(x,y))) == expected.has(Vector2i(x,y))
		check(same,"Full native crater raster matches PE bitmap")
	for weapon in 3:
		m = fixture()
		check(NativeWeather.active(m.projectile_parameters(0,30,50,weapon)[0]),"Bigfoot explicitly uses native contact")
		check(Effects.shell_divisor(m.projectile_parameters(0,30,50,weapon)[0]) == [4,6,8][weapon],"Attached effects divided per salvo")
		for facing in [-1,1]:
			m = fixture()
			m.actors[0].facing = facing
			var shells: Array = m.projectile_parameters(0,90,100,weapon)
			# The clamped angle is40/35, then theta offsets; power420 offsets
			# remain above420 at full charge and below1 for the P−10 minimum.
			var geom: Array = Mobiles.emission(2,weapon)
			for i in shells.size():
				var angle: float = [40,40,35][weapon]
				var theta := int(angle if facing>0 else 180-angle) + int(geom[i].get("native_angle",0))
				var p := 420 + int(geom[i].get("native_power",0))
				var sine := FileAccess.get_file_as_bytes("res://assets/openbound/physics/native-sine-f32.bin").to_float32_array()
				var expected := Vector2i(int((int(sine[posmod(theta+90,360)]*p)<<8)/10),-int((int(sine[posmod(theta,360)]*p)<<8)/10))
				check(shells[i].launch_velocity_fp == expected,"Clamp then native spread, both directions")
	# Actual damage path, not just Shared.amount: a centered native blast.
	for weapon in 3:
		m = fixture()
		m.actors[0].invulnerable = true
		var shell: Dictionary = m.projectile_parameters(0,30,50,weapon)[0]
		var impact := Shared.center(m.actors[1])
		var expected := Shared.amount(m.actors[1],impact,{"power":[86,70,92][weapon],"dimension":[52,40,48][weapon],"aspect":[134,124,126][weapon],"flags":8})
		var hp := int(m.actors[1].hp)
		m.explode(Vector2(impact),1,shell)
		check(int(m.actors[1].hp) == hp-expected,"Match routes native power to final damage consumer")
	# A non-native opponent must not hide readiness; snapshots own both masks.
	for opponent in [2,3,4,14,15]:
		for weapon in 3:
			m = fixture(opponent)
			m.terrain.cells.fill(1)
			m.terrain.native_cells.fill(1)
			# Flat floor150; free muzzle and no incidental self contact.
			for y in range(150):
				for x in range(1280):
					m.terrain.native_cells[y*1280+x] = 0
			m.actors[0].pos = Vector2(200,110)
			m.actors[1].pos = Vector2(1100,110)
			var before: PackedByteArray = m.terrain.native_cells.duplicate()
			m.fire(30,35,weapon)
			var sim = Snapshot.capture(m)
			Snapshot.arm(sim,0,weapon,m.projectiles.duplicate(true))
			for i in range(1200):
				m.advance_projectiles(STEP/2)
				sim.advance_projectiles(STEP/2)
				if m.phase != Match.PHASE_FLIGHT:
					break
			check(m.phase==Match.PHASE_SETTLE and m.projectiles.is_empty(),"All bombs resolve and finish")
			check(m.terrain.native_cells==sim.terrain.native_cells and m.actors==sim.actors,"Execution equals independent snapshot")
			check(m.terrain.native_cells!=before,"Bombs carve non-native-opponent floor")
	test_quantized_tilt()
	test_interactions()
	finish("BIGFOOT NATIVE CHECKS")

func test_interactions() -> void:
	for weapon in 3:
		for item in ["", "dual", "dual_plus", "power_up", "blood", "bunge_shot", "thunder", "teleport"]:
			var m = fixture()
			m.actors[0].turn_item = item
			var shells: Array = m.shot_shells(0,30,35,weapon)
			var count: int = [4,6,8][weapon]
			var expected: int = count*2 if item=="dual" else (count+[6,4,4][weapon] if item=="dual_plus" else (1 if item=="teleport" else count))
			check(shells.size()==expected,"Item preserves native component grouping "+item)
			for shell in shells:
				check(Bigfoot.active(shell)==(item!="teleport"),"Beacon excluded from native combat")
				if item=="teleport":
					check(not NativeWeather.active(shell),"Beacon keeps its distinct terrain-only physics")
					continue
				var data := Bigfoot.parameters(shell,m.actors[0])
				check(int(data.percent)==(130 if item=="power_up" else (133 if item=="blood" else 100)),"Offline attack percentage bridge")
				check(int(shell.bigfoot_crater_percent)==(125 if item=="bunge_shot" else 100),"Bunge dimension percentage bridge")
				if int(shell.volley)==1:
					check(float(shell.pose_start_at)>1.0 and int(shell.damage)==[86,70,92][int(shell.weapon)],"Dual second weapon owns native damage and separate clock")
	# Isolate each attachment in the real impact path and count attribution only
	# from its new events. A second collect over old events would double Gold.
	for weapon in 3:
		for electric in [false,true]:
			var m = fixture()
			m.actors[1].pos = Vector2(400,130)
			m.actors[0].invulnerable = true
			m.weather.queue[0].type = "thor"
			m.fire(30,35,weapon)
			var shell: Dictionary = m.projectiles[0]
			shell.electric = electric
			var point := Vector2(Shared.center(m.actors[1]))
			m.events.clear()
			m.explode(point,1,shell)
			var thors: Array = m.events.filter(func(e):return e.type=="thor")
			check(thors.size()==1 and thors[0].source=="bigfoot_weather","One native Thor request per component")
			var flashes: Array = m.events.filter(func(e):return e.type=="mobile_lightning")
			check(flashes.size()==(1 if electric else 0),"One electricity attachment per component")
			var damage := 0
			for event in m.events:
				if event.type in ["damage","shield_damage"] and int(event.actor)==1:
					damage += int(event.amount)
			check(int(m.shot_gold.enemy_damage)==damage and damage>0,"Gold collects each damage event once")
			var explosions: Array = m.events.filter(func(e):return e.type=="explosion" and int(e.get("vehicle",0))==2)
			check(explosions.size()==1 and m.events.find(thors[0])<m.events.find(explosions[0]),"Thor precedes one Bigfoot blast")
	# Shared flight and CPU: Force/Tornado/electricity plus Thor are mutable
	# state, so compare every tick and mutate a deep snapshot after launching.
	for weapon in 3:
		for climate in ["force","tornado","electricity","thor"]:
			var m = fixture()
			m.actors[1].pos = Vector2(450,200)
			if climate=="thor":
				m.weather.queue[0].type="thor"
			else:
				m.weather.add_column(climate,300,1)
			m.fire(30,35,weapon)
			var sim = Snapshot.capture(m)
			Snapshot.arm(sim,0,weapon,m.projectiles.duplicate(true))
			sim.shot_gold=m.shot_gold.duplicate(true)
			m.events.clear()
			var identical := true
			for tick in 900:
				m.advance_projectiles(STEP/2)
				m.advance_projectiles(STEP/2)
				sim.advance_projectiles(STEP)
				identical = identical and m.events==sim.events and m.projectiles==sim.projectiles and m.actors==sim.actors and m.weather.thor==sim.weather.thor and m.shot_gold==sim.shot_gold
				m.events.clear()
				sim.events.clear()
				if m.phase!=Match.PHASE_FLIGHT:
					break
			check(identical and m.phase==Match.PHASE_SETTLE,"Fractional deltas and snapshot parity "+climate)
			var frozen: Array = m.actors.duplicate(true)
			var terrain: PackedByteArray = m.terrain.native_cells.duplicate()
			sim.actors[0].hp=1
			sim.terrain.native_cells[0]=1
			sim.weather.thor.xp=9999
			check(m.actors==frozen and m.terrain.native_cells==terrain and int(m.weather.thor.xp)!=9999,"Snapshot fields never alias the world")

func test_quantized_tilt() -> void:
	var m = fixture()
	m.actors[0].pos=Vector2(200,120)
	# Two real support columns yield a legal21-degree tilt. The selected
	# aim is half a degree either side of support, making theta quantize0.
	for y in range(75,400):m.terrain.cells[y*640+91]=1
	for y in range(82,400):m.terrain.cells[y*640+109]=1
	var rotation: float = m.body_rotation(0)
	check(rad_to_deg(rotation)>20.0,"Real sloped support fixture")
	for shift in [-0.5,0.5]:
		var angle: float = rad_to_deg(rotation)+shift
		var shells: Array = m.projectile_parameters(0,angle,50,0)
		var physics = load("res://scripts/classic_ballistics.gd")
		for component in [2,3]:
			var theta := 1 if component==2 else -1
			check(shells[component].launch_velocity_fp==physics.launch_velocity_fp(theta,210),"Native theta offset after truncation across zero")
