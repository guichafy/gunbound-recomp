extends RefCounted
## Presentation of weather columns, Thor, beams and ground
## particles with the original OpenBound sprites. Never decides combat: it only
## reads match.gd state and events. Pause freezes it because game.gd stops ticking.

const Weather = preload("res://scripts/weather.gd")
# Weather.cs: frames 128×64 (pivot 64,32), 8 frames at 15 fps, columns scroll 50 px/s.
const FRAME := Vector2(128, 64)
const SCROLL_SPEED := 50.0
const FADE_TIME := 1.0
const COLUMN_SHEETS := {
	"force": ["Force", 2], "weakness": ["Weakness", 2], "mirror": ["Mirror", 2],
	"random": ["Random", 2], "electricity": ["Electricity", 1], "tornado": ["Tornado", 1],
}
# WeatherDisplay icon order (22×22): row 0 coloured, row 1 grayscale.
const ICON_INDEX := {"force": 0, "tornado": 1, "electricity": 2, "wind": 3, "thor": 4, "protection": 5, "ignorance": 6, "weakness": 7, "mirror": 8, "random": 9}
const NAMES := {"force": "Força", "tornado": "Tornado", "electricity": "Elétrico", "wind": "Vento", "thor": "Thor", "protection": "Proteção", "ignorance": "Ignorância", "weakness": "Fraqueza", "mirror": "Espelho", "random": "Aleatório"}
# Thor beam colours by level (Parameter.ColorGradient, alpha raised for visibility).
const THOR_COLORS := [Color8(57, 255, 20), Color8(27, 3, 163), Color8(204, 255, 0), Color8(255, 7, 58), Color8(255, 255, 255)]
# ParticleBuilder / Particle.cs ground particle parameters.
const PARTICLE_ROTATION := PI * 50.0
const PARTICLE_SCALE := 0.5
const PARTICLE_Y_SPEED := -500.0
const PARTICLE_MAX_SPEED := 2000.0
const PARTICLE_Y_ACCELERATION := 500.0
const PARTICLE_WIND := 5.0
const PARTICLE_SPREAD := 5
const PARTICLE_CAP := 80

var sheets := {}
var thor_sheet: Texture2D
var thor_laser: Texture2D
var lightning: Texture2D
var force_particle: Texture2D
var electric_particle: Texture2D
var ground: Texture2D
var ground_frames := 0
var ground_pivot := Vector2(24, 24)
var sounds := {}
var scroll := 0.0
var clock := 0.0
var column_age := {}
var particles: Array = []
var beams: Array = []
var thor_position := Vector2.INF
var thor_shot := 0.0
var noise := RandomNumberGenerator.new()

func _init() -> void:
	noise.seed = 4242
	for type in COLUMN_SHEETS:
		sheets[type] = load("res://assets/openbound/weather/%s.png" % COLUMN_SHEETS[type][0])
	thor_sheet = load("res://assets/openbound/thor/Spritesheet.png")
	thor_laser = load("res://assets/openbound/thor/ThorLaser.png")
	lightning = load("res://assets/openbound/weather/LightningSE.png")
	force_particle = load("res://assets/openbound/weather/ForceParticle.png")
	electric_particle = load("res://assets/openbound/weather/ElectricityParticle.png")
	sounds = {
		"mirror": load("res://assets/openbound/weather/Mirror.mp3"),
		"wind": load("res://assets/openbound/weather/WindTransition.mp3"),
		"lightning": load("res://assets/openbound/weather/LightningS1.mp3"),
		"thor": load("res://assets/openbound/thor/AdukaS2.mp3"),
	}

func reset(map: Dictionary) -> void:
	particles.clear()
	beams.clear()
	column_age.clear()
	thor_position = Vector2.INF
	ground = null
	if not map.is_empty() and ResourceLoader.exists(map.particle):
		ground = load(map.particle)
		ground_frames = int(map.particle_frames)
		ground_pivot = map.particle_pivot

func react(event: Dictionary, model, sound) -> void:
	match event.type:
		"explosion":
			emit_ground(event.position, int(event.get("removed", 0)), float(event.get("angle", PI * 0.5)), model)
		"thor":
			beams.append({"kind": "thor", "from": event.from, "to": event.position, "age": 0.0, "level": int(event.level)})
			thor_shot = 0.0
			emit_ground(event.position, int(event.removed), (Vector2(event.position) - Vector2(event.from)).angle(), model)
			sound.play("explosion", sounds.thor)
		"lightning":
			beams.append({"kind": "lightning", "from": event.top, "to": event.position, "age": 0.0, "frame": noise.randi_range(0, 3)})
			emit_ground(event.position, int(event.removed), -PI * 0.5, model)
			sound.play("explosion", sounds.lightning)
		"weather_hit":
			if event.weather == "mirror":
				sound.play("explosion", sounds.mirror)
		"weather":
			if event.weather == "wind":
				sound.play("turn", sounds.wind)

func emit_ground(position: Vector2, removed_cells: int, angle: float, model) -> void:
	# Projectile.cs: removed pixels / 32 particles (one cell is 2×2 pixels).
	if ground == null or ground_frames <= 0 or removed_cells <= 0:
		return
	var wind: Vector2 = model.weather.wind_vector() * PARTICLE_WIND
	var count := mini(PARTICLE_CAP, removed_cells * 4 / 32)
	for i in range(count):
		var spread := float(i % PARTICLE_SPREAD + 1)
		var direction := angle + (noise.randf() - 0.5) * TAU / spread
		var trajectory := Vector2.from_angle(direction)
		var amount := noise.randf()
		particles.append({
			"origin": position, "age": 0.0, "frame": noise.randi_range(0, ground_frames - 1),
			"speed": Vector2(amount * PARTICLE_MAX_SPEED * trajectory.x, PARTICLE_Y_SPEED + amount * PARTICLE_MAX_SPEED * trajectory.y),
			"acceleration": Vector2(wind.x, PARTICLE_Y_ACCELERATION + wind.y),
			"rotation": direction, "spin": (noise.randf() - 0.5) * PARTICLE_ROTATION,
			"growth": (noise.randf() - 0.5) * PARTICLE_SCALE,
		})

func tick(delta: float, model) -> void:
	clock += delta
	scroll = fmod(scroll + SCROLL_SPEED * delta, FRAME.y * 8.0)
	var alive := {}
	for column in model.weather.columns:
		alive[int(column.id)] = true
		column_age[int(column.id)] = float(column_age.get(int(column.id), 0.0)) + delta
	for id in column_age.keys():
		if not alive.has(id):
			column_age.erase(id)
	var world: Vector2 = model.terrain.world_size()
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		particle.age += delta
		var position := particle_position(particle)
		if position.y > world.y + 60.0 or position.x < -200.0 or position.x > world.x + 200.0 or particle.age > 6.0:
			particles.remove_at(i)
	for i in range(beams.size() - 1, -1, -1):
		beams[i].age += delta
		if beams[i].age > 0.6:
			beams.remove_at(i)
	# ThorSatellite.SetPosition eases with a sine over a quarter period.
	var target: Vector2 = model.weather.thor.pos
	if thor_position == Vector2.INF:
		thor_position = target
	thor_position = thor_position.lerp(target, 1.0 - pow(0.02, delta))
	thor_shot += delta

func particle_position(particle: Dictionary) -> Vector2:
	var t: float = particle.age
	return Vector2(particle.origin) + Vector2(particle.speed) * t + Vector2(particle.acceleration) * t * t * 0.5

func draw_columns(view: Node2D, model, offset: Vector2) -> void:
	var height: float = model.terrain.world_size().y
	for column in model.weather.columns:
		var sheet: Texture2D = sheets.get(column.type)
		if sheet == null:
			continue
		var columns_in_sheet: int = COLUMN_SHEETS[column.type][1]
		var scale: float = float(column.scale)
		var size := FRAME * scale
		var fade := clampf(float(column_age.get(int(column.id), 0.0)) / FADE_TIME, 0.0, 1.0)
		if column.type == "random" and bool(column.used):
			fade *= 0.35
		var tint := Color(1, 1, 1, fade)
		var start := -size.y + fmod(scroll * scale, size.y)
		var segment := 0
		var y := start
		while y < height + size.y:
			# Variable columns animate at 15 fps; Random keeps a fixed frame per segment.
			var frame := segment % 8 if column.type == "random" else (int(clock * 15.0) + segment) % 8
			var source := Rect2(Vector2(frame % columns_in_sheet, frame / columns_in_sheet) * FRAME, FRAME)
			view.draw_texture_rect_region(sheet, Rect2(Vector2(float(column.x) - size.x * 0.5, y) + offset, size), source, tint)
			y += size.y
			segment += 1

func draw_thor(view: Node2D, model, offset: Vector2) -> void:
	if not model.weather.thor.active or thor_position == Vector2.INF:
		return
	# Stand 0–19, Active 20–39, ShootingS1 40–55 (ThorSatellite presets, 15 fps).
	var frame := 20 + int(clock * 15.0) % 20
	if thor_shot < 16.0 / 15.0:
		frame = 40 + int(thor_shot * 15.0) % 16
	var cell := Vector2(197, 190)
	var source := Rect2(Vector2(frame % 14, frame / 14) * cell, cell)
	var bob := Vector2(sin(clock * 0.8) * 3.0, cos(clock * 0.4) * 2.0)
	var focus := thor_position + Vector2(0, 400)
	for projectile in model.projectiles:
		if bool(projectile.get("thor", false)) and bool(projectile.launched):
			focus = projectile.pos
			break
	view.draw_set_transform(thor_position + bob + offset, (focus - thor_position).angle() - PI, Vector2.ONE * 0.6)
	view.draw_texture_rect_region(thor_sheet, Rect2(-Vector2(118, 111), cell), source)
	view.draw_set_transform(Vector2.ZERO)
	var label := "LV %d · %d XP" % [int(model.weather.thor.level), int(model.weather.thor.xp)]
	var font: Font = view.ui.bold
	view.draw_string_outline(font, thor_position + offset + Vector2(30, 70), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, view.ui.INK)
	view.draw_string(font, thor_position + offset + Vector2(30, 70), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9cff8a"))

func draw_beams(view: Node2D, offset: Vector2) -> void:
	for beam in beams:
		var from: Vector2 = Vector2(beam.from) + offset
		var to: Vector2 = Vector2(beam.to) + offset
		var length := from.distance_to(to)
		if length < 1.0:
			continue
		var fade := clampf(1.0 - float(beam.age) / 0.6, 0.0, 1.0)
		var angle := (to - from).angle() - PI * 0.5
		view.draw_set_transform(from, angle)
		if beam.kind == "thor":
			var color: Color = THOR_COLORS[clampi(int(beam.level) - 1, 0, THOR_COLORS.size() - 1)]
			view.draw_texture_rect(thor_laser, Rect2(-12, 0, 24, length), false, Color(color, fade))
			view.draw_texture_rect(thor_laser, Rect2(-5, 0, 10, length), false, Color(1, 1, 1, fade))
		else:
			var frame := (int(beam.frame) + int(float(beam.age) * 20.0)) % 4
			view.draw_texture_rect_region(lightning, Rect2(-24, 0, 48, length), Rect2(frame * 64, 0, 64, 256), Color(1, 1, 1, fade))
		view.draw_set_transform(Vector2.ZERO)

func draw_shell_marks(view: Node2D, model, offset: Vector2) -> void:
	# Force sparks, electric arcs and Weakness darkening ride on influenced shells.
	for projectile in model.projectiles:
		if not bool(projectile.launched):
			continue
		var position: Vector2 = Vector2(projectile.hit_pos) + offset
		var frame := int(clock * 15.0) % 8
		if "electricity" in projectile.influenced:
			view.draw_texture_rect_region(electric_particle, Rect2(position - Vector2(20, 20), Vector2(40, 40)), Rect2(frame * 32, 0, 32, 32))
		if "force" in projectile.influenced:
			for k in range(3):
				var jitter := Vector2(sin(clock * 23.0 + k * 2.1), cos(clock * 19.0 + k * 1.7)) * 12.0
				view.draw_texture_rect_region(force_particle, Rect2(position + jitter - Vector2(8, 8), Vector2(16, 16)), Rect2(((frame + k) % 8) * 32, 0, 32, 32))
		if "weakness" in projectile.influenced:
			view.draw_circle(position, 9.0, Color(0.12, 0.12, 0.12, 0.55))

func draw_particles(view: Node2D, offset: Vector2) -> void:
	if ground == null:
		return
	var cell := ground_pivot * 2.0
	var columns := int(ground.get_width() / cell.x)
	for particle in particles:
		var frame: int = particle.frame
		var source := Rect2(Vector2(frame % columns, frame / columns) * cell, cell)
		var scale := maxf(0.1, 1.0 + float(particle.growth) * float(particle.age))
		view.draw_set_transform(particle_position(particle) + offset, float(particle.rotation) + float(particle.spin) * float(particle.age), Vector2.ONE * scale)
		view.draw_texture_rect_region(ground, Rect2(-ground_pivot, cell), source)
	view.draw_set_transform(Vector2.ZERO)
