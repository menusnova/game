extends Control

const SC_MAIN := "res://main_menu.tscn"

# ── Layout ────────────────────────────────────────────────────────
const W      := 1152.0
const H      := 648.0
const SIDE_W := 200.0
const TOP_H  := 52.0

# ── Palette ───────────────────────────────────────────────────────
const C_BG   := Color(0.085, 0.090, 0.120, 1.0)
const C_SIDE := Color(0.055, 0.058, 0.082, 1.0)
const C_TXT  := Color(0.92, 0.94, 1.00, 1.0)
const C_DIM  := Color(0.55, 0.60, 0.74, 0.80)
const C_LINE := Color(1.0, 1.0, 1.0, 0.07)

# ── Shop definitions ──────────────────────────────────────────────
const SHOPS := [
	{
		"id":       "void_market",
		"label":    "Void Market",
		"icon":     "🏪",
		"currency": "Aether Credit",
		"cur_sym":  "AC",
		"cur_col":  Color(1.00, 0.82, 0.28, 1.0),
		"cur_icon": "res://image/icon_gold.png",
		"desc":     "ใช้ Aether Credit แลกวัตถุดิบและของใช้ทั่วไป",
		"accent":   Color(0.42, 0.72, 1.00, 1.0),
	},
	{
		"id":       "synthesis",
		"label":    "Synthesis Exchange",
		"icon":     "⚡",
		"currency": "Void Crystal",
		"cur_sym":  "VC",
		"cur_col":  Color(0.55, 0.40, 1.00, 1.0),
		"cur_icon": "res://image/crystal_gem.png",
		"desc":     "ใช้ Void Crystal แลก Aether Shard และพลังงาน",
		"accent":   Color(0.70, 0.50, 1.00, 1.0),
	},
	{
		"id":       "premium",
		"label":    "Premium Store",
		"icon":     "💎",
		"currency": "Void Crystal X",
		"cur_sym":  "VCX",
		"cur_col":  Color(0.40, 0.85, 1.00, 1.0),
		"desc":     "ใช้ Void Crystal X (เติมเงินเท่านั้น)",
		"accent":   Color(0.35, 0.78, 1.00, 1.0),
	},
]

# ── Item data ─────────────────────────────────────────────────────
const VOID_MARKET_ITEMS := [
	{"name": "Iron Ore",    "sub": "วัตถุดิบ ×10", "cost": 100, "icon": "🪨",                                 "tag": "material"},
	{"name": "EXP Card M", "sub": "EXP +2000",      "cost": 200, "img": "res://image/icon_exp.png",            "tag": "exp"},
]

const SYNTHESIS_ITEMS := [
	{"name": "Aether Shard",     "sub": "สุ่ม Gacha ×1",    "cost": 160,  "img": "res://image/crystal_gem.png",  "tag": "gacha"},
	{"name": "Aether Shard ×10", "sub": "สุ่ม Gacha ×10",   "cost": 1600, "img": "res://image/crystal_gem.png",  "tag": "gacha",  "badge": "Best"},
	{"name": "Aether Pulse",     "sub": "พลังงาน Farm ×1",  "cost": 40,   "img": "res://image/icon_energy.png",  "tag": "energy"},
	{"name": "Aether Pulse ×60", "sub": "พลังงาน Farm ×60", "cost": 2400, "img": "res://image/icon_energy.png",  "tag": "energy", "badge": "Save"},
]

const PREMIUM_ITEMS := []

# ── State ─────────────────────────────────────────────────────────
var _active_shop := "void_market"
var _cat_btns: Array[Button] = []

@onready var _back_btn:     Panel     = $BackBtn
@onready var _content_root: Control   = $ContentScroll/ContentRoot
@onready var _gold_lbl:     Label     = $WalletRow/GoldPill/GoldVal
@onready var _free_lbl:     Label     = $WalletRow/FreePill/FreeVal
@onready var _paid_lbl:     Label     = $WalletRow/PaidPill/PaidVal
@onready var _fade:         ColorRect = $FadeOverlay

# ══════════════════════════════════════════════════════════════════
func _ready() -> void:
	create_tween().tween_property(_fade, "color:a", 0.0, 0.25)

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

	_build_sidebar()
	_switch_shop("void_market")

	if not CurrencyManager.currency_changed.is_connected(_rebuild_wallet):
		CurrencyManager.currency_changed.connect(_rebuild_wallet)
	_rebuild_wallet()

# ── Sidebar ───────────────────────────────────────────────────────
func _build_sidebar() -> void:
	var y := TOP_H
	for i in SHOPS.size():
		var shop: Dictionary = SHOPS[i]
		# ซ่อน premium tab ถ้าไม่มีของ
		if str(shop["id"]) == "premium" and PREMIUM_ITEMS.is_empty():
			continue
		var btn := _make_shop_btn(shop)
		btn.position = Vector2(0, y)
		add_child(btn)
		_cat_btns.append(btn)
		y += 140.0

func _make_shop_btn(shop: Dictionary) -> Button:
	var accent: Color = shop["accent"]
	var btn := Button.new()
	btn.size = Vector2(SIDE_W, 136)
	btn.clip_contents = false
	btn.focus_mode = Control.FOCUS_NONE
	for st in ["normal","hover","pressed","focus"]:
		btn.add_theme_stylebox_override(st, _flat(Color(0,0,0,0), Color(0,0,0,0)))
	btn.pressed.connect(_switch_shop.bind(str(shop["id"])))

	# Icon circle
	var icon_bg := Panel.new()
	icon_bg.size     = Vector2(56, 56)
	icon_bg.position = Vector2(16, 40)
	icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_bg.add_theme_stylebox_override("panel",
		_flat(Color(accent.r,accent.g,accent.b,0.12), Color(accent.r,accent.g,accent.b,0.3), 28, 1))
	btn.add_child(icon_bg)

	var icon_lbl := Label.new()
	icon_lbl.text = str(shop["icon"])
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 26)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_bg.add_child(icon_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = str(shop["label"])
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", C_DIM)
	name_lbl.size     = Vector2(SIDE_W - 84, 22)
	name_lbl.position = Vector2(80, 42)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	# Currency label
	var cur_lbl := Label.new()
	cur_lbl.text = str(shop["cur_sym"])
	cur_lbl.add_theme_font_size_override("font_size", 10)
	cur_lbl.add_theme_color_override("font_color", shop["cur_col"])
	cur_lbl.size     = Vector2(SIDE_W - 84, 16)
	cur_lbl.position = Vector2(80, 66)
	cur_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cur_lbl)

	# Divider
	var div := ColorRect.new()
	div.size = Vector2(SIDE_W - 24, 1)
	div.position = Vector2(12, 135)
	div.color = C_LINE
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(div)

	# Active bar
	var act_bar := ColorRect.new()
	act_bar.name = "ActiveBar"
	act_bar.size     = Vector2(3, 80)
	act_bar.position = Vector2(0, 26)
	act_bar.color    = accent
	act_bar.visible  = false
	act_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(act_bar)

	return btn

func _restyle_sidebar() -> void:
	for i in _cat_btns.size():
		var btn := _cat_btns[i]
		var shop: Dictionary = SHOPS[i]
		var active := str(shop["id"]) == _active_shop
		var accent: Color = shop["accent"]
		var name_lbl := btn.get_child(1) as Label
		var cur_lbl  := btn.get_child(2) as Label
		var act_bar  := btn.get_node("ActiveBar") as ColorRect

		if name_lbl: name_lbl.add_theme_color_override("font_color", C_TXT if active else C_DIM)
		if act_bar:  act_bar.visible = active
		if active:
			btn.add_theme_stylebox_override("normal", _flat(Color(accent.r,accent.g,accent.b,0.10), Color(0,0,0,0)))
			btn.add_theme_stylebox_override("hover",  _flat(Color(accent.r,accent.g,accent.b,0.15), Color(0,0,0,0)))
		else:
			btn.add_theme_stylebox_override("normal", _flat(Color(0,0,0,0), Color(0,0,0,0)))
			btn.add_theme_stylebox_override("hover",  _flat(Color(1,1,1,0.04), Color(0,0,0,0)))

# ── Switch shop ───────────────────────────────────────────────────
func _switch_shop(shop_id: String) -> void:
	_active_shop = shop_id
	_restyle_sidebar()
	for c in _content_root.get_children(): c.queue_free()
	match shop_id:
		"void_market": _build_shop_page(VOID_MARKET_ITEMS, SHOPS[0])
		"synthesis":   _build_shop_page(SYNTHESIS_ITEMS,   SHOPS[1])
		"premium":     _build_premium_page()

# ── Generic item grid page ────────────────────────────────────────
func _build_shop_page(items: Array, shop: Dictionary) -> void:
	var cw := W - SIDE_W
	var accent: Color = shop["accent"]
	var cur_col: Color = shop["cur_col"]

	# Header banner
	var banner := ColorRect.new()
	banner.size  = Vector2(cw, 56)
	banner.color = Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.22, 1.0)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(banner)

	var banner_title := Label.new()
	banner_title.text = "%s  %s" % [str(shop["icon"]), str(shop["label"])]
	banner_title.position = Vector2(20, 8)
	banner_title.add_theme_font_size_override("font_size", 18)
	banner_title.add_theme_color_override("font_color", Color(accent.r + 0.2, accent.g + 0.1, accent.b + 0.1, 1.0))
	banner_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(banner_title)

	var banner_sub := Label.new()
	banner_sub.text = str(shop["desc"])
	banner_sub.position = Vector2(20, 32)
	banner_sub.add_theme_font_size_override("font_size", 10)
	banner_sub.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.65))
	banner_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(banner_sub)

	# Item grid: 4 columns, portrait cards
	const COLS    := 4
	const CARD_W  := 212.0
	const CARD_H  := 230.0
	const PAD_X   := 10.0
	const PAD_Y   := 10.0
	const START_X := 16.0
	const START_Y := 68.0

	for i in items.size():
		var item: Dictionary = items[i]
		var col := i % COLS
		var row := i / COLS
		var px := START_X + col * (CARD_W + PAD_X)
		var py := START_Y + row * (CARD_H + PAD_Y)
		_content_root.add_child(_make_item_card(item, px, py, CARD_W, CARD_H, shop))

func _make_item_card(item: Dictionary, px: float, py: float, pw: float, ph: float, shop: Dictionary) -> Panel:
	var accent: Color  = shop["accent"]
	var cur_col: Color = shop["cur_col"]
	var is_premium     := str(shop["id"]) == "premium"

	var card := Panel.new()
	card.position = Vector2(px, py)
	card.size     = Vector2(pw, ph)
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel",
		_flat(Color(0.08, 0.08, 0.15, 1.0), Color(accent.r, accent.g, accent.b, 0.30), 8, 1))

	# ── Image area (top ~60% of card) ───────────────────────────────
	const IMG_H := 140.0
	var img_bg := ColorRect.new()
	img_bg.size     = Vector2(pw, IMG_H)
	img_bg.position = Vector2(0, 0)
	img_bg.color    = Color(accent.r*0.10, accent.g*0.10, accent.b*0.16, 1.0)
	img_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(img_bg)

	if item.has("img"):
		var img_tex := TextureRect.new()
		img_tex.texture      = load(str(item["img"]))
		img_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		img_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img_tex.size         = Vector2(pw, IMG_H)
		img_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(img_tex)
	else:
		var icon_lbl := Label.new()
		icon_lbl.text = str(item.get("icon", "📦"))
		icon_lbl.size = Vector2(pw, IMG_H)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 52)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(icon_lbl)

	# Badge top-right
	if item.has("badge"):
		var badge_col := Color(1.0, 0.60, 0.20, 1.0)
		if item["badge"] == "Best":      badge_col = Color(0.30, 0.90, 0.55, 1.0)
		if item["badge"] == "Save":      badge_col = Color(0.40, 0.85, 1.00, 1.0)
		if item["badge"] == "Limited":   badge_col = Color(0.95, 0.35, 0.45, 1.0)
		if item["badge"] == "Popular":   badge_col = Color(0.50, 0.80, 1.00, 1.0)
		if item["badge"] == "Exclusive": badge_col = Color(0.85, 0.55, 1.00, 1.0)
		var badge := Panel.new()
		badge.size     = Vector2(48, 18)
		badge.position = Vector2(pw - 52, 4)
		badge.add_theme_stylebox_override("panel",
			_flat(Color(badge_col.r*0.22, badge_col.g*0.22, badge_col.b*0.28, 0.95),
				  Color(badge_col.r, badge_col.g, badge_col.b, 0.80), 4, 1))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
		var bl := Label.new()
		bl.text = str(item["badge"])
		bl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		bl.add_theme_font_size_override("font_size", 9)
		bl.add_theme_color_override("font_color", badge_col)
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(bl)

	# ── Name ────────────────────────────────────────────────────────
	var name_lbl := Label.new()
	name_lbl.text = str(item["name"])
	name_lbl.position = Vector2(8, IMG_H + 6)
	name_lbl.size     = Vector2(pw - 16, 22)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", C_TXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# ── Price row: currency icon + number ───────────────────────────
	var cost_text: String
	if is_premium:
		cost_text = str(item.get("price", "฿?"))
	else:
		cost_text = str(int(item.get("cost", 0)))

	var price_y := IMG_H + 32.0
	var cur_icon_path := str(shop.get("cur_icon", ""))

	# Currency icon (16×16)
	if cur_icon_path != "":
		var ci := TextureRect.new()
		ci.texture      = load(cur_icon_path)
		ci.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ci.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ci.size         = Vector2(16, 16)
		ci.position     = Vector2(8, price_y + 1)
		ci.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(ci)

	var price_lbl := Label.new()
	price_lbl.text = cost_text
	price_lbl.position = Vector2(28, price_y)
	price_lbl.size     = Vector2(pw - 36, 18)
	price_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	price_lbl.add_theme_font_size_override("font_size", 13)
	price_lbl.add_theme_color_override("font_color", cur_col)
	price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(price_lbl)

	# Hover / click
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_fx_scale(card)
	)
	return card

# ── Premium page (special layout) ────────────────────────────────
func _build_premium_page() -> void:
	var shop: Dictionary = SHOPS[2]
	var accent: Color = shop["accent"]
	var cw := W - SIDE_W

	# Header banner with premium gradient feel
	var banner := ColorRect.new()
	banner.size  = Vector2(cw, 56)
	banner.color = Color(0.05, 0.12, 0.22, 1.0)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(banner)

	var banner_title := Label.new()
	banner_title.text = "💎  Premium Store"
	banner_title.position = Vector2(20, 8)
	banner_title.add_theme_font_size_override("font_size", 18)
	banner_title.add_theme_color_override("font_color", Color(0.55, 0.90, 1.0, 1.0))
	banner_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(banner_title)

	var banner_sub := Label.new()
	banner_sub.text = "ใช้ Void Crystal X (เติมเงินเท่านั้น)  ·  ปลอดภัย · ไม่บังคับ"
	banner_sub.position = Vector2(20, 32)
	banner_sub.add_theme_font_size_override("font_size", 10)
	banner_sub.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0, 0.65))
	banner_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(banner_sub)

	# "First top-up bonus" notice
	var notice := ColorRect.new()
	notice.size     = Vector2(cw - 24, 32)
	notice.position = Vector2(12, 64)
	notice.color    = Color(0.18, 0.30, 0.55, 0.55)
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(notice)

	var notice_lbl := Label.new()
	notice_lbl.text = "✦  รับโบนัสสองเท่าสำหรับการเติมเงินครั้งแรก — ครั้งเดียวตลอดชีพ"
	notice_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notice_lbl.offset_left = 12; notice_lbl.offset_right = 12
	notice_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_lbl.add_theme_font_size_override("font_size", 11)
	notice_lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 0.90))
	notice_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_child(notice_lbl)

	# 2-column grid for premium items
	const COLS   := 2
	const CARD_W := 440.0
	const CARD_H := 110.0
	const PAD_X  := 24.0
	const PAD_Y  := 12.0
	const START_X := 20.0
	const START_Y := 108.0

	for i in PREMIUM_ITEMS.size():
		var item: Dictionary = PREMIUM_ITEMS[i]
		var col := i % COLS
		var row := i / COLS
		var px := START_X + col * (CARD_W + PAD_X)
		var py := START_Y + row * (CARD_H + PAD_Y)
		_content_root.add_child(_make_item_card(item, px, py, CARD_W, CARD_H, shop))

# ── Wallet ────────────────────────────────────────────────────────
func _rebuild_wallet() -> void:
	if _gold_lbl: _gold_lbl.text = _fmt(CurrencyManager.gold)
	if _free_lbl: _free_lbl.text = _fmt(CurrencyManager.free_crystal)
	if _paid_lbl: _paid_lbl.text = _fmt(CurrencyManager.paid_crystal)

# ── Helpers ───────────────────────────────────────────────────────
func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.1fK" % (n / 1000.0)
	return str(n)

func _flat(bg: Color, border: Color, radius: int = 0, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color    = bg
	sb.border_color = border
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
