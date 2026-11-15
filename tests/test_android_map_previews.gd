extends "res://tests/support/suite.gd"
func run() -> void:
	var room = preload("res://scripts/classic_room_art.gd").new()
	check(room.get("android_mode")!=null,"Room art exposes Android-safe preview path")
	if room.get("android_mode")!=null:
		room.android_mode=true
		for index in 22:
			var frame: AtlasTexture=room.frame("room_maps",index)
			check(frame!=null and frame.region==Rect2(0,0,544,336),"Android HD frame dimensions "+str(index))
			check(frame.atlas.resource_path=="res://assets/hd/classic/android_map_previews/map_%02d.png"%index,"Android preview order "+str(index))
		check(room.art._cache.is_empty(),"Android never loads wide room HD atlas")
		room.android_previews={}
		var fallback: AtlasTexture=room.frame("room_maps",3)
		check(fallback.atlas.resource_path=="res://assets/classic/room/details/maps.png" and fallback.region==Rect2(408,0,136,84),"Missing Android catalog falls back to native only")
		check(room.art._cache.is_empty(),"Native fallback cannot load wide HD")
		room.android_previews={"schema":1,"frame_size":[544,336],"frames":[{"index":0,"file":"../../room_smooth_4x/room/details/maps.png"}]}
		fallback=room.frame("room_maps",0)
		check(fallback.atlas.resource_path=="res://assets/classic/room/details/maps.png","Malformed catalog cannot escape Android preview directory")
	report("ANDROID MAP PREVIEWS CHECKS")
	quit(exit_code())
