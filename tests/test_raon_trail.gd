extends "res://tests/support/suite.gd"
## Native bullet afterimages, Raon T1 only (ADR-118/120): PublishProjectileTrackingState 0x458690
## stores x/y/angle per render; the battle render 0x4c4e93 draws levels 7..0
## with alpha 255-32k; the end of the frame shifts level k <- k-1. Render is
## at most once per 50ms GameTick, so a level is one 20Hz model tick.
const Sprite = preload("res://scripts/classic_sprite.gd")

func shell(points: int, blend: float = 1.0) -> Dictionary:
	var trail: Array = []
	for i in points:
		trail.append(Vector2(100+10*i,200-3*i))
	return {"trail":trail,"draw_fraction":blend,"velocity":Vector2(200,-60),"hit_pos":trail[-1]}

func run() -> void:
	check(Sprite.NATIVE_TRAIL_LEVELS == 8,"Native history keeps eight levels")
	var levels: Array = Sprite.trail_levels(shell(12))
	check(levels.size() == 7,"Seven afterimages are drawn behind the current bullet")
	if levels.size() == 7:
		check(int(levels[0].level) == 7 and int(levels[6].level) == 1,"Oldest level draws first (7..1)")
		for entry in levels:
			var k := int(entry.level)
			check(is_equal_approx(float(entry.alpha),float(255-32*k)/255.0),"Level%d alpha is 255-32k" % k)
		# trail[-1] is the current tick; level k is k ticks earlier.
		check(Vector2(levels[6].pos) == Vector2(100+10*10,200-3*10),"Level1 is the previous tick position")
		check(Vector2(levels[0].pos) == Vector2(100+10*4,200-3*4),"Level7 is seven ticks earlier")
		check(is_equal_approx(float(levels[6].angle),Vector2(10,-3).angle()),"Level angle follows that tick's displacement")
	var half: Array = Sprite.trail_levels(shell(12,0.5))
	check(Vector2(half[6].pos) == Vector2(100+10*9.5,200-3*9.5),"Interpolated presentation shifts every level by the same blend")
	check(Sprite.trail_levels(shell(3)).size() == 2,"A young shell only shows the levels it has published")
	check(Sprite.trail_levels(shell(1)).is_empty(),"No afterimage before the first move")
	# After the shell stops publishing, the frame-end shift keeps draining:
	# j ticks later level k shows the point published (k-j) ticks before removal.
	var history: Array = shell(12).trail
	for ticks in range(1,9):
		var left: Array = Sprite.lingering_levels(history,ticks)
		check(left.size() == maxi(0,8-ticks),"Tick%d after impact keeps %d levels" % [ticks,maxi(0,8-ticks)])
		if not left.is_empty():
			check(int(left[0].level) == 7 and int(left[-1].level) == ticks,"Drain draws levels 7..%d" % ticks)
			check(Vector2(left[-1].pos) == Vector2(history[-1]),"Newest remaining copy stays on the last published point")
			check(is_equal_approx(float(left[-1].alpha),float(255-32*ticks)/255.0),"Remaining copy keeps its level alpha")
	# ADR-120 (user decision): only the Raon T1 shows the native history.
	for kind in ["armor","trico","boomer","raon","lightning","jd","asate","ice","turtle","grub","dragon","knight","aduka","bigfoot","mage","nak"]:
		for weapon in 3:
			var wanted: bool = kind == "raon" and weapon == 0
			check(Sprite.has_trail(kind,weapon) == wanted,"%s weapon%d trail=%s" % [kind,weapon,wanted])
	finish("RAON TRAIL CHECKS")
