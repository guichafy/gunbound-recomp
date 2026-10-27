extends RefCounted
## Native Thor image/EPA and discrete model clocks. Never changes model state.
const Assets = preload("res://scripts/client_weather_assets.gd")
const Timing = preload("res://scripts/classic_shot_timing.gd")
const BOB := [-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0]
var meta: Dictionary
var textures := {}
var glow = preload("res://scripts/additive_sprite_art.gd").new()

func _init() -> void:
	meta = Assets.thor_metadata()
	if meta.is_empty():return
	for name in meta.sheets:
		var paint := CanvasTexture.new()
		paint.diffuse_texture = Assets.texture(str(name).get_basename())
		if paint.diffuse_texture==null:continue
		paint.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		textures[name] = paint

func sample(thor: Dictionary, fraction: float = 1.0) -> Dictionary:
	if meta.is_empty():return {}
	var state := str(thor.get("state","normal"))
	var sequence: Dictionary = meta.states.get(state,meta.states.normal)
	var frame := Timing.frame(sequence.frames,sequence.durations,int(thor.get("state_tick",0))*Timing.STEP,state!="fire")
	var position := Vector2(thor.get("previous_display_pos",thor.pos)).lerp(Vector2(thor.get("display_pos",thor.pos)),clampf(fraction,0,1))
	if state!="fire":
		position.y += BOB[posmod(int(thor.get("idle_tick",0)),22)]
	return {"state":state,"frame":frame,"position":position,"rotation":-deg_to_rad(float(thor.get("native_angle",270)))}

func draw(view: Node2D, thor: Dictionary, offset: Vector2, fraction: float = 1.0) -> Vector2:
	glow.begin(view)
	var data := sample(thor,fraction)
	if data.is_empty():return Vector2(thor.pos)+offset
	var transform := Transform2D(float(data.rotation),Vector2(data.position)+offset)
	for name in meta.sheets:
		if not textures.has(name):continue
		var info: Dictionary = meta.sheets[name]
		var cell := Vector2(info.cell[0],info.cell[1])
		var target := Rect2(-Vector2(info.origin[0],info.origin[1]),cell)
		var index := int(data.frame)
		var source := Rect2(Vector2(index%int(meta.columns),index/int(meta.columns))*cell,cell)
		if name=="ThorLight.png":
			glow.draw(view,textures[name],target,source,transform)
		else:
			view.draw_set_transform_matrix(transform)
			view.draw_texture_rect_region(textures[name],target,source)
	view.draw_set_transform(Vector2.ZERO)
	return Vector2(data.position)+offset

func clear() -> void:
	glow.clear()
