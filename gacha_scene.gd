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
		"label":  "Character\nEvent Warp",
		"tag":    "LIMITED",
		"icon":   "✦",
		"accent": Color(0.35, 0.75, 1.0),
		"banner_title": "Lyra · นักเล่นแร่แรงสูง",
		"banner_sub":   "5★  Rate Up  •  LIMITED",
		"art_icon":     "🔥",
		"art_col":      Color(1.0, 0.40, 0.15),
		"duration":     "อีก 21 วัน",
		"desc_lines": [
			"ทุก 10 ครั้งรับประกันได้ตัวละคร 4★ ขึ้นไป",
			"ตัวละครหลักในแบนเนอร์นี้มีอัตราได้รับสูงขึ้น",
		],
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
		"duration":     "อีก 21 วัน",
		"desc_lines": [
			"ทุก 10 ครั้งรับประกันได้ไพ่ช่วย 4★ ขึ้นไป",
			"ไพ่หลักในแบนเนอร์นี้มีอัตราได้รับสูงขึ้น",
		],
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
		"duration":     "ถาวร",
		"desc_lines": [
			"ทุก 10 ครั้งรับประกันได้ตัวละคร 4★ ขึ้นไป",
			"รวมตัวละครและไพ่ช่วยทุกประเภทในระบบ",
		],
	},
]

var _pity   := 0
var _pity_4 := 0
var _active_warp := 0

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
var _warp_btns:      Array[Button] = []

@onready var _result_ov:  Control       = $ResultOverlay
@onready var _result_con: HBoxContainer = $ResultOverlay/ResultContainer
@onready var _skip_btn:   Button        = $ResultOverlay/SkipBtn


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

# ── Layout constants ──────────────────────────────────────────────
const W       := 1152.0
const H       := 648.0
const TOP_H   := 52.0    # top bar height
const BOT_H   := 72.0    # bottom bar height
const THUMB_W := 68.0    # left thumbnail strip width
const INFO_W  := 310.0   # info card width
const TAB_H       := 80.0    # active warp tab height
const TAB_H_INACT := 22.0    # collapsed inactive tab height
const TAB_GAP     := 16.0

func _build_hsr_ui() -> void:
	# Dark gradient background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.05, 0.14, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	add_child(bg)
	_add_stars(bg)

	# ── Art placeholder area (center-right) ──
	var art_x := THUMB_W + INFO_W + 16.0
	var art_rect := ColorRect.new()
	art_rect.size     = Vector2(W - art_x, H - TOP_H - BOT_H)
	art_rect.position = Vector2(art_x, TOP_H)
	art_rect.color    = Color(0, 0, 0, 0)
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_rect.z_index  = 0
	add_child(art_rect)


	# ── Left thumbnail strip ──
	_build_thumb_strip()

	# ── Info card ──
	_build_info_card()

	# ── Top bar ──
	_build_top_bar()

	# ── Bottom bar ──
	_build_bottom_bar()

	if _result_ov:
		_result_ov.z_index = 50
		move_child(_result_ov, get_child_count() - 1)

# ── Thumbnail strip (far-left, warp type selector) ──────────────
func _build_thumb_strip() -> void:
	var strip_sb := _sb(Color(0.03, 0.04, 0.12, 0.90), Color(1,1,1, 0.05), 0, 1)
	var strip := Panel.new()
	strip.name     = "_ThumbStrip"
	strip.size     = Vector2(THUMB_W, H - TOP_H - BOT_H)
	strip.position = Vector2(0, TOP_H)
	strip.add_theme_stylebox_override("panel", strip_sb)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.z_index  = 5
	add_child(strip)

	var total_h := TAB_H + (WARP_TYPES.size() - 1) * (TAB_H_INACT + TAB_GAP) + (WARP_TYPES.size() - 1) * TAB_GAP
	var start_y := maxf((H - TOP_H - BOT_H - total_h) * 0.5, 12.0)
	var cy := start_y
	for i in WARP_TYPES.size():
		var wd: Dictionary = WARP_TYPES[i]
		var active := i == _active_warp
		var btn := _make_thumb_btn(wd, active)
		var bh := TAB_H if active else TAB_H_INACT
		btn.size     = Vector2(THUMB_W - 8, bh)
		btn.position = Vector2(4, cy)
		btn.pressed.connect(_on_warp_tab.bind(i))
		strip.add_child(btn)
		_warp_btns.append(btn)
		cy += bh + TAB_GAP

# ── Info card (left panel, HSR-style white/translucent card) ─────
func _build_info_card() -> void:
	var d: Dictionary = WARP_TYPES[_active_warp]
	var acc: Color = d["accent"] as Color

	var ix := THUMB_W + 12.0
	var iy := TOP_H + 16.0
	var iw := INFO_W
	var ih := H - TOP_H - BOT_H - 32.0

	var card_sb := _sb(Color(0.96, 0.97, 1.0, 0.11), Color(1.0, 1.0, 1.0, 0.16), 14, 1)
	card_sb.shadow_color = Color(0, 0, 0, 0.40)
	card_sb.shadow_size  = 12

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

	# Tag chip "Character Event Warp"
	var tag_sb := _sb(Color(acc.r * 0.15, acc.g * 0.2, acc.b * 0.45, 0.9),
		Color(acc.r, acc.g, acc.b, 0.6), 4, 1)
	var tag := Panel.new()
	tag.size     = Vector2(iw - pad * 2, 24)
	tag.position = Vector2(pad, cy)
	tag.add_theme_stylebox_override("panel", tag_sb)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tag)
	var tag_lbl := Label.new()
	tag_lbl.text = str(d["label"]).replace("\n", " ")
	tag_lbl.add_theme_font_size_override("font_size", 11)
	tag_lbl.add_theme_color_override("font_color", Color(acc.r + 0.2, acc.g + 0.1, acc.b, 1.0))
	tag_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(tag_lbl)
	cy += 32

	# Banner title
	var title := Label.new()
	title.text = str(d["banner_title"])
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.97))
	title.size     = Vector2(iw - pad * 2, 30)
	title.position = Vector2(pad, cy)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)
	cy += 36

	# Timer row
	var timer_row := HBoxContainer.new()
	timer_row.position = Vector2(pad, cy)
	timer_row.add_theme_constant_override("separation", 4)
	timer_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(timer_row)
	var timer_ico := Label.new()
	timer_ico.text = "⏱"
	timer_ico.add_theme_font_size_override("font_size", 13)
	timer_ico.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 0.9))
	timer_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_row.add_child(timer_ico)
	var timer_lbl := Label.new()
	timer_lbl.text = str(d.get("duration", "ถาวร"))
	timer_lbl.add_theme_font_size_override("font_size", 13)
	timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))
	timer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_row.add_child(timer_lbl)
	cy += 28

	# Description lines
	for desc_line in d.get("desc_lines", []) as Array:
		var dl := Label.new()
		dl.text = str(desc_line)
		dl.add_theme_font_size_override("font_size", 11)
		dl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 0.75))
		dl.size     = Vector2(iw - pad * 2, 32)
		dl.position = Vector2(pad, cy)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(dl)
		cy += 36

	# Separator
	var sep := ColorRect.new()
	sep.size     = Vector2(iw - pad * 2, 1)
	sep.position = Vector2(pad, cy)
	sep.color    = Color(1, 1, 1, 0.10)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep)
	cy += 10

	# Featured header
	var feat_hdr := Label.new()
	feat_hdr.text = "ตัวละครเด่น"
	feat_hdr.add_theme_font_size_override("font_size", 11)
	feat_hdr.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0, 0.6))
	feat_hdr.size     = Vector2(iw - pad * 2, 18)
	feat_hdr.position = Vector2(pad, cy)
	feat_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(feat_hdr)
	cy += 22

	# Featured character portrait slots (3 slots)
	var feat_w  := 72.0
	var feat_h  := 90.0
	var feat_gap := 8.0
	for fi in 3:
		var feat_sb2 := _sb(Color(0.08, 0.10, 0.20, 0.80), Color(1,1,1, 0.12), 8, 1)
		var feat_slot := Panel.new()
		feat_slot.size     = Vector2(feat_w, feat_h)
		feat_slot.position = Vector2(pad + fi * (feat_w + feat_gap), cy)
		feat_slot.add_theme_stylebox_override("panel", feat_sb2)
		feat_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(feat_slot)
		# placeholder icon
		var fi_lbl := Label.new()
		fi_lbl.text = str(d["art_icon"])
		fi_lbl.add_theme_font_size_override("font_size", 28)
		fi_lbl.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 0.25))
		fi_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fi_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fi_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		fi_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		feat_slot.add_child(fi_lbl)
	cy += feat_h + 8

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
	cy += 22

	# Bottom action buttons (Exchange / View Details)
	var btn_y := ih - 52.0
	var ex_btn := _ghost_btn("แลกเปลี่ยน", 12)
	ex_btn.size     = Vector2((iw - pad * 2 - 8) * 0.5, 38)
	ex_btn.position = Vector2(pad, btn_y)
	card.add_child(ex_btn)

	var det_btn := _ghost_btn("ดูรายละเอียด", 12)
	det_btn.size     = Vector2((iw - pad * 2 - 8) * 0.5, 38)
	det_btn.position = Vector2(pad + (iw - pad * 2 - 8) * 0.5 + 8, btn_y)
	card.add_child(det_btn)

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

	# Back button — top-left
	var back_btn := _make_visible_back_btn(Vector2(8, (TOP_H - 45) * 0.5), Vector2(42, 45), _go_back)
	bar.add_child(back_btn)


	# Currency row (top-right): free crystal pill + paid crystal pill + close
	var curr_row := HBoxContainer.new()
	curr_row.add_theme_constant_override("separation", 6)
	curr_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(curr_row)

	var gem_tex  := _load_png("res://image/crystal_gem.png")
	var paid_tex := _load_png("res://image/icon_paid.png")

	# Free crystal pill
	_new_gem_lbl = _make_curr_pill(curr_row, gem_tex,  Color(0.35, 0.85, 1.0, 1.0))

	# Paid crystal pill
	_paid_gem_lbl = _make_curr_pill(curr_row, paid_tex, Color(0.78, 0.55, 1.0, 1.0))


	# Position currency row at far right
	curr_row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	curr_row.offset_right = -8
	curr_row.offset_left  = -340

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

	# Two warp buttons on the right side (left btn wider, stretches toward right)
	var btn_h  := 50.0
	var btn_y  := (BOT_H - btn_h) * 0.5
	var btn_w2 := 220.0   # Warp ×10
	var btn_w1 := 256.0   # Warp ×1 — wider, extends toward right
	var bx2    := W - btn_w2 - 16.0
	var bx1    := bx2 - btn_w1 - 10.0

	# Warp ×1 — gem icon + count + label
	_new_pull1 = _warp_btn(1)
	_new_pull1.size     = Vector2(btn_w1, btn_h)
	_new_pull1.position = Vector2(bx1, btn_y)
	_new_pull1.pressed.connect(func(): _do_pull(1))
	bar.add_child(_new_pull1)

	# Warp ×10
	_new_pull10 = _warp_btn(10)
	_new_pull10.size     = Vector2(btn_w2, btn_h)
	_new_pull10.position = Vector2(bx2, btn_y)
	_new_pull10.pressed.connect(func(): _do_pull(10))
	bar.add_child(_new_pull10)

func _warp_btn(count: int) -> Button:
	var cost := PULL_COST_1 * count
	var cost_str := "%d" % cost if count == 1 else "1,500"
	var btn := Button.new()
	# Build layout inside button manually via sub-labels
	var sb_n := _sb(Color(0.14, 0.22, 0.55, 1.0), Color(0.35, 0.55, 1.0, 0.5), 10, 1)
	var sb_h := _sb(Color(0.20, 0.30, 0.68, 1.0), Color(0.45, 0.65, 1.0, 0.7), 10, 1)
	btn.add_theme_stylebox_override("normal",  sb_n)
	btn.add_theme_stylebox_override("hover",   sb_h)
	btn.add_theme_stylebox_override("pressed", sb_n)
	btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	# Gem icon + cost (top area)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 4)
	top_row.position = Vector2(12, 6)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(top_row)

	var gem_tex := _load_png("res://image/icon_paid.png")
	if gem_tex:
		var ico := TextureRect.new()
		ico.texture = gem_tex
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ico.custom_minimum_size = Vector2(18, 18)
		ico.size = Vector2(18, 18)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_row.add_child(ico)
	var cost_lbl := Label.new()
	cost_lbl.text = "×%s" % cost_str
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0, 1.0))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(cost_lbl)

	# Warp label (bottom)
	var warp_lbl := Label.new()
	warp_lbl.text = "สุ่ม  ×%d" % count
	warp_lbl.add_theme_font_size_override("font_size", 15)
	warp_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	warp_lbl.position = Vector2(12, 26)
	warp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(warp_lbl)
	return btn

# ── Warp tab ──────────────────────────────────────────────────────
func _on_warp_tab(idx: int) -> void:
	if idx == _active_warp: return
	_active_warp = idx
	if is_instance_valid(_info_card_node):
		_info_card_node.free()
		_info_card_node = null
	_new_pity_lbl = null
	_new_pity_bar = null
	_new_pity4_lbl = null
	_new_pity4_bar = null
	_build_info_card()
	# Restyle and reposition all tab buttons
	var strip := get_node_or_null("_ThumbStrip")
	var total_h := TAB_H + (_warp_btns.size() - 1) * (TAB_H_INACT + TAB_GAP) + (_warp_btns.size() - 1) * TAB_GAP
	var cy := maxf((H - TOP_H - BOT_H - total_h) * 0.5, 12.0)
	for i in _warp_btns.size():
		var active := i == _active_warp
		var bh := TAB_H if active else TAB_H_INACT
		_warp_btns[i].size.y = bh
		_warp_btns[i].position.y = cy
		_restyle_thumb_btn(_warp_btns[i], WARP_TYPES[i], active)
		cy += bh + TAB_GAP
	_refresh_ui()

func _make_thumb_btn(d: Dictionary, active: bool) -> Button:
	var btn := Button.new()
	_restyle_thumb_btn(btn, d, active)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	return btn

func _restyle_thumb_btn(btn: Button, d: Dictionary, active: bool) -> void:
	var acc: Color = d["accent"] as Color
	var bh := TAB_H if active else TAB_H_INACT
	btn.size.y = bh

	var bg_col  := Color(acc.r * 0.22, acc.g * 0.22, acc.b * 0.35, 0.95) if active else Color(acc.r*0.06, acc.g*0.06, acc.b*0.12, 0.70)
	var bdr_col := Color(acc.r, acc.g, acc.b, 0.8) if active else Color(acc.r, acc.g, acc.b, 0.25)
	var bdr_w   := 2 if active else 1

	var sb  := _sb(bg_col, bdr_col, 6, bdr_w)
	var sbf := StyleBoxFlat.new()
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   _sb(Color(acc.r*0.15, acc.g*0.15, acc.b*0.28, 0.92), bdr_col, 6, 1))
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus",   sbf)

	for c in btn.get_children(): c.queue_free()

	if active:
		# Thumbnail art area
		var thumb := ColorRect.new()
		thumb.size     = Vector2(THUMB_W - 16, TAB_H * 0.55)
		thumb.position = Vector2(4, 4)
		thumb.color    = Color(acc.r * 0.08, acc.g * 0.08, acc.b * 0.15, 0.9)
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(thumb)

		var icon_lbl := Label.new()
		icon_lbl.text = str(d["icon"])
		icon_lbl.add_theme_font_size_override("font_size", 16)
		icon_lbl.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 0.85))
		icon_lbl.size     = thumb.size
		icon_lbl.position = thumb.position
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_lbl)

		var tab_lbl := Label.new()
		tab_lbl.text = str(d["label"])
		tab_lbl.add_theme_font_size_override("font_size", 7)
		tab_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
		tab_lbl.size     = Vector2(THUMB_W - 8, TAB_H - thumb.size.y - 8)
		tab_lbl.position = Vector2(2, 4 + thumb.size.y + 2)
		tab_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tab_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tab_lbl)

		# Active accent bar on left
		var bar2 := ColorRect.new()
		bar2.size     = Vector2(3, TAB_H - 8)
		bar2.position = Vector2(0, 4)
		bar2.color    = Color(acc.r, acc.g, acc.b, 1.0)
		bar2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(bar2)
	else:
		# Collapsed: just icon + tiny label centered vertically
		var icon_lbl := Label.new()
		icon_lbl.text = str(d["icon"])
		icon_lbl.add_theme_font_size_override("font_size", 11)
		icon_lbl.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 0.45))
		icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_lbl)

# ── Helpers ───────────────────────────────────────────────────────
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
	for i in names.size():
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

func _make_back_btn(pos: Vector2, sz: Vector2, callback: Callable) -> Control:
	var btn := Panel.new()
	btn.position = pos
	btn.z_index = 20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
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

func _go_back() -> void:
	if _revealing: return
	SceneTransition.fade_to(SC_MAIN)
