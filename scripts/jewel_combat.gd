extends RefCounted
## Bridges the existing Thor projectile families into the separate JEWEL
## dispatcher. Native shell parameters where ported, explicitly retained
## prepared-shell/offline bridges elsewhere; never mobile defense/falloff.
const Rules = preload("res://scripts/jewel_rules.gd")
static var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/xfs/jewel/combat.json"))

static func enabled(model) -> bool:
	return model!=null and model.get("mode")=="jewel" and not model.jewel_state.is_empty()

static func point(model, position: Vector2i) -> Dictionary:
	if not enabled(model):return {}
	var slot := Rules.hit(model.jewel_state,position)
	return {"position":Vector2(position),"actor":-1,"jewel":slot,"fraction":0.0} if slot>=0 else {}

## Existing non-native family sweep: sample physical published path, not render
## interpolation. Ground/mobile contacts win ties, like450e10's dispatch order.
static func contact(model, start: Vector2, end: Vector2, previous: Dictionary) -> Dictionary:
	if not enabled(model):return previous
	var limit := start.distance_squared_to(Vector2(previous.position)) if not previous.is_empty() else INF
	var steps := maxi(1,ceili(start.distance_to(end)))
	for index in range(steps+1):
		var fraction := float(index)/steps
		var at := start.lerp(end,fraction)
		if start.distance_squared_to(at)>=limit:return previous
		var hit := point(model,Vector2i(at.floor()))
		if not hit.is_empty():
			hit.fraction=fraction
			return hit
	return previous

static func impact(model, position: Vector2, shell: Dictionary, data: Dictionary = {}) -> void:
	if not enabled(model):return
	var owner := int(shell.get("owner",model.shot_actor))
	var vehicle := int(shell.get("vehicle",model.actors[model.shot_actor].vehicle))
	var weapon := clampi(int(shell.get("weapon",model.shot_weapon)),0,2)
	var source: Dictionary=catalog.weapons[str(vehicle)][weapon]
	var shot: Dictionary=source.duplicate(true)
	# Native combat ports have already applied per-component Attack/Dig and
	# preserve the native three truncations. Other families retain their
	# current prepared-shell damage/radius and item bridges, as in SOLO.
	if data.is_empty():
		var rules: Dictionary=model.weapon_rules(model.shot_actor,weapon)
		shot.power=triple(int(shell.get("damage",rules.damage)))
		shot.dimension=triple(int(float(shell.get("blast_radius",rules.radius))*2))
		shot.percent=100+int(model.Items.attack(str(model.actors[model.shot_actor].get("turn_item",""))))
		shot.force=int(shell.get("native_force",0))
	else:
		for key in ["power","dimension","aspect"]:shot[key]=triple(int(data[key]))
		shot.percent=int(data.get("percent",100))
		shot.bonus=int(data.get("bonus",0))
		shot.force=int(data.get("weather_bonus",0))
	shot.owner=owner
	shot.material=0 # All three triples verified equal in the pinned DAT.
	Rules.blast(model.jewel_state,Vector2i(position),shot)
	model.jewel_state.terrain_owner=owner

static func bridge(model, position: Vector2, radius: float, damage: float, owner: int, attack: float = 0) -> void:
	if not enabled(model):return
	# Existing offline mines/bolts: use their own payload, never clone parent.
	Rules.blast(model.jewel_state,Vector2i(position),{"power":triple(int(damage)),"dimension":triple(int(radius*2)),
		"aspect":triple(100),"owner":owner,"percent":100+int(attack)})
	model.jewel_state.terrain_owner=owner

static func native_blast(model, position: Vector2i, data: Dictionary, owner: int) -> void:
	if not enabled(model):return
	Rules.blast(model.jewel_state,position,{"power":triple(int(data.power)),"dimension":triple(int(data.dimension)),
		"aspect":triple(int(data.aspect)),"owner":owner,"percent":int(data.get("percent",100)),
		"bonus":int(data.get("bonus",0)),"force":int(data.get("weather_bonus",0))})
	model.jewel_state.terrain_owner=owner

static func shock(model, point_value: Vector2i, radius: int) -> void:
	if not enabled(model):return
	for entity in model.jewel_state.entities:
		if bool(entity.removed):continue
		if (Vector2i(entity.pos)-point_value).length_squared()<radius*radius:
			entity.pose="shock"
			entity.pose_age=0.0
			entity.pose_tick=0

## Offline CPU values the complete volley's score delta first, then accumulated
## useful resistance damage. Negative jewels carry a negative utility.
static func progress(state: Dictionary, owner: int) -> float:
	var result := 0.0
	for entity in state.entities:
		if bool(entity.removed) or bool(entity.drop):continue
		var value: int=Rules.POINTS[int(entity.type)]
		var fraction := minf(float(entity.damage)/float(entity.resistance),1.0)
		result+=value*fraction*(1.0 if int(entity.owner)==owner else -1.0)
	return result

static func triple(value: int) -> Array:
	return [value,value,value]

static func pending(model) -> bool:
	for entity in model.jewel_state.entities:
		if bool(entity.removed):continue
		if bool(entity.drop) or int(entity.fall)!=0:return true
		var pos:=Vector2i(entity.pos)
		if pos.x<=0 or pos.x>=int(model.terrain.world_size().x):return true
		if int(model.terrain.native_surface_at(pos.x,pos.y-15))>pos.y+1:return true
	return false
