extends "res://tests/support/suite.gd"
## REQ-19/27/28: native rank2 alongside world and queue names (issue43).
const Ranks = preload("res://scripts/classic_ranks.gd")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new("res://.tools/battle-rank/test-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted = true
	scene.profile.nickname = "ABCDEFGHIJKLMNOPQRST"
	scene.profile.rank = -4
	scene.opening = 0
	scene.start_match()
	var state: Dictionary = scene.hud_state()
	check(state.get("actor_ranks",[]) == [-4,19], "Battle receives assigned player rank and CPUChick, independently of XP")
	check(scene.hud.has_method("nameplate_layout"), "World nameplate has the native rank2 layout")
	check(scene.hud.has_method("delayboard_layout"), "Queue reserves space for native rank2 before names")
	if scene.hud.has_method("nameplate_layout") and scene.hud.has_method("delayboard_layout"):
		for at in [Vector2(200,300),Vector2(950,260),Vector2(-15,600)]:
			var layout: Dictionary = scene.hud.nameplate_layout(at)
			check(layout.rank == Rect2(at+Vector2(-40,45),Vector2(25,15)), "4635be: rank2 at box+(1,7), no scaling in world")
			check(layout.baseline == at+Vector2(-14,59), "4635f5: name starts one pixel after rank, preserved13px font baseline")
		for order in [[0,1],[1,0]]:
			state.queue = [{"actor":order[0],"delay":120},{"actor":order[1],"delay":900}]
			var layout: Dictionary = scene.hud.delayboard_layout(state)
			check(layout.names[order.find(0)] == "ABCDEFGHIJKLMNOPQRST", "Queue keeps entire20character name in either order")
			check(layout.ranks[order.find(0)] == -4 and layout.ranks[order.find(1)] ==19, "Ranks follow actor identity, not row order")
			check(layout.nick_x ==47.0 and layout.rank_x==19.0, "409535..40959b: rank19, name47 in native screen pixels")
			var width: float = scene.hud.font.get_string_size(state.player_name,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x/1.6
			check(layout.delay_right-layout.delay_width >=47+width+4, "Long name has a gap before delay digits")
		for code in range(-4,21):
			var icon: AtlasTexture = scene.hud.rank_icon(code)
			check(icon.region == Rect2((code+4)*25,0,25,15), "Horizontal native frame for signed rank%d" % code)
			check(icon == scene.hud.rank_icon(code), "Rank resource retained across redraws%d" % code)
		check(scene.hud.rank_icon(999) == scene.hud.rank_icon(Ranks.CHICK), "Invalid presentation code uses existing Chick normalization")
		var xp_before: int = scene.profile.xp
		scene.profile.xp = 999999
		check(scene.hud_state().actor_ranks == [-4,19], "XP does not assign a battle rank")
		scene.profile.xp = xp_before
		for code in [Ranks.GM,0,Ranks.CHICK]:
			scene.profile.rank = code
			check(scene.hud_state().actor_ranks == [code,19], "Battle respects profile rank%d" % code)
	var playbacks := audio_playbacks(scene.sound)
	scene.queue_free()
	await process_frame
	await await_audio_release(playbacks)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.tools/battle-rank/test-profile.json"))
	finish("BATTLE RANK CHECKS")
