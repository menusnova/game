extends Control

const SC_MAIN := "res://main_menu.tscn"
const PULL_COST_1  := 160
const PULL_COST_10 := 1600
const PITY_HARD    := 90
const PITY_SOFT    := 75
const RATE_5 := 0.016
const RATE_4 := 0.051

# 5★ characters
const POOL_5: Array[String] = ["Lyra", "Seraph"]
# 4★ characters + support cards
const POOL_4: Array[String] = [
	"Kael", "Mira", "Voss",               # characters
	"Acid Flask", "Iron Shield", "Ember Seal",  # support cards
]
# 3★ element cards (from the lab element set)
const POOL_3: Array[String] = [
	"H", "O", "Na", "Cl", "C",
	"Fe", "N", "S", "Ca", "Mg",
	"K", "Cu", "Zn", "P", "Si",
]

# card type lookup for display
const CARD_TYPE: Dictionary = {
	"Lyra": "CHARACTER", "Seraph": "CHARACTER",
	"Kael": "CHARACTER", "Mira": "CHARACTER", "Voss": "CHARACTER",
	"Acid Flask": "SUPPORT", "Iron Shield": "SUPPORT", "Ember Seal": "SUPPORT",
}
const ELEM_NAME: Dictionary = {
	"H": "Hydrogen", "O": "Oxygen",    "Na": "Sodium",   "Cl": "Chlorine",
	"C": "Carbon",   "Fe": "Iron",     "N":  "Nitrogen",  "S":  "Sulfur",
	"Ca": "Calcium", "Mg": "Magnesium","K":  "Potassium", "Cu": "Copper",
	"Zn": "Zinc",    "P":  "Phosphorus","Si": "Silicon",
}

# Warp type definitions (left selector)
const WARP_TYPES := [
	{
		"id":     "char",
		"label":  "Character\nEvent Warp",
		"tag":    "LIMITED",
		"icon":   "✦",
		"accent": Color(0.35, 0.75, 1.0),
		"banner_title": "Lyra · นักเล่นแร่แรงสูง",
		"banner_sub":   "5★  Rate Up  •  LIMITED",
		"art_icon":     "🔥",
		"art_col":      Color(1.0, 0.40, 0.15),
	},
	{
		"id":     "lc",
		"label":  "Light Cone\nEvent Warp",
		"tag":    "LIMITED",
		"icon":   "📖",
		"accent": Color(1.0, 0.78, 0.22),
		"banner_title": "Arcane Formula",
		"banner_sub":   "4★  Erudition Path  •  LC",
		"art_icon":     "📖",
		"art_col":      Color(1.0, 0.80, 0.25),
	},
	{
		"id":     "std",
		"label":  "Standard\nWarp",
		"tag":    "PERMANENT",
		"icon":   "⋆",
		"accent": Color(0.60, 0.65, 1.0),
		"banner_title": "Stellar Vault",
		"banner_sub":   "Standard 5★ Pool",
		"art_icon":     "⋆",
		"art_col":      Color(0.60, 0.65, 1.0),
	},
]

var _pity   := 0
var _pity_4 := 0
var _active_warp := 0   # index into WARP_TYPES

var _revealing   := false
var _skip_to_end := false

# Dynamic UI refs
var _new_gem_lbl:    Label       = null
var _new_pity_lbl:   Label       = null
var _new_pity_bar:   ProgressBar = null
var _new_pull1:      Button      = null
var _new_pull10:     Button      = null
var _banner_title:   Label       = null
var _banner_sub:     Label       = null
var _banner_art:     Label       = null
var _banner_glow:    ColorRect   = null
var _banner_card_node: Panel     = null
var _warp_btns:      Array[Button] = []

# .tscn overlay nodes (reveal animation)
@onready var _result_ov:  Control       = $ResultOverlay
@onready var _result_con: HBoxContainer = $ResultOverlay/ResultContainer
@onready var _skip_btn:   Button        = $ResultOverlay/SkipBtn

# Legacy .tscn nodes — hidden at runtime
@onready var _pull1:    Button      = $PullBtn1
@onready var _pull10:   Button      = $PullBtn10
@onready var _back:     Button      = $BackBtn
@onready var _pity_bar: ProgressBar = $BannerCard/PityBar
@onready var _pity_lbl: Label       = $BannerCard/PityLabel
@onready var _gem_lbl:  Label       = $InfoPanel/CurrencyRow/GemCount

# ── Setup ─────────────────────────────────────────────────────────
func _ready() -> void:
	for n in ["Background","BgDim","BannerCard","InfoPanel","PullBtn1","PullBtn10","HistoryBtn","BackBtn"]:
		var node := get_node_or_null(n)
		if node: node.visible = false

	if _skip_btn:
		_skip_btn.pressed.connect(_on_skip)
	if _result_ov:
		_result_ov.visible = false

	_build_hsr_ui()
	_refresh_ui()

# ── HSR Layout ────────────────────────────────────────────────────
const W := 1152.0
const H := 648.0
const LEFT_W  := 210.0   # left warp-type panel
const BOT_H   := 88.0    # bottom action bar

func _build_hsr_ui() -> void:
	# Starfield background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.03, 0.08, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	add_child(bg)
	_add_stars(bg)

	# Subtle gradient vignette
	var vign := ColorRect.new()
	vign.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vign.color = Color(0, 0, 0, 0.0)
	vign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vign.z_index = -9
	add_child(vign)

	# ── Left selector panel ──
	var left_sb := _sb(Color(0.03, 0.05, 0.13, 0.82), Color(1,1,1, 0.06), 0, 1)
	var left_panel := Panel.new()
	left_panel.size     = Vector2(LEFT_W, H - BOT_H)
	left_panel.position = Vector2.ZERO
	left_panel.add_theme_stylebox_override("panel", left_sb)
	left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.z_index = 3
	add_child(left_panel)

	# "WARP" header inside left panel
	var warp_hdr := Label.new()
	warp_hdr.text = "WARP"
	warp_hdr.add_theme_font_size_override("font_size", 22)
	warp_hdr.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 0.9))
	warp_hdr.size     = Vector2(LEFT_W, 36)
	warp_hdr.position = Vector2(0, 18)
	warp_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warp_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.add_child(warp_hdr)

	var sep_hdr := ColorRect.new()
	sep_hdr.size     = Vector2(LEFT_W - 24, 1)
	sep_hdr.position = Vector2(12, 58)
	sep_hdr.color    = Color(0.37, 0.62, 1.0, 0.18)
	sep_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.add_child(sep_hdr)

	# Warp type buttons
	for i in WARP_TYPES.size():
		var d: Dictionary = WARP_TYPES[i]
		var btn := _make_warp_tab(d, i == _active_warp)
		btn.position = Vector2(0, 68 + i * 130)
		btn.size     = Vector2(LEFT_W, 120)
		btn.pressed.connect(_on_warp_tab.bind(i))
		left_panel.add_child(btn)
		_warp_btns.append(btn)

	# ── Main banner area (floating card) ──
	_build_banner_card()

	# ── Bottom bar ──
	_build_bottom_bar()

	# Ensure result overlay on top
	if _result_ov:
		_result_ov.z_index = 50
		move_child(_result_ov, get_child_count() - 1)

func _build_banner_card() -> void:
	var d: Dictionary = WARP_TYPES[_active_warp]
	var acc: Color = d["accent"] as Color

	# Floating card — no heavy bg, just a subtle tinted border
	var cx := LEFT_W + 40
	var cy := 40.0
	var cw := W - cx - 40
	var ch := H - BOT_H - cy - 20

	var card_sb := _sb(
		Color(acc.r * 0.04, acc.g * 0.04, acc.b * 0.10, 0.30),
		Color(acc.r, acc.g, acc.b, 0.22),
		18, 1
	)
	var card := Panel.new()
	card.name     = "_BannerCard"
	card.size     = Vector2(cw, ch)
	card.position = Vector2(cx, cy)
	card.add_theme_stylebox_override("panel", card_sb)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_index  = 2
	add_child(card)
	_banner_card_node = card

	# Accent corner bar (top)
	var top_bar := ColorRect.new()
	top_bar.size     = Vector2(cw, 3)
	top_bar.color    = Color(acc.r, acc.g, acc.b, 0.7)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(top_bar)

	# Glow blob behind art
	_banner_glow = ColorRect.new()
	_banner_glow.size     = Vector2(cw * 0.6, ch * 0.7)
	_banner_glow.position = Vector2((cw - cw * 0.6) * 0.5, ch * 0.1)
	_banner_glow.color    = Color(acc.r, acc.g, acc.b, 0.055)
	_banner_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_banner_glow)

	# Large art icon (center)
	_banner_art = Label.new()
	_banner_art.text = str(d["art_icon"])
	_banner_art.add_theme_font_size_override("font_size", 120)
	_banner_art.add_theme_color_override("font_color",
		Color((d["art_col"] as Color).r, (d["art_col"] as Color).g, (d["art_col"] as Color).b, 0.18))
	_banner_art.size     = Vector2(cw, ch)
	_banner_art.position = Vector2.ZERO
	_banner_art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_art.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_banner_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_banner_art)

	# Pulse animation on art
	var tp := _banner_art.create_tween().set_loops()
	tp.tween_property(_banner_art, "modulate:a", 0.55, 2.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tp.tween_property(_banner_art, "modulate:a", 1.0,  2.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Banner title + sub (bottom of card)
	var info_y := ch - 80.0
	_banner_title = Label.new()
	_banner_title.text = str(d["banner_title"])
	_banner_title.add_theme_font_size_override("font_size", 28)
	_banner_title.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_banner_title.size     = Vector2(cw - 32, 36)
	_banner_title.position = Vector2(16, info_y)
	_banner_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_banner_title)

	_banner_sub = Label.new()
	_banner_sub.text = str(d["banner_sub"])
	_banner_sub.add_theme_font_size_override("font_size", 12)
	_banner_sub.add_theme_color_override("font_color", Color(acc.r + 0.1, acc.g + 0.05, acc.b, 0.8))
	_banner_sub.size     = Vector2(cw - 32, 20)
	_banner_sub.position = Vector2(16, info_y + 40)
	_banner_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_banner_sub)

func _build_bottom_bar() -> void:
	var bar_sb := _sb(Color(0.03, 0.05, 0.12, 0.92), Color(1,1,1, 0.07), 0, 1)
	var bar := Panel.new()
	bar.name     = "_BottomBar"
	bar.size     = Vector2(W, BOT_H)
	bar.position = Vector2(0, H - BOT_H)
	bar.add_theme_stylebox_override("panel", bar_sb)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.z_index  = 4
	add_child(bar)

	# ◀ Back (far left)
	var back := _ghost_btn("◀", 13)
	back.size     = Vector2(52, 44)
	back.position = Vector2(16, (BOT_H - 44) * 0.5)
	back.pressed.connect(_go_back)
	bar.add_child(back)

	# Gem + pity info (center-left)
	var info_x := 84.0
	var gem_row := HBoxContainer.new()
	gem_row.position = Vector2(info_x, 12)
	gem_row.add_theme_constant_override("separation", 4)
	bar.add_child(gem_row)
	var gem_tex := load("res://image/crystal_gem.png") as Texture2D
	if gem_tex:
		var gem_ico := TextureRect.new()
		gem_ico.texture = gem_tex
		gem_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gem_ico.custom_minimum_size = Vector2(22, 22)
		gem_row.add_child(gem_ico)
	else:
		var gem_ico := Label.new()
		gem_ico.text = "💠"
		gem_ico.add_theme_font_size_override("font_size", 18)
		gem_row.add_child(gem_ico)
	_new_gem_lbl = Label.new()
	_new_gem_lbl.text = "0"
	_new_gem_lbl.add_theme_font_size_override("font_size", 18)
	_new_gem_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	gem_row.add_child(_new_gem_lbl)

	# Pity counter
	var pity_cap := Label.new()
	pity_cap.text = "Pity"
	pity_cap.add_theme_font_size_override("font_size", 9)
	pity_cap.add_theme_color_override("font_color", Color(1,1,1, 0.35))
	pity_cap.position = Vector2(info_x, 38)
	pity_cap.size     = Vector2(40, 14)
	bar.add_child(pity_cap)

	_new_pity_lbl = Label.new()
	_new_pity_lbl.text = "0 / 90"
	_new_pity_lbl.add_theme_font_size_override("font_size", 12)
	_new_pity_lbl.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0, 0.9))
	_new_pity_lbl.position = Vector2(info_x + 36, 36)
	_new_pity_lbl.size     = Vector2(90, 18)
	bar.add_child(_new_pity_lbl)

	_new_pity_bar = ProgressBar.new()
	_new_pity_bar.max_value     = PITY_HARD
	_new_pity_bar.value         = 0
	_new_pity_bar.show_percentage = false
	_new_pity_bar.size     = Vector2(160, 5)
	_new_pity_bar.position = Vector2(info_x, 62)
	bar.add_child(_new_pity_bar)

	# Pull buttons (right side)
	var btn_w := 220.0
	var btn_h := 52.0
	var bx    := W - (btn_w * 2 + 12 + 16)

	_new_pull1 = _pull_btn("Warp  ×1\n160 คริสตัล", Color(0.13, 0.25, 0.58, 1.0), Color(0.20, 0.33, 0.68, 1.0))
	_new_pull1.size     = Vector2(btn_w, btn_h)
	_new_pull1.position = Vector2(bx, (BOT_H - btn_h) * 0.5)
	_new_pull1.pressed.connect(func(): _do_pull(1))
	bar.add_child(_new_pull1)

	_new_pull10 = _pull_btn("Warp  ×10\n1,600 คริสตัล", Color(0.32, 0.58, 1.0, 1.0), Color(0.42, 0.68, 1.0, 1.0))
	_new_pull10.size     = Vector2(btn_w, btn_h)
	_new_pull10.position = Vector2(bx + btn_w + 12, (BOT_H - btn_h) * 0.5)
	_new_pull10.pressed.connect(func(): _do_pull(10))
	bar.add_child(_new_pull10)

# ── Warp tab selection ─────────────────────────────────────────────
func _on_warp_tab(idx: int) -> void:
	if idx == _active_warp:
		return
	_active_warp = idx
	if is_instance_valid(_banner_card_node):
		_banner_card_node.free()
		_banner_card_node = null
	_build_banner_card()
	# Re-style warp tab buttons
	for i in _warp_btns.size():
		_restyle_warp_tab(_warp_btns[i], WARP_TYPES[i], i == _active_warp)

func _make_warp_tab(d: Dictionary, active: bool) -> Button:
	var btn := Button.new()
	_restyle_warp_tab(btn, d, active)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	return btn

func _restyle_warp_tab(btn: Button, d: Dictionary, active: bool) -> void:
	var acc: Color = d["accent"] as Color
	var bg_col := Color(acc.r * 0.18, acc.g * 0.18, acc.b * 0.28, 0.95) if active else Color(0.02, 0.03, 0.08, 0.0)
	var bdr_col := Color(acc.r, acc.g, acc.b, 0.7) if active else Color(1,1,1, 0.07)
	var bdr_w := 1 if active else 0

	var sb := _sb(bg_col, bdr_col, 12, bdr_w)
	var sbf := StyleBoxFlat.new()
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   _sb(Color(acc.r*0.12, acc.g*0.12, acc.b*0.22, 0.88), bdr_col, 12, 1))
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus",   sbf)

	# Clear children and rebuild content label inside
	for c in btn.get_children():
		c.queue_free()

	var icon_lbl := Label.new()
	icon_lbl.text = str(d["icon"])
	icon_lbl.add_theme_font_size_override("font_size", 26)
	icon_lbl.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 0.9 if active else 0.45))
	icon_lbl.size     = Vector2(LEFT_W, 34)
	icon_lbl.position = Vector2(0, 14)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = str(d["label"])
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color",
		Color(1.0, 1.0, 1.0, 0.95) if active else Color(0.60, 0.68, 0.80, 0.65))
	name_lbl.size     = Vector2(LEFT_W - 16, 36)
	name_lbl.position = Vector2(8, 50)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	# Active indicator: left accent bar
	if active:
		var bar := ColorRect.new()
		bar.size     = Vector2(3, 100)
		bar.position = Vector2(0, 10)
		bar.color    = Color(acc.r, acc.g, acc.b, 1.0)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(bar)

# ── Helpers ───────────────────────────────────────────────────────
func _sb(bg: Color, bdr: Color, radius: int, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bdr
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_border_width(side, bw)
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_right = radius
	s.corner_radius_bottom_left  = radius
	return s

func _pull_btn(label: String, col: Color, col_h: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(1,1,1,1))
	btn.add_theme_stylebox_override("normal",  _sb(col,   col,   12, 0))
	btn.add_theme_stylebox_override("hover",   _sb(col_h, col_h, 12, 0))
	btn.add_theme_stylebox_override("pressed", _sb(col,   col,   12, 0))
	btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	return btn

func _ghost_btn(label: String, fsize: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", fsize)
	btn.add_theme_color_override("font_color", Color(1,1,1, 0.65))
	btn.add_theme_stylebox_override("normal",  _sb(Color(1,1,1,0.04), Color(1,1,1,0.10), 10, 1))
	btn.add_theme_stylebox_override("hover",   _sb(Color(1,1,1,0.08), Color(1,1,1,0.18), 10, 1))
	btn.add_theme_stylebox_override("pressed", _sb(Color(1,1,1,0.04), Color(1,1,1,0.10), 10, 1))
	btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	return btn

func _add_stars(parent: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99991
	for _i in 90:
		var dot := ColorRect.new()
		var sz  := rng.randf_range(1.0, 2.8)
		dot.size     = Vector2(sz, sz)
		dot.position = Vector2(rng.randf_range(0, W), rng.randf_range(0, H))
		var br := rng.randf_range(0.4, 1.0)
		dot.color = Color(br, br, br + 0.05, rng.randf_range(0.15, 0.55))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(dot)
		var td := dot.create_tween().set_loops()
		td.tween_interval(rng.randf_range(0, 4.0))
		td.tween_property(dot, "modulate:a", rng.randf_range(0.05, 0.3), rng.randf_range(1.2, 3.5)).set_ease(Tween.EASE_IN_OUT)
		td.tween_property(dot, "modulate:a", 1.0, rng.randf_range(1.2, 3.5)).set_ease(Tween.EASE_IN_OUT)

# ── Input / skip ─────────────────────────────────────────────────
func _input(ev: InputEvent) -> void:
	if not _revealing: return
	if ev is InputEventMouseButton and ev.pressed:
		_skip_to_end = true

func _on_skip() -> void:
	if _revealing:
		_skip_to_end = true
	else:
		_result_ov.visible = false

func _refresh_ui() -> void:
	var gems := CurrencyManager.total_crystal()
	if _new_gem_lbl:    _new_gem_lbl.text    = str(gems)
	if _new_pity_bar:   _new_pity_bar.value  = _pity
	if _new_pity_lbl:   _new_pity_lbl.text   = "%d / %d" % [_pity, PITY_HARD]
	if _new_pull1:      _new_pull1.disabled  = gems < PULL_COST_1
	if _new_pull10:     _new_pull10.disabled = gems < PULL_COST_10

# ── Pull logic (unchanged) ────────────────────────────────────────
func _do_pull(count: int) -> void:
	if _revealing: return
	var cost: int = PULL_COST_10 if count == 10 else PULL_COST_1 * count
	if not CurrencyManager.spend_gems(cost): return
	var results:  Array[String] = []
	var rarities: Array[int]    = []
	for i in count:
		var r: Array = _roll()
		results.append(str(r[0]))
		rarities.append(int(r[1]))
	DomainManager.add_points("gacha")
	for i in results.size():
		if rarities[i] >= 4:
			CharacterManager.unlock(results[i])
	_refresh_ui()
	_run_reveal(results, rarities)

func _roll() -> Array:
	_pity   += 1
	_pity_4 += 1
	if _pity >= PITY_HARD:
		_pity = 0; _pity_4 = 0
		return [POOL_5[randi() % POOL_5.size()], 5]
	if _pity_4 >= 10:
		_pity_4 = 0
		return [POOL_4[randi() % POOL_4.size()], 4]
	var rate5 := RATE_5
	if _pity >= PITY_SOFT:
		rate5 = RATE_5 + 0.06 * (_pity - PITY_SOFT)
	rate5 = minf(rate5, 1.0)
	var roll := randf()
	if roll < rate5:
		_pity = 0
		return [POOL_5[randi() % POOL_5.size()], 5]
	if roll < rate5 + RATE_4:
		_pity_4 = 0
		return [POOL_4[randi() % POOL_4.size()], 4]
	return [POOL_3[randi() % POOL_3.size()], 3]

# ── Sequential reveal ─────────────────────────────────────────────
func _run_reveal(names: Array[String], rarities: Array[int]) -> void:
	_revealing   = true
	_skip_to_end = false
	_skip_btn.text = "แตะเพื่อข้าม"
	for child in _result_con.get_children():
		child.queue_free()
	_result_ov.visible  = true
	_result_con.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.z_index = 5
	_result_ov.add_child(dim)
	var td := dim.create_tween()
	td.tween_property(dim, "color:a", 0.88, 0.4)
	await td.finished

	for i in names.size():
		if _skip_to_end: break
		await _reveal_one(names[i], rarities[i])
		if not _skip_to_end:
			await get_tree().create_timer(0.55 if rarities[i] == 5 else 0.28).timeout

	dim.queue_free()
	_result_con.visible = true
	for i in names.size():
		_result_con.add_child(_make_summary_card(names[i], rarities[i]))

	_revealing   = false
	_skip_to_end = false
	_skip_btn.text = "CLOSE"

func _reveal_one(char_name: String, rarity: int) -> void:
	if rarity == 5: await _reveal_5star(char_name)
	else:           await _reveal_normal(char_name, rarity)

func _reveal_normal(char_name: String, rarity: int) -> void:
	var cb: Color; var cg: Color; var cs: Color
	match rarity:
		4: cb=Color(0.72,0.45,1.0,1.0); cg=Color(0.55,0.25,1.0,0.55); cs=Color(0.78,0.55,1.0)
		_: cb=Color(0.35,0.62,1.0,0.7); cg=Color(0.2,0.5,1.0,0.3);    cs=Color(0.5,0.72,1.0)
	var card := _build_reveal_card(char_name, rarity, cb, cg, cs, 220, 310)
	card.pivot_offset = Vector2(110, 155)
	card.scale = Vector2(0.0, 1.0)
	_result_ov.add_child(card)
	var t := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(card, "scale:x", 1.0, 0.22)
	await t.finished
	if rarity == 4: _shake(card)
	await get_tree().create_timer(0.7).timeout
	var tf := card.create_tween()
	tf.tween_property(card, "modulate:a", 0.0, 0.25)
	await tf.finished
	card.queue_free()

func _reveal_5star(char_name: String) -> void:
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.88, 0.3, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 20
	_result_ov.add_child(flash)
	var tf := flash.create_tween()
	tf.tween_property(flash, "color:a", 0.75, 0.12)
	tf.tween_property(flash, "color:a", 0.0,  0.35)
	await tf.finished

	var card := _build_reveal_card(char_name, 5,
		Color(1.0,0.82,0.2,1.0), Color(1.0,0.7,0.1,0.6), Color(1.0,0.88,0.25), 280, 380)
	card.pivot_offset = Vector2(140, 190)
	card.scale = Vector2(0.0, 1.0)
	_result_ov.add_child(card)

	var glow := ColorRect.new()
	glow.color = Color(1.0, 0.78, 0.1, 0.0)
	glow.size = Vector2(340, 440)
	glow.position = Vector2(card.position.x - 30, card.position.y - 30)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = card.z_index - 1
	_result_ov.add_child(glow)
	glow.move_to_front(); card.move_to_front(); flash.move_to_front()

	var tg := glow.create_tween().set_parallel(true)
	tg.tween_property(glow, "modulate:a", 0.45, 0.3)
	var tc := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tc.tween_property(card, "scale:x", 1.0, 0.28)
	await tc.finished

	var name_big := Label.new()
	name_big.text = char_name
	name_big.add_theme_font_size_override("font_size", 32)
	name_big.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 0.0))
	name_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_big.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	name_big.offset_top=110; name_big.offset_left=-200; name_big.offset_right=200
	name_big.z_index = 25
	_result_ov.add_child(name_big)
	var tn := name_big.create_tween()
	tn.tween_property(name_big, "theme_override_colors/font_color", Color(1.0, 0.92, 0.4, 1.0), 0.6)
	await tn.finished
	await get_tree().create_timer(1.0).timeout
	var tf2 := create_tween().set_parallel(true)
	tf2.tween_property(card,     "modulate:a", 0.0, 0.3)
	tf2.tween_property(glow,     "modulate:a", 0.0, 0.3)
	tf2.tween_property(name_big, "modulate:a", 0.0, 0.3)
	await tf2.finished
	card.queue_free(); glow.queue_free(); name_big.queue_free(); flash.queue_free()

func _build_reveal_card(char_name: String, rarity: int,
		border: Color, glow_col: Color, star_color: Color, w: float, h: float) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(w, h)
	card.size = Vector2(w, h)
	card.position = Vector2((W - w) * 0.5, (H - h) * 0.5)
	card.z_index = 15
	var sb := StyleBoxFlat.new()
	for i in [0,1,2,3]: sb.set_border_width(i, 2)
	sb.border_color = border; sb.shadow_color = glow_col; sb.shadow_size = 12
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		sb.set(r, 14)
	match rarity:
		5: sb.bg_color = Color(0.12, 0.09, 0.02, 0.97)
		4: sb.bg_color = Color(0.09, 0.05, 0.16, 0.97)
		_: sb.bg_color = Color(0.05, 0.09, 0.18, 0.97)
	card.add_theme_stylebox_override("panel", sb)

	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.add_theme_font_size_override("font_size", 16)
	stars.add_theme_color_override("font_color", star_color)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	stars.offset_top=12; stars.offset_bottom=34
	card.add_child(stars)

	# For element cards show symbol big + full name; for others just name
	if rarity == 3 and ELEM_NAME.has(char_name):
		var sym_lbl := Label.new()
		sym_lbl.text = char_name
		sym_lbl.add_theme_font_size_override("font_size", 54)
		sym_lbl.add_theme_color_override("font_color", Color(border.r, border.g, border.b, 0.9))
		sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		sym_lbl.offset_top = 50; sym_lbl.offset_bottom = 130
		sym_lbl.offset_left = -80; sym_lbl.offset_right = 80
		card.add_child(sym_lbl)

		var name_lbl := Label.new()
		name_lbl.text = ELEM_NAME.get(char_name, char_name)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(1,1,1,0.85))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		name_lbl.offset_top=-36; name_lbl.offset_bottom=-10
		card.add_child(name_lbl)
	else:
		var name_lbl := Label.new()
		name_lbl.text = char_name
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", Color(1,1,1,0.95))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		name_lbl.offset_top=-36; name_lbl.offset_bottom=-10
		card.add_child(name_lbl)

	var rlbl := Label.new()
	var ctype: String = CARD_TYPE.get(char_name, "")
	if rarity == 3: ctype = "ELEMENT CARD"
	elif ctype == "": ctype = "CHARACTER"
	rlbl.text = "%d★  %s" % [rarity, ctype]
	rlbl.add_theme_font_size_override("font_size", 10)
	rlbl.add_theme_color_override("font_color", Color(border.r, border.g, border.b, 0.8))
	rlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rlbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	rlbl.offset_top=-56; rlbl.offset_bottom=-38
	card.add_child(rlbl)
	return card

func _make_summary_card(char_name: String, rarity: int) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(88, 120)
	var sb := StyleBoxFlat.new()
	for i in [0,1,2,3]: sb.set_border_width(i, 1)
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		sb.set(r, 8)
	match rarity:
		5: sb.bg_color=Color(0.15,0.12,0.04,0.95); sb.border_color=Color(1.0,0.82,0.2,0.9); sb.shadow_color=Color(1.0,0.7,0.1,0.5); sb.shadow_size=8
		4: sb.bg_color=Color(0.1,0.06,0.18,0.95);  sb.border_color=Color(0.65,0.45,1.0,0.9); sb.shadow_color=Color(0.5,0.2,1.0,0.4);  sb.shadow_size=6
		_: sb.bg_color=Color(0.06,0.1,0.2,0.95);   sb.border_color=Color(0.37,0.62,1.0,0.4)
	card.add_theme_stylebox_override("panel", sb)

	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.add_theme_font_size_override("font_size", 9)
	match rarity:
		5: stars.add_theme_color_override("font_color", Color(1.0,0.82,0.2))
		4: stars.add_theme_color_override("font_color", Color(0.75,0.55,1.0))
		_: stars.add_theme_color_override("font_color", Color(0.5,0.7,1.0))
	stars.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stars.offset_bottom=-6; stars.offset_left=4; stars.offset_right=84; stars.offset_top=-18
	card.add_child(stars)

	# Element cards: show symbol large, full name tiny
	if rarity == 3 and ELEM_NAME.has(char_name):
		var sym := Label.new()
		sym.text = char_name
		sym.add_theme_font_size_override("font_size", 28)
		sym.add_theme_color_override("font_color", Color(0.5, 0.78, 1.0, 0.9))
		sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		sym.offset_top=14; sym.offset_bottom=54; sym.offset_left=-44; sym.offset_right=44
		card.add_child(sym)

	var name_lbl := Label.new()
	name_lbl.text = ELEM_NAME.get(char_name, char_name) if rarity == 3 else char_name
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.add_theme_color_override("font_color", Color(1,1,1,0.9))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top=-22; name_lbl.offset_bottom=-4
	card.add_child(name_lbl)

	card.modulate.a = 0.0
	var t := card.create_tween()
	t.tween_property(card, "modulate:a", 1.0, 0.3)
	return card

func _shake(node: Control) -> void:
	var orig := node.position
	var t := node.create_tween()
	for _i in 5:
		t.tween_property(node, "position:x", orig.x + randf_range(-5, 5), 0.04)
	t.tween_property(node, "position:x", orig.x, 0.04)

func _go_back() -> void:
	if _revealing: return
	SceneTransition.fade_to(SC_MAIN)
