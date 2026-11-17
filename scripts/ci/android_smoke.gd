extends "res://scripts/ci/smoke.gd"
## Opt-in diagnostic APK only. Never accepts a caller-provided profile path.

func is_enabled() -> bool:
	return OS.has_feature("android") and OS.has_feature("android_ci")

func parse_request(arguments: PackedStringArray, enabled: bool, version: String) -> Dictionary:
	var rejected := {"ok": false}
	if not enabled:
		return rejected
	var values := {}
	var index := 0
	while index < arguments.size():
		var key := arguments[index]
		if key == "--ci-smoke":
			if values.has(key):
				return rejected
			values[key] = true
			index += 1
		elif key in ["--ci-version", "--ci-run"]:
			if values.has(key) or index + 1 >= arguments.size():
				return rejected
			values[key] = arguments[index + 1]
			index += 2
		else:
			return rejected
	if not values.has("--ci-smoke") or values.get("--ci-version", "") != version:
		return rejected
	var token: String = values.get("--ci-run", "")
	if token.length() != 32 or not token.is_valid_hex_number(false):
		return rejected
	return {"ok": true, "version": version, "token": token,
		"profile": "user://ci/gunbound-package-" + token + "/ci-profile.json"}

func validate_arguments(arguments: PackedStringArray) -> Dictionary:
	return parse_request(arguments, is_enabled(), str(ProjectSettings.get_setting("application/config/version", "")))

func prepare(target, arguments: PackedStringArray = OS.get_cmdline_user_args()) -> bool:
	requested = validate_arguments(arguments)
	if not requested.ok:
		return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(requested.profile.get_base_dir())) != OK:
		return false
	view = target
	view.profile = load("res://scripts/profile.gd").new(requested.profile)
	view.options = load("res://scripts/options.gd").new(requested.profile + "-options.json")
	return true

func finish_report() -> void:
	var report := {"schema": 1, "token": requested.get("token", ""),
		"version": requested.get("version", ""), "cases": cases,
		"failures": failures, "profile_isolated": str(requested.get("profile", "")).begins_with("user://ci/gunbound-package-")}
	print("ANDROID DIAGNOSTIC JSON: ", JSON.stringify(report))
	print("ANDROID DIAGNOSTIC: ", "PASS" if failures == 0 else "FAIL")

func run() -> void:
	await preload("res://scripts/ci/android_performance.gd").run(view)
	await super.run()
