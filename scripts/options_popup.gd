extends Control
## Native battle configuration: play_option.img, input4b9ed0/render4c8890.
## Frozen offline match, Sniper/MIDI/3d and Godot backend bridges: ADR-137.
signal changed
signal accepted
signal cancelled
signal quit_requested

const Art = preload("res://scripts/classic_battle_options_art.gd")
const K := 1.6
const SIZE := Vector2(276,408)
const ORIGIN := Vector2(8,45)
const AUDIO_LEVELS := [0,80,90,95,98,100]
const SCROLL_LEVELS := [20,30,40,50,60,70]
const VALUES := ["aiming","scroll","bgm","sfx","background"]
# Strict x86 comparisons, original800x600 canvas. WM_LBUTTONDOWN only.
const BOUNDS := {
	"aiming": [Rect2(29,114,65,13),Rect2(113,114,65,13),Rect2(198,114,64,13)],
	"scroll": [Rect2(39,168,26,12),Rect2(65,168,40,12),Rect2(105,168,40,12),Rect2(145,168,40,12),Rect2(185,168,40,12),Rect2(225,168,40,12)],
	"bgm": [Rect2(89,248,21,12),Rect2(110,248,30,12),Rect2(140,248,30,12),Rect2(170,248,30,12),Rect2(200,248,30,12),Rect2(230,248,21,12)],
	"sfx": [Rect2(89,274,21,12),Rect2(110,274,30,12),Rect2(140,274,30,12),Rect2(170,274,30,12),Rect2(200,274,30,12),Rect2(230,274,21,12)],
	"background": [Rect2(35,374,39,13),Rect2(219,374,39,13)]}
const RADIO_POSITIONS := {
	"aiming": [Vector2(29,114),Vector2(113,114),Vector2(198,114)],
	"scroll": [Vector2(39,168),Vector2(79,168),Vector2(119,168),Vector2(159,168),Vector2(199,168),Vector2(239,168)],
	"bgm": [Vector2(89,248),Vector2(119,248),Vector2(149,248),Vector2(179,248),Vector2(209,248),Vector2(239,248)],
	"sfx": [Vector2(89,274),Vector2(119,274),Vector2(149,274),Vector2(179,274),Vector2(209,274),Vector2(239,274)],
	"background": [Vector2(35,374),Vector2(219,374)]}
var options
var art
var snapshot := {}
var resolved := false
var accept_button: BaseButton
var cancel_button: BaseButton
var quit_button: BaseButton

# Sprite may extend beyond the native hitbox; never fit82x33 into74x26.
class NativeButton extends BaseButton:
	var art
	var sprite: String
	func _init(paint, key: String) -> void:
		art = paint
		sprite = key
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for event in [mouse_entered,mouse_exited,button_down,button_up]:
			event.connect(queue_redraw)
	func _draw() -> void:
		var frame := 3 if disabled else (2 if is_pressed() else (1 if is_hovered() else 0))
		art.draw(self,sprite,Vector2.ZERO,frame)

func _init(values = null, paint = null) -> void:
	options = values
	art = Art.new() if paint == null else paint
	for key in VALUES:
		snapshot[key] = options.get(key)
	position = ORIGIN*K
	size = SIZE*K
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	accept_button = make_button("NativeOptionOK.png",Rect2(187,408,74,26),"OK")
	cancel_button = make_button("NativeOptionClose.png",Rect2(248,53,22,20),"Cancel (ESC)")
	quit_button = make_button("NativeOptionQuit.png",Rect2(27,408,74,26),"Leave training")
	accept_button.pressed.connect(func(): accepted.emit())
	cancel_button.pressed.connect(func(): cancelled.emit())
	quit_button.pressed.connect(func(): quit_requested.emit())
	unsupported(Rect2(198,114,64,13),"Sniper ainda não portado")
	unsupported(Rect2(35,218,222,12),"MP3; MIDI ainda não portado")
	unsupported(Rect2(29,323,234,14),"Qualidade 3d não se aplica ao renderer Godot; Normal fixo")

func make_button(sprite: String, bounds: Rect2, tooltip: String) -> BaseButton:
	var button := NativeButton.new(art,sprite)
	button.position = point(bounds.position)
	button.size = bounds.size*K
	button.tooltip_text = tooltip
	add_child(button)
	return button

func unsupported(bounds: Rect2, tooltip: String) -> void:
	var region := Control.new()
	region.position = point(bounds.position)
	region.size = bounds.size*K
	region.mouse_filter = Control.MOUSE_FILTER_STOP
	region.tooltip_text = tooltip
	add_child(region)

func point(native_point: Vector2) -> Vector2:
	return (native_point-ORIGIN)*K

func radio_rect(key: String, index: int) -> Rect2:
	var bounds: Rect2 = BOUNDS[key][index]
	return Rect2(point(bounds.position),bounds.size*K)

func restore() -> void:
	if resolved:
		return
	resolved = true
	for key in snapshot:
		options.set(key,snapshot[key])
	changed.emit()
	queue_redraw()

func commit() -> void:
	resolved = true

func select_radio(key: String, index: int) -> void:
	if key == "aiming" and index < 2:
		options.aiming = index
	elif key == "background":
		options.background = index == 0
	elif key in ["bgm","sfx"]:
		options.set(key,AUDIO_LEVELS[index])
	elif key == "scroll":
		options.scroll = SCROLL_LEVELS[index]
	else:
		return
	changed.emit()
	queue_redraw()

func pointer_down(local: Vector2) -> void:
	var native := (local/K+ORIGIN).floor()
	for key in BOUNDS:
		for index in BOUNDS[key].size():
			var r: Rect2 = BOUNDS[key][index]
			if native.x>r.position.x and native.x<r.end.x and native.y>r.position.y and native.y<r.end.y:
				select_radio(key,index)
				return

func pointer_up() -> void:
	pass

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_down(event.position)
		accept_event()
	elif event is InputEventMouseMotion:
		accept_event()

func selection_index(key: String) -> int:
	match key:
		"aiming": return options.aiming
		"background": return 0 if options.background else 1
		"scroll":
			# 4c9ef9..4c9f15: trunc(scroll/10)-2; unsigned bound0..5.
			var slot := int(options.scroll/10.0)-2
			return slot if slot>=0 and slot<6 else -1
		_: return AUDIO_LEVELS.find(options.get(key))

func _draw() -> void:
	art.draw(self,"NativeOptionsPanel.png",Vector2.ZERO)
	for key in RADIO_POSITIONS:
		var index := selection_index(key)
		if index >= 0:
			art.draw(self,"NativeOptionRadio.png",point(RADIO_POSITIONS[key][index]))
	art.draw(self,"NativeOptionRadio.png",point(Vector2(214,218)),0,Color(1,1,1,0.38))
	art.draw(self,"NativeOptionRadio.png",point(Vector2(113,324)),0,Color(1,1,1,0.38))
