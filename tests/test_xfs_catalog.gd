extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var catalog=load("res://scripts/avatar_catalog.gd").new()
	var rows: Array=catalog.entries.values().filter(func(row): return row.get("source")=="xfs")
	check(rows.size()==562,"All 562 real XFS records are loaded")
	check(rows.filter(func(row): return row.buyable).size()==479,"All 479 buyable records are available")
	check(catalog.items(0,0).size()==77 and catalog.items(1,0).size()==81,"Both original head catalogs are complete")
	check(catalog.items(1,3).size()==174,"All flags are shared between genders")
	var marine: Dictionary=catalog.find("xfs:0:0:1")
	check(not marine.is_empty(),"XFS IDs have a separate namespace")
	if not marine.is_empty():
		check(marine.gold_price==10000 and marine.cash_price==1000,"Native prices, not old 100/100 placeholders")
		check(marine.bonuses==[0,0,3,0,0,0,0,3],"Marine defense/popularity match DAT")
		check(catalog.find("xfs:1:1:5").bonuses[4]==-3,"Negative native modifiers remain signed")
		check(catalog.find("xfs:0:2:1").name=="Battle Goggle","Old Pilot Goggles ID does not rename Battle Goggle")
		check(catalog.find("xfs:2:3:132").art_available,"Ghost supports its effect-only artwork")
		for row in rows:
			check(ResourceLoader.exists(row.portrait),"Registered portrait: "+row.key)
			if row.buyable:
				check(row.art_available and not row.layers.is_empty(),"Purchasable item has real art: "+row.key)
		var art=load("res://scripts/avatar_art.gd").new(false)
		for gender in [0,1]:
			for row in catalog.items(gender,0):
				if not row.buyable: continue
				var gear: Dictionary=catalog.defaults(gender)
				gear["0"]=row.key
				check(not art.sample(gear,0.5).is_empty(),"Renderable native outfit: "+row.key)
	var path := "res://.tools/xfs-catalog-profile.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var p=load("res://scripts/profile.gd").new(path)
	check(p.equipped_set()["0"]=="xfs:0:0:0","New profiles use native defaults")
	if not marine.is_empty():
		check(p.purchase(marine.key,"gold")=="funds","Native price respects existing balance")
		check(p.purchase(marine.key,"cash")=="ok" and p.cash==0,"Cash purchase uses the native price once")
		check(p.equip(marine.key),"Purchased XFS piece can be equipped")
		check(p.has_method("equipment_bonuses"),"Equipment has a model-level stat aggregate")
		if p.has_method("equipment_bonuses"):
			check(p.equipment_bonuses()==marine.bonuses,"Equipped totals match the purchased piece")
		var restored=load("res://scripts/profile.gd").new(path)
		restored.load_profile()
		check(restored.owns(marine.key) and restored.equipped_set()==p.equipped_set(),"XFS purchases/equipment survive reload")
		check(p.purchase("xfs:0:1:61","gold")=="invalid","Non-buyable placeholder cannot be purchased")
		p.cash=10000
		p.path="res://.tools/missing-xfs-profile/profile.json"
		var before: int=p.cash
		check(p.purchase("xfs:0:0:2","cash")=="save" and p.cash==before and not p.owns("xfs:0:0:2"),"XFS failed save rolls back currency and ownership")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("XFS CATALOG CHECKS: ",checks," | FAILURES: ",failures)
	quit(0 if failures==0 else 1)
