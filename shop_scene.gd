extends Control

const SC_MAIN := "res://main_menu.tscn"

# ── Shop Data ─────────────────────────────────────────────────────
const TABS := ["SUPPLIES", "OPERATOR", "EVENT"]

const TAB_LABELS := {
	"SUPPLIES": "คลังวัสดุ",
	"OPERATOR": "ผู้ปฏิบัติการ",
	"EVENT":    "กิจกรรมพิเศษ",
}
const TAB_ICONS := {
	"SUPPLIES": "◈",
	"OPERATOR": "★",
	"EVENT":    "◆",
}

const ITEMS := {
	"SUPPLIES": [
		{"id": "s1", "name": "เพชรฟรี ×60",       "icon": "◈", "rarity": 4,
		 "desc": "เพชรฟรีสำหรับสุ่มกาชา", "cost": 0,      "currency": "gold", "stock": -1},
		{"id": "s2", "name": "เงิน ×10,000",       "icon": "◎", "rarity": 3,
		 "desc": "เงินสำหรับอัปเกรด", "cost": 200,  "currency": "gems", "stock": -1},
		{"id": "s3", "name": "EXP Card (เล็ก)",    "icon": "▲", "rarity": 2,
		 "desc": "เพิ่ม EXP 1,000", "cost": 5000, "currency": "gold", "stock": -1},
		{"id": "s4", "name": "EXP Card (กลาง)",    "icon": "▲", "rarity": 3,
		 "desc": "เพิ่ม EXP 5,000", "cost": 20000,"currency": "gold", "stock": -1},
		{"id": "s5", "name": "วัสดุอัปสกิล I",    "icon": "✦", "rarity": 3,
		 "desc": "อัปสกิลระดับ 2–4", "cost": 3000, "currency": "gold", "stock": -1},
		{"id": "s6", "name": "วัสดุอัปสกิล II",   "icon": "✦", "rarity": 4,
		 "desc": "อัปสกิลระดับ 5–7", "cost": 8000, "currency": "gold", "stock": -1},
		{"id": "s7", "name": "Compound Catalyst",  "icon": "⬡", "rarity": 5,
		 "desc": "วัสดุ Elite Promotion", "cost": 30000,"currency": "gold", "stock": -1},
		{"id": "s8", "name": "ใบอนุญาตสุ่ม",      "icon": "⊛", "rarity": 5,
		 "desc": "แลกได้ 1 ครั้งสุ่มกาชา", "cost": 160,  "currency": "gems", "stock": 5},
	],
	"OPERATOR": [
		{"id": "o1", "name": "Lyra",  "icon": "★", "rarity": 5,
		 "desc": "5★ Sniper — DPS ระยะไกลสูง", "cost": 3000, "currency": "gems", "stock": 1},
		{"id": "o2", "name": "Kael",  "icon": "★", "rarity": 4,
		 "desc": "4★ Defender — แนวหน้าแข็งแกร่ง", "cost": 1200, "currency": "gems", "stock": 1},
		{"id": "o3", "name": "Mira",  "icon": "★", "rarity": 4,
		 "desc": "4★ Medic — รักษา AOE", "cost": 1200, "currency": "gems", "stock": 1},
		{"id": "o4", "name": "Voss",  "icon": "★", "rarity": 4,
		 "desc": "4★ Caster — ดีลเวทย์", "cost": 1200, "currency": "gems", "stock": 1},
	],
	"EVENT": [
		{"id": "e1", "name": "Event Token ×5",   "icon": "◆", "rarity": 3,
		 "desc": "โทเค็นกิจกรรมพิเศษ", "cost": 0,    "currency": "gold", "stock": -1},
		{"id": "e2", "name": "Seraph (จำกัด)",   "icon": "★", "rarity": 5,
		 "desc": "5★ ตัวละครจำกัด", "cost": 600, "currency": "gems", "stock": 1},
		{"id": "e3", "name": "Outfit: Eclipse",  "icon": "◈", "rarity": 4,
		 "desc": "ชุดทางเลือกของ Lyra", "cost": 300, "currency": "gems", "stock": 1},
		{"id": "e4", "name": "Compound Catalyst","icon": "⬡", "rarity": 4,
		 "desc": "วัสดุสังเคราะห์ขั้นสูง", "cost": 15000,"currency": "gold", "stock": 3},
		{"id": "e5", "name": "เงิน ×30,000",     "icon": "◎", "rarity": 3,
		 "desc": "Lungmen Dollars", "cost": 180,  "currency": "gems", "stock": 2},
	],
}

var _stock: Dictionary = {}
var _current_tab    := "SUPPLIES"
var _selected_item: Dictionary = {}

# ── Layout ────────────────────────────────────────────────────────
const SIDEBAR_W := 180
const TOPBAR_H  := 56
const SCREEN_W  := 1152
const SCREEN_H  := 648
const GRID_X    := SIDEBAR_W
const GRID_W    := SCREEN_W - SIDEBAR_W   # 972

# ── Colors ────────────────────────────────────────────────────────
const C_R5     := Color(1.00, 0.80, 0.20, 1.0)
const C_R4     := Color(0.72, 0.50, 1.00, 1.0)
const C_R3     := Color(0.35, 0.65, 1.00, 1.0)
const C_R2     := Color(0.45, 0.80, 0.55, 1.0)
const C_BG     := Color(0.04, 0.05, 0.10, 1.0)
const C_SIDEBAR:= Color(0.025, 0.035, 0.08, 1.0)
const C_PANEL  := Color(0.055, 0.075, 0.16, 1.0)
const C_BORDER := Color(0.18, 0.52, 0.9,  0.3)
const C_ACTIVE := Color(0.25, 0.65, 1.0,  1.0)
const C_TEXT   := Color(0.88, 0.92, 1.00, 1.0)
const C_SUB    := Color(0.55, 0.70, 0.90, 0.8)
const C_GOLD   := Color(1.00, 0.82, 0.25, 1.0)
const C_GREY   := Color(0.40, 0.48, 0.60, 0.7)

# ── Node refs ─────────────────────────────────────────────────────
var _tab_btns:  Array[Button] = []
var _item_grid: GridContainer
var _wallet_row: HBoxContainer
var _confirm_ov: Control
var _tab_title: Label

func _ready() -> void:
	_init_stock()
	_build_ui()

func _init_stock() -> void:
	for tab in ITEMS:
		for item in ITEMS[tab]:
			if item["stock"] > 0:
				_stock[item["id"]] = item["stock"]

# ════════════════════════════════════════════════════════════════
#  UI BUILD
# ════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_sidebar()
	_build_topbar()
	_build_grid_area()
	_build_confirm_overlay()
	_switch_tab("SUPPLIES")

# ── Sidebar ───────────────────────────────────────────────────────
func _build_sidebar() -> void:
	var sb := Panel.new()
	sb.position = Vector2(0, 0)
	sb.size     = Vector2(SIDEBAR_W, SCREEN_H)
	sb.add_theme_stylebox_override("panel", _flat(C_SIDEBAR, C_BORDER, 0, 0, 0, 0, 0, 1))
	add_child(sb)

	var logo := Label.new()
	logo.text = "SHOP"
	logo.add_theme_font_size_override("font_size", 22)
	logo.add_theme_color_override("font_color", C_TEXT)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.size     = Vector2(SIDEBAR_W, 52)
	logo.position = Vector2(0, 12)
	logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sb.add_child(logo)

	var sep := ColorRect.new()
	sep.color    = Color(C_BORDER)
	sep.size     = Vector2(SIDEBAR_W - 24, 1)
	sep.position = Vector2(12, 60)
	sb.add_child(sep)

	var y := 76.0
	for tab in TABS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(SIDEBAR_W, 48)
		btn.position = Vector2(0, y)
		btn.text = "%s  %s" % [TAB_ICONS[tab], TAB_LABELS[tab]]
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0)))
		_style_sidebar_btn(btn, false)
		btn.pressed.connect(_switch_tab.bind(tab))
		sb.add_child(btn)
		_tab_btns.append(btn)
		y += 52

	var back := Button.new()
	back.text = "← กลับ"
	back.add_theme_font_size_override("font_size", 12)
	back.add_theme_color_override("font_color", C_SUB)
	back.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
	back.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.06), Color(0,0,0,0)))
	back.add_theme_stylebox_override("pressed", _flat(Color(1,1,1,0.03), Color(0,0,0,0)))
	back.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	back.size     = Vector2(SIDEBAR_W, 40)
	back.position = Vector2(0, SCREEN_H - 52)
	back.pressed.connect(_go_back)
	sb.add_child(back)

# ── Top bar ───────────────────────────────────────────────────────
func _build_topbar() -> void:
	var bar := Panel.new()
	bar.position = Vector2(SIDEBAR_W, 0)
	bar.size     = Vector2(SCREEN_W - SIDEBAR_W, TOPBAR_H)
	bar.add_theme_stylebox_override("panel", _flat(Color(0.05, 0.07, 0.14, 1.0), C_BORDER, 0, 0, 0, 1))
	add_child(bar)

	_tab_title = Label.new()
	_tab_title.text = TAB_LABELS["SUPPLIES"]
	_tab_title.add_theme_font_size_override("font_size", 16)
	_tab_title.add_theme_color_override("font_color", C_TEXT)
	_tab_title.position = Vector2(20, 0)
	_tab_title.size     = Vector2(300, TOPBAR_H)
	_tab_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(_tab_title)

	_wallet_row = HBoxContainer.new()
	_wallet_row.position = Vector2(300, 10)
	_wallet_row.size     = Vector2(SCREEN_W - SIDEBAR_W - 300 - 16, 36)
	_wallet_row.alignment = BoxContainer.ALIGNMENT_END
	bar.add_child(_wallet_row)
	_rebuild_wallet()

# ── Grid area ─────────────────────────────────────────────────────
func _build_grid_area() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(GRID_X, TOPBAR_H)
	scroll.size     = Vector2(GRID_W, SCREEN_H - TOPBAR_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   16)
	mc.add_theme_constant_override("margin_right",  16)
	mc.add_theme_constant_override("margin_top",    20)
	mc.add_theme_constant_override("margin_bottom", 20)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_item_grid = GridContainer.new()
	_item_grid.columns = 5
	_item_grid.add_theme_constant_override("h_separation", 12)
	_item_grid.add_theme_constant_override("v_separation", 12)
	_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.add_child(_item_grid)
	scroll.add_child(mc)

# ── Wallet ────────────────────────────────────────────────────────
func _rebuild_wallet() -> void:
	for c in _wallet_row.get_children():
		c.queue_free()
	_add_wallet_pill("💰", str(CurrencyManager.gold),         Color(1.00, 0.82, 0.25, 1.0))
	_add_wallet_pill("💠", str(CurrencyManager.free_crystal), Color(0.35, 0.90, 1.00, 1.0))

func _add_wallet_pill(icon: String, value: String, col: Color) -> void:
	var pill := Panel.new()
	pill.custom_minimum_size = Vector2(96, 30)
	pill.add_theme_stylebox_override("panel", _flat(Color(0.06, 0.10, 0.22, 0.9), Color(C_BORDER), 6))
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8; row.offset_right = -8
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ico := Label.new()
	ico.text = icon
	ico.add_theme_font_size_override("font_size", 13)
	row.add_child(ico)
	var amt := Label.new()
	amt.text = " " + value
	amt.add_theme_font_size_override("font_size", 11)
	amt.add_theme_color_override("font_color", col)
	row.add_child(amt)
	pill.add_child(row)
	_wallet_row.add_child(pill)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(6, 0)
	_wallet_row.add_child(spacer)

# ════════════════════════════════════════════════════════════════
#  TAB SWITCH
# ════════════════════════════════════════════════════════════════
func _switch_tab(tab: String) -> void:
	_current_tab   = tab
	_selected_item = {}
	if _tab_title:
		_tab_title.text = TAB_LABELS.get(tab, tab)
	for i in _tab_btns.size():
		_style_sidebar_btn(_tab_btns[i], TABS[i] == tab)
	for child in _item_grid.get_children():
		child.queue_free()
	for item in ITEMS[tab]:
		_item_grid.add_child(_make_item_card(item))

# ── Item card ─────────────────────────────────────────────────────
func _make_item_card(item: Dictionary) -> Control:
	var remaining: int   = _stock.get(item["id"], item["stock"])
	var sold_out: bool   = item["stock"] > 0 and remaining <= 0
	var rarity: int      = int(item.get("rarity", 3))
	var r_col: Color     = _rarity_color(rarity)
	var cur: String      = str(item.get("currency", "gold"))
	var cost_val: int    = int(item["cost"])
	var affordable: bool = cost_val == 0 or _check_afford(cur, cost_val)

	var card := Panel.new()
	card.custom_minimum_size = Vector2(172, 210)
	var bg_col := Color(0.06, 0.09, 0.20, 0.9) if not sold_out else Color(0.04, 0.05, 0.10, 0.9)
	card.add_theme_stylebox_override("panel",
		_flat(bg_col, r_col if not sold_out else Color(0.3,0.3,0.4,0.25), 8, 1))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_item_click.bind(item, card))

	# Rarity bar top
	var rbar := ColorRect.new()
	rbar.color  = Color(r_col.r, r_col.g, r_col.b, 0.55 if not sold_out else 0.15)
	rbar.size   = Vector2(172, 4)
	rbar.position = Vector2(0, 0)
	rbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rbar)

	# Icon area
	var icon_bg := ColorRect.new()
	icon_bg.color  = Color(r_col.r, r_col.g, r_col.b, 0.06 if not sold_out else 0.02)
	icon_bg.size   = Vector2(172, 118)
	icon_bg.position = Vector2(0, 4)
	icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_bg)

	var icon_lbl := Label.new()
	icon_lbl.text = item["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 48)
	icon_lbl.add_theme_color_override("font_color",
		Color(r_col.r, r_col.g, r_col.b, 0.30 if sold_out else 1.0))
	icon_lbl.size     = Vector2(172, 118)
	icon_lbl.position = Vector2(0, 4)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_lbl)

	# Stars
	var stars := ""
	for _i in rarity:
		stars += "★"
	var star_lbl := Label.new()
	star_lbl.text = stars
	star_lbl.add_theme_font_size_override("font_size", 9)
	star_lbl.add_theme_color_override("font_color",
		Color(r_col.r, r_col.g, r_col.b, 0.8 if not sold_out else 0.3))
	star_lbl.size     = Vector2(172, 16)
	star_lbl.position = Vector2(0, 120)
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(star_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", C_GREY if sold_out else C_TEXT)
	name_lbl.size     = Vector2(156, 38)
	name_lbl.position = Vector2(8, 138)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# Cost / sold out
	var cost_lbl := Label.new()
	if sold_out:
		cost_lbl.text = "SOLD OUT"
		cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 0.8))
	elif cost_val == 0:
		cost_lbl.text = "ฟรี"
		cost_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
	else:
		cost_lbl.text = "%s %d" % [_cur_icon(cur), cost_val]
		cost_lbl.add_theme_color_override("font_color",
			C_GOLD if affordable else Color(1.0, 0.4, 0.4))
	cost_lbl.add_theme_font_size_override("font_size", 11)
	cost_lbl.size     = Vector2(172, 22)
	cost_lbl.position = Vector2(0, 182)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(cost_lbl)

	# Sold-out dim
	if sold_out:
		var dim2 := ColorRect.new()
		dim2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim2.color = Color(0, 0, 0, 0.38)
		dim2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(dim2)

	return card

func _on_item_click(ev: InputEvent, item: Dictionary, card: Control) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var remaining: int = _stock.get(item["id"], item["stock"])
		var sold_out: bool = item["stock"] > 0 and remaining <= 0
		if sold_out:
			return
		_selected_item = item
		_fx_scale(card)
		_open_confirm()

# ════════════════════════════════════════════════════════════════
#  CONFIRM OVERLAY
# ════════════════════════════════════════════════════════════════
func _build_confirm_overlay() -> void:
	_confirm_ov = Control.new()
	_confirm_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_ov.visible = false
	_confirm_ov.z_index = 50
	add_child(_confirm_ov)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_ov.add_child(dim)

	var box := Panel.new()
	box.size     = Vector2(380, 220)
	box.position = Vector2((SCREEN_W - 380) * 0.5, (SCREEN_H - 220) * 0.5)
	box.add_theme_stylebox_override("panel",
		_flat(Color(0.07, 0.10, 0.20, 0.98), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.6), 10, 1))
	_confirm_ov.add_child(box)

	var title := Label.new()
	title.text = "ยืนยันการซื้อ"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", C_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24; title.offset_bottom = 54
	box.add_child(title)

	var item_lbl := Label.new()
	item_lbl.name = "ItemLabel"
	item_lbl.add_theme_font_size_override("font_size", 14)
	item_lbl.add_theme_color_override("font_color", C_SUB)
	item_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	item_lbl.offset_top = 60; item_lbl.offset_bottom = 84
	box.add_child(item_lbl)

	var cost_lbl := Label.new()
	cost_lbl.name = "CostLabel"
	cost_lbl.add_theme_font_size_override("font_size", 20)
	cost_lbl.add_theme_color_override("font_color", C_GOLD)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	cost_lbl.offset_top = 90; cost_lbl.offset_bottom = 120
	box.add_child(cost_lbl)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -58; row.offset_bottom = -14
	row.offset_left = 24; row.offset_right = -24
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var cancel := Button.new()
	cancel.text = "ยกเลิก"
	cancel.custom_minimum_size = Vector2(140, 38)
	cancel.add_theme_font_size_override("font_size", 13)
	cancel.add_theme_color_override("font_color", C_SUB)
	cancel.add_theme_stylebox_override("normal",  _flat(Color(0.1,0.12,0.22,1), Color(C_BORDER), 6, 1))
	cancel.add_theme_stylebox_override("hover",   _flat(Color(0.14,0.17,0.30,1), Color(C_BORDER), 6, 1))
	cancel.add_theme_stylebox_override("pressed", _flat(Color(0.08,0.10,0.18,1), Color(C_BORDER), 6, 1))
	cancel.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	cancel.pressed.connect(func(): _confirm_ov.visible = false)
	row.add_child(cancel)

	var confirm := Button.new()
	confirm.name = "ConfirmBtn"
	confirm.text = "ซื้อเลย"
	confirm.custom_minimum_size = Vector2(140, 38)
	confirm.add_theme_font_size_override("font_size", 13)
	confirm.add_theme_color_override("font_color", C_BG)
	confirm.add_theme_stylebox_override("normal",  _flat(C_ACTIVE, Color(0,0,0,0), 6))
	confirm.add_theme_stylebox_override("hover",   _flat(Color(0.35,0.75,1.0,1), Color(0,0,0,0), 6))
	confirm.add_theme_stylebox_override("pressed", _flat(Color(0.18,0.55,0.9,1), Color(0,0,0,0), 6))
	confirm.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	confirm.pressed.connect(_execute_purchase)
	row.add_child(confirm)

func _open_confirm() -> void:
	if _selected_item.is_empty():
		return
	var item := _selected_item
	var box: Panel = _confirm_ov.get_child(1) as Panel
	box.get_node("ItemLabel").text = item["name"]
	var c_key: String = str(item.get("currency", "gold"))
	var c_amt: int    = int(item["cost"])
	if c_amt == 0:
		box.get_node("CostLabel").text = "ฟรี"
	else:
		box.get_node("CostLabel").text = "%s  %d" % [_cur_icon(c_key), c_amt]
	_confirm_ov.visible = true

func _execute_purchase() -> void:
	_confirm_ov.visible = false
	var item := _selected_item
	if item.is_empty():
		return
	if int(item["cost"]) > 0:
		var cur_key: String = str(item.get("currency", "gold"))
		var amt: int = int(item["cost"])
		if cur_key == "gems":
			CurrencyManager.spend_gems(amt)
		else:
			CurrencyManager.spend_gold(amt)
	if int(item["stock"]) > 0:
		_stock[item["id"]] = int(_stock.get(item["id"], item["stock"])) - 1
	DomainManager.add_points("shop")
	_rebuild_wallet()
	_switch_tab(_current_tab)
	_selected_item = {}

# ════════════════════════════════════════════════════════════════
#  HELPERS
# ════════════════════════════════════════════════════════════════
func _check_afford(cur: String, amount: int) -> bool:
	if cur == "gems":
		return CurrencyManager.total_crystal() >= amount
	return CurrencyManager.gold >= amount

func _cur_icon(cur: String) -> String:
	return "💠" if cur == "gems" else "💰"

func _rarity_color(rarity: int) -> Color:
	match rarity:
		5: return C_R5
		4: return C_R4
		3: return C_R3
		_: return C_R2

func _style_sidebar_btn(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_color_override("font_color", C_TEXT)
		btn.add_theme_stylebox_override("normal",
			_flat(Color(0.10, 0.16, 0.32, 1.0), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.7), 0, 0, 0, 0, 0, 3))
		btn.add_theme_stylebox_override("hover",
			_flat(Color(0.10, 0.16, 0.32, 1.0), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.7), 0, 0, 0, 0, 0, 3))
		btn.add_theme_stylebox_override("pressed",
			_flat(Color(0.08, 0.12, 0.26, 1.0), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.7), 0, 0, 0, 0, 0, 3))
	else:
		btn.add_theme_color_override("font_color", C_SUB)
		btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
		btn.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.04), Color(0,0,0,0)))
		btn.add_theme_stylebox_override("pressed", _flat(Color(1,1,1,0.02), Color(0,0,0,0)))

func _flat(bg: Color, border: Color, radius: int = 0,
		bw: int = 1, bw_top: int = 0, bw_bottom: int = 0,
		bw_left: int = 0, bw_right: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = bg
	sb.border_color = border
	sb.set_border_width(SIDE_LEFT,   bw)
	sb.set_border_width(SIDE_TOP,    bw)
	sb.set_border_width(SIDE_RIGHT,  bw)
	sb.set_border_width(SIDE_BOTTOM, bw)
	if bw_top    > 0: sb.set_border_width(SIDE_TOP,    bw_top)
	if bw_bottom > 0: sb.set_border_width(SIDE_BOTTOM, bw_bottom)
	if bw_left   > 0: sb.set_border_width(SIDE_LEFT,   bw_left)
	if bw_right  > 0: sb.set_border_width(SIDE_RIGHT,  bw_right)
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
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(SC_MAIN)
