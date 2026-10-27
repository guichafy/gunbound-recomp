extends "res://tests/support/suite.gd"
const Match = preload("res://scripts/match.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Lightning = preload("res://scripts/lightning_combat.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
class NativeWeatherFixture extends "res://scripts/weather.gd":
	var is_native := true
	var period := 2

func fixture():
	var model = Match.new()
	model.start(1,1,42,"","original",null,[],[],[],0,4)
	model.weather = NativeWeatherFixture.new()
	model.weather.queue = [{"type":"wind"}]
	model.terrain.enable_native()
	model.terrain.native_cells.fill(0)
	model.actors[0].pos = Vector2(50,50)
	model.actors[1].pos = Vector2(600,100)
	model.actors[0].tilt = 0.0
	model.actors[1].tilt = 0.0
	model.events.clear()
	return model

func shell(weapon: int = 0) -> Dictionary:
	return {"vehicle":1,"weapon":weapon,"owner":0,"electric":true,"native_force":0}

func run() -> void:
	var implementation = load("res://scripts/mage_weather_effects.gd") if ResourceLoader.exists("res://scripts/mage_weather_effects.gd") else null
	check(implementation != null,"Native attached Mage weather implementation exists")
	if implementation == null:
		finish("MAGE WEATHER EFFECTS CHECKS")
		return
	var model = fixture()
	var rows := [[0,0,115,27],[1,1,116,27],[3,3,119,27],[50,50,190,39],[-3,-3,110,26]]
	for row in rows:
		model.actors[0].attributes[Attributes.ATTACK] = row[0]
		model.actors[0].attributes[Attributes.DIG] = row[1]
		var parameters: Dictionary = implementation.parameters(shell(),model.actors[0])
		check(parameters.power==row[2] and parameters.dimension==row[3],"Independent PE divide-after-attributes fixture%s"%str(row))
		check(parameters.aspect==134 and parameters.flags==1,"Electrical blast owns Lightning T1 aspect/flags")
	model.actors[0].attributes.fill(0)
	var shot := shell()
	shot.native_force = 26
	check(implementation.parameters(shot,model.actors[0]).weather_bonus==0,"431d90 does not copy parent Force15c0 into auxiliary blast")
	check(implementation.shell_divisor(shell(1))==2 and implementation.shell_divisor(shell(0))==1 and implementation.shell_divisor(shell(2))==1,"Mage native divisors1/2/1")
	var seeds := [[0,633,464846],[1,564,79067],[42,735,262144],[4294967295,702,850625],[2147483648,1281,2148429995]]
	for row in seeds:
		var native: Dictionary = implementation.native_thor_position(row[0],1800)
		check(native.position==Vector2(row[1],500) and native.seed==row[2],"Unsigned PE LCG native Thor fixture%s"%str(row))
	check(implementation.setup_thor(model,42)==262144,"Setup returns advanced seed")
	check(model.weather.thor.pos==Vector2(475,500),"Procedural1280 world positions Thor from native width")
	check(model.weather.thor.present and model.weather.thor.native,"Thor exists outside Thor weather")
	model.weather.thor.xp=201
	model.weather.queue[0].type="thor"
	implementation.transition(model,1)
	check(model.weather.thor.level==2 and model.weather.thor.pos.y==540,"Turn transition recomputes level and advances Thor climate40")
	implementation.transition(model,1)
	check(model.weather.thor.pos.y==540,"Repeated same transition preserves position")
	model.weather.thor.xp=601
	implementation.transition(model,2)
	check(model.weather.thor.level==3 and model.weather.thor.pos.y==540,"Level updates on every turn; position only climate boundary")
	implementation.transition(model,3)
	check(model.weather.thor.pos.y==580,"Consecutive Thor boundary advances again")
	model.weather.thor.pos.y=990
	implementation.transition(model,5)
	check(model.weather.thor.pos.y==1000,"Thor target Y caps at1000")
	model.weather.queue[0].type="wind"
	implementation.transition(model,7)
	check(not model.weather.thor.active and model.weather.thor.pos.y==1000,"Leaving Thor keeps position and deactivates")
	test_electric_blast(implementation)
	test_electricity(implementation)
	test_thor_gate(implementation)
	finish("MAGE WEATHER EFFECTS CHECKS")

func test_electricity(implementation) -> void:
	for weapon in 3:
		var model = fixture()
		var width := int(model.terrain.world_size().x)
		model.terrain.native_cells[250*width+200]=1
		model.actors[1].vehicle=4 # mechanical feet=pos+(0,22)
		model.actors[1].pos=Vector2(200,128)
		model.actors[1].hp=1000
		model.actors[1].shield=0
		model.actors[1].attributes[Attributes.DEFENSE]=50
		implementation.impact(model,shell(weapon),Vector2(200,300))
		check(model.actors[1].has("lightning_pending"),"Attached electricity queues shock before blast weapon%d"%weapon)
		check(model.actors[1].hp==1000,"Far upstream feet receive shock without blast weapon%d"%weapon)
		Lightning.resolve(model)
		check(model.actors[1].hp==(968 if weapon==1 else 957),"Mechanical attached shock32/43 ignores Defense50 weapon%d"%weapon)
		var explosions: Array=model.events.filter(func(event): return event.type=="explosion")
		check(explosions.size()==1 and explosions[0].position==Vector2(200,250),"Attached blast uses first original solid pixel")
		check(explosions[0].vehicle==8 and explosions[0].weapon==0 and explosions[0].native_attached and explosions[0].source=="weather","Attached explosion uses native Lightning art metadata")
	# Void suppresses blast while the vertical ray/shock can still exist.
	var model=fixture()
	model.actors[1].vehicle=4
	model.actors[1].pos=Vector2(200,128)
	model.actors[1].hp=1000
	model.actors[1].shield=0
	implementation.impact(model,shell(),Vector2(200,300))
	check(model.events.filter(func(event): return event.type=="explosion").is_empty(),"No terrain does not invent a weather blast")
	check(model.events.filter(func(event): return event.type=="mobile_lightning").size()==1,"Void retains native visual ray")
	Lightning.resolve(model)
	check(model.actors[1].hp==957,"Void still samples shock from clamped map bottom")
	# Chain strict25, and direct shock uses a separate pending record.
	for distance in [24,25]:
		model=fixture()
		model.terrain.native_cells[250*int(model.terrain.world_size().x)+200]=1
		model.actors[1].vehicle=4
		model.actors[1].pos=Vector2(200,128)
		model.actors[1].hp=1000
		model.actors[1].shield=0
		model.actors[0].vehicle=8
		model.actors[0].pos=Vector2(200+distance,127) # Lightning feet150
		model.actors[0].hp=750
		model.actors[0].shield=0
		implementation.impact(model,shell(),Vector2(200,300))
		# radius25 direct also reaches dx24: remove it to isolate chain contract.
		model.actors[0].erase("lightning_pending")
		Lightning.resolve(model)
		check(model.actors[0].hp==(730 if distance==24 else 750),"Weather chain20 strict25px distance%d"%distance)

func test_thor_gate(implementation) -> void:
	var model=fixture()
	implementation.setup_thor(model,42)
	var shot:=shell(1)
	shot.electric=false
	shot.thor=true
	implementation.impact(model,shot,Vector2(200,300))
	check(model.events.filter(func(event): return event.type=="thor").is_empty(),"Launch Thor flag does not replace current weather gate")
	model.weather.queue[0].type="thor"
	shot.thor=false
	implementation.impact(model,shot,Vector2(200,300))
	var beams: Array=model.events.filter(func(event): return event.type=="thor")
	check(beams.size()==1 and beams[0].source=="mage_weather","Current Thor weather attaches even without launch flag")
	check(beams[0].power==50 and beams[0].period==2000,"Mage T2 halves Thor power and doubles beam period")
	# Both effects must be published before caller's own Mage blast/EMP.
	model=fixture()
	implementation.setup_thor(model,42)
	model.weather.queue[0].type="thor"
	model.terrain.native_cells[250*int(model.terrain.world_size().x)+200]=1
	implementation.impact(model,shell(),Vector2(200,300))
	var electric_index: int=-1
	var thor_index: int=-1
	for index in model.events.size():
		if model.events[index].type=="explosion" and model.events[index].get("native_attached",false):electric_index=index
		if model.events[index].type=="thor":thor_index=index
	check(electric_index>=0 and thor_index>electric_index,"Native attached electricity precedes Thor")

func test_electric_blast(implementation) -> void:
	for force in [0,26]:
		var model=fixture()
		model.terrain.native_cells[250*int(model.terrain.world_size().x)+200]=1
		model.actors[1].vehicle=4 # origin22-height/2=pos+10, vulnerability84+electric4
		model.actors[1].pos=Vector2(200,240)
		model.actors[1].hp=1000
		model.actors[1].shield=20
		var shot:=shell()
		shot.native_force=force
		implementation.impact(model,shot,Vector2(200,300))
		#115*1000/1000; *88/100=101; shield20 thenHP81. Parent Force
		#15c0 is absent in the new blast; copied17e4 is the separate percentage.
		check(model.actors[1].hp==919 and model.actors[1].shield==0,"Auxiliary weather blast excludes parent Force%s"%force)
		check(model.actors[1].has("lightning_pending"),"Blast leaves separately pending weather shock")
	# A lethal native blast retains the pre-impact alive eligibility for chain20.
	var model=fixture()
	model.terrain.native_cells[250*int(model.terrain.world_size().x)+200]=1
	model.actors[1].vehicle=4
	model.actors[1].pos=Vector2(200,240)
	model.actors[1].hp=1
	model.actors[1].shield=0
	model.actors[0].vehicle=8
	model.actors[0].pos=Vector2(224,239) # both native originsY262
	model.actors[0].hp=750
	model.actors[0].shield=0
	implementation.impact(model,shell(),Vector2(200,300))
	check(model.actors[1].hp==0 and model.actors[1].get("lightning_alive",false),"Native electricity queues shock before lethal auxiliary blast")
	model.actors[0].erase("lightning_pending")
	var before:=int(model.actors[0].hp)
	Lightning.resolve(model)
	check(model.actors[0].hp==before-20,"Lethal auxiliary blast still permits native secondary chain")
