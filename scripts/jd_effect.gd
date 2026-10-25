extends RefCounted
## Fixed JD crystals. Native sources/ABI/limits: docs/sdd/JD_CLASSIC_FIX.md.
## Called by the common 20Hz model step; no render/clock/global profile reads.
const Attributes = preload("res://scripts/player_attributes.gd")
const Damage = preload("res://scripts/damage.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const FACTORS := {4:84,1:92,3:90,5:92,2:100,6:94,7:85,8:86,9:94,10:94,11:93,12:82,13:92,14:95,15:88,16:91}
const TYPES := {4:8,1:5,3:8,5:2,2:8,6:2,7:8,8:4,9:4,10:5,11:2,12:2,13:2,14:3,15:8,16:8}

static func create(projectile: Dictionary, position: Vector2, owner: int) -> Dictionary:
	return {"kind":"jd_crystal", "crystal":true, "pos":Vector2(int(position.x),int(position.y)),
		"owner":owner,"weapon":int(projectile.weapon), "projectile":projectile.duplicate(true),
		"ticks":0,"age":0.0,"state_age":0.0,"state":"normal","active":true}

static func radius_for(effect: Dictionary, actor: Dictionary) -> int:
	var radius := 68 if int(effect.weapon) == 2 else 60
	var flags := int(TYPES.get(int(actor.vehicle),0))
	if flags & 8:
		radius += int(radius / 2)
	if flags & 4:
		radius += int(radius / 4)
	return radius

static func ss_damage(actor: Dictionary) -> int:
	# 48f7da: native type14 (Godot Knight15) does not receive this damage.
	if int(actor.vehicle) == 15:
		return 0
	var flags := int(TYPES.get(int(actor.vehicle),0))
	# The existing model exposes combined signed defense points, not the
	# native guarded field. The bridge uses its 8/10 reduction (41d17d).
	var factor := int(actor.get("native_damage_factor",int(FACTORS.get(int(actor.vehicle),100))-int(Attributes.points(actor,Attributes.DEFENSE)*8/10)))
	if flags & 8:
		factor += 4
	if flags & 2:
		factor -= 4
	return maxi(0,int(14*factor/100))

static func _slope(actor: Dictionary, center: Vector2, repulse: bool) -> int:
	# Native guarded slope is facing-relative. Current terrain tilt is already
	# world-relative radians; project that onto the requested direction.
	var toward := 1 if center.x > float(actor.pos.x) else -1
	var direction := -toward if repulse else toward
	return int(rad_to_deg(float(actor.get("tilt",0.0))))*direction

static func _pull_mines(effect: Dictionary, mines: Array) -> bool:
	var working := false
	var center := Vector2(effect.pos)
	var radius := 68 if int(effect.weapon) == 2 else 60
	for mine in mines:
		var delta := Vector2i(int(mine.pos.x)-int(center.x),int(mine.pos.y)-int(center.y))
		if delta.length_squared() >= radius*radius:
			continue
		if int(effect.weapon) == 2:
			mine.jd_detonate = true
			continue
		if absi(delta.x) <= 2:
			continue
		var slope := _slope(mine,center,false)
		if slope > 80:
			continue
		working = true
		var debt := int(mine.get("jd_motion_debt",0))+(100-slope)*2
		if debt > 100:
			mine.pos.x += (-1 if delta.x > 0 else 1)*int(debt/100)
			debt %= 100
		mine.jd_motion_debt = debt
	return working

## Returns true while retained; false removes AFTER this call's effects.
static func step(effect: Dictionary, actors: Array, mines: Array, terrain, events: Array) -> bool:
	if not bool(effect.get("active",true)):
		return false
	var repulse := int(effect.weapon) == 2
	var center := Vector2(effect.pos)
	var working := false
	for index in range(actors.size()):
		var actor: Dictionary = actors[index]
		if int(actor.hp) <= 0 or bool(actor.get("jd_immune",false)):
			continue
		var delta := Vector2i(int(actor.pos.x)-int(center.x),int(actor.pos.y)-int(center.y))
		var radius := radius_for(effect,actor)
		if delta.length_squared() >= radius*radius:
			continue
		if repulse:
			Damage.deal_damage(actors,events,index,ss_damage(actor),"jd_crystal")
			actor.last_attacker = int(effect.owner)
		elif absi(delta.x) <= 2:
			continue
		var slope := _slope(actor,center,repulse)
		if slope > 80:
			continue
		working = true
		var debt := int(actor.get("jd_motion_debt",0))+200-3*slope
		if debt > 100:
			var direction := (-1 if delta.x >= 0 else 1)*(-1 if repulse else 1)
			var amount := int(debt/100)
			var blocked := false
			if repulse and terrain != null:
				# Bridge to the current alpha terrain. The client's leading-edge
				# height probe/virtual support solver is not yet ported in full.
				var half := Vector2(Mobiles.body(actor).box).x*0.5
				blocked = terrain.is_solid(Vector2(float(actor.pos.x)+direction*half,float(actor.pos.y)-30))
			if not blocked:
				actor.pos.x += direction*amount
			debt %= 100
		actor.jd_motion_debt = debt
	working = _pull_mines(effect,mines) or working
	var counter := int(effect.ticks)
	effect.ticks = counter+1
	effect.age = float(effect.ticks)*0.05
	var state := "work" if working else "normal"
	effect.state_age = float(effect.get("state_age",0.0))+0.05 if state == str(effect.state) else 0.0
	effect.state = state
	effect.active = working and counter <= (20 if repulse else 18)
	return bool(effect.active)
