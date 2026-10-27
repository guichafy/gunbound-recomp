extends RefCounted
## Mage decorative Force/Electric FX from436dc0/436ec0. RNG belongs only
## to presentation; physical point records never consume it in Match/CPU.
const Art = preload("res://scripts/mage_spark_art.gd")
const DEFAULT_SEED := 4242
var quality := 3 # Explicit local Effect3D input; native setting allows1/2/3.
var random_state := DEFAULT_SEED
var tick := 0
var particles: Array = []
var texture: Texture2D
var material := CanvasItemMaterial.new()
var canvases: Dictionary = {}

func _init() -> void:
	material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED

static func force_passes(force: int, level: int, roll: int) -> bool:
	return roll%400<level*force

static func electric_passes(level: int, roll: int) -> bool:
	return roll%100<level

func _rand() -> int:
	random_state=(random_state*214013+2531011)&0xffffffff
	return (random_state>>16)&32767

func reset(seed_value: int = DEFAULT_SEED) -> void:
	particles.clear()
	random_state=seed_value&0xffffffff
	tick=0
	clear_canvases()

func sync(current_tick: int) -> void:
	tick=current_tick
	for index in range(particles.size()-1,-1,-1):
		var effect: Dictionary=particles[index]
		effect.tick=tick-int(effect.birth)+1
		effect.angle=(int(effect.initial_angle)+int(effect.tick)*(1 if effect.kind=="force" else 6))%360
		if int(effect.tick)>15:particles.remove_at(index)

func accept(event: Dictionary) -> void:
	var samples: PackedInt32Array=event.samples
	var birth:=int(event.tick)
	if birth>tick:sync(birth)
	for offset in range(0,samples.size(),4):
		var point:=Vector2i(samples[offset],samples[offset+1])
		#436dc0 is attempted even atForce0; preserve that random draw.
		if force_passes(samples[offset+2],quality,_rand()):_spawn("force",point,birth)
		#455cc0 also calls436bd0 atForce0. Mage's passive density1e50
		# is0, so it creates no particle but still consumes its own trial.
		if samples[offset+2]==0:_rand()
		if samples[offset+3]!=0 and electric_passes(quality,_rand()):_spawn("electricity",point,birth)

func _spawn(kind: String, point: Vector2i, birth: int) -> void:
	var position:=point+Vector2i(_rand()%21-10,_rand()%21-10)
	var angle:=_rand()%360
	#190003/190004 are updated afterMage100002 in the same native tick.
	var age:=tick-birth+1
	if age>15:return
	particles.append({"kind":kind,"position":position,"birth":birth,"initial_angle":angle,
		"tick":age,"angle":(angle+age*(1 if kind=="force" else 6))%360})

func draw(view: Node2D, offset: Vector2) -> void:
	if particles.is_empty() and not canvases.has(view.get_instance_id()):return
	if texture==null:texture=load(Art.TEXTURE)
	var id:=view.get_instance_id()
	var canvas: RID
	if canvases.has(id):canvas=canvases[id]
	else:
		canvas=RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(canvas,view.get_canvas_item())
		RenderingServer.canvas_item_set_material(canvas,material.get_rid())
		RenderingServer.canvas_item_set_draw_index(canvas,-150)
		canvases[id]=canvas
	RenderingServer.canvas_item_clear(canvas)
	var points:=PackedVector2Array()
	var uv:=PackedVector2Array()
	var colors:=PackedColorArray()
	var indices:=PackedInt32Array()
	for kind in ["force","electricity"]:
		for effect in particles:
			if str(effect.kind)!=kind:continue
			var quad:=Art.quad(effect)
			if quad.is_empty():continue
			var base:=points.size()
			for point in quad.points:points.append(point+offset)
			uv.append_array(quad.uv)
			for vertex in 4:colors.append(quad.color)
			indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))
	if not points.is_empty():
		RenderingServer.canvas_item_add_triangle_array(canvas,indices,points,colors,uv,PackedInt32Array(),PackedFloat32Array(),texture.get_rid())

func clear_canvases() -> void:
	for canvas in canvases.values():RenderingServer.canvas_item_clear(canvas)

func _notification(what: int) -> void:
	if what==NOTIFICATION_PREDELETE:
		for canvas in canvases.values():RenderingServer.free_rid(canvas)
