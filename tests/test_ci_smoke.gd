extends "res://tests/support/suite.gd"

func run() -> void:
	var smoke = load("res://scripts/ci/smoke.gd").new()
	check(smoke.has_method("prepare"), "runtime smoke supplies prepare before Game._ready")
	if smoke.has_method("validate_arguments"):
		check(not smoke.validate_arguments(PackedStringArray()).ok, "missing arguments rejected")
		check(not smoke.validate_arguments(PackedStringArray(["--ci-version", "0.20.5", "--ci-profile", "user://profile.json"])).ok, "real user profile rejected")
		check(not smoke.validate_arguments(PackedStringArray(["--ci-version", "0.20.5", "--ci-profile", OS.get_user_data_dir().path_join("profile.json")])).ok, "absolute real user profile rejected")
		var temporary := OS.get_cache_dir().path_join("gunbound-package-contract/ci-profile.json")
		var parsed: Dictionary = smoke.validate_arguments(PackedStringArray(["--ci-version", "0.20.5", "--ci-profile", temporary]))
		check(parsed.ok and parsed.profile == temporary, "isolated profile request accepted")
		var scene = load("res://scenes/main.tscn").instantiate()
		check(scene.profile == null, "scene has no profile before ready")
		check(not smoke.prepare(scene, PackedStringArray()) and scene.profile == null, "invalid smoke cannot create a real profile")
		# Use a fresh smoke after the deliberate failure above.
		smoke.free()
		smoke = load("res://scripts/ci/smoke.gd").new()
		var version: String = ProjectSettings.get_setting("application/config/version", "")
		check(smoke.prepare(scene, PackedStringArray(["--ci-version", version, "--ci-profile", temporary])), "prepare injects isolated profile before ready")
		check(scene.profile.path == temporary and scene.options.path == temporary + "-options.json", "profile and options are both isolated")
		scene.free()
	else:
		check(false, "runtime smoke supplies argument validation")
	smoke.free()
	finish("CI SMOKE CHECKS")
