extends RefCounted
## Read-only presentation of snapshot-owned Ion and native green/yellow ribbons.
const Timing = preload("res://scripts/classic_shot_timing.gd")
const Physics = preload("res://scripts/classic_ballistics.gd")
const BOB := [-5,-5,-5,-4,-4,-3,-2,0,2,3,4,5,5,5,4,3,2,0,-2,-3,-4,-4]
const MageArt = preload("res://scripts/mage_projectile_art.gd")
var ion: Texture2D
var laser: Texture2D
var meta: Dictionary = {}

func _init() -> void:
	ion = load("res://assets/openbound/asate/Ion.png")
	laser = load("res://assets/openbound/mage/original/LaserEffect.png")
	meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/openbound/asate/ion.json"))

func draw_satellite(view: Node2D, satellite: Dictionary, offset: Vector2, fraction: float = 1.0) -> void:
	var state := str(satellite.get("state","normal"))
	var frames: Array = meta.states.get(state,meta.states.normal)
	var durations: Array = meta.durations.get(state,[])
	var index := Timing.frame(frames,durations,float(satellite.get("state_tick",0))*0.05,state in ["normal","move"])
	var cell := Vector2(meta.cell[0],meta.cell[1])
	var origin := Vector2(meta.origin[0],meta.origin[1])
	var position := Vector2(satellite.get("previous_pos",satellite.pos)).lerp(Vector2(satellite.pos),clampf(fraction,0,1))
	if state == "normal":
		position.y += BOB[posmod(int(satellite.get("idle_tick",0)),22)]
	view.draw_set_transform(position+offset,-deg_to_rad(float(satellite.get("angle",270))))
	view.draw_texture_rect_region(ion,Rect2(-origin,cell),Rect2(Vector2(index%int(meta.columns),index/int(meta.columns))*cell,cell))
	view.draw_set_transform(Vector2.ZERO)

static func triangle_data(projectile: Dictionary, weapon: int) -> Dictionary:
	# Shared native renderer47f1c0 serializes16 sections to the same
	# LaserEffect raster as Mage. High byte0x0f stores tail length;
	# low RGB0x00ff00/0xffff00 is Ion's T1/T2 color, not Mage cyan/pink.
	var shot := projectile.duplicate(true)
	var side := Vector2.ZERO
	var velocity: Vector2i = shot.get("fp_velocity",Vector2i.ZERO)
	if velocity != Vector2i.ZERO:
		var angle := Physics.velocity_angle(velocity)+90
		side = Vector2(int(6*Physics.s(angle+90)),int(-6*Physics.s(angle)))
	if not shot.has("laser_sides") or shot.laser_sides.size() != shot.get("trail",[]).size():
		shot.laser_sides = []
		for _point in shot.get("trail",[]):
			shot.laser_sides.append(side)
	var data := MageArt.triangle_data(shot,0)
	var colors: PackedColorArray = data.colors
	for index in colors.size():
		colors[index] = Color(0.0 if weapon == 0 else 1.0,1.0,0.0,colors[index].a)
	data.colors = colors
	return data

func draw_child(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> void:
	var data := triangle_data(projectile,weapon)
	if data.points.is_empty():
		return
	view.draw_set_transform(offset)
	RenderingServer.canvas_item_add_triangle_array(view.get_canvas_item(),data.indices,data.points,data.colors,data.uv,PackedInt32Array(),PackedFloat32Array(),laser.get_rid())
	view.draw_set_transform(Vector2.ZERO)
