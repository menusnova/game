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

const CHARS : Array = [
	{"name":"LUXIA",  "element":"✦ LIGHT",    "rarity":5, "lv":80, "atk":2840, "def":1100, "hp":18400, "color":Color(1.00,0.82,0.30,1)},
	{"name":"EMBER",  "element":"🔥 FIRE",    "rarity":4, "lv":70, "atk":1920, "def":840,  "hp":14200, "color":Color(1.00,0.40,0.20,1)},
	{"name":"AQUA",   "element":"💧 WATER",   "rarity":4, "lv":60, "atk":1680, "def":960,  "hp":16800, "color":Color(0.20,0.60,1.00,1)},
	{"name":"TERRA",  "element":"🌿 EARTH",   "rarity":3, "lv":40, "atk":1100, "def":1200, "hp":20000, "color":Color(0.30,0.85,0.40,1)},
	{"name":"VOLT",   "element":"⚡ LIGHTNING","rarity":4, "lv":55, "atk":1740, "def":720,  "hp":13600, "color":Color(0.90,0.85,0.10,1)},
	{"name":"FROST",  "element":"❄ CRYO",    "rarity":5, "lv":75, "atk":2560, "def":880,  "hp":15800, "color":Color(0.60,0.90,1.00,1)},
]

var _selected : int = 0
var _detail   : Control

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Top bar ───────────────────────────────────────────────────────────
	var top := _panel(Rect2(0, 0, 1152, 52), Color(0.03,0.07,0.18,0.98), C_ACCENT, 0.0)
	add_child(top)
	_back_btn(top, C_ACCENT)
	_lbl_at(top, "👤  ALCHEMIST",        20, C_ACCENT, Vector2(460, 8))
	_lbl_at(top, "Character Collection",  10, C_TEXT2,  Vector2(468, 34))
	var sep := ColorRect.new(); sep.position = Vector2(0,51); sep.size = Vector2(1152,1); sep.color = C_ACCENT
	top.add_child(sep)

	# ── Roster grid  (x=8, y=60, w=460, h=580) ───────────────────────────
	# Card size 108×130, gap 4, 4 cols → 4×112=448 fits in 460
	# 2 rows needed for 6 chars
	var grid := _panel(Rect2(8, 60, 460, 300), C_PANEL, C_BORDER, 8.0)
	add_child(grid)
	_lbl_at(grid, "ROSTER  (%d / 50)" % CHARS.size(), 10, C_TEXT2, Vector2(12, 8))

	for i in range(CHARS.size()):
		var ch    : Dictionary = CHARS[i]
		var col   : int = i % 4
		var row   : int = i / 4
		var card  := _panel(Rect2(10 + col * 112, 26 + row * 132, 108, 128),
							Color(ch.color.r*0.10, ch.color.g*0.10, ch.color.b*0.10, 0.92),
							ch.color if i == _selected else C_BDR2, 6.0)
		grid.add_child(card)

		# Portrait (small generated)
		var port := TextureRect.new()
		port.position    = Vector2(8, 16); port.size = Vector2(92, 80)
		port.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		port.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		port.texture     = PortraitGen.make(ch.color, 92, 80)
		port.mouse_filter= Control.MOUSE_FILTER_IGNORE
		card.add_child(port)

		# Stars
		var stars := "★".repeat(ch.rarity) + "☆".repeat(5 - ch.rarity)
		_lbl_at(card, stars, 7, C_GOLD, Vector2(4, 4))
		_lbl_at(card, ch.name,         10, C_TEXT,  Vector2(4, 100))
		_lbl_at(card, "Lv.%d" % ch.lv,  8, C_TEXT2, Vector2(4, 114))

		var idx : int = i
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_selected = idx
				_refresh_detail())
		card.mouse_filter = Control.MOUSE_FILTER_STOP

	# ── Detail panel  (x=478, y=60, w=666, h=580) ────────────────────────
	_detail = _panel(Rect2(478, 60, 666, 576), C_PANEL, C_BORDER, 8.0)
	_detail.name = "Detail"
	add_child(_detail)
	_fill_detail()

func _fill_detail() -> void:
	for c in _detail.get_children(): c.queue_free()
	var ch : Dictionary = CHARS[_selected]
	var iw : float = 650.0   # inner width (666 - 8 padding each side)

	# Character name + stars
	_lbl_at(_detail, ch.name,                   32, ch.color, Vector2(16, 12))
	_lbl_at(_detail, ch.element,                 13, ch.color, Vector2(18, 52))
	_lbl_at(_detail, "★".repeat(ch.rarity),      14, C_GOLD,  Vector2(18, 70))

	# Portrait (large)
	var port := TextureRect.new()
	port.position    = Vector2(16, 94); port.size = Vector2(260, 380)
	port.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	port.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	port.texture     = PortraitGen.make(ch.color, 260, 380)
	port.mouse_filter= Control.MOUSE_FILTER_IGNORE
	_detail.add_child(port)

	# ── Stats panel  (x=288, y=94, w=358, h=200) ─────────────────────────
	var sp := _panel(Rect2(288, 94, 358, 196), C_PANEL2, C_BORDER, 8.0)
	_detail.add_child(sp)
	_lbl_at(sp, "STATS", 11, C_TEXT2, Vector2(12, 8))

	var stats : Array = [
		["Level",     "Lv. %d / 90" % ch.lv],
		["ATK",       _fmt(ch.atk)],
		["DEF",       _fmt(ch.def)],
		["HP",        _fmt(ch.hp)],
		["Crit Rate", "62.5%"],
		["Crit DMG",  "148.2%"],
	]
	for i in range(stats.size()):
		var sd : Array = stats[i]
		_lbl_at(sp, sd[0], 10, C_TEXT2, Vector2(12, 30 + i * 26))
		_lbl_at(sp, sd[1], 11, C_TEXT,  Vector2(175, 30 + i * 26))

	# ── Skills  (x=288, y=300, w=358, h=140) ─────────────────────────────
	var skp := _panel(Rect2(288, 300, 358, 140), C_PANEL2, C_BORDER, 8.0)
	_detail.add_child(skp)
	_lbl_at(skp, "SKILLS", 11, C_TEXT2, Vector2(12, 8))

	var skills : Array = [["⚔","Atk"],["💥","Skill"],["✨","Burst"],["🔮","Passive"]]
	for i in range(skills.size()):
		var sk    : Array  = skills[i]
		var sx    : float  = 12.0 + i * 84.0
		var scard := _panel(Rect2(sx, 28, 78, 100), C_DARK, ch.color, 6.0)
		skp.add_child(scard)
		_lbl_at(scard, sk[0], 24, ch.color, Vector2(22, 12))
		_lbl_at(scard, sk[1],  9, C_TEXT2,  Vector2(20, 58))
		_lbl_at(scard, "Lv.10", 8, C_TEXT,  Vector2(18, 74))

	# ── Level up button ───────────────────────────────────────────────────
	var lbu := Button.new()
	lbu.text     = "▲  LEVEL UP"
	lbu.position = Vector2(16, 482); lbu.size = Vector2(260, 42)
	lbu.add_theme_font_size_override("font_size", 13)
	lbu.add_theme_color_override("font_color", C_DARK)
	_apply_style(lbu, ch.color, ch.color, 8.0)
	_detail.add_child(lbu)

func _fmt(n: int) -> String:
	if n >= 1000: return "%d,%03d" % [n/1000, n%1000]
	return str(n)

func _refresh_detail() -> void:
	_fill_detail()

func _back_btn(parent: Control, accent: Color) -> void:
	var b := Button.new(); b.text = "◀  LOBBY"; b.position = Vector2(10,10); b.size = Vector2(100,32)
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color(0.82,0.93,1,1))
	_apply_style(b, Color(accent.r,accent.g,accent.b,0.22), accent, 5.0)
	b.pressed.connect(_go_lobby); parent.add_child(b)

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
