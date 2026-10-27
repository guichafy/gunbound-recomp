extends "res://scripts/aduka_sprite.gd"
## Shared original atlas/quantized heading pipeline, without Aduka's vertical
## Facing reversal. Lightning SS supplies only an additive bullet8pl layer.
func projectile_layers(projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> Array:
	var layers: Array=super.projectile_layers(projectile,weapon,offset)
	var heading:=Physics.velocity_angle(projectile.get("fp_velocity",Physics.velocity_fp(projectile.get("velocity",Vector2.RIGHT))))
	for layer in layers:
		layer.flip_y=false
		layer.additive=weapon==2 or str(layer.sheet).ends_with("Light.png")
		layer.transform=Transform2D(-deg_to_rad(heading),Vector2(projectile.get("hit_pos",projectile.pos))+offset)
	return layers

## Native AvataTexture1/2 and AvataEffectTexture1/2 render guards skip EPA
## state14(dead); CharacterTexture still draws. Dead frame header fields
## are not valid RiderPivots and must never position an equipped avatar.
static func rider_visible(pose: String) -> bool:
	return pose!="destroyed"

func draw(view: Node2D, request) -> void:
	if rider_visible(str(request.pose)):
		super.draw(view,request)
		return
	var amount: float=request.width/hull_width
	var ground: float=24.0 if request.width<150.0 else request.width*0.23
	view.draw_set_transform(request.pos,request.rotation,Vector2(-request.facing,1))
	view.draw_texture_rect_region(paint_texture,Rect2(Vector2(-pivot.x*amount,ground-contact_y*amount),cell*amount),frame_rect(request.frame),request.color)
	view.draw_set_transform(Vector2.ZERO)
