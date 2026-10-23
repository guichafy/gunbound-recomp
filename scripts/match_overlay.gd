extends RefCounted
## Help, options, item selection, pause and result layers (ADR-070). Owns the
## open layer and its popups; the scene reacts to `opened`/`closed` (pause,
## charge, Options button) and the builders below only read the scene.

const Match = preload("res://scripts/match.gd")

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
	if kind == "options" and kind_name != "options":
		options.save_options()
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
	var lines := ["← / → ou A / D        Mover o veículo", "↑ / ↓ ou W / S        Ângulo, 1° por toque", "ESPAÇO                  Segurar carrega a barra; soltar dispara", "Modo Drag (ESC)    Arrastar → no mapa: força; soltar dispara", "TAB  ou  1 / 2 / 3    Trocar o tiro (S1, S2, SS)", "F8  /  F                   Passar o turno  /  virar parado", "ESC  /  P                 Opções  /  pausa", "F1–F6 ou clique       Item da barra (um por turno; SS fica travado)", "Arrastar a tela        Olhar o mapa (botão direito no Drag)"]
	for index in range(lines.size()):
		host.ui.label(card, lines[index], Vector2(32, 86 + index * 28), Vector2(500, 28), 16)
	host.ui.label(card, "Vento 2D e clima mudam a cada rodada (ícones no topo). Colunas\nalteram o tiro: Força, Fraqueza, Espelho, Tornado, Elétrico; Thor\natinge o impacto. Zere a vida ou derrube o adversário para vencer.", Vector2(32, 344), Vector2(500, 70), 14, host.ui.MUTED)
	host.ui.button(card, "ENTENDI", Vector2(32, 424), Vector2(496, 42), host.close_overlay, true)

func show_options(host) -> void:
	if host.screen != "match" or host.model.phase == Match.PHASE_FINISHED:
		return
	open("options")
	options_popup = host.OptionsPopup.new(options)
	options_popup.changed.connect(host.apply_options)
	options_popup.accepted.connect(host.accept_options)
	layer.add_child(options_popup)
	var pause_size := Vector2(84, 30)
	var pause: Button = host.ui.button(options_popup, "PAUSA", options_popup.point(host.OptionsPopup.PAUSE_OFFSET) - pause_size * 0.5, pause_size, host.show_pause)
	pause.add_theme_font_size_override("font_size", 13)
	pause.modulate = Color(1, 1, 1, 0.82)
	pause.tooltip_text = "Pausa, recomeçar ou voltar ao menu (P)"

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
	if host.screen != "match" or host.model.phase == Match.PHASE_FINISHED:
		return
	var card := make(host, "pause")
	host.ui.label(card, "Uma pausa no combate.", Vector2(32, 27), Vector2(496, 55), 30, host.ui.CREAM, true)
	host.ui.label(card, "A partida e o relógio estão pausados.", Vector2(32, 91), Vector2(496, 35), 17, host.ui.MUTED)
	host.ui.button(card, "CONTINUAR", Vector2(32, 160), Vector2(496, 48), host.close_overlay, true)
	host.ui.button(card, "Como jogar", Vector2(32, 226), Vector2(240, 45), host.show_help)
	host.ui.button(card, "Som: " + ("ligado" if not host.sound.muted else "desligado"), Vector2(288, 226), Vector2(240, 45), func(): host.sound.muted = not host.sound.muted; host.show_pause())
	host.ui.button(card, "Recomeçar treino", Vector2(32, 300), Vector2(496, 45), host.start_match)
	host.ui.button(card, "Voltar ao menu", Vector2(32, 366), Vector2(496, 45), host.show_menu)
	host.ui.label(card, "Seu progresso de partidas concluídas fica salvo.", Vector2(32, 438), Vector2(496, 28), 14, host.ui.MUTED)

func show_result(host) -> void:
	if host.screen != "match" or host.model.phase != Match.PHASE_FINISHED:
		return
	var card := make(host, "result")
	var result := "VITÓRIA!" if host.model.winner == Match.PLAYER else ("EMPATE" if host.model.winner == -1 else "A MÁQUINA VENCEU")
	host.ui.label(card, "TREINO CONCLUÍDO", Vector2(32, 24), Vector2(496, 24), 12, host.ui.TEAL, true)
	host.ui.label(card, result, Vector2(32, 72), Vector2(496, 65), 38, host.ui.CREAM, true)
	host.ui.label(card, "Boa mira, %s." % host.profile.nickname if host.model.winner == Match.PLAYER else "Cada cratera ensina. Tente uma nova trajetória.", Vector2(32, 145), Vector2(496, 45), 17, host.ui.MUTED)
	host.ui.panel(card, Vector2(32, 215), Vector2(496, 92), Color("23454d"), 12)
	host.ui.label(card, "+%d XP · %d Gold" % [host.reward,host.gold_reward], Vector2(53, 230), Vector2(340, 35), 24, host.ui.TEAL, true)
	host.ui.label(card, "NÍVEL %d   ·   %d XP TOTAL" % [host.profile.level(), host.profile.xp], Vector2(53, 270), Vector2(450, 24), 14, host.ui.CREAM)
	host.ui.label(card, "%d turnos  ·  %s" % [host.model.total_turns, "progresso salvo neste Mac" if host.profile.last_save_ok else "não foi possível salvar o progresso"], Vector2(32, 324), Vector2(496, 35), 14, host.ui.MUTED)
	host.ui.button(card, "REVANCHE", Vector2(32, 386), Vector2(496, 47), host.start_match, true)
	host.ui.button(card, "Voltar ao menu", Vector2(32, 444), Vector2(496, 33), host.show_menu)
