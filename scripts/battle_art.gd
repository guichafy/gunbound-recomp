extends RefCounted
## Presentation-only animation and procedural effects; never writes match state.

var motion: Array = []

func reset(actors: Array) -> void:
	motion.clear()
	for actor in actors:
		motion.append({"pos": Vector2(actor.pos), "previous": Vector2(actor.pos), "moving": 0.0, "recoil": 0.0, "hurt": 0.0, "dead": 0.0, "rotation": 0.0, "pose": "idle", "pose_age": 0.0, "wheel_phase": 0.0, "bigfoot": actor.vehicle == 2, "mage": actor.vehicle == 1})

func react(event: Dictionary) -> void:
	if event.type == "fire":
		motion[event.actor].recoil = 1.16
		motion[event.actor].pose = "recoil"
		motion[event.actor].pose_age = 0.0
	elif event.type in ["damage", "shield_damage"]:
		motion[event.actor].hurt = 1.05 if (motion[event.actor].bigfoot or motion[event.actor].mage) else 0.5
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
			pose += "_" + str(selected_weapon if index == 0 else cpu_weapon)
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
	if (charging and index == 0) or (cpu_charging and index == 1):
		return "charging"
	if motion[index].moving > 0.0:
		return "moving"
	return "idle"

func atlas_frame(view: Node2D, index: int) -> int:
	var actor: Dictionary = view.model.actors[index]
	var state: Dictionary = motion[index]
	var pose := state_name(view.model, index, view.charging, view.model.phase == "aim" and view.model.active == 1 and not view.cpu_plan.is_empty())
	var weapon: int = view.weapon if index == 0 else int(view.cpu_plan.get("weapon", view.model.last_shots[index].get("weapon", 0)))
	if pose == "recoil":
		weapon = int(view.model.last_shots[index].get("weapon", 0))
	var atlas = view.mage if actor.vehicle == 1 else view.bigfoot
	return atlas.frame_index(pose, float(state.pose_age), weapon, actor.hp <= actor.max_hp * 0.3)

func draw_actor(view: Node2D, index: int, offset: Vector2) -> void:
	var model = view.model
	var actor: Dictionary = model.actors[index]
	var state: Dictionary = motion[index]
	var pos: Vector2 = state.pos
	var dead: float = state.dead
	var death_duration := 1.6 if actor.vehicle == 1 else 1.15
	if actor.hp <= 0 and dead > death_duration:
		return
	var tint: Color = model.VEHICLES[actor.vehicle].color
	var time: float = view.elapsed
	var rotation: float = state.rotation
	if actor.hp <= 0:
		rotation += dead * float(actor.facing) * 0.8
	view.draw_set_transform(pos + offset)
	view.draw_style_box(view.ui.box(Color(0.02, 0.04, 0.1, 0.28), 10), Rect2(-40, 21, 80, 9))
	view.draw_set_transform(Vector2.ZERO)
	var alpha := clampf(1.0 - dead / death_duration, 0.0, 1.0) if actor.hp <= 0 else 1.0
	var color := Color(1, 0.65, 0.6, alpha) if state.hurt > 0.0 and int(time * 24.0) % 2 == 0 else Color(1, 1, 1, alpha)
	var atlas = view.mage if actor.vehicle == 1 else view.bigfoot
	var weapon: int = view.weapon if index == 0 else int(view.cpu_plan.get("weapon", model.last_shots[index].get("weapon", 0)))
	if state.pose == "recoil":
		weapon = int(model.last_shots[index].get("weapon", 0))
	atlas.draw(view, pos + offset, 60.0, actor.facing, rotation, atlas_frame(view, index), color, state.pose, state.pose_age, weapon, actor.hp <= actor.max_hp * 0.3, state.wheel_phase)
	# Turn pointer and name box gave way to the original HUD (hud_art.gd).

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
