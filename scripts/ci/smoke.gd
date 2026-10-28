extends Node
## Release templates disable --script. Game._ready selects this runtime smoke
## only for --ci-smoke, injecting an isolated profile before any normal setup.

var failures := 0
var view
var requested: Dictionary = {}

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("PACKAGED SMOKE FAIL: ", message)

func validate_arguments(arguments: PackedStringArray) -> Dictionary:
	var version := ""
	var profile_path := ""
	for index in range(arguments.size() - 1):
		if arguments[index] == "--ci-version":
			version = arguments[index + 1]
		if arguments[index] == "--ci-profile":
			profile_path = arguments[index + 1]
	# The launcher creates this dedicated directory with tempfile. In particular,
	# an absolute path to the real user profile must never qualify as a smoke.
	var isolated := profile_path.is_absolute_path() and profile_path.get_file() == "ci-profile.json"
	isolated = isolated and profile_path.get_base_dir().get_file().begins_with("gunbound-package-")
	return {"ok": not version.is_empty() and isolated, "version": version, "profile": profile_path}

func prepare(target, arguments: PackedStringArray = OS.get_cmdline_user_args()) -> bool:
	requested = validate_arguments(arguments)
	if not requested.ok or str(ProjectSettings.get_setting("application/config/version", "")) != requested.version:
		return false
	view = target
	view.profile = load("res://scripts/profile.gd").new(requested.profile)
	view.options = load("res://scripts/options.gd").new(requested.profile + "-options.json")
	return true

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	for forbidden in ["res://override.cfg", "res://export_credentials.cfg", "res://tests/test_runner.gd", "res://.github/workflows/desktop.yml", "res://assets/xfs/reference/avatar.xfs", "res://assets/xfs/reference/mh.dat"]:
		check(not FileAccess.file_exists(forbidden) and not ResourceLoader.exists(forbidden), "unexpected private/source resource: " + forbidden)
	for path in ["res://scenes/main.tscn", "res://scripts/match.gd", "res://assets/hd/pilot_side.png"]:
		check(ResourceLoader.exists(path), "missing resource: " + path)
	for path in ["res://assets/xfs/shop/catalog.json", "res://assets/xfs/avatars/catalog.json", "res://assets/classic/manifest.json", "res://assets/xfs/result/catalog.json"]:
		check(FileAccess.file_exists(path), "missing catalog: " + path)
	if failures == 0:
		view.set_process(false)
		view.sound.muted = true
		await get_tree().process_frame
		print("PACKAGED SMOKE: lobby initialized")
		check(view.screen == "lobby", "lobby initialization failed")
		view.show_menu()
		await get_tree().process_frame
		print("PACKAGED SMOKE: room initialized")
		check(view.screen == "menu", "room initialization failed")
		view.show_shop()
		await get_tree().process_frame
		print("PACKAGED SMOKE: shop initialized")
		check(view.screen == "shop", "shop initialization failed")
		check(view.profile.path == requested.profile and view.profile.save_profile(), "temporary profile save failed")
	view.queue_free()
	await get_tree().process_frame
	print("PACKAGED SMOKE: ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
