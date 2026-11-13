extends SceneTree
## Issue43: actual world/queue nameplates, both teams/order and20character name.
const OUT := "res://docs/battle-rank/"
const PROFILE := "res://.tools/battle-rank/capture-profile.json"
var view
var viewport: SubViewport

func _initialize() -> void:
	call_deferred("run")

func snap(tag: String) -> void:
	view.queue_redraw()
	view.screen_hud.queue_redraw()
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.save_png(OUT+tag+".png")
	print("CAPTURE ",tag," ",image.get_size()," ranks=",view.hud_state().actor_ranks)

## Independent native-size pixel probe: source opaque pixels must be present
## at the two known world anchors. Removing/swapping either draw must fail.
func verify_world(image: Image) -> void:
	var source: Image = load("res://assets/classic/ranks/rank2.png").get_image()
	var samples: Array = []
	for pair in [[-4,Vector2i(280,459)],[19,Vector2i(760,459)]]:
		var checked := 0
		var mismatch := 0
		for y in 15:
			for x in 25:
				var expected := source.get_pixel((pair[0]+4)*25+x,y)
				if expected.a < 1.0:
					continue
				checked += 1
				if image.get_pixel(pair[1].x+x,pair[1].y+y) != expected:
					mismatch += 1
		assert(checked>10 and mismatch==0,"World rank pixels absent/wrong at native anchor")
		samples.append({"code":pair[0],"opaque_pixels":checked,"mismatch":mismatch})
	var file := FileAccess.open(OUT+"gpu-verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"resolution":[1280,800],"world_rank_samples":samples},"\t"))
	print("WORLD RANK PIXELS ",samples)

func run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	view = load("res://scenes/main.tscn").instantiate()
	view.profile = load("res://scripts/profile.gd").new(PROFILE)
	viewport.add_child(view)
	view.scale = Vector2(1.35,1.35)
	view.position = Vector2(96,0)
	view.sound.muted = true
	view.set_process(false)
	view.opening = 0
	view.match_seed = 43
	view.weather_mode = "wind"
	view.select_vehicle(2)
	view.start_match()
	# Deterministic presentation composition on the actual Miramo terrain.
	view.rig.position = Vector2(100,800)
	view.model.actors[0].pos = Vector2(420,1150)
	view.model.actors[1].pos = Vector2(900,1150)
	view.model.actors[0].facing = 1
	view.model.actors[1].facing = -1
	view.art.reset(view.model.actors)
	view.hud.reset(view.model)
	view.profile.nickname = "Piloto"
	view.profile.rank = 20
	view.queue_entries = [{"actor":0,"delay":120},{"actor":1,"delay":400}]
	await snap("battle-rank-gm")
	view.profile.nickname = "ABCDEFGHIJKLMNOPQRST"
	view.profile.rank = -4
	view.queue_entries.reverse()
	view.model.active = 1
	await snap("battle-rank-long-cpu-first")
	viewport.size = Vector2i(1280,800)
	view.scale = Vector2.ONE
	view.position = Vector2.ZERO
	await snap("battle-rank-1280")
	verify_world(viewport.get_texture().get_image())
	view.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))
	quit()
