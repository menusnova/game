extends Control

const SC_MAIN := "res://main_menu.tscn"

# ── Layout ────────────────────────────────────────────────────────
const W      := 1152.0
const H      := 648.0
const SIDE_W := 190.0   # left sidebar
const TOP_H  := 52.0    # topbar height

# ── Palette ───────────────────────────────────────────────────────
const C_BG    := Color(0.085, 0.090, 0.120, 1.0)
const C_SIDE  := Color(0.055, 0.058, 0.082, 1.0)
const C_TOP   := Color(0.072, 0.076, 0.105, 1.0)
const C_LINE  := Color(1.0, 1.0, 1.0, 0.07)
const C_ACT   := Color(0.42, 0.72, 1.00, 1.0)
const C_TXT   := Color(0.92, 0.94, 1.00, 1.0)
const C_DIM   := Color(0.55, 0.60, 0.74, 0.80)
const C_CARD  := Color(0.22, 0.16, 0.38, 1.0)
const C_BONUS := Color(0.50, 0.38, 0.85, 1.0)

# ── Categories (left sidebar) ─────────────────────────────────────
const CATS := [
	{"id": "recommend",    "label": "แนะนำ"},
	{"id": "crystal_pack", "label": "คริสตัลเติม"},
	{"id": "starlight",    "label": "แลกสตาร์ไลท์"},
	{"id": "embers",       "label": "แลกแอมเบอร์"},
	{"id": "contract",     "label": "ร้านสัญญา"},
	{"id": "stellar",      "label": "ค้าดาวฤกษ์"},
]

# ── Crystal packages (Oneiric Pouch equivalent) ───────────────────
const CRYSTAL_PACKS := [
	{"n": 60,   "bonus": 60,   "price": "฿49",    "first_double": true},
	{"n": 300,  "bonus": 300,  "price": "฿169",   "first_double": true},
	{"n": 980,  "bonus": 980,  "price": "฿549",   "first_double": true},
	{"n": 1980, "bonus": 1980, "price": "฿1,099", "first_double": true},
	{"n": 3280, "bonus": 3280, "price": "฿1,849", "first_double": true},
	{"n": 6480, "bonus": 6480, "price": "฿3,699", "first_double": true},
]

const OTHER_ITEMS := [
	{"name": "Express Supply Pass", "price": "฿59",  "sub": "รับรางวัลพิเศษ 30 วัน"},
	{"name": "Trailblaze Pass",     "price": "฿219", "sub": "Battle Pass เดือนนี้"},
]

# ── State ─────────────────────────────────────────────────────────
var _active_cat   := "crystal_pack"
var _cat_btns:    Array[Button] = []

@onready var _back_btn:     Panel          = $BackBtn
@onready var _content_root: Control        = $ContentScroll/ContentRoot
@onready var _gold_lbl:     Label          = $WalletRow/GoldPill/GoldVal
@onready var _free_lbl:     Label          = $WalletRow/FreePill/FreeVal
@onready var _paid_lbl:     Label          = $WalletRow/PaidPill/PaidVal
@onready var _fade:         ColorRect      = $FadeOverlay

# ══════════════════════════════════════════════════════════════════
func _ready() -> void:
	# Fade in
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.25)

	# Back button
	_back_btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw := _back_btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(_back_btn, "scale", Vector2(0.78, 0.78), 0.08)
			tw.tween_property(_back_btn, "scale", Vector2(1.0, 1.0), 0.22)
			tw.tween_callback(_go_back)
	)
	_back_btn.mouse_entered.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	_back_btn.mouse_exited.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)

	_build_sidebar_cats()
	_switch_cat("crystal_pack")

	if not CurrencyManager.currency_changed.is_connected(_rebuild_wallet):
		CurrencyManager.currency_changed.connect(_rebuild_wallet)
	_rebuild_wallet()

# ── Left sidebar category buttons (dynamic) ───────────────────────
func _build_sidebar_cats() -> void:
	var cat_y := 52.0
	for cat in CATS:
		var btn := _make_cat_btn(str(cat["label"]), str(cat["id"]))
		btn.position = Vector2(0, cat_y)
		add_child(btn)
		_cat_btns.append(btn)
		cat_y += 56.0

func _make_cat_btn(label: String, cat_id: String) -> Button:
	var btn := Button.new()
	btn.size = Vector2(SIDE_W, 52)
	btn.clip_contents = false
	btn.pressed.connect(_switch_cat.bind(cat_id))

	# blank style
	for st in ["normal","hover","pressed","focus"]:
		btn.add_theme_stylebox_override(st, _flat(Color(0,0,0,0), Color(0,0,0,0)))

	# icon slot (empty TextureRect — user fills in)
	var ico_slot := TextureRect.new()
	ico_slot.size     = Vector2(32, 32)
	ico_slot.position = Vector2(14, 10)
	ico_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico_slot.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	ico_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(ico_slot)

	# icon placeholder circle
	var ico_ph := StyleBoxFlat.new()
	ico_ph.bg_color = Color(1, 1, 1, 0.06)
	ico_ph.corner_radius_top_left     = 16
	ico_ph.corner_radius_top_right    = 16
	ico_ph.corner_radius_bottom_right = 16
	ico_ph.corner_radius_bottom_left  = 16
	var ico_panel := Panel.new()
	ico_panel.size     = Vector2(32, 32)
	ico_panel.position = Vector2(14, 10)
	ico_panel.add_theme_stylebox_override("panel", ico_ph)
	ico_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(ico_panel)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C_DIM)
	lbl.size     = Vector2(SIDE_W - 58, 52)
	lbl.position = Vector2(54, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	# active left bar (hidden by default)
	var act_bar := ColorRect.new()
	act_bar.name = "ActiveBar"
	act_bar.size     = Vector2(3, 36)
	act_bar.position = Vector2(0, 8)
	act_bar.color    = C_ACT
	act_bar.visible  = false
	act_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(act_bar)

	return btn

func _restyle_cats() -> void:
	for i in _cat_btns.size():
		var btn := _cat_btns[i]
		var cat_id: String = str(CATS[i]["id"])
		var active: bool = cat_id == _active_cat
		var lbl := btn.get_child(2) as Label
		var bar := btn.get_node("ActiveBar") as ColorRect
		if lbl:
			lbl.add_theme_color_override("font_color", C_TXT if active else C_DIM)
		if bar:
			bar.visible = active
		if active:
			btn.add_theme_stylebox_override("normal",  _flat(Color(C_ACT.r,C_ACT.g,C_ACT.b,0.10), Color(0,0,0,0)))
			btn.add_theme_stylebox_override("hover",   _flat(Color(C_ACT.r,C_ACT.g,C_ACT.b,0.14), Color(0,0,0,0)))
		else:
			btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
			btn.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.04), Color(0,0,0,0)))


func _switch_cat(cat_id: String) -> void:
	_active_cat = cat_id
	_restyle_cats()
	for c in _content_root.get_children(): c.queue_free()
	match cat_id:
		"crystal_pack": _build_crystal_pack_page()
		_:              _build_coming_soon_page()

# ── Crystal Pack page (Oneiric Pouch style) ───────────────────────
func _build_crystal_pack_page() -> void:
	var cw := W - SIDE_W

	# "Double bonus on first top-up" banner
	var notice_bg := ColorRect.new()
	notice_bg.size     = Vector2(cw, 36)
	notice_bg.position = Vector2(0, 0)
	notice_bg.color    = Color(0.28, 0.18, 0.50, 0.55)
	notice_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(notice_bg)

	var notice_lbl := Label.new()
	notice_lbl.text = "รับโบนัสสองเท่าสำหรับการเติมเงินครั้งแรก  (ครั้งเดียวเท่านั้น)"
	notice_lbl.add_theme_font_size_override("font_size", 12)
	notice_lbl.add_theme_color_override("font_color", Color(0.90, 0.78, 1.0, 0.95))
	notice_lbl.size     = Vector2(cw, 36)
	notice_lbl.position = Vector2(0, 0)
	notice_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	notice_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(notice_lbl)

	# 6 crystal pack cards
	const PACK_W  := 148.0
	const PACK_H  := 186.0
	const PACK_PAD := 16.0
	const ROW_Y   := 56.0
	var total_w   := PACK_W * 6 + PACK_PAD * 5
	var start_x   := (cw - total_w) * 0.5

	for i in CRYSTAL_PACKS.size():
		var pack: Dictionary = CRYSTAL_PACKS[i]
		var px := start_x + i * (PACK_W + PACK_PAD)
		_content_root.add_child(_make_pack_card(pack, px, ROW_Y, PACK_W, PACK_H))

	# Other items row (Express Supply Pass etc.)
	const ITEM_W := 148.0
	const ITEM_H := 148.0
	const ITEM_Y := 260.0
	var item_start_x := start_x

	for i in OTHER_ITEMS.size():
		var item: Dictionary = OTHER_ITEMS[i]
		var ix := item_start_x + i * (ITEM_W + PACK_PAD)
		_content_root.add_child(_make_other_card(item, ix, ITEM_Y, ITEM_W, ITEM_H))

func _make_pack_card(pack: Dictionary, px: float, py: float, pw: float, ph: float) -> Panel:
	var card := Panel.new()
	card.position = Vector2(px, py)
	card.size     = Vector2(pw, ph)

	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color(0.19, 0.13, 0.34, 0.97)
	card_sb.border_color = Color(0.55, 0.40, 0.85, 0.55)
	card_sb.set_border_width(SIDE_LEFT,   1)
	card_sb.set_border_width(SIDE_RIGHT,  1)
	card_sb.set_border_width(SIDE_TOP,    1)
	card_sb.set_border_width(SIDE_BOTTOM, 1)
	card_sb.corner_radius_top_left     = 8
	card_sb.corner_radius_top_right    = 8
	card_sb.corner_radius_bottom_right = 8
	card_sb.corner_radius_bottom_left  = 8
	card.add_theme_stylebox_override("panel", card_sb)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	# "Bonus +N" badge at top-center
	var bonus_n: int = int(pack["bonus"])
	var badge_bg := StyleBoxFlat.new()
	badge_bg.bg_color = Color(0.45, 0.30, 0.78, 1.0)
	badge_bg.corner_radius_top_left     = 4
	badge_bg.corner_radius_top_right    = 4
	badge_bg.corner_radius_bottom_right = 4
	badge_bg.corner_radius_bottom_left  = 4
	var badge := Panel.new()
	badge.size     = Vector2(pw - 24, 20)
	badge.position = Vector2(12, 8)
	badge.add_theme_stylebox_override("panel", badge_bg)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(badge)

	var badge_lbl := Label.new()
	badge_lbl.text = "Bonus +%d" % bonus_n
	badge_lbl.add_theme_font_size_override("font_size", 10)
	badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
	badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_lbl)

	# Crystal icon image area (empty — user fills in)
	var img_slot := TextureRect.new()
	img_slot.size     = Vector2(pw - 24, 80)
	img_slot.position = Vector2(12, 34)
	img_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_slot.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(img_slot)

	# placeholder background for image area
	var img_ph_sb := StyleBoxFlat.new()
	img_ph_sb.bg_color = Color(0.30, 0.22, 0.50, 0.35)
	img_ph_sb.corner_radius_top_left     = 4
	img_ph_sb.corner_radius_top_right    = 4
	img_ph_sb.corner_radius_bottom_right = 4
	img_ph_sb.corner_radius_bottom_left  = 4
	var img_ph := Panel.new()
	img_ph.size     = Vector2(pw - 24, 80)
	img_ph.position = Vector2(12, 34)
	img_ph.add_theme_stylebox_override("panel", img_ph_sb)
	img_ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(img_ph)

	# "Crystal ×N" label
	var n: int = int(pack["n"])
	var name_lbl := Label.new()
	name_lbl.text = "Crystal ×%d" % n
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.88, 0.82, 1.0, 0.95))
	name_lbl.size     = Vector2(pw, 20)
	name_lbl.position = Vector2(0, 120)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# separator line
	var sep := ColorRect.new()
	sep.size     = Vector2(pw - 24, 1)
	sep.position = Vector2(12, 144)
	sep.color    = Color(1, 1, 1, 0.10)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep)

	# Price
	var price_lbl := Label.new()
	price_lbl.text = str(pack["price"])
	price_lbl.add_theme_font_size_override("font_size", 13)
	price_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0, 1.0))
	price_lbl.size     = Vector2(pw, 30)
	price_lbl.position = Vector2(0, 150)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(price_lbl)

	# hover effect
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_fx_scale(card)
	)

	return card

func _make_other_card(item: Dictionary, px: float, py: float, pw: float, ph: float) -> Panel:
	var card := Panel.new()
	card.position = Vector2(px, py)
	card.size     = Vector2(pw, ph)

	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color(0.12, 0.10, 0.20, 0.97)
	card_sb.border_color = Color(0.40, 0.32, 0.65, 0.45)
	card_sb.set_border_width(SIDE_LEFT,   1)
	card_sb.set_border_width(SIDE_RIGHT,  1)
	card_sb.set_border_width(SIDE_TOP,    1)
	card_sb.set_border_width(SIDE_BOTTOM, 1)
	card_sb.corner_radius_top_left     = 8
	card_sb.corner_radius_top_right    = 8
	card_sb.corner_radius_bottom_right = 8
	card_sb.corner_radius_bottom_left  = 8
	card.add_theme_stylebox_override("panel", card_sb)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	# image placeholder
	var img_ph_sb := StyleBoxFlat.new()
	img_ph_sb.bg_color = Color(0.22, 0.18, 0.36, 0.45)
	img_ph_sb.corner_radius_top_left     = 6
	img_ph_sb.corner_radius_top_right    = 6
	img_ph_sb.corner_radius_bottom_right = 6
	img_ph_sb.corner_radius_bottom_left  = 6
	var img_ph := Panel.new()
	img_ph.size     = Vector2(pw - 20, 70)
	img_ph.position = Vector2(10, 10)
	img_ph.add_theme_stylebox_override("panel", img_ph_sb)
	img_ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(img_ph)

	# Image TextureRect (empty)
	var img_slot := TextureRect.new()
	img_slot.size     = Vector2(pw - 20, 70)
	img_slot.position = Vector2(10, 10)
	img_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_slot.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(img_slot)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = str(item["name"])
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", C_TXT)
	name_lbl.size     = Vector2(pw - 16, 32)
	name_lbl.position = Vector2(8, 84)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# Price
	var price_lbl := Label.new()
	price_lbl.text = str(item["price"])
	price_lbl.add_theme_font_size_override("font_size", 12)
	price_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0, 1.0))
	price_lbl.size     = Vector2(pw, 24)
	price_lbl.position = Vector2(0, 118)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(price_lbl)

	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_fx_scale(card)
	)
	return card

# ── Coming soon page ──────────────────────────────────────────────
func _build_coming_soon_page() -> void:
	var lbl := Label.new()
	lbl.text = "กำลังจะมาเร็วๆนี้"
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", C_DIM)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(lbl)

# ── Wallet (top-right) ────────────────────────────────────────────
func _rebuild_wallet() -> void:
	if _gold_lbl: _gold_lbl.text = _fmt(CurrencyManager.gold)
	if _free_lbl: _free_lbl.text = _fmt(CurrencyManager.free_crystal)
	if _paid_lbl: _paid_lbl.text = _fmt(CurrencyManager.paid_crystal)

func _load_png(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.1fK" % (n / 1000.0)
	return str(n)

func _flat(bg: Color, border: Color, radius: int = 0, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = border
	sb.set_border_width(SIDE_LEFT,   bw)
	sb.set_border_width(SIDE_TOP,    bw)
	sb.set_border_width(SIDE_RIGHT,  bw)
	sb.set_border_width(SIDE_BOTTOM, bw)
	sb.corner_radius_top_left     = radius
	sb.corner_radius_top_right    = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left  = radius
	return sb

func _fx_scale(node: Control) -> void:
	var t := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(node, "scale", Vector2(0.93, 0.93), 0.07)
	t.tween_property(node, "scale", Vector2(1.0,  1.0),  0.15)

func _go_back() -> void:
	SceneTransition.fade_to(SC_MAIN)
