extends RefCounted
## Presentation of weather columns, Thor, beams and ground
## particles with original Thor's Hammer art where this client has an equivalent.
## Historical calendar/layout adapters remain explicit. Never decides combat: it only
## reads match.gd state and events. Pause freezes it because game.gd stops ticking.

const Weather = preload("res://scripts/weather.gd")
const Maps = preload("res://scripts/maps.gd")
const Assets = preload("res://scripts/client_weather_assets.gd")
const ShotTiming = preload("res://scripts/classic_shot_timing.gd")
var lightning_beam_art = preload("res://scripts/lightning_beam_art.gd").new()
var native_beam_art = preload("res://scripts/aduka_beam_art.gd").new()
var native_thor_art = preload("res://scripts/thor_native_art.gd").new()
var native_columns = preload("res://scripts/mage_weather_art.gd").new()
var mage_sparks = preload("res://scripts/mage_sparks.gd").new()
var thor_glow = preload("res://scripts/additive_sprite_art.gd").new()
var column_glow = preload("res://scripts/additive_sprite_art.gd").new()
var beam_glow = preload("res://scripts/additive_sprite_art.gd").new()
var mark_glow = preload("res://scripts/additive_sprite_art.gd").new()
# Weather.cs: frames 128×64 (pivot 64,32), 8 frames at 15 fps, columns scroll 50 px/s.
const FRAME := Vector2(128, 64)
const SCROLL_SPEED := 50.0
const FADE_TIME := 1.0
const COLUMN_SHEETS := {
	"force": ["Force", 2], "weakness": ["Weakness", 2], "mirror": ["Mirror", 2],
	"random": ["Random", 2], "electricity": ["Electricity", 2], "tornado": ["Tornado", 2],
}
const CLIENT_COLUMNS := {"force":"FirewallTexture", "electricity":"LightningTexture", "tornado":"TornadoTexture"}
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
var thor_light: Texture2D
var thor_meta: Dictionary
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
		# Weakness/Mirror/Random have no category in this build (ADR-128).
		sheets[type] = Assets.texture(CLIENT_COLUMNS[type]) if CLIENT_COLUMNS.has(type) else load("res://assets/openbound/weather/%s.png" % COLUMN_SHEETS[type][0])
	thor_sheet = Assets.texture("ThorBody")
	thor_light = Assets.texture("ThorLight")
	thor_meta = Assets.thor_metadata()
	thor_laser = Assets.texture("LaserEffect")
	lightning = Assets.texture("Lightning")
	force_particle = Assets.texture("CrashTexture")
	electric_particle = force_particle
	sounds = {
		"mirror": load("res://assets/openbound/weather/Mirror.mp3"),
		"wind": load("res://assets/openbound/weather/WindTransition.mp3"),
		"lightning": load("res://assets/openbound/weather/LightningS1.mp3"),
		"thor": load("res://assets/openbound/thor/AdukaS2.mp3"),
	}
	ShotTiming.prewarm()
	# SpawnThorEffect432320 uses the Mage T2 blast table slot for both guides.
	sounds.thor_native = ShotTiming.stream(1,1,"blast")

func reset(map: Dictionary) -> void:
	clear_beams()
	native_thor_art.clear()
	particles.clear()
	beams.clear()
	column_age.clear()
	thor_position = Vector2.INF
	ground = null
	if not map.is_empty() and ResourceLoader.exists(Maps.path(map, "particle")):
		ground = load(Maps.path(map, "particle"))
		ground_frames = int(map.particle_frames)
		ground_pivot = map.particle_pivot

func react(event: Dictionary, model, sound) -> void:
	match event.type:
		"mage_spark_samples":
			mage_sparks.accept(event)
		"explosion":
			emit_ground(event.position, int(event.get("removed", 0)), float(event.get("angle", PI * 0.5)), model)
		"mobile_lightning":
			var effect: Dictionary=event.duplicate(true)
			effect.kind="mobile_lightning"
			effect.age=0.0
			beams.append(effect)
		"thor":
			beams.append({"kind": "thor", "from": event.from, "to": event.position, "age": 0.0, "level": int(event.level),"native":bool(event.get("native",false)),"ttl":float(event.get("ttl",0.6)),"period":int(event.get("period",1000)),"rgb":int(event.get("rgb",0x00ff00))})
			if event.has("native_angle"):
				beams[-1].native_angle = int(event.native_angle)
			thor_shot = 0.0
			emit_ground(event.position, int(event.removed), (Vector2(event.position) - Vector2(event.from)).angle(), model)
			if bool(event.get("contact",true)):
				sound.play("explosion", sounds.thor_native if bool(event.get("native",false)) else sounds.thor)
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
	mage_sparks.sync(int(model.spark_tick))
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
		if beams[i].age > float(beams[i].get("ttl",0.6)):
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
	RenderingServer.canvas_item_set_draw_index(column_glow.begin(view),-200)
	var height: float = model.terrain.world_size().y
	if model.weather.get("is_native")==true:
		native_columns.draw(view,model.weather.columns,column_age,offset,height)
		return
	native_columns.clear()
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
			var target := Rect2(Vector2(float(column.x) - size.x * 0.5, y) + offset, size)
			if column.type=="electricity":column_glow.draw(view,sheet,target,source,Transform2D.IDENTITY,tint)
			else:view.draw_texture_rect_region(sheet,target,source,tint)
			y += size.y
			segment += 1

func draw_thor(view: Node2D, model, offset: Vector2) -> void:
	RenderingServer.canvas_item_set_draw_index(thor_glow.begin(view),-100)
	if not (model.weather.thor.active or bool(model.weather.thor.get("present",false))) or thor_position == Vector2.INF:
		return
	if bool(model.weather.thor.get("native",false)):
		var at: Vector2 = native_thor_art.draw(view,model.weather.thor,offset,clampf(float(model.accumulator)/0.05,0,1))
		var text := "LV %d · %d XP"%[int(model.weather.thor.level),int(model.weather.thor.get("display_xp",model.weather.thor.xp))]
		var native_font: Font = view.ui.bold
		view.draw_string_outline(native_font,at+Vector2(30,70),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,4,view.ui.INK)
		view.draw_string(native_font,at+Vector2(30,70),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("9cff8a"))
		return
	# Stand 0–19, Active 20–39, ShootingS1 40–55 (ThorSatellite presets, 15 fps).
	var frame := 20 + int(clock * 15.0) % 20
	if thor_shot < 16.0 / 15.0:
		frame = 40 + int(thor_shot * 15.0) % 16
	if thor_sheet==null or thor_meta.is_empty():return
	# The historical adapter keeps its placement/15fps/scale. Native source
	# windows and hotspots replace the composed sheet's transparent padding.
	var body: Dictionary = thor_meta.sheets["ThorBody.png"]
	var cell := Vector2(body.cell[0],body.cell[1])
	var source := Rect2(Vector2(frame % 14, frame / 14) * cell, cell)
	var bob := Vector2(sin(clock * 0.8) * 3.0, cos(clock * 0.4) * 2.0)
	var focus := thor_position + Vector2(0, 400)
	for projectile in model.projectiles:
		if bool(projectile.get("thor", false)) and bool(projectile.launched):
			focus = projectile.pos
			break
	var transform := Transform2D((focus-thor_position).angle()-PI,Vector2.ONE*0.6,0,thor_position+bob+offset)
	view.draw_set_transform_matrix(transform)
	view.draw_texture_rect_region(thor_sheet, Rect2(-Vector2(body.origin[0],body.origin[1]), cell), source)
	view.draw_set_transform(Vector2.ZERO)
	if thor_light!=null:
		var light: Dictionary = thor_meta.sheets["ThorLight.png"]
		var light_cell := Vector2(light.cell[0],light.cell[1])
		var light_source := Rect2(Vector2(frame%14,frame/14)*light_cell,light_cell)
		thor_glow.draw(view,thor_light,Rect2(-Vector2(light.origin[0],light.origin[1]),light_cell),light_source,transform)
	var label := "LV %d · %d XP" % [int(model.weather.thor.level), int(model.weather.thor.xp)]
	var font: Font = view.ui.bold
	view.draw_string_outline(font, thor_position + offset + Vector2(30, 70), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, view.ui.INK)
	view.draw_string(font, thor_position + offset + Vector2(30, 70), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9cff8a"))

func clear_beams() -> void:
	thor_glow.clear()
	column_glow.clear()
	beam_glow.clear()
	mark_glow.clear()
	mage_sparks.reset()
	native_columns.clear()
	beams.clear()
	native_beam_art.clear()
	lightning_beam_art.clear()

func draw_beams(view: Node2D, offset: Vector2) -> void:
	RenderingServer.canvas_item_set_draw_index(beam_glow.begin(view),-100)
	lightning_beam_art.draw(view,beams.filter(func(beam):return str(beam.kind)=="mobile_lightning"),offset)
	var native_beams: Array = []
	for beam in beams:
		if bool(beam.get("native",false)):
			var native: Dictionary = beam.duplicate()
			native.position = native.to
			native_beams.append(native)
	native_beam_art.draw(view,native_beams,offset)
	for beam in beams:
		if bool(beam.get("native",false)) or str(beam.kind)=="mobile_lightning":
			continue
		var from: Vector2 = Vector2(beam.from) + offset
		var to: Vector2 = Vector2(beam.to) + offset
		var length := from.distance_to(to)
		if length < 1.0:
			continue
		var fade := clampf(1.0 - float(beam.age) / 0.6, 0.0, 1.0)
		var angle := (to - from).angle() - PI * 0.5
		var transform := Transform2D(angle,from)
		if beam.kind == "thor":
			var color: Color = THOR_COLORS[clampi(int(beam.level) - 1, 0, THOR_COLORS.size() - 1)]
			if thor_laser!=null:
				var region := beam_region("thor",int(float(beam.age)*20.0))
				beam_glow.draw(view,thor_laser,Rect2(-12,0,24,length),region,transform,Color(color,fade))
				beam_glow.draw(view,thor_laser,Rect2(-5,0,10,length),region,transform,Color(1,1,1,fade))
		else:
			var frame := (int(beam.frame) + int(float(beam.age) * 20.0)) % 4
			if lightning!=null:beam_glow.draw(view,lightning,Rect2(-24,0,48,length),beam_region("lightning",frame),transform,Color(1,1,1,fade))

func draw_shell_marks(view: Node2D, model, offset: Vector2) -> void:
	RenderingServer.canvas_item_set_draw_index(mark_glow.begin(view),-150)
	mage_sparks.draw(view,offset)
	# Force sparks, electric arcs and Weakness darkening ride on influenced shells.
	for projectile in model.projectiles:
		if not bool(projectile.launched):
			continue
		if int(projectile.get("vehicle",0))==1 and not bool(projectile.get("beacon",false)):
			continue
		var position: Vector2 = Vector2(projectile.hit_pos) + offset
		var frame := int(clock * 15.0) % 8
		if "electricity" in projectile.influenced and electric_particle!=null:
			mark_glow.draw(view,electric_particle,Rect2(position-Vector2(20,20),Vector2(40,40)),shell_mark_region("electricity",frame),Transform2D.IDENTITY)
		if "force" in projectile.influenced and force_particle!=null:
			for k in range(3):
				var jitter := Vector2(sin(clock * 23.0 + k * 2.1), cos(clock * 19.0 + k * 1.7)) * 12.0
				mark_glow.draw(view,force_particle,Rect2(position+jitter-Vector2(8,8),Vector2(16,16)),shell_mark_region("force",frame+k),Transform2D.IDENTITY)
		if "weakness" in projectile.influenced:
			view.draw_circle(position, 9.0, Color(0.12, 0.12, 0.12, 0.55))

## Source strips are native; non-Mage emission/layout above remain adapters.
static func shell_mark_region(kind: String, frame: int) -> Rect2:
	return Rect2(posmod(frame,8)*32,64 if kind=="force" else 96,32,32)

static func beam_region(kind: String, frame: int) -> Rect2:
	return Rect2(posmod(frame,8)*16,0,16,256) if kind=="thor" else Rect2(posmod(frame,4)*64,0,64,256)

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
