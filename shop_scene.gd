extends Control

const SC_MAIN := "res://main_menu.tscn"

# ── Data ──────────────────────────────────────────────────────────
const TABS: Array[String] = ["SUPPLIES", "CHARACTER", "EVENT"]
const TAB_LABELS := {
	"SUPPLIES":  "คลังวัสดุ",
	"CHARACTER": "ผู้ปฏิบัติการ",
	"EVENT":     "ร้านกิจกรรม",
}
const SUB_CATS := {
	"SUPPLIES":  ["ทั้งหมด", "พลังงาน", "คริสตัล", "EXP", "วัสดุอัปสกิล"],
	"CHARACTER": ["ทั้งหมด", "5★", "4★"],
	"EVENT":     ["ทั้งหมด", "ตัวละคร", "วัสดุ"],
}
const ITEMS := {
	"SUPPLIES": [
		# ── พลังงาน ──────────────────────────────────────────
		{"id":"e_s","name":"ก้อนพลังงาน S",    "icon":"⚡","rarity":2,"sub":"พลังงาน",
		 "desc":"เติมพลังงาน +60",             "cost":3000, "currency":"gold","stock":-1,
		 "effect":"energy:60"},
		{"id":"e_m","name":"ก้อนพลังงาน M",    "icon":"⚡","rarity":3,"sub":"พลังงาน",
		 "desc":"เติมพลังงาน +120",            "cost":8000, "currency":"gold","stock":-1,
		 "effect":"energy:120"},
		{"id":"e_l","name":"ก้อนพลังงาน L",    "icon":"⚡","rarity":4,"sub":"พลังงาน",
		 "desc":"เติมพลังงานเต็ม +240",        "cost":60,   "currency":"gems","stock":3,
		 "effect":"energy:240"},
		# ── คริสตัล / เม็ดสุ่ม ───────────────────────────────
		{"id":"g_1","name":"เม็ดสุ่ม ×1",      "icon":"◈","rarity":3,"sub":"คริสตัล",
		 "desc":"คริสตัลฟรี +150 (สุ่มได้ 1 ครั้ง)", "cost":150,  "currency":"gems","stock":-1,
		 "effect":"crystal:150"},
		{"id":"g_10","name":"เม็ดสุ่ม ×10",    "icon":"◈","rarity":4,"sub":"คริสตัล",
		 "desc":"คริสตัลฟรี +1,500 (สุ่มได้ 10 ครั้ง)","cost":1500,"currency":"gems","stock":-1,
		 "effect":"crystal:1500"},
		{"id":"s8","name":"ใบอนุญาตสุ่ม",      "icon":"⊛","rarity":5,"sub":"คริสตัล",
		 "desc":"สุ่มกาชาได้ 1 ครั้ง",        "cost":150,  "currency":"gems","stock":5,
		 "effect":"crystal:150"},
		# ── EXP / วัสดุ ──────────────────────────────────────
		{"id":"s2","name":"เงิน ×10,000",       "icon":"◎","rarity":3,"sub":"EXP",
		 "desc":"เงินสำหรับอัปเกรด",           "cost":200,  "currency":"gems","stock":-1},
		{"id":"s3","name":"EXP Card (เล็ก)",    "icon":"▲","rarity":2,"sub":"EXP",
		 "desc":"เพิ่ม EXP 1,000",             "cost":5000, "currency":"gold","stock":-1},
		{"id":"s4","name":"EXP Card (กลาง)",    "icon":"▲","rarity":3,"sub":"EXP",
		 "desc":"เพิ่ม EXP 5,000",             "cost":20000,"currency":"gold","stock":-1},
		{"id":"s5","name":"วัสดุอัปสกิล I",    "icon":"✦","rarity":3,"sub":"วัสดุอัปสกิล",
		 "desc":"อัปสกิลระดับ 2–4",            "cost":3000, "currency":"gold","stock":-1},
		{"id":"s6","name":"วัสดุอัปสกิล II",   "icon":"✦","rarity":4,"sub":"วัสดุอัปสกิล",
		 "desc":"อัปสกิลระดับ 5–7",            "cost":8000, "currency":"gold","stock":-1},
		{"id":"s7","name":"Compound Catalyst",  "icon":"⬡","rarity":5,"sub":"วัสดุอัปสกิล",
		 "desc":"วัสดุ Elite Promotion",        "cost":30000,"currency":"gold","stock":-1},
	],
	"CHARACTER": [
		{"id":"c1","name":"Lyra", "icon":"★","rarity":5,"sub":"5★",
		 "desc":"5★ Sniper — DPS ระยะไกลสูง",      "cost":3000,"currency":"gems","stock":1},
		{"id":"c2","name":"Kael", "icon":"★","rarity":4,"sub":"4★",
		 "desc":"4★ Defender — แนวหน้าแข็งแกร่ง", "cost":1200,"currency":"gems","stock":1},
		{"id":"c3","name":"Mira", "icon":"★","rarity":4,"sub":"4★",
		 "desc":"4★ Medic — รักษา AOE",             "cost":1200,"currency":"gems","stock":1},
		{"id":"c4","name":"Voss", "icon":"★","rarity":4,"sub":"4★",
		 "desc":"4★ Caster — ดีลเวทย์",            "cost":1200,"currency":"gems","stock":1},
	],
	"EVENT": [
		{"id":"e1","name":"Event Token ×5",  "icon":"◆","rarity":3,"sub":"วัสดุ",
		 "desc":"โทเค็นกิจกรรมพิเศษ",       "cost":0,   "currency":"gold","stock":-1},
		{"id":"e2","name":"Seraph (จำกัด)",  "icon":"★","rarity":5,"sub":"ตัวละคร",
		 "desc":"5★ ตัวละครจำกัด",           "cost":600, "currency":"gems","stock":1},
		{"id":"e3","name":"Outfit: Eclipse", "icon":"◈","rarity":4,"sub":"วัสดุ",
		 "desc":"ชุดทางเลือกของ Lyra",        "cost":300, "currency":"gems","stock":1},
		{"id":"e4","name":"Compound Catalyst","icon":"⬡","rarity":4,"sub":"วัสดุ",
		 "desc":"วัสดุสังเคราะห์ขั้นสูง",  "cost":15000,"currency":"gold","stock":3},
		{"id":"e5","name":"เงิน ×30,000",    "icon":"◎","rarity":3,"sub":"วัสดุ",
		 "desc":"Lungmen Dollars",           "cost":180, "currency":"gems","stock":2},
	],
}

# ── State ─────────────────────────────────────────────────────────
var _stock: Dictionary = {}
var _current_tab := "SUPPLIES"
var _current_sub := "ทั้งหมด"
var _selected_item: Dictionary = {}

# ── Layout constants ──────────────────────────────────────────────
const SW := 1152; const SH := 648
const TOP_H  := 54   # topbar
const TAB_H  := 46   # horizontal tabs
const SUB_H  := 38   # sub-category filter pills
const CON_Y  := TOP_H + TAB_H + SUB_H   # 138
const CON_H  := SH - CON_Y              # 510
const COLS   := 4
const CARD_W := 244
const CARD_H := 248
const GAP    := 14
const PAD    := 24   # grid side padding

# ── Palette ───────────────────────────────────────────────────────
const C_BG   := Color(0.030, 0.038, 0.082, 1.0)
const C_TOP  := Color(0.038, 0.048, 0.108, 1.0)
const C_SUB  := Color(0.032, 0.040, 0.090, 1.0)
const C_LINE := Color(0.20, 0.40, 0.80, 0.20)
const C_ACT  := Color(0.38, 0.72, 1.00, 1.0)
const C_TXT  := Color(0.90, 0.93, 1.00, 1.0)
const C_DIM  := Color(0.52, 0.64, 0.84, 0.68)
const C_GOLD := Color(1.00, 0.84, 0.30, 1.0)
const C_GREY := Color(0.34, 0.42, 0.54, 0.80)
const C_R5   := Color(1.00, 0.80, 0.20, 1.0)
const C_R4   := Color(0.76, 0.48, 1.00, 1.0)
const C_R3   := Color(0.36, 0.62, 1.00, 1.0)
const C_R2   := Color(0.40, 0.78, 0.52, 1.0)

# ── Refs ──────────────────────────────────────────────────────────
var _tab_btns: Array[Button] = []
var _tab_inds: Array         = []
var _sub_btns: Array[Button] = []
var _sub_bar:  Control
var _item_grid: GridContainer
var _wallet_row: HBoxContainer
var _confirm_ov: Control

# ══════════════════════════════════════════════════════════════════
func _ready() -> void:
	for tab in ITEMS:
		for it in ITEMS[tab]:
			if int(it["stock"]) > 0:
				_stock[it["id"]] = int(it["stock"])
	_build_ui()

# ══════════════════════════════════════════════════════════════════
#  UI BUILD
# ══════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_topbar()
	_build_tabbar()
	_build_subbar()
	_build_content()
	_build_confirm_overlay()
	_switch_tab("SUPPLIES")

# ── Top bar ───────────────────────────────────────────────────────
func _build_topbar() -> void:
	var bar := ColorRect.new()
	bar.size  = Vector2(SW, TOP_H)
	bar.color = C_TOP
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	# bottom line
	_hline(0, TOP_H - 1, SW)

	var back := Button.new()
	back.text = "◀"
	back.size = Vector2(50, TOP_H)
	back.add_theme_font_size_override("font_size", 24)
	back.add_theme_color_override("font_color", C_TXT)
	for st in ["normal","hover","pressed","focus"]:
		back.add_theme_stylebox_override(st, _flat(Color(0,0,0,0), Color(0,0,0,0)))
	back.pressed.connect(_go_back)
	add_child(back)

	var title := Label.new()
	title.text = "STORE"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", C_TXT)
	title.position = Vector2(50, 0)
	title.size     = Vector2(180, TOP_H)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	_wallet_row = HBoxContainer.new()
	_wallet_row.position = Vector2(SW - 340, (TOP_H - 30) / 2.0)
	_wallet_row.size     = Vector2(332, 30)
	_wallet_row.alignment = BoxContainer.ALIGNMENT_END
	add_child(_wallet_row)
	_rebuild_wallet()
	if not CurrencyManager.currency_changed.is_connected(_rebuild_wallet):
		CurrencyManager.currency_changed.connect(_rebuild_wallet)

# ── Horizontal tab bar ────────────────────────────────────────────
func _build_tabbar() -> void:
	var bar := ColorRect.new()
	bar.position = Vector2(0, TOP_H)
	bar.size     = Vector2(SW, TAB_H)
	bar.color    = C_TOP
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_hline(0, TOP_H + TAB_H - 1, SW)

	var x := 52.0
	for i in TABS.size():
		var tab: String = TABS[i]
		var btn := Button.new()
		btn.text = TAB_LABELS[tab]
		btn.size = Vector2(148, TAB_H)
		btn.position = Vector2(x, TOP_H)
		btn.add_theme_font_size_override("font_size", 13)
		for st in ["normal","hover","pressed","focus"]:
			btn.add_theme_stylebox_override(st, _flat(Color(0,0,0,0), Color(0,0,0,0)))
		btn.pressed.connect(_switch_tab.bind(tab))
		add_child(btn)
		_tab_btns.append(btn)

		# indicator line (shown when active)
		var ind := ColorRect.new()
		ind.size     = Vector2(120, 2)
		ind.position = Vector2(x + 14, TOP_H + TAB_H - 2)
		ind.color    = Color(C_ACT.r, C_ACT.g, C_ACT.b, 0.0)
		ind.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ind)
		_tab_inds.append(ind)

		x += 152.0

# ── Sub-category filter bar ───────────────────────────────────────
func _build_subbar() -> void:
	_sub_bar = Control.new()
	_sub_bar.position    = Vector2(0, TOP_H + TAB_H)
	_sub_bar.size        = Vector2(SW, SUB_H)
	_sub_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub_bar)

	var sbg := ColorRect.new()
	sbg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sbg.color = C_SUB
	sbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sub_bar.add_child(sbg)

	_hline(0, TOP_H + TAB_H + SUB_H - 1, SW)

# ── Content area ──────────────────────────────────────────────────
func _build_content() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, CON_Y)
	scroll.size     = Vector2(SW, CON_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   PAD)
	mc.add_theme_constant_override("margin_right",  PAD)
	mc.add_theme_constant_override("margin_top",    20)
	mc.add_theme_constant_override("margin_bottom", 20)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_item_grid = GridContainer.new()
	_item_grid.columns = COLS
	_item_grid.add_theme_constant_override("h_separation", GAP)
	_item_grid.add_theme_constant_override("v_separation", GAP)
	_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.add_child(_item_grid)
	scroll.add_child(mc)

# ── Wallet ────────────────────────────────────────────────────────
func _rebuild_wallet() -> void:
	for c in _wallet_row.get_children(): c.queue_free()
	_wallet_pill("💰", null, _fmt(CurrencyManager.gold),         C_GOLD)
	_wallet_pill("", load("res://image/crystal_gem.png"), _fmt(CurrencyManager.free_crystal), Color(0.35, 0.90, 1.00, 1.0))
	_wallet_pill("🔮", null, _fmt(CurrencyManager.paid_crystal), Color(0.76, 0.52, 0.92, 1.0))

func _wallet_pill(icon: String, icon_tex: Texture2D, val: String, col: Color) -> void:
	var pill := Panel.new()
	pill.custom_minimum_size = Vector2(102, 28)
	pill.add_theme_stylebox_override("panel",
		_flat(Color(0.06, 0.09, 0.22, 0.85), Color(col.r,col.g,col.b,0.30), 5, 1))
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8; row.offset_right = -8
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if icon_tex:
		var ico := TextureRect.new()
		ico.texture = icon_tex
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.custom_minimum_size = Vector2(16, 16)
		row.add_child(ico)
	elif icon != "":
		var ico := Label.new()
		ico.text = icon
		ico.add_theme_font_size_override("font_size", 12)
		row.add_child(ico)
	var amt := Label.new()
	amt.text = " " + val
	amt.add_theme_font_size_override("font_size", 11)
	amt.add_theme_color_override("font_color", col)
	row.add_child(amt)
	pill.add_child(row)
	_wallet_row.add_child(pill)
	var sp := Control.new(); sp.custom_minimum_size = Vector2(5,0)
	_wallet_row.add_child(sp)

# ══════════════════════════════════════════════════════════════════
#  TAB & FILTER SWITCH
# ══════════════════════════════════════════════════════════════════
func _switch_tab(tab: String) -> void:
	_current_tab = tab
	_current_sub = "ทั้งหมด"
	_selected_item = {}

	# update tab button styles
	for i in _tab_btns.size():
		var active: bool = TABS[i] == tab
		_tab_btns[i].add_theme_color_override("font_color",
			C_TXT if active else C_DIM)
		_tab_inds[i].color = Color(C_ACT.r, C_ACT.g, C_ACT.b, 1.0 if active else 0.0)

	# rebuild sub-category pills
	for c in _sub_bar.get_children():
		if not (c is ColorRect):
			c.queue_free()
	_sub_btns.clear()

	var sx := float(PAD)
	for sub in SUB_CATS[tab]:
		var btn := Button.new()
		btn.text = sub
		btn.add_theme_font_size_override("font_size", 11)
		btn.size = Vector2(0, 26)
		btn.position = Vector2(sx, (SUB_H - 26) / 2.0)
		_style_sub_btn(btn, sub == _current_sub)
		btn.pressed.connect(_switch_sub.bind(sub))
		_sub_bar.add_child(btn)
		_sub_btns.append(btn)
		# measure width via minimum_size hack
		btn.size.x = btn.text.length() * 10 + 28
		sx += btn.size.x + 8

	_rebuild_grid()

func _switch_sub(sub: String) -> void:
	_current_sub = sub
	for i in _sub_btns.size():
		_style_sub_btn(_sub_btns[i], _sub_btns[i].text == sub)
	_rebuild_grid()

func _rebuild_grid() -> void:
	for c in _item_grid.get_children(): c.queue_free()
	var list: Array = ITEMS[_current_tab]
	for item in list:
		if _current_sub != "ทั้งหมด" and str(item.get("sub","")) != _current_sub:
			continue
		_item_grid.add_child(_make_card(item))

# ══════════════════════════════════════════════════════════════════
#  ITEM CARD  (HSR style — portrait, rarity gradient)
# ══════════════════════════════════════════════════════════════════
func _make_card(item: Dictionary) -> Control:
	var id       := str(item["id"])
	var rarity   := int(item.get("rarity", 3))
	var stock    := int(item.get("stock", -1))
	var remain   := int(_stock.get(id, stock))
	var sold_out := stock > 0 and remain <= 0
	var cost     := int(item["cost"])
	var cur      := str(item.get("currency","gold"))
	var affordable := cost == 0 or _can_afford(cur, cost)
	var r_col    := _rcol(rarity)

	var card := Panel.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)

	# card background
	var card_bg := Color(0.06, 0.09, 0.20, 0.90) if not sold_out else Color(0.04,0.05,0.10,0.88)
	var border_a := 0.55 if not sold_out else 0.20
	card.add_theme_stylebox_override("panel",
		_flat(card_bg, Color(r_col.r, r_col.g, r_col.b, border_a), 6, 1))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	if not sold_out:
		card.gui_input.connect(_on_card_click.bind(item, card))

	# ── Rarity color strip at top ──
	var strip := ColorRect.new()
	strip.color  = Color(r_col.r, r_col.g, r_col.b, 0.70 if not sold_out else 0.20)
	strip.size   = Vector2(CARD_W, 3)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(strip)

	# ── Icon area (upper 62%) ──
	const ICON_H := 152
	var icon_bg := Panel.new()
	icon_bg.position = Vector2(0, 3)
	icon_bg.size     = Vector2(CARD_W, ICON_H)
	var ib_sb := StyleBoxFlat.new()
	ib_sb.bg_color = Color(r_col.r * 0.18, r_col.g * 0.18, r_col.b * 0.22, 0.55 if not sold_out else 0.15)
	icon_bg.add_theme_stylebox_override("panel", ib_sb)
	icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_bg)

	var icon_lbl := Label.new()
	icon_lbl.text = str(item["icon"])
	icon_lbl.add_theme_font_size_override("font_size", 52)
	icon_lbl.add_theme_color_override("font_color",
		Color(r_col.r, r_col.g, r_col.b, 0.22 if sold_out else 1.0))
	icon_lbl.size     = Vector2(CARD_W, ICON_H)
	icon_lbl.position = Vector2(0, 3)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_lbl)

	# ── Rarity stars ──
	const STAR_Y := 158
	var star_lbl := Label.new()
	star_lbl.text = "★".repeat(rarity)
	star_lbl.add_theme_font_size_override("font_size", 9)
	star_lbl.add_theme_color_override("font_color",
		Color(r_col.r, r_col.g, r_col.b, 0.75 if not sold_out else 0.28))
	star_lbl.size     = Vector2(CARD_W, 14)
	star_lbl.position = Vector2(0, STAR_Y)
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(star_lbl)

	# ── Item name ──
	const NAME_Y := 175
	var name_lbl := Label.new()
	name_lbl.text = str(item["name"])
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", C_GREY if sold_out else C_TXT)
	name_lbl.size     = Vector2(CARD_W - 14, 40)
	name_lbl.position = Vector2(7, NAME_Y)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# ── Cost / SOLD OUT ──
	const COST_Y := 217
	var cost_lbl := Label.new()
	if sold_out:
		cost_lbl.text = "SOLD OUT"
		cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.32, 0.32, 0.85))
	elif cost == 0:
		cost_lbl.text = "FREE"
		cost_lbl.add_theme_color_override("font_color", Color(0.38, 1.0, 0.55, 1.0))
	else:
		cost_lbl.text = "%s %s" % [_cur_icon(cur), _fmt(cost)]
		cost_lbl.add_theme_color_override("font_color",
			C_GOLD if affordable else Color(1.0, 0.38, 0.38, 1.0))
	cost_lbl.add_theme_font_size_override("font_size", 12)
	cost_lbl.size     = Vector2(CARD_W, 22)
	cost_lbl.position = Vector2(0, COST_Y)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(cost_lbl)

	# ── Stock badge (top-right corner) ──
	if stock > 0:
		var badge := Panel.new()
		badge.size     = Vector2(38, 20)
		badge.position = Vector2(CARD_W - 40, 6)
		badge.add_theme_stylebox_override("panel",
			_flat(Color(0.04,0.06,0.18,0.92), Color(r_col.r,r_col.g,r_col.b,0.5), 4, 1))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
		var blbl := Label.new()
		blbl.text = "×%d" % (remain if not sold_out else 0)
		blbl.add_theme_font_size_override("font_size", 9)
		blbl.add_theme_color_override("font_color",
			Color(0.60, 0.72, 1.0, 0.9) if not sold_out else Color(0.5,0.5,0.5,0.7))
		blbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		blbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		blbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(blbl)

	# ── Sold-out overlay ──
	if sold_out:
		var dim := ColorRect.new()
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.color = Color(0, 0, 0, 0.40)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(dim)

	return card

# ── Card click ────────────────────────────────────────────────────
func _on_card_click(ev: InputEvent, item: Dictionary, card: Control) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_selected_item = item
		_fx_scale(card)
		_open_confirm()

# ══════════════════════════════════════════════════════════════════
#  CONFIRM OVERLAY  (HSR style — left icon + right info)
# ══════════════════════════════════════════════════════════════════
func _build_confirm_overlay() -> void:
	_confirm_ov = Control.new()
	_confirm_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_ov.visible = false
	_confirm_ov.z_index = 60
	add_child(_confirm_ov)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.70)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_confirm_ov.visible = false)
	_confirm_ov.add_child(dim)

	const PW := 500; const PH := 240
	var box := Panel.new()
	box.name     = "Box"
	box.size     = Vector2(PW, PH)
	box.position = Vector2((SW - PW) * 0.5, (SH - PH) * 0.5)
	box.z_index  = 1
	box.add_theme_stylebox_override("panel",
		_flat(Color(0.06, 0.08, 0.18, 0.98),
			  Color(C_ACT.r, C_ACT.g, C_ACT.b, 0.50), 10, 1))
	_confirm_ov.add_child(box)

	# Left icon panel
	var icon_panel := Panel.new()
	icon_panel.name = "IconPanel"
	icon_panel.size = Vector2(140, PH)
	icon_panel.add_theme_stylebox_override("panel",
		_flat(Color(0.08, 0.10, 0.24, 0.95), Color(0,0,0,0), 10, 0))
	box.add_child(icon_panel)

	var icon_lbl := Label.new()
	icon_lbl.name = "IconLbl"
	icon_lbl.add_theme_font_size_override("font_size", 54)
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.add_child(icon_lbl)

	var rarity_bar := ColorRect.new()
	rarity_bar.name = "RarityBar"
	rarity_bar.size = Vector2(3, PH)
	rarity_bar.position = Vector2(140, 0)
	rarity_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rarity_bar)

	# Right info
	var info := Control.new()
	info.name     = "Info"
	info.position = Vector2(150, 0)
	info.size     = Vector2(PW - 150, PH)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(info)

	var item_name := Label.new()
	item_name.name = "ItemName"
	item_name.add_theme_font_size_override("font_size", 17)
	item_name.add_theme_color_override("font_color", C_TXT)
	item_name.position = Vector2(16, 22)
	item_name.size     = Vector2(320, 28)
	item_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(item_name)

	var stars_lbl := Label.new()
	stars_lbl.name = "Stars"
	stars_lbl.add_theme_font_size_override("font_size", 11)
	stars_lbl.position = Vector2(16, 52)
	stars_lbl.size     = Vector2(200, 16)
	stars_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(stars_lbl)

	var desc_lbl := Label.new()
	desc_lbl.name = "Desc"
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", C_DIM)
	desc_lbl.position = Vector2(16, 74)
	desc_lbl.size     = Vector2(320, 40)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(desc_lbl)

	# separator
	var sep := ColorRect.new()
	sep.color    = Color(C_ACT.r, C_ACT.g, C_ACT.b, 0.18)
	sep.size     = Vector2(PW - 166, 1)
	sep.position = Vector2(16, 122)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(sep)

	var cost_row := HBoxContainer.new()
	cost_row.name     = "CostRow"
	cost_row.position = Vector2(16, 132)
	cost_row.size     = Vector2(320, 28)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(cost_row)

	var cost_hint := Label.new()
	cost_hint.text = "ราคา : "
	cost_hint.add_theme_font_size_override("font_size", 12)
	cost_hint.add_theme_color_override("font_color", C_DIM)
	cost_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(cost_hint)

	var cost_val := Label.new()
	cost_val.name = "CostVal"
	cost_val.add_theme_font_size_override("font_size", 14)
	cost_val.add_theme_color_override("font_color", C_GOLD)
	cost_val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(cost_val)

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.position = Vector2(16, PH - 54)
	btn_row.size     = Vector2(PW - 166, 40)
	btn_row.add_theme_constant_override("separation", 12)
	info.add_child(btn_row)

	var cancel := Button.new()
	cancel.text = "ยกเลิก"
	cancel.custom_minimum_size = Vector2(140, 40)
	cancel.add_theme_font_size_override("font_size", 13)
	cancel.add_theme_color_override("font_color", C_DIM)
	cancel.add_theme_stylebox_override("normal",  _flat(Color(0.10,0.12,0.26,1), Color(C_LINE.r,C_LINE.g,C_LINE.b,0.4), 6,1))
	cancel.add_theme_stylebox_override("hover",   _flat(Color(0.14,0.17,0.32,1), Color(C_LINE.r,C_LINE.g,C_LINE.b,0.5), 6,1))
	cancel.add_theme_stylebox_override("pressed", _flat(Color(0.08,0.10,0.20,1), Color(0,0,0,0), 6))
	cancel.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	cancel.pressed.connect(func(): _confirm_ov.visible = false)
	btn_row.add_child(cancel)

	var buy := Button.new()
	buy.name = "BuyBtn"
	buy.text = "แลก / ซื้อ"
	buy.custom_minimum_size = Vector2(150, 40)
	buy.add_theme_font_size_override("font_size", 13)
	buy.add_theme_color_override("font_color", Color(0.04, 0.06, 0.14, 1.0))
	buy.add_theme_stylebox_override("normal",  _flat(C_ACT, Color(0,0,0,0), 6))
	buy.add_theme_stylebox_override("hover",   _flat(Color(0.45,0.82,1.0,1), Color(0,0,0,0), 6))
	buy.add_theme_stylebox_override("pressed", _flat(Color(0.25,0.60,0.92,1), Color(0,0,0,0), 6))
	buy.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	buy.pressed.connect(_execute_purchase)
	btn_row.add_child(buy)

func _open_confirm() -> void:
	if _selected_item.is_empty(): return
	var item  := _selected_item
	var box   := _confirm_ov.get_node("Box") as Panel
	var rarity := int(item.get("rarity", 3))
	var r_col  := _rcol(rarity)
	var cost   := int(item["cost"])
	var cur    := str(item.get("currency","gold"))

	box.get_node("IconPanel/IconLbl").text = str(item["icon"])
	box.get_node("RarityBar").color = Color(r_col.r, r_col.g, r_col.b, 0.8)
	box.get_node("Info/ItemName").text = str(item["name"])
	box.get_node("Info/Stars").text    = "★".repeat(rarity)
	box.get_node("Info/Stars").add_theme_color_override("font_color", r_col)
	box.get_node("Info/Desc").text     = str(item.get("desc",""))

	var cost_val := box.get_node("Info/CostRow/CostVal") as Label
	if cost == 0:
		cost_val.text = "FREE"
		cost_val.add_theme_color_override("font_color", Color(0.38, 1.0, 0.55))
	else:
		cost_val.text = "%s %s" % [_cur_icon(cur), _fmt(cost)]
		cost_val.add_theme_color_override("font_color",
			C_GOLD if _can_afford(cur, cost) else Color(1.0, 0.38, 0.38))

	_confirm_ov.visible = true

func _execute_purchase() -> void:
	_confirm_ov.visible = false
	var item := _selected_item
	if item.is_empty(): return
	var cost := int(item["cost"])
	if cost > 0:
		var cur := str(item.get("currency","gold"))
		var ok: bool = CurrencyManager.spend_gems(cost) if cur == "gems" else CurrencyManager.spend_gold(cost)
		if not ok:
			_selected_item = {}
			return
	var stock := int(item.get("stock",-1))
	if stock > 0:
		_stock[str(item["id"])] = int(_stock.get(str(item["id"]), stock)) - 1
	# ── Apply item effect ──────────────────────────────────────────
	var effect: String = str(item.get("effect", ""))
	if effect != "":
		var parts := effect.split(":")
		if parts.size() == 2:
			var amount: int = int(parts[1])
			match parts[0]:
				"energy":  CurrencyManager.add_energy(amount)
				"crystal": CurrencyManager.add_free_crystal(amount)
				"gold":    CurrencyManager.add_gold(amount)
	DomainManager.add_points("shop")
	_rebuild_wallet()
	_rebuild_grid()
	_selected_item = {}

# ══════════════════════════════════════════════════════════════════
#  HELPERS
# ══════════════════════════════════════════════════════════════════
func _can_afford(cur: String, amount: int) -> bool:
	if cur == "gems": return CurrencyManager.total_crystal() >= amount
	return CurrencyManager.gold >= amount

func _cur_icon(cur: String) -> String:
	return "💠" if cur == "gems" else "💰"

func _rcol(rarity: int) -> Color:
	match rarity:
		5: return C_R5
		4: return C_R4
		3: return C_R3
		_: return C_R2

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.1fK" % (n / 1000.0)
	return str(n)

func _style_sub_btn(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_color_override("font_color", Color(0.06, 0.08, 0.18, 1.0))
		btn.add_theme_stylebox_override("normal",  _flat(C_ACT, Color(0,0,0,0), 12))
		btn.add_theme_stylebox_override("hover",   _flat(C_ACT, Color(0,0,0,0), 12))
		btn.add_theme_stylebox_override("pressed", _flat(Color(0.28,0.62,0.92,1), Color(0,0,0,0), 12))
	else:
		btn.add_theme_color_override("font_color", C_DIM)
		btn.add_theme_stylebox_override("normal",  _flat(Color(1,1,1,0.06), Color(C_LINE.r,C_LINE.g,C_LINE.b,0.35), 12, 1))
		btn.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.10), Color(C_LINE.r,C_LINE.g,C_LINE.b,0.50), 12, 1))
		btn.add_theme_stylebox_override("pressed", _flat(Color(1,1,1,0.04), Color(0,0,0,0), 12))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0)))

func _hline(x: float, y: float, w: float) -> void:
	var line := ColorRect.new()
	line.color    = C_LINE
	line.position = Vector2(x, y)
	line.size     = Vector2(w, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)

func _flat(bg: Color, border: Color, radius: int = 0, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = bg
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
	t.tween_property(node, "scale", Vector2(0.92, 0.92), 0.07)
	t.tween_property(node, "scale", Vector2(1.0,  1.0),  0.16)

func _go_back() -> void:
	SceneTransition.fade_to(SC_MAIN)
