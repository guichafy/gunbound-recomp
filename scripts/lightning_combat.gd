extends RefCounted
## Lightning native consumers:482550/4a8360/4837e0/43af40/43bda0/45ea40.
## See LIGHTNING_CLIENT_REVIEW.md for coordinate/item/weather bridges.
const Shared = preload("res://scripts/aduka_combat.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Items = preload("res://scripts/items.gd")
const Damage = preload("res://scripts/damage.gd")
static var catalog: Dictionary = {}

static func warmup() -> void:
	if catalog.is_empty():
		catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/lightning/combat_native.json"))

static func active(projectile: Dictionary) -> bool:
	return int(projectile.get("vehicle",0))==8 and not bool(projectile.get("beacon",false))

static func prepare(projectile: Dictionary, actor: Dictionary) -> void:
	if not active(projectile):return
	var data: Dictionary=catalog.weapons[int(projectile.weapon)]
	projectile.damage=int(data.power)+3*Attributes.points(actor,Attributes.ATTACK)
	projectile.lightning_dimension=int(data.dimension)+Physics.quot(Attributes.points(actor,Attributes.DIG),2)
	projectile.lightning_crater_percent=100+int(Items.dig(str(actor.get("turn_item",""))))
	projectile.blast_radius=Physics.quot(int(projectile.lightning_dimension),2)
	projectile.skip_actors=int(projectile.weapon)<2
	projectile.native_contact_stride=3 if int(projectile.weapon)==0 else 8

static func parameters(projectile: Dictionary, actor: Dictionary, weapon: int = -1) -> Dictionary:
	var slot:=int(projectile.weapon) if weapon<0 else weapon
	var source: Dictionary=catalog.weapons[slot]
	# SS's remote strike calls431d90 with T1, independently of the SS blast.
	return {"power":int(projectile.damage) if slot==int(projectile.weapon) else int(source.power)+3*Attributes.points(actor,Attributes.ATTACK),
		"dimension":int(projectile.lightning_dimension) if slot==int(projectile.weapon) else int(source.dimension)+Physics.quot(Attributes.points(actor,Attributes.DIG),2),
		"aspect":int(source.aspect),"flags":int(source.flags),
		"weather_bonus":int(projectile.get("native_force",0)),
		"percent":100+int(Items.attack(str(actor.get("turn_item",""))))}

## First original solid pixel, scanning downward from y0, including holes
## outside X before a diagonal enters the map. No mobile intersection here.
static func ground_ray(terrain, impact: Vector2i, direction: int) -> Dictionary:
	var world:=Vector2i(terrain.world_size())
	var x:=impact.x-direction*impact.y
	for y in world.y:
		if terrain.native_solid(Vector2i(x,y)):
			return {"position":Vector2i(x,y),"contact":true,"direction":direction}
		x+=direction
	return {"position":Vector2i(x,world.y) if direction!=0 else Vector2i(impact.x,10000),"contact":false,"direction":direction}

static func shock_hit(feet: Vector2i, impact: Vector2i, direction: int, radius: int, flags: int, world: Vector2i) -> bool:
	var step:=radius if direction==0 else Physics.quot(radius*7,10)
	if step<=0:return false
	var cursor:=Vector2i(impact.x,mini(impact.y,world.y))
	var hit_radius:=radius+Physics.quot(radius,5) if (flags&8)!=0 else radius
	while cursor.y>=0 and cursor.x>=0 and cursor.x<world.x:
		if (feet-cursor).length_squared()<hit_radius*hit_radius:return true
		cursor+=Vector2i(direction*step,-step)
	return false

static func queue_shock(model, projectile: Dictionary, point: Vector2i, direction: int, data: Dictionary) -> void:
	for index in model.actors.size():
		var target: Dictionary=model.actors[index]
		if not bool(target.get("lightning_alive",int(target.hp)>0)) or bool(target.get("invulnerable",false)) or target.has("lightning_pending"):continue
		if not shock_hit(Shared.origin(target),point,direction,int(data.shock_radius),int(Shared.body(target).flags),Vector2i(model.terrain.world_size())):continue
		target.lightning_pending={"primary":int(data.shock),"secondary":int(data.chain),"radius":int(data.shock_radius),"projectile":projectile.duplicate(true)}

static func blast(model, projectile: Dictionary, point: Vector2i, weapon: int) -> void:
	var owner:=int(projectile.get("owner",model.shot_actor))
	var data:=parameters(projectile,model.actors[owner],weapon)
	var dimension:=Physics.quot(int(data.dimension)*int(projectile.get("lightning_crater_percent",100)),100)
	var removed: int=model.terrain.carve_native(Shared.crater_spans(point,dimension,int(data.aspect)))
	model.events.append({"type":"explosion","position":Vector2(point),"radius":int(data.dimension)*0.5,"weapon":weapon,"vehicle":8,"removed":removed,"angle":PI*0.5})
	Shared.apply(model.actors,model.events,point,data)

static func ray(model, projectile: Dictionary, impact: Vector2i, direction: int, weapon: int) -> void:
	var traced:=ground_ray(model.terrain,impact,direction)
	var point:=Vector2i(traced.position)
	# Native visual ray exists even if there is no solid contact.
	model.events.append({"type":"mobile_lightning","position":Vector2(point.x,mini(point.y,int(model.terrain.world_size().y))),"direction":direction,"ttl":0.5,"contact":traced.contact})
	if int(projectile.weapon)!=1:
		queue_shock(model,projectile,point,-direction,catalog.weapons[int(projectile.weapon)])
	if bool(traced.contact):blast(model,projectile,point,weapon)
	if int(projectile.weapon)==1:
		queue_shock(model,projectile,point,-direction,catalog.weapons[1])

static func impact(model, projectile: Dictionary, position: Vector2) -> void:
	# The native alive flag changes after damage/shock processing. Preserve
	# that eligibility until this tick's flush even if offline HP becomes0.
	for actor in model.actors:
		if not actor.has("lightning_alive"):actor.lightning_alive=int(actor.hp)>0
	var start: int=model.events.size()
	var point:=Vector2i(position)
	var weapon:=int(projectile.weapon)
	if weapon==2:
		#483ff0 calls4837e0 without a primary impact blast.
		model.events.append({"type":"explosion","position":Vector2(point),"radius":0.0,"weapon":2,"vehicle":8,"removed":0,"angle":PI*0.5})
		var radius:=int(catalog.weapons[2].shock_radius)
		var owner:=int(projectile.get("owner",model.shot_actor))
		for index in model.actors.size():
			var target: Dictionary=model.actors[index]
			if index==owner or int(target.hp)<=0 or bool(target.get("invulnerable",false)):continue
			if (Shared.origin(target)-Vector2i(0,10)-point).length_squared()<radius*radius:
				ray(model,projectile,Shared.origin(target),0,0)
	else:
		for direction in ([0] if weapon==0 else [1,-1]):
			ray(model,projectile,point,direction,weapon)
	model.explode_actions(position,projectile,start)

## Native43bda0 propagates the secondary20 once;45ea40 consumes pending at
## the end of simulation. Defense does not multiply this electrical damage.
static func resolve(model) -> void:
	var changed:=true
	while changed:
		changed=false
		for source in model.actors:
			if not source.has("lightning_pending") or not bool(source.get("lightning_alive",int(source.hp)>0)) or (int(Shared.body(source).flags)&1)!=0:continue
			var pending: Dictionary=source.lightning_pending
			for target in model.actors:
				if target.has("lightning_pending") or not bool(target.get("lightning_alive",int(target.hp)>0)) or bool(target.get("invulnerable",false)) or (int(Shared.body(target).flags)&3)!=0:continue
				if (Shared.origin(source)-Shared.origin(target)).length_squared()>=int(pending.radius)*int(pending.radius):continue
				target.lightning_pending=pending.duplicate(true)
				target.lightning_pending.primary=0
				changed=true
	for index in model.actors.size():
		var target: Dictionary=model.actors[index]
		if not target.has("lightning_pending"):continue
		var pending: Dictionary=target.lightning_pending
		target.erase("lightning_pending")
		if not bool(target.get("lightning_alive",int(target.hp)>0)) or bool(target.get("invulnerable",false)):continue
		var amount:=int(pending.primary)+int(pending.secondary)
		if (int(Shared.body(target).flags)&8)!=0:amount+=Physics.quot(amount*8,100)
		var first: int=model.events.size()
		Damage.deal_damage(model.actors,model.events,index,amount,"shock")
		model.collect_gold_damage(first,Vector2(target.pos),pending.projectile)
	for actor in model.actors:actor.erase("lightning_alive")
