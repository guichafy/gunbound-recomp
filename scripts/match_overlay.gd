extends RefCounted
## Help, native battle options, item selection and result layers. Owns the
## open layer and its popups; the scene reacts to `opened`/`closed` (pause,
## charge, Options button) and the builders below only read the scene.

const Match = preload("res://scripts/match.gd")
const ResultWindow = preload("res://scripts/classic_result.gd")

signal opened(kind: String)
signal closed

var root: Control
var options
var kind := ""
var layer: Control = null
var options_popup: Control = null
var items_popup: Control = null

## A new screen root: nothing is open on it.
func attach(new_root: Control, saved_options) -> void:
	root = new_root
	options = saved_options
	layer = null
	kind = ""
	options_popup = null

func is_open() -> bool:
	return layer != null

## Full-screen layer that pauses the match and blocks the HUD below it.
func open(kind_name: String) -> Control:
	if kind == "options" and options_popup != null:
		options_popup.restore()
	if is_instance_valid(layer):
		root.remove_child(layer)
		layer.queue_free()
	kind = kind_name
	layer = Control.new()
	layer.size = Vector2(1280, 800)
	root.add_child(layer)
	options_popup = null
	opened.emit(kind_name)
	return layer

func make(host, kind_name: String) -> Panel:
	open(kind_name)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 800)
	shade.color = Color(0.025, 0.09, 0.12, 0.73)
	layer.add_child(shade)
	return host.ui.panel(layer, Vector2(360, 155), Vector2(560, 490), host.ui.INK, 22)

func close() -> void:
	if kind == "options" and options_popup != null:
		options_popup.restore()
	if is_instance_valid(layer):
		root.remove_child(layer)
		layer.queue_free()
	layer = null
	kind = ""
	options_popup = null
	closed.emit()

func show_help(host) -> void:
	var card := make(host, "help")
	host.ui.label(card, "Como jogar", Vector2(32, 25), Vector2(490, 50), 32, host.ui.CREAM, true)
	var lines := ["← / → ou A / D        Mover o veículo", "↑ / ↓ ou W / S        Ângulo, 1° por toque", "ESPAÇO                  Segurar carrega a barra; soltar dispara", "Modo Drag (ESC)    Arrastar → no mapa: força; soltar dispara", "TAB  ou  1 / 2 / 3    Trocar o tiro (S1, S2, SS)", "F8  /  F                   Passar o turno  /  virar parado", "ESC  /  P                 Menu clássico (OK confirma, X cancela)", "F1–F6 ou clique       Item da barra (um por turno; SS fica travado)", "Arrastar a tela        Olhar o mapa (botão direito no Drag)"]
	for index in range(lines.size()):
		host.ui.label(card, lines[index], Vector2(32, 86 + index * 28), Vector2(500, 28), 16)
	host.ui.label(card, "Vento 2D e clima mudam a cada rodada (ícones no topo). Colunas\nalteram o tiro: Força, Fraqueza, Espelho, Tornado, Elétrico; Thor\natinge o impacto. Zere a vida ou derrube o adversário para vencer.", Vector2(32, 344), Vector2(500, 70), 14, host.ui.MUTED)
	host.ui.button(card, "ENTENDI", Vector2(32, 424), Vector2(496, 42), host.close_overlay, true)

func show_options(host) -> void:
	if host.screen != "match" or host.model.phase == Match.PHASE_FINISHED:
		return
	if kind == "options":
		return
	open("options")
	options_popup = host.OptionsPopup.new(options)
	options_popup.changed.connect(host.apply_options)
	options_popup.accepted.connect(host.accept_options)
	options_popup.cancelled.connect(host.cancel_options)
	options_popup.quit_requested.connect(host.quit_battle_options)
	layer.add_child(options_popup)

## Menu: PopupSelectItem over a shade; Accept or ESC saves the loadout.
func show_items(host) -> void:
	if host.screen != "menu":
		return
	open("items")
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 800)
	shade.color = Color(0.025, 0.09, 0.12, 0.55)
	layer.add_child(shade)
	items_popup = host.SelectItemPopup.new(options, host.item_art)
	items_popup.accepted.connect(host.accept_items)
	layer.add_child(items_popup)

func show_pause(host) -> void:
	# Compatibility for callers/captures; there is only one battle menu.
	show_options(host)

## Original result window (REQ-50/ADR-139): drawn straight over the battle,
## no shade; the transparent layer blocks the HUD, as the client removes its
## buttons. OK returns to the room (adaptation: the 0x3f8 handler is unproven).
func show_result(host) -> void:
	if host.screen != "match" or host.model.phase != Match.PHASE_FINISHED:
		return
	open("result")
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var window = ResultWindow.new(ResultWindow.training_teams(host.model, host.profile, host.reward, host.gold_reward), ResultWindow.winner_team(host.model), host.show_menu)
	window.scale = Vector2(1.6, 1.6)
	if not host.profile.last_save_ok:
		window.notice = "Não foi possível salvar o progresso."
	layer.add_child(window)
