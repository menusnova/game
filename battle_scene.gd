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
	"name":         "Lyra",
	"max_hp":       100,
	"passive":      "Reaction Master",
	"skill_name":   "Chain Reaction",
	"skill_ap":     2,
	"skill_cd":     2,
	"ult_name":     "Element Burst",
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
var _skill_ap_boost:   bool = false  # recover full AP next turn after skill
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

var _deck_cnt_lbl:  Label   = null
var _disc_cnt_lbl:  Label   = null
var _info_panel:    Panel   = null
var _card_nodes:    Array[Control] = []
var _press_card_id: String  = ""
var _press_start:   float   = -1.0
var _info_shown:    bool    = false

# ── Colors ────────────────────────────────────────────────
const C_BG     := Color(0.04, 0.045, 0.10, 1.0)
const C_PANEL  := Color(0.06, 0.08,  0.16, 0.92)
const C_BORDER := Color(0.22, 0.50,  0.90, 0.25)
const C_TEXT   := Color(0.90, 0.93,  1.00, 1.0)
const C_SUB    := Color(0.55, 0.68,  0.90, 0.75)
const C_GOLD   := Color(1.00, 0.82,  0.25, 1.0)
const C_HP     := Color(0.25, 0.85,  0.45, 1.0)
const C_ENEMY  := Color(0.95, 0.35,  0.35, 1.0)
const C_AP     := Color(0.35, 0.72,  1.00, 1.0)
const C_GAUGE  := Color(1.00, 0.75,  0.25, 1.0)

# ── Layout constants (1152×648) ────────────────────────────
# Enemy — center-top (feels far away / background)
const ENEMY_CX := 560.0
const ENEMY_CY := 200.0
# Player sprite — bottom-left foreground (back view, large)
const PLAYER_X := 40.0
const PLAYER_Y := 290.0
const PLAYER_W := 240.0
const PLAYER_H := 300.0
# Action ring center (bottom-right)
const RING_CX  := 990.0
const RING_CY  := 497.0
const RING_R   := 88.0
# Card hand strip
const HAND_Y   := 556.0
const HAND_H   := 88.0
# Fan hand layout
const FAN_CENTER_X := 165.0
const FAN_BASE_Y   := 636.0
const FAN_ARC_R    := 520.0
const FAN_SPREAD   := 6.5
const CARD_W       := 84.0
const CARD_H       := 110.0
# Deck / Discard circles
const DECK_CX  := 830.0
const DECK_CY  := 558.0
const DISC_CX  := 738.0
const DISC_CY  := 558.0
const CIRC_R   := 36.0
# Ultimate circle — center of action ring
const ULT_CX   := RING_CX
const ULT_CY   := RING_CY
const ULT_R    := 46.0
# Card hold threshold (seconds)
const HOLD_THRESH := 0.32

# ════════════════════════════════════════════════════════════
#  ENTRY
# ════════════════════════════════════════════════════════════
const ENERGY_COST := 10

func _ready() -> void:
	CurrencyManager.spend_energy(ENERGY_COST)
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
	# ── Background: sky top → ground bottom gradient ──────────
	var sky := ColorRect.new()
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.05, 0.06, 0.14, 1.0)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	# Horizon glow — warm strip at mid-height
	var horizon := ColorRect.new()
	horizon.size     = Vector2(1152, 120)
	horizon.position = Vector2(0, 260)
	horizon.color    = Color(0.18, 0.10, 0.28, 0.55)
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	# Ground plane — darker, slightly purple-tinted
	var ground := ColorRect.new()
	ground.size     = Vector2(1152, 300)
	ground.position = Vector2(0, 348)
	ground.color    = Color(0.03, 0.02, 0.08, 1.0)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)

	# Ground line (horizon divider)
	var gline := ColorRect.new()
	gline.size     = Vector2(1152, 2)
	gline.position = Vector2(0, 347)
	gline.color    = Color(0.40, 0.28, 0.70, 0.35)
	gline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gline)

	# Vignette overlay
	var vig := ColorRect.new()
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.color = Color(0.0, 0.0, 0.05, 0.42)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)

	_build_topbar()
	_build_enemy_panel()
	_build_player_sprite()
	_build_player_hud()
	_build_react_hint()
	_build_hand_panel()
	_build_deck_discard_circles()
	_build_action_ring()
	_build_ult_button()
	_build_card_info_panel()
	_build_message_bar()

# ── Top bar ───────────────────────────────────────────────
func _build_topbar() -> void:
	var bar := Panel.new()
	bar.size = Vector2(1152, 40)
	bar.add_theme_stylebox_override("panel", _flat(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
	add_child(bar)

	_stage_lbl = _mk_label("Stage 1", 12, C_SUB, bar, Vector2(14, 11))
	_turn_lbl  = _mk_label("เทิร์นของคุณ", 13, C_GOLD, bar, Vector2(426, 11), Vector2(300, 18), true)

	var back := _make_back_btn(Vector2(1104, 4), Vector2(42, 45), func():
		if _battle_over or _player_turn: _go_back()
	)
	bar.add_child(back)

# ── Enemy — center-top, smaller (distance perspective) ───
func _build_enemy_panel() -> void:
	# Shadow on ground below enemy
	var shadow := ColorRect.new()
	shadow.size     = Vector2(140, 18)
	shadow.position = Vector2(ENEMY_CX - 70.0, ENEMY_CY + 118.0)
	shadow.color    = Color(0.0, 0.0, 0.0, 0.35)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	# Enemy sprite placeholder — smaller than player (far away)
	var circle := Panel.new()
	circle.size = Vector2(140, 140)
	circle.position = Vector2(ENEMY_CX - 70.0, ENEMY_CY - 70.0)
	circle.add_theme_stylebox_override("panel",
		_flat(Color(0.18,0.04,0.04,0.88), Color(0.90,0.25,0.25,0.60), 70, 2))
	add_child(circle)

	var sp_lbl := Label.new()
	sp_lbl.text = "👾"
	sp_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	sp_lbl.add_theme_font_size_override("font_size", 56)
	sp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(sp_lbl)

	# Idle bob animation
	var t := circle.create_tween().set_loops()
	t.tween_property(circle, "position:y", ENEMY_CY - 70.0 - 6.0, 1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(circle, "position:y", ENEMY_CY - 70.0 + 6.0, 1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Enemy HUD bar — floats above enemy (no frame)
	var ep := Panel.new()
	ep.size     = Vector2(280, 52)
	ep.position = Vector2(ENEMY_CX - 140.0, ENEMY_CY - 138.0)
	ep.add_theme_stylebox_override("panel", _flat(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
	add_child(ep)

	_enemy_name_lbl = _mk_label("", 13, C_TEXT, ep, Vector2(10, 4))

	var ehb_bg := ColorRect.new()
	ehb_bg.color    = Color(1,1,1,0.10)
	ehb_bg.size     = Vector2(260, 9)
	ehb_bg.position = Vector2(10, 24)
	ep.add_child(ehb_bg)

	_enemy_hp_bar = ColorRect.new()
	_enemy_hp_bar.color    = C_ENEMY
	_enemy_hp_bar.size     = Vector2(260, 9)
	_enemy_hp_bar.position = Vector2(10, 24)
	ep.add_child(_enemy_hp_bar)

	_enemy_hp_lbl     = _mk_label("", 10, C_ENEMY, ep, Vector2(10, 36))
	_enemy_status_lbl = _mk_label("", 10, Color(0.9,0.6,0.3), ep, Vector2(140, 36))

# ── Player sprite — back view, large, bottom-left ─────────
func _build_player_sprite() -> void:
	# Ground shadow
	var shadow := ColorRect.new()
	shadow.size     = Vector2(180, 22)
	shadow.position = Vector2(PLAYER_X + 30.0, PLAYER_Y + PLAYER_H - 10.0)
	shadow.color    = Color(0.0, 0.0, 0.0, 0.45)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	# Player placeholder — tall silhouette (back view)
	var body := Panel.new()
	body.size     = Vector2(PLAYER_W, PLAYER_H)
	body.position = Vector2(PLAYER_X, PLAYER_Y)
	body.add_theme_stylebox_override("panel",
		_flat(Color(0.08,0.10,0.24,0.90), Color(0.35,0.60,1.00,0.40), 18, 1))
	add_child(body)

	# Cape / cloak shape overlay
	var cape := ColorRect.new()
	cape.size     = Vector2(PLAYER_W - 20.0, PLAYER_H * 0.65)
	cape.position = Vector2(10.0, PLAYER_H * 0.30)
	cape.color    = Color(0.12, 0.06, 0.22, 0.70)
	cape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(cape)

	# Head circle
	var head := Panel.new()
	head.size     = Vector2(56, 56)
	head.position = Vector2((PLAYER_W - 56.0) / 2.0, 18.0)
	head.add_theme_stylebox_override("panel",
		_flat(Color(0.14,0.16,0.32,1.0), Color(0.45,0.65,1.00,0.50), 28, 1))
	body.add_child(head)

	# Subtle idle breathe tween
	var t := body.create_tween().set_loops()
	t.tween_property(body, "position:y", PLAYER_Y - 4.0, 2.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(body, "position:y", PLAYER_Y + 4.0, 2.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# "PLAYER" label inside — will be replaced by real sprite
	var ph := Label.new()
	ph.text = "← ตัวละคร\n(placeholder)"
	ph.size = Vector2(PLAYER_W, 40)
	ph.position = Vector2(0, PLAYER_H * 0.72)
	ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ph.add_theme_font_size_override("font_size", 10)
	ph.add_theme_color_override("font_color", Color(0.45,0.55,0.80,0.55))
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(ph)

# ── Player HUD — floats above hand strip, left side ───────
func _build_player_hud() -> void:
	var pp := Panel.new()
	pp.size     = Vector2(312, 120)
	pp.position = Vector2(8, HAND_Y - 132.0)
	pp.add_theme_stylebox_override("panel", _flat(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
	add_child(pp)

	_mk_label(CHARACTER["name"], 12, C_TEXT, pp, Vector2(12, 6))

	# HP bar
	var phb_bg := ColorRect.new()
	phb_bg.color    = Color(1,1,1,0.08)
	phb_bg.size     = Vector2(288, 10)
	phb_bg.position = Vector2(12, 26)
	pp.add_child(phb_bg)

	_player_hp_bar          = ColorRect.new()
	_player_hp_bar.color    = C_HP
	_player_hp_bar.size     = Vector2(288, 10)
	_player_hp_bar.position = Vector2(12, 26)
	pp.add_child(_player_hp_bar)

	_player_hp_lbl = _mk_label("", 10, C_HP,              pp, Vector2(12, 40))
	_shield_lbl    = _mk_label("", 10, Color(0.7,0.9,1.0), pp, Vector2(180, 40))

	# AP section — image slot left + dots fill remaining width
	var ap_row := Panel.new()
	ap_row.size     = Vector2(288, 56)
	ap_row.position = Vector2(12, 56)
	ap_row.add_theme_stylebox_override("panel", _flat(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
	ap_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pp.add_child(ap_row)

	# AP sub-label
	var ap_sub := Label.new()
	ap_sub.text = "AP"
	ap_sub.position = Vector2(4, 4)
	ap_sub.add_theme_font_size_override("font_size", 10)
	ap_sub.add_theme_color_override("font_color", C_SUB)
	ap_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ap_row.add_child(ap_sub)

	# Dots — start from left, bigger font
	_ap_lbl = Label.new()
	_ap_lbl.position = Vector2(4, 18)
	_ap_lbl.size     = Vector2(280, 34)
	_ap_lbl.add_theme_font_size_override("font_size", 30)
	_ap_lbl.add_theme_color_override("font_color", C_AP)
	_ap_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ap_row.add_child(_ap_lbl)

	# hidden refs for _refresh_ui (still needed)
	_deck_lbl    = Label.new(); _deck_lbl.visible    = false; pp.add_child(_deck_lbl)
	_discard_lbl = Label.new(); _discard_lbl.visible = false; pp.add_child(_discard_lbl)

# ── Reaction hint bar ──────────────────────────────────────
func _build_react_hint() -> void:
	var rb := Panel.new()
	rb.size     = Vector2(700, 28)
	rb.position = Vector2(226, 524)
	rb.add_theme_stylebox_override("panel",
		_flat(Color(0.12,0.10,0.04,0.95), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.4), 6, 1))
	rb.visible = false
	add_child(rb)
	_react_hint = _mk_label("", 11, C_GOLD, rb, Vector2(0,6), Vector2(700,16), true)

# ── Hand area — bottom strip ───────────────────────────────
func _build_hand_panel() -> void:
	# No background strip — cards float as fan (UNO style)
	_hand_container = HBoxContainer.new()
	_hand_container.visible = false
	add_child(_hand_container)

# ── Action ring — Persona-style circle, bottom-right ──────
func _build_action_ring() -> void:
	# Background disc
	var disc := Panel.new()
	disc.size     = Vector2(220, 220)
	disc.position = Vector2(RING_CX - 110.0, RING_CY - 110.0)
	disc.add_theme_stylebox_override("panel",
		_flat(Color(0.04,0.05,0.12,0.82), Color(0.20,0.40,0.80,0.18), 110, 1))
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(disc)

	# 5 buttons arranged in a circle
	# Angles: spread around bottom-right arc (right side)
	# 0=Attack(top), 1=Skill, 2=EndTurn(bottom), 3=Defend, 4=Ult (center-right)
	const DEFS := [
		["Attack",  "⚔",  "ATK\n1AP",  Color(0.95,0.35,0.35),  -90.0],
		["Skill",   "⚡",  "SKL\n2AP",  Color(0.80,0.50,1.00),   -8.0],
		["EndTurn", "▶",  "END",        Color(0.55,0.75,0.55),   74.0],
		["Defend",  "🛡",  "DEF\n1AP",  Color(0.35,0.65,1.00),  156.0],
	]
	const BTN_R := 34.0  # button half-size

	for d in DEFS:
		var id: String  = d[0]
		var icon: String = d[1]
		var lbl_txt: String = d[2]
		var col: Color  = d[3]
		var angle_deg: float = d[4]
		var rad := deg_to_rad(angle_deg)
		var bx := RING_CX + RING_R * cos(rad) - BTN_R
		var by := RING_CY + RING_R * sin(rad) - BTN_R

		var btn := Button.new()
		btn.text     = icon + "\n" + lbl_txt
		btn.size     = Vector2(BTN_R * 2.0, BTN_R * 2.0)
		btn.position = Vector2(bx, by)
		btn.add_theme_font_size_override("font_size", 11)
		var bg_col  := Color(col.r*0.14, col.g*0.14, col.b*0.20, 0.95)
		var brd_col := Color(col.r, col.g, col.b, 0.50)
		btn.add_theme_stylebox_override("normal",   _flat(bg_col, brd_col, int(BTN_R), 2))
		btn.add_theme_stylebox_override("hover",    _flat(Color(col.r*0.28,col.g*0.28,col.b*0.40,1.0), Color(col.r,col.g,col.b,0.90), int(BTN_R), 2))
		btn.add_theme_stylebox_override("pressed",  _flat(Color(col.r*0.08,col.g*0.08,col.b*0.12,1.0), Color(col.r,col.g,col.b,1.00), int(BTN_R), 2))
		btn.add_theme_stylebox_override("disabled", _flat(Color(0.08,0.09,0.12,0.80), Color(0.25,0.28,0.35,0.25), int(BTN_R), 1))
		btn.add_theme_color_override("font_color",          C_TEXT)
		btn.add_theme_color_override("font_color_disabled", Color(0.30,0.33,0.42))
		add_child(btn)
		match id:
			"Attack":  _btn_attack = btn; btn.pressed.connect(_on_attack)
			"Defend":  _btn_defend = btn; btn.pressed.connect(_on_defend)
			"Skill":   _btn_skill  = btn; btn.pressed.connect(_on_skill)
			"EndTurn": _btn_end    = btn; btn.pressed.connect(_on_end_turn)

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

# ── Deck / Discard circles ────────────────────────────────
func _build_deck_discard_circles() -> void:
	for is_deck in [true, false]:
		var cx    := DECK_CX if is_deck else DISC_CX
		var cy    := DECK_CY if is_deck else DISC_CY
		var label := "เด็ค" if is_deck else "ทิ้ง"
		var col   := Color(0.35, 0.62, 1.0) if is_deck else Color(0.65, 0.45, 0.40)

		var circ := Panel.new()
		circ.size     = Vector2(CIRC_R * 2, CIRC_R * 2)
		circ.position = Vector2(cx - CIRC_R, cy - CIRC_R)
		circ.add_theme_stylebox_override("panel",
			_flat(Color(col.r*0.10, col.g*0.10, col.b*0.18, 0.92),
				  Color(col.r, col.g, col.b, 0.50), int(CIRC_R), 2))
		circ.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circ.z_index = 4
		add_child(circ)

		# TextureRect placeholder for future image
		var tex := TextureRect.new()
		tex.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		tex.offset_left  = -16; tex.offset_right  = 16
		tex.offset_top   = -16; tex.offset_bottom = 16
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circ.add_child(tex)

		# Count label (center)
		var cnt := Label.new()
		cnt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cnt.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		cnt.add_theme_font_size_override("font_size", 16)
		cnt.add_theme_color_override("font_color", Color(col.r + 0.1, col.g + 0.05, col.b, 0.9))
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circ.add_child(cnt)
		if is_deck: _deck_cnt_lbl = cnt
		else:       _disc_cnt_lbl = cnt

		# Label below circle
		var lbl := Label.new()
		lbl.text = label
		lbl.size = Vector2(CIRC_R * 2, 14)
		lbl.position = Vector2(0, CIRC_R * 2 + 2)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.55))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circ.add_child(lbl)

# ── Ultimate standalone circle ────────────────────────────
func _build_ult_button() -> void:
	var col := C_GAUGE
	var circ := Panel.new()
	circ.size     = Vector2(ULT_R * 2, ULT_R * 2)
	circ.position = Vector2(ULT_CX - ULT_R, ULT_CY - ULT_R)
	circ.add_theme_stylebox_override("panel",
		_flat(Color(col.r*0.10, col.g*0.08, col.b*0.04, 0.92),
			  Color(col.r, col.g, col.b, 0.45), int(ULT_R), 2))
	circ.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circ.z_index = 4
	add_child(circ)

	# Gauge fill (fills from bottom as gauge increases)
	_gauge_bar = ColorRect.new()
	_gauge_bar.color    = Color(col.r, col.g, col.b, 0.28)
	_gauge_bar.size     = Vector2(ULT_R * 2, 0)
	_gauge_bar.position = Vector2(0, ULT_R * 2)
	_gauge_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circ.add_child(_gauge_bar)

	# TextureRect placeholder for ULT art
	var tex := TextureRect.new()
	tex.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	tex.offset_left  = -20; tex.offset_right  = 20
	tex.offset_top   = -20; tex.offset_bottom = 20
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circ.add_child(tex)

	# Center icon 💥
	var icon_lbl := Label.new()
	icon_lbl.text = "💥"
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 32)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circ.add_child(icon_lbl)

	# Gauge % label (bottom of circle)
	_gauge_lbl = _mk_label("0%", 9, C_GOLD, circ,
		Vector2(0, ULT_R * 2 - 14), Vector2(ULT_R * 2, 14), true)

	# Clickable button overlay
	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_theme_stylebox_override("normal",   _flat(Color(0,0,0,0), Color(0,0,0,0), int(ULT_R)))
	btn.add_theme_stylebox_override("hover",    _flat(Color(1,1,1,0.10), Color(col.r,col.g,col.b,0.6), int(ULT_R), 2))
	btn.add_theme_stylebox_override("pressed",  _flat(Color(0,0,0,0.15), Color(0,0,0,0), int(ULT_R)))
	btn.add_theme_stylebox_override("disabled", _flat(Color(0,0,0,0), Color(0,0,0,0)))
	btn.add_theme_stylebox_override("focus",    StyleBoxFlat.new())
	btn.text = ""
	btn.pressed.connect(_on_ultimate)
	btn.z_index = 1
	circ.add_child(btn)
	_btn_ult = btn

	# "ULT" label centered below the circle
	var lbl := Label.new()
	lbl.text = "ULT"
	lbl.size = Vector2(ULT_R * 2, 14)
	lbl.position = Vector2(0, ULT_R * 2 + 3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.55))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circ.add_child(lbl)

# ── Card info panel (slide in from right on hold) ─────────
func _build_card_info_panel() -> void:
	_info_panel = Panel.new()
	_info_panel.size     = Vector2(320, 400)
	_info_panel.position = Vector2(1160, 56)  # off-screen
	_info_panel.add_theme_stylebox_override("panel",
		_flat(Color(0.05, 0.07, 0.16, 0.97), Color(0.35, 0.62, 1.0, 0.35), 12, 1))
	_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.z_index = 20
	add_child(_info_panel)

func _show_card_info(id: String) -> void:
	if not is_instance_valid(_info_panel): return
	var data: Dictionary = CARD_DB.get(id, {})
	if data.is_empty(): return
	for c in _info_panel.get_children(): c.queue_free()

	var col: Color = data.get("color", Color(0.5,0.5,0.8))
	var ctype: String = data.get("type","element")

	# Top color stripe
	var stripe := ColorRect.new()
	stripe.size  = Vector2(320, 3); stripe.color = Color(col.r, col.g, col.b, 0.7)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_child(stripe)

	# Symbol large
	var sym: String = data.get("symbol", data.get("name", id))
	var sym_lbl := Label.new()
	sym_lbl.text = sym; sym_lbl.position = Vector2(16, 14)
	sym_lbl.add_theme_font_size_override("font_size", 48)
	sym_lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.88))
	sym_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_child(sym_lbl)

	# Name + type
	var name_lbl := Label.new()
	name_lbl.text = data.get("name", id)
	name_lbl.position = Vector2(104, 18)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_child(name_lbl)

	# Type chip
	var type_info: Dictionary = ELEM_INFO.get(id, {})
	var type_str: String = type_info.get("type", ctype.to_upper())
	var type_lbl := Label.new()
	type_lbl.text = type_str; type_lbl.position = Vector2(104, 42)
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.add_theme_color_override("font_color", Color(col.r + 0.1, col.g, col.b, 0.75))
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_child(type_lbl)

	# Divider
	var div := ColorRect.new()
	div.color = Color(1,1,1,0.08); div.size = Vector2(288, 1); div.position = Vector2(16, 76)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_child(div)

	# Real-world description
	var desc_str: String = type_info.get("desc", data.get("desc", ""))
	if not desc_str.is_empty():
		var hdr := Label.new()
		hdr.text = "ข้อมูลจริง"; hdr.position = Vector2(16, 86)
		hdr.add_theme_font_size_override("font_size", 10)
		hdr.add_theme_color_override("font_color", C_GOLD)
		hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_info_panel.add_child(hdr)
		var desc_lbl := Label.new()
		desc_lbl.text = desc_str; desc_lbl.position = Vector2(16, 102)
		desc_lbl.size = Vector2(288, 80)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.88, 1.0, 0.80))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_info_panel.add_child(desc_lbl)

	# Game effect
	var effect_y := 196.0
	if data.has("desc") and ctype != "element":
		var div2 := ColorRect.new()
		div2.color = Color(1,1,1,0.08); div2.size = Vector2(288,1); div2.position = Vector2(16, effect_y - 8)
		div2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_info_panel.add_child(div2)
		var eff_hdr := Label.new()
		eff_hdr.text = "ผลในเกม"; eff_hdr.position = Vector2(16, effect_y)
		eff_hdr.add_theme_font_size_override("font_size", 10)
		eff_hdr.add_theme_color_override("font_color", C_GOLD)
		eff_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_info_panel.add_child(eff_hdr)
		var eff_lbl := Label.new()
		eff_lbl.text = data["desc"]; eff_lbl.position = Vector2(16, effect_y + 16)
		eff_lbl.size = Vector2(288, 40)
		eff_lbl.add_theme_font_size_override("font_size", 12)
		eff_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.65, 0.9))
		eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		eff_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		_info_panel.add_child(eff_lbl)

	# AP cost
	if data.has("ap"):
		var ap_lbl2 := Label.new()
		ap_lbl2.text = "AP Cost: %d" % data["ap"]
		ap_lbl2.position = Vector2(16, 370)
		ap_lbl2.add_theme_font_size_override("font_size", 11)
		ap_lbl2.add_theme_color_override("font_color", C_AP)
		ap_lbl2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_info_panel.add_child(ap_lbl2)

	# Slide in
	var t := _info_panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_info_panel, "position:x", 820.0, 0.20)

func _hide_card_info() -> void:
	if not is_instance_valid(_info_panel): return
	var t := _info_panel.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_info_panel, "position:x", 1160.0, 0.15)

# ── Card tap handler (replaces old _on_card_click) ────────
func _on_card_tap(id: String, _idx: int) -> void:
	if not _player_turn or _battle_over: return
	var data: Dictionary = CARD_DB.get(id, {})
	match data.get("type", "element"):
		"element":  _handle_element_select(id)
		"reaction": _use_reaction_card(id)
		"support":  _use_support_card(id)

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
	for c in _card_nodes:
		if is_instance_valid(c): c.queue_free()
	_card_nodes.clear()
	var n := _hand.size()
	for i in n:
		var id: String = _hand[i]
		var data: Dictionary = CARD_DB.get(id, {})
		if data.is_empty(): continue
		var card := _make_card_node(id, data, i, n)
		add_child(card)
		_card_nodes.append(card)

const ELEM_INFO := {
	"H":  {"desc":"ธาตุที่เบาที่สุด พบมากที่สุดในจักรวาล 75% ของมวลสาร ใช้เป็นเชื้อเพลิงสะอาด", "type":"Nonmetal"},
	"O":  {"desc":"ก๊าซ 21% ของบรรยากาศโลก จำเป็นต่อการหายใจของสิ่งมีชีวิต",                     "type":"Nonmetal"},
	"Na": {"desc":"โลหะอ่อนสีเงิน ระเบิดรุนแรงเมื่อสัมผัสน้ำ ควบคุมแรงดันเลือดในร่างกาย",       "type":"Alkali Metal"},
	"Cl": {"desc":"แก๊สพิษสีเหลือง-เขียว เคยใช้เป็นอาวุธในสงครามโลก ปัจจุบันใช้ฆ่าเชื้อ",       "type":"Halogen"},
	"Fe": {"desc":"โลหะที่พบมากที่สุดในโลก เป็นส่วนประกอบหลักของแกนโลก ใช้ในการก่อสร้าง",       "type":"Transition Metal"},
	"C":  {"desc":"พบในสิ่งมีชีวิตทุกชนิด รากฐานของสารอินทรีย์ มีทั้งรูปกราไฟต์และเพชร",         "type":"Nonmetal"},
}

func _make_card_node(id: String, data: Dictionary, idx: int, total: int) -> Control:
	var ctype: String = data.get("type", "element")
	var col:   Color  = data.get("color", Color(0.5,0.5,0.6))
	var selected := (_selected_elem == id and ctype == "element")

	# Fan position on arc
	var half      := (total - 1) / 2.0
	var angle_rad := deg_to_rad((idx - half) * FAN_SPREAD)
	var bx        := FAN_CENTER_X + FAN_ARC_R * sin(angle_rad)
	var by        := FAN_BASE_Y   + FAN_ARC_R * (1.0 - cos(angle_rad))

	var border_a := 0.9 if selected else 0.35
	var bg_r     := 0.28 if selected else 0.10
	var bw       := 2   if selected else 1
	var panel    := Panel.new()
	panel.size          = Vector2(CARD_W, CARD_H)
	panel.position      = Vector2(bx - CARD_W * 0.5, by - CARD_H)
	panel.pivot_offset  = Vector2(CARD_W * 0.5, CARD_H)
	panel.rotation      = angle_rad
	panel.z_index       = 8 + idx
	panel.mouse_filter  = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel",
		_flat(Color(col.r*bg_r, col.g*bg_r, col.b*(bg_r+0.06), 1.0),
			  Color(col.r, col.g, col.b, border_a), 12, bw))

	# Build frame tex — added last so it renders on top of all content
	var frame_tier := 1
	if ctype == "reaction":
		frame_tier = clampi(int(data.get("tier", 1)), 1, 4)
	var frame_tex := TextureRect.new()
	frame_tex.texture      = load("res://image/g%d.jpg" % frame_tier)
	frame_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	frame_tex.stretch_mode = TextureRect.STRETCH_SCALE
	# Bigger than the card so frame fully covers all edges
	const FRAME_PAD := 10.0
	frame_tex.size     = Vector2(CARD_W + FRAME_PAD * 2, CARD_H + FRAME_PAD * 2)
	frame_tex.position = Vector2(-FRAME_PAD, -FRAME_PAD)
	frame_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_mat := CanvasItemMaterial.new()
	frame_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	frame_tex.material = frame_mat

	var tag_txt: String
	match ctype:
		"element":  tag_txt = "ELEMENT"
		"reaction": tag_txt = "TIER%d %dAP" % [data.get("tier",1), data.get("ap",1)]
		"support":  tag_txt = "SUPPORT %dAP" % data.get("ap",1)
	var tag := Label.new()
	tag.text = tag_txt; tag.position = Vector2(4, 5)
	tag.add_theme_font_size_override("font_size", 7)
	tag.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.60))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tag)

	# Big symbol
	var sym: String = data.get("symbol", data.get("name","?"))
	var sym_lbl := Label.new()
	sym_lbl.text = sym
	sym_lbl.size = Vector2(CARD_W, 50)
	sym_lbl.position = Vector2(0, 16)
	sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym_lbl.add_theme_font_size_override("font_size", 28 if ctype == "element" else 14)
	sym_lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.9))
	sym_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sym_lbl)

	# Divider
	var div := ColorRect.new()
	div.color = Color(col.r, col.g, col.b, 0.18)
	div.size  = Vector2(CARD_W - 10, 1); div.position = Vector2(5, 68)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = data.get("name", id)
	name_lbl.size = Vector2(CARD_W - 6, 28); name_lbl.position = Vector2(3, 72)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	# Selection glow
	if selected:
		var glow := ColorRect.new()
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glow.color = Color(col.r, col.g, col.b, 0.12)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(glow)

	# Frame on top of all content (BLEND_MODE_ADD: dark center = transparent)
	panel.add_child(frame_tex)

	# Hover: lift up
	var base_y := by - CARD_H
	panel.mouse_entered.connect(func():
		var t := panel.create_tween().set_ease(Tween.EASE_OUT)
		t.tween_property(panel, "position:y", base_y - 18.0, 0.12)
	)
	panel.mouse_exited.connect(func():
		var t := panel.create_tween().set_ease(Tween.EASE_OUT)
		t.tween_property(panel, "position:y", base_y if not selected else base_y - 18.0, 0.10)
	)

	# Tap / Hold detection
	panel.gui_input.connect(func(ev: InputEvent):
		if not (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT):
			return
		if ev.pressed:
			_press_card_id = id
			_press_start   = Time.get_ticks_msec() / 1000.0
			_info_shown    = false
		else:
			var held := Time.get_ticks_msec() / 1000.0 - _press_start
			_press_start = -1.0
			_hide_card_info()
			_info_shown = false
			if held < HOLD_THRESH and _player_turn and not _battle_over:
				_on_card_tap(id, idx)
	)
	return panel

# ════════════════════════════════════════════════════════════
#  CARD INTERACTION
# ════════════════════════════════════════════════════════════
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
	var pair: Array[String] = [a, b]
	pair.sort()
	var key: String = pair[0] + "+" + pair[1]

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
	if _ap < 2:       _msg("❌ AP ไม่พอ (ต้องการ 2 AP)"); return
	if _skill_cd > 0: _msg("⏳ Skill Cooldown เหลือ %d เทิร์น" % _skill_cd); return

	_ap -= 2
	_main_action_done = true
	_skill_cd = CHARACTER["skill_cd"]
	_skill_ap_boost = true  # recover full AP next turn

	_draw_one()
	_add_gauge(8)
	_msg("⚡ %s — จั๋ว 1 ใบ · AP เต็มเทิร์นหน้า" % CHARACTER["skill_name"])
	_flash_msg()
	_refresh_ui()

func _on_ultimate() -> void:
	if not _player_turn or _battle_over: return
	if _ult_gauge < MAX_GAUGE: _msg("❌ Gauge ยังไม่เต็ม (%d/%d)" % [_ult_gauge, MAX_GAUGE]); return
	if _ult_used:              _msg("❌ ใช้ Ultimate แล้วในเทิร์นนี้"); return

	_ult_used  = true
	_ult_gauge = 0

	# Draw 2 element cards that form a valid reaction pair
	var pair_drawn := 0
	var tried: Array[String] = []
	for recipe_key in RECIPES.keys():
		var parts: PackedStringArray = (recipe_key as String).split("+")
		if parts.size() == 2 and pair_drawn == 0:
			var ea: String = parts[0]; var eb: String = parts[1]
			if ea in _deck or ea in _discard:
				_hand.append(ea)
				if ea in _deck:
					_deck.erase(ea)
				else:
					_discard.erase(ea)
				var draw_b := eb if (eb in _deck or eb in _discard) else ea
				_hand.append(draw_b)
				if eb in _deck:
					_deck.erase(eb)
				elif eb in _discard:
					_discard.erase(eb)
				pair_drawn = 2
				tried = [ea, eb]
				break
	# fallback: draw any 2 element cards
	if pair_drawn == 0:
		for _i in 2:
			_draw_one()

	_msg("💥 %s — จั๋ว%s ขึ้นมือ!" % [CHARACTER["ult_name"],
		(" %s+%s" % [tried[0], tried[1]]) if tried.size() == 2 else " 2 ใบ"])
	_flash_msg()
	_refresh_ui()

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
		if not is_instance_valid(self): return

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
	if not is_instance_valid(self): return

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

	var ap_gain: int
	if _skill_ap_boost:
		_skill_ap_boost = false
		ap_gain = MAX_AP - _ap
		_ap = MAX_AP
		_msg("✨ เทิร์นของคุณ — AP ฟื้นฟูเต็ม! (%d)" % MAX_AP)
	else:
		ap_gain = AP_RECOVER
		_ap = min(_ap + AP_RECOVER, MAX_AP)
		_msg("✨ เทิร์นของคุณ — AP ฟื้นฟู +%d" % ap_gain)
	_draw_one()

	_set_buttons_enabled(true)
	_refresh_ui()

# ════════════════════════════════════════════════════════════
#  WIN / LOSE
# ════════════════════════════════════════════════════════════
func _check_battle() -> void:
	if _enemy_hp <= 0:
		_enemy_hp = 0
		_battle_over = true
		_refresh_ui()
		_set_buttons_enabled(false)
		DomainManager.add_points("battle")
		await get_tree().create_timer(0.6).timeout
		if not is_instance_valid(self): return
		_show_result_screen(true)
		return

	if _player_hp <= 0:
		_player_hp = 0
		_battle_over = true
		_refresh_ui()
		_set_buttons_enabled(false)
		await get_tree().create_timer(0.6).timeout
		if not is_instance_valid(self): return
		_show_result_screen(false)

func _show_result_screen(won: bool) -> void:
	# Rewards
	var exp_gain    := 30 + _current_stage * 20
	var gold_gain   := 100 + _current_stage * 50
	var crystal_gain := 5 if (_current_stage % 3 == 0 or won) else 0
	if not won:
		exp_gain  = int(exp_gain  * 0.3)
		gold_gain = int(gold_gain * 0.2)
		crystal_gain = 0
	CurrencyManager.add_gold(gold_gain)
	CurrencyManager.add_free_crystal(crystal_gain)

	# Overlay
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color   = Color(0.0, 0.0, 0.0, 0.0)
	ov.z_index = 50
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)

	var tw_bg := ov.create_tween()
	tw_bg.tween_property(ov, "color", Color(0.0, 0.0, 0.05, 0.82), 0.35)

	# Card panel — right-center
	const PW := 380.0; const PH := 430.0
	const PX := 1152.0 - PW - 32.0; const PY := (648.0 - PH) * 0.5
	var panel := Panel.new()
	panel.position = Vector2(PX, PY)
	panel.size     = Vector2(PW, PH)
	panel.modulate = Color(1, 1, 1, 0.0)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.04, 0.05, 0.14, 0.97) if won else Color(0.10, 0.03, 0.05, 0.97)
	psb.border_color = Color(0.95, 0.78, 0.20, 0.9) if won else Color(0.80, 0.20, 0.20, 0.9)
	psb.set_border_width(SIDE_LEFT, 2); psb.set_border_width(SIDE_RIGHT, 2)
	psb.set_border_width(SIDE_TOP, 2);  psb.set_border_width(SIDE_BOTTOM, 2)
	psb.corner_radius_top_left    = 18; psb.corner_radius_top_right    = 18
	psb.corner_radius_bottom_right= 18; psb.corner_radius_bottom_left  = 18
	psb.shadow_color = Color(0.95, 0.78, 0.20, 0.35) if won else Color(0.80, 0.20, 0.20, 0.35)
	psb.shadow_size  = 12
	panel.add_theme_stylebox_override("panel", psb)
	ov.add_child(panel)

	var tw_p := panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_p.tween_property(panel, "modulate:a", 1.0, 0.45)

	# Top accent bar
	var accent := ColorRect.new()
	accent.size  = Vector2(PW, 4)
	accent.color = Color(0.95, 0.78, 0.20, 1.0) if won else Color(0.90, 0.20, 0.20, 1.0)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(accent)

	# Result title
	var title_lbl := Label.new()
	title_lbl.text = "VICTORY" if won else "DEFEAT"
	title_lbl.position = Vector2(0, 28)
	title_lbl.size     = Vector2(PW, 72)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 44)
	title_lbl.add_theme_color_override("font_color",
		Color(0.98, 0.88, 0.30, 1.0) if won else Color(0.95, 0.35, 0.35, 1.0))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_lbl)

	# Sub text
	var sub_lbl := Label.new()
	sub_lbl.text = "Stage %d — ผ่านแล้ว!" % _current_stage if won else "Stage %d — พ่ายแพ้" % _current_stage
	sub_lbl.position = Vector2(0, 102)
	sub_lbl.size     = Vector2(PW, 22)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.70, 0.80, 1.0, 0.75))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub_lbl)

	# Divider
	var div := ColorRect.new()
	div.position = Vector2(24, 132)
	div.size     = Vector2(PW - 48, 1)
	div.color    = Color(1, 1, 1, 0.1)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	# Rewards header
	var rew_hdr := Label.new()
	rew_hdr.text     = "รางวัลที่ได้รับ" if won else "สิ่งที่ได้รับ"
	rew_hdr.position = Vector2(24, 148)
	rew_hdr.size     = Vector2(PW - 48, 20)
	rew_hdr.add_theme_font_size_override("font_size", 11)
	rew_hdr.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9, 0.7))
	rew_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(rew_hdr)

	# Reward rows
	const ROWS: Array = [
		["⚔", "EXP",      Color(0.50, 0.90, 1.00)],
		["💰", "Gold",     Color(0.95, 0.78, 0.20)],
		["💎", "Crystal",  Color(0.55, 0.75, 1.00)],
	]
	var row_vals := [exp_gain, gold_gain, crystal_gain]
	var ry := 178.0
	for i in ROWS.size():
		var row_data: Array = ROWS[i]
		var val: int = row_vals[i]
		# Row bg
		var row_bg := Panel.new()
		row_bg.position = Vector2(24, ry)
		row_bg.size     = Vector2(PW - 48, 44)
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color(1, 1, 1, 0.04)
		rsb.corner_radius_top_left    = 8; rsb.corner_radius_top_right    = 8
		rsb.corner_radius_bottom_right= 8; rsb.corner_radius_bottom_left  = 8
		row_bg.add_theme_stylebox_override("panel", rsb)
		panel.add_child(row_bg)

		var icon_lbl := Label.new()
		icon_lbl.text     = str(row_data[0])
		icon_lbl.position = Vector2(12, 0)
		icon_lbl.size     = Vector2(32, 44)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 18)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_bg.add_child(icon_lbl)

		var name_lbl := Label.new()
		name_lbl.text     = str(row_data[1])
		name_lbl.position = Vector2(48, 0)
		name_lbl.size     = Vector2(160, 44)
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0, 0.90))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_bg.add_child(name_lbl)

		var val_lbl := Label.new()
		val_lbl.text     = "+%d" % val if val > 0 else "—"
		val_lbl.position = Vector2(0, 0)
		val_lbl.size     = Vector2(PW - 48 - 16, 44)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		val_lbl.add_theme_font_size_override("font_size", 18)
		val_lbl.add_theme_color_override("font_color", row_data[2] as Color)
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_bg.add_child(val_lbl)

		ry += 52.0

	# Button
	var btn_y := PH - 64.0
	var btn := Panel.new()
	btn.position = Vector2(32, btn_y)
	btn.size     = Vector2(PW - 64, 44)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color     = Color(0.95, 0.78, 0.20, 1.0) if won else Color(0.55, 0.12, 0.12, 1.0)
	bsb.corner_radius_top_left    = 10; bsb.corner_radius_top_right    = 10
	bsb.corner_radius_bottom_right= 10; bsb.corner_radius_bottom_left  = 10
	btn.add_theme_stylebox_override("panel", bsb)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(btn)

	var btn_lbl := Label.new()
	btn_lbl.text = "ต่อไป →" if won else "กลับหน้าหลัก"
	btn_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.add_theme_font_size_override("font_size", 15)
	btn_lbl.add_theme_color_override("font_color",
		Color(0.10, 0.06, 0.02, 1.0) if won else Color(1.0, 0.80, 0.80, 1.0))
	btn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(btn_lbl)

	btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw_out := ov.create_tween()
			tw_out.tween_property(ov, "modulate:a", 0.0, 0.25)
			tw_out.tween_callback(func():
				if not is_instance_valid(self): return
				if won: _next_stage()
				else:   _go_back()
			)
	)

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
func _process(_delta: float) -> void:
	if _press_start >= 0.0 and not _info_shown:
		if Time.get_ticks_msec() / 1000.0 - _press_start >= HOLD_THRESH:
			_show_card_info(_press_card_id)
			_info_shown = true

func _refresh_ui() -> void:
	if _stage_lbl:   _stage_lbl.text = "Stage %d" % _current_stage
	if _turn_lbl:    _turn_lbl.text  = "เทิร์นของคุณ" if _player_turn else "เทิร์นศัตรู"

	# AP dots: ● filled, ○ empty
	if _ap_lbl:
		var dots := "●".repeat(_ap) + "○".repeat(MAX_AP - _ap)
		_ap_lbl.text = dots

	# Ultimate gauge circle (fills from bottom)
	var ult_ratio := _ult_gauge / float(MAX_GAUGE)
	var fill_h    := ULT_R * 2.0 * ult_ratio
	if _gauge_bar:
		_gauge_bar.size.y     = fill_h
		_gauge_bar.position.y = ULT_R * 2.0 - fill_h
	if _gauge_lbl:  _gauge_lbl.text = "%d%%" % int(ult_ratio * 100.0)

	# Deck / Discard circles
	if _deck_cnt_lbl: _deck_cnt_lbl.text = str(_deck.size())
	if _disc_cnt_lbl: _disc_cnt_lbl.text = str(_discard.size())

	# Player HP
	var max_hp: float = float(CHARACTER["max_hp"])
	if _player_hp_bar: _player_hp_bar.size.x = 288.0 * (maxi(0, _player_hp) / max_hp)
	if _player_hp_lbl: _player_hp_lbl.text = "HP %d/%d" % [maxi(0,_player_hp), int(max_hp)]
	if _shield_lbl:    _shield_lbl.text = "🛡 %d" % _player_shield if _player_shield > 0 else ""

	# Enemy
	var emax: float = float(_enemy_data.get("hp", 100))
	if _enemy_name_lbl: _enemy_name_lbl.text = _enemy_data.get("name", "")
	if _enemy_hp_bar:   _enemy_hp_bar.size.x = 260.0 * (maxi(0, _enemy_hp) / emax)
	if _enemy_hp_lbl:   _enemy_hp_lbl.text = "HP %d/%d" % [maxi(0,_enemy_hp), int(emax)]
	if _enemy_status_lbl:
		var s: Array[String] = []
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
		var cd := "\nCD:%d" % _skill_cd if _skill_cd > 0 else "\n2AP"
		_btn_skill.text = "⚡\nSKL%s" % cd
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
func _make_back_btn(pos: Vector2, sz: Vector2, callback: Callable) -> Control:
	var btn := Panel.new()
	btn.position = pos
	btn.z_index = 20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.05, 0.15, 0.55)
	sb.border_color = Color(0.45, 0.72, 1.0, 0.90)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(22)
	btn.add_theme_stylebox_override("panel", sb)
	btn.size        = Vector2(42, 45)
	btn.pivot_offset = Vector2(21, 22)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon := TextureRect.new()
	icon.texture      = preload("res://image/back.png")
	icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)
	btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(btn, "scale", Vector2(0.78, 0.78), 0.08)
			tw.tween_property(btn, "scale", Vector2(1.0,  1.0),  0.22)
			tw.tween_callback(callback)
	)
	btn.mouse_entered.connect(func():
		var tw := btn.create_tween().set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween().set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)
	return btn

func _go_back() -> void:
	SceneTransition.fade_to(SC_MAIN)
