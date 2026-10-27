extends Node2D
## Presentation and input. Combat outcomes belong exclusively to MatchModel.

const Match = preload("res://scripts/match.gd")
const CpuTurn = preload("res://scripts/cpu_turn.gd")
const MenuScreen = preload("res://scripts/menu_screen.gd")
const LobbyScreen = preload("res://scripts/lobby_screen.gd")
const Combat = preload("res://scripts/combat.gd")
const ClassicSprite = preload("res://scripts/classic_sprite.gd")
const AvatarShop = preload("res://scripts/avatar_shop.gd")
const ShopModel = preload("res://scripts/avatar_shop_model.gd")
var shop
var actor_avatars: Array = []
var gold_reward := 0
const Profile = preload("res://scripts/profile.gd")
const UIFactory = preload("res://scripts/ui.gd")
const Sound = preload("res://scripts/sound.gd")
const BattleArt = preload("res://scripts/battle_art.gd")
const MobileLooks = preload("res://scripts/mobile_looks.gd")
const SpritePose = preload("res://scripts/sprite_pose.gd")
const Maps = preload("res://scripts/maps.gd")
const WeatherArt = preload("res://scripts/weather_art.gd")
const HudArt = preload("res://scripts/hud_art.gd")
const Options = preload("res://scripts/options.gd")
const OptionsPopup = preload("res://scripts/options_popup.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Mobiles = preload("res://scripts/mobiles.gd")
const AimControl = preload("res://scripts/aim_control.gd")
const CameraRig = preload("res://scripts/camera_rig.gd")
const MatchOverlay = preload("res://scripts/match_overlay.gd")
const ItemArt = preload("res://scripts/item_art.gd")
const ItemBar = preload("res://scripts/item_bar.gd")
const SelectItemPopup = preload("res://scripts/select_item_popup.gd")
const Items = preload("res://scripts/items.gd")
var hud = HudArt.new()
var screen_hud: Node2D
var item_art = ItemArt.new()
var item_bar = ItemBar.new(item_art)
var weather_art = WeatherArt.new()
var art = BattleArt.new()
var ui = UIFactory.new()
var model = Match.new()
var profile = null
# PopupGameOptions values; saved next to the profile (tests isolate both).
var options
var sound = null
var screen := "lobby"
var root: Control
var background: Texture2D
var map_backgrounds := {}
const VIEW_SIZE := CameraRig.VIEW_SIZE
var rig := CameraRig.new()
var aim := AimControl.new()
# Help, options, items, pause and result: the open layer lives in MatchOverlay.
var overlays := MatchOverlay.new()
var dragging := false
var pan_mask := MOUSE_BUTTON_MASK_LEFT
# Lobby (entrada) e sala 1×1. Os controles vivem nesses objetos, não na cena.
var lobby = null
var menu = null
# A loja volta para a tela que a abriu (lobby ou sala).
var shop_return := "lobby"
const RoomChoice = preload("res://scripts/room_choice.gd")
var room_random_sprite = preload("res://scripts/room_random_sprite.gd").new()
var player_random := false
var cpu_random := false
var room_rng := RandomNumberGenerator.new()
var vehicle := 2
# -1 follows Mobiles.opponent. A room pick stores that mobile until changed.
var cpu_vehicle := -1
var cpu_difficulty := 1
# Training option: the map's original weather preset or every effect (Thor included).
var weather_mode := "original"
# Match RNG seed; -1 draws a new one. Tests pin it to replay a scene (REQ-12).
var match_seed := -1
var paused := false
var elapsed := 0.0
# CPU turn (REQ-32): worker-thread aim search, presentation wait, fire.
var cpu := CpuTurn.new()
# Who opens the next match: Match.RANDOM_OPENING in play (ADR-076); tests pin a side.
var opening := Match.RANDOM_OPENING
var match_id := ""
var reward := 0
var result_wait := -1.0
var effects: Array = []
# Raon T1 afterimages still draining after their shell left the model (ADR-118/120).
var lingering: Array = []
var floating: Array = []
var shake := 0.0
var fire_button: Button
var pass_button: TextureButton
var options_button: TextureButton
var flip_button: Button
var move_left: Button
var move_right: Button
var weapon_buttons: Array[TextureButton] = []
var queue_entries: Array = []
# One sprite per mobile, from the presentation catalog (ADR-081).
var sprites := build_sprites()

static func build_sprites() -> Dictionary:
	var result := {}
	for vehicle_id in MobileLooks.ids():
		var look: Dictionary = MobileLooks.look(vehicle_id)
		var sprite = load(look.sprite).new()
		if sprite.has_method("setup"):
			sprite.setup(str(look.kind))
			sprite.rear = bool(Mobiles.definition(vehicle_id).get("rear", false))
		result[vehicle_id] = sprite
	return result

func _ready() -> void:
	room_rng.randomize()
	# HUD HD sprites (3×) are drawn smaller than their pixels; mipmaps keep 1 px borders.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background = load("res://assets/art/background.png")
	if profile == null:
		profile = Profile.new()
	profile.load_profile()
	profile.grant_test_funds()
	if options == null:
		options = Options.new(profile.path.get_basename() + "-options.json")
		options.load_options()
	aim.drag_rng.randomize()
	if sound == null:
		sound = Sound.new()
	if sound.get_parent() != self:
		add_child(sound)
	apply_options()
	overlays.opened.connect(_on_overlay_opened)
	overlays.closed.connect(_on_overlay_closed)
	show_lobby()

## An overlay pauses the match, drops a charge and locks the Options button.
func _on_overlay_opened(kind: String) -> void:
	aim.charging = false
	paused = true
	if is_instance_valid(options_button):
		options_button.disabled = kind == "options"

## Closing resumes; after the match ends, the result comes back.
func _on_overlay_closed() -> void:
	paused = false
	if is_instance_valid(options_button):
		options_button.disabled = false
	if screen == "match" and model.phase == Match.PHASE_FINISHED:
		show_result()

func replace_root() -> void:
	# Private world-effect canvases belong to Game, not to the replaced UI.
	weather_art.clear_beams()
	weather_art.native_thor_art.clear()
	for sprite in sprites.values():
		if sprite.has_method("clear_projectiles"):
			sprite.clear_projectiles()
	screen_hud = null
	if is_instance_valid(root):
		remove_child(root)
		root.queue_free()
	root = Control.new()
	# World/RID effects z0, screen HUD z1, interactive UI z2.
	root.z_index = 2
	root.size = Vector2(1280, 800)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	overlays.attach(root, options)
	paused = false
	aim.charging = false

## Drops the room controls after replace_root has queued them for deletion.
func _clear_front() -> void:
	if screen == "menu" and menu != null and is_instance_valid(menu.nickname_input):
		profile.nickname = profile.clean_nickname(menu.nickname_input.text)
		profile.save_profile()
	weather_art.clear_beams()
	cpu.discard()
	sound.stop_music()
	result_wait = -1.0
	effects.clear()
	lingering.clear()
	floating.clear()
	replace_root()
	menu = null
	lobby = null

func show_lobby() -> void:
	_clear_front()
	screen = "lobby"
	model.phase = Match.PHASE_MENU
	lobby = LobbyScreen.new()
	lobby.build(root, ui, {"version": version(), "nickname": profile.nickname, "level": profile.level(),
		"rank": profile.rank, "xp": profile.xp, "gold": profile.gold, "cash": profile.cash},
		{"create": show_menu, "show_shop": show_shop, "quit": quit_game})
	queue_redraw()

func show_menu() -> void:
	_clear_front()
	screen = "menu"
	model.phase = Match.PHASE_MENU
	menu = MenuScreen.new()
	menu.build(root, ui, {"version": version(), "nickname": profile.nickname, "difficulty": cpu_difficulty,
		"weather_mode": weather_mode, "weather_label": weather_label(), "items_label": items_label(),
		"items": options.items.duplicate(), "rank": profile.rank, "level": profile.level(), "xp": profile.xp, "wins": profile.wins,
		"cpu_vehicle": resolved_cpu_id(), "item_art": item_art},
		{"select_vehicle": select_vehicle, "select_cpu_vehicle": select_cpu_vehicle, "select_difficulty": func(index: int): cpu_difficulty = index,
		"set_weather": set_weather, "show_items": show_items, "start": start_match, "show_shop": show_shop,
		"show_help": show_help, "leave": show_lobby, "commit_items": commit_items})
	menu.figures.paint = draw_room_figures
	menu.show_vehicle(vehicle)
	if player_random:
		menu.show_random("player")
	if cpu_random:
		menu.show_random("cpu")
	menu.figures.queue_redraw()
	queue_redraw()

func quit_game() -> void:
	get_tree().quit()

## Single source of the version: application/config/version (ADR-081).
static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))

func show_shop() -> void:
	if screen == "menu" and menu != null and is_instance_valid(menu.nickname_input):
		profile.nickname = profile.clean_nickname(menu.nickname_input.text)
	if not profile.save_profile():
		return
	if screen == "lobby" or screen == "menu":
		shop_return = screen
	cpu.discard()
	sound.stop_music()
	replace_root()
	menu = null
	lobby = null
	screen = "shop"
	shop = AvatarShop.new()
	root.add_child(shop)
	shop.setup(self,ShopModel.new(profile))
	queue_redraw()

## Volta à tela que abriu a loja (lobby ou sala).
func leave_shop() -> void:
	var back := shop_return
	shop_return = "lobby"
	if back == "menu":
		show_menu()
	else:
		show_lobby()

## Training option: the map's original weather weights or every effect.
## The room popup sets the mode on Accept; it does not flip a live button.
func set_weather(mode: String) -> String:
	weather_mode = "all" if mode == "all" else "original"
	return weather_label()

func toggle_weather() -> String:
	return set_weather("all" if weather_mode == "original" else "original")

func weather_label() -> String:
	return "Clima: " + ("original do mapa" if weather_mode == "original" else "todos (Thor)")

## The mobile the machine will drive. An explicit pick wins over the pairing.
func resolved_cpu_id() -> int:
	return cpu_vehicle if cpu_vehicle >= 0 else Mobiles.opponent(vehicle)

func select_vehicle(index: int) -> void:
	if index==RoomChoice.RANDOM:
		player_random = true
		if menu != null:
			menu.show_random("player")
		queue_redraw()
		return
	player_random = false
	index = Match.normalize_vehicle(index)
	vehicle = index
	if menu != null and is_instance_valid(menu.vehicle_info):
		menu.show_vehicle(index)
		if cpu_vehicle < 0 and not cpu_random:
			menu.show_cpu(Mobiles.opponent(vehicle))
	queue_redraw()

func select_cpu_vehicle(index: int) -> void:
	if index==RoomChoice.RANDOM:
		cpu_random = true
		if menu != null:
			menu.show_random("cpu")
		queue_redraw()
		return
	cpu_random = false
	cpu_vehicle = Match.normalize_vehicle(index)
	if menu != null and is_instance_valid(menu.cpu_mobile):
		menu.show_cpu(cpu_vehicle)
	queue_redraw()

func start_match() -> void:
	if screen == "menu" and menu != null and is_instance_valid(menu.nickname_input):
		profile.nickname = profile.clean_nickname(menu.nickname_input.text)
		profile.save_profile()
	if player_random:
		vehicle = RoomChoice.roll(room_rng)
	if cpu_random:
		cpu_vehicle = RoomChoice.roll(room_rng)
	screen = "match"
	model.start(vehicle, cpu_difficulty, match_seed, Maps.DEFAULT, weather_mode, Terrain.new(), options.items, [profile.attributes, []], [profile.equipment_bonuses(), []], opening, cpu_vehicle)
	item_art.clear()
	actor_avatars = [profile.equipped_set(), profile.catalog.defaults(0)]
	# LevelScene: ChangeSong(SongParameter.LevelScene); keeps playing across rematches.
	sound.play_music()
	art.bind_sprites(sprites)
	art.reset(model.actors)
	rig.manual = false
	dragging = false
	rig.last_impact = Vector2.INF
	rig.position = clamp_camera(camera_goal())
	weather_art.reset(Maps.get_map(model.map_id))
	match_id = str(Time.get_unix_time_from_system()) + ":" + str(Time.get_ticks_usec())
	reward = 0
	gold_reward = 0
	result_wait = -1.0
	aim.angle = clampf(45.0, model.aim_limits(Match.PLAYER).x, model.aim_limits(Match.PLAYER).y)
	aim.power = 0.0
	aim.weapon = 0
	aim.charging = false
	cpu.reset()
	effects.clear()
	lingering.clear()
	floating.clear()
	replace_root()
	build_hud()
	consume_events()
	update_hud()

func build_hud() -> void:
	# Native two-band interface: visual and input rectangles share Layout.
	hud.reset(model)
	screen_hud = Node2D.new()
	screen_hud.name = "ScreenHud"
	screen_hud.z_index = -1
	screen_hud.draw.connect(_draw_screen_hud)
	root.add_child(screen_hud)
	for box in [HudArt.Layout.HEADER,HudArt.Layout.FOOTER]:
		var blocker := Control.new()
		blocker.position = box.position
		blocker.size = box.size
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(blocker)
	# Shot strength selector: a draggable reference marker (does not set the power).
	var selector := Control.new()
	var area: Rect2 = hud.strength_rect().grow_individual(0, 8, 0, 8)
	selector.position = area.position
	selector.size = area.size
	selector.mouse_filter = Control.MOUSE_FILTER_STOP
	selector.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			hud.set_selector_from_screen(selector.position.x + event.position.x)
	)
	root.add_child(selector)
	weapon_buttons.clear()
	for index in range(Mobiles.weapon_count(model.actors[Match.PLAYER].vehicle)):
		var button: TextureButton = hud.make_button(root, "shot", index)
		button.pressed.connect(func(): select_weapon(index))
		button.tooltip_text = "%s · atraso %d" % [model.weapon_rules(Match.PLAYER, index).name, model.weapon_rules(Match.PLAYER, index).delay]
		weapon_buttons.append(button)
	options_button = hud.make_button(root, "options")
	options_button.tooltip_text = "Configuration (ESC / P)"
	options_button.pressed.connect(show_options)
	pass_button = hud.make_button(root, "skip")
	pass_button.tooltip_text = "Passar o turno (F8)"
	pass_button.pressed.connect(pass_turn)
	# Discreet extras for mouse/touch play; the original only has the keyboard.
	var extras := Vector2(1062, HudArt.Layout.FOOTER.position.y - 40)
	move_left = ui.button(root, "←", extras, Vector2(40, 32), func(): pass)
	move_right = ui.button(root, "→", extras + Vector2(44, 0), Vector2(40, 32), func(): pass)
	flip_button = ui.button(root, "F", extras + Vector2(88, 0), Vector2(36, 32), flip)
	fire_button = ui.button(root, "●", extras + Vector2(128, 0), Vector2(78, 32), func(): pass, true)
	fire_button.tooltip_text = "Segure para carregar e solte para disparar (ou Espaço)"
	fire_button.button_down.connect(begin_charge)
	fire_button.button_up.connect(release_charge)
	for button in [move_left, move_right, flip_button, fire_button]:
		button.add_theme_font_size_override("font_size", 15)
		button.modulate = Color(1, 1, 1, 0.82)
	item_bar.build(self, root)
	select_weapon(0)

## Test API (test_refinement_scene, test_hud): the Delayboard entries shown now.
func displayed_queue() -> Array:
	return queue_entries

func animation_state(index: int) -> String:
	return art.state_name(model, index, aim.charging, cpu.charging(model))

func player_can_act() -> bool:
	return screen == "match" and model.phase == Match.PHASE_AIM and model.active == Match.PLAYER and not paused

func select_weapon(index: int) -> void:
	if screen != "match" or not player_can_act():
		return
	if Match.SPECIAL_WEAPON == index and not model.can_use_special(Match.PLAYER):
		return
	aim.weapon = index
	var limits: Vector2 = model.aim_limits(Match.PLAYER, aim.weapon)
	aim.angle = clampf(aim.angle, limits.x, limits.y)
	for j in range(weapon_buttons.size()):
		hud.style_button(weapon_buttons[j], j == index)

func cycle_weapon() -> void:
	# ShotButton.UpdateKeyboard: Tab moves to the next shot, skipping a disabled SS.
	var next := (aim.weapon + 1) % Mobiles.weapon_count(model.actors[Match.PLAYER].vehicle)
	if next == Match.SPECIAL_WEAPON and not model.can_use_special(Match.PLAYER):
		next = 0
	select_weapon(next)

func begin_charge() -> void:
	aim.begin_charge(self)

func release_charge() -> void:
	aim.release_charge(self)

func begin_drag(x: float) -> void:
	aim.begin_drag(self, x)

func update_drag(x: float, relative_x: float) -> void:
	aim.update_drag(x, relative_x)

func release_drag() -> void:
	aim.release_drag(self)

## HUD.UseItemAction on the own turn: the match validates and applies the item;
## DisableSS moves an SS selection to the second shot.
func use_item(slot: int) -> bool:
	if not player_can_act() or not model.use_item(slot):
		return false
	if aim.weapon == Match.SPECIAL_WEAPON:
		select_weapon(1)
	return true

func pass_turn() -> void:
	if player_can_act():
		aim.charging = false
		model.pass_turn()

func shoot() -> void:
	if player_can_act():
		aim.charging = false
		hud.previous_power = aim.power
		hud.previous_angle = hud.hud_angle(model, aim.angle, aim.weapon)
		model.fire(aim.angle, aim.power, aim.weapon)

func flip() -> void:
	if player_can_act():
		model.actors[Match.PLAYER].facing *= -1

func _process(delta: float) -> void:
	if not paused:
		elapsed += minf(delta, 0.1)
	queue_redraw()
	if screen == "menu" and menu != null and is_instance_valid(menu.figures):
		menu.figures.queue_redraw()
	if screen != "match" or paused:
		return
	var frame_delta := minf(delta, 0.1)
	if player_can_act():
		var direction := 0.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or move_left.is_pressed():
			direction -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or move_right.is_pressed():
			direction += 1.0
		if not is_zero_approx(direction):
			model.move_actor(direction, frame_delta)
		update_aim_keys(frame_delta)
		aim.tick(self, frame_delta)
	hud.update_movement(bool(hud_state().moving))
	hud.tick(frame_delta, model, sound)
	item_art.tick(frame_delta)
	var shells_before: Array = model.projectiles.duplicate()
	model.tick(frame_delta)
	collect_lingering(shells_before)
	weather_art.tick(frame_delta, model)
	art.tick(model, frame_delta, aim.charging, aim.weapon, cpu.charging(model), cpu.weapon())
	consume_events()
	cpu.tick(model, frame_delta)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].age += frame_delta
		if effects[i].age > 1.5:
			effects.remove_at(i)
	for i in range(lingering.size() - 1, -1, -1):
		lingering[i].age += frame_delta
		if lingering[i].age > ClassicSprite.NATIVE_TRAIL_LEVELS * Combat.STEP:
			lingering.remove_at(i)
	for i in range(floating.size() - 1, -1, -1):
		floating[i].age += frame_delta
		if floating[i].age > 1.5:
			floating.remove_at(i)
	update_camera(frame_delta)
	shake = maxf(0.0, shake - frame_delta * 24.0)
	if result_wait >= 0.0:
		result_wait -= frame_delta
		if result_wait < 0.0:
			show_result()
	update_hud()

func _exit_tree() -> void:
	cpu.discard()

func update_aim_keys(delta: float) -> void:
	aim.update_keys(self, delta)

func step_angle(direction: int) -> void:
	aim.step_angle(self, direction)

func actor_context(index: int) -> Dictionary:
	var cpu_weapon := cpu.weapon(int(model.last_shots[index].get("weapon", 0)))
	return {
		"charging": aim.charging,
		"cpu_charging": cpu.charging(model),
		"player_weapon": aim.weapon,
		"cpu_weapon": cpu_weapon,
		"avatar_context": {"equipment":actor_avatars[index],"age":elapsed} if actor_avatars.size()==2 else {},
		"atlas": sprite_for(int(model.actors[index].vehicle)),
		"elapsed": elapsed,
		"shadow": ui.box(Color(0.02, 0.04, 0.1, 0.28), 10),
	}

## Test API (test_mage_scene, test_bigfoot): atlas frame drawn for an actor.
func actor_frame(index: int) -> int:
	return art.atlas_frame(model, index, actor_context(index))

func sprite_for(vehicle_id: int):
	return sprites.get(vehicle_id)

func play_mobile_shot(event: Dictionary) -> void:
	var id := int(event.vehicle) if event.has("vehicle") else int(model.actors[event.actor].vehicle)
	# A Dual second volley sounds like a new shot; the teleport beacon has its own.
	var moment: String = "fire" if event.type == "volley" else event.type
	if not Mobiles.has_id(id) or Mobiles.shot_sound_on(id) != moment or not bool(event.get("sound", true)) or bool(event.get("beacon", false)) or event.get("item", "") == "teleport":
		return
	var body = sprite_for(id)
	if body == null:
		return
	if id == 10 and bool(event.get("child",false)):
		var original: AudioStream = body.satellite_sounds[clampi(int(event.weapon),0,2)]
		# The PE names10s3fire.xes, but this XFS build does not contain it.
		if original.get_length() > 0.0:
			sound.play("fire",original)
		return
	sound.play("fire", Mobiles.ShotTiming.stream(id, int(event.weapon), "fire"))

func consume_events() -> void:
	var granted := -1
	for event in model.events:
		art.react(event)
		hud.react(event, model)
		weather_art.react(event, model, sound)
		item_art.react(event, sound)
		match event.type:
			"turn":
				granted = int(event.actor)
				rig.manual = false
				rig.last_impact = Vector2.INF
				aim.charging = false
				cpu.begin_turn()
				if event.actor == Match.PLAYER:
					# HUD.GrantTurn resets the strength bar; the marker keeps the last shot.
					aim.power = 0.0
				sound.play_turn(event.actor == Match.PLAYER)
				if aim.weapon == Match.SPECIAL_WEAPON and not model.can_use_special(Match.PLAYER):
					aim.weapon = 0
			"fire":
				rig.manual = false
				play_mobile_shot(event)
			"volley":
				play_mobile_shot(event)
			"projectile_launch":
				play_mobile_shot(event)
			"explosion":
				rig.last_impact = event.position
				var vehicle_id := int(event.get("vehicle", Mobiles.DEFAULT_ID))
				effects.append({"pos": event.position, "radius": event.radius, "weapon": event.weapon, "vehicle": vehicle_id, "child":bool(event.get("child",false)), "raon_mine":bool(event.get("raon_mine",false)), "ss_state":str(event.get("ss_state","normal")), "age": 0.0, "angle":float(event.get("angle",0.0))})
				shake = 7.0
				var original: AudioStream = null
				var body = sprite_for(vehicle_id)
				if body != null:
					original = Mobiles.ShotTiming.stream(vehicle_id, int(event.weapon), "blast")
				sound.play("explosion", original)
			"fall":
				floating.append({"pos": Vector2(model.actors[event.actor].pos.x, minf(float(model.actors[event.actor].pos.y), model.terrain.world_size().y) - 80.0), "text": "QUEDA!", "age": 0.0, "color": Color("ffbc79")})
			"finished":
				aim.charging = false
				gold_reward = model.player_gold_reward()
				reward = profile.award(match_id, model.winner == Match.PLAYER, model.winner == -1, gold_reward)
				result_wait = 1.7
				sound.play("result")
	model.events.clear()
	# HUD.GrantTurn after the turn events: drop the used item, run a queued one.
	if granted >= 0 and screen == "match":
		item_bar.on_turn(self, granted)

func update_hud() -> void:
	if screen != "match":
		return
	var limits: Vector2 = model.aim_limits(Match.PLAYER, aim.weapon)
	aim.angle = clampf(aim.angle, limits.x, limits.y)
	var enabled := player_can_act()
	pass_button.disabled = not enabled
	flip_button.disabled = not enabled
	move_left.disabled = not enabled
	move_right.disabled = not enabled
	fire_button.disabled = not enabled
	item_bar.sync(self)
	for index in range(weapon_buttons.size()):
		var button: TextureButton = weapon_buttons[index]
		button.disabled = index == Match.SPECIAL_WEAPON and not model.can_use_special(Match.PLAYER)
		if bool(button.get_meta("activated")) != (index == aim.weapon):
			hud.style_button(button, index == aim.weapon)
	weapon_buttons[Match.SPECIAL_WEAPON].tooltip_text = "%s: liberado no primeiro turno; depois do uso, volta em quatro turnos próprios." % model.weapon_rules(Match.PLAYER, Match.SPECIAL_WEAPON).name
	var displayed_weapon: int = aim.weapon if model.active == Match.PLAYER else cpu.weapon()
	if model.phase == Match.PHASE_FINISHED:
		queue_entries = []
	elif model.phase == Match.PHASE_AIM and model.active == Match.CPU and cpu.plan.is_empty():
		queue_entries = current_order()
	else:
		queue_entries = model.initiative_preview(displayed_weapon)

## Turn order by current readiness only, while the CPU has not chosen a weapon.
## The rule (tie favours the other side) lives in TurnTable.current_order.
func current_order() -> Array:
	return model.current_order()

## State the HUD draws from; HudArt never reads game.gd internals directly.
func hud_state() -> Dictionary:
	return {"power": aim.power, "angle": hud.hud_angle(model, aim.angle, aim.weapon),
		"movement": model.movement_left / maxf(1.0, model.movement_budget()), "gold": maxi(0,int(model.actors[Match.PLAYER].gold_state.gold)), "queue": queue_entries,
		"drag": options.drag_aiming(), "moving": model.phase==Match.PHASE_AIM and model.active==Match.PLAYER and (move_left.is_pressed() or move_right.is_pressed() or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)),
		"player_name": profile.nickname, "weapon": aim.weapon, "aim": aim.angle, "paused_cpu": false}

func _unhandled_key_input(event: InputEvent) -> void:
	if screen == "shop":
		return
	if not event is InputEventKey or event.echo:
		return
	if event.pressed and event.physical_keycode == KEY_ESCAPE:
		if overlays.kind == "options":
			cancel_options()
		elif overlays.kind == "items":
			accept_items()
		elif overlays.is_open():
			if overlays.kind != "result":
				close_overlay()
		elif screen == "menu" and menu != null and menu.popup_open():
			menu.cancel_popup()
		elif screen == "menu":
			show_lobby()
		elif screen == "match":
			show_options()
		return
	if screen == "menu" and menu != null and menu.popup_open():
		return
	if event.pressed and event.physical_keycode == KEY_P and screen == "match" and overlays.kind in ["", "options"]:
		show_pause()
		return
	if event.pressed and event.physical_keycode == KEY_H:
		show_help()
		return
	# F1–F6 press the item buttons (extra; also queues on the other turn).
	if event.pressed and screen == "match" and not overlays.is_open() and event.physical_keycode >= KEY_F1 and event.physical_keycode <= KEY_F6:
		item_bar.key(self, event.physical_keycode - KEY_F1)
		return
	if not player_can_act():
		return
	if event.physical_keycode == KEY_SPACE:
		if event.pressed:
			begin_charge()
		else:
			release_charge()
	elif event.pressed:
		match event.physical_keycode:
			KEY_TAB: cycle_weapon()
			KEY_F8: pass_turn()
			KEY_1: select_weapon(0)
			KEY_2: select_weapon(1)
			KEY_3: select_weapon(2)
			KEY_F: flip()

func close_overlay() -> void:
	overlays.close()

func show_help() -> void:
	overlays.show_help(self)

func show_options() -> void:
	overlays.show_options(self)

func apply_options() -> void:
	sound.set_volume(Options.volume_gain(options.sfx))
	sound.set_music_volume(Options.volume_gain(options.bgm))
	queue_redraw()

func accept_options() -> void:
	if overlays.options_popup != null:
		overlays.options_popup.commit()
	options.save_options()
	close_overlay()

func cancel_options() -> void:
	close_overlay()

func quit_battle_options() -> void:
	cancel_options()
	show_menu()

## A sala grava a carga no painel direito. Não abre o modal Select Item.
func show_items() -> void:
	pass

func items_label() -> String:
	return "Itens (%d/6)" % Items.used_slots(options.items)

func commit_items(next: Array) -> void:
	options.items = Items.sanitize(next)
	options.save_options()
	if menu != null:
		menu.show_loadout(options.items)

## ESC ainda grava se um modal de itens antigo estiver aberto.
func accept_items() -> void:
	commit_items(options.items)
	close_overlay()

func show_pause() -> void:
	overlays.show_pause(self)

func show_result() -> void:
	overlays.show_result(self)

## Margins beside the 800×600 stage. The stage itself draws the classic art.
func _draw_classic_front() -> void:
	var origin_x := (1280.0 - 800.0 * 4.0 / 3.0) * 0.5
	var stage_right := origin_x + 800.0 * 4.0 / 3.0
	draw_rect(Rect2(0, 0, origin_x, 800), Color("6a8dac"))
	draw_rect(Rect2(stage_right, 0, 1280.0 - stage_right, 800), Color("4a446a"))

## Dois mobiles da sala, no nó que fica acima do fundo e atrás dos botões.
## O piloto usa o equipamento do perfil. A CPU fica com o piloto padrão.
func draw_room_figures(canvas: Node2D) -> void:
	if menu == null:
		return
	draw_figure(canvas, RoomChoice.RANDOM if player_random else vehicle, menu.player_anchor, 1, profile.equipped_set())
	draw_figure(canvas, RoomChoice.RANDOM if cpu_random else resolved_cpu_id(), menu.cpu_anchor, -1, {})

func _draw_screen_hud() -> void:
	if screen == "match" and is_instance_valid(screen_hud) and model.terrain != null:
		hud.draw_screen(screen_hud,model,hud_state())

func _draw() -> void:
	if is_instance_valid(screen_hud):
		screen_hud.queue_redraw()
	if screen == "shop":
		draw_rect(Rect2(0,0,1280,800),Color("11223c"))
		return
	if screen == "lobby" or screen == "menu":
		_draw_classic_front()
		return
	if background == null:
		return
	var backdrop: Dictionary = map_background(model.map_id) if model.terrain != null else {}
	if screen == "match" and not options.background:
		# PopupGameOptions "Background: Off" hides the map backdrop.
		draw_rect(Rect2(0, 0, 1280, 800), Color.BLACK)
	elif backdrop.is_empty():
		draw_texture_rect(background, Rect2(0, 0, 1280, 800), false)
	else:
		draw_texture_rect_region(backdrop.texture, Rect2(0, 0, 1280, 800), background_region(backdrop))
	if model.terrain == null:
		return
	var offset := (HudArt.Layout.WORLD.position + Vector2(sin(elapsed * 81.0), cos(elapsed * 74.0)) * shake - rig.position).round()
	draw_set_transform(offset)
	if not model.terrain.map_id.is_empty():
		# Original map: client foreground carries its own crater and blackmask pixels.
		if model.terrain.visual_texture != null:
			draw_texture_rect(model.terrain.visual_texture, model.terrain.visual_rect, false)
	else:
		draw_procedural_terrain()
	# Weather layers draw in world space with their own offset (identity canvas).
	draw_set_transform(Vector2.ZERO)
	weather_art.draw_columns(self, model, offset)
	weather_art.draw_thor(self, model, offset)
	var satellite_sprite = sprite_for(10)
	for satellite in model.satellites.values():
		satellite_sprite.satellite_art.draw_satellite(self,satellite,offset,clampf(float(model.accumulator)/0.05,0,1))
	draw_set_transform(offset)
	for index in range(model.actors.size()):
		art.draw_actor(self, model, index, offset, actor_context(index))
		if art.motion[index].pose == "using_item":
			var body = sprite_for(int(model.actors[index].vehicle))
			if body != null:
				item_art.draw_using(self, body, art.motion[index], int(model.actors[index].facing), offset)
	hud.draw_world(self, model, offset, hud_state())
	draw_projectiles(offset)
	draw_mines(offset)
	draw_set_transform(Vector2.ZERO)
	weather_art.draw_shell_marks(self, model, offset)
	weather_art.draw_beams(self, offset)
	weather_art.draw_particles(self, offset)
	draw_set_transform(offset)
	for effect in effects:
		var body = sprite_for(int(effect.get("vehicle", -1)))
		if body != null:
			body.draw_effect(self, effect, offset)
	item_art.draw_flames(self, offset)
	draw_floating(offset)
	draw_set_transform(Vector2.ZERO)
	draw_offscreen_markers()

## A shell with the native afterimage history keeps draining after it leaves
## the model; the copy is presentation only and never reaches collision.
func collect_lingering(shells_before: Array) -> void:
	for shell in shells_before:
		if not bool(shell.get("launched", false)) or model.projectiles.any(func(live): return is_same(live, shell)):
			continue
		var body = sprite_for(int(shell.get("vehicle", -1)))
		if body != null and body.has_method("leaves_trail") and body.leaves_trail(shell):
			lingering.append({"shell": shell.duplicate(true), "vehicle": int(shell.vehicle), "age": 0.0})

## Shells in flight, in world space. Each shell keeps its weapon (Dual+ mixes
## S1 and S2 in one turn); the beacon has its own art.
func draw_projectiles(offset: Vector2) -> void:
	for sprite in sprites.values():
		if sprite.has_method("begin_projectiles"):
			sprite.begin_projectiles(self)
	for ghost in lingering:
		var ghost_body = sprite_for(int(ghost.vehicle))
		if ghost_body != null:
			ghost_body.draw_lingering(self, ghost, offset)
	draw_set_transform(offset)
	for source_projectile in model.projectiles:
		var projectile: Dictionary = source_projectile.duplicate()
		var blend := clampf(float(model.accumulator)/0.05,0.0,1.0)
		projectile.draw_fraction = blend
		projectile.hit_pos = Vector2(projectile.get("previous_hit_pos",projectile.hit_pos)).lerp(projectile.hit_pos,blend)
		projectile.pos = Vector2(projectile.get("previous_draw_pos",projectile.pos)).lerp(projectile.pos,blend)
		if not projectile.launched:
			continue
		if bool(projectile.get("beacon", false)):
			item_art.draw_beacon(self, projectile, offset)
			draw_set_transform(offset)
			continue
		var shooter := int(model.actors[model.shot_actor].vehicle)
		var body = sprite_for(shooter)
		if body == null:
			continue
		var shell_weapon := int(projectile.get("weapon", model.shot_weapon))
		var color: Color = model.weapon_rules(model.shot_actor, shell_weapon).color
		if Mobiles.generic_trail(shooter) and not body.native_animation:
			var trail: Array = projectile.trail
			for index in range(1, trail.size()):
				draw_line(trail[index - 1], trail[index], Color(color, float(index) / trail.size() * 0.6), 2.0, true)
		body.draw_projectile(self, projectile, shell_weapon, offset)
		draw_set_transform(offset)

func draw_mines(offset: Vector2) -> void:
	var body = sprite_for(7)
	if body != null and body.has_method("draw_placed"):
		var marks: Array = model.mines.duplicate()
		for projectile in model.projectiles:
			if bool(projectile.get("crystal_body", false)):
				marks.append({"pos": projectile.get("hit_pos", projectile.pos), "crystal": true})
		for effect in model.battle_effects:
			if str(effect.kind) == "jd_crystal":
				marks.append(effect)
		body.draw_placed(self, marks, model.actors, offset)

## Rising texts ("QUEDA!") that fade over 1.5 s.
func draw_floating(offset: Vector2) -> void:
	draw_set_transform(offset)
	for item in floating:
		var pos: Vector2 = item.pos + Vector2(-22, -70 - float(item.age) * 34.0)
		draw_string_outline(ui.bold, pos, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, 5, Color(0.05, 0.12, 0.18, 1.0 - float(item.age) / 1.5))
		draw_string(ui.bold, pos, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(item.color, 1.0 - float(item.age) / 1.5))

func draw_procedural_terrain() -> void:
	draw_texture_rect(model.terrain.texture, Rect2(0, 0, 1280, 800), false)
	# Small vegetation details follow the current collision surface.
	for x in range(48, 1240, 31):
		var y: float = model.terrain.surface_at(x)
		if y > 610.0:
			continue
		draw_line(Vector2(x, y), Vector2(x - 3, y - 7), Color("4b8050"), 2.0, true)
		if x % 3 == 0:
			draw_circle(Vector2(x - 3, y - 8), 2.2, Color("f4d5b2"))

func draw_offscreen_markers() -> void:
	# Edge arrows for actors the camera does not show, so the target is never lost.
	var view := HudArt.Layout.WORLD
	for index in range(model.actors.size()):
		var actor: Dictionary = model.actors[index]
		var screen_pos: Vector2 = Vector2(actor.pos) - rig.position + view.position
		if int(actor.hp) <= 0 or view.grow(-10).has_point(screen_pos):
			continue
		var edge := Vector2(clampf(screen_pos.x, 34.0, VIEW_SIZE.x - 34.0), clampf(screen_pos.y, view.position.y + 34.0, view.end.y - 30.0))
		var direction := (screen_pos - edge).normalized()
		if direction == Vector2.ZERO:
			continue
		var tint: Color = Match.VEHICLES[actor.vehicle].color
		var tip := edge + direction * 16.0
		var side := direction.orthogonal() * 10.0
		draw_colored_polygon(PackedVector2Array([tip, edge - side, edge + side]), tint)
		draw_polyline(PackedVector2Array([tip, edge - side, edge + side, tip]), ui.INK, 2.0, true)
		var label := "%s · %dm" % ["Você" if index == Match.PLAYER else "Autômato", int(screen_pos.distance_to(edge) / 10.0)]
		var width: float = ui.bold.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var text_pos := edge - direction * 22.0 + Vector2(-width * 0.5, 5)
		text_pos.x = clampf(text_pos.x, 8.0, VIEW_SIZE.x - width - 8.0)
		draw_string_outline(ui.bold, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, ui.INK)
		draw_string(ui.bold, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tint.lightened(0.25))

func map_background(id: String) -> Dictionary:
	# Client background (mos.img frame 1); source = the whole original raster.
	if id.is_empty():
		return {}
	if not map_backgrounds.has(id):
		var path := Maps.path(Maps.get_map(id), "background")
		var entry := {}
		if ResourceLoader.exists(path):
			var original: Texture2D = load(path)
			entry = {"texture": original, "source": Rect2(Vector2.ZERO, original.get_size()), "density": 1.0}
		map_backgrounds[id] = entry
	return map_backgrounds[id]

func background_region(backdrop: Dictionary) -> Rect2:
	# LevelScene parallax: the 1.6:1 window slides across the background as the
	# camera crosses its range, limited to the pixels the file covers.
	var source: Rect2 = backdrop.source
	var window := Vector2(source.size.x, source.size.x / 1.6)
	if window.y > source.size.y:
		window = Vector2(source.size.y * 1.6, source.size.y)
	var limits := camera_limits()
	var fraction := Vector2.ZERO
	if limits.size.x > 0.0:
		fraction.x = (rig.position.x - limits.position.x) / limits.size.x
	if limits.size.y > 0.0:
		fraction.y = (rig.position.y - limits.position.y) / limits.size.y
	var top_left := source.position + (source.size - window) * fraction
	return Rect2((top_left - source.position) * float(backdrop.density), window * float(backdrop.density))

func camera_limits() -> Rect2:
	return rig.limits(model.terrain if model != null else null)

func clamp_camera(value: Vector2) -> Vector2:
	return rig.fit(model.terrain if model != null else null, value)

func camera_goal() -> Vector2:
	return rig.goal(model)

func update_camera(delta: float) -> void:
	rig.update(delta, model)

## Drag aiming sees the motion and the release before the HUD, so letting go
## over the action bar (or a lost release) still ends the drag.
func _input(event: InputEvent) -> void:
	if not (aim.charging and aim.drag_aiming):
		return
	if event is InputEventMouseMotion:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			release_drag()
		else:
			update_drag(event.position.x, event.relative.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		release_drag()

func _unhandled_input(event: InputEvent) -> void:
	if screen != "match" or overlays.is_open():
		return
	# Drag mode: a left press in the world during the player's aim starts the shot.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and options.drag_aiming() and player_can_act() and HudArt.Layout.in_world(event.position):
		begin_drag(event.position.x)
		dragging = false
		return
	# Drag the world (mouse or touch) to look around; tracking resumes next turn or shot.
	if camera_limits().size == Vector2.ZERO:
		return
	# Touch is emulated as mouse by default; handle only one source to avoid double panning.
	var touch_as_mouse: bool = ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true)
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		# The right (or middle) button always looks around; Drag mode needs it.
		dragging = event.pressed and HudArt.Layout.in_world(event.position)
		pan_mask = {MOUSE_BUTTON_LEFT: MOUSE_BUTTON_MASK_LEFT, MOUSE_BUTTON_RIGHT: MOUSE_BUTTON_MASK_RIGHT, MOUSE_BUTTON_MIDDLE: MOUSE_BUTTON_MASK_MIDDLE}[event.button_index]
	elif event is InputEventScreenTouch and not touch_as_mouse:
		dragging = event.pressed and HudArt.Layout.in_world(event.position)
	elif event is InputEventMouseMotion and dragging:
		# A release consumed by the HUD must not leave the drag stuck on.
		if not (event.button_mask & pan_mask):
			dragging = false
			return
		rig.manual = true
		rig.position = clamp_camera(rig.position - event.relative * options.scroll_factor())
	elif event is InputEventScreenDrag and dragging and not touch_as_mouse:
		rig.manual = true
		rig.position = clamp_camera(rig.position - event.relative * options.scroll_factor())

func draw_figure(canvas: Node2D, kind: int, pos: Vector2, facing: int, equipment: Dictionary) -> void:
	var body = room_random_sprite if kind==RoomChoice.RANDOM else sprite_for(kind)
	if body == null:
		return
	var context := {}
	if not equipment.is_empty():
		context = {"equipment": equipment, "age": elapsed}
	var shot_facing := facing * int(MobileLooks.look(kind).get("room_facing", 1))
	body.draw(canvas, SpritePose.new(pos.round(), MenuScreen.MOBILE_WIDTH, shot_facing, {
		"frame": body.frame_index("idle", elapsed, 0, false),
		"age": elapsed,
		"avatar_context": context,
	}))
