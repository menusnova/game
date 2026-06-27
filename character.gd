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
const C_PURPLE := Color(0.65, 0.35, 1.00, 1.0)

# Demo character roster
const CHARS : Array = [
	{"name": "LUXIA",   "element": "✦ LIGHT",  "rarity": 5, "lv": 80, "atk": 2840, "color": Color(1.0, 0.82, 0.30, 1)},
	{"name": "EMBER",   "element": "🔥 FIRE",   "rarity": 4, "lv": 70, "atk": 1920, "color": Color(1.0, 0.40, 0.20, 1)},
	{"name": "AQUA",    "element": "💧 WATER",  "rarity": 4, "lv": 60, "atk": 1680, "color": Color(0.20, 0.60, 1.00, 1)},
	{"name": "TERRA",   "element": "🌿 EARTH",  "rarity": 3, "lv": 40, "atk": 1100, "color": Color(0.30, 0.85, 0.40, 1)},
	{"name": "VOLT",    "element": "⚡ LIGHTNING","rarity": 4, "lv": 55, "atk": 1740, "color": Color(0.90, 0.85, 0.10, 1)},
	{"name": "FROST",   "element": "❄ CRYO",   "rarity": 5, "lv": 75, "atk": 2560, "color": Color(0.60, 0.90, 1.00, 1)},
]

var _selected : int = 0

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(bg)

	# Top bar
	var top := _panel(Rect2(0, 0, 1152, 52), Color(0.03, 0.07, 0.18, 0.98), C_ACCENT, 0.0)
	add_child(top)
	var back := Button.new(); back.text = "◀  LOBBY"; back.position = Vector2(10,10); back.size = Vector2(100,32)
	back.add_theme_font_size_override("font_size", 12)
	back.add_theme_color_override("font_color", C_TEXT)
	_apply_style(back, Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.22), C_ACCENT, 5.0)
	back.pressed.connect(_go_lobby); top.add_child(back)
	_lbl_at(top, "👤  ALCHEMIST", 20, C_ACCENT, Vector2(450, 8))
	_lbl_at(top, "Character Collection", 10, C_TEXT2, Vector2(470, 34))
	var sep := ColorRect.new(); sep.position = Vector2(0,51); sep.size = Vector2(1152,1); sep.color = C_ACCENT
	top.add_child(sep)

	# Character grid (left)
	var grid := _panel(Rect2(8, 62, 460, 572), C_PANEL, C_BORDER, 8.0)
	add_child(grid)
	_lbl_at(grid, "ROSTER  (%d / 50)" % CHARS.size(), 11, C_TEXT2, Vector2(12, 8))

	for i in range(CHARS.size()):
		var ch : Dictionary = CHARS[i]
		var col : int = i % 4
		var row : int = i / 4
		var cx  : float = 10 + col * 110.0
		var cy  : float = 32 + row * 120.0
		var card := _panel(Rect2(cx, cy, 100, 110),
							Color(ch.color.r*0.1, ch.color.g*0.1, ch.color.b*0.1, 0.9),
							ch.color if i == _selected else C_BDR2, 7.0)
		grid.add_child(card)

		# Star rarity
		var stars := "★".repeat(ch.rarity) + "☆".repeat(5 - ch.rarity)
		_lbl_at(card, stars, 8, ch.color, Vector2(4, 4))
		# Placeholder art box
		var art := _panel(Rect2(20, 18, 60, 60), Color(0,0,0,0.4), ch.color, 4.0)
		card.add_child(art)
		_lbl_at(art, ch.element.split(" ")[0], 22, ch.color, Vector2(12, 10))
		_lbl_at(card, ch.name,           10, C_TEXT,   Vector2(4, 84))
		_lbl_at(card, "Lv.%d" % ch.lv,   8, C_TEXT2,  Vector2(60, 86))

		var idx : int = i
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed:
				_selected = idx; _refresh_detail())
		card.mouse_filter = Control.MOUSE_FILTER_STOP

	# Detail panel (right)
	var detail := _panel(Rect2(478, 62, 666, 572), C_PANEL, C_BORDER, 8.0)
	detail.name = "Detail"; add_child(detail)
	_build_detail(detail)

func _build_detail(detail: Control) -> void:
	for c in detail.get_children(): c.queue_free()
	var ch : Dictionary = CHARS[_selected]

	_lbl_at(detail, ch.name, 32, ch.color, Vector2(20, 16))
	_lbl_at(detail, ch.element, 14, ch.color, Vector2(22, 58))
	var stars := "★".repeat(ch.rarity)
	_lbl_at(detail, stars, 16, C_GOLD, Vector2(22, 76))

	# Art placeholder
	var art := _panel(Rect2(20, 100, 280, 340), Color(ch.color.r*0.08, ch.color.g*0.08, ch.color.b*0.08, 0.9), ch.color, 10.0)
	detail.add_child(art)
	_lbl_at(art, ch.element.split(" ")[0], 80, Color(ch.color.r,ch.color.g,ch.color.b,0.3), Vector2(60, 100))
	_lbl_at(art, "[ Art Placeholder ]", 12, ch.color, Vector2(60, 280))

	# Stats
	var stats_panel := _panel(Rect2(316, 100, 330, 200), C_PANEL2, C_BORDER, 8.0)
	detail.add_child(stats_panel)
	_lbl_at(stats_panel, "STATS", 11, C_TEXT2, Vector2(12, 10))
	var stats_data : Array = [
		["Level",    "Lv. %d / 90" % ch.lv],
		["ATK",      str(ch.atk)],
		["DEF",      "1,240"],
		["HP",       "14,800"],
		["Crit Rate","62.5%"],
		["Crit DMG", "148.2%"],
	]
	for i in range(stats_data.size()):
		var sd : Array = stats_data[i]
		_lbl_at(stats_panel, sd[0], 10, C_TEXT2, Vector2(12, 32 + i*26))
		_lbl_at(stats_panel, sd[1], 11, C_TEXT,  Vector2(160, 32 + i*26))

	# Skill icons
	var skills_panel := _panel(Rect2(316, 310, 330, 130), C_PANEL2, C_BORDER, 8.0)
	detail.add_child(skills_panel)
	_lbl_at(skills_panel, "SKILLS", 11, C_TEXT2, Vector2(12, 10))
	var skill_icons : Array = ["⚔ Attack", "💥 Skill", "✨ Burst", "🔮 Passive"]
	for i in range(skill_icons.size()):
		var sb := _panel(Rect2(10 + i*76, 30, 68, 80), C_DARK, ch.color, 6.0)
		skills_panel.add_child(sb)
		_lbl_at(sb, skill_icons[i].split(" ")[0], 22, ch.color, Vector2(18, 10))
		_lbl_at(sb, skill_icons[i].split(" ")[1], 8, C_TEXT2, Vector2(6, 56))

	# Level up button
	var lvup := Button.new(); lvup.text = "▲  LEVEL UP"; lvup.size = Vector2(300, 40)
	lvup.position = Vector2(20, 458); lvup.add_theme_font_size_override("font_size", 13)
	lvup.add_theme_color_override("font_color", C_DARK)
	_apply_style(lvup, ch.color, ch.color, 8.0); detail.add_child(lvup)

func _refresh_detail() -> void:
	var detail := get_node_or_null("Detail")
	if detail: _build_detail(detail)

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
