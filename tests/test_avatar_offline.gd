extends "res://tests/support/suite.gd"
## Expectations fixed from the Ghidra/XFS audit, not catalog eligibility helpers.
const PATH := "res://.tools/avatar-offline-test.json"
const BAD := "res://.tools/no-offline-save-directory/profile.json"
const Profile = preload("res://scripts/profile.gd")
const Model = preload("res://scripts/avatar_shop_model.gd")
func run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var expected: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/offline_avatar_keys.json"))
	var p = Profile.new(PATH)
	var before: Dictionary = p.snapshot()
	check(p.has_method("grant_offline_avatars"),"Offline grant exists")
	if p.has_method("grant_offline_avatars"):
		check(p.grant_offline_avatars(),"New profile receives grant")
		check(p.owned.size()==74,"Exactly 67 additions to seven defaults")
		for key in expected:
			check(p.owns(key),"Audited native piece granted: "+str(key))
		check(p.gold==before.shop.gold and p.cash==before.shop.cash and p.equipped_set()==before.shop.equipped["0"],"Grant changes neither wallet nor equipment")
		var saved := FileAccess.get_file_as_string(PATH)
		check(p.grant_offline_avatars() and FileAccess.get_file_as_string(PATH)==saved,"Grant is idempotent without rewriting save")
		var q = Profile.new(PATH)
		q.load_profile()
		check(q.owned==p.owned,"All granted pieces survive reload")
		p = Profile.new(PATH)
		p.gold=4321
		p.cash=765
		p.xp=812
		p.matches=7
		p.wins=2
		p.owned.append("xfs:0:0:1")
		check(p.equip("xfs:0:0:1"),"Existing save has purchased outfit")
		q = Profile.new(PATH)
		q.load_profile()
		check(q.grant_offline_avatars() and q.owned.size()==75 and q.gold==4321 and q.cash==765 and q.xp==812 and q.matches==7 and q.wins==2 and q.equipped_set()["0"]=="xfs:0:0:1","Existing profile receives only the missing pieces")
		var failed = Profile.new(BAD)
		var snapshot: Dictionary = failed.snapshot()
		check(not failed.grant_offline_avatars() and failed.snapshot()==snapshot,"Failed grant rolls back ownership and wallet")
		var corrupt_path := "res://.tools/avatar-offline-corrupt.json"
		var file := FileAccess.open(corrupt_path,FileAccess.WRITE)
		file.store_string("invalid profile JSON")
		file.close()
		var corrupt = Profile.new(corrupt_path)
		corrupt.load_profile()
		check(not corrupt.grant_offline_avatars() and FileAccess.get_file_as_string(corrupt_path)=="invalid profile JSON" and corrupt.owned.size()==7,"Automatic grant never overwrites an unreadable existing profile")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(corrupt_path))
		for key in ["xfs:0:1:61","xfs:2:3:84","xfs:2:3:163"]:
			check(not q.owns(key),"Source art gap remains excluded: "+key)
		p.load_profile()
	check_mixed_store(p)
	await check_scene()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	finish("OFFLINE AVATAR CHECKS")

func check_mixed_store(p) -> void:
	var shop = Model.new(p)
	var seen := {}
	for category in range(4):
		shop.filter(category,"",false)
		var count := 0
		var other_gender := false
		for page in range(shop.last_page):
			for item in shop.filter(category,"",false,page):
				check(not seen.has(item.key),"No duplicate mixed-store piece: "+str(item.key))
				seen[item.key]=true
				if int(item.gender)==1: other_gender=true
				check(not other_gender or int(item.gender)!=0,"Current gender precedes the other gender")
				count+=1
		check(count==[156,151,72,167][category],"Full mixed category including offline pieces: "+str(category))
	check(seen.size()==546,"All 479 sale pieces and 67 offline pieces appear once")
	p.gender=1
	check(shop.filter(0,"",false)[0].gender==1,"Female pilot sees female cards first in the same mixed collection")
	p.gender=0
	var old: Dictionary = p.snapshot()
	check(shop.select("xfs:1:0:1") and p.snapshot()==old,"Selecting other-gender card does not alter profile")
	check(shop.try_selected() and shop.preview["0"]=="xfs:1:0:1" and shop.preview["1"]=="xfs:1:1:0" and p.snapshot()==old,"Unowned Try builds a compatible temporary outfit")
	shop.reset_preview()
	check(shop.preview==p.equipped_set(),"Laundry restores saved outfit")
	p.cash=2000
	var gear: Dictionary = p.equipped_set()
	check(shop.confirm_buy("xfs:1:0:1","cash")=="ok" and p.gender==0 and p.cash==1000 and p.equipped_set()==gear,"Purchase of other-gender item does not switch saved pilot")
	check(shop.select("xfs:1:0:77") and shop.try_selected() and p.gender==1 and p.equipped_set()["0"]=="xfs:1:0:77" and shop.preview["1"]=="xfs:1:1:0","Owned Skeleton head dresses the other gender atomically")
	var female: Dictionary = p.snapshot()
	var preview: Dictionary = shop.preview.duplicate(true)
	p.path=BAD
	check(shop.select("xfs:0:0:73") and not shop.try_selected() and p.snapshot()==female and shop.preview==preview,"Failed cross-gender dress preserves profile and preview")
	p.path=PATH
	shop.reset_preview()

func check_scene() -> void:
	const SCENE_PATH := "res://.tools/avatar-offline-scene.json"
	for path in [SCENE_PATH,SCENE_PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.profile=Profile.new(SCENE_PATH)
	root.size=Vector2i(1280,800)
	root.add_child(scene)
	scene.set_process(false)
	scene.sound.muted=true
	scene.show_shop()
	await process_frame
	var view=scene.shop
	var p=scene.profile
	check(p.owns("xfs:1:0:77") and p.owns("xfs:0:0:73"),"App startup grants both genders")
	check(view.inventory_count()==74,"Inventory exposes both genders and shared pieces once")
	check(view.model.select("xfs:1:0:77"),"Other-gender Skeleton is selectable")
	view.refresh(0,17)
	# Selection is cleared on page changes; select again on its actual page.
	for page in range(view.model.last_page):
		view.refresh(0,page)
		var found := false
		for card in view.cards.get_children():
			if card.item.key=="xfs:1:0:77":
				card.pressed.emit()
				found = true
				break
		if found:
			break
	view.try_selected()
	check(p.gender==1 and p.equipped_set()["0"]=="xfs:1:0:77" and view.gender_button.text.contains("Feminino"),"Try updates saved gender, outfit and selector caption")
	check(view.model.selected_key=="xfs:1:0:77" and view.try_state=="Vestido","Dressed card stays visible and selected after gender order changes")
	check(view.buy_button.disabled,"Granted item cannot be bought or charged")
	view.equip_inventory("xfs:1:1:74")
	check(p.equipped_set()["1"]=="xfs:1:1:74","Granted body can be dressed from inventory")
	view.equip_inventory("xfs:0:0:73")
	check(p.gender==0 and p.equipped_set()["0"]=="xfs:0:0:73","Mixed inventory can switch to the other saved outfit")
	view.equip_inventory("xfs:1:0:77")
	check(p.gender==1 and p.equipped_set()["1"]=="xfs:1:1:74","Returning to female outfit retains its dressed Skeleton body")
	scene.leave_shop()
	scene.show_menu()
	scene.opening=0
	scene.start_match()
	check(scene.actor_avatars[0]["0"]=="xfs:1:0:77" and scene.actor_avatars[0]["1"]=="xfs:1:1:74","Offline outfit reaches the battle presentation")
	var restored=Profile.new(SCENE_PATH)
	restored.load_profile()
	check(restored.gender==1 and restored.equipped_set()==p.equipped_set(),"Scene dressing survives reload")
	scene.queue_free()
	await process_frame
	for path in [SCENE_PATH,SCENE_PATH.get_basename()+"-options.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
