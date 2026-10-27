extends "res://tests/support/suite.gd"
const Legacy = preload("res://scripts/weather.gd")
const Combat = preload("res://scripts/aduka_combat.gd")

func run() -> void:
	var resource := "res://scripts/mage_weather.gd"
	var exists := ResourceLoader.exists(resource)
	var weather = load(resource).new() if exists else Legacy.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	weather.setup([0,0,0,0,100,0,0,0,0,0],Vector2(1800,1800),rng)
	check(str(weather.queue[0].type)=="force","Native seven-category calendar excludes legacy weakness")
	if not exists:
		finish("MAGE WEATHER CHECKS")
		return
	check(bool(weather.is_native),"Native state identifies itself for shared presentation")
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/mage_weather_native.json"))
	for fixture in fixtures:
		rng.seed = int(fixture.seed)
		weather = load(resource).new()
		weather.setup(fixture.preset,Vector2(1800,1800),rng)
		check(weather.calendar==fixture.calendar.map(func(value):return int(value)),"31 native swaps seed%d"%fixture.seed)
		check(weather.random_table.slice(0,8)==fixture.table8.map(func(value):return int(value)),"Native LCG table seed%d"%fixture.seed)
		check(weather.wind_force==int(fixture.force) and weather.wind_angle==int(fixture.angle),"Initial native wind seed%d"%fixture.seed)
		check(weather.next_wind_force==int(fixture.next_force) and weather.next_wind_delta==int(fixture.next_delta),"Initial next-wind state seed%d"%fixture.seed)
		check(weather.columns.is_empty() and weather.random_cursor==0,"Setup does not consume turn zero")
		for row in fixture.turns:
			var entry: Dictionary = weather.advance_turn(int(row.turn),rng)
			check(str(entry.type)==str(row.type),"Calendar period actor turn%d"%row.turn)
			check(weather.wind_force==int(row.force) and weather.wind_angle==int(row.angle),"Wind ordering turn%d seed%d"%[row.turn,fixture.seed])
			check(weather.next_wind_force==int(row.next_force) and weather.next_wind_delta==int(row.next_delta),"MSVCRT signed-char next wind turn%d"%row.turn)
			check(weather.random_cursor==int(row.cursor),"Three table values consumed per boundary including non-column weather")
			check(weather.queue.map(func(value):return str(value.type))==row.forecast,"Four-period forecast turn%d"%row.turn)
			if row.has("spawn"):
				var found := false
				for column in weather.columns:
					if int(column.x)==int(row.spawn[0]) and int(column.native_width)==int(row.spawn[1]):found=true
				check(found,"Native spawn center/full width from independent table")
		var clone = weather.copy()
		check(clone.get_script()==weather.get_script(),"Copy retains native subclass")
		var before: Array = weather.columns.duplicate(true)
		clone.add_column("force",-10000,1.0)
		clone.calendar[0] = 6
		clone.random_table[0] = 0
		check(weather.columns==before and weather.calendar==fixture.calendar.map(func(value):return int(value)) and weather.random_table.slice(0,8)==fixture.table8.map(func(value):return int(value)),"Snapshot deeply isolates columns/calendar/random table")
		var actual: Dictionary = weather.advance_turn(20,rng)
		var copied: Dictionary = clone.advance_turn(20,rng)
		check(actual==copied and weather.wind_force==clone.wind_force and weather.wind_angle==clone.wind_angle,"Copy retains private native and CRT RNG state")
	_test_columns(resource)
	_test_boundaries(resource)
	_test_moon_eclipse(resource)
	finish("MAGE WEATHER CHECKS")

func _test_columns(resource: String) -> void:
	var weather = load(resource).new()
	var rng := RandomNumberGenerator.new()
	rng.seed=1
	weather.spawn_ranges={"force":[Vector2i(321,322),Vector2i(321,322),Vector2i(321,322),Vector2i(321,322),Vector2i(321,322),Vector2i(321,322),Vector2i(321,322),Vector2i(321,322)]}
	weather.setup([8,0,0,0,0,0,0],Vector2(1800,1800),rng)
	weather.advance_turn(0,rng)
	check(weather.columns.size()==1 and int(weather.columns[0].x)==321,"Explicit native spawn ranges survive setup")
	weather.columns.clear()
	var first: Dictionary=weather.add_column("tornado",100,1.0)
	var id := int(first.id)
	check(int(first.native_width)==128 and weather.inner_half(first)==32.0,"Quarter-width native contact")
	check(not weather.inside_inner(first,Vector2(68,100)) and not weather.inside_inner(first,Vector2(132,100)),"Native contact excludes both exact X borders")
	check(weather.inside_inner(first,Vector2(69,-9000)) and weather.inside_inner(first,Vector2(131,9000)),"Native inner contact tests X at all world heights")
	var previous_count: int=weather.columns.size()
	check(weather.add_column("wind",100,1.0).is_empty() and weather.add_column("random",100,1.0).is_empty() and weather.columns.size()==previous_count,"Only the three native column families may spawn")
	var merged: Dictionary=weather.add_column("tornado",168,1.0)
	check(weather.columns.size()==1 and int(merged.x)==134 and int(merged.native_width)==192 and int(merged.id)==id,"Inclusive scan enters strict old border; merge max×15/10 once")
	check(int(merged.lifetime)==10000,"Native lifetime retained without unproven expiration")
	weather.columns.clear()
	weather.add_column("tornado",100,1.0)
	weather.add_column("tornado",169,1.0)
	check(weather.columns.size()==2,"Scan tangent at strict border does not merge")
	weather.add_column("force",100,1.0)
	check(weather.columns.size()==3,"Column types persist together")
	weather.calendar.fill(3)
	weather.advance_turn(1,rng)
	check(weather.columns.is_empty(),"Non-column weather clears all three families at every actor turn")
	weather.calendar.fill(0)
	weather.add_column("force",100,1.0)
	weather.add_column("tornado",300,1.0)
	weather.add_column("electricity",600,1.0)
	weather.advance_turn(3,rng)
	check(weather.columns.size()==1 and str(weather.columns[0].type)=="force","Non-boundary actor turn retains only the active column family")
	weather.columns.clear()
	weather.add_column("force",120,1.0)
	weather.add_column("force",-120,1.0)
	var result: Dictionary=weather.add_column("force",0,3.0)
	check(int(result.x)==-60 and weather.columns.size()==2,"Pixel scan selects leftmost overlap and stops after first existing object")

func _test_boundaries(resource: String) -> void:
	var weather = load(resource).new()
	var rng := RandomNumberGenerator.new()
	rng.seed=42
	weather.setup([0,0,0,8,0,0,0],Vector2(1800,1800),rng)
	weather.wind_angle=350
	weather.next_wind_delta=10
	weather.next_wind_force=0
	weather.advance_turn(0,rng)
	check(weather.wind_angle==360 and weather.wind_force==0,"Native angle retains exact360 and turn-zero oscillation clamps force")
	var before := [weather.wind_force,weather.wind_angle,weather.random_cursor,weather.native_seed,weather.crt_seed]
	weather.advance_turn(0,rng)
	check(before==[weather.wind_force,weather.wind_angle,weather.random_cursor,weather.native_seed,weather.crt_seed],"Repeated same-turn call cannot consume RNG or reapply oscillation")
	weather.advance_turn(1,rng)
	weather.next_wind_delta=-128
	weather.next_wind_force=26
	weather.advance_turn(2,rng)
	check(weather.wind_angle==232 and weather.wind_force==26,"Signed-char delta applies before oscillation and upper clamp")
	weather.advance_turn(3,rng)
	weather.next_wind_delta=-80
	weather.wind_angle=10
	weather.next_wind_force=10
	weather.advance_turn(4,rng)
	check(weather.wind_angle==290 and weather.wind_force==11,"Negative wind heading wraps once before oscillation")
	weather = load(resource).new()
	weather.setup([8,0,0,0,0,0,0],Vector2(1800,1800),rng)
	weather.random_cursor=1023
	weather.random_table[1023]=7
	weather.random_table[0]=1234
	weather.random_table[1]=63
	weather.advance_turn(0,rng)
	check(weather.random_cursor==2 and int(weather.columns[0].x)==1234 and int(weather.columns[0].native_width)==127,"Random table wraps each of the three consumed indices independently")
	weather.spawn_ranges={"force":[Vector2i(4,5)]}
	var clone = weather.copy()
	clone.spawn_ranges.force[0]=Vector2i(8,9)
	check(weather.spawn_ranges.force[0]==Vector2i(4,5),"Copy deeply isolates configured stage ranges")

func _test_moon_eclipse(resource: String) -> void:
	Combat.warmup()
	var weather = load(resource).new()
	weather.queue=[{"type":"protection"}]
	for row in [[1,730,500,521],[2,1100,800,833],[5,1050,800,884],[1,751,700,722],[1,730,725,730]]:
		var actor := {"vehicle":row[0],"max_hp":row[1],"hp":row[2],"shield":31,"turn_item":"","attributes":[0,0,0,50,0,0,0,0]}
		var healed: int=weather.moon_heal(actor)
		check(actor.hp==row[3] and healed==int(row[3])-int(row[2]),"Native Moon uses final max HP, type flags and integer division")
		check(actor.shield==31,"Moon leaves shield untouched")
	for guard in [{"hp":0},{"hp":100,"active":false},{"hp":100,"dead":true}]:
		var actor := {"vehicle":1,"max_hp":730,"hp":100}
		actor.merge(guard,true)
		var before: int=actor.hp
		check(weather.moon_heal(actor)==0 and actor.hp==before,"Moon rejects inactive/dead actor")
	var actors := [{"turn_item":"dual","items":[{"id":"dual","used":false}]},{"turn_item":"dual_plus"},{"turn_item":"thunder"},{"turn_item":"power_up"},{"turn_item":"teleport"}]
	weather.eclipse_reset(actors)
	check(actors[0].turn_item=="dual","Moon does not clear Dual")
	weather.queue=[{"type":"ignorance"}]
	weather.eclipse_reset(actors)
	check(actors[0].turn_item=="" and actors[1].turn_item=="","Eclipse clears both persistent Dual flags for every actor")
	check(actors[2].turn_item=="thunder" and actors[3].turn_item=="power_up" and actors[4].turn_item=="teleport","Eclipse-specific reset leaves other effects to common reset")
	check(not bool(actors[0].items[0].used),"Eclipse never spends inventory")
	var actor := {"vehicle":1,"max_hp":730,"hp":500}
	check(weather.moon_heal(actor)==0 and actor.hp==500,"Eclipse does not heal")
