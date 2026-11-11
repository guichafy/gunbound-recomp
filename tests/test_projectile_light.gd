extends "res://tests/support/suite.gd"
## Expected membership/passes come from PE vtables + XFS, not the port catalog.
const Looks = preload("res://scripts/mobile_looks.gd")
const Classic = preload("res://scripts/classic_sprite.gd")
const Additive = preload("res://scripts/additive_sprite_art.gd")
var fixture: Dictionary

class PassRecorder extends RefCounted:
	var calls: Array = []
	var starts := 0
	func begin(_view):
		calls.clear()
		starts += 1
	func clear():
		calls.clear()
	func draw(_view, texture, target, source, transform, color = Color.WHITE):
		calls.append({"texture":texture,"target":target,"source":source,"transform":transform,"color":color})

class View extends Node2D:
	var sprite
	var shell: Dictionary
	var weapon := 0
	func _draw():
		sprite.begin_projectiles(self)
		sprite.draw_projectile(self,shell,weapon)

func run() -> void:
	fixture = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/projectile_light_native.json"))
	check(PackedInt32Array(fixture.render.body) == PackedInt32Array([19,5,20,6]) and PackedInt32Array(fixture.render.light) == PackedInt32Array([19,5,20,2]), "PE order: normal alpha body then SRCALPHA/ONE light")
	for kind in ["armor","bigfoot","trico","jd","asate","ice"]:
		var sprite = Classic.new()
		sprite.setup(kind)
		var pass_art = PassRecorder.new()
		sprite.light_pass = pass_art
		var view := View.new()
		view.sprite = sprite
		root.add_child(view)
		for row in fixture.consumers:
			if row.kind != kind: continue
			var weapon := int(row.weapon)
			var name := "Bullet%d.png"%(weapon+1)
			check(sprite.light_only(name) == str(row.body).is_empty(), "%s/%d light-only inventory"%[kind,weapon])
			for direction in [1,-1]:
				for age in [0.0,0.049,0.05,0.051,0.6]:
					view.shell = {"pos":Vector2(111,88),"hit_pos":Vector2(112,89),"velocity":Vector2(20*direction,-7),"age":age,"weapon":weapon,"launched":true}
					view.weapon = weapon
					view.queue_redraw()
					await process_frame
					await process_frame
					check(pass_art.starts > 0,"%s begins its per-view pass"%kind)
					var count := 0 if str(row.light).is_empty() else 1
					check(pass_art.calls.size()==count,"%s/%d emits exactly %d additive cell, age%s direction%d"%[kind,weapon,count,age,direction])
					if count==1 and pass_art.calls.size()==1:
						var light_name := name if str(row.body).is_empty() else name.replace(".png","Light.png")
						var call: Dictionary = pass_art.calls[0]
						var info: Dictionary = sprite.sheet(light_name)
						var cell: Array = sprite.cell_frame(light_name,sprite.projectile_frame(info,view.shell))
						check(call.texture==sprite._optional_cached(light_name) and call.source==cell[0] and call.target==cell[1],"original cell/pivot/density preserved")
						check(call.color==Color.WHITE and call.transform==Transform2D(Vector2(view.shell.velocity).angle(),Vector2(112,89)),"head alpha255 and original transform preserved")
					check(view.shell.age==age and view.shell.pos==Vector2(111,88),"presentation never mutates shell")
		view.free()
	for id in Looks.ids():
		for weapon in 3:
			check(Classic.has_trail(str(Looks.look(id).kind),weapon)==(id==7 and weapon==0),"trail remains Raon T1 only")
	var art = Additive.new()
	var first := Node2D.new()
	var second := Node2D.new()
	root.add_child(first)
	root.add_child(second)
	var one: RID = art.begin(first)
	var two: RID = art.begin(second)
	check(one!=two and art.canvases.size()==2,"separate additive canvases for simultaneous views")
	first.free()
	art.begin(second)
	check(art.canvases.size()==1,"destroyed view releases its private RID on next begin")
	second.free()
	art.clear()
	check(art.canvases.is_empty(),"clear prunes all destroyed views")
	finish("PROJECTILE LIGHT CHECKS")
