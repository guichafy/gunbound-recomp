extends "res://scripts/classic_sprite.gd"
## Native source sheets/Facing. T2's only supplied sheet doubles as its
## colored fallback body: alpha keeps the creatures legible on the HD snow.
const Physics = preload("res://scripts/classic_ballistics.gd")
var glow = preload("res://scripts/additive_sprite_art.gd").new()

func begin_projectiles(view: Node2D) -> void:
	glow.begin(view)

func clear_projectiles() -> void:
	glow.clear()

func projectile_layers(projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> Array:
	if not projectile.get("launched",true) or weapon<0 or weapon>2:
		return []
	Physics.warmup()
	var velocity: Vector2i = projectile.get("fp_velocity",Physics.velocity_fp(projectile.get("velocity",Vector2.RIGHT)))
	var heading := Physics.velocity_angle(velocity)
	# 488880 publishes vertical UV reversal, not a different trajectory.
	var flip := weapon>0 and heading>90 and heading<270
	var at: Vector2 = projectile.get("hit_pos",projectile.pos)+offset
	var result: Array = []
	var body := "Bullet%d.png"%(weapon+1)
	for name in [body,body.replace(".png","Light.png")]:
		var info := sheet(name)
		if info.is_empty():
			continue
		var parts := cell_frame(name,projectile_frame(info,projectile))
		result.append({"sheet":name,"source":parts[0],"target":parts[1],
			"additive":name.ends_with("Light.png"),"flip_y":flip,
			"transform":Transform2D(-deg_to_rad(heading),Vector2(1,-1 if flip else 1),0,at)})
	return result

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> void:
	for layer in projectile_layers(projectile,weapon,offset):
		var paint := _optional_cached(layer.sheet)
		if layer.additive:
			glow.draw(view,paint,layer.target,layer.source,layer.transform)
		else:
			view.draw_set_transform_matrix(layer.transform)
			view.draw_texture_rect_region(paint,layer.target,layer.source)
	view.draw_set_transform(Vector2.ZERO)
