extends SceneTree
## Base of the headless suites (scripts/check.sh): counts checks, reports
## failures and prints the "<LABEL> CHECKS: n | FAILURES: m" line the harness reads.

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

## Subclasses implement the scenario here (it may await frames).
func run() -> void:
	pass

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func exit_code() -> int:
	return 0 if failures == 0 else 1

func report(label: String) -> void:
	print(label, ": ", checks, " | FAILURES: ", failures)

## Prints the summary and leaves with 1 on any failure.
func finish(label: String) -> void:
	report(label)
	quit(exit_code())

## Stopping a player queues release on AudioServer's mixer thread. WeakRefs
## observe that release without retaining playback resources in the test.
func audio_playbacks(sound) -> Array[WeakRef]:
	var result: Array[WeakRef] = []
	for player in sound.players + [sound.music]:
		if player != null and player.has_stream_playback():
			result.append(weakref(player.get_stream_playback()))
	return result

## Same bounded completion condition as test_client_audio; a fixed sleep can
## finish before the mixer on a loaded hosted runner. Never hide a leak log.
func await_audio_release(playbacks: Array[WeakRef]) -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while playbacks.any(func(ref: WeakRef) -> bool: return ref.get_ref() != null) and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	check(playbacks.all(func(ref: WeakRef) -> bool: return ref.get_ref() == null), "Scene teardown releases every observed audio playback")
