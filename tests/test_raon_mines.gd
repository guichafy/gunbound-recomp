extends "res://tests/support/suite.gd"
## Raon S2/SS placed mines from AnimateMine 0x498b60 / AnimateSuperMine 0x4921e0,
## slope 0x4986a0 and draw publication 0x499d50 (ADR-117). Expected values are
## derived by hand from the PE rules recorded in RAON_CLASSIC_FIX.md.
const Raon = preload("res://scripts/raon_effect.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const RAON := 7

## Column heights in pixels; anything missing is void.
class Columns:
	extends RefCounted
	var heights := {}
	var fallback := 700.0
	var width := 1280.0
	var height := 800.0
	func surface_at(x: float, from_y: float = 0.0) -> float:
		var top := float(heights.get(int(floor(x)),fallback))
		return top if top >= from_y else maxf(top,from_y)
	func is_void(y: float) -> bool:
		return y >= height
	func world_size() -> Vector2:
		return Vector2(width,height)

func actor(foot: Vector2, hp: int = 100) -> Dictionary:
	var stance := float(Mobiles.definition(RAON).stance)
	return {"pos":foot-Vector2(0,stance),"hp":hp,"vehicle":RAON,"tilt":0.0}

func mine_at(at: Vector2, weapon: int = 1, owner: int = 0) -> Dictionary:
	return Raon.create_mine({"weapon":weapon,"damage":200,"blast_radius":21.0,"fp_ready":true,"fp_velocity":Vector2i(256,0)},at,owner,RAON)

## Independent LUT read: int16 at center 0x598e7e + 2*(dy*256+dx).
func lut(dx: int, dy: int) -> int:
	while dx < -127 or dx > 128 or dy < -127 or dy > 128:
		dx = int(dx/2); dy = int(dy/2)
	var raw := Physics.angles.decode_s16(2*(dx+127+256*(dy+127)))
	return raw-360 if raw > 270 else raw

func run() -> void:
	Physics.warmup()
	test_slope()
	test_fall_and_bounce()
	test_trigger()
	test_out_of_world()
	test_draw_contract()
	test_match_paths()
	finish("RAON MINES CHECKS")

func test_slope() -> void:
	var ground := Columns.new()
	check(Raon.slope_angle(ground,100,700) == 0,"Flat ground gives slope0")
	# Ramp: x-10 → 704, x+10 → 696: dx20, dy=hR-hL=-8.
	ground.heights = {90:704,100:700,110:696}
	check(Raon.slope_angle(ground,100,700) == lut(20,-8),"Uphill to the right uses LUT(20,-8)=%d" % lut(20,-8))
	check(lut(20,-8) > 0,"Uphill to the right is a positive (counterclockwise) angle")
	ground.heights = {90:696,100:700,110:704}
	check(Raon.slope_angle(ground,100,700) == lut(20,8),"Downhill to the right uses LUT(20,8)-360")
	# Left cliff deeper than h0+20, right normal: hL mirrored as 2*h0-hR.
	ground.heights = {90:760,100:700,110:696}
	check(Raon.slope_angle(ground,100,700) == lut(20,696-704),"Left cliff mirrors the right sample")
	# Right cliff, left normal: hR mirrored as 2*h0-hL.
	ground.heights = {90:704,100:700,110:780}
	check(Raon.slope_angle(ground,100,700) == lut(20,696-704),"Right cliff mirrors the left sample")
	# Both cliffs: flat.
	ground.heights = {90:760,100:700,110:780}
	check(Raon.slope_angle(ground,100,700) == 0,"Two cliffs flatten the mine")

func test_fall_and_bounce() -> void:
	var ground := Columns.new()
	ground.fallback = 200.0
	var mine := mine_at(Vector2(100,170))
	var mines: Array = [mine]
	var actors: Array = [actor(Vector2(-500,200))]
	var expected := [171,173,176,180,185,195,200,200]
	for tick in expected.size():
		Raon.step_mines(mines,actors,ground,0.05)
		check(int(mine.pos.y) == int(expected[tick]),"Fall tick%d y=%d (got %d)" % [tick+1,expected[tick],int(mine.pos.y)])
	check(not bool(mine.falling) and int(mine.fall_speed) == 0,"Landing below speed5 stops the fall")
	var near := mine_at(Vector2(100,190))
	Raon.step_mines([near],actors,ground,0.05)
	check(int(near.pos.y) == 200 and not bool(near.falling),"Within15px the mine snaps to the ground without falling")

func test_trigger() -> void:
	var ground := Columns.new()
	for gap in [7,8,9]:
		var mine := mine_at(Vector2(100,700))
		var actors: Array = [actor(Vector2(-500,700)),actor(Vector2(100+gap,700))]
		var hit: Array = Raon.step_mines([mine],actors,ground,0.05)
		check((not hit.is_empty()) == (gap < 8),"Foot gap%dpx %s the mine (dx²+dy²<64)" % [gap,"triggers" if gap < 8 else "does not trigger"])
	var diagonal := mine_at(Vector2(100,700))
	check(not Raon.step_mines([diagonal],[actor(Vector2(105,705))],ground,0.05).is_empty(),"Diagonal 5,5 (50<64) is inside radius8")
	var corner := mine_at(Vector2(100,700))
	check(Raon.step_mines([corner],[actor(Vector2(106,706))],ground,0.05).is_empty(),"Diagonal 6,6 (72) is outside radius8")
	var owner := mine_at(Vector2(100,700),1,0)
	check(not Raon.step_mines([owner],[actor(Vector2(102,700))],ground,0.05).is_empty(),"The owner also detonates its own mine")
	var dead := mine_at(Vector2(100,700))
	check(Raon.step_mines([dead],[actor(Vector2(100,700),0)],ground,0.05).is_empty(),"Dead mobiles are ignored (flag+0xbff7)")
	var ss := mine_at(Vector2(100,700),2)
	var other := mine_at(Vector2(105,700),1,1)
	var far: Array = [actor(Vector2(-500,700))]
	var result: Array = Raon.step_mines([ss,other],far,ground,0.05)
	check(result == [0],"Supermine detonates on another mine inside radius8; the S2 mine does not")

func test_out_of_world() -> void:
	var ground := Columns.new()
	ground.fallback = 5000.0
	var mine := mine_at(Vector2(100,700))
	var mines: Array = [mine]
	var actors: Array = [actor(Vector2(-500,700))]
	var exploded := false
	for tick in 60:
		exploded = exploded or not Raon.step_mines(mines,actors,ground,0.05).is_empty()
		if bool(mine.get("lost",false)):
			break
	check(bool(mine.get("lost",false)) and not exploded,"A mine falling out of the world is lost without exploding")

func test_draw_contract() -> void:
	var ground := Columns.new()
	ground.heights = {90:704,100:700,110:696}
	var right := mine_at(Vector2(100,700))
	right.dir = 1.0
	Raon.step_mines([right],[actor(Vector2(-500,700))],ground,0.05)
	check(int(right.slope) == lut(20,-8),"Mine publishes its LUT slope every tick")
	var xf: Transform2D = Raon.draw_transform(right)
	check((xf*Vector2(-1,0)).distance_to(Vector2(100,700)) < 0.001,"Mirrored cell maps local x -> -x-1 around the ground point")
	check(is_equal_approx(xf.get_rotation(),-deg_to_rad(float(lut(20,-8)))) or is_equal_approx(xf.get_rotation(),PI-deg_to_rad(float(lut(20,-8)))),"Rotation is counterclockwise by the slope")
	check(xf.x.x * xf.y.y - xf.x.y * xf.y.x < 0.0,"A right-facing mine mirrors the left-facing sheet (0x3fa8 set)")
	var left := mine_at(Vector2(100,700))
	left.dir = -1.0
	left.slope = 0
	check(Raon.draw_transform(left).determinant() > 0.0 and Raon.draw_transform(left).origin == Vector2(100,700),"A left-facing mine keeps the sheet and pivots on the ground point")

func test_match_paths() -> void:
	var model = Match.new()
	model.start(RAON,1,42,"")
	model.wind = Vector2.ZERO
	model.weather.columns.clear()
	model.weather.thor.active = false
	model.terrain.cells.fill(0)
	for y in range(220,model.terrain.HEIGHT):
		for x in model.terrain.WIDTH:
			model.terrain.cells[y*model.terrain.WIDTH+x] = 1
	var stance := float(Mobiles.definition(int(model.actors[1].vehicle)).stance)
	model.actors[0].pos = Vector2(200,440-float(Mobiles.definition(RAON).stance))
	model.actors[1].pos = Vector2(640,440-stance)
	model.mines = [Raon.create_mine({"weapon":1,"damage":200,"blast_radius":21.0,"fp_ready":true,"fp_velocity":Vector2i(-256,0)},Vector2(800,440),0,RAON)]
	model.active = 1
	model.phase = Match.PHASE_AIM
	model.events.clear()
	# The CPU walks onto the mine during its own aim phase.
	model.actors[1].pos = Vector2(803,440-stance)
	model.tick(0.05)
	var blasts: Array = model.events.filter(func(event): return event.type == "explosion" and bool(event.get("raon_mine",false)))
	check(model.mines.is_empty() and blasts.size() == 1,"A mobile walking onto a mine detonates it during AIM")
	if blasts.size() == 1:
		check(Vector2(blasts[0].position) == Vector2(800,430),"Mine blast is centred 10px above the ground point")
