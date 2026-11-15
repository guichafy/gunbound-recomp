extends RefCounted
## Independent from overlay visibility; foreground does not implicitly resume.
var suspended := false
var awaiting_resume := false
var reason := ""
const BACK_GATE_MSEC := 300
var last_back_msec := -BACK_GATE_MSEC
func accept_back(now_msec: int) -> bool:
	# Godot 4.7.2 emits both Activity and raw-key Back requests. On the AVD
	# they arrived ~160 ms apart, even across frames. No gesture ID is exposed.
	if now_msec-last_back_msec<BACK_GATE_MSEC:return false
	last_back_msec=now_msec
	return true
func suspend(value: String) -> void:
	suspended=true
	awaiting_resume=true
	reason=value
func resume() -> void:
	suspended=false
func confirm_resume() -> void:
	if not suspended:
		awaiting_resume=false
		reason=""
func is_blocked() -> bool:
	return suspended or awaiting_resume
