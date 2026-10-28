extends RefCounted
## Shared native weather sampling,455cc0/451030/4510f0. Mage4572b0/4a4950/
##483ff0, Lightning482550/4a8360 and Aduka share the velocity-preserving tornado.
const Physics = preload("res://scripts/classic_ballistics.gd")

static func active(projectile: Dictionary) -> bool:
	return int(projectile.get("vehicle",0)) in [1,6,8,16] and not bool(projectile.get("beacon",false))

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
			projectile.native_force = clampi(int(projectile.get("native_force",0))+int(projectile.get("native_contact_stride",8)),20,100)
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
	# MageS2 publishes the wave point to+f54 before testing the bounds
	# (4a5b8c..4a5bbc/4a5d35); its private carrier is restored next tick.
	if int(projectile.get("vehicle",0))==1 and str(projectile.get("flight",""))=="mage_wave":
		x = floori(float(projectile.hit_pos.x))
	if x<int(state.center)-int(state.half) or x>int(state.center)+int(state.half):
		state.turns = int(state.turns)+1
		if int(state.turns)<3:
			velocity.x = -velocity.x
		else:
			projectile.tornado = {}
	projectile.fp_velocity = velocity
	# Third crossing still took the tornado branch; wind resumes next tick.
	return false
