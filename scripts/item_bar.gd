extends RefCounted
## EquippedButtonBar in the battle HUD and HUD.UseItemAction / GrantTurn /
## LockItem. Presentation and input only: match.gd validates and applies items.

const Match = preload("res://scripts/match.gd")
const Items = preload("res://scripts/items.gd")
const HudArt = preload("res://scripts/hud_art.gd")

# Native header tray:501,2, six36px slots. Used buttons compact immediately.
const BAR_OFFSET := Vector2(501,2)
const STATUS_SIZE := Vector2(217,38)

var art
var buttons: Array = []
var lock_rect: TextureRect
# Slot clicked during the other turn (used at the next own turn).
var queued := -1
# Slot consumed on this own turn. It leaves the bar immediately; the flag
# only remembers which button was used until the next GrantTurn.
var removal := -1
# EquippedButtonBar.Disable after a use, until the next own GrantTurn.
var disabled_until_turn := false

func _init(item_art) -> void:
	art = item_art

func build(host, parent: Control) -> void:
	buttons.clear()
	queued = -1
	removal = -1
	disabled_until_turn = false
	var items: Array = host.model.actors[Match.PLAYER].items
	for slot in range(items.size()):
		var id: String = items[slot].id
		var button := TextureButton.new()
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.focus_mode = Control.FOCUS_NONE
		button.size = Vector2(71 if Items.slots(id)==2 else 35,31) * HudArt.K
		button.tooltip_text = "%s · atraso %d (F%d)" % [Items.definition(id).name, roundi(Items.delay(id)), slot + 1]
		button.set_meta("slot", slot)
		art.style_button(button, id, false,true)
		button.pressed.connect(func(): press(host, slot))
		parent.add_child(button)
		buttons.append(button)
	lock_rect = TextureRect.new()
	lock_rect.texture = art.region("MatchStatus.png", Rect2(Vector2.ZERO, STATUS_SIZE))
	lock_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_rect.stretch_mode = TextureRect.STRETCH_SCALE
	lock_rect.position = Vector2(500,1)*HudArt.K
	lock_rect.size = Vector2(217,38)*HudArt.K
	lock_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	lock_rect.tooltip_text = "Ignorância: itens travados"
	lock_rect.visible = false
	parent.add_child(lock_rect)
	layout(host)

## Visible slots in bar order. A used item leaves as soon as it is consumed.
func visible_slots(host) -> Array:
	var result: Array = []
	var items: Array = host.model.actors[Match.PLAYER].items
	for slot in range(mini(items.size(), buttons.size())):
		if not bool(items[slot].used):
			result.append(slot)
	return result

## EquippedButtonBar.RealocateEquippedItems.
func layout(host) -> void:
	var x := BAR_OFFSET.x
	var shown := visible_slots(host)
	for slot in range(buttons.size()):
		var button: TextureButton = buttons[slot]
		button.visible = slot in shown
		if button.visible:
			button.position = Vector2(x, BAR_OFFSET.y)*HudArt.K
			x += 36.0*Items.slots(host.model.actors[Match.PLAYER].items[slot].id)

## HUD.UseItemAction.
func press(host, slot: int) -> void:
	if host.screen != "match" or host.paused or slot < 0 or slot >= buttons.size():
		return
	var model = host.model
	var items: Array = model.actors[Match.PLAYER].items
	if slot >= items.size() or model.phase == Match.PHASE_FINISHED or bool(items[slot].used) or blocked(host):
		return
	if host.player_can_act():
		if host.use_item(slot):
			removal = slot
			queued = -1
			disabled_until_turn = true
			layout(host)
		return
	# Not this mobile's turn: toggle the activated face to use it at the turn start.
	queued = -1 if queued == slot else slot

## Bar disabled: Ignorance, or an item was used since the last own turn began.
func blocked(host) -> bool:
	return host.model.items_locked() or disabled_until_turn

## HUD.GrantTurn: remove the used button, unlock, and run the queued use.
func on_turn(host, actor: int) -> void:
	if actor != Match.PLAYER:
		return
	removal = -1
	disabled_until_turn = false
	layout(host)
	if queued >= 0:
		var slot := queued
		queued = -1
		press(host, slot)

## F1–F6 (extra, ADR-058): the n-th visible button.
func key(host, position: int) -> void:
	var shown := visible_slots(host)
	if position >= 0 and position < shown.size():
		press(host, shown[position])

func sync(host) -> void:
	#4cef06 resets HUD selection on Eclipse entry. Locked input cannot
	# create a new queue, so clearing during sync also covers CPU turn chains.
	var native_climate: bool = host.model.weather.get("is_native")==true
	if native_climate and host.model.items_locked():queued=-1
	if lock_rect!=null:
		lock_rect.tooltip_text="Eclipse: itens travados" if native_climate else "Ignorância: itens travados"
	if buttons.is_empty():
		if lock_rect != null:
			lock_rect.visible = host.model.items_locked()
		return
	layout(host)
	var items: Array = host.model.actors[Match.PLAYER].items
	var locked := blocked(host)
	var finished: bool = host.model.phase == Match.PHASE_FINISHED
	# A match restarted without this loadout leaves extra buttons: hide them.
	for slot in range(items.size(), buttons.size()):
		buttons[slot].visible = false
	for slot in range(mini(items.size(), buttons.size())):
		var button: TextureButton = buttons[slot]
		var activated := slot == queued or slot == removal
		if bool(button.get_meta("activated")) != activated:
			art.style_button(button, items[slot].id, activated,true)
		button.disabled = finished or (locked and not activated) or bool(items[slot].used)
	lock_rect.visible = host.model.items_locked()
