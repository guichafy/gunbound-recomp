extends Control
## Thor's Hammer result window (REQ-50/ADR-139). Layout from FUN_004c8890
## (panels and rows) and FUN_004d0260 (one row), in the client's 800×600
## virtual pixels; the scene scales the node by 1.6. Every frame is drawn at
## anchor + IMG pivot, as FUN_004ed6a0 does. Contract: RESULT_SCREEN_NATIVE.md.

const ShopArt = preload("res://scripts/classic_shop_art.gd")
const Ranks = preload("res://scripts/classic_ranks.gd")
const GoldTracker = preload("res://scripts/gold_tracker.gd")
const Match = preload("res://scripts/match.gd")
const CATALOG := "res://assets/xfs/result/catalog.json"
const TEAM_A := 0
const TEAM_B := 1
const PANEL := [Vector2(24,48),Vector2(403,48)]
const ROW_X := [52,431]
const ROW_TOP := 151
const ROW_STEP := 66
const ROW_LAST := 414
const OK_AT := Vector2(671,441)
const OK_ENTRY := "b_result_confirm"
const GUILD_COLOR := Color(1,0,0)  # RGB565 0xF800
const CPU_NAME := "CPU"

var art
var ops: Array = []
var notice := ""
var ok_button: TextureButton
# Draw commands keep only the RID: hold the rank AtlasTextures for the frame.
var rank_icons: Dictionary = {}

## Frame of a team's panel: WIN (1) when that team won, LOSE (0) otherwise.
## A draw (winner outside 0/1) leaves both panels on LOSE.
static func panel_frame(team: int, winner_team: int) -> int:
	return 1 if team == winner_team else 0

## Row tops: 151 + 66·n while the top stays at or above 414 (four rows).
static func row_tops(count: int) -> Array:
	var result: Array = []
	var y := ROW_TOP
	while result.size() < count and y <= ROW_LAST:
		result.append(y)
		y += ROW_STEP
	return result

## Characters of a printf field, drawn from `base`; spaces advance only.
static func number_ops(text: String, count: int, at: Vector2, advance: int, base: int, minus: int) -> Array:
	var result: Array = []
	for index in range(mini(count,text.length())):
		var character := text[index]
		if character == " ":
			continue
		var frame := minus if character == "-" else base+text.unicode_at(index)-48
		result.append(["frame","numfont:%d" % frame,at+Vector2(index*advance,0)])
	return result

## Draw operations of one FUN_004d0260 row.
static func row_ops(team: int, y: int, row: Dictionary) -> Array:
	var x: int = ROW_X[team]
	var result: Array = [["frame","result_back:%d" % (2 if team == TEAM_A else 3),Vector2(x,y)]]
	result.append(["rank",int(row.get("rank",Ranks.CHICK)),Vector2(x+41,y+17)])
	var guild := str(row.get("guild",""))
	if not guild.is_empty():
		result.append(["text","%s[%3d/%3d]" % [guild,int(row.get("guild_rank",0)),int(row.get("guild_total",0))],Vector2(x+58,y+16),GUILD_COLOR])
	result.append(["text",str(row.get("name","")),Vector2(x+58,y+30),Color.BLACK])
	var points := int(row.get("points",0))
	result.append_array(number_ops("%3d" % points,3,Vector2(x+254,y+8),9,80 if points >= 0 else 90,102))
	result.append(["frame","numfont:%d" % (100 if points >= 0 else 101),Vector2(x+281,y+8)])
	var gold := int(row.get("gold",0))
	var a := team == TEAM_A
	result.append_array(number_ops("%5d" % gold,5,Vector2(x+195,y+26),16,103 if a else 114,224 if a else 225))
	result.append(["frame","numfont:%d" % (113 if a else 124),Vector2(x+274,y+26)])
	return result

## Whole window: panel A, its rows, panel B, its rows (FUN_004c8890 order).
static func layout(teams: Array, winner_team: int) -> Array:
	var result: Array = []
	for team in [TEAM_A,TEAM_B]:
		result.append(["frame","result_back:%d" % panel_frame(team,winner_team),PANEL[team]])
		var rows: Array = teams[team]
		var tops := row_tops(rows.size())
		for index in range(tops.size()):
			result.append_array(row_ops(team,tops[index],rows[index]))
	return result

## Training rows: player on team A, CPU on team B, as in the room. P shows
## the port's XP reward; the CPU has no account, so it scores 0P as Chick.
static func training_teams(model, profile, reward: int, gold_reward: int) -> Array:
	return [[{"name":profile.nickname,"rank":profile.rank,"points":reward,"gold":gold_reward}],
		[{"name":CPU_NAME,"rank":Ranks.CHICK,"points":0,"gold":GoldTracker.player_reward(model,Match.CPU)}]]

static func winner_team(model) -> int:
	return TEAM_A if model.winner == Match.PLAYER else (TEAM_B if model.winner == Match.CPU else -1)

func _init(teams: Array = [[],[]], winner: int = -1, confirm: Callable = Callable(), catalog: String = CATALOG) -> void:
	name = "ResultWindow"
	art = ShopArt.new(catalog,"res://.tools/no-result-hd/")
	art.use_hd = false
	size = Vector2(800,500)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ops = layout(teams,winner)
	ok_button = TextureButton.new()
	ok_button.name = "ResultOK"
	ok_button.position = OK_AT
	ok_button.ignore_texture_size = true
	ok_button.stretch_mode = TextureButton.STRETCH_SCALE
	ok_button.focus_mode = Control.FOCUS_NONE
	# EPA: ready 0, mouse 1, push 2, disable 3.
	ok_button.texture_normal = art.texture(OK_ENTRY+":0")
	ok_button.texture_hover = art.texture(OK_ENTRY+":1")
	ok_button.texture_pressed = art.texture(OK_ENTRY+":2")
	ok_button.texture_disabled = art.texture(OK_ENTRY+":3")
	ok_button.tooltip_text = "Voltar à sala"
	if confirm.is_valid():
		ok_button.pressed.connect(confirm)
	add_child(ok_button)
	ok_button.size = art.size(OK_ENTRY+":0")

func _draw() -> void:
	for op in ops:
		match op[0]:
			"frame":
				art.draw(self,op[1],op[2])
			"rank":
				if not rank_icons.has(op[1]):
					rank_icons[op[1]] = Ranks.icon(op[1],false,false)
				draw_texture_rect(rank_icons[op[1]],Rect2(op[2],Vector2(15,25)),false)
			"text":
				art.draw_text(self,op[1],op[2],op[3])
	if not notice.is_empty():
		draw_string(ThemeDB.fallback_font,Vector2(26,446),notice,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(1,0.86,0.6))
