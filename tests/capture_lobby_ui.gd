extends SceneTree
## GPU QA do lobby, sempre com perfil isolado. Não executa o cliente original.
const OUT := "res://docs/lobby-rank/"
const PATH := "res://.tools/lobby-rank/capture-profile.json"
var scene

func _initialize() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + file + ".png")

func run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.profile = load("res://scripts/profile.gd").new(PATH)
	root.add_child(scene)
	scene.scale = Vector2.ONE * 1.35
	scene.position = Vector2(96, 0)
	scene.set_process(false)
	scene.sound.muted = true
	await capture("lobby-gm")
	scene.profile.nickname = "WWWWWWWWWWWWWWWWWWWW"
	scene.profile.xp = 1000000000
	scene.profile.gold = 1000000000
	scene.profile.cash = 1000000000
	scene.show_lobby()
	for i in range(80):
		scene.lobby.submit_chat("Mensagem %02d: [b]texto literal[/b] no canal local." % i)
	scene.lobby.chat_input.text = "Mensagem em edição — sem cobrir a borda"
	scene.lobby.chat_input.grab_focus()
	await process_frame
	await capture("lobby-stress")
	var report := {"size":root.size, "rank":scene.profile.rank, "history":scene.lobby.lines.size(), "controls":{}}
	for name in ["PilotName", "PilotRank", "PilotGP", "PilotGold", "PilotCash", "PilotRankIcon", "ChannelRankIcon", "LocalChatHistory", "LocalChatInput"]:
		var node = scene.root.find_child(name, true, false)
		report.controls[name] = {"position":node.position, "size":node.size, "global_rect":node.get_global_rect()}
	var file := FileAccess.open(OUT + "render.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	scene.free()
	quit()
