extends "res://tests/support/suite.gd"
class SlowGame extends "res://scripts/game.gd":
	func leave_shop() -> void:
		super.leave_shop()
		OS.delay_msec(400)
func get_tree_quit_back() -> bool:
	return quit_on_go_back
func run() -> void:
	var path := "res://scripts/platform_lifecycle.gd"
	check(ResourceLoader.exists(path),"Independent lifecycle latch exists")
	if ResourceLoader.exists(path):
		var life = load(path).new()
		check(life.accept_back(1000),"First Back is accepted")
		await process_frame
		check(not life.accept_back(1160),"Duplicate native Back is ignored across frames")
		check(life.accept_back(1300),"New Back is accepted after the 300 ms gate")
		if life.has_method("finish_back"):
			life.finish_back(2200)
			check(not life.accept_back(2201),"A duplicate queued during slow navigation is rejected after completion")
			check(life.accept_back(2500),"A new Back is accepted 300 ms after navigation completes")
		else:check(false,"Back gate must cover navigation work, not only entry time")
		check(not life.is_blocked(),"Initially running")
		life.suspend("focus")
		life.suspend("pause")
		check(life.is_blocked(),"Suspension idempotently blocks")
		life.resume()
		check(life.is_blocked(),"Resume requires explicit confirmation")
		life.confirm_resume()
		check(not life.is_blocked(),"Confirmed resume clears latch")
	var scene = SlowGame.new()
	scene.android_test=true
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/android-v1/lifecycle-profile.json")
	root.add_child(scene)
	check(not get_tree_quit_back(),"Android disables engine automatic Back quit")
	scene.show_shop()
	root.go_back_requested.emit()
	root.go_back_requested.emit()
	check(scene.screen=="lobby","Window Back signal alone leaves shop for lobby")
	check(not scene.root.get_children().any(func(child):return child is ConfirmationDialog),"Duplicate native Back callback cannot open exit confirmation")
	scene.lifecycle.last_back_msec=-1000
	root.go_back_requested.emit()
	check(scene.root.get_node_or_null("PlatformExitConfirm")!=null,"Lobby Back opens one managed exit confirmation")
	scene.lifecycle.last_back_msec=-1000
	root.go_back_requested.emit()
	await process_frame
	await process_frame
	check(not scene.root.get_children().any(func(child):return child is ConfirmationDialog),"Next accepted Back cancels exit confirmation without stacking")
	scene.lifecycle.last_back_msec=-1000
	scene.show_menu()
	root.go_back_requested.emit()
	check(scene.screen=="lobby","Window Back navigates exactly one screen")
	scene.show_lobby_settings()
	check(not scene.overlays.settings_popup.nickname_input.has_focus(),"Android Settings does not open IME until a nickname tap")
	check(scene.overlays.settings_popup.nickname_input.select_all_on_focus,"Android nickname can replace its existing value on focus")
	scene.close_overlay()
	scene.set_process(false)
	scene.sound.muted=true
	scene.opening=0
	scene.start_match()
	scene.begin_charge()
	await process_frame
	scene.lifecycle.last_back_msec=-1000
	root.go_back_requested.emit()
	root.go_back_requested.emit()
	check(scene.overlays.kind=="options" and not scene.aim.charging,"One native Back gesture pauses once and cancels charge")
	scene.close_overlay()
	scene.suspend_platform("test")
	check(not scene.aim.charging and scene.effective_paused(),"Suspend cancels charge")
	var before: float=scene.model.turn_time
	scene._process(60.0)
	check(scene.model.turn_time==before,"Background 60 seconds cannot advance turn")
	scene._on_overlay_closed()
	check(scene.effective_paused(),"Closing overlay cannot release lifecycle latch")
	scene.resume_platform()
	check(scene.effective_paused(),"Foreground still blocked")
	root.go_back_requested.emit()
	check(scene.root.get_node_or_null("PlatformResume")!=null and scene.effective_paused(),"Back cannot remove explicit resume overlay")
	scene.confirm_platform_resume()
	check(not scene.effective_paused(),"Explicit resume releases gameplay")
	scene.model.active=1
	scene.cpu.start(scene.model)
	var task: int=scene.cpu.task
	var rng_before: int=scene.model.rng.state
	scene.suspend_platform("cpu")
	scene.suspend_platform("duplicate")
	scene._process(60.0)
	scene.resume_platform()
	scene.confirm_platform_resume()
	check(scene.cpu.task==task and not scene.cpu.search.is_empty(),"CPU resumes the same pure snapshot request")
	check(scene.model.rng.state==rng_before,"Repeated suspension cannot reroll CPU RNG")
	scene.show_menu()
	scene.begin_loading()
	var loading_before: float=scene.loading_elapsed
	scene.suspend_platform("loading")
	scene._process(60.0)
	check(scene.screen=="loading" and scene.loading_elapsed==loading_before,"Background cannot start loading match")
	scene.queue_free()
	await process_frame
	report("ANDROID LIFECYCLE CHECKS")
	quit(exit_code())
