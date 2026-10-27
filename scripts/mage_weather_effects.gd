extends RefCounted
## PE457386/4a4f42/4840c2: attached Electricity precedes Thor, then
## the caller applies Mage's crater/EMP/blast. Shared execution/prediction
## use this pure model path; no scene, profile, resource loading or RNG here.
const Lightning = preload("res://scripts/lightning_combat.gd")
const Shared = preload("res://scripts/aduka_combat.gd")
const Thor = preload("res://scripts/aduka_effect.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Items = preload("res://scripts/items.gd")
const ELECTRIC_POWER := 230
const ELECTRIC_DIMENSION := 54
const ELECTRIC_ASPECT := 134
const ELECTRIC_FLAGS := 1
const ELECTRIC_DIVISOR := 2
const SHOCK_PRIMARY := 20
const SHOCK_SECONDARY := 20
const SHOCK_RADIUS := 25
const THOR_INITIAL_Y := 500
const THOR_Y_STEP := 40
const THOR_Y_CAP := 1000

static func shell_divisor(projectile: Dictionary) -> int:
	return 2 if int(projectile.get("weapon",0))==1 else 1

## 431d90 calls41da80 with divisor1, then40ab20 divides the complete
## power/dimension cells by2.17e4 is the percentage, not accumulated Force15c0;
## the new blast starts without the parent's Force bonus.
## Item percentages retain the explicitly authorized offline item bridge.
static func parameters(projectile: Dictionary, actor: Dictionary) -> Dictionary:
	return {"power":Physics.quot(ELECTRIC_POWER+3*Attributes.points(actor,Attributes.ATTACK),ELECTRIC_DIVISOR),
		"dimension":Physics.quot(ELECTRIC_DIMENSION+Physics.quot(Attributes.points(actor,Attributes.DIG),2),ELECTRIC_DIVISOR),
		"aspect":ELECTRIC_ASPECT,"flags":ELECTRIC_FLAGS,
		"weather_bonus":0,
		"percent":100+int(Items.attack(str(actor.get("turn_item",""))))}

static func impact(model, projectile: Dictionary, position: Vector2) -> void:
	if int(projectile.get("vehicle",0))!=1 or bool(projectile.get("beacon",false)):
		return
	if bool(projectile.get("electric",false)):
		for actor in model.actors:
			if not actor.has("lightning_alive"):
				actor.lightning_alive=int(actor.hp)>0
		var traced := Lightning.ground_ray(model.terrain,Vector2i(position),0)
		var point := Vector2i(traced.position)
		model.events.append({"type":"mobile_lightning","position":Vector2(point.x,mini(point.y,int(model.terrain.world_size().y))),
			"direction":0,"ttl":0.5,"contact":traced.contact,"native_attached":true,"source":"weather"})
		# The same shock/chain consumers as MobileLightning, with independent
		# weather constants25/20/20, not Lightning's70/56/20 weapon table.
		Lightning.queue_shock(model,projectile,point,0,{"shock":Physics.quot(SHOCK_PRIMARY,shell_divisor(projectile)),
			"chain":SHOCK_SECONDARY,"shock_radius":SHOCK_RADIUS})
		if bool(traced.contact):
			var owner := int(projectile.get("owner",model.shot_actor))
			var actor: Dictionary=model.actors[owner]
			var data := parameters(projectile,actor)
			var crater_percent := 100+int(Items.dig(str(actor.get("turn_item",""))))
			var dimension := Physics.quot(int(data.dimension)*crater_percent,100)
			var removed: int=model.terrain.carve_native(Shared.crater_spans(point,dimension,ELECTRIC_ASPECT))
			model.events.append({"type":"explosion","position":Vector2(point),"radius":float(data.dimension)*0.5,
				"weapon":0,"vehicle":8,"owner":owner,"removed":removed,"angle":PI*0.5,
				"native_attached":true,"source":"weather"})
			Shared.apply(model.actors,model.events,point,data)
	# Native callers inspect current climate4 at impact. No launch-time
	# projectile.thor flag can replace this gate. Electricity may carve first.
	if not model.weather.queue.is_empty() and str(model.weather.queue[0].type)=="thor":
		Thor.strike(model,projectile,position,"mage_weather",shell_divisor(projectile))

## 4bb730→4bc117→439d90: input is the native LCG seed at setup entry.
## The normal1×1 setup has no previous5b3480 advance. MSVCRT rand used
## for cell obfuscation/audio is a different generator. Both IMULs wrap32.
static func native_thor_position(seed: int, width: int) -> Dictionary:
	var state := seed&0xffffffff
	var value := (state*0xda003+0x5703b11)&0xffffffff
	var advanced := (state+((value*97+97)&0xffffffff)%1000001)&0xffffffff
	return {"position":Vector2(Physics.quot(width,2)+value%1000-500,THOR_INITIAL_Y),"seed":advanced,"t":value}

## Thor exists in the native scene independently of the active climate.
## Return the advanced seed so an integrating native calendar can retain it.
static func setup_thor(model, seed: int) -> int:
	var initial := native_thor_position(seed,int(model.terrain.world_size().x))
	model.weather.thor.pos=initial.position
	Thor.ensure_thor(model)
	model.weather.thor.display_pos=initial.position
	model.weather.thor.previous_display_pos=initial.position
	model.weather.thor.transition_turn=-1
	return int(initial.seed)

## Called once per new1-based turn after the calendar updates its climate.
## 4cf310 phase0, after its actor queue empties, enters4ccd10;4ce1b2
## recomputes Thor level once before the next shot.4cee30 moves Y only
## at max(turn−1,0)%period==0; snapshots own the transition marker deeply.
static func transition(model, total_turns: int) -> void:
	if not bool(model.weather.thor.get("native",false)):
		return
	var thor: Dictionary=model.weather.thor
	if int(thor.get("transition_turn",-1))==total_turns:
		return
	thor.transition_turn=total_turns
	thor.level=Thor.level_for_xp(int(thor.get("xp",0)))
	var configured_period = model.weather.get("period")
	var period := maxi(1,int(configured_period)) if configured_period!=null else 2
	if maxi(total_turns-1,0)%period!=0:
		return
	thor.active=not model.weather.queue.is_empty() and str(model.weather.queue[0].type)=="thor"
	if bool(thor.active):
		thor.pos.y=mini(int(thor.pos.y)+THOR_Y_STEP,THOR_Y_CAP)
	thor.state="active" if bool(thor.active) else "normal"
	thor.state_tick=0
