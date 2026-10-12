extends RefCounted
## Presentation-only animation. Draw calls receive a context, not the game node.

const Match = preload("res://scripts/match.gd")
const Mobiles = preload("res://scripts/mobiles.gd")

var motion: Array = []

func reset(actors: Array) -> void:
	motion.clear()
	for actor in actors:
		var spec: Dictionary = Mobiles.definition(actor.vehicle)
		motion.append({"pos": Vector2(actor.pos), "previous": Vector2(actor.pos), "moving": 0.0, "recoil": 0.0, "hurt": 0.0, "dead": 0.0, "rotation": 0.0, "pose": "idle", "pose_age": 0.0, "wheel_phase": 0.0, "hurt_time": float(spec.hurt), "death_time": float(spec.death)})

func react(event: Dictionary) -> void:
	if event.type == "fire":
		motion[event.actor].recoil = 1.16
		motion[event.actor].pose = "recoil"
		motion[event.actor].pose_age = 0.0
	elif event.type in ["damage", "shield_damage"]:
		motion[event.actor].hurt = float(motion[event.actor].hurt_time)
		motion[event.actor].pose = "hurt"
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
	if motion[index].hurt > 0.0:
		return "hurt"
	if motion[index].recoil > 0.0:
		return "recoil"
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
	return ctx.atlas.frame_index(state_name(model, index, bool(ctx.charging), bool(ctx.cpu_charging)), float(state.pose_age), weapon, actor.hp <= actor.max_hp * 0.3)

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
	atlas.draw(view, pos + offset, 60.0, actor.facing, rotation, atlas_frame(model, index, ctx), color, state.pose, state.pose_age, weapon, actor.hp <= actor.max_hp * 0.3, state.wheel_phase, ctx.get("avatar_context",{}))

func draw_explosion(view: Node2D, effect: Dictionary) -> void:
	var age: float = effect.age
	var pos: Vector2 = effect.pos
	var radius: float = effect.radius
	var flash := maxf(0.0, 1.0 - age / 0.32)
	view.draw_circle(pos, radius * (0.3 + age * 2.0), Color(1, 0.55, 0.16, flash * 0.48))
	view.draw_circle(pos, radius * 0.45 * flash, Color(1, 0.97, 0.78, flash))
	view.draw_arc(pos, radius * (0.3 + age * 1.8), 0, TAU, 48, Color(1, 0.85, 0.45, flash), maxf(1, flash * 5), true)
	for i in range(18):
		var direction := Vector2.from_angle(PI + float(i) * PI / 17.0)
		var speed := radius * (1.1 + float(i % 4) * 0.25)
		var point := pos + direction * speed * age + Vector2(0, age * age * 150.0)
		var opacity := maxf(0.0, 1.0 - age / 1.2)
		var color := Color(Color("c49863") if i % 3 else Color("e7d497"), opacity)
		view.draw_set_transform(point, age * (i + 1))
		view.draw_rect(Rect2(-3, -3, 6, 4), color)
	view.draw_set_transform(Vector2.ZERO)
	for i in range(6):
		var point := pos + Vector2((i - 2.5) * 11.0, -age * (38 + i * 5))
		var opacity := maxf(0.0, 1.0 - age / 1.5) * 0.28
		view.draw_circle(point, 8 + age * (15 + i), Color(0.2, 0.22, 0.26, opacity))
