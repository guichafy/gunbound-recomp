extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Snapshot = preload("res://scripts/flight_snapshot.gd")
const Ice = preload("res://scripts/ice_effects.gd")
const Damage = preload("res://scripts/damage.gd")
const Art = preload("res://scripts/battle_art.gd")
const NativeWeather = preload("res://scripts/aduka_weather.gd")

func fixture(opponent: int = 2):
	var m = Match.new()
	m.start(11,1,29,"","wind",null,[],[],[],0,opponent)
	m.actors[0].pos = Vector2(200,100)
	m.actors[1].pos = Vector2(1100,200)
	m.actors[0].invulnerable = true
	m.actors[0].turns = 3
	m.weather.columns.clear()
	m.events.clear()
	m.shot_actor = 0
	return m

func hit(m, weapon: int, point: Vector2i) -> void:
	m.shot_weapon = weapon
	var shell: Dictionary = m.projectile_parameters(0,30,50,weapon)[0]
	m.explode(Vector2(point),1,shell)

func run() -> void:
	oracle_cases()
	var m = fixture()
	m.actors[1].shield = 10000
	var old_attributes: Array = m.actors[1].attributes.duplicate(true)
	var impact := Shared.center(m.actors[1])
	hit(m,1,impact)
	check(m.actors[1].get("native_resistance",[]) == [0,0,5,0],"T2 applies third native field even with full shield")
	check(m.actors[1].hp == m.actors[1].max_hp,"Shield prevents all HP damage")
	check(m.actors[1].attributes == old_attributes,"Ice never modifies actor/profile attributes")
	for i in 12:
		hit(m,1,impact)
	check(m.actors[1].get("native_resistance",[]) == [0,0,50,0],"Repeated T2 saturates at50")
	hit(m,2,impact)
	check(m.actors[1].get("native_resistance",[]) == [5,5,20,5],"SS has its own cap20 and lowers a T2 field above20")
	var copy = Snapshot.capture(m)
	copy.actors[1]["native_resistance"] = [20,20,20,20]
	check(m.actors[1].get("native_resistance",[]) == [5,5,20,5],"Snapshot changes do not mutate live state")
	for distance in [129,130,131]:
		m = fixture()
		impact = Shared.origin(m.actors[1])-Vector2i(0,10)+Vector2i(distance,0)
		hit(m,2,impact)
		check(m.actors[1].get("native_resistance",[]) == ([5,5,5,5] if distance<130 else [0,0,0,0]),"SS strict radius boundary%d" % distance)
	for opponent in [2,11,15]:
		m = fixture(opponent)
		hit(m,1,Shared.center(m.actors[1]))
		check(m.actors[1].get("native_resistance",[]) == ([0,0,0,0] if opponent==15 else [0,0,5,0]),"T2 source type exclusion%d" % opponent)
	model_cases()
	finish("ICE EFFECTS CHECKS")

func oracle_cases() -> void:
	var oracle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/ice_native.json"))
	for row in oracle.damage:
		var actor := {"hp":int(row.hp),"shield":int(row.shield),"pos":Vector2.ZERO,
			"vehicle":15 if int(row.source_type)==14 else 11 if int(row.source_type)==10 else 4,
			"ice_alive":row.alive,"invulnerable":row.immune,"native_resistance":row.before.map(func(v): return int(v))}
		var amount := Ice.modify_damage(actor,int(row.power),int(row.flags)) if Ice.eligible(actor) and int(row.dx)==0 else 0
		check(amount==int(row.damage),"PE computed amount / sequential typed IDIV")
		if row.vector != null:
			Ice.t2(actor,amount)
		check(actor.native_resistance==row.after.map(func(v): return int(v)),"PE T2 state, limits and eligibility " + str(row) + " actual=" + str(actor.native_resistance))
		var events: Array = []
		Damage.deal_damage([actor],events,0,amount)
		check(actor.shield==int(row.shield_after),"PE shield consumer after state")
		check(actor.hp==maxi(0,int(row.hp_after)),"PE HP consumer with declared terminal0")
	for row in oracle.ss:
		var actor := {"hp":1000,"vehicle":15 if int(row.source_type)==14 else 11,
			"ice_alive":row.alive,"invulnerable":row.immune,"native_resistance":row.before.map(func(v): return int(v))}
		Ice.ss(actor,Vector2i(200,200),Vector2i(200-int(row.distance),190))
		check(actor.native_resistance==row.after.map(func(v): return int(v)),"PE SS real425ac0 area / capped4 fields " + str(row) + " actual=" + str(actor.native_resistance))
	for row in oracle.body:
		var m = fixture()
		m.actors[1].hp = int(row.hp)
		m.actors[1].shield = int(row.shield)
		m.actors[1].native_resistance = row.before.map(func(v): return int(v))
		var shell: Dictionary = m.projectile_parameters(0,30,50,1)[0]
		m.explode(Vector2(Shared.center(m.actors[1])-Vector2i(int(row.dx),0)),1,shell)
		check(m.actors[1].hp==maxi(0,int(row.hp_after)),"Match native Ice HP equals PE " + str(row) + " actual=" + str(m.actors[1].hp))
		check(m.actors[1].shield==int(row.shield_after),"Match native Ice shield equals PE " + str(row) + " actual=" + str(m.actors[1].shield))
		check(m.actors[1].native_resistance==row.after.map(func(v): return int(v)),"Match native Ice state equals PE")
	for row in oracle.initializers:
		var m = fixture()
		m.actors[0].attributes = [int(row.attack),0,0,0,0,0,int(row.dig),0]
		var shell: Dictionary = m.projectile_parameters(0,30,50,int(row.weapon))[0]
		var data := Ice.parameters(shell,m.actors[0])
		check(int(data.power)==int(row.power) and int(data.dimension)==int(row.dimension) and int(data.aspect)==int(row.aspect) and int(data.flags)==int(row.flags),"PE41da80 Ice initializer signed bonuses")
	var roster := [4,1,3,5,2,6,7,8,9,10,11,12,13,14,15,16]
	for row in oracle.masks:
		check(Ice.attack_mask(roster[int(row.source_type)],int(row.weapon))==int(row.flags),"PE41da80 attack mask for every mobile/weapon")

func model_cases() -> void:
	var presets := ConfigFile.new()
	check(presets.load("res://export_presets.cfg")==OK,"Export presets load")
	for section in ["preset.0","preset.1"]:
		check("assets/classic/ice_effects.json" in str(presets.get_value(section,"include_filter","")),"Both exports include Ice metadata")
	# Without shield the old implementation corrupts DEFENSE; fixture starts
	# from a caller-owned attribute allocation and must leave both unchanged.
	var m = fixture()
	var attrs: Array = m.actors[1].attributes.duplicate(true)
	hit(m,1,Shared.center(m.actors[1]))
	check(m.actors[1].attributes==attrs,"Unshielded T2 leaves DEFENSE allocation intact")
	check(m.events.filter(func(e): return e.type=="ice_effect").size()==1,"One pose publication per eligible target")
	var before: Array = m.actors.duplicate(true)
	var terrain: PackedByteArray = m.terrain.cells.duplicate()
	var predicted: Dictionary = m.predict_shot(0,30,50,1)
	check(not predicted.is_empty(),"CPU prediction completes with Ice state")
	check(m.actors==before and m.terrain.cells==terrain,"CPU search leaves live actors/terrain intact")
	var sim = Snapshot.capture(m)
	sim.actors[1].native_resistance[2] = 49
	check(int(m.actors[1].native_resistance[2])==5,"Snapshot nested array mutation is independent")
	# A missed SS still changes state inside130px; no HP/Gold event invented.
	m = fixture()
	var hp := int(m.actors[1].hp)
	hit(m,2,Shared.origin(m.actors[1])-Vector2i(0,10)+Vector2i(100,0))
	check(m.actors[1].hp==hp and m.actors[1].native_resistance==[5,5,5,5],"SS area effect without any HP damage")
	check(m.events.filter(func(e): return e.type in ["damage","shield_damage"]).is_empty(),"SS state creates no phantom Gold damage")
	for weapon in [1,2]:
		for kind in ["dead","immune"]:
			m = fixture()
			m.actors[1].hp = 0 if kind=="dead" else 1000
			m.actors[1].invulnerable = kind=="immune"
			hit(m,weapon,Shared.center(m.actors[1]))
			check(m.actors[1].native_resistance==[0,0,0,0],"No effect on%s target" % kind)
		m = fixture()
		m.actors[1].hp = 1
		hit(m,weapon,Shared.center(m.actors[1]))
		check(m.actors[1].hp==0 and m.actors[1].native_resistance==([0,0,5,0] if weapon==1 else [5,5,5,5]),"Lethal blast retains source alive eligibility within impact")
		check(not m.actors[1].has("ice_alive"),"Transient alive stamp cleared after impact")
		check(not NativeWeather.active(m.projectile_parameters(0,30,50,weapon)[0]),"Ice state does not activate another contact physics")
	# Rendering timer is independent of permanent fields; N−1/N/N+1.
	m = fixture()
	m.actors[1].native_resistance = [0,0,50,0]
	var art = Art.new()
	art.reset(m.actors)
	art.react({"type":"ice_effect","actor":1})
	check(art.state_name(m,1,false)=="ice","Native ice pose begins")
	art.tick(m,0.95)
	check(art.state_name(m,1,false)=="ice","Pose tick19 still ice")
	art.tick(m,0.05)
	check(art.state_name(m,1,false)!="ice","Pose ends at20ticks")
	art.tick(m,0.05)
	check(m.actors[1].native_resistance==[0,0,50,0],"Pose expiration never restores typed fields")
	var full = Snapshot.capture(m)
	var split = Snapshot.capture(m)
	var shells: Array = m.shot_shells(0,30,50,1)
	Snapshot.arm(full,0,1,shells.duplicate(true))
	Snapshot.arm(split,0,1,shells.duplicate(true))
	full.tick(0.05)
	for i in 5:
		split.tick(0.01)
	check(full.actors==split.actors and full.projectiles==split.projectiles,"Fractional deltas preserve physical state")
	var held: Array = full.actors.duplicate(true)
	full.tick(0.0)
	check(full.actors==held,"Zero time does not expire state")
