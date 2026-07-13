extends Control

const SC_MAIN := "res://main_menu.tscn"
const PULL_COST_1  := 150
const PULL_COST_10 := 1500
const PITY_HARD    := 90
const PITY_SOFT    := 75
const RATE_5 := 0.016
const RATE_4 := 0.051

# 5★ characters
const POOL_5: Array[String] = ["Lyra", "Seraph"]
# 4★ characters + support cards
const POOL_4: Array[String] = [
	"Kael", "Mira", "Voss",
	"Acid Flask", "Iron Shield", "Ember Seal",
]
# 3★ element cards
const POOL_3: Array[String] = [
	"H", "O", "Na", "Cl", "C",
	"Fe", "N", "S", "Ca", "Mg",
	"K", "Cu", "Zn", "P", "Si",
]

const PORTRAITS: Dictionary = {
	"Alchemist": "res://image/lyra_1.png",
	"Lyra":      "res://image/lyra_2.png",
}

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

const WARP_TYPES := [
	{
		"id":     "char",
		"label":  "Void\nResonance",
		"tag":    "LIMITED",
		"icon":   "✦",
		"accent": Color(0.35, 0.75, 1.0),
		"banner_title": "Void Resonance",
		"banner_sub":   "LIMITED",
		"art_icon":     "🔥",
		"art_col":      Color(1.0, 0.40, 0.15),
		"art_img":      "res://image/lyra_1.png",
		"feat_imgs":    ["res://image/lyra_1.png", "res://image/lyra_2.png", "res://image/lyra_3.png"],
		"duration":     "อีก 21 วัน",
		"desc_lines": [
			"ทุก 10 ครั้งรับประกันได้ตัวละคร 4★ ขึ้นไป",
			"ตัวละครหลักในแบนเนอร์นี้มีอัตราได้รับสูงขึ้น",
		],
	},
	{
		"id":     "lc",
		"label":  "Formula\nResonance",
		"tag":    "LIMITED",
		"icon":   "📖",
		"accent": Color(1.0, 0.78, 0.22),
		"banner_title": "Formula Resonance",
		"banner_sub":   "LIMITED",
		"art_icon":     "📖",
		"art_col":      Color(1.0, 0.80, 0.25),
		"art_img":      "res://image/lyra_2.png",
		"feat_imgs":    ["res://image/lyra_2.png", "res://image/lyra_1.png", "res://image/lyra_3.png"],
		"duration":     "อีก 21 วัน",
		"desc_lines": [
			"ทุก 10 ครั้งรับประกันได้ไพ่ช่วย 4★ ขึ้นไป",
			"ไพ่หลักในแบนเนอร์นี้มีอัตราได้รับสูงขึ้น",
		],
	},
]

var _pity   := 0
var _pity_4 := 0
var _active_warp := 0
var _pull_history: Array = []   # [{name, entity_type, banner, time, rarity}]

var _revealing   := false
var _skip_to_end := false

var _new_gem_lbl:    Label       = null  # kept for compat — shows free crystal
var _paid_gem_lbl:   Label       = null
var _new_pity_lbl:   Label       = null
var _new_pity_bar:   ProgressBar = null
var _new_pity4_lbl:  Label       = null
var _new_pity4_bar:  ProgressBar = null
var _new_pull1:      Button      = null
var _new_pull10:     Button      = null
var _info_card_node: Panel       = null
var _warp_btns:      Array[Control] = []

@onready var _result_ov:  Control       = $ResultOverlay
@onready var _result_con: HBoxContainer = $ResultOverlay/ResultContainer
@onready var _skip_btn:   Button        = $ResultOverlay/SkipBtn


# ── Setup ─────────────────────────────────────────────────────────
func _ready() -> void:
	for n in ["Background","BgDim","BannerCard","InfoPanel","PullBtn1","PullBtn10","HistoryBtn","BackBtn"]:
		var node := get_node_or_null(n)
		if node: node.visible = false

	if _skip_btn:
		_skip_btn.icon = null
		_skip_btn.pressed.connect(_on_skip)
	if _result_ov:
		_result_ov.visible = false

	_build_hsr_ui()
	_refresh_ui()

# ── Layout constants ──────────────────────────────────────────────
const W          := 1152.0
const H          := 648.0
const TOP_H      := 52.0    # top bar height
const BOT_H      := 72.0    # bottom bar height
const THUMB_W    := 180.0   # left selector strip width
const INFO_W     := 320.0   # info card width
const SEL_CW     := 164.0   # selector card width
const SEL_CH     := 76.0

func _build_hsr_ui() -> void:
	# Background image
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = load("res://image/bggacha.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	add_child(bg)
	_add_stars(bg)

	# ── Left selector strip ──
	_build_selector_strip()

	# ── Info card ──
	_build_info_card()

	# ── Top bar ──
	_build_top_bar()

	# ── Bottom bar ──
	_build_bottom_bar()

	if _result_ov:
		_result_ov.z_index = 50
		move_child(_result_ov, get_child_count() - 1)

# ── Left selector strip ──────────────────────────────────────────
func _build_selector_strip() -> void:
	const GAP := 8.0
	var avail_h := H - TOP_H - BOT_H - GAP * (WARP_TYPES.size() - 1) - 16.0
	var btn_h   := avail_h / WARP_TYPES.size()
	var start_y := TOP_H + 8.0
	for i in WARP_TYPES.size():
		var card := _make_selector_card(WARP_TYPES[i], i == _active_warp, i, SEL_CW, btn_h)
		card.position = Vector2(8, start_y + i * (btn_h + GAP))
		card.z_index  = 5
		add_child(card)
		_warp_btns.append(card)

func _make_selector_card(wd: Dictionary, active: bool, idx: int,
		cw: float = SEL_CW, ch: float = SEL_CH) -> Panel:
	var acc: Color = wd["accent"] as Color
	var card := Panel.new()
	card.size = Vector2(cw, ch)
	card.clip_contents = true
	card.mouse_filter  = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.02, 0.06, 0.18, 1.0) if active else Color(0.03, 0.04, 0.10, 0.80)
	sb.border_color = Color(acc.r, acc.g, acc.b, 0.85 if active else 0.22)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	if active:
		sb.shadow_color = Color(acc.r, acc.g, acc.b, 0.55)
		sb.shadow_size  = 8
	card.add_theme_stylebox_override("panel", sb)

	# Icon centered (no portrait art)
	var ico := _lbl(str(wd["icon"]), 22, Color(acc.r, acc.g, acc.b, 0.85))
	ico.size = Vector2(cw, ch - 28)
	ico.position = Vector2(0, 8)
	ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ico.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	card.add_child(ico)

	var stripe := ColorRect.new()
	stripe.color = Color(acc.r, acc.g, acc.b, 0.85 if active else 0.35)
	stripe.size  = Vector2(cw, 3)
	stripe.position = Vector2.ZERO
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stripe)

	var bot := ColorRect.new()
	bot.color = Color(0.01, 0.01, 0.04, 0.88)
	bot.size  = Vector2(cw, 20)
	bot.position = Vector2(0, ch - 20)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bot)

	var lbl := _lbl(str(wd["label"]).replace("\n", " "), 8,
					Color(1, 1, 1, 0.95 if active else 0.55))
	lbl.size = Vector2(cw, 20)
	lbl.position = Vector2(0, ch - 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_child(lbl)

	var tag := _lbl(str(wd["tag"]), 7, Color(acc.r, acc.g, acc.b, 0.85 if active else 0.35))
	tag.size     = Vector2(cw - 4, 14)
	tag.position = Vector2(2, 5)
	card.add_child(tag)

	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_on_warp_tab(idx)
	)
	return card

func _rebuild_art() -> void:
	var old := get_node_or_null("_ArtRect")
	if old: old.queue_free()
	var d: Dictionary = WARP_TYPES[_active_warp]
	var art_tex: Texture2D = _load_png(str(d.get("art_img", "")))
	if not art_tex: return
	var art_y  := TOP_H
	var art_h  := H - TOP_H - BOT_H
	var art_rect := TextureRect.new()
	art_rect.name         = "_ArtRect"
	art_rect.texture      = art_tex
	art_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_rect.size         = Vector2(W - THUMB_W, art_h)
	art_rect.position     = Vector2(THUMB_W, art_y)
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_rect.z_index      = 0
	add_child(art_rect)

# ── Info card (left panel, HSR-style white/translucent card) ─────
func _build_info_card() -> void:
	var d: Dictionary = WARP_TYPES[_active_warp]
	var acc: Color = d["accent"] as Color

	var ix := THUMB_W + 12.0
	var iy := TOP_H + 8.0
	var iw := INFO_W
	var ih := H - TOP_H - BOT_H - 16.0

	var card_sb := _sb(Color(0.93, 0.94, 0.97, 0.96), Color(0.75, 0.80, 0.95, 0.40), 14, 1)
	card_sb.shadow_color = Color(0, 0, 0, 0.45)
	card_sb.shadow_size  = 14

	var card := Panel.new()
	card.name     = "_InfoCard"
	card.size     = Vector2(iw, ih)
	card.position = Vector2(ix, iy)
	card.add_theme_stylebox_override("panel", card_sb)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_index  = 4
	add_child(card)
	_info_card_node = card

	var pad := 16.0
	var cy  := pad

	# Tag chip
	var tag_sb := _sb(Color(acc.r * 0.18, acc.g * 0.25, acc.b * 0.55, 0.92),
		Color(acc.r, acc.g, acc.b, 0.50), 4, 1)
	var tag := Panel.new()
	tag.size     = Vector2(140, 22)
	tag.position = Vector2(pad, cy)
	tag.add_theme_stylebox_override("panel", tag_sb)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tag)
	var tag_lbl := Label.new()
	tag_lbl.text = str(d.get("banner_sub", ""))
	tag_lbl.add_theme_font_size_override("font_size", 10)
	tag_lbl.add_theme_color_override("font_color", Color(acc.r + 0.15, acc.g + 0.10, acc.b, 1.0))
	tag_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(tag_lbl)
	cy += 30

	# Banner title
	var title := Label.new()
	title.text = str(d["banner_title"])
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.10, 0.12, 0.22, 0.95))
	title.size     = Vector2(iw - pad * 2, 52)
	title.position = Vector2(pad, cy)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)
	cy += 58

	# Duration
	var dur_lbl := Label.new()
	dur_lbl.text = str(d.get("duration", "ถาวร"))
	dur_lbl.add_theme_font_size_override("font_size", 12)
	dur_lbl.add_theme_color_override("font_color", Color(0.30, 0.35, 0.50, 0.80))
	dur_lbl.size     = Vector2(iw - pad * 2, 20)
	dur_lbl.position = Vector2(pad, cy)
	dur_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dur_lbl)
	cy += 28

	# Separator
	var sep := ColorRect.new()
	sep.size     = Vector2(iw - pad * 2, 1)
	sep.position = Vector2(pad, cy)
	sep.color    = Color(0.18, 0.22, 0.40, 0.18)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep)
	cy += 12

	# Description lines (dark text)
	for desc_line in d.get("desc_lines", []) as Array:
		var dl := Label.new()
		dl.text = str(desc_line)
		dl.add_theme_font_size_override("font_size", 11)
		dl.add_theme_color_override("font_color", Color(0.22, 0.28, 0.45, 0.85))
		dl.size     = Vector2(iw - pad * 2, 32)
		dl.position = Vector2(pad, cy)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(dl)
		cy += 34

	cy += 4


	# Pity section
	var sep2 := ColorRect.new()
	sep2.size     = Vector2(iw - pad * 2, 1)
	sep2.position = Vector2(pad, cy)
	sep2.color    = Color(1, 1, 1, 0.10)
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep2)
	cy += 10

	var pity5_hdr := Label.new()
	pity5_hdr.text = "รับประกัน 5★ ทุก 90 ครั้ง (Soft pity 75)"
	pity5_hdr.add_theme_font_size_override("font_size", 10)
	pity5_hdr.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0, 0.50))
	pity5_hdr.size     = Vector2(iw - pad * 2, 16)
	pity5_hdr.position = Vector2(pad, cy)
	pity5_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(pity5_hdr)
	cy += 18

	var pity5_row := HBoxContainer.new()
	pity5_row.size     = Vector2(iw - pad * 2, 16)
	pity5_row.position = Vector2(pad, cy)
	pity5_row.add_theme_constant_override("separation", 8)
	pity5_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(pity5_row)

	_new_pity_bar = ProgressBar.new()
	_new_pity_bar.max_value       = PITY_HARD
	_new_pity_bar.value           = _pity
	_new_pity_bar.show_percentage = false
	_new_pity_bar.custom_minimum_size = Vector2(iw - pad * 2 - 80, 6)
	_new_pity_bar.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	pity5_row.add_child(_new_pity_bar)

	_new_pity_lbl = Label.new()
	_new_pity_lbl.text = "%d / %d" % [_pity, PITY_HARD]
	_new_pity_lbl.add_theme_font_size_override("font_size", 11)
	_new_pity_lbl.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0, 0.90))
	_new_pity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pity5_row.add_child(_new_pity_lbl)
	cy += 22

	var pity4_hdr := Label.new()
	pity4_hdr.text = "รับประกัน 4★ ทุก 10 ครั้ง"
	pity4_hdr.add_theme_font_size_override("font_size", 10)
	pity4_hdr.add_theme_color_override("font_color", Color(0.78, 0.55, 1.0, 0.50))
	pity4_hdr.size     = Vector2(iw - pad * 2, 16)
	pity4_hdr.position = Vector2(pad, cy)
	pity4_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(pity4_hdr)
	cy += 18

	var pity4_row := HBoxContainer.new()
	pity4_row.size     = Vector2(iw - pad * 2, 16)
	pity4_row.position = Vector2(pad, cy)
	pity4_row.add_theme_constant_override("separation", 8)
	pity4_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(pity4_row)

	_new_pity4_bar = ProgressBar.new()
	_new_pity4_bar.max_value       = 10
	_new_pity4_bar.value           = _pity_4
	_new_pity4_bar.show_percentage = false
	_new_pity4_bar.custom_minimum_size = Vector2(iw - pad * 2 - 80, 6)
	_new_pity4_bar.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	pity4_row.add_child(_new_pity4_bar)

	_new_pity4_lbl = Label.new()
	_new_pity4_lbl.text = "%d / 10" % _pity_4
	_new_pity4_lbl.add_theme_font_size_override("font_size", 11)
	_new_pity4_lbl.add_theme_color_override("font_color", Color(0.78, 0.55, 1.0, 0.90))
	_new_pity4_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pity4_row.add_child(_new_pity4_lbl)
	cy += 28

	# ประวัติ button inside white card (bottom)
	var hist_btn := _ghost_btn("ประวัติ", 12)
	hist_btn.size     = Vector2(iw - pad * 2, 40)
	hist_btn.position = Vector2(pad, ih - pad - 40)
	hist_btn.pressed.connect(_show_history_overlay)
	card.add_child(hist_btn)

# ── Top bar ──────────────────────────────────────────────────────
func _build_top_bar() -> void:
	var bar_sb := _sb(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0)
	var bar := Panel.new()
	bar.name     = "_TopBar"
	bar.size     = Vector2(W, TOP_H)
	bar.position = Vector2.ZERO
	bar.add_theme_stylebox_override("panel", bar_sb)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.z_index  = 6
	add_child(bar)

	var title_lbl := Label.new()
	title_lbl.text = "Void Gate"
	title_lbl.position = Vector2(16, 0)
	title_lbl.size = Vector2(200, TOP_H)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0, 1.0))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(title_lbl)

	# Back/close button — top-right (X style like reference)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.size     = Vector2(40, 40)
	close_btn.position = Vector2(W - 48, (TOP_H - 40) * 0.5)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	close_btn.add_theme_stylebox_override("normal",  _sb(Color(1,1,1,0.06), Color(1,1,1,0.12), 8, 1))
	close_btn.add_theme_stylebox_override("hover",   _sb(Color(1,1,1,0.12), Color(1,1,1,0.22), 8, 1))
	close_btn.add_theme_stylebox_override("pressed", _sb(Color(1,1,1,0.06), Color(1,1,1,0.12), 8, 1))
	close_btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	close_btn.pressed.connect(_go_back)
	bar.add_child(close_btn)

	# Currency row (top-right, left of close button)
	var curr_row := HBoxContainer.new()
	curr_row.add_theme_constant_override("separation", 6)
	curr_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(curr_row)

	var gem_tex  := _load_png("res://image/crystal_gem.png")
	var paid_tex := _load_png("res://image/icon_paid.png")

	_new_gem_lbl  = _make_curr_pill(curr_row, gem_tex,  Color(0.35, 0.85, 1.0, 1.0))
	_paid_gem_lbl = _make_curr_pill(curr_row, paid_tex, Color(0.78, 0.55, 1.0, 1.0))

	curr_row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	curr_row.offset_right = -56
	curr_row.offset_left  = -296

# ── Bottom bar (Warp ×1 and Warp ×10 buttons) ───────────────────
func _build_bottom_bar() -> void:
	var bar_sb := _sb(Color(0.03, 0.04, 0.12, 0.92), Color(1,1,1, 0.07), 0, 1)
	var bar := Panel.new()
	bar.name     = "_BottomBar"
	bar.size     = Vector2(W, BOT_H)
	bar.position = Vector2(0, H - BOT_H)
	bar.add_theme_stylebox_override("panel", bar_sb)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.z_index  = 6
	add_child(bar)

	var btn_h := 48.0
	var btn_y := (BOT_H - btn_h) * 0.5

	# Right warp buttons — bigger for easy tapping
	var btn_w2 := 210.0
	var btn_w1 := 210.0
	var bx2    := W - btn_w2 - 16.0
	var bx1    := bx2 - btn_w1 - 12.0

	_new_pull1 = _warp_btn(1)
	_new_pull1.size     = Vector2(btn_w1, btn_h)
	_new_pull1.position = Vector2(bx1, btn_y)
	_new_pull1.pressed.connect(func(): _do_pull(1))
	bar.add_child(_new_pull1)

	_new_pull10 = _warp_btn(10)
	_new_pull10.size     = Vector2(btn_w2, btn_h)
	_new_pull10.position = Vector2(bx2, btn_y)
	_new_pull10.pressed.connect(func(): _do_pull(10))
	bar.add_child(_new_pull10)

func _warp_btn(count: int) -> Button:
	var btn := Button.new()
	var sb_empty := StyleBoxFlat.new()
	sb_empty.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal",  sb_empty)
	btn.add_theme_stylebox_override("hover",   sb_empty)
	btn.add_theme_stylebox_override("pressed", sb_empty)
	btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.clip_contents = true

	# btgacha.jpg as button background — STRETCH_SCALE avoids the aspect-cover
	# crop that produced a thin cropped "strip" (image is 1344x768, far wider
	# aspect than the 210x48 button, so COVERED mode zoomed into a sliver)
	var bg_tex := _load_png("res://image/btgacha.jpg")
	if bg_tex:
		var bg_rect := TextureRect.new()
		bg_rect.texture      = bg_tex
		bg_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
		bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		bg_rect.material = mat
		btn.add_child(bg_rect)
	else:
		var sb_n := _sb(Color(0.14, 0.22, 0.55, 1.0), Color(0.35, 0.55, 1.0, 0.5), 10, 1)
		btn.add_theme_stylebox_override("normal",  sb_n)
		btn.add_theme_stylebox_override("hover",   _sb(Color(0.20, 0.30, 0.68, 1.0), Color(0.45, 0.65, 1.0, 0.7), 10, 1))
		btn.add_theme_stylebox_override("pressed", sb_n)

	# gacha_card icon on the left — BLEND_MODE_ADD makes black bg transparent
	var card_tex := _load_png("res://image/gacha_card.jpg")
	if card_tex:
		var ico := TextureRect.new()
		ico.texture      = card_tex
		ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.size         = Vector2(34, 34)
		ico.position     = Vector2(12, 6)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ico_mat := CanvasItemMaterial.new()
		ico_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		ico.material = ico_mat
		btn.add_child(ico)

	# Label: "สุ่ม ×1" / "สุ่ม ×10" — offset right to leave room for icon
	var warp_lbl := Label.new()
	warp_lbl.text = "Synthesize  ×%d" % count
	warp_lbl.add_theme_font_size_override("font_size", 16)
	warp_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	warp_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	warp_lbl.offset_left = 36
	warp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warp_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	warp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(warp_lbl)
	return btn

# ── Warp tab ──────────────────────────────────────────────────────
func _on_warp_tab(idx: int) -> void:
	if idx == _active_warp: return
	_active_warp = idx
	if is_instance_valid(_info_card_node): _info_card_node.free()
	_info_card_node = null
	_new_pity_lbl = null; _new_pity_bar = null
	_new_pity4_lbl = null; _new_pity4_bar = null
	# Rebuild left tab buttons
	for btn in _warp_btns:
		if is_instance_valid(btn): btn.queue_free()
	_warp_btns.clear()
	_build_selector_strip()
	# Rebuild info card
	_build_info_card()
	_refresh_ui()

# ── Helpers ───────────────────────────────────────────────────────
func _lbl(text: String, font_sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_sz)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _blue_glow_sb(alpha: float = 1.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.02, 0.06, 0.18, alpha)
	sb.border_color = Color(0.25, 0.60, 1.0, 0.70 * alpha)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0.20, 0.55, 1.0, 0.45 * alpha)
	sb.shadow_size  = 6
	return sb

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.1fK" % (n / 1000.0)
	return str(n)

func _load_png(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

# Builds a main-menu-style pill (dark bg + icon + amount label + "+")
# Returns the Label so the caller can update the value.
func _make_curr_pill(parent: HBoxContainer, icon_tex: Texture2D, _col: Color) -> Label:
	var pill := Panel.new()
	var pill_sb := StyleBoxFlat.new()
	pill_sb.bg_color = Color(0.08, 0.09, 0.14, 0.92)
	pill_sb.border_color = Color(1, 1, 1, 0.08)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: pill_sb.set_border_width(side, 1)
	pill_sb.corner_radius_top_left     = 8
	pill_sb.corner_radius_top_right    = 8
	pill_sb.corner_radius_bottom_right = 8
	pill_sb.corner_radius_bottom_left  = 8
	pill.add_theme_stylebox_override("panel", pill_sb)
	pill.custom_minimum_size = Vector2(110, 30)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)

	if icon_tex:
		var ico := TextureRect.new()
		ico.texture = icon_tex
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ico.size     = Vector2(22, 22)
		ico.position = Vector2(5, 4)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(ico)

	var val_lbl := Label.new()
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0, 1.0))
	val_lbl.size     = Vector2(60, 30)
	val_lbl.position = Vector2(31, 0)
	val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(val_lbl)

	var plus_lbl := Label.new()
	plus_lbl.text = "+"
	plus_lbl.add_theme_font_size_override("font_size", 14)
	plus_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.80))
	plus_lbl.size     = Vector2(18, 30)
	plus_lbl.position = Vector2(92, 0)
	plus_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(plus_lbl)

	return val_lbl

func _sb(bg: Color, bdr: Color, radius: int, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = bdr
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: s.set_border_width(side, bw)
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

# ── Input / skip ──────────────────────────────────────────────────
func _input(ev: InputEvent) -> void:
	if not _revealing: return
	if ev is InputEventMouseButton and ev.pressed:
		_skip_to_end = true

func _on_skip() -> void:
	if _revealing: _skip_to_end = true
	else:          _result_ov.visible = false

func _refresh_ui() -> void:
	var gems := CurrencyManager.total_crystal()
	if _new_gem_lbl:   _new_gem_lbl.text    = _fmt(CurrencyManager.free_crystal)
	if _paid_gem_lbl:  _paid_gem_lbl.text   = _fmt(CurrencyManager.paid_crystal)
	if _new_pity_bar:  _new_pity_bar.value  = _pity
	if _new_pity_lbl:  _new_pity_lbl.text   = "Pity  %d / %d" % [_pity, PITY_HARD]
	if _new_pity4_bar: _new_pity4_bar.value = _pity_4
	if _new_pity4_lbl: _new_pity4_lbl.text  = "4★  %d / 10" % _pity_4
	if _new_pull1:     _new_pull1.disabled  = gems < PULL_COST_1
	if _new_pull10:    _new_pull10.disabled = gems < PULL_COST_10

# ── Pull logic ────────────────────────────────────────────────────
func _do_pull(count: int) -> void:
	if _revealing: return
	_show_confirm_dialog(count)

func _show_confirm_dialog(count: int) -> void:
	if get_node_or_null("_ConfirmDialog") != null: return
	var cost: int = PULL_COST_10 if count == 10 else PULL_COST_1 * count
	var cost_str := "1,500" if count == 10 else str(cost)

	# Dim overlay
	var dim := ColorRect.new()
	dim.name = "_ConfirmDialog"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 80
	add_child(dim)

	# Dialog box
	var box := Panel.new()
	var bw := 420.0; var bh := 210.0
	box.size = Vector2(bw, bh)
	box.position = Vector2((W - bw) * 0.5, (H - bh) * 0.5)
	var box_sb := StyleBoxFlat.new()
	box_sb.bg_color = Color(0.06, 0.08, 0.18, 0.97)
	box_sb.border_color = Color(0.35, 0.65, 1.0, 0.6)
	box_sb.set_border_width_all(1)
	box_sb.set_corner_radius_all(14)
	box_sb.shadow_color = Color(0.2, 0.5, 1.0, 0.4)
	box_sb.shadow_size = 14
	box.add_theme_stylebox_override("panel", box_sb)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.add_child(box)

	# Title
	var title := Label.new()
	title.text = "ยืนยันการสุ่ม"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(bw, 36)
	title.position = Vector2(0, 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	# Description — cost row with crystal icon
	var cost_row := HBoxContainer.new()
	cost_row.size     = Vector2(bw - 40, 28)
	cost_row.position = Vector2(20, 62)
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override("separation", 4)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cost_row)

	var cost_pre := Label.new()
	cost_pre.text = "ใช้ %s" % cost_str
	cost_pre.add_theme_font_size_override("font_size", 13)
	cost_pre.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0, 0.90))
	cost_pre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(cost_pre)

	var gem_ico := TextureRect.new()
	var gem_tex := _load_png("res://image/crystal_gem.png")
	if gem_tex: gem_ico.texture = gem_tex
	gem_ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	gem_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem_ico.custom_minimum_size = Vector2(18, 18)
	gem_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(gem_ico)

	var cost_suf := Label.new()
	cost_suf.text = "เพื่อ Synthesize %d ครั้ง" % count
	cost_suf.add_theme_font_size_override("font_size", 13)
	cost_suf.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0, 0.90))
	cost_suf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(cost_suf)

	var desc2 := Label.new()
	desc2.text = "และรับ %d เม็ดสุ่ม (การ์ดข้อมูลบุคคล)" % count
	desc2.add_theme_font_size_override("font_size", 11)
	desc2.add_theme_color_override("font_color", Color(0.70, 0.76, 0.90, 0.72))
	desc2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc2.size     = Vector2(bw - 40, 22)
	desc2.position = Vector2(20, 94)
	desc2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(desc2)

	# Buttons row
	var btn_y := bh - 56.0
	var btn_w := 140.0

	var cancel_btn := Button.new()
	cancel_btn.text = "ยกเลิก"
	cancel_btn.size = Vector2(btn_w, 38)
	cancel_btn.position = Vector2((bw * 0.5) - btn_w - 8, btn_y)
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.add_theme_color_override("font_color", Color(0.75, 0.82, 1.0, 0.80))
	cancel_btn.add_theme_stylebox_override("normal",  _sb(Color(1,1,1,0.05), Color(1,1,1,0.12), 10, 1))
	cancel_btn.add_theme_stylebox_override("hover",   _sb(Color(1,1,1,0.10), Color(1,1,1,0.20), 10, 1))
	cancel_btn.add_theme_stylebox_override("pressed", _sb(Color(1,1,1,0.05), Color(1,1,1,0.12), 10, 1))
	cancel_btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	cancel_btn.pressed.connect(func(): dim.queue_free())
	box.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "ยืนยัน (%s)" % cost_str
	if gem_tex: confirm_btn.icon = gem_tex
	confirm_btn.expand_icon = true
	# crystal_gem.png is 1024x1024 — Button.icon renders at native size
	# unless capped; match the 18px icon used in cost_row above (same group)
	confirm_btn.add_theme_constant_override("icon_max_width", 18)
	confirm_btn.size = Vector2(btn_w, 38)
	confirm_btn.position = Vector2((bw * 0.5) + 8, btn_y)
	confirm_btn.add_theme_font_size_override("font_size", 13)
	confirm_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	confirm_btn.add_theme_stylebox_override("normal",  _sb(Color(0.15, 0.35, 0.80, 1.0), Color(0.40, 0.65, 1.0, 0.7), 10, 1))
	confirm_btn.add_theme_stylebox_override("hover",   _sb(Color(0.20, 0.42, 0.90, 1.0), Color(0.50, 0.75, 1.0, 0.9), 10, 1))
	confirm_btn.add_theme_stylebox_override("pressed", _sb(Color(0.15, 0.35, 0.80, 1.0), Color(0.40, 0.65, 1.0, 0.7), 10, 1))
	confirm_btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	confirm_btn.pressed.connect(func():
		dim.queue_free()
		_execute_pull(count)
	)
	box.add_child(confirm_btn)

	# Fade in
	dim.modulate.a = 0.0
	var t := dim.create_tween()
	t.tween_property(dim, "modulate:a", 1.0, 0.18)

func _execute_pull(count: int) -> void:
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
	var banner_name: String = str(WARP_TYPES[_active_warp].get("banner_title", ""))
	var now := Time.get_datetime_string_from_system(false, true)
	for i in results.size():
		if rarities[i] >= 4:
			CharacterManager.unlock(results[i])
		var etype: String
		if rarities[i] == 3:
			etype = "Element Card"
		elif CARD_TYPE.get(results[i], "") == "SUPPORT":
			etype = "Formula Card"
		else:
			etype = "Character"
		_pull_history.insert(0, {
			"name": results[i], "entity_type": etype,
			"banner": banner_name, "time": now, "rarity": rarities[i]
		})
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
	if is_instance_valid(_skip_btn): _skip_btn.text = "แตะเพื่อข้าม"
	for child in _result_con.get_children(): child.queue_free()
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
	# Sort indices by rarity descending so highest rarity appears first (left)
	var indices := range(names.size())
	indices.sort_custom(func(a, b): return rarities[a] > rarities[b])
	for i in indices:
		_result_con.add_child(_make_summary_card(names[i], rarities[i]))

	_revealing   = false
	_skip_to_end = false
	if is_instance_valid(_skip_btn): _skip_btn.text = "CLOSE"

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

	if rarity == 3 and ELEM_NAME.has(char_name):
		var sym_lbl := Label.new()
		sym_lbl.text = char_name
		sym_lbl.add_theme_font_size_override("font_size", 54)
		sym_lbl.add_theme_color_override("font_color", Color(border.r, border.g, border.b, 0.9))
		sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		sym_lbl.offset_top=50; sym_lbl.offset_bottom=130; sym_lbl.offset_left=-80; sym_lbl.offset_right=80
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
	const CW := 90.0
	const CH := 126.0
	var portrait_h := CH - 30.0

	var r_col: Color
	match rarity:
		5: r_col = Color(1.0,  0.80, 0.20)
		4: r_col = Color(0.72, 0.50, 1.00)
		_: r_col = Color(0.35, 0.65, 1.00)

	var card := Panel.new()
	card.custom_minimum_size = Vector2(CW, CH)
	card.size = Vector2(CW, CH)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _blue_glow_sb())

	# 1) Portrait background
	var pbg := ColorRect.new()
	pbg.color = Color(0.03, 0.06, 0.18, 1.0)
	pbg.size  = Vector2(CW, portrait_h)
	pbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(pbg)

	# 2) Content (portrait or element symbol)
	if rarity >= 4:
		var portrait_path: String = PORTRAITS.get(char_name, "")
		if portrait_path != "" and ResourceLoader.exists(portrait_path):
			var ptex := TextureRect.new()
			ptex.texture      = load(portrait_path)
			ptex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			ptex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			ptex.size         = Vector2(CW, portrait_h + 16)
			ptex.position     = Vector2(0, 10)
			ptex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(ptex)
		else:
			var nm2 := _lbl(char_name, 22, Color(r_col.r, r_col.g, r_col.b, 0.90))
			nm2.size = Vector2(CW, portrait_h)
			nm2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nm2.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			card.add_child(nm2)
	else:
		# Element card: large symbol
		var sym := _lbl(char_name, 32, Color(r_col.r, r_col.g, r_col.b, 0.90))
		sym.size = Vector2(CW, portrait_h)
		sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		card.add_child(sym)

	# 3) Bottom info overlay
	var bot := ColorRect.new()
	bot.color    = Color(0.01, 0.01, 0.04, 0.88)
	bot.size     = Vector2(CW, 30)
	bot.position = Vector2(0, CH - 30)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bot)

	# 4) Rarity stripe at very top
	var stripe := ColorRect.new()
	stripe.color = Color(r_col.r, r_col.g, r_col.b, 0.80)
	stripe.size  = Vector2(CW, 3)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stripe)

	# 5) Stars (below stripe)
	var stars := _lbl("★".repeat(rarity), 8, Color(r_col.r, r_col.g, r_col.b, 0.90))
	stars.size     = Vector2(CW - 4, 13)
	stars.position = Vector2(2, 4)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(stars)

	# 6) Name at bottom
	var display_name: String = str(ELEM_NAME.get(char_name, char_name)) if rarity == 3 else char_name
	var nm := _lbl(display_name, 8, Color(0.92, 0.94, 1.0, 1.0))
	nm.size     = Vector2(CW, 18)
	nm.position = Vector2(0, CH - 20)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_child(nm)

	# 7) Card frame — g1.jpg BLEND_MODE_ADD (last child, renders on top)
	var frame_tex := _load_png("res://image/g1.jpg")
	if frame_tex:
		var frame := TextureRect.new()
		frame.texture      = frame_tex
		frame.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		frame.material = mat
		card.add_child(frame)

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

func _make_visible_back_btn(pos: Vector2, sz: Vector2, callback: Callable) -> Control:
	return _make_back_btn(pos, sz, callback)

func _show_history_overlay() -> void:
	if get_node_or_null("_HistoryOv") != null: return
	const OW := 900.0; const OH := 520.0
	const COL_W := [160.0, 200.0, 220.0, 210.0]
	const COL_H := ["Entity Type", "Entity Name", "Synthesize Type", "Time"]

	# Dim backdrop
	var dim := ColorRect.new()
	dim.name = "_HistoryOv"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 90
	add_child(dim)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			dim.queue_free()
	)

	# Main panel
	var box := Panel.new()
	box.size     = Vector2(OW, OH)
	box.position = Vector2((W - OW) * 0.5, (H - OH) * 0.5)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	var box_sb := StyleBoxFlat.new()
	box_sb.bg_color     = Color(0.93, 0.92, 0.88, 0.98)
	box_sb.border_color = Color(0.65, 0.60, 0.50, 0.60)
	box_sb.set_border_width_all(1)
	box_sb.set_corner_radius_all(6)
	box_sb.shadow_color = Color(0, 0, 0, 0.50)
	box_sb.shadow_size  = 16
	box.add_theme_stylebox_override("panel", box_sb)
	dim.add_child(box)
	box.mouse_filter = Control.MOUSE_FILTER_STOP  # block clicks from reaching dim

	# Tab bar background
	var tab_bg := ColorRect.new()
	tab_bg.color = Color(0.18, 0.16, 0.14, 1.0)
	tab_bg.size  = Vector2(OW, 48)
	tab_bg.position = Vector2.ZERO
	tab_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(tab_bg)

	# Tab: View Details (inactive)
	var tab_det := Button.new()
	tab_det.text = "View Details"
	tab_det.size = Vector2(200, 48)
	tab_det.position = Vector2(0, 0)
	tab_det.add_theme_font_size_override("font_size", 14)
	tab_det.add_theme_color_override("font_color", Color(0.70, 0.68, 0.62, 1.0))
	tab_det.add_theme_stylebox_override("normal",  _sb(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
	tab_det.add_theme_stylebox_override("hover",   _sb(Color(1,1,1,0.06), Color(0,0,0,0), 0, 0))
	tab_det.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	box.add_child(tab_det)

	# Vertical divider between tabs
	var vdiv := ColorRect.new()
	vdiv.color = Color(0.50, 0.48, 0.44, 0.5)
	vdiv.size  = Vector2(1, 28)
	vdiv.position = Vector2(200, 10)
	vdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(vdiv)

	# Tab: Records (active)
	var tab_rec := Button.new()
	tab_rec.text = "Records"
	tab_rec.size = Vector2(160, 48)
	tab_rec.position = Vector2(201, 0)
	tab_rec.add_theme_font_size_override("font_size", 14)
	tab_rec.add_theme_color_override("font_color", Color(0.85, 0.72, 0.35, 1.0))
	tab_rec.add_theme_stylebox_override("normal",  _sb(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
	tab_rec.add_theme_stylebox_override("hover",   _sb(Color(1,1,1,0.06), Color(0,0,0,0), 0, 0))
	tab_rec.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	box.add_child(tab_rec)

	# Gold underline for active tab
	var uline := ColorRect.new()
	uline.color    = Color(0.85, 0.72, 0.35, 1.0)
	uline.size     = Vector2(80, 2)
	uline.position = Vector2(201 + 40, 46)
	uline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(uline)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.size = Vector2(42, 42)
	close_btn.position = Vector2(OW - 48, 3)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.70, 0.68, 0.62, 1.0))
	close_btn.add_theme_stylebox_override("normal",  _sb(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
	close_btn.add_theme_stylebox_override("hover",   _sb(Color(1,1,1,0.08), Color(0,0,0,0), 0, 0))
	close_btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	close_btn.pressed.connect(func(): dim.queue_free())
	box.add_child(close_btn)

	# Divider below tab bar
	var hdiv := ColorRect.new()
	hdiv.color = Color(0.60, 0.58, 0.52, 0.40)
	hdiv.size  = Vector2(OW, 1)
	hdiv.position = Vector2(0, 48)
	hdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hdiv)

	# Banner title inside content
	var active_title: String = str(WARP_TYPES[_active_warp].get("banner_title", ""))
	var banner_lbl := Label.new()
	banner_lbl.text = active_title
	banner_lbl.position = Vector2(20, 58)
	banner_lbl.size = Vector2(OW - 40, 28)
	banner_lbl.add_theme_font_size_override("font_size", 18)
	banner_lbl.add_theme_color_override("font_color", Color(0.12, 0.10, 0.08, 0.95))
	banner_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(banner_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "ดูประวัติ Synthesize ย้อนหลัง ข้อมูลอาจใช้เวลาอัปเดตสักครู่"
	sub_lbl.position = Vector2(20, 88)
	sub_lbl.size = Vector2(OW - 40, 22)
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(0.35, 0.33, 0.28, 0.85))
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(sub_lbl)

	# Table header
	const TABLE_Y := 118.0
	const ROW_H   := 44.0
	var hdr_bg := ColorRect.new()
	hdr_bg.color    = Color(0.85, 0.82, 0.76, 0.55)
	hdr_bg.size     = Vector2(OW - 2, ROW_H)
	hdr_bg.position = Vector2(1, TABLE_Y)
	hdr_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hdr_bg)

	var hx := 20.0
	for c in COL_H.size():
		var hl := Label.new()
		hl.text = COL_H[c]
		hl.position = Vector2(hx, TABLE_Y + 4)
		hl.size = Vector2(COL_W[c], ROW_H - 8)
		hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hl.add_theme_font_size_override("font_size", 12)
		hl.add_theme_color_override("font_color", Color(0.68, 0.55, 0.22, 1.0))
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(hl)
		hx += COL_W[c]

	# Scrollable rows
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, TABLE_Y + ROW_H)
	scroll.size     = Vector2(OW, OH - TABLE_Y - ROW_H - 4)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(scroll)

	var rows_vbox := VBoxContainer.new()
	rows_vbox.custom_minimum_size = Vector2(OW, 0)
	rows_vbox.add_theme_constant_override("separation", 0)
	scroll.add_child(rows_vbox)

	var rarity_cols := {5: Color(0.85,0.68,0.18,1.0), 4: Color(0.65,0.42,0.92,1.0), 3: Color(0.35,0.55,0.90,1.0)}

	if _pull_history.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "ยังไม่มีประวัติการ Synthesize"
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38, 0.80))
		empty_lbl.custom_minimum_size = Vector2(OW, 80)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		rows_vbox.add_child(empty_lbl)
	else:
		for i in _pull_history.size():
			var entry: Dictionary = _pull_history[i]
			var row_bg := Panel.new()
			row_bg.custom_minimum_size = Vector2(OW, ROW_H)
			var row_sb := StyleBoxFlat.new()
			row_sb.bg_color = Color(0.96, 0.95, 0.91, 1.0) if i % 2 == 0 else Color(0.90, 0.89, 0.85, 1.0)
			row_sb.set_border_width(SIDE_BOTTOM, 1)
			row_sb.border_color = Color(0.75, 0.73, 0.68, 0.35)
			row_bg.add_theme_stylebox_override("panel", row_sb)
			row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rows_vbox.add_child(row_bg)

			var rx := 20.0
			var cols_data: Array = [
				{"text": str(entry.get("entity_type","")), "col": Color(0.15,0.13,0.10,0.90)},
				{"text": str(entry.get("name","")),        "col": rarity_cols.get(int(entry.get("rarity",3)), Color(0.15,0.13,0.10,0.90))},
				{"text": str(entry.get("banner","")),      "col": Color(0.15,0.13,0.10,0.80)},
				{"text": str(entry.get("time","")),        "col": Color(0.35,0.33,0.28,0.80)},
			]
			for c in cols_data.size():
				var cl := Label.new()
				cl.text = cols_data[c]["text"]
				cl.position = Vector2(rx, 4)
				cl.size = Vector2(COL_W[c] - 8, ROW_H - 8)
				cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				cl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				cl.add_theme_font_size_override("font_size", 12)
				cl.add_theme_color_override("font_color", cols_data[c]["col"])
				cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				row_bg.add_child(cl)
				rx += COL_W[c]

	# Fade in
	dim.modulate.a = 0.0
	dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.18)

func _go_back() -> void:
	if _revealing: return
	SceneTransition.fade_to(SC_MAIN)
