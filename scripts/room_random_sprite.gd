extends "res://scripts/mobile_sprite.gd"
## OpenBound Random is a room-only body with the same player avatar renderer.
## MobileFlipbook.cs:28×47, pivot14/23.5; RiderPivot.json:15/−5.
const ROOT := "res://assets/hd/classic/room_random_4x/"
const SOURCE := "res://assets/openbound/random/"
const RECORD := {"file":"CharacterSpritesheet.png","size":[336.0,47.0],"frame_size":[28.0,47.0],"frames":12.0}
var density := 1.0
var art = preload("res://scripts/classic_lobby_art.gd").new(ROOT,"assets/openbound/random/")
func _init() -> void:
	original_art = true
	configure(SOURCE.trim_suffix("/"),Vector2(28,47),Vector2(14,23.5),{"idle":[0,11,20.0,true]},60.0,45.0,"random")
	refresh_art()
func refresh_art() -> void:
	density = 1.0
	paint_texture = pixel_texture(texture)
	var hd: Texture2D = art.texture("room_random_mobile",RECORD)
	if hd!=null:
		paint_texture = pixel_texture(hd)
		density = 4.0
func frame_rect(index: int) -> Rect2:
	return Rect2(Vector2((index%12)*28,0)*density,cell*density)
