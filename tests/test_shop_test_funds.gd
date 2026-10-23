extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var Profile=load("res://scripts/profile.gd")
	var path:="res://.tools/shop-test-funds.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var profile=Profile.new(path)
	check(profile.gold==999999999 and profile.cash==999999999,"New default profile has the requested test wallet")
	check(profile.has_method("grant_test_funds"),"Startup can grant existing profiles test funds once")
	if profile.has_method("grant_test_funds"):
		profile.gold=750
		profile.cash=1800
		profile.xp=600
		profile.nickname="Teste salvo"
		check(profile.purchase("xfs:0:0:1","cash")=="ok" and profile.equip("xfs:0:0:1"),"Existing owned equipment fixture")
		var previous: Dictionary=profile.snapshot()
		previous.shop.erase("test_funds_granted")
		var file:=FileAccess.open(path,FileAccess.WRITE)
		file.store_string(JSON.stringify(previous))
		file.close()
		profile=Profile.new(path)
		profile.load_profile()
		check(profile.gold==750 and profile.cash==800,"Reading an old wallet preserves its saved values before the startup grant")
		check(profile.grant_test_funds() and profile.gold==999999999 and profile.cash==999999999,"Existing wallet receives exactly the requested balance once")
		check(profile.xp==600 and profile.nickname=="Teste salvo" and profile.owns("xfs:0:0:1") and profile.equipped_set()["0"]=="xfs:0:0:1","Grant preserves progress, ownership and equipment")
		check(profile.purchase("xfs:0:0:2","gold")=="ok","Test balance purchases real XFS equipment")
		var spent: Dictionary=profile.snapshot()
		profile=Profile.new(path)
		profile.load_profile()
		check(profile.grant_test_funds() and profile.snapshot()==spent,"Reload and repeated startup do not refill spent currency")
		profile.restore(previous)
		profile.path="res://.tools/missing-test-funds-directory/profile.json"
		var before: Dictionary=profile.snapshot()
		check(not profile.grant_test_funds() and profile.snapshot()==before,"Failed save rolls back funds and grant marker")
		profile.path=path
		profile.restore({"nickname":"Danificado","xp":0,"wins":0,"matches":0,"awarded":[],"shop":{"gold":"invalid","cash":20}})
		check(profile.grant_test_funds() and profile.gold==0 and profile.cash==20,"Corrupt wallets do not gain a refill through migration")
	var all=Profile.new(path)
	var bought:=0
	var dressed:=0
	for gender in [0,1]:
		check(all.set_gender(gender),"Change gender for the complete XFS catalog")
		for item in all.catalog.entries.values():
			if item.get("source")!="xfs" or not item.get("buyable",false) or not all.catalog.compatible(item.key,gender) or all.owns(item.key):continue
			var currency:="gold" if item.gold_price>0 else "cash"
			if all.purchase(item.key,currency)=="ok":bought+=1
			if all.equip(item.key):dressed+=1
	check(bought==479 and dressed==479,"Requested starting funds buy and equip all 479 available avatars across both genders")
	check(all.gold>=0 and all.cash>=0,"Full catalog remains within the requested budget")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("SHOP TEST FUNDS CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
