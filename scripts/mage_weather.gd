extends "res://scripts/weather.gd"
## Native client calendar (41fd50/41f200), Moon43c6a0 and Eclipse43a670.
## RNG seeds, period2 and default world-wide column ranges are offline inputs.
## protection/ignorance are presentation aliases for native Moon/Eclipse.
const Body = preload("res://scripts/aduka_combat.gd")
const Integer = preload("res://scripts/classic_ballistics.gd")
const NATIVE_TYPES := ["force","tornado","electricity","wind","thor","protection","ignorance"]
const LEGACY_INDICES := [0,1,2,3,7,5,6]
const MASK32 := 0xffffffff
const TABLE_MASK := 1023
var is_native := true
var calendar: Array = []
var random_table: Array = []
var random_cursor := 0
var native_seed := 0
var crt_seed := 0
var next_wind_force := 0
var next_wind_delta := 0
var period := 2
# Optional stage rows: type -> eight Vector2i(min,max) pairs; max is exclusive.
var spawn_ranges: Dictionary = {}
var last_turn := -1

func setup(preset: Array, world_size: Vector2, rng: RandomNumberGenerator) -> Dictionary:
	Body.warmup()
	world = world_size
	weights.clear()
	for index in NATIVE_TYPES.size():
		var source := int(LEGACY_INDICES[index]) if preset.size()>=10 else index
		weights.append(maxi(0,int(preset[source])) if source<preset.size() else 0)
	calendar.clear()
	for category in NATIVE_TYPES.size():
		for _count in mini(int(weights[category]),8-calendar.size()):
			calendar.append(category)
	while calendar.size()<8:
		calendar.append(0)
	native_seed = rng.seed&MASK32
	crt_seed = rng.seed&MASK32
	for _swap in 31:
		var first := _lcg()&7
		var second := _lcg()&7
		var value: int = calendar[first]
		calendar[first] = calendar[second]
		calendar[second] = value
	wind_force = _lcg()%26
	wind_angle = _lcg()%360
	next_wind_force = (_lcg()&15)-8
	next_wind_delta = _lcg()%80-40
	random_table.clear()
	for _index in 1024:
		random_table.append(_lcg())
	random_cursor = 0
	columns.clear()
	next_id = 0
	last_turn = -1
	wind_turn = 0
	thor = {"active":false,"pos":Vector2.ZERO,"level":1,"xp":0}
	_forecast(0)
	return queue[0]

## Zero-based actor turn, including the first turn's oscillation/boundary.
func advance_turn(turn: int, _rng: RandomNumberGenerator) -> Dictionary:
	if turn==last_turn:
		return queue[0]
	last_turn = turn
	_forecast(turn)
	var entry: Dictionary = queue[0]
	# 4cee69 ->43c620 runs before the boundary guard on every actor turn.
	# Only the active family survives; non-column weather removes all columns.
	for index in range(columns.size()-1,-1,-1):
		if str(columns[index].type)!=str(entry.type):columns.remove_at(index)
	if turn%period==0:
		if str(entry.type)=="wind":
			wind_force = next_wind_force
			wind_angle += next_wind_delta
			# Native branch is >360, not >=360: angle360 is retained.
			if wind_angle>360:wind_angle-=360
			if wind_angle<0:wind_angle+=360
		if str(entry.type) in ["force","tornado","electricity"]:
			var slot := int(random_table[random_cursor&TABLE_MASK])&7
			var bounds := Vector2i(0,maxi(1,int(world.x)))
			var ranges: Array = spawn_ranges.get(str(entry.type),[])
			if slot<ranges.size():bounds=Vector2i(ranges[slot])
			var x := int(random_table[(random_cursor+1)&TABLE_MASK])%maxi(1,bounds.y-bounds.x)+bounds.x
			var width := (int(random_table[(random_cursor+2)&TABLE_MASK])&63)+64
			add_column(str(entry.type),float(x),float(width)/128.0)
			entry.x = float(x)/maxf(1.0,world.x)
			entry.native_x = x
			entry.native_width = width
		random_cursor = (random_cursor+3)&TABLE_MASK
	if (turn+1)%period==0:
		next_wind_force = _crt_rand()%27
		var delta := _crt_rand()%180
		next_wind_delta = delta-256 if delta>=128 else delta
	wind_force = clampi(wind_force+int(WIND_OSCILLATION[turn&7]),0,26)
	wind_turn = turn+1
	return entry

func _forecast(turn: int) -> void:
	queue.clear()
	var at := Integer.quot(turn,period)
	for index in DISPLAYED:
		queue.append({"type":NATIVE_TYPES[int(calendar[(at+index)&7])],"x":0.5,"y":0.5,"extra":""})

func _lcg() -> int:
	var value := (native_seed*0x343fd+0x5809315)&MASK32
	native_seed = (native_seed+((value*97+97)&MASK32)%1000001)&MASK32
	return value

func _crt_rand() -> int:
	crt_seed = (crt_seed*214013+2531011)&MASK32
	return (crt_seed>>16)&32767

func add_column(type: String, x: float, scale: float, extra: String = "") -> Dictionary:
	if type not in ["force","tornado","electricity"]:return {}
	var center := int(x)
	var width := maxi(1,int(scale*128.0))
	var quarter := Integer.quot(width,4)
	# Spawn435800/435ad0/435da0 scans pixels left-to-right and stops at first hit.
	for pixel in range(center-quarter-5,center+quarter+6):
		for old in columns:
			if str(old.type)!=type:continue
			var old_quarter := Integer.quot(int(old.native_width),4)
			if pixel>int(old.x)-old_quarter and pixel<int(old.x)+old_quarter:
				old.x = Integer.quot(int(old.x)+center,2)
				old.native_width = Integer.quot(maxi(int(old.native_width),width)*15,10)
				old.scale = float(old.native_width)/128.0
				old.lifetime = 10000
				return old
	var column := {"id":next_id,"type":type,"x":center,"scale":float(width)/128.0,
		"native_width":width,"lifetime":10000,"extra":extra,"used":false,"native":true}
	next_id += 1
	columns.append(column)
	return column

func inner_half(column: Dictionary) -> float:
	return float(Integer.quot(int(column.get("native_width",128)),4))

## Outer rearm keeps Weather's adapter margin; creation's ±5 scan is not its proof.
func inside_inner(column: Dictionary, point: Vector2) -> bool:
	var half := inner_half(column)
	return point.x>float(column.x)-half and point.x<float(column.x)+half

## Returns effective HP gained; final max_hp already includes actor attributes.
func moon_heal(actor: Dictionary) -> int:
	if queue.is_empty() or str(queue[0].type)!="protection":return 0
	if int(actor.get("hp",0))<=0 or not bool(actor.get("active",true)) or bool(actor.get("dead",false)):return 0
	var percentage := 8 if (int(Body.body(actor).flags)&2)!=0 else 3
	var before := int(actor.hp)
	actor.hp = mini(int(actor.max_hp),before+Integer.quot(int(actor.max_hp)*percentage,100))
	return int(actor.hp)-before

## Eclipse-specific reset; common transient item cleanup remains in turn setup.
func eclipse_reset(actors: Array) -> void:
	if queue.is_empty() or str(queue[0].type)!="ignorance":return
	for actor in actors:
		if str(actor.get("turn_item","")) in ["dual","dual_plus"]:actor.turn_item=""

func copy():
	var result = super.copy()
	result.calendar = calendar.duplicate(true)
	result.random_table = random_table.duplicate(true)
	result.spawn_ranges = spawn_ranges.duplicate(true)
	result.random_cursor = random_cursor
	result.native_seed = native_seed
	result.crt_seed = crt_seed
	result.next_wind_force = next_wind_force
	result.next_wind_delta = next_wind_delta
	result.period = period
	result.last_turn = last_turn
	return result
