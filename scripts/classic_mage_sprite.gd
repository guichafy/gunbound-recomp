extends "res://scripts/classic_sprite.gd"
## Mage body/EPA/SS/impacts plus native LaserEffect T1/T2 composition.
const MageArt = preload("res://scripts/mage_projectile_art.gd")
var laser_art = MageArt.new()

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> void:
	if not projectile.get("launched",true):
		return
	if weapon == 2:
		super.draw_projectile(view,projectile,weapon,offset)
	else:
		laser_art.draw(view,projectile,weapon,offset)
