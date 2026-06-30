extends Control

const SC_MAIN := "res://main_menu.tscn"

# ── Shop Data ─────────────────────────────────────────────────────
const TABS := ["SUPPLIES", "OPERATOR", "EVENT"]

const ITEMS := {
	"SUPPLIES": [
		{"id": "s1",  "name": "Originite Prime",   "icon": "◈", "desc": "Premium currency. Used for Headhunting.", "cost": 0,   "currency": "💎", "stock": -1},
		{"id": "s2",  "name": "LMD ×10,000",       "icon": "◎", "desc": "Lungmen Dollars. Used for Operator promotion and crafting.", "cost": 200, "currency": "🧪", "stock": -1},
		{"id": "s3",  "name": "EXP Card (Small)",   "icon": "▲", "desc": "Grants 1,000 EXP to an Operator.", "cost": 80,  "currency": "🧪", "stock": -1},
		{"id": "s4",  "name": "EXP Card (Medium)",  "icon": "▲", "desc": "Grants 5,000 EXP to an Operator.", "cost": 360, "currency": "🧪", "stock": -1},
		{"id": "s5",  "name": "Skill Upgrade I",    "icon": "✦", "desc": "Material for upgrading Operator skills to rank 2–4.", "cost": 50,  "currency": "🧪", "stock": -1},
		{"id": "s6",  "name": "Skill Upgrade II",   "icon": "✦", "desc": "Material for upgrading Operator skills to rank 5–7.", "cost": 150, "currency": "🧪", "stock": -1},
		{"id": "s7",  "name": "Compound Catalyst",  "icon": "⬡", "desc": "Advanced synthesis material. Required for elite promotion.", "cost": 600, "currency": "🧪", "stock": -1},
		{"id": "s8",  "name": "Headhunting Permit", "icon": "⊛", "desc": "Can be exchanged for 1 Headhunting pull.", "cost": 600, "currency": "⭐", "stock": 5},
	],
	"OPERATOR": [
		{"id": "o1",  "name": "Lyra",    "icon": "★", "desc": "5★ Sniper — Marksman. High single-target DPS with extended range.", "cost": 3000, "currency": "⭐", "stock": 1},
		{"id": "o2",  "name": "Kael",    "icon": "★", "desc": "4★ Defender — Guardian. Sturdy frontline with area taunt ability.", "cost": 1200, "currency": "⭐", "stock": 1},
		{"id": "o3",  "name": "Mira",    "icon": "★", "desc": "4★ Medic — Therapist. AOE healing for deployed units.", "cost": 1200, "currency": "⭐", "stock": 1},
		{"id": "o4",  "name": "Voss",    "icon": "★", "desc": "4★ Caster — Core. Magic damage dealer, low cost deployment.", "cost": 1200, "currency": "⭐", "stock": 1},
	],
	"EVENT": [
		{"id": "e1",  "name": "Event Token ×5",    "icon": "◆", "desc": "Exchange tokens from the current limited event.", "cost": 0,   "currency": "🎫", "stock": -1},
		{"id": "e2",  "name": "Seraph (Limited)",   "icon": "★", "desc": "5★ Limited Operator — Only available during this event.", "cost": 600, "currency": "🎫", "stock": 1},
		{"id": "e3",  "name": "Outfit: Eclipse",    "icon": "◈", "desc": "Alternative outfit for Lyra. Cosmetic only.", "cost": 300, "currency": "🎫", "stock": 1},
		{"id": "e4",  "name": "Compound Catalyst",  "icon": "⬡", "desc": "Advanced synthesis material.", "cost": 120, "currency": "🎫", "stock": 3},
		{"id": "e5",  "name": "LMD ×30,000",       "icon": "◎", "desc": "Lungmen Dollars.", "cost": 180, "currency": "🎫", "stock": 2},
	],
}

# ── Currency ──────────────────────────────────────────────────────
var _wallet := {"💎": 90, "🧪": 2400, "⭐": 3600, "🎫": 0}
var _stock   := {}   # tracks remaining stock per item id

var _current_tab    := "SUPPLIES"
var _selected_item: Dictionary = {}

# ── Colors ────────────────────────────────────────────────────────
const C_BG      := Color(0.04, 0.05, 0.10, 1.0)
const C_PANEL   := Color(0.07, 0.09, 0.16, 1.0)
const C_BORDER  := Color(0.18, 0.52, 0.9,  0.35)
const C_ACTIVE  := Color(0.25, 0.65, 1.0,  1.0)
const C_TEXT    := Color(0.88, 0.92, 1.0,  1.0)
const C_SUB     := Color(0.55, 0.70, 0.90, 0.8)
const C_GOLD    := Color(1.00, 0.82, 0.25, 1.0)
const C_PURPLE  := Color(0.75, 0.55, 1.0,  1.0)
const C_GREY    := Color(0.40, 0.48, 0.60, 0.7)

# ── Nodes (built in _ready) ───────────────────────────────────────
var _tab_btns:   Array[Button]  = []
var _item_grid:  GridContainer
var _detail_box: Control
var _buy_btn:    Button
var _wallet_row: HBoxContainer
var _confirm_ov: Control  # confirm popup

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

	# header
	_build_header()

	# tab bar
	_build_tabs()

	# main area: left grid + right detail
	_build_main_area()

	# confirm overlay (hidden)
	_build_confirm_overlay()

	_switch_tab("SUPPLIES")

func _build_header() -> void:
	var hdr := Panel.new()
	hdr.size = Vector2(1152, 52)
	hdr.add_theme_stylebox_override("panel", _flat(Color(0.05, 0.07, 0.14, 1.0), Color(C_BORDER), 0, 1))
	add_child(hdr)

	var title := Label.new()
	title.text = "SHOP"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_TEXT)
	title.position = Vector2(24, 14)
	hdr.add_child(title)

	# wallet row
	_wallet_row = HBoxContainer.new()
	_wallet_row.position = Vector2(600, 12)
	_wallet_row.size = Vector2(500, 32)
	_wallet_row.alignment = BoxContainer.ALIGNMENT_END
	hdr.add_child(_wallet_row)
	_rebuild_wallet()

	# back button
	var back := Button.new()
	back.text = "← BACK"
	back.add_theme_font_size_override("font_size", 12)
	back.add_theme_color_override("font_color", C_SUB)
	back.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
	back.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.06), Color(0,0,0,0)))
	back.add_theme_stylebox_override("pressed", _flat(Color(1,1,1,0.03), Color(0,0,0,0)))
	back.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	back.size = Vector2(90, 32)
	back.position = Vector2(16, 10)
	back.pressed.connect(_go_back)
	hdr.add_child(back)

func _rebuild_wallet() -> void:
	for c in _wallet_row.get_children():
		c.queue_free()
	for cur in ["💎", "🧪", "⭐", "🎫"]:
		var pill := Panel.new()
		pill.custom_minimum_size = Vector2(90, 28)
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

func _build_tabs() -> void:
	var bar := Panel.new()
	bar.position = Vector2(0, 52)
	bar.size = Vector2(1152, 44)
	bar.add_theme_stylebox_override("panel", _flat(Color(0.055, 0.075, 0.15, 1.0), Color(C_BORDER), 0, 1))
	add_child(bar)

	var x := 24.0
	for tab in TABS:
		var btn := Button.new()
		btn.text = tab
		btn.custom_minimum_size = Vector2(130, 34)
		btn.position = Vector2(x, 5)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0)))
		_style_tab(btn, false)
		btn.pressed.connect(_switch_tab.bind(tab))
		bar.add_child(btn)
		_tab_btns.append(btn)
		x += 138

func _build_main_area() -> void:
	# left: scroll + grid
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 96)
	scroll.size = Vector2(700, 552)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_item_grid = GridContainer.new()
	_item_grid.columns = 3
	_item_grid.add_theme_constant_override("h_separation", 10)
	_item_grid.add_theme_constant_override("v_separation", 10)
	_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gpad := Control.new(); gpad.custom_minimum_size = Vector2(16, 12)
	# wrap grid in margin container
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   16)
	mc.add_theme_constant_override("margin_right",  16)
	mc.add_theme_constant_override("margin_top",    16)
	mc.add_theme_constant_override("margin_bottom", 16)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.add_child(_item_grid)
	scroll.add_child(mc)

	# right: detail panel
	var divider := ColorRect.new()
	divider.position = Vector2(700, 96)
	divider.size = Vector2(1, 552)
	divider.color = Color(C_BORDER)
	add_child(divider)

	_detail_box = Panel.new()
	_detail_box.position = Vector2(701, 96)
	_detail_box.size = Vector2(451, 552)
	_detail_box.add_theme_stylebox_override("panel", _flat(C_PANEL, Color(0,0,0,0)))
	add_child(_detail_box)
	_build_detail_empty()

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
	box.size = Vector2(380, 220)
	box.position = Vector2((1152 - 380) * 0.5, (648 - 220) * 0.5)
	box.add_theme_stylebox_override("panel", _flat(Color(0.07, 0.10, 0.20, 0.98), Color(C_ACTIVE), 10, 1))
	_confirm_ov.add_child(box)

	var title := Label.new()
	title.text = "CONFIRM PURCHASE"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", C_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24; title.offset_bottom = 48
	box.add_child(title)

	var item_lbl := Label.new()
	item_lbl.name = "ItemLabel"
	item_lbl.add_theme_font_size_override("font_size", 14)
	item_lbl.add_theme_color_override("font_color", C_SUB)
	item_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	item_lbl.offset_top = 60; item_lbl.offset_bottom = 85
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
	row.offset_top = -60; row.offset_bottom = -16
	row.offset_left = 24; row.offset_right = -24
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var cancel := Button.new()
	cancel.text = "CANCEL"
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
	confirm.text = "PURCHASE"
	confirm.custom_minimum_size = Vector2(140, 38)
	confirm.add_theme_font_size_override("font_size", 13)
	confirm.add_theme_color_override("font_color", C_BG)
	confirm.add_theme_stylebox_override("normal",  _flat(C_ACTIVE, Color(0,0,0,0), 6))
	confirm.add_theme_stylebox_override("hover",   _flat(Color(0.35, 0.75, 1.0, 1), Color(0,0,0,0), 6))
	confirm.add_theme_stylebox_override("pressed", _flat(Color(0.18, 0.55, 0.9, 1), Color(0,0,0,0), 6))
	confirm.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	confirm.pressed.connect(_execute_purchase)
	row.add_child(confirm)

# ════════════════════════════════════════════════════════════════
#  TAB + GRID
# ════════════════════════════════════════════════════════════════
func _switch_tab(tab: String) -> void:
	_current_tab = tab
	_selected_item = {}
	_build_detail_empty()

	for i in _tab_btns.size():
		_style_tab(_tab_btns[i], TABS[i] == tab)

	for child in _item_grid.get_children():
		child.queue_free()

	for item in ITEMS[tab]:
		_item_grid.add_child(_make_item_card(item))

func _make_item_card(item: Dictionary) -> Control:
	var remaining := _stock.get(item["id"], item["stock"])
	var sold_out  := item["stock"] > 0 and remaining <= 0

	var card := Panel.new()
	card.custom_minimum_size = Vector2(208, 90)
	var border_col := C_BORDER if not sold_out else Color(0.3, 0.3, 0.4, 0.3)
	card.add_theme_stylebox_override("panel", _flat(Color(0.06, 0.09, 0.18, 0.9), border_col, 6, 1))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_item_click.bind(item, card))

	# icon
	var icon := Label.new()
	icon.text = item["icon"]
	icon.add_theme_font_size_override("font_size", 28)
	icon.add_theme_color_override("font_color",
		C_GOLD if item.get("name","").begins_with("5") or item["icon"] == "★" else C_ACTIVE)
	icon.position = Vector2(12, 18)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)

	# name
	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", C_GREY if sold_out else C_TEXT)
	name_lbl.position = Vector2(52, 10)
	name_lbl.size = Vector2(148, 36)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# cost row
	var cost_lbl := Label.new()
	if item["cost"] == 0:
		cost_lbl.text = "FREE"
		cost_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	else:
		cost_lbl.text = "%s %d" % [item["currency"], item["cost"]]
		cost_lbl.add_theme_color_override("font_color", C_GOLD if not sold_out else C_GREY)
	cost_lbl.add_theme_font_size_override("font_size", 12)
	cost_lbl.position = Vector2(52, 58)
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(cost_lbl)

	# stock badge
	if item["stock"] > 0:
		var stock_lbl := Label.new()
		stock_lbl.text = "SOLD OUT" if sold_out else "×%d left" % remaining
		stock_lbl.add_theme_font_size_override("font_size", 9)
		stock_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.4, 0.4) if sold_out else Color(0.55, 0.85, 1.0))
		stock_lbl.position = Vector2(148, 62)
		stock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(stock_lbl)

	if sold_out:
		var dim2 := ColorRect.new()
		dim2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim2.color = Color(0, 0, 0, 0.45)
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
	hint.text = "SELECT AN ITEM"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(C_SUB.r, C_SUB.g, C_SUB.b, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_box.add_child(hint)

func _build_detail(item: Dictionary) -> void:
	for c in _detail_box.get_children():
		c.queue_free()

	var remaining := _stock.get(item["id"], item["stock"])
	var sold_out  := item["stock"] > 0 and remaining <= 0
	var can_afford := item["cost"] == 0 or _wallet.get(item["currency"], 0) >= item["cost"]

	# icon big
	var icon := Label.new()
	icon.text = item["icon"]
	icon.add_theme_font_size_override("font_size", 64)
	icon.add_theme_color_override("font_color", C_GOLD if item["icon"] == "★" else C_ACTIVE)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	icon.offset_top = 36; icon.offset_bottom = 110
	_detail_box.add_child(icon)

	# name
	var name_lbl := Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_lbl.offset_top = 118; name_lbl.offset_bottom = 148
	_detail_box.add_child(name_lbl)

	# divider
	var div := ColorRect.new()
	div.color = Color(C_BORDER)
	div.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	div.offset_top = 154; div.offset_bottom = 155
	div.offset_left = 32; div.offset_right = -32
	_detail_box.add_child(div)

	# desc
	var desc := Label.new()
	desc.text = item["desc"]
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", C_SUB)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	desc.offset_top = 166; desc.offset_bottom = 280
	desc.offset_left = 32; desc.offset_right = -32
	_detail_box.add_child(desc)

	# stock info
	if item["stock"] > 0:
		var slbl := Label.new()
		slbl.text = "SOLD OUT" if sold_out else "Stock: %d / %d" % [remaining, item["stock"]]
		slbl.add_theme_font_size_override("font_size", 12)
		slbl.add_theme_color_override("font_color",
			Color(1.0, 0.4, 0.4) if sold_out else Color(0.55, 0.85, 1.0))
		slbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		slbl.offset_top = 284; slbl.offset_bottom = 304
		_detail_box.add_child(slbl)

	# cost display
	var cost_row := Label.new()
	if item["cost"] == 0:
		cost_row.text = "FREE"
		cost_row.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	else:
		cost_row.text = "%s  %d" % [item["currency"], item["cost"]]
		cost_row.add_theme_color_override("font_color", C_GOLD if can_afford else Color(1.0, 0.4, 0.4))
	cost_row.add_theme_font_size_override("font_size", 22)
	cost_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cost_row.offset_top = -110; cost_row.offset_bottom = -70
	_detail_box.add_child(cost_row)

	# not enough label
	if item["cost"] > 0 and not can_afford:
		var warn := Label.new()
		warn.text = "Insufficient funds"
		warn.add_theme_font_size_override("font_size", 11)
		warn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 0.85))
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		warn.offset_top = -68; warn.offset_bottom = -50
		_detail_box.add_child(warn)

	# buy button
	_buy_btn = Button.new()
	_buy_btn.text = "SOLD OUT" if sold_out else ("GET" if item["cost"] == 0 else "PURCHASE")
	_buy_btn.disabled = sold_out or (item["cost"] > 0 and not can_afford)
	_buy_btn.custom_minimum_size = Vector2(220, 46)
	_buy_btn.add_theme_font_size_override("font_size", 15)
	var btn_col := C_ACTIVE if (not sold_out and can_afford) else C_GREY
	_buy_btn.add_theme_color_override("font_color", C_BG if (not sold_out and can_afford) else C_GREY)
	_buy_btn.add_theme_stylebox_override("normal",   _flat(btn_col if not sold_out else Color(0.12,0.14,0.24,1), Color(0,0,0,0), 8))
	_buy_btn.add_theme_stylebox_override("hover",    _flat(Color(0.35,0.75,1.0,1), Color(0,0,0,0), 8))
	_buy_btn.add_theme_stylebox_override("pressed",  _flat(Color(0.18,0.55,0.9,1), Color(0,0,0,0), 8))
	_buy_btn.add_theme_stylebox_override("disabled", _flat(Color(0.12,0.14,0.24,1), Color(C_GREY.r,C_GREY.g,C_GREY.b,0.3), 8, 1))
	_buy_btn.add_theme_stylebox_override("focus",    _flat(Color(0,0,0,0), Color(0,0,0,0)))
	_buy_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_buy_btn.offset_top = -58; _buy_btn.offset_bottom = -12
	_buy_btn.offset_left = 56; _buy_btn.offset_right = -56
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

	# deduct cost
	if item["cost"] > 0:
		_wallet[item["currency"]] -= item["cost"]

	# reduce stock
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
func _style_tab(btn: Button, active: bool) -> void:
	if active:
		btn.add_theme_color_override("font_color", C_ACTIVE)
		btn.add_theme_stylebox_override("normal",  _flat(Color(0.08, 0.13, 0.28, 1.0), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.6), 0, 0, 0, 2))
		btn.add_theme_stylebox_override("hover",   _flat(Color(0.08, 0.13, 0.28, 1.0), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.6), 0, 0, 0, 2))
		btn.add_theme_stylebox_override("pressed", _flat(Color(0.06, 0.10, 0.22, 1.0), Color(C_ACTIVE.r, C_ACTIVE.g, C_ACTIVE.b, 0.6), 0, 0, 0, 2))
	else:
		btn.add_theme_color_override("font_color", C_SUB)
		btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
		btn.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.05), Color(0,0,0,0)))
		btn.add_theme_stylebox_override("pressed", _flat(Color(1,1,1,0.02), Color(0,0,0,0)))

func _flat(bg: Color, border: Color, radius: int = 0,
		bw: int = 1, bw_top: int = 0, bw_bottom: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	for side in [0,1,2,3]:
		sb.set_border_width(side, bw)
	if bw_top > 0:
		sb.set_border_width(SIDE_TOP, bw_top)
	if bw_bottom > 0:
		sb.set_border_width(SIDE_BOTTOM, bw_bottom)
	sb.corner_radius_top_left    = radius
	sb.corner_radius_top_right   = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left  = radius
	return sb

func _fx_scale(node: Control) -> void:
	var t := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(node, "scale", Vector2(0.94, 0.94), 0.07)
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
