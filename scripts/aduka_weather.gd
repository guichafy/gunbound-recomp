extends RefCounted
## Native projectile weather sampling,455cc0/451030/4510f0 and Aduka ticks.
const Physics = preload("res://scripts/classic_ballistics.gd")

static func active(projectile: Dictionary) -> bool:
	return int(projectile.get("vehicle",0))==16 and not bool(projectile.get("beacon",false))

static func geometry(column: Dictionary) -> Vector2i:
	# Bridge the existing world's displayed128px columns to native full width.
	return Vector2i(int(column.x),Physics.quot(int(column.get("native_width",128.0*float(column.scale))),4))

static func sample(model, projectile: Dictionary, point: Vector2i, force_sampled: bool) -> bool:
	for column in model.weather.columns:
		var type := str(column.type)
		if type not in ["tornado","force","electricity"]:
			continue
		var span := geometry(column)
		# Native hazards extend through the world vertically; strict X borders.
		if point.x<=span.x-span.y or point.x>=span.x+span.y:
			continue
		if type=="force" and not force_sampled:
			projectile.native_force = clampi(int(projectile.get("native_force",0))+8,20,100)
			force_sampled = true
		elif type=="tornado" and projectile.tornado.is_empty():
			projectile.tornado = {"native":true,"column":int(column.id),"turns":0,"center":span.x,"half":span.y}
		elif type=="electricity":
			projectile.electric = true
		if type not in projectile.influenced:
			projectile.influenced.append(type)
			model.events.append({"type":"weather_hit","weather":type,"position":Vector2(point),"extra":column.get("extra","")})
	return force_sampled

## Called after movement/contact, before acceleration. No normalized direction,
## minimum world-speed, impulse or reset to the original launch velocity.
static func finish(projectile: Dictionary) -> bool:
	var state: Dictionary = projectile.tornado
	if state.is_empty():
		return true
	assert(bool(state.get("native",false)))
	var velocity: Vector2i = projectile.fp_velocity
	if absi(velocity.x)<200:
		velocity.x = -200 if velocity.x<0 else 200
	var x := int(projectile.fp_pos.x)>>8
	if x<int(state.center)-int(state.half) or x>int(state.center)+int(state.half):
		state.turns = int(state.turns)+1
		if int(state.turns)<3:
			velocity.x = -velocity.x
		else:
			projectile.tornado = {}
	projectile.fp_velocity = velocity
	# Third crossing still took the tornado branch; wind resumes next tick.
	return false
