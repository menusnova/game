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
		{"id": "s1", "name": "Originite Prime",   "icon": "◈", "rarity": 5,
		 "desc": "Premium currency. Used for Headhunting.", "cost": 0,   "currency": "💎", "stock": -1},
		{"id": "s2", "name": "LMD ×10,000",       "icon": "◎", "rarity": 3,
		 "desc": "Lungmen Dollars. Used for Operator promotion and crafting.", "cost": 200, "currency": "🧪", "stock": -1},
		{"id": "s3", "name": "EXP Card (Small)",   "icon": "▲", "rarity": 2,
		 "desc": "Grants 1,000 EXP to an Operator.", "cost": 80,  "currency": "🧪", "stock": -1},
		{"id": "s4", "name": "EXP Card (Medium)",  "icon": "▲", "rarity": 3,
		 "desc": "Grants 5,000 EXP to an Operator.", "cost": 360, "currency": "🧪", "stock": -1},
		{"id": "s5", "name": "Skill Upgrade I",    "icon": "✦", "rarity": 3,
		 "desc": "Material for upgrading Operator skills to rank 2–4.", "cost": 50,  "currency": "🧪", "stock": -1},
		{"id": "s6", "name": "Skill Upgrade II",   "icon": "✦", "rarity": 4,
		 "desc": "Material for upgrading Operator skills to rank 5–7.", "cost": 150, "currency": "🧪", "stock": -1},
		{"id": "s7", "name": "Compound Catalyst",  "icon": "⬡", "rarity": 5,
		 "desc": "Advanced synthesis material. Required for elite promotion.", "cost": 600, "currency": "🧪", "stock": -1},
		{"id": "s8", "name": "Headhunting Permit", "icon": "⊛", "rarity": 5,
		 "desc": "Can be exchanged for 1 Headhunting pull.", "cost": 600, "currency": "⭐", "stock": 5},
	],
	"OPERATOR": [
		{"id": "o1", "name": "Lyra",  "icon": "★", "rarity": 5,
		 "desc": "5★ Sniper — Marksman.\nHigh single-target DPS with extended range.", "cost": 3000, "currency": "⭐", "stock": 1},
		{"id": "o2", "name": "Kael",  "icon": "★", "rarity": 4,
		 "desc": "4★ Defender — Guardian.\nSturdy frontline with area taunt ability.", "cost": 1200, "currency": "⭐", "stock": 1},
		{"id": "o3", "name": "Mira",  "icon": "★", "rarity": 4,
		 "desc": "4★ Medic — Therapist.\nAOE healing for deployed units.", "cost": 1200, "currency": "⭐", "stock": 1},
		{"id": "o4", "name": "Voss",  "icon": "★", "rarity": 4,
		 "desc": "4★ Caster — Core.\nMagic damage dealer, low cost deployment.", "cost": 1200, "currency": "⭐", "stock": 1},
	],
	"EVENT": [
		{"id": "e1", "name": "Event Token ×5",   "icon": "◆", "rarity": 3,
		 "desc": "Exchange tokens from the current limited event.", "cost": 0,   "currency": "🎫", "stock": -1},
		{"id": "e2", "name": "Seraph (Limited)",  "icon": "★", "rarity": 5,
		 "desc": "5★ Limited Operator.\nOnly available during this event.", "cost": 600, "currency": "🎫", "stock": 1},
		{"id": "e3", "name": "Outfit: Eclipse",   "icon": "◈", "rarity": 4,
		 "desc": "Alternative outfit for Lyra.\nCosmetic only.", "cost": 300, "currency": "🎫", "stock": 1},
		{"id": "e4", "name": "Compound Catalyst", "icon": "⬡", "rarity": 4,
		 "desc": "Advanced synthesis material.", "cost": 120, "currency": "🎫", "stock": 3},
		{"id": "e5", "name": "LMD ×30,000",      "icon": "◎", "rarity": 3,
		 "desc": "Lungmen Dollars.", "cost": 180, "currency": "🎫", "stock": 2},
	],
}

# ── Currency ──────────────────────────────────────────────────────
var _wallet := {"💎": 90, "🧪": 2400, "⭐": 3600, "🎫": 0}
var _stock   := {}

var _current_tab    := "SUPPLIES"
var _selected_item: Dictionary = {}

# ── Layout constants ──────────────────────────────────────────────
const SIDEBAR_W  := 180
const TOPBAR_H   := 56
const DETAIL_W   := 400
const SCREEN_W   := 1152
const SCREEN_H   := 648

# Grid area: x = SIDEBAR_W  →  SCREEN_W - DETAIL_W
# = 180 → 752  (572px)
const GRID_X := SIDEBAR_W
const GRID_W := SCREEN_W - SIDEBAR_W - DETAIL_W   # 572

# ── Rarity colors ─────────────────────────────────────────────────
const C_R5 := Color(1.00, 0.80, 0.20, 1.0)   # gold
const C_R4 := Color(0.72, 0.50, 1.00, 1.0)   # purple
const C_R3 := Color(0.35, 0.65, 1.00, 1.0)   # blue
const C_R2 := Color(0.45, 0.80, 0.55, 1.0)   # green

# ── Base colors ───────────────────────────────────────────────────
const C_BG      := Color(0.04, 0.05, 0.10, 1.0)
const C_SIDEBAR := Color(0.025, 0.035, 0.08, 1.0)
const C_PANEL   := Color(0.055, 0.075, 0.16, 1.0)
const C_BORDER  := Color(0.18, 0.52, 0.9,  0.3)
const C_ACTIVE  := Color(0.25, 0.65, 1.0,  1.0)
const C_TEXT    := Color(0.88, 0.92, 1.00, 1.0)
const C_SUB     := Color(0.55, 0.70, 0.90, 0.8)
const C_GOLD    := Color(1.00, 0.82, 0.25, 1.0)
const C_GREY    := Color(0.40, 0.48, 0.60, 0.7)

# ── Node refs ─────────────────────────────────────────────────────
var _tab_btns:   Array[Button]  = []
var _item_grid:  GridContainer
var _detail_box: Control
var _buy_btn:    Button
var _wallet_row: HBoxContainer
var _confirm_ov: Control
var _tab_title:  Label

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
	# root bg
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_sidebar()
	_build_topbar()
	_build_grid_area()
	_build_detail_panel()
	_build_confirm_overlay()

	_switch_tab("SUPPLIES")

# ── Sidebar ──────────────────────────────────────────────────────
func _build_sidebar() -> void:
	var sb := Panel.new()
	sb.position = Vector2(0, 0)
	sb.size     = Vector2(SIDEBAR_W, SCREEN_H)
	sb.add_theme_stylebox_override("panel", _flat(C_SIDEBAR, C_BORDER, 0, 0, 0, 0, 1, 0))
	add_child(sb)

	# Logo / title
	var logo := Label.new()
	logo.text = "SHOP"
	logo.add_theme_font_size_override("font_size", 22)
	logo.add_theme_color_override("font_color", C_TEXT)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.size = Vector2(SIDEBAR_W, 52)
	logo.position = Vector2(0, 12)
	logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sb.add_child(logo)

	# Thin divider under logo
	var sep := ColorRect.new()
	sep.color    = Color(C_BORDER)
	sep.size     = Vector2(SIDEBAR_W - 24, 1)
	sep.position = Vector2(12, 60)
	sb.add_child(sep)

	# Tab buttons
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

	# Back button at bottom
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

	# Wallet
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
	mc.add_theme_constant_override("margin_left",   12)
	mc.add_theme_constant_override("margin_right",  12)
	mc.add_theme_constant_override("margin_top",    16)
	mc.add_theme_constant_override("margin_bottom", 16)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_item_grid = GridContainer.new()
	_item_grid.columns = 3
	_item_grid.add_theme_constant_override("h_separation", 10)
	_item_grid.add_theme_constant_override("v_separation", 10)
	_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.add_child(_item_grid)
	scroll.add_child(mc)

	# Right border of grid area
	var div := ColorRect.new()
	div.position = Vector2(GRID_X + GRID_W, TOPBAR_H)
	div.size     = Vector2(1, SCREEN_H - TOPBAR_H)
	div.color    = Color(C_BORDER)
	add_child(div)

# ── Detail panel ──────────────────────────────────────────────────
func _build_detail_panel() -> void:
	_detail_box = Panel.new()
	_detail_box.position = Vector2(GRID_X + GRID_W + 1, TOPBAR_H)
	_detail_box.size     = Vector2(DETAIL_W - 1, SCREEN_H - TOPBAR_H)
	_detail_box.add_theme_stylebox_override("panel", _flat(C_PANEL, Color(0,0,0,0)))
	add_child(_detail_box)
	_build_detail_empty()

# ── Confirm overlay ───────────────────────────────────────────────
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
	box.add_theme_stylebox_override("panel", _flat(Color(0.07, 0.10, 0.20, 0.98), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.6), 10, 1))
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

func _rebuild_wallet() -> void:
	for c in _wallet_row.get_children():
		c.queue_free()
	for cur in ["💎", "🧪", "⭐", "🎫"]:
		var pill := Panel.new()
		pill.custom_minimum_size = Vector2(86, 30)
		pill.add_theme_stylebox_override("panel", _flat(Color(0.06, 0.10, 0.22, 0.9), Color(C_BORDER), 6))
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 8; row.offset_right = -8
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var ico := Label.new()
		ico.text = cur
		ico.add_theme_font_size_override("font_size", 13)
		row.add_child(ico)
		var amt := Label.new()
		amt.text = " %d" % _wallet[cur]
		amt.add_theme_font_size_override("font_size", 12)
		amt.add_theme_color_override("font_color", C_TEXT)
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
	_current_tab  = tab
	_selected_item = {}
	_build_detail_empty()

	if _tab_title:
		_tab_title.text = TAB_LABELS.get(tab, tab)

	for i in _tab_btns.size():
		_style_sidebar_btn(_tab_btns[i], TABS[i] == tab)

	for child in _item_grid.get_children():
		child.queue_free()

	for item in ITEMS[tab]:
		_item_grid.add_child(_make_item_card(item))

# ── Item card (portrait style) ────────────────────────────────────
func _make_item_card(item: Dictionary) -> Control:
	var remaining: int = _stock.get(item["id"], item["stock"])
	var sold_out: bool = item["stock"] > 0 and remaining <= 0
	var rarity: int    = int(item.get("rarity", 3))
	var r_col: Color   = _rarity_color(rarity)

	var card := Panel.new()
	# portrait: fit 3 in GRID_W - margins*2 - separations
	# GRID_W=572, margin=12*2=24, sep=10*2=20 → avail=528 → per card=176
	card.custom_minimum_size = Vector2(162, 200)
	var bg_col := Color(0.06, 0.09, 0.20, 0.9) if not sold_out else Color(0.04, 0.05, 0.10, 0.9)
	card.add_theme_stylebox_override("panel", _flat(bg_col, r_col if not sold_out else Color(0.3,0.3,0.4,0.25), 8, 1))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_item_click.bind(item, card))

	# rarity bar at top
	var rbar := ColorRect.new()
	rbar.color    = Color(r_col.r, r_col.g, r_col.b, 0.55 if not sold_out else 0.15)
	rbar.size     = Vector2(162, 4)
	rbar.position = Vector2(0, 0)
	rbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rbar)

	# icon area (top half)
	var icon_bg := ColorRect.new()
	icon_bg.color  = Color(r_col.r, r_col.g, r_col.b, 0.06 if not sold_out else 0.02)
	icon_bg.size   = Vector2(162, 110)
	icon_bg.position = Vector2(0, 4)
	icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_bg)

	var icon_lbl := Label.new()
	icon_lbl.text = item["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 44)
	icon_lbl.add_theme_color_override("font_color",
		Color(r_col.r, r_col.g, r_col.b, 0.35 if sold_out else 1.0))
	icon_lbl.size = Vector2(162, 110)
	icon_lbl.position = Vector2(0, 4)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_lbl)

	# rarity stars
	var stars := ""
	for _i in rarity:
		stars += "★"
	var star_lbl := Label.new()
	star_lbl.text = stars
	star_lbl.add_theme_font_size_override("font_size", 9)
	star_lbl.add_theme_color_override("font_color", Color(r_col.r, r_col.g, r_col.b, 0.8 if not sold_out else 0.3))
	star_lbl.size     = Vector2(162, 16)
	star_lbl.position = Vector2(0, 112)
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(star_lbl)

	# item name
	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", C_GREY if sold_out else C_TEXT)
	name_lbl.size     = Vector2(150, 36)
	name_lbl.position = Vector2(6, 130)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# cost / free / sold out
	var cost_lbl := Label.new()
	if sold_out:
		cost_lbl.text = "SOLD OUT"
		cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 0.8))
	elif item["cost"] == 0:
		cost_lbl.text = "FREE"
		cost_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
	else:
		cost_lbl.text = "%s %d" % [item["currency"], item["cost"]]
		cost_lbl.add_theme_color_override("font_color", C_GOLD)
	cost_lbl.add_theme_font_size_override("font_size", 11)
	cost_lbl.size     = Vector2(162, 22)
	cost_lbl.position = Vector2(0, 172)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(cost_lbl)

	# sold-out dim overlay
	if sold_out:
		var dim2 := ColorRect.new()
		dim2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim2.color = Color(0, 0, 0, 0.38)
		dim2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(dim2)

	return card

func _on_item_click(ev: InputEvent, item: Dictionary, card: Control) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_selected_item = item
		_build_detail(item)
		_fx_scale(card)

# ════════════════════════════════════════════════════════════════
#  DETAIL PANEL
# ════════════════════════════════════════════════════════════════
func _build_detail_empty() -> void:
	for c in _detail_box.get_children():
		c.queue_free()
	var hint := Label.new()
	hint.text = "เลือกไอเทม"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(C_SUB.r, C_SUB.g, C_SUB.b, 0.35))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_box.add_child(hint)

func _build_detail(item: Dictionary) -> void:
	for c in _detail_box.get_children():
		c.queue_free()

	var remaining: int  = _stock.get(item["id"], item["stock"])
	var sold_out: bool  = item["stock"] > 0 and remaining <= 0
	var can_afford: bool = item["cost"] == 0 or _wallet.get(item["currency"], 0) >= item["cost"]
	var rarity: int     = int(item.get("rarity", 3))
	var r_col: Color    = _rarity_color(rarity)

	# Rarity accent bar at top
	var rbar := ColorRect.new()
	rbar.color    = Color(r_col.r, r_col.g, r_col.b, 0.6)
	rbar.size     = Vector2(DETAIL_W - 1, 3)
	rbar.position = Vector2(0, 0)
	_detail_box.add_child(rbar)

	# Icon display area
	var icon_bg := ColorRect.new()
	icon_bg.color    = Color(r_col.r, r_col.g, r_col.b, 0.06)
	icon_bg.size     = Vector2(DETAIL_W - 1, 160)
	icon_bg.position = Vector2(0, 3)
	_detail_box.add_child(icon_bg)

	var icon_lbl := Label.new()
	icon_lbl.text = item["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 72)
	icon_lbl.add_theme_color_override("font_color", r_col)
	icon_lbl.size     = Vector2(DETAIL_W - 1, 160)
	icon_lbl.position = Vector2(0, 3)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_detail_box.add_child(icon_lbl)

	# Stars
	var stars := ""
	for _i in rarity:
		stars += "★"
	var star_lbl := Label.new()
	star_lbl.text = stars
	star_lbl.add_theme_font_size_override("font_size", 13)
	star_lbl.add_theme_color_override("font_color", Color(r_col.r, r_col.g, r_col.b, 0.9))
	star_lbl.size     = Vector2(DETAIL_W - 1, 22)
	star_lbl.position = Vector2(0, 166)
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_box.add_child(star_lbl)

	# Item name
	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_lbl.offset_top = 192; name_lbl.offset_bottom = 222
	_detail_box.add_child(name_lbl)

	# Divider
	var div := ColorRect.new()
	div.color = Color(r_col.r, r_col.g, r_col.b, 0.2)
	div.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	div.offset_top = 228; div.offset_bottom = 229
	div.offset_left = 28; div.offset_right = -28
	_detail_box.add_child(div)

	# Description
	var desc := Label.new()
	desc.text = item["desc"]
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", C_SUB)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	desc.offset_top = 238; desc.offset_bottom = 340
	desc.offset_left = 28; desc.offset_right = -28
	_detail_box.add_child(desc)

	# Stock info
	if item["stock"] > 0:
		var slbl := Label.new()
		slbl.text = "SOLD OUT" if sold_out else "คงเหลือ: %d / %d" % [remaining, item["stock"]]
		slbl.add_theme_font_size_override("font_size", 12)
		slbl.add_theme_color_override("font_color",
			Color(1.0, 0.4, 0.4) if sold_out else Color(0.55, 0.85, 1.0))
		slbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		slbl.offset_top = 344; slbl.offset_bottom = 366
		_detail_box.add_child(slbl)

	# Cost
	var cost_lbl := Label.new()
	if item["cost"] == 0:
		cost_lbl.text = "FREE"
		cost_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	else:
		cost_lbl.text = "%s  %d" % [item["currency"], item["cost"]]
		cost_lbl.add_theme_color_override("font_color", C_GOLD if can_afford else Color(1.0, 0.4, 0.4))
	cost_lbl.add_theme_font_size_override("font_size", 22)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cost_lbl.offset_top = -110; cost_lbl.offset_bottom = -68
	_detail_box.add_child(cost_lbl)

	if item["cost"] > 0 and not can_afford:
		var warn := Label.new()
		warn.text = "เงินไม่พอ"
		warn.add_theme_font_size_override("font_size", 11)
		warn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 0.85))
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		warn.offset_top = -66; warn.offset_bottom = -48
		_detail_box.add_child(warn)

	# Buy button
	_buy_btn = Button.new()
	_buy_btn.text = "SOLD OUT" if sold_out else ("รับฟรี" if item["cost"] == 0 else "ซื้อ")
	_buy_btn.disabled = sold_out or (item["cost"] > 0 and not can_afford)
	_buy_btn.custom_minimum_size = Vector2(240, 48)
	_buy_btn.add_theme_font_size_override("font_size", 15)
	var btn_col: Color = C_ACTIVE if (not sold_out and can_afford) else C_GREY
	_buy_btn.add_theme_color_override("font_color", C_BG if (not sold_out and can_afford) else C_GREY)
	_buy_btn.add_theme_stylebox_override("normal",   _flat(btn_col if not sold_out else Color(0.12,0.14,0.24,1), Color(0,0,0,0), 8))
	_buy_btn.add_theme_stylebox_override("hover",    _flat(Color(0.35,0.75,1.0,1), Color(0,0,0,0), 8))
	_buy_btn.add_theme_stylebox_override("pressed",  _flat(Color(0.18,0.55,0.9,1), Color(0,0,0,0), 8))
	_buy_btn.add_theme_stylebox_override("disabled", _flat(Color(0.12,0.14,0.24,1), Color(C_GREY.r,C_GREY.g,C_GREY.b,0.3), 8, 1))
	_buy_btn.add_theme_stylebox_override("focus",    _flat(Color(0,0,0,0), Color(0,0,0,0)))
	_buy_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_buy_btn.offset_top = -56; _buy_btn.offset_bottom = -8
	_buy_btn.offset_left = 48; _buy_btn.offset_right = -48
	_buy_btn.pressed.connect(_open_confirm)
	_detail_box.add_child(_buy_btn)

# ════════════════════════════════════════════════════════════════
#  PURCHASE FLOW
# ════════════════════════════════════════════════════════════════
func _open_confirm() -> void:
	if _selected_item.is_empty():
		return
	var item := _selected_item
	var box: Panel = _confirm_ov.get_child(1)
	box.get_node("ItemLabel").text = item["name"]
	if item["cost"] == 0:
		box.get_node("CostLabel").text = "FREE"
	else:
		box.get_node("CostLabel").text = "%s  %d" % [item["currency"], item["cost"]]
	_confirm_ov.visible = true

func _execute_purchase() -> void:
	_confirm_ov.visible = false
	var item := _selected_item
	if item.is_empty():
		return
	if item["cost"] > 0:
		_wallet[item["currency"]] -= item["cost"]
	if item["stock"] > 0:
		_stock[item["id"]] = _stock.get(item["id"], item["stock"]) - 1
	DomainManager.add_points("shop")
	_rebuild_wallet()
	_switch_tab(_current_tab)
	_build_detail_empty()
	_selected_item = {}

# ════════════════════════════════════════════════════════════════
#  HELPERS
# ════════════════════════════════════════════════════════════════
func _rarity_color(rarity: int) -> Color:
	match rarity:
		5: return C_R5
		4: return C_R4
		3: return C_R3
		_: return C_R2

func _style_sidebar_btn(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_color_override("font_color", C_TEXT)
		btn.add_theme_stylebox_override("normal",  _flat(Color(0.10, 0.16, 0.32, 1.0), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.7), 0, 0, 0, 0, 0, 3))
		btn.add_theme_stylebox_override("hover",   _flat(Color(0.10, 0.16, 0.32, 1.0), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.7), 0, 0, 0, 0, 0, 3))
		btn.add_theme_stylebox_override("pressed", _flat(Color(0.08, 0.12, 0.26, 1.0), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.7), 0, 0, 0, 0, 0, 3))
	else:
		btn.add_theme_color_override("font_color", C_SUB)
		btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
		btn.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.04), Color(0,0,0,0)))
		btn.add_theme_stylebox_override("pressed", _flat(Color(1,1,1,0.02), Color(0,0,0,0)))

# _flat: border sides = all bw, then individual overrides for top/bottom/left/right
func _flat(bg: Color, border: Color, radius: int = 0,
		bw: int = 1, bw_top: int = 0, bw_bottom: int = 0,
		bw_left: int = 0, bw_right: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color    = bg
	sb.border_color = border
	for side in [0,1,2,3]:
		sb.set_border_width(side, bw)
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
