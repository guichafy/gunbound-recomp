extends RefCounted
## Presentation-only animation and procedural effects; never writes match state.

var motion: Array = []

func reset(actors: Array) -> void:
	motion.clear()
	for actor in actors:
		motion.append({"pos": Vector2(actor.pos), "previous": Vector2(actor.pos), "moving": 0.0, "recoil": 0.0, "hurt": 0.0, "dead": 0.0, "rotation": 0.0, "pose": "idle", "pose_age": 0.0, "bigfoot": actor.vehicle == 2})

func react(event: Dictionary) -> void:
	if event.type == "fire":
		motion[event.actor].recoil = 1.16 if motion[event.actor].bigfoot else 0.45
		motion[event.actor].pose = "recoil"
		motion[event.actor].pose_age = 0.0
	elif event.type == "damage":
		motion[event.actor].hurt = 1.05 if motion[event.actor].bigfoot else 0.5
		motion[event.actor].pose = "hurt"
		motion[event.actor].pose_age = 0.0

func tick(model, delta: float, charging: bool = false, selected_weapon: int = 0) -> void:
	for index in range(motion.size()):
		var state: Dictionary = motion[index]
		var actor: Dictionary = model.actors[index]
		state.moving = 0.16 if absf(actor.pos.x - state.previous.x) > 0.01 else maxf(0.0, state.moving - delta)
		state.previous = actor.pos
		state.pos = Vector2(state.pos).lerp(actor.pos, 1.0 - exp(-delta * 18.0))
		state.rotation = lerp_angle(float(state.rotation), model.body_rotation(index), 1.0 - exp(-delta * 18.0))
		state.recoil = maxf(0.0, state.recoil - delta)
		state.hurt = maxf(0.0, state.hurt - delta)
		if actor.hp <= 0:
			state.dead += delta
		var pose := state_name(model, index, charging)
		if pose == "charging":
			pose += "_" + str(selected_weapon)
		if state.pose != pose:
			state.pose = pose
			state.pose_age = 0.0
		else:
			state.pose_age += delta

func state_name(model, index: int, charging: bool) -> String:
	if model.actors[index].hp <= 0:
		return "destroyed"
	if motion[index].hurt > 0.0:
		return "hurt"
	if motion[index].recoil > 0.0:
		return "recoil"
	if charging and index == 0:
		return "charging"
	if motion[index].moving > 0.0:
		return "moving"
	return "idle"

func atlas_frame(view: Node2D, index: int) -> int:
	var actor: Dictionary = view.model.actors[index]
	var state: Dictionary = motion[index]
	var pose := state_name(view.model, index, view.charging)
	var weapon: int = view.weapon if index == 0 else int(view.model.last_shots[index].get("weapon", 0))
	if pose == "recoil":
		weapon = int(view.model.last_shots[index].get("weapon", 0))
	return view.bigfoot.frame_index(pose, float(state.pose_age), weapon, actor.hp <= actor.max_hp * 0.3)

func draw_actor(view: Node2D, index: int, offset: Vector2) -> void:
	var model = view.model
	var actor: Dictionary = model.actors[index]
	var state: Dictionary = motion[index]
	var pos: Vector2 = state.pos
	var dead: float = state.dead
	if actor.hp <= 0 and dead > 1.15:
		return
	var tint: Color = model.VEHICLES[actor.vehicle].color
	var time: float = view.elapsed
	var rotation: float = state.rotation
	var recoil: float = state.recoil / 0.45
	var bounce := sin(time * (22.0 if state.moving > 0.0 else 2.8)) * (2.0 if state.moving > 0.0 else 0.65)
	var hurt: float = sin(time * 85.0) * state.hurt * 4.0
	var render_pos := pos + offset + Vector2(-actor.facing * recoil * 8.0 + hurt, bounce)
	if actor.hp <= 0:
		render_pos += Vector2(0, dead * dead * 45.0)
		rotation += dead * float(actor.facing) * 0.8
	view.draw_set_transform(pos + offset)
	view.draw_style_box(view.ui.box(Color(0.02, 0.04, 0.1, 0.28), 10), Rect2(-40, 21, 80, 9))
	view.draw_set_transform(Vector2.ZERO)
	var alpha := clampf(1.0 - dead / 1.15, 0.0, 1.0) if actor.hp <= 0 else 1.0
	var color := Color(1, 0.65, 0.6, alpha) if state.hurt > 0.0 and int(time * 24.0) % 2 == 0 else Color(1, 1, 1, alpha)
	if actor.vehicle == 2:
		view.bigfoot.draw(view, pos + offset, 60.0, actor.facing, rotation, atlas_frame(view, index), color)
	else:
		view.draw_sprite(actor.vehicle, render_pos, 100.0, actor.facing, rotation, Vector2(1.0 + recoil * 0.05, 1.0 - recoil * 0.07), color)
	if actor.hp <= 0:
		return
	if actor.vehicle != 2:
		# Small animated drive disks reinforce movement without changing the PNG.
		view.draw_set_transform(render_pos, rotation)
		for x in [-22.0, 0.0, 22.0]:
			view.draw_circle(Vector2(x, 14), 7.0, Color("13283e"))
			view.draw_arc(Vector2(x, 14), 5.0, 0, TAU, 16, tint.darkened(0.2), 2.0, true)
			var spin: float = time * 10.0 * actor.facing if state.moving > 0.0 else 0.0
			view.draw_line(Vector2(x, 14) - Vector2.from_angle(spin) * 4, Vector2(x, 14) + Vector2.from_angle(spin) * 4, view.ui.STEEL, 1.5, true)
		view.draw_set_transform(Vector2.ZERO)
		var actor_angle: float = view.angle if index == 0 else float(view.cpu_plan.get("angle", model.last_shots[index].get("angle", 45.0)))
		var direction: Vector2 = model.shot_velocity(index, actor_angle, 100, 0).normalized()
		var pivot: Vector2 = model.cannon_pivot(index) + offset
		var tip := pivot + direction * (38.0 - recoil * 10.0)
		view.draw_line(pivot, tip, Color("091523"), 13.0, true)
		view.draw_line(pivot, tip, tint.darkened(0.2), 8.0, true)
		view.draw_line(pivot + Vector2(-1, -2), tip + Vector2(-1, -2), tint.lightened(0.3), 2.0, true)
		view.draw_circle(pivot, 7.0, view.ui.STEEL)
		if view.charging and index == 0:
			var radius: float = 10.0 + view.power * 0.1 + sin(time * 25.0) * 2.0
			view.draw_circle(tip, radius, Color(tint, 0.2))
			view.draw_arc(tip, radius * 0.7, time * 4, time * 4 + PI * 1.5, 30, view.ui.AMBER, 2.0, true)
		if recoil > 0.55:
			var blast: Vector2 = model.muzzle(index, actor_angle) + offset
			view.draw_circle(blast, recoil * 15.0, Color(1, 0.75, 0.3, recoil * 0.8))
			view.draw_circle(blast, recoil * 7.0, Color(1, 1, 0.85, recoil))
	if model.active == index and model.phase == "aim":
		var pointer := pos + offset + Vector2(0, -94 + sin(time * 4.0) * 3.0)
		view.draw_colored_polygon(PackedVector2Array([pointer + Vector2(-8, -9), pointer + Vector2(8, -9), pointer + Vector2(0, 3)]), view.ui.AMBER)
		view.draw_string(view.ui.bold, pointer + Vector2(-23, -17), "TURNO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, view.ui.INK)
	var name: String = view.profile.nickname if index == 0 else "Autômato"
	var width: float = view.ui.bold.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	view.draw_style_box(view.ui.box(Color(0.03, 0.08, 0.14, 0.87), 3, view.ui.STEEL), Rect2(pos.x + offset.x - width * 0.5 - 7, pos.y + offset.y + 76, width + 14, 22))
	view.draw_string(view.ui.bold, pos + offset + Vector2(-width / 2, 92), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tint.lightened(0.2))

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

func draw_compass(view: Node2D) -> void:
	var center := Vector2(640, 52)
	var ui = view.ui
	view.draw_circle(center + Vector2(2, 4), 42, Color(0, 0, 0, 0.25))
	view.draw_circle(center, 40, ui.INK)
	view.draw_arc(center, 40, 0, TAU, 64, ui.STEEL, 3, true)
	view.draw_arc(center, 35, 0, TAU, 64, Color("355c7c"), 1, true)
	for i in range(12):
		var dir := Vector2.from_angle(i * TAU / 12)
		view.draw_line(center + dir * 30, center + dir * 34, ui.STEEL, 1, true)
	if not is_zero_approx(view.model.wind):
		var facing := signf(view.model.wind)
		var arrow: Color = ui.AMBER if absf(view.model.wind) > 18 else ui.TEAL
		view.draw_line(center + Vector2(-facing * 19, 0), center + Vector2(facing * 22, 0), arrow, 4, true)
		view.draw_colored_polygon(PackedVector2Array([center + Vector2(facing * 24, 0), center + Vector2(facing * 12, -7), center + Vector2(facing * 12, 7)]), arrow)
	view.draw_string(ui.bold, center + Vector2(-29, 57), "VENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ui.INK)
