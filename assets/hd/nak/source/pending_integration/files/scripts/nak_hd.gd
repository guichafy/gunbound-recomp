extends RefCounted
## Constant Nak anatomy and separate fixed-register effects. Presentation only.
## Identity: original tank3/bullet3/flame3. Registration: catalog.json.
const CATALOG := "res://assets/hd/nak/catalog.json"
var groups: Dictionary = {}
var catalog_valid := false

func _init() -> void:
	if not FileAccess.file_exists(CATALOG):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	if not data is Dictionary or data.get("version",0) != 1:
		return
	var registration: Dictionary = data.get("registration",{})
	if registration.get("native_pivot",[]) != [37,50] or registration.get("native_contact_y",0) != 53 or registration.get("native_hull_width",0) != 51 or registration.get("native_body_at_support",[]) != [-4,-22]:
		return
	for group in ["masters","effects"]:
		var spec: Dictionary = data.get(group,{})
		var path: String = spec.get("path","")
		if not ResourceLoader.exists(path):
			return
		var texture: Texture2D = load(path)
		var size: Array = spec.get("size",[])
		if size.size() != 2 or texture.get_size() != Vector2(size[0],size[1]):
			return
		var paint := CanvasTexture.new()
		paint.diffuse_texture = texture
		paint.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var sprites: Dictionary = {}
		for key in spec.get("sprites",{}):
			var item: Dictionary = spec.sprites[key]
			var r: Array = item.get("region",[])
			if r.size() != 4:
				return
			var region := Rect2(r[0],r[1],r[2],r[3])
			if not region.has_area() or not Rect2(Vector2.ZERO,texture.get_size()).encloses(region):
				return
			var entry := {"source":region}
			var native: Array = item.get("native_rect",[])
			if group == "masters" or str(key).begins_with("impact_"):
				if native.size() != 4 or native[2] <= 0 or native[3] <= 0:
					return
				entry.native = Rect2(native[0],native[1],native[2],native[3])
			sprites[key] = entry
		groups[group] = {"texture":texture,"paint":paint,"sprites":sprites}
	for key in ["mobile","s1","s2","ss"]:
		if not groups.masters.sprites.has(key):
			return
	for row in range(3):
		for column in range(3):
			if not groups.effects.sprites.has("impact_%d_%d" % [row,column]):
				return
	for key in ["bubble","light_s1","light_s2"]:
		if not groups.effects.sprites.has(key):
			return
	catalog_valid = true

func available() -> bool:
	return catalog_valid and groups.size() == 2 and groups.masters.texture != null and groups.effects.texture != null

static func fit(source: Rect2, native: Rect2, bottom: bool = false) -> Rect2:
	var fitted := source.size * minf(native.size.x/source.size.x,native.size.y/source.size.y)
	return Rect2(Vector2(native.get_center().x-fitted.x*0.5,native.end.y-fitted.y) if bottom else native.get_center()-fitted*0.5,fitted)

func target(key: String) -> Rect2:
	var part: Dictionary = groups.masters.sprites[key]
	return fit(part.source,part.native,key == "mobile")

func draw_mobile(rig, view: Node2D, pos: Vector2, width: float, facing: int, rotation: float, pose: String, age: float, weapon: int, low_health: bool, color: Color, _wheel_phase: float, context: Dictionary) -> bool:
	if not available():
		return false
	var state: Dictionary = context.get("rig_state",{})
	if state.is_empty():
		state = rig.sample(pose,age,weapon,float(context.get("age",age)))
	var scale := width/60.0
	var ground := 24.0 if width<150.0 else width*0.23
	var support := Transform2D(rotation,pos)*Transform2D(Vector2(-facing*scale,0),Vector2(0,scale),Vector2(0,ground))
	var body := support*Transform2D(state.body_angle,state.body_offset)
	var tint := Color(color,color.a*state.alpha)
	if low_health:
		tint *= Color(0.7,0.7,0.7)
	var equipment: Dictionary = context.get("equipment",rig.avatars.catalog.defaults(0))
	# Body origin is the native RiderPivot + RIDER_ADJUST, never a silhouette center.
	if not rig.avatars.draw(view,equipment,support*rig.avatar_transform(state),float(context.get("age",age)),tint):
		return false
	view.draw_set_transform_matrix(body)
	var part: Dictionary = groups.masters.sprites.mobile
	var rect := target("mobile")
	view.draw_texture_rect_region(groups.masters.paint,Rect2(rect.position*60.0/51.0,rect.size*60.0/51.0),part.source,tint)
	# The native bubble repeats in the last second of the six-second idle cycle.
	if pose == "idle" and not low_health:
		var cycle := fposmod(age,6.0)
		if cycle >= 5.0:
			var size := 8.0*sin((cycle-5.0)*PI)
			var bubble: Dictionary = groups.effects.sprites.bubble
			var anchor := Vector2(-26,-18)*60.0/51.0
			view.draw_texture_rect_region(groups.effects.paint,fit(bubble.source,Rect2(anchor-Vector2.ONE*size,Vector2.ONE*size*2.0)),bubble.source,tint)
	if state.glow > 0.001:
		var glow: Dictionary = groups.effects.sprites.light_s1
		var center := Vector2(24,-29)*60.0/51.0
		view.draw_texture_rect_region(groups.effects.paint,Rect2(center-Vector2.ONE*8,Vector2.ONE*16),glow.source,Color(1,0.75,0.5,state.glow*tint.a*0.6))
	if state.flash > 0.001:
		view.draw_circle(Vector2(24,-29)*60.0/51.0,5*state.flash,Color(1,0.9,0.7,tint.a*state.flash))
	view.draw_set_transform(Vector2.ZERO)
	return true

func projectile_sample(projectile: Dictionary, weapon: int) -> Dictionary:
	var key: String = ["s1","s2","ss"][clampi(weapon,0,2)]
	# Preserve bullet3pl's asymmetric hotspot near its front, not the alpha center.
	return {"key":key,"position":Vector2(projectile.get("hit_pos",projectile.pos)),"rect":target(key),
		"flip":-1.0 if weapon==2 and Vector2(projectile.velocity).x<0.0 else 1.0,
		"pulse":0.7+0.15*sin(float(projectile.age)*TAU*6.0),"underground":bool(projectile.get("underground",false))}

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2) -> bool:
	if not available():
		return false
	if not projectile.get("launched",true):
		return true
	var state := projectile_sample(projectile,weapon)
	var part: Dictionary = groups.masters.sprites[state.key]
	view.draw_set_transform(state.position+offset,0.0,Vector2(state.flip,1))
	if weapon<2:
		var light: Dictionary = groups.effects.sprites["light_s1" if weapon==0 else "light_s2"]
		var radius := 11.0 if weapon==0 else 17.0
		view.draw_texture_rect_region(groups.effects.paint,fit(light.source,Rect2(-Vector2.ONE*radius,Vector2.ONE*radius*2)),light.source,Color(1,1,1,state.pulse))
	view.draw_texture_rect_region(groups.masters.paint,state.rect,part.source)
	view.draw_set_transform(Vector2.ZERO)
	return true

static func impact_sample(age: float, duration: float) -> Dictionary:
	var progress := clampf(age/maxf(duration,0.0001),0.0,1.0)
	var phase := progress*2.0
	return {"first":mini(2,int(phase)),"second":mini(2,int(phase)+1),"blend":phase-floor(phase),"alpha":1.0-smoothstep(0.65,1.0,progress)}

func draw_effect(view: Node2D, effect: Dictionary, offset: Vector2, _size: Vector2, duration: float) -> bool:
	if not available():
		return false
	if float(effect.age)>=duration:
		return true
	var state := impact_sample(float(effect.age),duration)
	view.draw_set_transform(Vector2(effect.pos)+offset)
	for entry in [[state.first,1.0-state.blend],[state.second,state.blend]]:
		if entry[1]<=0.0:
			continue
		var part: Dictionary = groups.effects.sprites["impact_%d_%d" % [int(effect.weapon),entry[0]]]
		view.draw_texture_rect_region(groups.effects.paint,fit(part.source,part.native),part.source,Color(1,1,1,state.alpha*entry[1]))
	view.draw_set_transform(Vector2.ZERO)
	return true
