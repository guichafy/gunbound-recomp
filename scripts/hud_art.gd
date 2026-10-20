extends RefCounted
## OpenBound battle HUD (HUD.cs, Crosshair.cs, WindCompass.cs, Delayboard.cs,
## HealthBar.cs, Nameplate.cs, FloatingText.cs) drawn with the original layout.
## Presentation only: reads match.gd state and events, never decides combat.
## Offsets are the C# ones on an 800×500 virtual screen scaled by K = 1.6;
## HD sprites (assets/hd/hud, 3× the original) fall back to the originals.

const Match = preload("res://scripts/match.gd")

const K := 1.6
const BAR_CENTER := Vector2(400, 457.5)  # origin = (0, (500 - 85) / 2) from the centre
const COMPASS_CENTER := Vector2(400, 73.6)  # (0, (54 - 250) * 0.9) from the centre
const TEAM_BLUE := Color8(98, 149, 230)
const TEAM_RED := Color8(246, 161, 98)
const HEALTH_GREEN := Color8(99, 182, 74)
const HEALTH_BLUE := Color8(33, 56, 198)
const HEALTH_BLACK := Color8(41, 44, 41)
const HEALTH_RED := Color8(198, 20, 0)
const CROSSHAIR_FADE := Color(0.6, 0.6, 0.6, 0.6)
const CROSSHAIR_INTRO := 0.25
const POINTER_OFFSET := 29.0
const MAX_WIND := 35.0
const TURN_TIME := 30
# Button.cs presets: frame index of normal, hover, clicked, disabled, activated.
const SHOT_FRAMES := [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14]]
const SHOT_OFFSETS := [Vector2(-371, -4), Vector2(-328, -4), Vector2(-285, -4)]
const OPTIONS_OFFSET := Vector2(-359, 26)
const SKIP_OFFSET := Vector2(-296, 26)
const STRENGTH_OFFSET := Vector2(41, 17)
const MOVEMENT_OFFSET := Vector2(41, 35)
const WEATHER_OFFSET := Vector2(157, -20)
# SpriteNumericField presets: glyph size and where digit d / minus sit.
const FONTS := {
	"current_angle": {"file": "FontCurrentAngle.png", "size": Vector2(15, 15)},
	"previous_angle": {"file": "FontPreviousAngle.png", "size": Vector2(10, 8)},
	"gold": {"file": "FontGold.png", "size": Vector2(15, 15)},
	"delay": {"file": "FontDelay.png", "size": Vector2(8, 9)},
	"damage": {"file": "FontDamage.png", "size": Vector2(14, 19), "minus_first": true},
	"crosshair": {"file": "FontCrosshairAngle.png", "size": Vector2(10, 12)},
	"wind": {"file": "FontWindCompass.png", "size": Vector2(13, 19)},
	"timer": {"file": "FontTurnTimer.png", "size": Vector2(66, 82), "columns": 5},
	"blue_turn": {"file": "FontBlueTurnCounter.png", "size": Vector2(13, 17)},
	"red_turn": {"file": "FontRedTurnCounter.png", "size": Vector2(13, 17)},
}
const ICON_INDEX := {"force": 0, "tornado": 1, "electricity": 2, "wind": 3, "thor": 4, "protection": 5, "ignorance": 6, "weakness": 7, "mirror": 8, "random": 9}

var textures := {}
var originals := {}
var clock_sound: AudioStream
var font: Font
# Crosshair intro (Crosshair.PlayAnimation), compass animation, timer, floats.
var crosshair_age := 99.0
var compass_rotation := PI * 1.5
var compass_spin := 0.0
var yellow_alpha := 0.0
var red_alpha := 0.0
var yellow_target := 0.0
var red_target := 0.0
var shown_wind := 0
var last_second := -1
var floats: Array = []
var selector_x := -160.0
var previous_power := -1.0
var previous_angle := -1
var weather_slide := 0.0
var weather_shown: Array = []
var weather_previous := ""

func _init() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Noto Sans", "Trebuchet MS", "Avenir Next"])
	font.font_weight = 700
	var names := ["ActionBar.png", "StrenghtMetter.png", "MovementMetter.png", "PreviousShootingStrenghtPointer.png",
		"ShotStrenghtSelector.png", "SelectedPlayerTurnBG.png", "TurnCounterBalloon.png", "WeatherFrame.png",
		"CompassBackground.png", "CompassForeground.png", "CompassWhiteArrow.png", "CompassYellowArrow.png",
		"CompassRedArrow.png", "HealthBarFrame.png", "CrosshairFrame.png", "CrosshairPointer.png",
		"ShotSelector.png", "Options.png", "SkipTurn.png", "WeatherIcons.png"]
	for font_spec in FONTS.values():
		names.append(font_spec.file)
	for mob in ["Mage", "Bigfoot", "Nak"]:
		for shot in ["S1", "S2", "SS"]:
			for side in ["Ally", "Enemy"]:
				names.append("Crosshair%s%s%s.png" % [mob, shot, side])
	for name in names:
		var original_path: String = "res://assets/openbound/weather/WeatherIcons.png" if name == "WeatherIcons.png" else "res://assets/openbound/hud/" + name
		var original: Texture2D = load(original_path)
		originals[name] = original
		var hd_path: String = "res://assets/hd/hud/" + name
		textures[name] = load(hd_path) if ResourceLoader.exists(hd_path) else original
	clock_sound = load("res://assets/openbound/hud/ClockSecond.mp3")

## Screen position of a HUD.cs offset (relative to the action bar centre).
static func bar_point(offset: Vector2) -> Vector2:
	return (BAR_CENTER + offset) * K

func density(name: String) -> float:
	return float(textures[name].get_width()) / float(originals[name].get_width())

func original_size(name: String) -> Vector2:
	return Vector2(originals[name].get_size())

func blit(view: CanvasItem, name: String, source: Rect2, dest: Rect2, color: Color = Color.WHITE) -> void:
	var d := density(name)
	view.draw_texture_rect_region(textures[name], dest, Rect2(source.position * d, source.size * d), color)

## Sprite with the default OpenBound pivot (centre) at a screen/world point.
func sprite(view: CanvasItem, name: String, center: Vector2, scale: float, source: Rect2 = Rect2(), color: Color = Color.WHITE) -> void:
	var src := source if source.size != Vector2.ZERO else Rect2(Vector2.ZERO, original_size(name))
	blit(view, name, src, Rect2(center - src.size * scale * 0.5, src.size * scale), color)

func atlas(name: String, source: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = textures[name]
	var d := density(name)
	texture.region = Rect2(source.position * d, source.size * d)
	return texture

func reset(model) -> void:
	floats.clear()
	crosshair_age = 99.0
	selector_x = -160.0
	previous_power = -1.0
	previous_angle = -1
	last_second = -1
	weather_shown = []
	weather_slide = 0.0
	weather_previous = ""
	compass_rotation = PI * 1.5
	shown_wind = -1
	sync_weather(model)

# ---------------------------------------------------------------- buttons

## TextureButton with the Button.cs state rectangles (normal, hover, clicked, disabled).
func make_button(parent: Node, kind: String, index: int = 0) -> TextureButton:
	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_NONE
	var size: Vector2
	var center: Vector2
	if kind == "shot":
		size = Vector2(37, 37)
		center = bar_point(SHOT_OFFSETS[index])
	else:
		size = Vector2(60, 23)
		center = bar_point(OPTIONS_OFFSET if kind == "options" else SKIP_OFFSET)
	button.size = size * K
	button.position = center - button.size * 0.5
	button.set_meta("kind", kind)
	button.set_meta("index", index)
	style_button(button, false)
	parent.add_child(button)
	return button

func style_button(button: TextureButton, activated: bool) -> void:
	var kind: String = button.get_meta("kind")
	var frames: Array
	var name: String
	var size: Vector2
	if kind == "shot":
		frames = SHOT_FRAMES[int(button.get_meta("index"))]
		name = "ShotSelector.png"
		size = Vector2(37, 37)
	else:
		frames = [0, 1, 2, 3, 3]
		name = "Options.png" if kind == "options" else "SkipTurn.png"
		size = Vector2(60, 23)
	var region := func(frame: int) -> AtlasTexture: return atlas(name, Rect2(Vector2(frame * size.x, 0), size))
	# An activated button keeps its activated face on hover (Button.ChangeButtonState).
	button.texture_normal = region.call(frames[4] if activated else frames[0])
	button.texture_hover = region.call(frames[4] if activated else frames[1])
	button.texture_pressed = region.call(frames[2])
	button.texture_disabled = region.call(frames[3])
	button.set_meta("activated", activated)

# ---------------------------------------------------------------- numbers

## SpriteNumericField: glyph advance is width − 2; anchor left/right/middle.
func number_width(kind: String, value: int, digits: int = 1) -> float:
	return (FONTS[kind].size.x - 2.0) * digit_text(value, digits).length()

func digit_text(value: int, digits: int) -> String:
	var text := str(absi(value)).pad_zeros(digits)
	return ("-" if value < 0 else "") + text

func draw_number(view: CanvasItem, kind: String, value: int, position: Vector2, anchor: String, scale: float, digits: int = 1, color: Color = Color.WHITE, row: int = 0) -> void:
	var spec: Dictionary = FONTS[kind]
	var glyph: Vector2 = spec.size
	var text := digit_text(value, digits)
	var advance := (glyph.x - 2.0) * scale
	var start := position.x
	if anchor == "right":
		start -= advance * text.length()
	elif anchor == "middle":
		start -= advance * text.length() * 0.5
	for i in range(text.length()):
		var character := text[i]
		var cell := 10 if character == "-" else int(character)
		if spec.get("minus_first", false):
			cell = 0 if character == "-" else int(character) + 1
		var source := Rect2(Vector2(cell * glyph.x, row * glyph.y), glyph)
		if spec.has("columns"):
			source = Rect2(Vector2((cell % 5) * glyph.x, (cell / 5) * glyph.y), glyph)
		blit(view, spec.file, source, Rect2(Vector2(start + advance * i, position.y), glyph * scale), color)

# ---------------------------------------------------------------- events/tick

func react(event: Dictionary, model) -> void:
	match event.type:
		"turn":
			if event.actor == Match.PLAYER:
				crosshair_age = 0.0
		"damage", "shield_damage":
			add_damage(event.actor, int(event.amount), model)

func add_damage(actor: int, amount: int, model) -> void:
	# FloatingTextHandler.AddDamage: one counter per actor accumulates hits.
	for entry in floats:
		if entry.actor == actor:
			entry.target -= amount
			entry.life = 3.0
			entry.step = (entry.target - entry.value) / 20.0
			return
	var start: float = Vector2(model.actors[actor].pos).y - 15.0
	floats.append({"actor": actor, "value": 0.0, "target": float(-amount), "step": float(-amount) / 20.0, "life": 3.0, "age": 0.0, "tick": 0.0, "y": start, "x": Vector2(model.actors[actor].pos).x})

func tick(delta: float, model, sound) -> void:
	crosshair_age += delta
	# WindCompass.UpdateCompassRotationAnimation / UpdateYRotatingAnimation.
	var force: float = model.weather.wind_force if model.weather != null else 0.0
	if int(force) != shown_wind:
		shown_wind = int(force)
		var half := MAX_WIND * 0.5
		yellow_target = 1.0 - absf(force - half) / half
		red_target = 1.0 - yellow_target if force > half else 0.0
	var goal: float = deg_to_rad(float(model.weather.wind_angle)) if model.weather != null and force > 0.0 else compass_rotation
	var difference := wrapf(goal - compass_rotation, -PI, PI)
	var turn := delta * (1.0 + force * 5.0 / MAX_WIND)
	compass_rotation = goal if absf(difference) <= turn else compass_rotation + signf(difference) * turn
	compass_spin = fmod(compass_spin + delta * (0.5 + force * 5.0 / MAX_WIND), TAU)
	yellow_alpha = move_toward(yellow_alpha, yellow_target, delta)
	red_alpha = move_toward(red_alpha, red_target, delta)
	# Floating damage counts up like CurrencySpriteFont (20 steps of 0.05 s).
	for i in range(floats.size() - 1, -1, -1):
		var entry: Dictionary = floats[i]
		entry.age += delta
		entry.life -= delta
		entry.tick += delta
		while entry.tick >= 0.05 and entry.value != entry.target:
			entry.tick -= 0.05
			entry.value += entry.step
			if absf(entry.value) > absf(entry.target):
				entry.value = entry.target
		if entry.life <= 0.0:
			floats.remove_at(i)
	weather_slide = maxf(0.0, weather_slide - delta * 24.0 / 0.5)
	sync_weather(model)
	# HUD.UpdateTimer: ClockSecond every second of the player's turn, last 10 s of others.
	var seconds := display_seconds(model)
	if seconds != last_second:
		if last_second >= 0 and seconds >= 0 and sound != null and (model.active == Match.PLAYER or seconds < 10):
			var pitch := clampf((float(last_second - 1) / TURN_TIME - 0.5) * 2.0, -1.0, 1.0)
			sound.play("clock", clock_sound, pow(2.0, pitch))
		last_second = seconds

func display_seconds(model) -> int:
	if model.phase != "aim":
		return -1
	return clampi(int(model.turn_time + 0.9), 0, TURN_TIME)

func sync_weather(model) -> void:
	if model.weather == null:
		return
	var types: Array = []
	for entry in model.weather.queue:
		types.append(str(entry.type))
	if types == weather_shown:
		return
	if not weather_shown.is_empty() and types.size() > 0 and weather_shown.size() > 1 and types[0] == weather_shown[1]:
		weather_previous = weather_shown[0]
		weather_slide = 24.0
	weather_shown = types

# ---------------------------------------------------------------- screen HUD

func draw_screen(view, model, state: Dictionary) -> void:
	draw_compass(view, model)
	draw_timer(view, model)
	draw_delayboard(view, model, state)
	sprite(view, "ActionBar.png", bar_point(Vector2.ZERO), K)
	draw_weather(view, model)
	# Strength (TimedProgressBar) and movement bars grow from the left edge.
	var strength := clampf(float(state.power) / 100.0, 0.0, 1.0)
	draw_meter(view, "StrenghtMetter.png", STRENGTH_OFFSET, strength)
	draw_meter(view, "MovementMetter.png", MOVEMENT_OFFSET, clampf(float(state.movement), 0.0, 1.0))
	if previous_power >= 0.0:
		sprite(view, "PreviousShootingStrenghtPointer.png", bar_point(Vector2(-160.0 + 400.0 * previous_power / 100.0, 26)), K)
	sprite(view, "ShotStrenghtSelector.png", bar_point(Vector2(selector_x, 17)), K)
	draw_number(view, "current_angle", int(state.angle), bar_point(Vector2(-149, -26)), "right", K)
	if previous_angle >= 0:
		draw_number(view, "previous_angle", previous_angle, bar_point(Vector2(-185, -20)), "right", K)
	draw_number(view, "gold", int(state.gold), bar_point(Vector2(372, 23)), "right", K)

func draw_meter(view: CanvasItem, name: String, offset: Vector2, fraction: float) -> void:
	var size := original_size(name)
	var left_top := bar_point(offset) - size * K * 0.5
	var width := floorf(fraction * size.x)
	if width <= 0.0:
		return
	blit(view, name, Rect2(Vector2.ZERO, Vector2(width, size.y)), Rect2(left_top, Vector2(width, size.y) * K))

func strength_rect() -> Rect2:
	var size := original_size("StrenghtMetter.png") * K
	return Rect2(bar_point(STRENGTH_OFFSET) - size * 0.5, size)

func set_selector_from_screen(x: float) -> void:
	selector_x = clampf(x / K - BAR_CENTER.x, -160.0, 240.0)

func draw_weather(view: CanvasItem, model) -> void:
	# WeatherDisplay roulette: previous, active (coloured, under the frame), next three.
	var center := bar_point(WEATHER_OFFSET)
	var left := center.x - 36.0 * K
	var slots: Array = [weather_previous] + weather_shown
	var top := center.y - 11.0 * K
	for slot in range(slots.size()):
		var type: String = slots[slot]
		if type.is_empty() or slot > 4:
			continue
		var x := left + (slot * 24.0 + weather_slide) * K
		if x < left - 1.0 or x > left + 96.0 * K:
			continue
		var row := 0 if slot == 1 else 1
		blit(view, "WeatherIcons.png", Rect2(ICON_INDEX.get(type, 3) * 22, row * 22, 22, 22), Rect2(Vector2(x, top), Vector2(22, 22) * K))
	sprite(view, "WeatherFrame.png", center, K)

func draw_compass(view: CanvasItem, model) -> void:
	var center := COMPASS_CENTER * K
	sprite(view, "CompassBackground.png", center, K)
	var squash := absf(cos(compass_spin))
	for pair in [["CompassWhiteArrow.png", 1.0], ["CompassYellowArrow.png", yellow_alpha], ["CompassRedArrow.png", red_alpha]]:
		if float(pair[1]) <= 0.0:
			continue
		view.draw_set_transform(center, compass_rotation, Vector2(K, K * squash))
		var size := original_size(pair[0])
		blit(view, pair[0], Rect2(Vector2.ZERO, size), Rect2(-size * 0.5, size), Color(1, 1, 1, float(pair[1])))
	view.draw_set_transform(center, compass_rotation, Vector2(K, K))
	var ring := original_size("CompassForeground.png")
	blit(view, "CompassForeground.png", Rect2(Vector2.ZERO, ring), Rect2(-ring * 0.5, ring), Color(1, 1, 1, 0.8))
	view.draw_set_transform(Vector2.ZERO)
	var force: int = int(model.weather.wind_force) if model.weather != null else 0
	draw_number(view, "wind", force, center - Vector2(0, 10) * K, "middle", K)

func draw_timer(view: CanvasItem, model) -> void:
	# TurnTimer shows only on the player's own turn (HUD.ResetTimer).
	var seconds := display_seconds(model)
	if seconds < 0 or model.active != 0:
		return
	draw_number(view, "timer", seconds, Vector2(780, 12.5) * K, "right", K, 2)

func draw_delayboard(view, model, state: Dictionary) -> void:
	# Delayboard: bottom-left anchored at the bar's top-left, one 16 px row per player.
	var entries: Array = state.queue
	if entries.is_empty():
		return
	var row_height := 16.0
	var base := Vector2(0, 415.0 - row_height * entries.size())
	var nick_size := 10.0 * K
	var names: Array = []
	var widest := 0.0
	for entry in entries:
		var name: String = state.player_name if entry.actor == Match.PLAYER else "Autômato"
		names.append(name)
		widest = maxf(widest, font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, int(nick_size)).x / K)
	var delay_width := 0.0
	for entry in entries:
		delay_width = maxf(delay_width, number_width("delay", int(entry.delay)))
	var nick_x := (13.0 - 2.0) + 4.0 + 4.0
	var delay_right := nick_x + widest + delay_width + 4.0
	for row in range(entries.size()):
		var entry: Dictionary = entries[row]
		var top := base + Vector2(0, row * row_height)
		if entry.actor == Match.PLAYER:
			# SelectedPlayerTurnBG column: green when next, orange otherwise.
			var column := 1.0 if row == 0 else 4.0
			blit(view, "SelectedPlayerTurnBG.png", Rect2(column, 0, 1, 17), Rect2(top * K, Vector2(delay_right + 4.0, 17) * K))
		draw_number(view, "blue_turn" if entry.actor == Match.PLAYER else "red_turn", row, top * K, "left", K)
		var color := TEAM_BLUE if entry.actor == Match.PLAYER else TEAM_RED
		var baseline := (top + Vector2(nick_x, 12.5)) * K
		view.draw_string_outline(font, baseline, names[row], HORIZONTAL_ALIGNMENT_LEFT, -1, int(nick_size), 4, Color.BLACK)
		view.draw_string(font, baseline, names[row], HORIZONTAL_ALIGNMENT_LEFT, -1, int(nick_size), color)
		draw_number(view, "delay", int(entry.delay), (top + Vector2(delay_right, 4.5)) * K, "right", K)

# ---------------------------------------------------------------- world HUD

func draw_world(view, model, offset: Vector2, state: Dictionary) -> void:
	for index in range(model.actors.size()):
		var actor: Dictionary = model.actors[index]
		if int(actor.hp) <= 0:
			continue
		draw_health(view, actor, Vector2(actor.pos) + offset)
		var name: String = state.player_name if index == Match.PLAYER else "Autômato"
		draw_nameplate(view, name, TEAM_BLUE if index == Match.PLAYER else TEAM_RED, Vector2(actor.pos) + offset + Vector2(0, 70))
	if model.phase == "aim" and model.active == Match.PLAYER and not state.paused_cpu:
		draw_crosshair(view, model, offset, state)
	if model.phase == "aim" and model.active == Match.CPU:
		draw_balloon(view, model, offset)
	for entry in floats:
		var rise := 40.0 * (1.0 - pow(1.0 - minf(1.0, entry.age / 0.6), 2.0))
		draw_number(view, "damage", int(entry.value), Vector2(entry.x, entry.y - rise) + offset, "middle", 1.0)

## HealthBar.UpdateBarSprite: 76 px interior shared by health and shield.
static func health_segments(actor: Dictionary) -> Vector2:
	var total := float(actor.max_hp) + float(actor.get("max_shield", 0.0))
	return Vector2(floorf(76.0 * float(actor.hp) / total), ceilf(76.0 * float(actor.get("shield", 0.0)) / total))

func draw_health(view: CanvasItem, actor: Dictionary, position: Vector2) -> void:
	var center := position + Vector2(0, 40)
	sprite(view, "HealthBarFrame.png", center, 1.0)
	var inner := 76.0
	var segments := health_segments(actor)
	var health := segments.x
	var shield := segments.y
	var left := center + Vector2(-38, -1.5)
	view.draw_rect(Rect2(left, Vector2(inner, 3)), HEALTH_BLACK)
	if shield > 0.0:
		view.draw_rect(Rect2(left + Vector2(health, 0), Vector2(minf(shield, inner - health), 3)), HEALTH_BLUE)
	if health > 0.0:
		var critical := float(actor.hp) <= float(actor.max_hp) * 0.3
		view.draw_rect(Rect2(left, Vector2(health, 3)), HEALTH_RED if critical else HEALTH_GREEN)

func draw_nameplate(view: CanvasItem, name: String, color: Color, center: Vector2) -> void:
	var size := 13
	var width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := center + Vector2(-width * 0.5, 5)
	view.draw_string_outline(font, baseline, name, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color.BLACK)
	view.draw_string(font, baseline, name, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func crosshair_name(model, index: int, weapon: int) -> String:
	var mob: String = str(model.VEHICLES[model.actors[index].vehicle].name)
	return "Crosshair%s%s%s.png" % [mob, ["S1", "S2", "SS"][clampi(weapon, 0, 2)], "Ally" if index == Match.PLAYER else "Enemy"]

func draw_crosshair(view: CanvasItem, model, offset: Vector2, state: Dictionary) -> void:
	# Crosshair.Update: frame on the cannon, rotated with the chassis, flipped
	# with facing; pointer 29 px along the real shot direction (shot_velocity).
	var center: Vector2 = model.cannon_pivot(Match.PLAYER) + offset
	var rotation: float = model.body_rotation(Match.PLAYER)
	var facing: int = model.actors[Match.PLAYER].facing
	var flip := Vector2(-1.0 if facing == 1 else 1.0, 1.0)
	var intro := clampf(crosshair_age / CROSSHAIR_INTRO, 0.0, 1.0)
	var frame_scale := 5.0 - 4.0 * intro
	view.draw_set_transform(center, rotation, flip * frame_scale)
	var size := original_size("CrosshairFrame.png")
	blit(view, "CrosshairFrame.png", Rect2(Vector2.ZERO, size), Rect2(-size * 0.5, size), CROSSHAIR_FADE)
	if intro < 1.0:
		view.draw_set_transform(Vector2.ZERO)
		return
	view.draw_set_transform(center, rotation, flip)
	var wedge := crosshair_name(model, Match.PLAYER, int(state.weapon))
	blit(view, wedge, Rect2(Vector2.ZERO, original_size(wedge)), Rect2(-original_size(wedge) * 0.5, original_size(wedge)))
	var direction: Vector2 = model.shot_velocity(Match.PLAYER, float(state.aim), 100.0, int(state.weapon)).normalized()
	view.draw_set_transform(center + direction * POINTER_OFFSET, direction.angle() + PI * 0.5)
	var pointer := original_size("CrosshairPointer.png")
	blit(view, "CrosshairPointer.png", Rect2(Vector2.ZERO, pointer), Rect2(-pointer * 0.5, pointer), CROSSHAIR_FADE)
	view.draw_set_transform(Vector2.ZERO)
	var label_angle := deg_to_rad(150.0)
	var label := center + 30.0 * Vector2.from_angle(rotation + label_angle) if facing == -1 else center - 30.0 * Vector2.from_angle(rotation - label_angle)
	draw_number(view, "crosshair", int(state.angle), label - Vector2(0, 6), "middle", 1.0)

## Crosshair.CalculateHUDAngle: angle of the real shot direction over the horizon.
static func hud_angle(model, angle: float, weapon: int, index: int = 0) -> int:
	var direction: Vector2 = model.shot_velocity(index, angle, 100.0, weapon).normalized()
	var degrees := rad_to_deg(atan2(-direction.y, absf(direction.x)))
	if degrees > 90.0:
		degrees = 90.0 - fmod(degrees, 90.0)
	return roundi(degrees)

func draw_balloon(view: CanvasItem, model, offset: Vector2) -> void:
	# TurnCounterBalloon over the other player when 20 s or less remain.
	var seconds := display_seconds(model)
	if seconds < 0 or seconds > 20:
		return
	var remaining: float = model.turn_time
	var frame := clampi(20 - seconds, 0, 20)
	var source := Rect2(Vector2((frame % 7) * 34, (frame / 7) * 31), Vector2(34, 31))
	var position: Vector2 = Vector2(model.actors[Match.CPU].pos) + offset - Vector2(0, 120) + Vector2(0, sin(PI * 0.5 + (20.0 - remaining)) * 5.0)
	sprite(view, "TurnCounterBalloon.png", position, 1.0, source)
