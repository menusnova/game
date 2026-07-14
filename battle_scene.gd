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
	"N":  {"type":"element","symbol":"N", "name":"Nitrogen","color":Color(0.35,0.50,0.95)},
	"S":  {"type":"element","symbol":"S", "name":"Sulfur",  "color":Color(1.00,0.85,0.10)},
	"Ca": {"type":"element","symbol":"Ca","name":"Calcium", "color":Color(0.80,0.75,0.65)},
	"Mg": {"type":"element","symbol":"Mg","name":"Magnesium","color":Color(0.60,0.85,0.60)},
	"K":  {"type":"element","symbol":"K", "name":"Potassium","color":Color(0.75,0.30,0.70)},
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
	"name":          "Lyra",
	"max_hp":        1000,
	"passive":       "Void Resonance",
	"atk_base":      24,
	"passive_bonus": 0.20,
	"skill_name":    "Aether Pulse",
	"skill_cd":      3,
	"ult_name":      "Absolute Zero Formula",
	"ult_dmg":       55,
}

# ════════════════════════════════════════════════════════════
#  STATE
# ════════════════════════════════════════════════════════════
var _deck:    Array = []
var _hand:    Array = []
var _discard: Array = []
var _element_fx: Node2D
var _stage_clear_fx: Node
var _player_sprite: TextureRect
var _player_body:   Control
var _enemy_sprite_tex: TextureRect
var _enemy_sprite_lbl: Label
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
var _is_defending:        bool = false   # Null Barrier active (50% reduction)
var _void_shield:         bool = false   # Aether Pulse — absorbs 1 hit
var _enemy_atk_debuff:    int  = 0       # Absolute Zero — enemy ATK reduction %
var _enemy_debuff_turns:  int  = 0       # turns remaining on ATK debuff
var _current_stage:       int  = 1
var _battle_over:         bool = false

# Reaction element selection (click-to-select, no drag)
var _selected_elem: String = ""

# ── UI node refs ──────────────────────────────────────────
var _msg_lbl:          Label
var _turn_lbl:         Label
var _ap_lbl:           Label
var _ap_orbs:          Array = []
var _gauge_bar:        TextureProgressBar
var _ult_circle:       Panel
var _ult_glow_on:      bool = false
var _ult_glow_tween:   Tween
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

var _back_menu:        Panel = null
var _back_menu_open:   bool  = false

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
const FAN_CENTER_X := 540.0
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
	# Energy not consumed for now — kept for later use
	# CurrencyManager.spend_energy(ENERGY_COST)
	_player_hp = CHARACTER["max_hp"]
	_build_ui()
	_build_element_fx()
	_build_stage_clear_fx()
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

func _load_png(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

## Soft-edged filled disc, used as the ULT gauge's radial progress texture (no rectangular corners).
func _make_disc_texture(diameter: int, color: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var center := Vector2(diameter * 0.5, diameter * 0.5)
	var r := diameter * 0.5 - 2.0
	for y in diameter:
		for x in diameter:
			var d := Vector2(x, y).distance_to(center)
			var a := 0.0
			if d <= r - 3.0:
				a = 0.85
			elif d <= r:
				a = 0.85 * (r - d) / 3.0
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	return ImageTexture.create_from_image(img)

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

# ── Top bar ───────────────────────────────────────────────
func _build_topbar() -> void:
	var bar := Panel.new()
	bar.size = Vector2(1152, 40)
	bar.add_theme_stylebox_override("panel", _flat(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
	add_child(bar)

	_stage_lbl = _mk_label("Stage 1", 12, C_SUB, bar, Vector2(14, 11))
	_turn_lbl  = _mk_label("เทิร์นของคุณ", 13, C_GOLD, bar, Vector2(426, 11), Vector2(300, 18), true)

	_build_back_menu(bar)

# ── Back button → expands left into Surrender / Continue choices ──
const BACK_X := 1104.0
const BACK_Y := 4.0
const BACK_W := 42.0
const BACK_H := 45.0
const BACK_MENU_W := 220.0

func _build_back_menu(bar: Panel) -> void:
	_back_menu = Panel.new()
	_back_menu.size = Vector2(BACK_MENU_W, BACK_H)
	_back_menu.position = Vector2(BACK_X + BACK_W, BACK_Y)   # tucked away, off past the back btn
	_back_menu.visible = false
	_back_menu.z_index = 19
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0.03, 0.05, 0.14, 0.96)
	msb.border_color = Color(0.45, 0.72, 1.0, 0.5)
	msb.set_border_width_all(1)
	msb.set_corner_radius_all(10)
	_back_menu.add_theme_stylebox_override("panel", msb)
	_back_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.add_child(_back_menu)

	var surrender_btn := Button.new()
	surrender_btn.text = "ยอมแพ้"
	surrender_btn.position = Vector2(8, 6)
	surrender_btn.size = Vector2(96, 33)
	surrender_btn.focus_mode = Control.FOCUS_NONE
	surrender_btn.add_theme_font_size_override("font_size", 12)
	surrender_btn.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75, 1.0))
	var surrender_sb := _flat(Color(0.45, 0.10, 0.10, 0.9), Color(0.90, 0.30, 0.30, 0.6), 8, 1)
	for s in ["normal", "hover", "pressed"]:
		surrender_btn.add_theme_stylebox_override(s, surrender_sb)
	surrender_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	surrender_btn.pressed.connect(_on_surrender)
	_back_menu.add_child(surrender_btn)

	var continue_btn := Button.new()
	continue_btn.text = "เล่นต่อ"
	continue_btn.position = Vector2(112, 6)
	continue_btn.size = Vector2(100, 33)
	continue_btn.focus_mode = Control.FOCUS_NONE
	continue_btn.add_theme_font_size_override("font_size", 12)
	continue_btn.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0, 1.0))
	var continue_sb := _flat(Color(0.10, 0.20, 0.45, 0.9), Color(0.40, 0.65, 1.0, 0.6), 8, 1)
	for s in ["normal", "hover", "pressed"]:
		continue_btn.add_theme_stylebox_override(s, continue_sb)
	continue_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	continue_btn.pressed.connect(_close_back_menu)
	_back_menu.add_child(continue_btn)

	var back := _make_back_btn(Vector2(BACK_X, BACK_Y), Vector2(BACK_W, BACK_H), func():
		_toggle_back_menu()
	)
	back.z_index = 21   # stays above the sliding menu
	bar.add_child(back)

func _toggle_back_menu() -> void:
	if _back_menu_open: _close_back_menu()
	else:               _open_back_menu()

func _open_back_menu() -> void:
	if _battle_over: return
	_back_menu_open = true
	_back_menu.visible = true
	var t := _back_menu.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_back_menu, "position:x", BACK_X + BACK_W - BACK_MENU_W, 0.22)

func _close_back_menu() -> void:
	if not _back_menu_open: return
	_back_menu_open = false
	var t := _back_menu.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_back_menu, "position:x", BACK_X + BACK_W, 0.18)
	t.tween_callback(func():
		if is_instance_valid(_back_menu): _back_menu.visible = false
	)

func _on_surrender() -> void:
	_close_back_menu()
	if _battle_over: return
	_battle_over = true
	_set_buttons_enabled(false)
	_show_result_screen(false)

# ── Enemy — center-top, smaller (distance perspective) ───
func _build_enemy_panel() -> void:
	# Shadow on ground below enemy
	var shadow := ColorRect.new()
	shadow.size     = Vector2(140, 18)
	shadow.position = Vector2(ENEMY_CX - 70.0, ENEMY_CY + 118.0)
	shadow.color    = Color(0.0, 0.0, 0.0, 0.35)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	# Enemy sprite — smaller than player (far away)
	var circle := Panel.new()
	circle.size = Vector2(140, 140)
	circle.position = Vector2(ENEMY_CX - 70.0, ENEMY_CY - 70.0)
	circle.clip_contents = true
	circle.add_theme_stylebox_override("panel",
		_flat(Color(0.18,0.04,0.04,0.88), Color(0.90,0.25,0.25,0.60), 70, 2))
	add_child(circle)

	_enemy_sprite_lbl = Label.new()
	_enemy_sprite_lbl.text = "👾"
	_enemy_sprite_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_enemy_sprite_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_sprite_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_enemy_sprite_lbl.add_theme_font_size_override("font_size", 56)
	_enemy_sprite_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(_enemy_sprite_lbl)

	_enemy_sprite_tex = TextureRect.new()
	_enemy_sprite_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_enemy_sprite_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_enemy_sprite_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_enemy_sprite_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_sprite_tex.visible = false
	circle.add_child(_enemy_sprite_tex)

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

const PLAYER_POSE := {
	"idle":  "res://image/lyra_guard.png",
	"atk":   "res://image/lyra_attack.png",
	"def":   "res://image/lyra_guard.png",
	"skl":   "res://image/lyra_skill.png",
	"ult":   "res://image/lyra_ultimate.png",
	"hit":   "res://image/lyra_hit.png",
}

# ── Player sprite — back view, large, bottom-left ─────────
func _build_player_sprite() -> void:
	# Ground shadow
	var shadow := ColorRect.new()
	shadow.size     = Vector2(180, 22)
	shadow.position = Vector2(PLAYER_X + 30.0, PLAYER_Y + PLAYER_H - 10.0)
	shadow.color    = Color(0.0, 0.0, 0.0, 0.45)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	var body := Control.new()
	body.size     = Vector2(PLAYER_W, PLAYER_H)
	body.position = Vector2(PLAYER_X, PLAYER_Y)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	_player_sprite = TextureRect.new()
	_player_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player_sprite.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_player_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_player_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ptex: Texture2D = _load_png(PLAYER_POSE["idle"])
	if ptex:
		_player_sprite.texture = ptex
	body.add_child(_player_sprite)

	# Subtle idle breathe tween
	var t := body.create_tween().set_loops()
	t.tween_property(body, "position:y", PLAYER_Y - 4.0, 2.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(body, "position:y", PLAYER_Y + 4.0, 2.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_player_body = body

## Swaps Lyra's battle pose (attack/defend/skill/ultimate/hit), then returns to idle after a beat.
func _set_player_pose(pose: String, hold: float = 0.5) -> void:
	if not _player_sprite: return
	var tex: Texture2D = _load_png(PLAYER_POSE.get(pose, PLAYER_POSE["idle"]))
	if not tex: return
	_player_sprite.texture = tex
	if pose == "idle": return
	await get_tree().create_timer(hold).timeout
	if is_instance_valid(_player_sprite):
		var idle_tex: Texture2D = _load_png(PLAYER_POSE["idle"])
		if idle_tex: _player_sprite.texture = idle_tex

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

	# AP orbs — individual Panel circles (filled = big glow, used = small hollow ring)
	const ORB_SZ  := 22.0
	const ORB_GAP := 10.0
	_ap_orbs = []
	for i in MAX_AP:
		var orb := Panel.new()
		orb.size = Vector2(ORB_SZ, ORB_SZ)
		orb.position = Vector2(4.0 + i * (ORB_SZ + ORB_GAP), 14.0)
		orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ap_row.add_child(orb)
		_ap_orbs.append(orb)
	# keep _ap_lbl alive (hidden) so other code refs don't crash
	_ap_lbl = Label.new(); _ap_lbl.visible = false; ap_row.add_child(_ap_lbl)

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
		["Attack",  "res://image/skill_void_strike.jpg",           "ATK\n1AP",  Color(0.95,0.35,0.35),  -90.0],
		["Skill",   "res://image/skill_aether_pulse.jpg",          "SKL\n2AP",  Color(0.80,0.50,1.00),   -8.0],
		["EndTurn", "",                                            "▶\nEND",    Color(0.55,0.75,0.55),   74.0],
		["Defend",  "res://image/skill_null_barrier.jpg",          "DEF\n1AP",  Color(0.35,0.65,1.00),  156.0],
	]
	const BTN_R := 34.0  # button half-size

	for d in DEFS:
		var id: String  = d[0]
		var icon_path: String = d[1]
		var lbl_txt: String = d[2]
		var col: Color  = d[3]
		var angle_deg: float = d[4]
		var rad := deg_to_rad(angle_deg)
		var bx := RING_CX + RING_R * cos(rad) - BTN_R
		var by := RING_CY + RING_R * sin(rad) - BTN_R

		var btn := Button.new()
		btn.text     = "" if icon_path != "" else lbl_txt
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

		if icon_path != "":
			var clip := Control.new()
			clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			clip.clip_contents = true
			clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(clip)
			var itex := TextureRect.new()
			itex.texture = load(icon_path)
			itex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			itex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			itex.stretch_mode = TextureRect.STRETCH_SCALE
			itex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			itex.modulate = Color(1, 1, 1, 0.85)
			var itex_mat := CanvasItemMaterial.new()
			itex_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			itex.material = itex_mat
			clip.add_child(itex)
			var caption := Label.new()
			caption.text = lbl_txt
			caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			caption.offset_top = -20
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.add_theme_font_size_override("font_size", 10)
			caption.add_theme_color_override("font_color", C_TEXT)
			caption.add_theme_color_override("font_shadow_color", Color(0,0,0,0.9))
			caption.add_theme_constant_override("shadow_offset_x", 1)
			caption.add_theme_constant_override("shadow_offset_y", 1)
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			clip.add_child(caption)

		match id:
			"Attack":  _btn_attack = btn; btn.pressed.connect(_on_attack)
			"Defend":  _btn_defend = btn; btn.pressed.connect(_on_defend)
			"Skill":   _btn_skill  = btn; btn.pressed.connect(_on_skill)
			"EndTurn": _btn_end    = btn; btn.pressed.connect(_on_end_turn)

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

	# Gauge fill — radial reveal, stays inside the circular frame (no square corners)
	_gauge_bar = TextureProgressBar.new()
	_gauge_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gauge_bar.texture_progress = _make_disc_texture(int(ULT_R * 2.0), col)
	_gauge_bar.fill_mode      = TextureProgressBar.FILL_CLOCKWISE
	_gauge_bar.radial_initial_angle = -90.0
	_gauge_bar.min_value = 0.0
	_gauge_bar.max_value = 100.0
	_gauge_bar.value     = 0.0
	_gauge_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circ.add_child(_gauge_bar)

	# Ultimate art (Absolute Zero Formula)
	var clip := Control.new()
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circ.add_child(clip)
	var tex := TextureRect.new()
	tex.texture = load("res://image/skill_absolute_zero_formula.jpg")
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.modulate = Color(1, 1, 1, 0.85)
	var tex_mat := CanvasItemMaterial.new()
	tex_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	tex.material = tex_mat
	clip.add_child(tex)

	_ult_circle = circ
	_ult_circle.modulate = Color(1, 1, 1, 1)

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

## Brightens (and gently pulses) the ULT circle once the gauge is fully charged, in place of a % readout.
func _set_ult_glow(on: bool) -> void:
	if on == _ult_glow_on: return
	_ult_glow_on = on
	if not is_instance_valid(_ult_circle): return
	if is_instance_valid(_ult_glow_tween): _ult_glow_tween.kill()
	if on:
		_ult_glow_tween = _ult_circle.create_tween().set_loops()
		_ult_glow_tween.tween_property(_ult_circle, "modulate", Color(1.35, 1.3, 1.05, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
		_ult_glow_tween.tween_property(_ult_circle, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
	else:
		_ult_glow_tween = _ult_circle.create_tween()
		_ult_glow_tween.tween_property(_ult_circle, "modulate", Color(1, 1, 1, 1), 0.25)

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
func _build_stage_clear_fx() -> void:
	var fx := preload("res://stage_clear_screen.gd").new()
	add_child(fx)
	fx.return_to_menu_requested.connect(func(): SceneTransition.fade_to(SC_MAIN))
	_stage_clear_fx = fx

func _build_element_fx() -> void:
	var fx := preload("res://element_card_system.gd").new()
	fx.player_pos = Vector2(PLAYER_X + PLAYER_W * 0.5, PLAYER_Y + PLAYER_H * 0.5)
	fx.enemy_pos  = Vector2(ENEMY_CX, ENEMY_CY)
	fx.z_index    = 25
	add_child(fx)
	_element_fx = fx

func _create_enemy() -> void:
	if _current_stage % 5 == 0:
		_enemy_data = {"name":"Void Dragon","hp":300,"attack":25,"type":"boss","img":"res://image/void_dragon.png"}
	else:
		var pool := [
			{"name":"Slime",     "hp":100,"attack":10,"type":"poison"},
			{"name":"Goblin",    "hp":80, "attack":20,"type":"attack"},
			{"name":"Knight",    "hp":150,"attack":12,"type":"tank"},
			{"name":"Void Beast","hp":120,"attack":16,"type":"attack","img":"res://image/void_beast.png"},
		]
		_enemy_data = pool.pick_random()
	_enemy_hp = _enemy_data["hp"]
	_refresh_enemy_sprite()

func _refresh_enemy_sprite() -> void:
	if not _enemy_sprite_tex: return
	var img_path: String = str(_enemy_data.get("img", ""))
	var tex: Texture2D = _load_png(img_path) if img_path != "" else null
	if tex:
		_enemy_sprite_tex.texture  = tex
		_enemy_sprite_tex.visible  = true
		_enemy_sprite_lbl.visible  = false
	else:
		_enemy_sprite_tex.visible  = false
		_enemy_sprite_lbl.visible  = true

func _build_deck() -> void:
	_deck = []
	if PlayerData.battle_deck_ready:
		for sym in PlayerData.battle_elem_deck:
			if not CARD_DB.has(sym): continue
			var cnt: int = PlayerData.battle_elem_deck[sym]
			for _i in cnt: _deck.append(sym)
		for sname in PlayerData.battle_supp_deck:
			if not CARD_DB.has(sname): continue
			var cnt2: int = PlayerData.battle_supp_deck[sname]
			for _i in cnt2: _deck.append(sname)
	if _deck.is_empty():
		# Fallback default 20-card deck: 16 elements + 4 supports
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
	"N":  {"desc":"ก๊าซ 78% ของบรรยากาศโลก จำเป็นต่อโปรตีนและ DNA",                          "type":"Nonmetal"},
	"S":  {"desc":"ธาตุสีเหลือง พบใกล้ภูเขาไฟ ใช้ผลิตกรดกำมะถันและยาง",                        "type":"Nonmetal"},
	"Ca": {"desc":"โลหะที่พบมากในกระดูกและฟัน จำเป็นต่อการหดตัวของกล้ามเนื้อ",                  "type":"Alkaline Earth Metal"},
	"Mg": {"desc":"โลหะเบา จำเป็นต่อคลอโรฟิลล์ในพืชและการทำงานของกล้ามเนื้อ",                   "type":"Alkaline Earth Metal"},
	"K":  {"desc":"โลหะอ่อนสีเงิน ควบคุมสัญญาณประสาทและการเต้นของหัวใจ",                        "type":"Alkali Metal"},
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
		_discard.append(a)
		_discard.append(b)
		_hand.append(result)
		# First successful reaction per turn gives +20 gauge
		if not _reaction_gauge_used:
			_add_gauge(20)
			_reaction_gauge_used = true
		_msg("⚗ %s + %s → %s! ✨" % [CARD_DB[a]["name"], CARD_DB[b]["name"], result])
		_refresh_hand()
		_refresh_ui()
		if _element_fx: _element_fx.play_reaction(result)
	else:
		_msg("❌ %s + %s ไม่เกิดปฏิกิริยา" % [CARD_DB[a]["name"], CARD_DB[b]["name"]])
		_refresh_hand()
		if _element_fx: _element_fx.play_no_reaction()

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
# ── Void Strike — Basic ATK ──────────────────────────────
# ── Void Resonance passive — active only after using an element/reaction
# card this turn, or while the enemy carries an active debuff ────────────
func _void_resonance_active() -> bool:
	return _reaction_gauge_used or _enemy_atk_debuff > 0

func _on_attack() -> void:
	if not _player_turn or _main_action_done or _battle_over: return
	if _ap < 1: _msg("❌ AP ไม่พอ (ต้องการ 1 AP)"); return

	_ap -= 1
	_main_action_done = true
	_is_defending = false
	_set_player_pose("atk")

	var base: int = CHARACTER["atk_base"]
	var bonus: float = CHARACTER["passive_bonus"] if _void_resonance_active() else 0.0
	var dmg := int(ceil(base * (1.0 + bonus)))   # 24, or ×1.20 = 28.8 → 29 when active

	_enemy_hp -= dmg
	_add_gauge(10)
	if bonus > 0.0:
		_msg("🌀 Void Strike — %d DMG  (+%.0f%% Void Resonance)" % [dmg, bonus * 100])
	else:
		_msg("🌀 Void Strike — %d DMG" % dmg)
	_flash_msg()
	_refresh_ui()
	_check_battle()

# ── Null Barrier — Defend (1 AP, ใช้แทน Attack/Skill ได้อย่างเดียวต่อเทิร์น) ──
func _on_defend() -> void:
	if not _player_turn or _main_action_done or _battle_over: return
	if _ap < 1: _msg("❌ AP ไม่พอ (ต้องการ 1 AP)"); return

	_ap -= 1
	_main_action_done = true
	_is_defending = true
	_set_player_pose("def", 0.8)
	_add_gauge(5)
	_msg("🛡 Null Barrier — ลดดาเมจ 50%")
	_refresh_ui()

# ── Aether Pulse — Skill (2 AP, ใช้แทน Attack/Defend ได้อย่างเดียวต่อเทิร์น) ──
func _on_skill() -> void:
	if not _player_turn or _main_action_done or _battle_over: return
	if _skill_cd > 0: _msg("⏳ Aether Pulse CD เหลือ %d เทิร์น" % _skill_cd); return
	if _ap < 2: _msg("❌ AP ไม่พอ (ต้องการ 2 AP)"); return

	_ap -= 2
	_main_action_done = true
	_skill_cd = CHARACTER["skill_cd"]   # 3 turns
	_set_player_pose("skl", 0.7)

	# ฟื้น HP 15%
	var heal := int(CHARACTER["max_hp"] * 0.15)
	_player_hp = mini(_player_hp + heal, CHARACTER["max_hp"])

	# สร้าง Void Shield
	_void_shield = true

	_add_gauge(12)
	_msg("✨ Aether Pulse — ฟื้น HP +%d  |  Void Shield พร้อม (รับดาเมจแทน HP 1 ครั้ง)" % heal)
	_flash_msg()
	_refresh_ui()

# ── Absolute Zero Formula — Ultimate ─────────────────────
func _on_ultimate() -> void:
	if not _player_turn or _battle_over: return
	if _ult_gauge < MAX_GAUGE: _msg("❌ Gauge ยังไม่เต็ม (%d/%d)" % [_ult_gauge, MAX_GAUGE]); return
	if _ult_used:              _msg("❌ ใช้ Ultimate แล้วในเทิร์นนี้"); return

	_ult_used  = true
	_ult_gauge = 0
	_set_player_pose("ult", 0.9)

	# 55 DMG, + Void Resonance 20% only if already primed (reaction card
	# used this turn, or enemy already carries a debuff from a prior cast)
	var base_dmg: int = CHARACTER["ult_dmg"]
	var bonus: float = CHARACTER["passive_bonus"] if _void_resonance_active() else 0.0
	var dmg := int(ceil(base_dmg * (1.0 + bonus)))   # 55, or ×1.20 = 66 when active

	_enemy_hp -= dmg

	# debuff: ลด ATK ศัตรู 30% เป็นเวลา 2 เทิร์น
	_enemy_atk_debuff   = 30
	_enemy_debuff_turns = 2

	if bonus > 0.0:
		_msg("🌑 Absolute Zero Formula — %d DMG ทุกตัว (+%.0f%% Void Resonance) | ลด ATK ศัตรู 30%% × 2 เทิร์น" % [dmg, bonus * 100])
	else:
		_msg("🌑 Absolute Zero Formula — %d DMG ทุกตัว | ลด ATK ศัตรู 30%% × 2 เทิร์น" % dmg)
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
		if not is_instance_valid(self): return

	# Enemy attacks
	var raw_dmg: int = _enemy_data.get("attack", 10)

	# Absolute Zero debuff — ลด ATK ศัตรู
	if _enemy_atk_debuff > 0:
		raw_dmg = max(1, int(raw_dmg * (1.0 - _enemy_atk_debuff / 100.0)))

	var dmg := raw_dmg

	# Null Barrier — ลดดาเมจ 50%
	if _is_defending:
		dmg = max(0, dmg / 2)

	# Void Shield — รับดาเมจแทน HP 1 ครั้ง (ดาเมจหายทั้งหมด)
	if _void_shield and dmg > 0:
		_void_shield = false
		_msg("💠 Void Shield — ดูดซับดาเมจ %d ทั้งหมด!" % dmg)
		_refresh_ui()
		await get_tree().create_timer(0.5).timeout
		if not is_instance_valid(self): return
		# เทิร์นยังดำเนินต่อ แต่ HP ไม่หาย
		dmg = 0

	# Salt shield
	if _player_shield > 0 and dmg > 0:
		var blocked := mini(_player_shield, dmg)
		_player_shield -= blocked
		dmg -= blocked

	_player_hp -= dmg
	if dmg > 0:
		_add_gauge(5)
		_set_player_pose("hit", 0.4)

	var def_txt := "  [Null Barrier -50%]" if _is_defending and raw_dmg > dmg else ""
	_msg("👾 %s โจมตี — เสีย %d HP%s" % [_enemy_data.get("name","ศัตรู"), max(0,dmg), def_txt])
	_refresh_ui()

	await get_tree().create_timer(0.7).timeout
	if not is_instance_valid(self): return

	if _player_hp <= 0:
		_check_battle(); return

	# Decay status
	_is_defending = false   # Null Barrier expires after taking 1 hit
	if _skill_cd          > 0: _skill_cd -= 1
	if _enemy_weak        > 0: _enemy_weak -= 1
	if _enemy_vulnerable  > 0: _enemy_vulnerable -= 1
	if _player_weak       > 0: _player_weak -= 1
	if _player_vulnerable > 0: _player_vulnerable -= 1
	if _enemy_debuff_turns > 0:
		_enemy_debuff_turns -= 1
		if _enemy_debuff_turns == 0:
			_enemy_atk_debuff = 0

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
		_grant_stage_reward()
		if _current_stage >= FINAL_STAGE:
			_stage_clear_fx.show_victory()
		else:
			await _stage_clear_fx.show_stage_clear(_current_stage)
			await get_tree().create_timer(2.0).timeout
			if not is_instance_valid(self): return
			await _stage_clear_fx.hide_stage_clear()
			if not is_instance_valid(self): return
			_next_stage()
		return

	if _player_hp <= 0:
		_player_hp = 0
		_battle_over = true
		_refresh_ui()
		_set_buttons_enabled(false)
		await get_tree().create_timer(0.6).timeout
		if not is_instance_valid(self): return
		_show_result_screen(false)

const FINAL_STAGE := 2   # only 2 stages exist — winning stage 2 ends the run

func _grant_stage_reward() -> void:
	var gold_gain: int = 100 + _current_stage * 50
	var crystal_gain: int = 5 if (_current_stage % 3 == 0 or _current_stage >= FINAL_STAGE) else 0
	CurrencyManager.add_gold(gold_gain)
	CurrencyManager.add_free_crystal(crystal_gain)

func _show_result_screen(won: bool) -> void:
	var is_final_win := won and _current_stage >= FINAL_STAGE

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

	# Full-screen overlay
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color   = Color(0.0, 0.0, 0.0, 0.0)
	ov.z_index = 50
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)

	var tw_bg := ov.create_tween()
	tw_bg.tween_property(ov, "color", Color(0.02, 0.02, 0.06, 0.92), 0.35)

	var main_col: Color = Color(0.98, 0.88, 0.30, 1.0) if won else Color(0.95, 0.35, 0.35, 1.0)

	# Big centered result text, upper-middle of screen
	var title_lbl := Label.new()
	title_lbl.text = "ชนะ" if won else "แพ้"
	title_lbl.position = Vector2(0, 90)
	title_lbl.size     = Vector2(1152.0, 110)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 80)
	title_lbl.add_theme_color_override("font_color", main_col)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_lbl.modulate = Color(1, 1, 1, 0.0)
	ov.add_child(title_lbl)
	var tw_t := title_lbl.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_t.tween_property(title_lbl, "modulate:a", 1.0, 0.45)

	var sub_lbl := Label.new()
	if is_final_win:
		sub_lbl.text = "ผ่านทุกด่านแล้ว! (Stage %d/%d)" % [_current_stage, FINAL_STAGE]
	elif won:
		sub_lbl.text = "Stage %d — ผ่านแล้ว!" % _current_stage
	else:
		sub_lbl.text = "Stage %d — พ่ายแพ้" % _current_stage
	sub_lbl.position = Vector2(0, 200)
	sub_lbl.size     = Vector2(1152.0, 26)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 15)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.83, 1.0, 0.80))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_lbl.modulate = Color(1, 1, 1, 0.0)
	ov.add_child(sub_lbl)
	var tw_s := sub_lbl.create_tween()
	tw_s.tween_property(sub_lbl, "modulate:a", 1.0, 0.4).set_delay(0.15)

	# Rewards — centered column below the title
	const RW := 360.0
	var rx := (1152.0 - RW) * 0.5
	var ry := 250.0

	var rew_hdr := Label.new()
	rew_hdr.text     = "รางวัลที่ได้รับ" if won else "สิ่งที่ได้รับ"
	rew_hdr.position = Vector2(rx, ry)
	rew_hdr.size     = Vector2(RW, 20)
	rew_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rew_hdr.add_theme_font_size_override("font_size", 12)
	rew_hdr.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9, 0.7))
	rew_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rew_hdr.modulate = Color(1, 1, 1, 0.0)
	ov.add_child(rew_hdr)
	ry += 30.0

	const ROWS: Array = [
		["⚔", "EXP",      Color(0.50, 0.90, 1.00)],
		["💰", "Gold",     Color(0.95, 0.78, 0.20)],
		["💎", "Crystal",  Color(0.55, 0.75, 1.00)],
	]
	var row_vals := [exp_gain, gold_gain, crystal_gain]
	var reward_nodes: Array = [rew_hdr]
	for i in ROWS.size():
		var row_data: Array = ROWS[i]
		var val: int = row_vals[i]
		var row_bg := Panel.new()
		row_bg.position = Vector2(rx, ry)
		row_bg.size     = Vector2(RW, 44)
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color(1, 1, 1, 0.05)
		rsb.set_corner_radius_all(8)
		row_bg.add_theme_stylebox_override("panel", rsb)
		row_bg.modulate = Color(1, 1, 1, 0.0)
		ov.add_child(row_bg)
		reward_nodes.append(row_bg)

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
		val_lbl.size     = Vector2(RW - 16, 44)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		val_lbl.add_theme_font_size_override("font_size", 18)
		val_lbl.add_theme_color_override("font_color", row_data[2] as Color)
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_bg.add_child(val_lbl)

		ry += 52.0

	for i in reward_nodes.size():
		var n: CanvasItem = reward_nodes[i]
		var tw_r := n.create_tween()
		tw_r.tween_property(n, "modulate:a", 1.0, 0.3).set_delay(0.20 + i * 0.06)

	# Button(s) — bottom center. Non-final win shows both "ต่อไป" and
	# "กลับหน้าหลัก" side by side; every other outcome shows a single
	# centered "กลับหน้าหลัก" button.
	var show_continue := won and not is_final_win
	var btn_h := 50.0
	var by := 648.0 - 90.0

	if show_continue:
		var bw := 180.0; var gap := 16.0
		var total_w := bw * 2 + gap
		var bx0 := (1152.0 - total_w) * 0.5
		_make_result_btn(ov, Vector2(bx0, by), Vector2(bw, btn_h),
			"ต่อไป →", Color(0.95, 0.78, 0.20, 1.0), Color(0.10, 0.06, 0.02, 1.0), 0.45,
			func():
				ov.queue_free()
				if is_instance_valid(self): _next_stage()
		)
		_make_result_btn(ov, Vector2(bx0 + bw + gap, by), Vector2(bw, btn_h),
			"กลับหน้าหลัก", Color(0.14, 0.16, 0.26, 1.0), Color(0.85, 0.88, 1.0, 1.0), 0.52,
			func():
				ov.queue_free()
				if is_instance_valid(self): _go_back()
		)
	else:
		var bw := 240.0
		_make_result_btn(ov, Vector2((1152.0 - bw) * 0.5, by), Vector2(bw, btn_h),
			"กลับหน้าหลัก",
			Color(0.95, 0.78, 0.20, 1.0) if won else Color(0.55, 0.12, 0.12, 1.0),
			Color(0.10, 0.06, 0.02, 1.0) if won else Color(1.0, 0.80, 0.80, 1.0), 0.45,
			func():
				ov.queue_free()
				if is_instance_valid(self): _go_back()
		)

func _make_result_btn(parent: Control, pos: Vector2, sz: Vector2, txt: String,
		bg_col: Color, txt_col: Color, delay: float, on_press: Callable) -> void:
	var btn := Panel.new()
	btn.position = pos
	btn.size     = sz
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = bg_col
	bsb.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("panel", bsb)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.modulate = Color(1, 1, 1, 0.0)
	parent.add_child(btn)
	var tw_b := btn.create_tween()
	tw_b.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(delay)

	var btn_lbl := Label.new()
	btn_lbl.text = txt
	btn_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.add_theme_font_size_override("font_size", 15)
	btn_lbl.add_theme_color_override("font_color", txt_col)
	btn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(btn_lbl)

	btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw_out := parent.create_tween()
			tw_out.tween_property(parent, "modulate:a", 0.0, 0.25)
			tw_out.tween_callback(on_press)
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
	_void_shield          = false
	_enemy_atk_debuff     = 0
	_enemy_debuff_turns   = 0
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

	# AP orbs: filled = large glow circle, used = small hollow ring
	for i in _ap_orbs.size():
		var orb := _ap_orbs[i] as Panel
		var sb := StyleBoxFlat.new()
		if i < _ap:
			sb.bg_color    = C_AP
			sb.border_color = Color(C_AP.r, C_AP.g, C_AP.b, 0.0)
			sb.set_border_width_all(0)
			sb.set_corner_radius_all(11)
			sb.shadow_color = Color(C_AP.r, C_AP.g, C_AP.b, 0.70)
			sb.shadow_size  = 8
			orb.size        = Vector2(22, 22)
			orb.position.y  = 14.0
		else:
			sb.bg_color    = Color(C_AP.r * 0.04, C_AP.g * 0.04, C_AP.b * 0.10, 0.6)
			sb.border_color = Color(C_AP.r, C_AP.g, C_AP.b, 0.35)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(8)
			sb.shadow_size  = 0
			orb.size        = Vector2(16, 16)
			orb.position.y  = 17.0
		orb.add_theme_stylebox_override("panel", sb)

	# Ultimate gauge — radial fill inside the circle; brightens when fully charged
	var ult_ratio := _ult_gauge / float(MAX_GAUGE)
	if _gauge_bar: _gauge_bar.value = ult_ratio * 100.0
	_set_ult_glow(_ult_gauge >= MAX_GAUGE and not _ult_used)

	# Deck / Discard circles
	if _deck_cnt_lbl: _deck_cnt_lbl.text = str(_deck.size())
	if _disc_cnt_lbl: _disc_cnt_lbl.text = str(_discard.size())

	# Player HP
	var max_hp: float = float(CHARACTER["max_hp"])
	if _player_hp_bar: _player_hp_bar.size.x = 288.0 * (maxi(0, _player_hp) / max_hp)
	if _player_hp_lbl: _player_hp_lbl.text = "%d" % maxi(0, _player_hp)
	var shield_parts: Array[String] = []
	if _player_shield > 0: shield_parts.append("🛡 %d" % _player_shield)
	if _void_shield:        shield_parts.append("💠 Void Shield")
	if _is_defending:       shield_parts.append("🌀 Barrier")
	if _shield_lbl: _shield_lbl.text = "  ".join(shield_parts)

	# Enemy
	var emax: float = float(_enemy_data.get("hp", 100))
	if _enemy_name_lbl: _enemy_name_lbl.text = _enemy_data.get("name", "")
	if _enemy_hp_bar:   _enemy_hp_bar.size.x = 260.0 * (maxi(0, _enemy_hp) / emax)
	if _enemy_hp_lbl:   _enemy_hp_lbl.text = "HP %d/%d" % [maxi(0,_enemy_hp), int(emax)]
	if _enemy_status_lbl:
		var s: Array[String] = []
		if _enemy_poison      > 0: s.append("☠ พิษ %d/t" % _enemy_poison)
		if _enemy_weak        > 0: s.append("💔 อ่อนแอ %d" % _enemy_weak)
		if _enemy_atk_debuff  > 0: s.append("⬇ ATK -%d%% (%dt)" % [_enemy_atk_debuff, _enemy_debuff_turns])
		_enemy_status_lbl.text = "  ".join(s)

	# Deck/Discard
	if _deck_lbl:    _deck_lbl.text    = "Deck: %d" % _deck.size()
	if _discard_lbl: _discard_lbl.text = "Discard: %d" % _discard.size()

	# Buttons — Attack (1 AP) / Defend (1 AP) / Skill (2 AP) are mutually
	# exclusive, pick exactly one per turn. Ultimate is independent.
	var pt := _player_turn and not _battle_over
	if _btn_attack: _btn_attack.disabled = not pt or _main_action_done or _ap < 1
	if _btn_defend: _btn_defend.disabled = not pt or _main_action_done or _ap < 1
	if _btn_skill:
		var cd := "\nCD:%d" % _skill_cd if _skill_cd > 0 else "\n2AP"
		_btn_skill.text = "✨\nSKL%s" % cd
		_btn_skill.disabled = not pt or _main_action_done or _skill_cd > 0 or _ap < 2
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
func _make_back_btn(pos: Vector2, _sz: Vector2, callback: Callable) -> Control:
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
