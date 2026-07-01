extends Control

# ════════════════════════════════════════════════════════════
#  CHEMIA — Battle Scene (rewritten)
#  Portrait 1080×1920, canvas_items stretch
# ════════════════════════════════════════════════════════════

const SC_MAIN := "res://main_menu.tscn"

# ── AP ────────────────────────────────────────────────────
const MAX_AP     := 5
const AP_RECOVER := 2
const START_AP   := 5
const START_HAND := 4

# ── Ultimate ──────────────────────────────────────────────
const MAX_GAUGE := 100

# ── Card database ─────────────────────────────────────────
const CARD_DB := {
	# Element cards — no AP cost, combined to create Reaction Cards
	"H":  {"type":"element","symbol":"H", "name":"Hydrogen","color":Color(0.50,0.85,1.00)},
	"O":  {"type":"element","symbol":"O", "name":"Oxygen",  "color":Color(0.40,0.90,0.70)},
	"Na": {"type":"element","symbol":"Na","name":"Sodium",  "color":Color(1.00,0.85,0.30)},
	"Cl": {"type":"element","symbol":"Cl","name":"Chlorine","color":Color(0.70,1.00,0.40)},
	"Fe": {"type":"element","symbol":"Fe","name":"Iron",    "color":Color(0.75,0.65,0.55)},
	"C":  {"type":"element","symbol":"C", "name":"Carbon",  "color":Color(0.60,0.60,0.75)},
	# Support cards — cost AP, go to Discard after use
	"Draw2":     {"type":"support","name":"Draw 2",    "desc":"จั่วการ์ด 2 ใบ","ap":1,"color":Color(0.60,0.40,1.00)},
	"RecoverAP": {"type":"support","name":"Recover AP","desc":"ฟื้นฟู AP +2",  "ap":1,"color":Color(0.30,0.80,1.00)},
	# Reaction cards — created mid-battle, vanish after use (not to Discard)
	"Water": {"type":"reaction","name":"Water","symbol":"H₂O","desc":"ฟื้นฟู HP +20",    "ap":1,"tier":1,"color":Color(0.30,0.70,1.00)},
	"Salt":  {"type":"reaction","name":"Salt", "symbol":"NaCl","desc":"Shield +20",       "ap":1,"tier":1,"color":Color(0.95,0.95,0.65)},
	"Rust":  {"type":"reaction","name":"Rust", "symbol":"Fe₂O₃","desc":"วางพิษ +5/เทิร์น","ap":2,"tier":2,"color":Color(0.75,0.45,0.20)},
}

# ── Recipes ───────────────────────────────────────────────
const RECIPES := {
	"H+O":   "Water",
	"Na+Cl": "Salt",
	"Fe+O":  "Rust",
}

# ── Character ─────────────────────────────────────────────
const CHARACTER := {
	"name":         "Alchemist",
	"max_hp":       100,
	"passive":      "Reaction Master",
	"skill_name":   "Power Strike",
	"skill_damage": 40,
	"skill_ap":     2,
	"skill_cd":     2,
	"ult_name":     "Element Burst",
	"ult_damage":   60,
}

# ════════════════════════════════════════════════════════════
#  STATE
# ════════════════════════════════════════════════════════════
var _deck:    Array = []
var _hand:    Array = []
var _discard: Array = []
var _reshuffle_count := 0

var _player_hp:          int = 0
var _player_shield:      int = 0
var _player_weak:        int = 0
var _player_vulnerable:  int = 0

var _enemy_data:          Dictionary = {}
var _enemy_hp:            int = 0
var _enemy_poison:        int = 0
var _enemy_weak:          int = 0
var _enemy_vulnerable:    int = 0

var _ap:                  int = START_AP
var _ult_gauge:           int = 0
var _reaction_gauge_used: bool = false  # once per turn

var _main_action_done: bool = false
var _ult_used:         bool = false
var _player_turn:      bool = true
var _skill_cd:         int  = 0
var _is_defending:     bool = false
var _current_stage:    int  = 1
var _battle_over:      bool = false

# Reaction element selection (click-to-select, no drag)
var _selected_elem: String = ""

# ── UI node refs ──────────────────────────────────────────
var _msg_lbl:          Label
var _turn_lbl:         Label
var _ap_lbl:           Label
var _gauge_bar:        ColorRect
var _gauge_lbl:        Label
var _player_hp_bar:    ColorRect
var _player_hp_lbl:    Label
var _shield_lbl:       Label
var _enemy_name_lbl:   Label
var _enemy_hp_bar:     ColorRect
var _enemy_hp_lbl:     Label
var _enemy_status_lbl: Label
var _hand_container:   HBoxContainer
var _deck_lbl:         Label
var _discard_lbl:      Label
var _stage_lbl:        Label
var _react_hint:       Label
var _btn_attack:       Button
var _btn_defend:       Button
var _btn_skill:        Button
var _btn_ult:          Button
var _btn_end:          Button

# ── Colors ────────────────────────────────────────────────
const C_BG     := Color(0.04, 0.045, 0.10, 1.0)
const C_PANEL  := Color(0.07, 0.09,  0.17, 1.0)
const C_BORDER := Color(0.22, 0.50,  0.90, 0.25)
const C_TEXT   := Color(0.90, 0.93,  1.00, 1.0)
const C_SUB    := Color(0.55, 0.68,  0.90, 0.75)
const C_GOLD   := Color(1.00, 0.82,  0.25, 1.0)
const C_HP     := Color(0.25, 0.85,  0.45, 1.0)
const C_ENEMY  := Color(0.95, 0.35,  0.35, 1.0)
const C_AP     := Color(0.35, 0.72,  1.00, 1.0)
const C_GAUGE  := Color(1.00, 0.75,  0.25, 1.0)

# ════════════════════════════════════════════════════════════
#  ENTRY
# ════════════════════════════════════════════════════════════
func _ready() -> void:
	_player_hp = CHARACTER["max_hp"]
	_build_ui()
	_create_enemy()
	_build_deck()
	_draw_n(START_HAND)
	_refresh_ui()
	_msg("✨ เริ่มการต่อสู้! ผสมธาตุเพื่อสร้างปฏิกิริยา")

# ════════════════════════════════════════════════════════════
#  UI BUILD
# ════════════════════════════════════════════════════════════
func _flat(col: Color, border: Color = Color(0,0,0,0), r: int = 8, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.corner_radius_top_left     = r; sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_right = r; sb.corner_radius_bottom_left  = r
	sb.border_width_left = bw; sb.border_width_right  = bw
	sb.border_width_top  = bw; sb.border_width_bottom = bw
	return sb

func _mk_label(txt: String, fs: int, col: Color, parent: Control,
		pos: Vector2, sz: Vector2 = Vector2.ZERO, center: bool = false) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	if sz != Vector2.ZERO: l.size = sz
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if center: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_topbar()
	_build_enemy_panel()
	_build_player_panel()
	_build_react_hint()
	_build_hand_panel()
	_build_action_row()
	_build_message_bar()

# ── Top bar ───────────────────────────────────────────────
func _build_topbar() -> void:
	var bar := Panel.new()
	bar.size = Vector2(1152, 44)
	bar.add_theme_stylebox_override("panel", _flat(Color(0.03,0.04,0.10,0.96), C_BORDER, 0, 1))
	add_child(bar)

	_stage_lbl = _mk_label("Stage 1", 13, C_SUB, bar, Vector2(14, 13))
	_turn_lbl  = _mk_label("เทิร์นของคุณ", 14, C_GOLD, bar, Vector2(426, 13), Vector2(300, 18), true)

	var back := Button.new()
	back.text = "✕  ออก"
	back.size = Vector2(90, 36)
	back.position = Vector2(1050, 4)
	back.add_theme_font_size_override("font_size", 13)
	for s in ["normal","hover","pressed","focus"]:
		back.add_theme_stylebox_override(s, _flat(Color(0,0,0,0), Color(0,0,0,0)))
	back.add_theme_color_override("font_color", C_SUB)
	back.pressed.connect(_go_back)
	bar.add_child(back)

# ── Enemy panel ────────────────────────────────────────────
func _build_enemy_panel() -> void:
	var ep := Panel.new()
	ep.size = Vector2(520, 340)
	ep.position = Vector2(0, 44)
	ep.add_theme_stylebox_override("panel", _flat(Color(0,0,0,0)))
	add_child(ep)

	# Enemy sprite circle
	var circle := Panel.new()
	circle.size = Vector2(130, 130)
	circle.position = Vector2(195, 16)
	circle.add_theme_stylebox_override("panel", _flat(Color(0.14,0.06,0.06,1.0), Color(0.8,0.3,0.3,0.45), 65, 2))
	ep.add_child(circle)
	var sp_lbl := Label.new()
	sp_lbl.text = "👾"
	sp_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	sp_lbl.add_theme_font_size_override("font_size", 52)
	sp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(sp_lbl)

	_enemy_name_lbl = _mk_label("", 16, C_TEXT, ep, Vector2(14, 158))

	# Enemy HP bar bg
	var ehb_bg := ColorRect.new()
	ehb_bg.color = Color(1,1,1,0.08)
	ehb_bg.size = Vector2(490, 13)
	ehb_bg.position = Vector2(14, 182)
	ep.add_child(ehb_bg)

	_enemy_hp_bar = ColorRect.new()
	_enemy_hp_bar.color = C_ENEMY
	_enemy_hp_bar.size = Vector2(490, 13)
	_enemy_hp_bar.position = Vector2(14, 182)
	ep.add_child(_enemy_hp_bar)

	_enemy_hp_lbl = _mk_label("", 12, C_ENEMY, ep, Vector2(14, 198))
	_enemy_status_lbl = _mk_label("", 12, Color(0.9,0.6,0.3), ep, Vector2(14, 218))

	# Enemy action hint
	_mk_label("⚠ ศัตรูโจมตีเมื่อสิ้นเทิร์น", 10, Color(1,1,1,0.25), ep, Vector2(14, 244))

# ── Player status panel ────────────────────────────────────
func _build_player_panel() -> void:
	var pp := Panel.new()
	pp.size = Vector2(604, 340)
	pp.position = Vector2(548, 44)
	pp.add_theme_stylebox_override("panel", _flat(C_PANEL, C_BORDER, 0, 1))
	add_child(pp)

	_mk_label(CHARACTER["name"], 14, C_TEXT, pp, Vector2(14, 10))

	# HP bar bg
	var phb_bg := ColorRect.new()
	phb_bg.color = Color(1,1,1,0.08)
	phb_bg.size = Vector2(380, 13)
	phb_bg.position = Vector2(14, 34)
	pp.add_child(phb_bg)

	_player_hp_bar = ColorRect.new()
	_player_hp_bar.color = C_HP
	_player_hp_bar.size = Vector2(380, 13)
	_player_hp_bar.position = Vector2(14, 34)
	pp.add_child(_player_hp_bar)

	_player_hp_lbl = _mk_label("", 12, C_HP, pp, Vector2(402, 30))
	_shield_lbl    = _mk_label("", 12, Color(0.7,0.9,1.0), pp, Vector2(14, 56))

	# AP display (dots)
	_ap_lbl = _mk_label("", 22, C_AP, pp, Vector2(14, 76))
	_mk_label("AP", 10, C_SUB, pp, Vector2(14, 106))

	# Ultimate gauge bar bg
	var gb_bg := ColorRect.new()
	gb_bg.color = Color(1,1,1,0.07)
	gb_bg.size = Vector2(250, 14)
	gb_bg.position = Vector2(100, 80)
	pp.add_child(gb_bg)

	_gauge_bar = ColorRect.new()
	_gauge_bar.color = C_GAUGE
	_gauge_bar.size = Vector2(0, 14)
	_gauge_bar.position = Vector2(100, 80)
	pp.add_child(_gauge_bar)

	_gauge_lbl = _mk_label("", 11, C_GOLD, pp, Vector2(100, 98))

	# Deck / Discard
	_deck_lbl    = _mk_label("", 12, C_SUB,              pp, Vector2(14, 130))
	_discard_lbl = _mk_label("", 12, Color(0.6,0.5,0.4), pp, Vector2(160, 130))

# ── Reaction hint bar ──────────────────────────────────────
func _build_react_hint() -> void:
	var rb := Panel.new()
	rb.size = Vector2(1152, 30)
	rb.position = Vector2(0, 384)
	rb.add_theme_stylebox_override("panel", _flat(Color(0.12,0.10,0.04,0.95), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.3), 0, 1))
	rb.visible = false
	add_child(rb)
	_react_hint = _mk_label("", 12, C_GOLD, rb, Vector2(0,7), Vector2(1152,16), true)

# ── Hand area ──────────────────────────────────────────────
func _build_hand_panel() -> void:
	var hp := Panel.new()
	hp.size = Vector2(1152, 148)
	hp.position = Vector2(0, 414)
	hp.add_theme_stylebox_override("panel", _flat(Color(0.04,0.05,0.10,0.92), C_BORDER, 0, 1))
	add_child(hp)

	_mk_label("HAND", 10, C_SUB, hp, Vector2(14, 6))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(8, 24)
	scroll.size = Vector2(1136, 118)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	hp.add_child(scroll)

	_hand_container = HBoxContainer.new()
	_hand_container.add_theme_constant_override("separation", 8)
	_hand_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_hand_container)

# ── Action buttons row ─────────────────────────────────────
func _build_action_row() -> void:
	var row_y := 562.0
	var defs := [
		["Attack",   "⚔ Attack\n1 AP",    Color(0.95,0.35,0.35)],
		["Defend",   "🛡 Defend\n1 AP",    Color(0.35,0.65,1.00)],
		["Skill",    "⚡ Skill\n2 AP",     Color(0.80,0.50,1.00)],
		["Ultimate", "💥 Ultimate\nGauge", Color(1.00,0.75,0.25)],
		["EndTurn",  "▶ End Turn",         Color(0.55,0.70,0.55)],
	]
	var bw := 180.0
	var gap := 14.0
	var total := defs.size() * bw + (defs.size()-1) * gap
	var sx := (1152.0 - total) / 2.0

	for i in defs.size():
		var id  := defs[i][0]; var txt := defs[i][1]; var col: Color = defs[i][2]
		var btn := Button.new()
		btn.text = txt
		btn.size = Vector2(bw, 62)
		btn.position = Vector2(sx + i*(bw+gap), row_y)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_stylebox_override("normal",   _flat(Color(col.r*0.12,col.g*0.12,col.b*0.18,1.0), Color(col.r,col.g,col.b,0.45), 10, 1))
		btn.add_theme_stylebox_override("hover",    _flat(Color(col.r*0.22,col.g*0.22,col.b*0.32,1.0), Color(col.r,col.g,col.b,0.85), 10, 2))
		btn.add_theme_stylebox_override("pressed",  _flat(Color(col.r*0.08,col.g*0.08,col.b*0.12,1.0), Color(col.r,col.g,col.b,1.00), 10, 2))
		btn.add_theme_stylebox_override("disabled", _flat(Color(0.09,0.10,0.14,1.0), Color(0.3,0.3,0.4,0.2), 10, 1))
		btn.add_theme_color_override("font_color",          C_TEXT)
		btn.add_theme_color_override("font_color_disabled", Color(0.35,0.38,0.48))
		add_child(btn)
		match id:
			"Attack":   _btn_attack = btn; btn.pressed.connect(_on_attack)
			"Defend":   _btn_defend = btn; btn.pressed.connect(_on_defend)
			"Skill":    _btn_skill  = btn; btn.pressed.connect(_on_skill)
			"Ultimate": _btn_ult    = btn; btn.pressed.connect(_on_ultimate)
			"EndTurn":  _btn_end    = btn; btn.pressed.connect(_on_end_turn)

# ── Message bar ────────────────────────────────────────────
func _build_message_bar() -> void:
	var mb := Panel.new()
	mb.size = Vector2(1152, 24)
	mb.position = Vector2(0, 624)
	mb.add_theme_stylebox_override("panel", _flat(Color(0.03,0.04,0.08,0.97)))
	add_child(mb)

	_msg_lbl = Label.new()
	_msg_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_msg_lbl.add_theme_font_size_override("font_size", 13)
	_msg_lbl.add_theme_color_override("font_color", C_TEXT)
	_msg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mb.add_child(_msg_lbl)

# ════════════════════════════════════════════════════════════
#  GAME SETUP
# ════════════════════════════════════════════════════════════
func _create_enemy() -> void:
	if _current_stage % 5 == 0:
		_enemy_data = {"name":"Boss Chimera","hp":300,"attack":25,"type":"boss"}
	else:
		var pool := [
			{"name":"Slime",  "hp":100,"attack":10,"type":"poison"},
			{"name":"Goblin", "hp":80, "attack":20,"type":"attack"},
			{"name":"Knight", "hp":150,"attack":12,"type":"tank"},
		]
		_enemy_data = pool.pick_random()
	_enemy_hp = _enemy_data["hp"]

func _build_deck() -> void:
	# Default 20-card deck: 16 elements + 4 supports
	_deck = []
	for _i in 4: _deck.append("H")
	for _i in 4: _deck.append("O")
	for _i in 3: _deck.append("Na")
	for _i in 3: _deck.append("Cl")
	for _i in 2: _deck.append("Fe")
	for _i in 2: _deck.append("Draw2")
	for _i in 2: _deck.append("RecoverAP")
	_deck.shuffle()
	_discard = []
	_reshuffle_count = 0

# ════════════════════════════════════════════════════════════
#  DECK / DRAW
# ════════════════════════════════════════════════════════════
func _draw_n(n: int) -> void:
	for _i in n:
		if _deck.is_empty():
			_reshuffle()
			if _deck.is_empty():
				break
		var idx := randi() % _deck.size()
		_hand.append(_deck[idx])
		_deck.remove_at(idx)
	_refresh_hand()

func _draw_one() -> void:
	if _deck.is_empty():
		_reshuffle()
		if _deck.is_empty():
			return
	var idx := randi() % _deck.size()
	_hand.append(_deck[idx])
	_deck.remove_at(idx)
	_refresh_hand()

func _reshuffle() -> void:
	if _discard.is_empty():
		return
	_reshuffle_count += 1
	_deck = _discard.duplicate()
	_discard.clear()
	_deck.shuffle()
	_msg("🔀 สับเด็คใหม่ (ครั้งที่ %d)" % _reshuffle_count)

# ════════════════════════════════════════════════════════════
#  HAND RENDERING
# ════════════════════════════════════════════════════════════
func _refresh_hand() -> void:
	for c in _hand_container.get_children():
		_hand_container.remove_child(c)
		c.queue_free()
	for i in _hand.size():
		var id: String = _hand[i]
		var data: Dictionary = CARD_DB.get(id, {})
		if data.is_empty(): continue
		_hand_container.add_child(_make_card_node(id, data, i))

func _make_card_node(id: String, data: Dictionary, idx: int) -> Control:
	var ctype: String = data.get("type", "element")
	var col:   Color  = data.get("color", Color(0.5,0.5,0.6))
	var selected := (_selected_elem == id and ctype == "element")

	var border_a := 0.9 if selected else 0.4
	var bg_r     := 0.28 if selected else 0.10
	var bw       := 2 if selected else 1
	var panel    := Panel.new()
	panel.custom_minimum_size = Vector2(112, 110)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel",
		_flat(Color(col.r*bg_r, col.g*bg_r, col.b*(bg_r+0.06), 1.0),
			  Color(col.r, col.g, col.b, border_a), 16, bw))

	# Type tag
	var tag_txt: String
	match ctype:
		"element":  tag_txt = "ELEMENT"
		"reaction": tag_txt = "TIER %d  •  %d AP" % [data.get("tier",1), data.get("ap",1)]
		"support":  tag_txt = "SUPPORT  •  %d AP" % data.get("ap",1)
	var tag := Label.new()
	tag.text = tag_txt
	tag.position = Vector2(8, 8)
	tag.add_theme_font_size_override("font_size", 9)
	tag.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.7))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tag)

	# Big symbol
	var sym := data.get("symbol", data.get("name","?"))
	var sym_lbl := Label.new()
	sym_lbl.text = sym
	sym_lbl.size = Vector2(112, 52)
	sym_lbl.position = Vector2(0, 18)
	sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym_lbl.add_theme_font_size_override("font_size", 32 if ctype == "element" else 18)
	sym_lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.9))
	sym_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sym_lbl)

	# Divider
	var div := ColorRect.new()
	div.color = Color(col.r, col.g, col.b, 0.2)
	div.size = Vector2(96, 1)
	div.position = Vector2(8, 72)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = data.get("name", id)
	name_lbl.size = Vector2(104, 28)
	name_lbl.position = Vector2(4, 76)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	# Desc (reaction/support only)
	if ctype != "element" and data.has("desc"):
		var desc_lbl := Label.new()
		desc_lbl.text = data["desc"]
		desc_lbl.size = Vector2(104, 22)
		desc_lbl.position = Vector2(4, 88)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.add_theme_color_override("font_color", C_SUB)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(desc_lbl)

	# Selection glow overlay
	if selected:
		var glow := ColorRect.new()
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glow.color = Color(col.r, col.g, col.b, 0.10)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(glow)

	panel.gui_input.connect(_on_card_click.bind(id, idx))
	return panel

# ════════════════════════════════════════════════════════════
#  CARD INTERACTION
# ════════════════════════════════════════════════════════════
func _on_card_click(ev: InputEvent, id: String, _idx: int) -> void:
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _player_turn or _battle_over:
		return
	var data: Dictionary = CARD_DB.get(id, {})
	match data.get("type", "element"):
		"element":  _handle_element_select(id)
		"reaction": _use_reaction_card(id)
		"support":  _use_support_card(id)

func _handle_element_select(id: String) -> void:
	if _selected_elem == "":
		_selected_elem = id
		_show_react_hint("เลือก [%s] — กดธาตุที่ 2 เพื่อผสม  (กดซ้ำเพื่อยกเลิก)" % CARD_DB[id]["name"])
		_refresh_hand()
	elif _selected_elem == id:
		# Deselect — same element type tapped again
		_selected_elem = ""
		_hide_react_hint()
		_refresh_hand()
		_msg("ยกเลิกการเลือก")
	else:
		_try_reaction(_selected_elem, id)

func _try_reaction(a: String, b: String) -> void:
	var pair := [a, b]
	pair.sort()
	var key := pair[0] + "+" + pair[1]

	_selected_elem = ""
	_hide_react_hint()

	if RECIPES.has(key):
		var result: String = RECIPES[key]
		_remove_from_hand(a)
		_remove_from_hand(b)
		_hand.append(result)
		# First successful reaction per turn gives +20 gauge
		if not _reaction_gauge_used:
			_add_gauge(20)
			_reaction_gauge_used = true
		_msg("⚗ %s + %s → %s! ✨" % [CARD_DB[a]["name"], CARD_DB[b]["name"], result])
		_refresh_hand()
		_refresh_ui()
	else:
		_msg("❌ %s + %s ไม่เกิดปฏิกิริยา" % [CARD_DB[a]["name"], CARD_DB[b]["name"]])
		_refresh_hand()

func _use_reaction_card(id: String) -> void:
	var data: Dictionary = CARD_DB.get(id, {})
	var cost: int = data.get("ap", 1)
	if _ap < cost:
		_msg("❌ AP ไม่พอ (ต้องการ %d AP)" % cost); return

	_ap -= cost
	_add_gauge(15)
	_remove_from_hand(id)
	# Reaction cards vanish — not added to discard

	match id:
		"Water":
			_player_hp = min(_player_hp + 20, CHARACTER["max_hp"])
			_msg("💧 Water — ฟื้นฟู HP +20")
		"Salt":
			_player_shield += 20
			_msg("🧂 Salt — Shield +20")
		"Rust":
			_enemy_poison += 5
			_msg("🦠 Rust — ศัตรูติดพิษ +5/เทิร์น")

	_refresh_hand()
	_refresh_ui()
	_check_battle()

func _use_support_card(id: String) -> void:
	var data: Dictionary = CARD_DB.get(id, {})
	var cost: int = data.get("ap", 1)
	if _ap < cost:
		_msg("❌ AP ไม่พอ (ต้องการ %d AP)" % cost); return

	_ap -= cost
	_add_gauge(5)
	_remove_from_hand(id)
	_discard.append(id)

	match id:
		"Draw2":
			_draw_n(2)
			_msg("📖 Draw 2 — จั่วการ์ด 2 ใบ")
		"RecoverAP":
			_ap = min(_ap + 2, MAX_AP)
			_msg("⚡ Recover AP — ฟื้นฟู AP +2")

	_refresh_hand()
	_refresh_ui()

func _remove_from_hand(id: String) -> void:
	var i := _hand.find(id)
	if i >= 0: _hand.remove_at(i)

# ════════════════════════════════════════════════════════════
#  MAIN ACTIONS
# ════════════════════════════════════════════════════════════
func _on_attack() -> void:
	if not _player_turn or _main_action_done or _battle_over: return
	if _ap < 1: _msg("❌ AP ไม่พอ"); return

	_ap -= 1
	_main_action_done = true
	_is_defending = false

	var dmg := 20
	if _player_weak > 0:      dmg = max(0, dmg - 5)
	if _enemy_vulnerable > 0: dmg += 5

	_enemy_hp -= dmg
	_add_gauge(10)
	_msg("⚔ Attack — โจมตี %d ดาเมจ" % dmg)
	_flash_msg()
	_refresh_ui()
	_check_battle()

func _on_defend() -> void:
	if not _player_turn or _main_action_done or _battle_over: return
	if _ap < 1: _msg("❌ AP ไม่พอ"); return

	_ap -= 1
	_main_action_done = true
	_is_defending = true
	_add_gauge(10)
	_msg("🛡 Defend — ลดดาเมจที่ได้รับ")
	_refresh_ui()

func _on_skill() -> void:
	if not _player_turn or _main_action_done or _battle_over: return
	if _ap < 2:      _msg("❌ AP ไม่พอ (ต้องการ 2 AP)"); return
	if _skill_cd > 0: _msg("⏳ Skill Cooldown เหลือ %d เทิร์น" % _skill_cd); return

	_ap -= 2
	_main_action_done = true
	_skill_cd = CHARACTER["skill_cd"]

	var dmg: int = CHARACTER["skill_damage"]
	if _player_weak > 0: dmg = max(0, dmg - 10)
	_enemy_hp -= dmg
	_add_gauge(10)
	_msg("⚡ %s — %d ดาเมจ" % [CHARACTER["skill_name"], dmg])
	_flash_msg()
	_refresh_ui()
	_check_battle()

func _on_ultimate() -> void:
	if not _player_turn or _battle_over: return
	if _ult_gauge < MAX_GAUGE: _msg("❌ Gauge ยังไม่เต็ม (%d/%d)" % [_ult_gauge, MAX_GAUGE]); return
	if _ult_used:              _msg("❌ ใช้ Ultimate แล้วในเทิร์นนี้"); return

	_ult_used  = true
	_ult_gauge = 0

	var dmg: int = CHARACTER["ult_damage"]
	_enemy_hp     -= dmg
	_enemy_poison += 3
	_msg("💥 %s — %d ดาเมจ + ติดพิษ +3!" % [CHARACTER["ult_name"], dmg])
	_flash_msg()
	_refresh_ui()
	_check_battle()

func _on_end_turn() -> void:
	if not _player_turn or _battle_over: return
	_player_turn = false
	_selected_elem = ""
	_hide_react_hint()
	_set_buttons_enabled(false)
	_refresh_ui()
	get_tree().create_timer(0.4).timeout.connect(_enemy_turn)

# ════════════════════════════════════════════════════════════
#  ENEMY TURN
# ════════════════════════════════════════════════════════════
func _enemy_turn() -> void:
	# Poison tick first
	if _enemy_poison > 0:
		_enemy_hp -= _enemy_poison
		_msg("☠ พิษ — ศัตรูเสีย %d HP" % _enemy_poison)
		_refresh_ui()
		if _enemy_hp <= 0:
			_check_battle(); return
		await get_tree().create_timer(0.7).timeout

	# Enemy attacks
	var dmg: int = _enemy_data.get("attack", 10)

	if _is_defending:
		dmg = max(0, dmg - 10)

	if _player_shield > 0:
		var blocked := mini(_player_shield, dmg)
		_player_shield -= blocked
		dmg -= blocked

	_player_hp -= dmg
	_add_gauge(5)  # taking damage gives +5 gauge

	_msg("👾 %s โจมตี — เสีย %d HP" % [_enemy_data.get("name","ศัตรู"), dmg])
	_refresh_ui()

	await get_tree().create_timer(0.7).timeout

	if _player_hp <= 0:
		_check_battle(); return

	# Decay status
	_is_defending = false
	if _skill_cd         > 0: _skill_cd -= 1
	if _enemy_weak       > 0: _enemy_weak -= 1
	if _enemy_vulnerable > 0: _enemy_vulnerable -= 1
	if _player_weak      > 0: _player_weak -= 1
	if _player_vulnerable > 0: _player_vulnerable -= 1

	_start_player_turn()

func _start_player_turn() -> void:
	_player_turn          = true
	_main_action_done     = false
	_ult_used             = false
	_reaction_gauge_used  = false

	_ap = min(_ap + AP_RECOVER, MAX_AP)
	_draw_one()

	_set_buttons_enabled(true)
	_refresh_ui()
	_msg("✨ เทิร์นของคุณ — AP ฟื้นฟู +%d" % AP_RECOVER)

# ════════════════════════════════════════════════════════════
#  WIN / LOSE
# ════════════════════════════════════════════════════════════
func _check_battle() -> void:
	if _enemy_hp <= 0:
		_enemy_hp = 0
		_battle_over = true
		_refresh_ui()
		_msg("🏆 ชนะ! ไปต่อ Stage %d" % (_current_stage + 1))
		_set_buttons_enabled(false)
		DomainManager.add_points("battle")
		get_tree().create_timer(1.8).timeout.connect(_next_stage)
		return

	if _player_hp <= 0:
		_player_hp = 0
		_battle_over = true
		_refresh_ui()
		_msg("💀 แพ้... กลับสู่เมนูหลัก")
		_set_buttons_enabled(false)
		get_tree().create_timer(2.0).timeout.connect(_go_back)

func _next_stage() -> void:
	_current_stage += 1
	_battle_over   = false
	_create_enemy()
	_player_turn          = true
	_main_action_done     = false
	_ult_used             = false
	_reaction_gauge_used  = false
	_is_defending         = false
	_selected_elem        = ""
	_ap                   = START_AP
	_player_shield        = 0
	_enemy_poison         = 0
	_enemy_weak           = 0
	_enemy_vulnerable     = 0
	_player_weak          = 0
	_player_vulnerable    = 0
	_draw_n(1)
	_set_buttons_enabled(true)
	_refresh_ui()
	_msg("📍 Stage %d — ศัตรูใหม่ปรากฎ!" % _current_stage)

# ════════════════════════════════════════════════════════════
#  GAUGE
# ════════════════════════════════════════════════════════════
func _add_gauge(amount: int) -> void:
	_ult_gauge = mini(_ult_gauge + amount, MAX_GAUGE)

# ════════════════════════════════════════════════════════════
#  UI REFRESH
# ════════════════════════════════════════════════════════════
func _refresh_ui() -> void:
	if _stage_lbl:   _stage_lbl.text = "Stage %d" % _current_stage
	if _turn_lbl:    _turn_lbl.text  = "เทิร์นของคุณ" if _player_turn else "เทิร์นศัตรู"

	# AP dots: ● filled, ○ empty
	if _ap_lbl:
		var dots := "●".repeat(_ap) + "○".repeat(MAX_AP - _ap)
		_ap_lbl.text = dots

	# Ultimate gauge
	if _gauge_bar:  _gauge_bar.size.x = 250.0 * (_ult_gauge / float(MAX_GAUGE))
	if _gauge_lbl:  _gauge_lbl.text = "Ultimate %d / %d" % [_ult_gauge, MAX_GAUGE]

	# Player HP
	var max_hp: float = float(CHARACTER["max_hp"])
	if _player_hp_bar: _player_hp_bar.size.x = 380.0 * (maxi(0, _player_hp) / max_hp)
	if _player_hp_lbl: _player_hp_lbl.text = "HP: %d / %d" % [maxi(0,_player_hp), int(max_hp)]
	if _shield_lbl:    _shield_lbl.text = "🛡 Shield: %d" % _player_shield if _player_shield > 0 else ""

	# Enemy
	var emax: float = float(_enemy_data.get("hp", 100))
	if _enemy_name_lbl: _enemy_name_lbl.text = _enemy_data.get("name", "")
	if _enemy_hp_bar:   _enemy_hp_bar.size.x = 490.0 * (maxi(0, _enemy_hp) / emax)
	if _enemy_hp_lbl:   _enemy_hp_lbl.text = "HP: %d / %d" % [maxi(0,_enemy_hp), int(emax)]
	if _enemy_status_lbl:
		var s := []
		if _enemy_poison > 0: s.append("☠ พิษ %d/เทิร์น" % _enemy_poison)
		if _enemy_weak   > 0: s.append("💔 อ่อนแอ %d" % _enemy_weak)
		_enemy_status_lbl.text = "  ".join(s)

	# Deck/Discard
	if _deck_lbl:    _deck_lbl.text    = "Deck: %d" % _deck.size()
	if _discard_lbl: _discard_lbl.text = "Discard: %d" % _discard.size()

	# Buttons
	var pt := _player_turn and not _battle_over
	if _btn_attack: _btn_attack.disabled = not pt or _main_action_done or _ap < 1
	if _btn_defend: _btn_defend.disabled = not pt or _main_action_done or _ap < 1
	if _btn_skill:
		var cd := " [CD:%d]" % _skill_cd if _skill_cd > 0 else ""
		_btn_skill.text = "⚡ Skill\n2 AP%s" % cd
		_btn_skill.disabled = not pt or _main_action_done or _ap < 2 or _skill_cd > 0
	if _btn_ult:
		_btn_ult.disabled = not pt or _ult_gauge < MAX_GAUGE or _ult_used
	if _btn_end:
		_btn_end.disabled = not pt

func _set_buttons_enabled(on: bool) -> void:
	for b in [_btn_attack, _btn_defend, _btn_skill, _btn_ult, _btn_end]:
		if b: b.disabled = not on

# ════════════════════════════════════════════════════════════
#  HELPERS
# ════════════════════════════════════════════════════════════
func _show_react_hint(text: String) -> void:
	if _react_hint:
		_react_hint.text = text
		_react_hint.get_parent().visible = true

func _hide_react_hint() -> void:
	if _react_hint:
		_react_hint.get_parent().visible = false

func _msg(text: String) -> void:
	if _msg_lbl: _msg_lbl.text = text

func _flash_msg() -> void:
	if _msg_lbl:
		_msg_lbl.modulate = Color(1.0, 0.85, 0.3)
		var t := _msg_lbl.create_tween()
		t.tween_property(_msg_lbl, "modulate", Color(1,1,1,1), 0.45)

# ════════════════════════════════════════════════════════════
#  NAVIGATION
# ════════════════════════════════════════════════════════════
func _go_back() -> void:
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0,0,0,0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.28)
	await t.finished
	get_tree().change_scene_to_file(SC_MAIN)
