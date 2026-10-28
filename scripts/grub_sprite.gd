extends "res://scripts/classic_sprite.gd"
## Grub (client type 12): the "l" images of graphics.xfs are light layers. Like the
## Aduka/Lightning glows they are drawn additively on top of the alpha body:
## bullet13nl / bullet13sl over the shells and tank13l over the hull. Without it
## the halo blends as a translucent veil (the blur of the first port).
const AdditiveArt = preload("res://scripts/additive_sprite_art.gd")
var glow = AdditiveArt.new()
var hull_glow = AdditiveArt.new()
var hull_info: Dictionary = {}
var hull_light: CanvasTexture
## The hull glow belongs to the view that opened it this frame (game.gd's battle
## pass, the room figures). Any other view draws the plain body: the private
## additive canvas of a view nobody clears would pile up a glow per redraw.
var hull_view := 0

func setup(kind: String) -> void:
	super.setup(kind)
	hull_info = meta.get("hull_light", {})
	var path := asset_folder + "/CharacterSpritesheetLight.png"
	if not hull_info.is_empty() and ResourceLoader.exists(path):
		hull_light = pixel_texture(load(path))

func begin_projectiles(view: Node2D) -> void:
	glow.begin(view)

func clear_projectiles() -> void:
	glow.clear()

func begin_hull_glow(view: Node2D) -> void:
	hull_glow.begin(view)
	hull_view = view.get_instance_id()

func clear_hull_glow() -> void:
	hull_glow.clear()
	hull_view = 0

func draw(view: Node2D, request) -> void:
	super.draw(view, request)
	draw_hull_glow(view, request)

## Additive tank13l pass over the body drawn by MobileSprite.draw.
func draw_hull_glow(view: Node2D, request) -> void:
	if hull_view != view.get_instance_id() or hull_light == null:
		return
	var amount: float = request.width / hull_width
	var ground: float = 24.0 if request.width < 150.0 else request.width * 0.23
	# Same hotspot as the body rectangle of MobileSprite.draw, then the light
	# sheet's own cell and origin (tank13l frames are larger than the hull).
	var hotspot := Vector2(0.0, ground - (contact_y - pivot.y) * amount)
	var cell_light := Vector2(hull_info.cell[0], hull_info.cell[1])
	var origin_light := Vector2(hull_info.origin[0], hull_info.origin[1])
	var columns := int(hull_info.columns)
	var index := clampi(request.frame, 0, int(hull_info.frames) - 1)
	var source := Rect2(Vector2(index % columns, int(index / columns)) * cell_light, cell_light)
	var target := Rect2(hotspot - origin_light * amount, cell_light * amount)
	hull_glow.draw(view, hull_light, target, source, Transform2D(request.rotation, Vector2(-request.facing, 1), 0.0, request.pos), request.color)

func draw_projectile(view: Node2D, projectile: Dictionary, weapon: int, offset: Vector2 = Vector2.ZERO) -> void:
	if not projectile.get("launched", true) or weapon < 0 or weapon >= bullets.size():
		return
	var name := projectile_sheet(projectile, weapon)
	var info := sheet(name)
	if info.is_empty():
		return
	var at: Vector2 = projectile.get("hit_pos", projectile.pos) + offset
	var angle := projectile_angle(projectile)
	var mirror := weapon == 2 and projectile.has("fp_velocity") and ss_mirrored(NativeBallistics.velocity_angle(projectile.fp_velocity))
	var scale := Vector2(1, -1) if mirror else Vector2.ONE
	var body := cell_frame(name, projectile_frame(info, projectile))
	view.draw_set_transform(at, angle, scale)
	view.draw_texture_rect_region(_optional_cached(name), body[1], body[0])
	view.draw_set_transform(Vector2.ZERO)
	var light_name := name.replace(".png", "Light.png")
	var light_info := sheet(light_name)
	if light_info.is_empty():
		return
	var light := cell_frame(light_name, projectile_frame(light_info, projectile))
	glow.draw(view, _optional_cached(light_name), light[1], light[0], Transform2D(angle, scale, 0.0, at))
