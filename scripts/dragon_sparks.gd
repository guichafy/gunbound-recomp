extends RefCounted
## Dragon S1/S2 have no published body (vtable 0x555ea8 publish = 0x429800):
## the shot is the trail of sparks that its Simulate 0x46fb20 leaves on every
## coarse sample of the sweep (ADR-154). The model only publishes each tick's
## sweep ("dragon_spark_sweep"); this presentation owns the RNG, like mage_sparks.
##  - sweep: 8 px samples from the previous to the current position; a per-shell
##    counter (0x3f9c, mod 6) lets a sample emit while it is below the Effect3D
##    quality byte 0x5f2f54 (1..3).
##  - 0x436fd0: 8 trials per sample, each passing on an even rand(); the spark
##    sits k/8 of the way from the previous position, ±4 px, angle rand()%360.
##  - 0x4711f0: lives 16 ticks, angle +6 per tick. 0x471240 draws CrashTexture
##    with 0x4ec840: size (16-age)*16/10, u (age/2)/8, v 0.615, alpha 255-16*age,
##    SRCALPHA/ONE.
const Assets = preload("res://scripts/client_weather_assets.gd")
const Art = preload("res://scripts/mage_spark_art.gd")
const STRIDE := 8
const LIFETIME := 16
const ROW := 0.61500000953674316
const DEFAULT_SEED := 1414
var quality := 3
var random_state := DEFAULT_SEED
var tick := 0
var particles: Array = []
var counters: Dictionary = {}
var texture: Texture2D
var material := CanvasItemMaterial.new()
var canvases: Dictionary = {}

func _init() -> void:
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

func _rand() -> int:
	random_state = (random_state * 214013 + 2531011) & 0xffffffff
	return (random_state >> 16) & 32767

func reset(seed_value: int = DEFAULT_SEED) -> void:
	particles.clear()
	counters.clear()
	random_state = seed_value & 0xffffffff
	tick = 0
	clear_canvases()

## Native sample points of one sweep, the same walk as 0x455cc0/0x46fb20.
static func samples(from: Vector2i, to: Vector2i) -> Array:
	var dx := absi(to.x - from.x)
	var dy := absi(to.y - from.y)
	var points: Array = []
	if dy < dx:
		var slope := ((to.y - from.y) << 16) / (dx + 1)
		var direction := 1 if from.x <= to.x else -1
		for index in range(dx / STRIDE + 1):
			points.append(Vector2i(from.x + direction * STRIDE * index, ((from.y << 16) + slope * STRIDE * (index + 1)) >> 16))
	else:
		var slope := ((to.x - from.x) << 16) / (dy + 1)
		var direction := 1 if from.y <= to.y else -1
		for index in range(dy / STRIDE + 1):
			points.append(Vector2i(((from.x << 16) + slope * STRIDE * (index + 1)) >> 16, from.y + direction * STRIDE * index))
	return points

func sync(current_tick: int) -> void:
	tick = current_tick
	for index in range(particles.size() - 1, -1, -1):
		var spark: Dictionary = particles[index]
		spark.age = tick - int(spark.birth) + 1
		spark.angle = (int(spark.initial_angle) + int(spark.age) * 6) % 360
		if int(spark.age) >= LIFETIME:
			particles.remove_at(index)

func accept(event: Dictionary) -> void:
	var birth := int(event.tick)
	if birth > tick:
		sync(birth)
	var from: Vector2i = event.from
	var key := str(event.get("key", ""))
	# 0x3f9c starts at 0 on every new shell.
	if bool(event.get("first", false)):
		counters.erase(key)
	for point in samples(from, Vector2i(event.to)):
		var counter := int(counters.get(key, 0))
		if counter < quality:
			emit(point, from, birth)
		counters[key] = (counter + 1) % 6

## 0x436fd0(sample, 8, previous).
func emit(point: Vector2i, from: Vector2i, birth: int) -> void:
	for step in STRIDE:
		if _rand() % 2 != 0:
			continue
		var x := from.x + (step * (point.x - from.x)) / STRIDE - 4 + _rand() % 9
		var y := from.y + (step * (point.y - from.y)) / STRIDE - 4 + _rand() % 9
		var angle := _rand() % 360
		particles.append({"position": Vector2i(x, y), "birth": birth, "initial_angle": angle, "age": 1, "angle": (angle + 6) % 360})

static func quad(spark: Dictionary) -> Dictionary:
	var age := int(spark.age)
	if age < 0 or age >= LIFETIME:
		return {}
	return Art.native_quad(Vector2i(spark.position), int(spark.angle), ((LIFETIME - age) * 16) / 10, float(age / 2) * 0.125, ROW, 255 - 16 * age)

func draw(view: Node2D, offset: Vector2) -> void:
	if particles.is_empty() and not canvases.has(view.get_instance_id()):
		return
	if texture == null:
		texture = Assets.texture("CrashTexture")
	if texture == null:
		return
	var id := view.get_instance_id()
	var canvas: RID
	if canvases.has(id):
		canvas = canvases[id]
	else:
		canvas = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(canvas, view.get_canvas_item())
		RenderingServer.canvas_item_set_material(canvas, material.get_rid())
		canvases[id] = canvas
	RenderingServer.canvas_item_clear(canvas)
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for spark in particles:
		var shape := quad(spark)
		if shape.is_empty():
			continue
		var base := points.size()
		for point in shape.points:
			points.append(point + offset)
		uv.append_array(shape.uv)
		for vertex in 4:
			colors.append(shape.color)
		indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
	if not points.is_empty():
		RenderingServer.canvas_item_add_triangle_array(canvas, indices, points, colors, uv, PackedInt32Array(), PackedFloat32Array(), texture.get_rid())

func clear_canvases() -> void:
	for canvas in canvases.values():
		RenderingServer.canvas_item_clear(canvas)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for canvas in canvases.values():
			RenderingServer.free_rid(canvas)
