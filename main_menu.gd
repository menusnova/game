extends Control

# ── Screen 1152 × 648 ─────────────────────────────────────────────────────────
const W : float = 1152.0
const H : float = 648.0

# ── Palette ───────────────────────────────────────────────────────────────────
const C_BG      := Color(0.02, 0.04, 0.13, 1.00)
const C_CARD    := Color(0.04, 0.08, 0.20, 0.88)
const C_CARD2   := Color(0.06, 0.11, 0.26, 0.92)
const C_DARK    := Color(0.02, 0.04, 0.12, 0.96)
const C_BORDER  := Color(0.18, 0.50, 0.90, 0.45)
const C_BDR2    := Color(0.22, 0.62, 1.00, 0.25)
const C_TEXT    := Color(0.93, 0.96, 1.00, 1.00)
const C_TEXT2   := Color(0.58, 0.78, 1.00, 1.00)
const C_TEXT3   := Color(0.38, 0.58, 0.88, 0.75)
const C_ACCENT  := Color(0.22, 0.72, 1.00, 1.00)
const C_GOLD    := Color(1.00, 0.82, 0.28, 1.00)
const C_PURPLE  := Color(0.65, 0.35, 1.00, 1.00)
const C_RED     := Color(1.00, 0.30, 0.30, 1.00)
const C_GREEN   := Color(0.25, 1.00, 0.55, 1.00)
const C_ORANGE  := Color(1.00, 0.58, 0.14, 1.00)
const C_DIAMOND := Color(0.55, 0.78, 1.00, 1.00)
const C_TEAL    := Color(0.10, 0.80, 0.75, 1.00)

const SC_BATTLE := "res://battle_scene.tscn"

var _show_female : bool = true
var _char_female : TextureRect
var _char_male   : TextureRect

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_add_bg()
	_build_char_stage()
	_build_top_bar()
	_build_profile()
	_build_left_menu()
	_build_limited_event()
	_build_top_right()
	_build_content_cards()
	_build_domain()
	_build_chat()
	_build_bottom_nav()

# ── Background ────────────────────────────────────────────────────────────────
func _add_bg() -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

# ── Character stage ───────────────────────────────────────────────────────────
func _build_char_stage() -> void:
	var glow := ColorRect.new()
	glow.position   = Vector2(180, 440); glow.size = Vector2(800, 210)
	glow.color      = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.05)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	_char_female = TextureRect.new()
	_char_female.name         = "FemaleCharacter"
	_char_female.position     = Vector2(310, 20)
	_char_female.size         = Vector2(500, 608)
	_char_female.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_char_female.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_female.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_female.texture      = PortraitGen.make(Color(0.55, 0.80, 1.00), 500, 608)
	add_child(_char_female)

	_char_male = TextureRect.new()
	_char_male.name         = "MaleCharacter"
	_char_male.position     = Vector2(310, 20)
	_char_male.size         = Vector2(500, 608)
	_char_male.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_char_male.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_male.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_male.texture      = PortraitGen.make(Color(1.00, 0.60, 0.20), 500, 608)
	_char_male.visible      = false
	add_child(_char_male)

	# Small ♀/♂ toggle — sits just above bottom nav, center-bottom of stage
	var tog := Button.new()
	tog.text     = "♀ · ♂"
	tog.position = Vector2(530, 584)
	tog.size     = Vector2(72, 22)
	tog.add_theme_font_size_override("font_size", 10)
	tog.add_theme_color_override("font_color", C_TEXT2)
	_style(tog, Color(0,0,0,0.50), C_BDR2, 6.0)
	tog.pressed.connect(_on_toggle_char)
	add_child(tog)

# ── Top bar  y=0 h=46  (4 floating currency labels, no background bar) ────────
func _build_top_bar() -> void:
	# Currencies — 4 individual floating items, spread across top
	var cur : Array = [
		["✦", "12,450",     C_ACCENT,  200.0],
		["🪙", "2,840,530",  C_GOLD,    380.0],
		["💎", "18,760",     C_DIAMOND, 580.0],
		["⚡", "240/240",    C_GREEN,   760.0],
	]
	for c : Array in cur:
		var x : float = c[3]
		_lbl_at(self, c[0], 15, c[2], Vector2(x,     9))
		_lbl_at(self, c[1], 12, C_TEXT,  Vector2(x+20, 11))
		_lbl_at(self, "+",  12, c[2],    Vector2(x+20+_sw(c[1],12)+3, 11))

# ── Profile card  x=8 y=54 w=240 h=68 ───────────────────────────────────────
func _build_profile() -> void:
	var card := _card(Rect2(8, 54, 240, 68), C_CARD, C_BORDER, 8.0)
	add_child(card)

	# Avatar (generated portrait cropped to circle feel)
	var av := TextureRect.new()
	av.position    = Vector2(8, 7); av.size = Vector2(50, 50)
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av.texture     = PortraitGen.make(Color(0.50, 0.72, 1.0), 50, 50)
	av.mouse_filter= Control.MOUSE_FILTER_IGNORE
	card.add_child(av)
	# Avatar circle border
	var av_ring := _card(Rect2(6, 5, 54, 54), Color(0,0,0,0), C_ACCENT, 27.0)
	card.add_child(av_ring)

	# Notification !
	_lbl_at(card, "!", 8, C_RED, Vector2(50, 5))

	# Info
	_lbl_at(card, "CHEMIA",          13, C_TEXT,  Vector2(64, 5))
	_lbl_at(card, "Lv.70",           10, C_TEXT2, Vector2(64, 21))
	_lbl_at(card, "MAX",              9, C_RED,   Vector2(96, 21))
	_rect(card, Vector2(64, 35), Vector2(166, 4), C_DARK)
	_rect(card, Vector2(64, 35), Vector2(166, 4), C_RED)   # full bar = MAX
	_lbl_at(card, "UID 10000001  📋", 8, C_TEXT3, Vector2(64, 43))

# ── Left menu  (floating, no panel bg) ───────────────────────────────────────
func _build_left_menu() -> void:
	var items : Array = [
		["🔔", "Notice",         C_RED,    true ],
		["🎁", "Missions",       C_GOLD,   true ],
		["🎉", "Event",          C_ORANGE, false],
		["⭐", "Pass",           C_PURPLE, false],
		["🛒", "Shop",           C_TEAL,   false],
		["💎", "First Purchase", C_PURPLE, false],
	]
	for i in range(items.size()):
		var m  : Array = items[i]
		var my : float = 134.0 + i * 34.0
		_lbl_at(self, m[0], 13, m[2],  Vector2(14, my))
		_lbl_at(self, m[1], 12, C_TEXT, Vector2(36, my+1))
		if m[3]:
			_rect(self, Vector2(27, my), Vector2(7, 7), C_RED)

# ── Limited Event banner  x=8 y=494 w=240 h=96 ───────────────────────────────
func _build_limited_event() -> void:
	var card := _card(Rect2(8, 494, 240, 96), Color(0.10, 0.03, 0.24, 0.94), C_PURPLE, 8.0)
	add_child(card)

	var tag := _card(Rect2(8, 6, 88, 13), Color(0.44, 0.07, 0.66, 1), Color(0,0,0,0), 3.0)
	card.add_child(tag)
	_lbl_at(tag, "LIMITED EVENT", 7, Color(1,1,1,1), Vector2(6, 2))

	_lbl_at(card, "STARFALL",     14, Color(1,1,1,1), Vector2(8, 22))
	_lbl_at(card, "INVOCATION",   14, C_PURPLE,       Vector2(8, 40))
	_lbl_at(card, "New Character Rate UP!", 8, C_TEXT2, Vector2(8, 62))

	for d in range(7):
		_rect(card, Vector2(8 + d*11, 82), Vector2(8, 4),
			  C_PURPLE if d == 0 else Color(1,1,1,0.20))

	# Character art right
	var art := TextureRect.new()
	art.position    = Vector2(148, 4); art.size = Vector2(86, 88)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture     = PortraitGen.make(Color(0.65, 0.35, 1.0), 86, 88)
	art.mouse_filter= Control.MOUSE_FILTER_IGNORE
	card.add_child(art)

# ── Top-right: Guide (80×80) + New Character banner (162×80) ─────────────────
func _build_top_right() -> void:
	# Guide
	var g := _card(Rect2(892, 54, 80, 80), C_CARD2, C_BORDER, 8.0)
	add_child(g)
	_lbl_at(g, "🛡",        24, C_ACCENT, Vector2(26, 6))
	_lbl_at(g, "Guide",     11, C_TEXT,   Vector2(20, 40))
	_lbl_at(g, "New Player", 8, C_TEXT2,  Vector2(12, 56))

	# New Character
	var nc := _card(Rect2(980, 54, 164, 80), Color(0.08, 0.04, 0.20, 0.94), C_GOLD, 8.0)
	add_child(nc)

	var hdr := ColorRect.new()
	hdr.position = Vector2(0,0); hdr.size = Vector2(164, 16); hdr.color = Color(0.10, 0.06, 0.28, 0.96)
	nc.add_child(hdr)
	_lbl_at(hdr, "NEW CHARACTER", 8, C_TEXT2, Vector2(6, 2))

	_lbl_at(nc, "LUXIA",         17, C_GOLD,   Vector2(8, 19))
	_lbl_at(nc, "✦ WHITE STAR ✦", 8, C_ACCENT, Vector2(8, 40))

	var art := TextureRect.new()
	art.position    = Vector2(100, 2); art.size = Vector2(60, 74)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture     = PortraitGen.make(Color(1.0, 0.85, 0.28), 60, 74)
	art.mouse_filter= Control.MOUSE_FILTER_IGNORE
	nc.add_child(art)

	for d in range(7):
		_rect(nc, Vector2(8 + d*9, 68), Vector2(6, 4),
			  C_GOLD if d == 0 else Color(1,1,1,0.20))

# ── Content cards right side ──────────────────────────────────────────────────
func _build_content_cards() -> void:
	const RX  : float = 892.0
	const CW  : float = 252.0
	const AW  : float = 108.0   # art panel width

	# Adventure  y=142 h=66
	var adv := _card(Rect2(RX, 142, CW, 66), C_CARD2, C_BORDER, 7.0)
	add_child(adv)
	_lbl_at(adv, "Adventure",    15, C_TEXT,  Vector2(10, 6))
	_lbl_at(adv, "MAIN STORY",    9, C_TEXT2, Vector2(10, 25))
	_lbl_at(adv, "CHAPTER 12-9",  8, C_TEXT3, Vector2(10, 48))
	_lbl_at(adv, "▶",            13, C_ACCENT,Vector2(CW-16, 24))
	var adv_a := _card(Rect2(CW-AW-2, 2, AW, 62), Color(0.04,0.08,0.22,0.82), Color(0,0,0,0), 6.0)
	adv.add_child(adv_a); _lbl_at(adv_a, "💠", 28, C_ACCENT, Vector2(38, 16))
	adv.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: _goto(SC_BATTLE))
	adv.mouse_filter = Control.MOUSE_FILTER_STOP

	# Chronicle  y=214 h=56
	var chr := _card(Rect2(RX, 214, CW, 56), C_CARD2, C_BORDER, 7.0)
	add_child(chr)
	_lbl_at(chr, "Chronicle",    14, C_TEXT,   Vector2(10, 6))
	_lbl_at(chr, "SIDE STORY",    9, C_TEXT2,  Vector2(10, 24))
	_lbl_at(chr, "▶",            13, C_PURPLE, Vector2(CW-16, 18))
	var chr_a := _card(Rect2(CW-AW-2, 2, AW, 52), Color(0.08,0.04,0.22,0.82), Color(0,0,0,0), 6.0)
	chr.add_child(chr_a)
	var chr_t := TextureRect.new()
	chr_t.position=Vector2(0,0); chr_t.size=Vector2(AW,52)
	chr_t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; chr_t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chr_t.texture=PortraitGen.make(Color(0.65,0.35,1.0),int(AW),52); chr_t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	chr_a.add_child(chr_t)

	# Simulation  y=276 h=56
	var sim := _card(Rect2(RX, 276, CW, 56), C_CARD2, C_BORDER, 7.0)
	add_child(sim)
	_lbl_at(sim, "Simulation",   14, C_TEXT,  Vector2(10, 6))
	_lbl_at(sim, "RESOURCE",      9, C_TEXT2, Vector2(10, 24))
	_lbl_at(sim, "▶",            13, C_GREEN, Vector2(CW-16, 18))
	var sim_a := _card(Rect2(CW-AW-2, 2, AW, 52), Color(0.03,0.12,0.10,0.82), Color(0,0,0,0), 6.0)
	sim.add_child(sim_a); _lbl_at(sim_a, "🔬", 26, C_GREEN, Vector2(38, 12))

	# Arena  x=892 y=338 w=120 h=66
	var arena := _card(Rect2(RX, 338, 120, 66), C_CARD2, C_BORDER, 7.0)
	add_child(arena)
	_lbl_at(arena, "Arena",     13, C_TEXT,    Vector2(8, 5))
	_lbl_at(arena, "PVP",        9, C_TEXT2,   Vector2(8, 21))
	_lbl_at(arena, "💠",        16, C_DIAMOND, Vector2(8, 32))
	_lbl_at(arena, "Diamond I",  8, C_TEXT2,   Vector2(32, 34))
	_lbl_at(arena, "3200/3500",  7, C_TEXT3,   Vector2(32, 46))
	_lbl_at(arena, "▶",         11, C_ACCENT,  Vector2(102, 22))
	arena.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: _goto(SC_BATTLE))
	arena.mouse_filter = Control.MOUSE_FILTER_STOP

	# Expedition  x=1020 y=338 w=124 h=66
	var exp := _card(Rect2(1020, 338, 124, 66), C_CARD2, C_BORDER, 7.0)
	add_child(exp)
	_lbl_at(exp, "Expedition",  12, C_TEXT,   Vector2(8, 5))
	_lbl_at(exp, "CHALLENGE",    9, C_TEXT2,  Vector2(8, 21))
	var exp_a := _card(Rect2(62, 4, 56, 58), Color(0.06,0.06,0.18,0.82), Color(0,0,0,0), 4.0)
	exp.add_child(exp_a); _lbl_at(exp_a, "🤖", 22, C_ORANGE, Vector2(14, 14))
	_lbl_at(exp, "▶", 11, C_ORANGE, Vector2(106, 22))

# ── Domain widget  bottom-right circular ─────────────────────────────────────
func _build_domain() -> void:
	# Outer ring
	var outer := _card(Rect2(1014, 466, 132, 132), Color(0,0,0,0), C_ACCENT, 66.0)
	add_child(outer)
	# Inner
	var inner := _card(Rect2(1020, 472, 120, 120), Color(0.04,0.07,0.20,0.94), C_ACCENT, 60.0)
	add_child(inner)
	_lbl_at(inner, "🛡",          20, C_ACCENT, Vector2(40, 8))
	_lbl_at(inner, "Domain",      13, C_TEXT,   Vector2(26, 38))
	_lbl_at(inner, "BONUS REWARD", 7, C_TEXT2,  Vector2(18, 57))
	# 100% badge
	var pct := _card(Rect2(1148, 502, 52, 52), Color(0.02,0.04,0.12,0.94), C_GOLD, 26.0)
	add_child(pct)
	_lbl_at(pct, "100%", 10, C_GOLD, Vector2(6, 19))

# ── Chat bar  y=566 h=26 ─────────────────────────────────────────────────────
func _build_chat() -> void:
	var bar := ColorRect.new()
	bar.position = Vector2(0, 566); bar.size = Vector2(982, 26)
	bar.color    = Color(0.02, 0.05, 0.15, 0.88)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_hline(bar, 0, 0, 982, C_BDR2)
	_lbl_at(bar, "💬", 12, C_ACCENT, Vector2(8, 5))
	_lbl_at(bar, "[World] Alchemist : สวัสดีทุกคน!", 10, C_TEXT2, Vector2(28, 6))

# ── Bottom nav  y=592 h=56 ───────────────────────────────────────────────────
func _build_bottom_nav() -> void:
	const NW : float = W * 0.5   # nav bar: left half only (~576px)
	var bar := ColorRect.new()
	bar.position = Vector2(0, 592); bar.size = Vector2(NW, 56)
	bar.color    = Color(0.02, 0.04, 0.14, 0.94)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_hline(bar, 0, 0, NW, C_BORDER)

	var nav : Array = [
		["⚗",  "Alchemist", true ],
		["⚔",  "Lineup",    false],
		["🔮", "Arcanum",   false],
		["🎒", "Inventory", false],
		["📖", "Database",  false],
		["🛡",  "Guild",     false],
		["📚", "Archive",   false],
	]
	var iw : float = NW / nav.size()
	for i in range(nav.size()):
		var item   : Array = nav[i]
		var active : bool  = item[2]
		var nx     : float = iw * i

		if active:
			_rect(bar, Vector2(nx, 0), Vector2(iw, 56), Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.12))
			_rect(bar, Vector2(nx, 0), Vector2(iw, 2),  C_ACCENT)

		# Notif dot (first two)
		if i == 0 or i == 2:
			_rect(bar, Vector2(nx + iw*0.5 + 8, 7), Vector2(7, 7), C_RED)

		var ic := _lbl(item[0], 20, C_ACCENT if active else C_TEXT2)
		ic.position = Vector2(nx, 7); ic.size = Vector2(iw, 24)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar.add_child(ic)

		var tx := _lbl(item[1], 9, C_ACCENT if active else C_TEXT3)
		tx.position = Vector2(nx, 33); tx.size = Vector2(iw, 14)
		tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar.add_child(tx)

# ── Toggle ♀/♂ ───────────────────────────────────────────────────────────────
func _on_toggle_char() -> void:
	_show_female       = not _show_female
	_char_female.visible = _show_female
	_char_male.visible   = not _show_female

# ── Scene transition ──────────────────────────────────────────────────────────
func _goto(path: String) -> void:
	if not ResourceLoader.exists(path): return
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0,0,0,0); ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween(); t.tween_property(ov, "color:a", 1.0, 0.28)
	await t.finished
	get_tree().change_scene_to_file(path)

# ── Helpers ───────────────────────────────────────────────────────────────────
func _card(r: Rect2, fill: Color, border: Color, radius: float) -> PanelContainer:
	var p := PanelContainer.new(); p.position = r.position; p.size = r.size
	_style(p, fill, border, radius); return p

func _style(node: Control, fill: Color, border: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(int(radius))
	node.add_theme_stylebox_override("panel", sb)

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; return l

func _lbl_at(p: Control, text: String, size: int, color: Color, pos: Vector2) -> Label:
	var l := _lbl(text, size, color); l.position = pos; p.add_child(l); return l

func _rect(p: Control, pos: Vector2, sz: Vector2, color: Color) -> void:
	var r := ColorRect.new(); r.position = pos; r.size = sz; r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE; p.add_child(r)

func _hline(p: Control, x: float, y: float, w: float, color: Color) -> void:
	_rect(p, Vector2(x, y), Vector2(w, 1), color)

# Rough string pixel width estimate
func _sw(s: String, size: int) -> float:
	return s.length() * size * 0.60
