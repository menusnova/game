extends Control

const C_BG     := Color(0.03, 0.06, 0.16, 1.0)
const C_PANEL  := Color(0.05, 0.10, 0.22, 0.93)
const C_PANEL2 := Color(0.07, 0.13, 0.28, 0.96)
const C_DARK   := Color(0.02, 0.04, 0.12, 1.0)
const C_BORDER := Color(0.15, 0.45, 0.85, 0.55)
const C_BDR2   := Color(0.20, 0.60, 1.00, 0.28)
const C_TEXT   := Color(0.82, 0.93, 1.00, 1.0)
const C_TEXT2  := Color(0.55, 0.75, 1.00, 1.0)
const C_ACCENT := Color(0.20, 0.70, 1.00, 1.0)
const C_GOLD   := Color(1.00, 0.82, 0.30, 1.0)
const C_GREEN  := Color(0.28, 1.00, 0.55, 1.0)
const C_TEAL   := Color(0.10, 0.80, 0.75, 1.0)
const C_PURPLE := Color(0.65, 0.35, 1.00, 1.0)
const C_ORANGE := Color(1.00, 0.60, 0.16, 1.0)

const TABS : Array = ["All", "Materials", "Upgrade", "Weapons", "Artifacts", "Other"]

const ITEMS : Array = [
	{"icon":"⚗",  "name":"Alchemy Core",    "qty":3820,  "rarity":4, "color": Color(0.10,0.80,0.75,1)},
	{"icon":"🔥", "name":"Flame Essence",    "qty":240,   "rarity":3, "color": Color(1.0,0.40,0.20,1)},
	{"icon":"💧", "name":"Aqua Crystal",     "qty":185,   "rarity":3, "color": Color(0.20,0.60,1.00,1)},
	{"icon":"⚡", "name":"Thunder Core",     "qty":92,    "rarity":4, "color": Color(0.90,0.85,0.10,1)},
	{"icon":"❄",  "name":"Frost Shard",      "qty":310,   "rarity":3, "color": Color(0.60,0.90,1.00,1)},
	{"icon":"🌿", "name":"Earth Root",       "qty":430,   "rarity":2, "color": Color(0.30,0.85,0.40,1)},
	{"icon":"✦",  "name":"Star Dust",        "qty":50,    "rarity":5, "color": Color(1.00,0.82,0.30,1)},
	{"icon":"📖", "name":"EXP Book I",       "qty":120,   "rarity":2, "color": Color(0.65,0.35,1.00,1)},
	{"icon":"📕", "name":"EXP Book II",      "qty":48,    "rarity":3, "color": Color(0.65,0.35,1.00,1)},
	{"icon":"📗", "name":"EXP Book III",     "qty":12,    "rarity":4, "color": Color(0.65,0.35,1.00,1)},
	{"icon":"⚔",  "name":"Blade of Dawn",    "qty":1,     "rarity":5, "color": Color(1.00,0.82,0.30,1)},
	{"icon":"🗡",  "name":"Iron Dagger",      "qty":3,     "rarity":3, "color": Color(0.55,0.75,1.00,1)},
	{"icon":"💎", "name":"Resonance Gem",    "qty":8,     "rarity":4, "color": Color(0.80,0.40,1.00,1)},
	{"icon":"🪨", "name":"Mora Stone",       "qty":2400,  "rarity":1, "color": Color(0.65,0.60,0.50,1)},
	{"icon":"🧪", "name":"Synthesis Fluid",  "qty":64,    "rarity":3, "color": Color(0.10,0.80,0.75,1)},
	{"icon":"🎇", "name":"Catalyst Orb",     "qty":7,     "rarity":4, "color": Color(0.90,0.50,0.10,1)},
]

var _active_tab : int = 0

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(bg)

	# Top bar
	var top := _panel(Rect2(0, 0, 1152, 52), Color(0.03, 0.07, 0.18, 0.98), C_TEAL, 0.0)
	add_child(top)
	var back := Button.new(); back.text = "◀  LOBBY"; back.position = Vector2(10,10); back.size = Vector2(100,32)
	back.add_theme_font_size_override("font_size", 12)
	back.add_theme_color_override("font_color", C_TEXT)
	_apply_style(back, Color(C_TEAL.r,C_TEAL.g,C_TEAL.b,0.22), C_TEAL, 5.0)
	back.pressed.connect(_go_lobby); top.add_child(back)
	_lbl_at(top, "🎒  INVENTORY", 20, C_TEAL, Vector2(456, 8))
	_lbl_at(top, "Items & Materials", 10, C_TEXT2, Vector2(476, 34))
	var sep := ColorRect.new(); sep.position = Vector2(0,51); sep.size = Vector2(1152,1); sep.color = C_TEAL
	top.add_child(sep)

	# ── Tabs ──────────────────────────────────────────────────────────────
	for i in range(TABS.size()):
		var active : bool = (i == _active_tab)
		var tb := Button.new(); tb.text = TABS[i]; tb.size = Vector2(148, 34)
		tb.position = Vector2(20 + i * 154, 62)
		tb.add_theme_font_size_override("font_size", 11)
		_apply_style(tb, Color(C_TEAL.r,C_TEAL.g,C_TEAL.b,0.22) if active else C_PANEL2,
					 C_TEAL if active else C_BORDER, 6.0)
		tb.add_theme_color_override("font_color", C_TEAL if active else C_TEXT2)
		add_child(tb)

	# ── Summary bar ───────────────────────────────────────────────────────
	var sbar := _panel(Rect2(20, 104, 1112, 36), C_PANEL2, C_BDR2, 6.0)
	add_child(sbar)
	var sum_data : Array = [
		["💎 Crystal", "8,500"],
		["🪙 Gold",     "1,240,000"],
		["⚗ A.Core",   "3,820"],
		["⚡ Energy",   "120/120"],
	]
	var sx : float = 16.0
	for sd : Array in sum_data:
		_lbl_at(sbar, sd[0], 10, C_TEXT2, Vector2(sx, 10))
		_lbl_at(sbar, sd[1], 11, C_TEXT,  Vector2(sx + 70, 10))
		sx += 230.0

	# ── Item grid ─────────────────────────────────────────────────────────
	var grid := _panel(Rect2(20, 148, 740, 480), C_PANEL, C_BORDER, 8.0)
	add_child(grid)
	_lbl_at(grid, "ITEMS  (%d / 2000)" % ITEMS.size(), 10, C_TEXT2, Vector2(12, 8))

	var cols : int = 6
	for i in range(ITEMS.size()):
		var item : Dictionary = ITEMS[i]
		var col  : int = i % cols
		var row  : int = i / cols
		var card := _panel(Rect2(12 + col * 118, 28 + row * 112, 108, 102),
							Color(item.color.r*0.09, item.color.g*0.09, item.color.b*0.09, 0.9),
							item.color, 6.0)
		grid.add_child(card)

		# Rarity stars (small)
		var stars := "★".repeat(item.rarity)
		_lbl_at(card, stars, 7, C_GOLD, Vector2(4, 3))
		# Icon
		_lbl_at(card, item.icon, 26, item.color, Vector2(34, 20))
		# Name
		var nm := _lbl(item.name, 8, C_TEXT)
		nm.position = Vector2(4, 62); nm.size = Vector2(100, 28)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD; nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(nm)
		# Qty badge
		var qb := _panel(Rect2(60, 3, 44, 16), C_DARK, C_BDR2, 3.0)
		card.add_child(qb)
		_lbl_at(qb, "×%s" % _fmt(item.qty), 8, C_TEXT, Vector2(4, 2))

	# ── Detail panel right ────────────────────────────────────────────────
	var detail := _panel(Rect2(770, 148, 362, 480), C_PANEL, C_BORDER, 8.0)
	add_child(detail)
	_lbl_at(detail, "SELECT AN ITEM", 13, C_TEXT2, Vector2(100, 200))
	_lbl_at(detail, "to view details", 10, C_TEXT2, Vector2(120, 224))

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.1fK" % (n / 1000.0)
	return str(n)

func _go_lobby() -> void:
	var t := create_tween()
	var fade := ColorRect.new(); fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0,0,0,0); fade.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(fade)
	t.tween_property(fade, "color:a", 1.0, 0.30); await t.finished
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _panel(rect: Rect2, fill: Color, border: Color, radius: float) -> PanelContainer:
	var p := PanelContainer.new(); p.position = rect.position; p.size = rect.size
	_apply_style(p, fill, border, radius); return p

func _apply_style(node: Control, fill: Color, border: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new(); sb.bg_color = fill; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(int(radius))
	node.add_theme_stylebox_override("panel", sb)

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; return l

func _lbl_at(parent: Control, text: String, size: int, color: Color, pos: Vector2) -> Label:
	var l := _lbl(text, size, color); l.position = pos; parent.add_child(l); return l
