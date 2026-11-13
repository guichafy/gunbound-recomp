extends RefCounted
## EPA/IMG scenery; parallax transform follows the port's existing backdrop.
const Timing = preload("res://scripts/classic_shot_timing.gd")
var textures: Dictionary = {}

static func sample(map: Dictionary, age: float) -> Array:
	var result: Array = []
	for row in map.get("scenery",[]):
		var frame := Timing.frame(row.frames,row.durations,age,bool(row.get("loop",true)))
		var pos: Array = row.positions[frame]
		result.append({"frame":frame,"position":Vector2(pos[0],pos[1]),"texture":row.texture,"cell":Vector2(row.cell[0],row.cell[1])})
	return result

func prepare(map: Dictionary) -> void:
	textures.clear()
	if not bool(map.get("scenery_enabled",false)):return
	for row in map.get("scenery",[]):
		textures[row.texture] = load(str(row.texture))

func draw(view: Node2D,map: Dictionary,region: Rect2,age: float) -> void:
	if not bool(map.get("scenery_enabled",false)):return
	var scale := Vector2(1280,800)/region.size
	for row in sample(map,age):
		var texture: Texture2D = textures.get(row.texture)
		if texture==null:continue
		var target := Rect2((Vector2(row.position)-region.position)*scale,Vector2(row.cell)*scale)
		view.draw_texture_rect_region(texture,target,Rect2(Vector2(row.frame*row.cell.x,0),row.cell))
