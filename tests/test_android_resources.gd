extends "res://tests/support/suite.gd"
var Game=load("res://scripts/game.gd")
class TrackedGame extends "res://scripts/game.gd":
	var allocations: Array=[]
	func sprite_for(id: int):
		if not sprites.has(id) and Mobiles.has_id(id):allocations.append(id)
		return super.sprite_for(id)
func run() -> void:
	check(Game.get_script_method_list().any(func(method):return method.name=="initial_sprites"),"Platform-specific initial sprite loading exists")
	if not Game.get_script_method_list().any(func(method):return method.name=="initial_sprites"):
		finish("ANDROID RESOURCES CHECKS")
		return
	check(Game.initial_sprites(true).is_empty(),"Android startup does not load the 16-mobile catalog")
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.android_test=true
	scene.sprites=Game.initial_sprites(true)
	scene.profile=load("res://scripts/profile.gd").new("res://.tools/android-v1/resources-profile.json")
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.opening=0
	for id in Game.MobileLooks.ids():
		scene.vehicle=id
		scene.cpu_vehicle=1 if id!=1 else 2
		scene.start_match()
		check(scene.sprites.size()==2,"Only the battle pair remains loaded for "+str(id))
		if id not in [7,9] and scene.cpu_vehicle not in [7,9]:
			scene.draw_mines(Vector2.ZERO)
			check(scene.sprites.size()==2,"An empty mine pass cannot load Raon "+str(id))
		for index in 2:
			var actor_id: int=scene.model.actors[index].vehicle
			var body=scene.sprite_for(actor_id)
			check(body!=null,"Selected sprite exists "+str(actor_id))
			check(scene.art.motion[index].native_animation==body.native_animation,"Native pose is prepared before BattleArt.reset")
			check(scene.art.sprites.get(actor_id)==body,"Presentation uses the same selected sprite")
	var before: int=scene.sprites.size()
	check(scene.sprite_for(-1)==null and scene.sprites.size()==before,"Invalid lookup cannot allocate a sprite")
	scene.show_menu()
	scene.prepare_sprites([3,13])
	check(scene.sprites.keys().all(func(id):return id in [3,13]) and scene.sprites.size()==2,"Room selection releases old battle sprites")
	scene.queue_free()
	await process_frame
	var tracked=TrackedGame.new()
	tracked.android_test=true
	tracked.sprites={}
	tracked.profile=load("res://scripts/profile.gd").new("res://.tools/android-v1/loading-resources-profile.json")
	root.add_child(tracked)
	tracked.sound.muted=true
	tracked.set_process(false)
	tracked.opening=0
	tracked.vehicle=2
	tracked.cpu_vehicle=1
	tracked.start_match()
	tracked.show_menu()
	tracked.vehicle=13
	tracked.cpu_vehicle=8
	tracked.begin_loading()
	tracked.allocations.clear()
	for frame in 5:
		tracked._tick_loading(0.0)
		tracked.queue_redraw()
		await process_frame
		await process_frame
	check(not tracked.allocations.any(func(id):return id in [1,2]),"Loading cannot reload the previous match pair every frame")
	check(tracked.sprites.size()==2 and tracked.sprites.has(13) and tracked.sprites.has(8),"Loading retains only the new preview pair")
	tracked.queue_free()
	await process_frame
	finish("ANDROID RESOURCES CHECKS")
