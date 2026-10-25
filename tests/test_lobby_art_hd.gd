extends "res://tests/support/suite.gd"
const Chrome = preload("res://scripts/classic_chrome.gd")
const Art = preload("res://scripts/classic_lobby_art.gd")
const Ranks = preload("res://scripts/classic_ranks.gd")
const HD := "res://assets/hd/classic/lobby_smooth_4x/"

func run() -> void:
	var chrome = Chrome.new()
	for key in ["lobby_back", "lobby_chat", "lobby_channel", "lobby_buddy_fill"]:
		var record: Dictionary = chrome.manifest.images[key]
		var texture: Texture2D = chrome.image(key)
		check(texture.resource_path == HD + record.file, key + " selects conservative4x")
		check(texture.get_size() == Vector2(record.size[0], record.size[1]) * 4, key + " has true4x pixels")
		var control: TextureRect = chrome.place(root, key, Vector2(23, 287))
		check(control.size == Vector2(record.size[0], record.size[1]) and control.position == Vector2(23,287), key + " preserves logical rectangle")
		control.free()
	for horizontal in [false, true]:
		var cell := Vector2(25,15) if horizontal else Vector2(15,25)
		for code in range(-4,21):
			var icon: AtlasTexture = Ranks.icon(code, horizontal)
			check(icon.atlas.resource_path.begins_with(HD) and icon.region == Rect2(Vector2((code+4)*cell.x,0)*4,cell*4), "Rank%d horizontal%s keeps code+4 in4x atlas" % [code,horizontal])
	check(chrome.image("room_back").resource_path == "res://assets/classic/room/back.png", "Room backdrop remains native")
	for info in chrome.lobby_art.catalog.assets.values():
		var imported: Image = load(HD + str(info.file)).get_image()
		var png := Image.load_from_file(HD + str(info.file))
		imported.convert(Image.FORMAT_RGBA8)
		png.convert(Image.FORMAT_RGBA8)
		imported.premultiply_alpha()
		png.premultiply_alpha()
		check(imported.get_data() == png.get_data(), str(info.file) + " imports without visible loss")
	test_fallback(chrome)
	finish("LOBBY ART HD CHECKS")

func test_fallback(chrome) -> void:
	var art = chrome.lobby_art
	var baseline: Dictionary = art.catalog.duplicate(true)
	for damaged in [{}, {"version":1,"scale":3,"assets":baseline.assets}, {"version":1,"scale":4,"assets":[]}]:
		art.catalog = damaged
		check(chrome.image("lobby_chat").resource_path == "res://assets/classic/lobby/chat.png", "Invalid catalog uses native artwork")
		var control: TextureRect = chrome.place(root,"lobby_chat",Vector2(23,287))
		check(control.size == Vector2(549,259), "Fallback preserves original geometry")
		control.free()
	for field in ["file","source","size","columns","rows"]:
		art.catalog = baseline.duplicate(true)
		art.catalog.assets.lobby_chat[field] = null
		check(chrome.image("lobby_chat").resource_path == "res://assets/classic/lobby/chat.png", "Invalid " + field + " falls back")
		check(chrome.image("lobby_channel").resource_path == HD + "lobby/channel.png", "One invalid record preserves valid neighbors")
	art.catalog = baseline.duplicate(true)
	art.catalog.assets.erase("lobby_back")
	check(chrome.image("lobby_back").resource_path == "res://assets/classic/lobby/back.png", "Absent image record falls back")
	# Same-size metadata cannot make a missing or wrong-size imported file valid.
	var record: Dictionary = baseline.assets.lobby_back.source.record.duplicate(true)
	art.catalog = baseline.duplicate(true)
	record.file = "missing.png"
	art.catalog.assets.lobby_back.file = record.file
	art.catalog.assets.lobby_back.source.file = "assets/classic/" + record.file
	art.catalog.assets.lobby_back.source.record = record
	check(art.texture("lobby_back",record) == null, "Absent HD resource is rejected")
	art.catalog = baseline
	art._cache[HD + "lobby/back.png"] = load("res://assets/classic/lobby/back.png")
	check(chrome.image("lobby_back").resource_path == "res://assets/classic/lobby/back.png", "Wrong-size imported sheet falls back")
	art._cache.clear()
	check(chrome.image("lobby_back").resource_path == HD + "lobby/back.png", "Valid resource recovers")
	for horizontal in [false,true]:
		var cell := Vector2(25,15) if horizontal else Vector2(15,25)
		var key := "rank2" if horizontal else "rank1"
		record = baseline.assets[key].source.record
		art.catalog = baseline.duplicate(true)
		art.catalog.assets[key].columns = 24
		check(art.texture(key,record) == null, "Incomplete rank atlas rejected")
		var icon := Ranks.icon(20,horizontal,false)
		check(icon.region == Rect2(Vector2(24 * cell.x,0),cell) and icon.atlas.resource_path == "res://assets/classic/ranks/" + key + ".png", "Native GM fallback keeps code20/frame24")
	art.catalog = baseline
