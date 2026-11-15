extends "res://tests/support/suite.gd"

func run() -> void:
	var source := load("res://scripts/ci/android_smoke.gd")
	check(source != null, "Android sandbox smoke exists")
	if source == null:
		finish("ANDROID SMOKE CHECKS")
		return
	var smoke = source.new()
	var version := str(ProjectSettings.get_setting("application/config/version"))
	var token := "0123456789abcdef0123456789abcdef"
	var valid := PackedStringArray(["--ci-smoke", "--ci-version", version, "--ci-run", token])
	var parsed: Dictionary = smoke.parse_request(valid, true, version)
	check(parsed.ok and parsed.profile == "user://ci/gunbound-package-" + token + "/ci-profile.json", "profile derived inside fixed sandbox")
	check(not smoke.parse_request(valid, false, version).ok, "distribution build rejects diagnostic mode")
	check(not smoke.parse_request(valid, true, "9.9.9").ok, "wrong version rejected")
	for invalid in ["", "../profile", "0123456789abcdef", token + "0", "G".repeat(32)]:
		var args := PackedStringArray(["--ci-smoke", "--ci-version", version, "--ci-run", invalid])
		check(not smoke.parse_request(args, true, version).ok, "bad token rejected")
	for extra in [PackedStringArray(["--ci-run", token]), PackedStringArray(["--ci-profile", "user://profile.json"]), PackedStringArray(["--unknown", "value"])]:
		var args := valid.duplicate()
		args.append_array(extra)
		check(not smoke.parse_request(args, true, version).ok, "duplicate/path/unknown option rejected")
	var scene = load("res://scenes/main.tscn").instantiate()
	check(not smoke.prepare(scene, valid) and scene.profile == null, "desktop cannot opt into Android smoke or touch default profile")
	scene.free()
	smoke.free()
	finish("ANDROID SMOKE CHECKS")
