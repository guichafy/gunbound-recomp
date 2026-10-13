extends SceneTree

const Match = preload("res://scripts/match.gd")
const Combat = preload("res://scripts/combat.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	var model = Match.new()
	model.start(2, 1, 7, "")
	var mage: Dictionary = model.actors[1]
	mage.shield = 100
	model.begin_turn()
	check(int(mage.shield) == 120, "Mage shield regenerates on the opponent's turn too")
	check(Combat.box_gap(Combat.box_center(mage), mage) == 0.0, "A point inside the Mage box has no gap")
	check(Combat.box_gap(Combat.box_center(mage) + Vector2(80, 0), mage) > 25.0, "Far hits miss the Mage box")
	check(Combat.blast_damage(25.0, 90.0, 25.0) == 90, "Inverse damage equals the base at the radius")
	check(Combat.blast_damage(10.0, 90.0, 25.0) == 225, "Inverse damage grows closer to the center")
	var before := int(model.actors[0].hp)
	model.wind = Vector2.ZERO
	model.actors[0].pos.y -= 180.0
	model.settle_actors()
	check(int(model.actors[0].hp) == before, "A short fall does not chip health")
	var parked := float(model.actors[0].pos.x)
	model.actors[0].pos.y -= 30.0
	model.wind = Vector2(90, 0)
	model.settle_actors()
	check(float(model.actors[0].pos.x) > parked, "Wind pushes a falling mobile sideways")
	model.start(2, 1, 8)
	model.actors[0].turn_item = "teleport"
	check(is_equal_approx(float(model.shot_shells(0, 40, 50, 0)[0].spawn_at), 0.4), "Bigfoot beacon waits 0.4 s")
	model.actors[1].turn_item = "teleport"
	check(is_equal_approx(float(model.shot_shells(1, 40, 50, 0)[0].spawn_at), 0.0), "Mage beacon leaves immediately")
	model.start(1, 1, 9)
	check(model.can_use_special(0) and model.fire(40.0, 50.0, 2), "SS can be fired on the first turn")
	check(int(model.actors[0].ss_lock) == 4, "SS lock becomes 4 when fired")
	model.phase = "aim"
	for _step in 3:
		model.begin_turn()
		check(not model.can_use_special(0), "SS stays locked while the counter is positive")
	model.begin_turn()
	check(model.can_use_special(0), "SS opens again on the fourth own turn")
	var mage_frames = load("res://scripts/mage_sprite.gd").new()
	var bigfoot_frames = load("res://scripts/bigfoot_sprite.gd").new()
	check(mage_frames.frame_index("hurt_2", 0, 0, false) == 366, "Mage second damage frame")
	check(mage_frames.frame_index("shock", 0, 0, false) == 120, "Mage shock frame")
	check(mage_frames.frame_index("falling", 0, 0, false) == 160, "Mage falling frame")
	check(mage_frames.frame_index("unable", 0, 0, false) == 80, "Mage unable-to-move frame")
	check(bigfoot_frames.frame_index("hurt_2", 0, 0, false) == 419, "Bigfoot second damage frame")
	check(bigfoot_frames.frame_index("shock", 0, 0, false) == 147, "Bigfoot shock frame")
	check(bigfoot_frames.frame_index("falling", 0, 0, false) == 187, "Bigfoot falling frame")
	check(bigfoot_frames.frame_index("unable", 0, 0, false) == 105, "Bigfoot unable-to-move frame")
	check(bool(load("res://scripts/mobiles.gd").definition(2).smoke) and not bool(load("res://scripts/mobiles.gd").definition(1).smoke), "Only Bigfoot smokes at low health")
	print("MOBILE PARITY CHECKS: ", checks, " | FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
