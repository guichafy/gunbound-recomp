extends RefCounted
## Native Aduka/Thor contact and damage; VA/contracts in ADUKA_COMBAT_REA.md.
## World→hotspot conversion bridges the existing actor presentation coordinates.
const Physics = preload("res://scripts/classic_ballistics.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Items = preload("res://scripts/items.gd")
const Damage = preload("res://scripts/damage.gd")
const NativeWeather = preload("res://scripts/aduka_weather.gd")
static var catalog: Dictionary = {}

static func warmup() -> void:
	if catalog.is_empty():
		catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/aduka/combat_native.json"))

static func body(actor: Dictionary) -> Dictionary:
	return catalog.bodies.get(str(int(actor.get("vehicle",16))),catalog.bodies["16"])

static func origin(actor: Dictionary) -> Vector2i:
	var offset := Vector2(0,float(body(actor).origin_y)).rotated(float(actor.get("tilt",0.0)))
	return Vector2i(Vector2(actor.pos)+offset)

## 45f300/45f5d0: positive tilt adds4; nonpositive NEG then SUB4.
static func tilt_offset(actor: Dictionary) -> Vector2i:
	var angle := -roundi(rad_to_deg(float(actor.get("tilt",0.0))))
	var index := Physics.quot(angle+4,10) if angle>0 else Physics.quot(-angle-4,10)
	var source: Array = catalog.tilt.x_large if (int(body(actor).flags)&1)!=0 else catalog.tilt.x_small
	var y := 0 if (int(body(actor).flags)&1)!=0 else int(catalog.tilt.y[mini(index,5)])
	return Vector2i(int(source[mini(index,6)])*(1 if angle>0 else -1),y)

static func center(actor: Dictionary) -> Vector2i:
	var data := body(actor)
	return origin(actor)+tilt_offset(actor)-Vector2i(0,Physics.quot(int(data.height)-int(data.bottom),2)+int(data.bottom))

static func hit_actor(point: Vector2i, actor: Dictionary) -> bool:
	if int(actor.get("hp",0))<=0 or bool(actor.get("invulnerable",false)):
		return false
	var data := body(actor)
	var at := origin(actor)+tilt_offset(actor)
	var half := Physics.quot(int(data.width),2)
	return point.x>=at.x-half and point.x<=at.x+half and point.y>=at.y-int(data.height)-int(data.bottom) and point.y<=at.y-int(data.bottom)

static func falloff(delta: Vector2i, dimension: int, aspect: int) -> int:
	var dx := Physics.quot(delta.x*100,maxi(1,aspect))
	var radius := Physics.quot(dimension,2)+10
	var square := dx*dx+delta.y*delta.y
	if radius<=0 or square>=radius*radius:
		return 0
	return int((radius-sqrt(float(square)))*1000.0/radius)

## Native passes are separate IDIVs; merging percentages changes damage.
static func amount(actor: Dictionary, impact: Vector2i, shot: Dictionary) -> int:
	var factor := falloff(center(actor)-impact,int(shot.dimension),int(shot.aspect))
	var damage := Physics.quot(int(shot.power)*factor,1000)
	damage = Physics.quot(damage*int(shot.get("percent",100)),100)
	damage = Physics.quot(damage*(100+int(shot.get("bonus",0))+Physics.quot(int(shot.get("weather_bonus",0)),2)),100)
	var vulnerability := int(body(actor).vulnerability)-Physics.quot(8*Attributes.points(actor,Attributes.DEFENSE),10)
	if bool(actor.get("native_protection",false)):
		vulnerability -= Physics.quot(vulnerability,5)
	var attack := int(shot.flags)
	var defense := int(body(actor).flags)
	if (defense&8)!=0:
		vulnerability += (-4 if (attack&2)!=0 else 0)+(4 if (attack&1)!=0 else 0)
	if (defense&4)!=0:
		vulnerability += (-4 if (attack&4)!=0 else 0)+(4 if (attack&2)!=0 else 0)
	if (defense&2)!=0:
		vulnerability += (4 if (attack&4)!=0 else 0)+(-4 if (attack&1)!=0 else 0)
	damage = Physics.quot(damage*vulnerability,100)
	var resistance: Array = actor.get("native_resistance",[0,0,0,0])
	for index in 4:
		if (attack&(8>>index))!=0:
			damage = Physics.quot(damage*(100+int(resistance[index])),100)
	return maxi(0,damage)

static func apply(actors: Array, events: Array, impact: Vector2i, shot: Dictionary, _thor: bool = false) -> int:
	var total := 0
	for index in actors.size():
		if int(actors[index].hp)<=0 or bool(actors[index].get("invulnerable",false)):
			continue
		var damage := amount(actors[index],impact,shot)
		# Native XP uses the computed amount, including shield and overkill.
		# The offline model publishes terminal HP0 for its existing turn contract.
		total += Damage.deal_damage(actors,events,index,damage)
	return total

static func prepare(projectile: Dictionary, actor: Dictionary) -> void:
	if int(projectile.get("vehicle",0))!=16 or int(projectile.weapon)!=0:
		return
	projectile.damage = int(catalog.t1.power)+3*Attributes.points(actor,Attributes.ATTACK)
	projectile.aduka_dimension = int(catalog.t1.dimension)+Physics.quot(Attributes.points(actor,Attributes.DIG),2)
	# Existing offline item contract is retained until its own native item
	# activation path is ported; it must not silently spend Bunge for no effect.
	projectile.aduka_crater_percent = 100+int(Items.dig(str(actor.get("turn_item",""))))
	projectile.blast_radius = Physics.quot(int(projectile.aduka_dimension),2)

static func t1_parameters(projectile: Dictionary, actor: Dictionary) -> Dictionary:
	return {"power":int(projectile.damage),"dimension":int(projectile.get("aduka_dimension",64)),
		"aspect":int(catalog.t1.aspect),"flags":int(catalog.t1.flags),
		"weather_bonus":int(projectile.get("native_force",0)),
		"percent":100+int(Items.attack(str(actor.get("turn_item",""))))}

static func point_contact(point: Vector2i, terrain, actors: Array, ground: bool = true, bodies: bool = true) -> Dictionary:
	if ground and terrain.native_solid(point):
		return {"position":Vector2(point),"actor":-1,"fraction":0.0}
	if bodies:
		for index in actors.size():
			if hit_actor(point,actors[index]):
				return {"position":Vector2(point),"actor":index,"fraction":0.0}
	return {}

## 455cc0 coarse8, then458920/458a00 refine only the detected contact kind.
## Minor coordinate advances before testing the major coordinate, including d0.
static func projectile_contact(start: Vector2i, end: Vector2i, terrain, actors: Array, projectile: Dictionary = {}, model = null) -> Dictionary:
	var delta := end-start
	var horizontal := absi(delta.y)<absi(delta.x)
	var major := absi(delta.x if horizontal else delta.y)
	var stride := Physics.quot((delta.y if horizontal else delta.x)*65536,major+1)
	var direction := 1 if (delta.x if horizontal else delta.y)>=0 else -1
	var minor := (start.y if horizontal else start.x)<<16
	var force_sampled := false
	for distance in range(0,major+8,8):
		minor += stride*8
		var position := _point(start,horizontal,direction,distance,minor>>16)
		if model!=null:
			force_sampled = NativeWeather.sample(model,projectile,position,force_sampled)
		var coarse := point_contact(position,terrain,actors)
		if coarse.is_empty():
			continue
		if distance>0:
			var fine_minor := minor-stride*8
			for fine in range(distance-8,distance):
				fine_minor += stride
				var contact := point_contact(_point(start,horizontal,direction,fine,fine_minor>>16),terrain,actors,int(coarse.actor)<0,int(coarse.actor)>=0)
				if not contact.is_empty():
					return contact
		return coarse
	return {}

static func _point(start: Vector2i, horizontal: bool, direction: int, distance: int, minor: int) -> Vector2i:
	return Vector2i(start.x+direction*distance,minor) if horizontal else Vector2i(minor,start.y+direction*distance)

## Producer4398e0/4e4fe0 computes contact;4262d0 records it for the consumer.
## The offline simulation performs those stages together with the same integers.
static func thor_contact(start: Vector2i, target: Vector2i, terrain, actors: Array) -> Dictionary:
	var delta := target-start
	var horizontal := absi(delta.y)<absi(delta.x)
	var major := absi(delta.x if horizontal else delta.y)
	var stride := Physics.quot((delta.y if horizontal else delta.x)*65536,major+1)*2
	var direction := 1 if (delta.x if horizontal else delta.y)>=0 else -1
	var minor := (start.y if horizontal else start.x)<<16
	var world := Vector2i(terrain.world_size())
	for distance in range(0,(world.x+world.y+1000)*2,2):
		minor += stride
		var point := _point(start,horizontal,direction,distance,minor>>16)
		if point.x<0 or point.x>world.x or point.y< -500 or point.y>world.y:
			return {}
		var contact := point_contact(point,terrain,actors)
		if not contact.is_empty():
			return contact
	return {}

## 4e4450: midpoint scanlines, horizontal extent truncated before doubling;
## right edge is exclusive (memset), unlike a filled floating-point ellipse.
static func crater_spans(center_point: Vector2i, dimension: int, aspect: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var radius := Physics.quot(dimension,2)
	if radius<0:
		return result
	_span(result,center_point,0,Physics.quot(radius*aspect,100))
	var decision := 1-radius
	var diagonal := 5-radius*2
	var vertical := 3
	var x := 0
	var y := radius
	while x<=y:
		x += 1
		var previous := diagonal
		if decision<0:
			diagonal = vertical
		else:
			previous += 2
			y -= 1
		decision += diagonal
		vertical += 2
		diagonal = previous+2
		_span(result,center_point,y,Physics.quot(x*aspect,100))
		_span(result,center_point,-y,Physics.quot(x*aspect,100))
		_span(result,center_point,x,Physics.quot(y*aspect,100))
		_span(result,center_point,-x,Physics.quot(y*aspect,100))
	return result

static func _span(result: Array[Vector3i], at: Vector2i, dy: int, half: int) -> void:
	if half>0:
		result.append(Vector3i(at.y+dy,at.x-half,at.x+half))
