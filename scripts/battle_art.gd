extends RefCounted
## Presentation-only animation. Draw calls receive a context, not the game node.

const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const SpritePose = preload("res://scripts/sprite_pose.gd")

const USING_ITEM_TIME := 20.0 / 19.0
var motion: Array = []

func reset(actors: Array) -> void:
	motion.clear()
	for actor in actors:
		var spec: Dictionary = Mobiles.definition(actor.vehicle)
		motion.append({"pos": Vector2(actor.pos), "previous": Vector2(actor.pos), "moving": 0.0, "recoil": 0.0, "hurt": 0.0, "hurt_pose": "hurt", "hurt_flip": false, "shock": 0.0, "falling": 0.0, "unable": 0.0, "using": 0.0, "dead": 0.0, "rotation": 0.0, "pose": "idle", "pose_age": 0.0, "wheel_phase": 0.0, "hurt_time": float(spec.hurt), "death_time": float(spec.death)})

func react(event: Dictionary) -> void:
	# A Dual second volley replays the shooting animation (OnStartInteracting).
	if event.type in ["fire", "volley"]:
		motion[event.actor].recoil = 1.16
		motion[event.actor].pose = "recoil"
		motion[event.actor].pose_age = 0.0
	elif event.type == "item":
		# Mobile.UseItem: ActorFlipbookState.UsingItem, 20 frames at 19 fps.
		motion[event.actor].using = USING_ITEM_TIME
		motion[event.actor].pose = "using_item"
		motion[event.actor].pose_age = 0.0
	elif event.type == "teleport":
		# ForceChangePosition: the mobile appears at the beacon, no slide.
		motion[event.actor].pos = Vector2(event.to)
		motion[event.actor].previous = Vector2(event.to)
	elif event.type in ["damage", "shield_damage"]:
		if str(event.get("kind", "")) == "shock":
			motion[event.actor].shock = 1.0
			motion[event.actor].pose = "shock"
		else:
			var alternate: bool = bool(motion[event.actor].hurt_flip)
			motion[event.actor].hurt_flip = not alternate
			motion[event.actor].hurt_pose = "hurt_2" if alternate else "hurt"
			motion[event.actor].hurt = float(motion[event.actor].hurt_time)
			motion[event.actor].pose = str(motion[event.actor].hurt_pose)
		motion[event.actor].pose_age = 0.0
	elif event.type == "fall":
		motion[event.actor].falling = 1.0
		motion[event.actor].pose = "falling"
		motion[event.actor].pose_age = 0.0
	elif event.type == "blocked":
		motion[event.actor].unable = 1.0
		motion[event.actor].pose = "unable"
		motion[event.actor].pose_age = 0.0

func tick(model, delta: float, charging: bool = false, selected_weapon: int = 0, cpu_charging: bool = false, cpu_weapon: int = 0) -> void:
	for index in range(motion.size()):
		var state: Dictionary = motion[index]
		var actor: Dictionary = model.actors[index]
		state.moving = 0.16 if absf(actor.pos.x - state.previous.x) > 0.01 else maxf(0.0, state.moving - delta)
		state.wheel_phase += (actor.pos.x - state.previous.x) / 15.0
		state.previous = actor.pos
		state.pos = Vector2(state.pos).lerp(actor.pos, 1.0 - exp(-delta * 18.0))
		state.rotation = lerp_angle(float(state.rotation), model.body_rotation(index), 1.0 - exp(-delta * 18.0))
		state.recoil = maxf(0.0, state.recoil - delta)
		state.hurt = maxf(0.0, state.hurt - delta)
		state.shock = maxf(0.0, state.shock - delta)
		state.falling = maxf(0.0, state.falling - delta)
		state.unable = maxf(0.0, state.unable - delta)
		state.using = maxf(0.0, state.using - delta)
		if actor.hp <= 0:
			state.dead += delta
		var pose := state_name(model, index, charging, cpu_charging)
		if pose == "charging":
			pose += "_" + str(selected_weapon if index == Match.PLAYER else cpu_weapon)
		if state.pose != pose:
			state.pose = pose
			state.pose_age = 0.0
		else:
			state.pose_age += delta

func state_name(model, index: int, charging: bool, cpu_charging: bool = false) -> String:
	if model.actors[index].hp <= 0:
		return "destroyed"
	if motion[index].shock > 0.0:
		return "shock"
	if motion[index].hurt > 0.0:
		return str(motion[index].hurt_pose)
	if motion[index].falling > 0.0:
		return "falling"
	if motion[index].unable > 0.0:
		return "unable"
	if motion[index].recoil > 0.0:
		return "recoil"
	if motion[index].using > 0.0:
		return "using_item"
	if (charging and index == Match.PLAYER) or (cpu_charging and index == Match.CPU):
		return "charging"
	if motion[index].moving > 0.0:
		return "moving"
	return "idle"

func selected_weapon(model, index: int, ctx: Dictionary) -> int:
	var pose := state_name(model, index, bool(ctx.charging), bool(ctx.cpu_charging))
	var weapon: int = int(ctx.player_weapon) if index == Match.PLAYER else int(ctx.cpu_weapon)
	if pose == "recoil":
		weapon = int(model.last_shots[index].get("weapon", 0))
	return weapon

func atlas_frame(model, index: int, ctx: Dictionary) -> int:
	var actor: Dictionary = model.actors[index]
	var state: Dictionary = motion[index]
	var weapon := selected_weapon(model, index, ctx)
	return ctx.atlas.frame_index(state_name(model, index, bool(ctx.charging), bool(ctx.cpu_charging)), float(state.pose_age), weapon, Mobiles.low_health(actor))

func presentation(index: int, rig, clock: float, weapon: int) -> Dictionary:
	# A separate history per actor; interrupted transitions start at the last
	# displayed geometry, not at an unrelated frame of the previous pose.
	var state: Dictionary = motion[index]
	var target: Dictionary = rig.sample(state.pose,float(state.pose_age),weapon,clock)
	var visual: Dictionary = state.get("visual",{})
	if visual.is_empty():
		visual = {"pose":state.pose,"age":state.pose_age,"weapon":weapon,"started":clock-0.14,"from":target.duplicate(true),"current":target}
		state.visual = visual
	elif visual.pose != state.pose or visual.weapon != weapon or float(state.pose_age) < float(visual.age):
		visual.from = visual.current.duplicate(true)
		visual.started = clock
		visual.pose = state.pose
		visual.weapon = weapon
	visual.age = state.pose_age
	var weight := smoothstep(0.0,0.14,maxf(0.0,clock-float(visual.started)))
	if weight >= 1.0:
		visual.current = target
		return target
	var result := target.duplicate(true)
	for field in ["body_offset","pilot_anchor"]:
		result[field] = Vector2(visual.from[field]).lerp(target[field],weight)
	for field in ["body_angle","barrel_angle","pilot_angle"]:
		result[field] = lerp_angle(float(visual.from[field]),float(target[field]),weight)
	visual.current = result
	return result

func draw_actor(view: Node2D, model, index: int, offset: Vector2, ctx: Dictionary) -> void:
	var actor: Dictionary = model.actors[index]
	var state: Dictionary = motion[index]
	var pos: Vector2 = state.pos
	var dead: float = state.dead
	var death_duration := float(state.death_time)
	if actor.hp <= 0 and dead > death_duration:
		return
	var time: float = float(ctx.elapsed)
	var rotation: float = state.rotation
	if actor.hp <= 0:
		rotation += dead * float(actor.facing) * 0.8
	view.draw_set_transform(pos + offset)
	view.draw_style_box(ctx.shadow, Rect2(-40, 21, 80, 9))
	view.draw_set_transform(Vector2.ZERO)
	var alpha := clampf(1.0 - dead / death_duration, 0.0, 1.0) if actor.hp <= 0 else 1.0
	var color := Color(1, 0.65, 0.6, alpha) if state.hurt > 0.0 and int(time * 24.0) % 2 == 0 else Color(1, 1, 1, alpha)
	var atlas = ctx.atlas
	var weapon: int = int(ctx.player_weapon) if index == Match.PLAYER else int(ctx.cpu_weapon)
	if state.pose == "recoil":
		weapon = int(model.last_shots[index].get("weapon", 0))
	var avatar_context: Dictionary = ctx.get("avatar_context",{}).duplicate()
	avatar_context.rig_state = presentation(index,atlas.hd_rig,time,weapon)
	atlas.draw(view, SpritePose.new(pos + offset, 60.0, actor.facing, {"rotation": rotation, "frame": atlas_frame(model, index, ctx),
		"color": color, "pose": state.pose, "age": state.pose_age, "weapon": weapon, "low_health": Mobiles.low_health(actor),
		"wheel_phase": state.wheel_phase, "avatar_context": avatar_context}))
	if bool(Mobiles.definition(int(actor.vehicle)).smoke) and int(actor.hp) > 0 and Mobiles.low_health(actor):
		var puff := fposmod(time, 0.8) / 0.8
		view.draw_circle(pos + offset + Vector2(8.0 * float(actor.facing), -20.0 - puff * 18.0), 2.5 + puff * 3.5, Color(0.78, 0.78, 0.8, (1.0 - puff) * 0.4))
