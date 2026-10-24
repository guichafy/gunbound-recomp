extends "res://tests/support/suite.gd"
func run() -> void:
	var sprites := [load("res://scripts/bigfoot_sprite.gd").new(),load("res://scripts/mage_sprite.gd").new()]
	for sprite in sprites:
		check(sprite.hd_rig.has_method("avatar_transform"), "Rig has body-pivot registration")
	if failures == 0:
		# C# RiderPivot idle(3,5)/(5,6), contact-pivot31/32, hull49/46.
		var centers := [Vector2(180.0/49.0,-1560.0/49.0),Vector2(300.0/46.0,-1560.0/46.0)]
		var scales := [60.0/49.0,60.0/46.0]
		for index in range(2):
			var rig = sprites[index].hd_rig
			var idle: Dictionary = rig.sample("idle",0,0)
			var transform: Transform2D = rig.avatar_transform(idle)
			check(transform.origin.is_equal_approx(centers[index]), "Body center matches native C# registration")
			check(is_equal_approx(transform.x.length(),scales[index]) and is_equal_approx(transform.y.length(),scales[index]), "Avatar uniform native scale")
			for facing in [-1,1]:
				var world := Transform2D(0,Vector2(-facing,1),0,Vector2(300,324))
				check((world*transform*Vector2.ZERO).is_equal_approx(Vector2(300-facing*centers[index].x,324+centers[index].y)), "Facing flips avatar around mobile origin")
				var slope := Transform2D(deg_to_rad(30),Vector2(300,300)) * Transform2D(0,Vector2(-facing,1),0,Vector2(0,24))
				check((slope*transform*Vector2.ZERO).is_equal_approx(Vector2(300,300)+(Vector2(-facing*centers[index].x,24+centers[index].y)).rotated(deg_to_rad(30))), "Slope rotates avatar with support")
			for pose in ["moving","charging","recoil","hurt","destroyed"]:
				var state: Dictionary = rig.sample(pose,0.3,0)
				var pose_transform: Transform2D = rig.avatar_transform(state)
				var body := Transform2D(state.body_angle,state.body_offset)
				check(pose_transform.origin.is_equal_approx(body*centers[index]), "Pose follows chassis without hip/body offset")
	finish("AVATAR MOUNT CHECKS")
