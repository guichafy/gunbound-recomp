extends RefCounted
## Aduka guides request Thor even outside Thor weather (PE0x4398e0).
## Native tables/SETG thresholds/beam raster: ADUKA_CLASSIC_FIX.md.
## Initial Thor placement remains the deterministic offline world policy.

const Combat = preload("res://scripts/combat.gd")
const NativeCombat = preload("res://scripts/aduka_combat.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const Attributes = preload("res://scripts/player_attributes.gd")
const Items = preload("res://scripts/items.gd")
const POWER := [100,140,180,220,260,300]
const DIMENSION := [44,46,48,50,52,54]
const PERIOD := [1000,800,700,600,500,400]
const RGB := [0x00ff00,0x00c040,0x008080,0x0040c0,0x0000ff,0xffffff]
const XP := [0,200,600,1600,3600,6600]

static func active(projectile: Dictionary) -> bool:
	return str(projectile.get("flight","")) == "aduka"

static func prepare(projectile: Dictionary) -> void:
	if not active(projectile):
		return
	projectile.damage = 0
	projectile.blast_radius = 0.0
	projectile.thor = false
	projectile.aduka_struck = false

static func parameters(level: int) -> Dictionary:
	var index := clampi(level,1,6)-1
	return {"power":POWER[index],"dimension":DIMENSION[index],"period":PERIOD[index],"rgb":RGB[index]}

static func level_for_xp(experience: int) -> int:
	var level := 1
	for index in XP.size():
		if experience > XP[index]:
			level = index+1
	return level

static func ensure_thor(model) -> void:
	var thor: Dictionary = model.weather.thor
	# The client receives this position from outside its factory. The offline
	# fallback is deterministic and consumes no match RNG or camera position.
	if not bool(thor.get("present",false)) and not bool(thor.get("active",false)) and Vector2(thor.get("pos",Vector2.ZERO)) == Vector2.ZERO:
		var world: Vector2 = model.terrain.world_size()
		thor.pos = Vector2(floor(world.x*0.5),floor(world.y*0.15))
	thor.present = true
	thor.level = clampi(int(thor.get("level",1)),1,6)
	thor.xp = maxi(0,int(thor.get("xp",0)))
	if not bool(thor.get("native",false)):
		thor.merge({"native":true,"state":"active" if thor.active else "normal","state_tick":0,
			"idle_tick":0,"native_angle":270,"display_pos":thor.pos,"previous_display_pos":thor.pos,
			"display_xp":int(thor.xp)})

## Thor Animate4abda0: EPA20Hz, discrete22-tick bob and integer Y easing.
## Called by the same fixed step in live play and copied CPU simulations.
static func step_thor(model) -> void:
	var thor: Dictionary = model.weather.thor
	if not bool(thor.get("native",false)):
		return
	thor.previous_display_pos = thor.display_pos
	var position: Vector2 = thor.display_pos
	var target: Vector2 = thor.pos
	thor.display_pos = Vector2(int(target.x),int(position.y)+Physics.quot(int(target.y-position.y)+7,8))
	thor.display_xp = int(thor.display_xp)+Physics.quot(int(thor.xp)-int(thor.display_xp)+7,8)
	thor.idle_tick = (int(thor.idle_tick)+1)%22
	thor.state_tick = int(thor.state_tick)+1
	if str(thor.state) == "fire" and int(thor.state_tick)<16:
		return
	var state := "active" if bool(thor.active) else "normal"
	if str(thor.state)!=state:
		thor.state = state
		thor.state_tick = 0


static func cannon(thor_position: Vector2, target: Vector2) -> Vector2:
	# 0x4f1f10 takes integer deltas directly (EAX=x,ECX=y), halves toward
	# zero into [-127,128], and reads a signed WORD. It does NOT perform the
	# flight heading's /100 and rounding to three degrees.
	Physics.warmup()
	var delta := target-thor_position
	if delta == Vector2.ZERO:
		return thor_position
	var heading := target_angle(Vector2i(delta))
	return thor_position + Vector2(-int(Physics.s(heading+90)*-50.0),-int(Physics.s(heading)*50.0))

static func target_angle(delta: Vector2i) -> int:
	Physics.warmup()
	var x := delta.x
	var y := delta.y
	while x < -127 or x > 128 or y < -127 or y > 128:
		x = Physics.quot(x,2)
		y = Physics.quot(y,2)
	return Physics.angles.decode_s16(2*(x+127+256*(y+127)))

static func impact(model, projectile: Dictionary, position: Vector2) -> bool:
	if not active(projectile) or bool(projectile.get("aduka_struck",false)):
		return false
	projectile.aduka_struck = true
	projectile.thor = false
	return strike(model,projectile,position)

## A shared native Thor request; weather-triggered beams in an Aduka match
## use the same level/XP table and art instead of reverting to the C# table.
static func strike(model, projectile: Dictionary, position: Vector2, source: String = "aduka", power_divisor: int = 1) -> bool:
	ensure_thor(model)
	var thor: Dictionary = model.weather.thor
	var level := int(thor.level)
	var data := parameters(level)
	# Mage weather attachment432320: divide power only, keep dimension;
	#45799a multiplies the beam period by the parent shell's divisor.
	power_divisor = maxi(1,power_divisor)
	data.power = Physics.quot(int(data.power),power_divisor)
	data.period = int(data.period)*power_divisor
	var owner := int(projectile.get("owner",model.shot_actor))
	var weapon := int(projectile.get("weapon",1))
	var origin := cannon(Vector2(thor.pos),position)
	# Native producer computes/stores the contact; the consumer applies that
	# record. One offline call combines those stages, without a swept DDA.
	var contact := NativeCombat.thor_contact(Vector2i(origin),Vector2i(position),model.terrain,model.actors)
	# Missing contact records suppress the blast, but the native consumer still
	# publishes the visual ray to the guide. Do not invent damage at its target.
	var strike: Vector2 = contact.get("position",position)
	var radius := float(data.dimension)*0.5
	var removed: int = 0 if contact.is_empty() else model.terrain.carve_native(NativeCombat.crater_spans(Vector2i(strike),int(data.dimension),150))
	#432320 creates a separate electrical blast with100%, aspect150 and no
	# owner Attack/Dig transfer. Shield/overkill credit follows45db20.
	var dealt: int = 0 if contact.is_empty() else NativeCombat.apply(model.actors,model.events,Vector2i(strike),
		{"power":data.power,"dimension":data.dimension,"aspect":150,"flags":4,"percent":100},true)
	thor.xp = int(thor.xp)+maxi(0,dealt)
	#4ccd10→4ac180 recomputes level at the next turn transition. Keep the
	# existing non-Mage bridge until its separate integration is requested.
	if model.weather.get("is_native")!=true:
		thor.level = level_for_xp(int(thor.xp))
	thor.state = "fire"
	thor.state_tick = 0
	thor.native_angle = target_angle(Vector2i(position)-Vector2i(thor.pos))
	var color := Color8((int(data.rgb)>>16)&255,(int(data.rgb)>>8)&255,int(data.rgb)&255)
	var effect := {"kind":"aduka","tick":-1,"owner":owner,"weapon":weapon,"vehicle":16,
		"from":origin,"position":strike,"target":position,"level":level,"period":data.period,"rgb":data.rgb,
		"native_angle":target_angle(Vector2i(position)-Vector2i(thor.pos))}
	model.battle_effects.append(effect)
	model.events.append({"type":"thor","native":true,"source":source,"actor":owner,
		"contact":not contact.is_empty(),
		"owner":owner,"weapon":weapon,"vehicle":16,"from":origin,"position":strike,
		"target":position,"removed":removed,"level":level,"new_level":thor.level,
		"xp":thor.xp,"guide_power":0,"power":data.power,"radius":radius,
		"ttl":1.0,"width":32.0,"period":data.period,"color":color,"rgb":data.rgb,
		"native_angle":effect.native_angle})
	return true

## Return whether the effect remains alive. The match owns deletion, and
## calls once per shared20Hz tick; a paused scene never advances this clock.
static func tick(_model, effect: Dictionary) -> bool:
	effect.tick = int(effect.get("tick",-1))+1
	return int(effect.tick)<=19

## Native0x4aacd0 draws a colored expanding quad and a white shrinking quad.
## half_width and alpha are integers; callers may build triangles without
## changing contact points. Each quad uses the same tick%8 UV phase.
static func beam_layers(effect: Dictionary, tick_value: int) -> Array:
	var count := clampi(tick_value,0,19)
	var period := maxi(1,int(effect.get("period",parameters(int(effect.get("level",1))).period)))
	return [{"half_width":16+int(count*count*100/period),"alpha":maxi(1,255-count*16),
		"rgb":int(effect.get("rgb",0x00ff00)),"uv_frame":count%8},
		{"half_width":maxi(1,int(16/maxi(1,count))),"alpha":255 if count<10 else maxi(1,455-count*20),
		"rgb":0xffffff,"uv_frame":count%8}]

static func beam_quads(effect: Dictionary, tick_value: int) -> Array:
	Physics.warmup()
	var heading := int(effect.get("native_angle",target_angle(Vector2i(Vector2(effect.position)-Vector2(effect.from)))))
	var origin := Vector2(effect.from)
	var target := Vector2(effect.position)
	var quads: Array = []
	for layer in beam_layers(effect,tick_value):
		var width: int = layer.half_width
		# 0x4aada1..4aae60: truncate each complete float32-LUT product.
		var side_a := Vector2(int(width*Physics.s(heading+180)),int(-width*Physics.s(heading+90)))
		var side_b := Vector2(int(width*Physics.s(heading)),int(-width*Physics.s(heading-90)))
		var u := float(layer.uv_frame)/16.0
		var rgb := int(layer.rgb)
		quads.append({"points":PackedVector2Array([origin+side_a,target+side_a,target+side_b,origin+side_b]),
			"uv":PackedVector2Array([Vector2(u,1),Vector2(u,0),Vector2(u+1.0/16.0,0),Vector2(u+1.0/16.0,1)]),
			"color":Color8((rgb>>16)&255,(rgb>>8)&255,rgb&255,int(layer.alpha))})
	return quads
