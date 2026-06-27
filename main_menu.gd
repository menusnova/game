extends Control

const W := 1152.0
const H := 648.0

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

var _char_female : TextureRect
var _char_male   : TextureRect
var _show_female := true

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_bg()
	_char_stage()
	_top_currencies()
	_left_panel()
	_right_panel()
	_chat_bar()
	_bottom_nav()

# ── Background ────────────────────────────────────────────────────────────────
func _bg() -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

# ── Character stage (center, behind UI) ──────────────────────────────────────
func _char_stage() -> void:
	_char_female = _portrait(Color(0.55, 0.80, 1.00), Vector2(310, 20), Vector2(500, 608))
	_char_female.name = "FemaleCharacter"
	add_child(_char_female)

	_char_male = _portrait(Color(1.00, 0.60, 0.20), Vector2(310, 20), Vector2(500, 608))
	_char_male.name    = "MaleCharacter"
	_char_male.visible = false
	add_child(_char_male)

	var tog := Button.new()
	tog.text     = "♀ · ♂"
	tog.position = Vector2(530, 584)
	tog.size     = Vector2(72, 22)
	tog.add_theme_font_size_override("font_size", 10)
	tog.add_theme_color_override("font_color", C_TEXT2)
	_style(tog, Color(0,0,0,0.50), C_BDR2, 6.0)
	tog.pressed.connect(_on_toggle_char)
	add_child(tog)

# ── Top: 4 floating currency labels ──────────────────────────────────────────
func _top_currencies() -> void:
	var data : Array = [
		["✦", "12,450",    C_ACCENT,   80.0],
		["🪙","2,840,530",  C_GOLD,    340.0],
		["💎","18,760",     C_DIAMOND, 640.0],
		["⚡","240/240",    C_GREEN,   930.0],
	]
	for d : Array in data:
		var x : float = d[3]
		# small semi-transparent pill behind each currency
		var pill := ColorRect.new()
		pill.position = Vector2(x - 4, 6)
		pill.size     = Vector2(130, 24)
		pill.color    = Color(0.01, 0.03, 0.10, 0.55)
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pill)

		_lbl_at(self, d[0], 13, d[2],  Vector2(x,     10))
		_lbl_at(self, d[1], 11, C_TEXT, Vector2(x+17,  12))
		_lbl_at(self, "+",  10, d[2],   Vector2(x+17 + d[1].length()*6.5, 12))

# ── Left panel ────────────────────────────────────────────────────────────────
func _left_panel() -> void:
	var col := VBoxContainer.new()
	col.position = Vector2(8, 54)
	col.add_theme_constant_override("separation", 6)
	add_child(col)

	# Profile card
	col.add_child(_profile_card())

	# Spacer
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 4)
	col.add_child(sp)

	# Left menu items
	var menu_items : Array = [
		["🔔", "Notice",         C_RED,    true ],
		["🎁", "Missions",       C_GOLD,   true ],
		["🎉", "Event",          C_ORANGE, false],
		["⭐", "Pass",           C_PURPLE, false],
		["🛒", "Shop",           C_TEAL,   false],
	]
	for m : Array in menu_items:
		col.add_child(_menu_row(m[0], m[1], m[2], m[3]))

	# Spacer to push event banner down
	var sp2 := Control.new(); sp2.custom_minimum_size = Vector2(0, 8)
	col.add_child(sp2)

	# Limited event banner
	col.add_child(_event_banner())

func _profile_card() -> Control:
	var card := _panel(Vector2(240, 68), C_CARD, C_BORDER, 8.0)

	var av := _portrait(Color(0.50, 0.72, 1.0), Vector2(8, 7), Vector2(50, 50))
	card.add_child(av)
	var av_ring := _panel_at(Rect2(6, 5, 54, 54), Color(0,0,0,0), C_ACCENT, 27.0)
	card.add_child(av_ring)

	_lbl_at(card, "!",              8,  C_RED,   Vector2(50, 5))
	_lbl_at(card, "CHEMIA",        13,  C_TEXT,  Vector2(64, 5))
	_lbl_at(card, "Lv.70",        10,  C_TEXT2, Vector2(64, 21))
	_lbl_at(card, "MAX",            9,  C_RED,   Vector2(96, 21))
	_rect(card, Vector2(64, 35), Vector2(166, 4), C_DARK)
	_rect(card, Vector2(64, 35), Vector2(166, 4), C_RED)
	_lbl_at(card, "UID 10000001  📋", 8, C_TEXT3, Vector2(64, 43))
	return card

func _menu_row(icon: String, label: String, color: Color, has_dot: bool) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(240, 28)
	row.add_theme_constant_override("separation", 6)

	var ic := _lbl(icon, 13, color)
	ic.custom_minimum_size = Vector2(22, 0)
	row.add_child(ic)

	var tx := _lbl(label, 12, C_TEXT)
	row.add_child(tx)

	if has_dot:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(7, 7)
		dot.color = C_RED
		dot.position = Vector2(0, 0)
		# place dot as overlay after building
		row.add_child(dot)

	return row

func _event_banner() -> Control:
	var card := _panel(Vector2(240, 96), Color(0.10, 0.03, 0.24, 0.94), C_PURPLE, 8.0)

	var tag := _panel_at(Rect2(8, 6, 88, 13), Color(0.44, 0.07, 0.66, 1), Color(0,0,0,0), 3.0)
	card.add_child(tag)
	_lbl_at(tag, "LIMITED EVENT", 7, C_TEXT, Vector2(6, 2))

	_lbl_at(card, "STARFALL",              14, C_TEXT,   Vector2(8, 22))
	_lbl_at(card, "INVOCATION",            14, C_PURPLE, Vector2(8, 40))
	_lbl_at(card, "New Character Rate UP!",  8, C_TEXT2, Vector2(8, 62))

	for d in range(7):
		_rect(card, Vector2(8 + d*11, 82), Vector2(8, 4), C_PURPLE if d==0 else Color(1,1,1,0.20))

	var art := _portrait(Color(0.65, 0.35, 1.0), Vector2(148, 4), Vector2(86, 88))
	card.add_child(art)
	return card

# ── Right panel ───────────────────────────────────────────────────────────────
func _right_panel() -> void:
	const RX := 892.0

	# Guide + New Char — side by side
	var top_row := HBoxContainer.new()
	top_row.position = Vector2(RX, 54)
	top_row.add_theme_constant_override("separation", 8)
	add_child(top_row)

	# Guide 80×80
	var g := _panel(Vector2(80, 80), C_CARD2, C_BORDER, 8.0)
	_lbl_at(g, "🛡",        24, C_ACCENT, Vector2(26, 6))
	_lbl_at(g, "Guide",     11, C_TEXT,   Vector2(20, 40))
	_lbl_at(g, "New Player", 8, C_TEXT2,  Vector2(12, 56))
	top_row.add_child(g)

	# New Char 164×80
	var nc := _panel(Vector2(164, 80), Color(0.08, 0.04, 0.20, 0.94), C_GOLD, 8.0)
	var hdr := ColorRect.new(); hdr.position = Vector2(0,0); hdr.size = Vector2(164,16)
	hdr.color = Color(0.10, 0.06, 0.28, 0.96)
	nc.add_child(hdr)
	_lbl_at(hdr, "NEW CHARACTER", 8, C_TEXT2, Vector2(6, 2))
	_lbl_at(nc,  "LUXIA",         17, C_GOLD,   Vector2(8, 19))
	_lbl_at(nc,  "✦ WHITE STAR ✦", 8, C_ACCENT, Vector2(8, 40))
	var nc_art := _portrait(Color(1.0, 0.85, 0.28), Vector2(100, 2), Vector2(60, 74))
	nc.add_child(nc_art)
	for d in range(7):
		_rect(nc, Vector2(8 + d*9, 68), Vector2(6, 4), C_GOLD if d==0 else Color(1,1,1,0.20))
	top_row.add_child(nc)

	# Content cards stacked vertically
	var col := VBoxContainer.new()
	col.position = Vector2(RX, 142)
	col.add_theme_constant_override("separation", 6)
	add_child(col)

	# Adventure
	var adv := _panel(Vector2(252, 66), C_CARD2, C_BORDER, 7.0)
	_lbl_at(adv, "Adventure",   15, C_TEXT,   Vector2(10, 6))
	_lbl_at(adv, "MAIN STORY",   9, C_TEXT2,  Vector2(10, 25))
	_lbl_at(adv, "CHAPTER 12-9", 8, C_TEXT3,  Vector2(10, 46))
	_lbl_at(adv, "▶",           13, C_ACCENT, Vector2(234, 24))
	_rect(adv, Vector2(144, 2), Vector2(106, 62), Color(0.04,0.08,0.22,0.55))
	_lbl_at(adv, "💠", 28, C_ACCENT, Vector2(182, 16))
	adv.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index==MOUSE_BUTTON_LEFT: _goto(SC_BATTLE))
	adv.mouse_filter = Control.MOUSE_FILTER_STOP
	col.add_child(adv)

	# Chronicle
	var chr := _panel(Vector2(252, 56), C_CARD2, C_BORDER, 7.0)
	_lbl_at(chr, "Chronicle",  14, C_TEXT,   Vector2(10, 6))
	_lbl_at(chr, "SIDE STORY",  9, C_TEXT2,  Vector2(10, 24))
	_lbl_at(chr, "▶",          13, C_PURPLE, Vector2(234, 18))
	var chr_art := _portrait(Color(0.65,0.35,1.0), Vector2(144,2), Vector2(106,52))
	chr.add_child(chr_art)
	col.add_child(chr)

	# Simulation
	var sim := _panel(Vector2(252, 56), C_CARD2, C_BORDER, 7.0)
	_lbl_at(sim, "Simulation", 14, C_TEXT,  Vector2(10, 6))
	_lbl_at(sim, "RESOURCE",    9, C_TEXT2, Vector2(10, 24))
	_lbl_at(sim, "▶",          13, C_GREEN, Vector2(234, 18))
	_rect(sim, Vector2(144, 2), Vector2(106, 52), Color(0.03,0.12,0.10,0.55))
	_lbl_at(sim, "🔬", 26, C_GREEN, Vector2(178, 12))
	col.add_child(sim)

	# Arena + Expedition side by side
	var battle_row := HBoxContainer.new()
	battle_row.add_theme_constant_override("separation", 6)
	col.add_child(battle_row)

	var arena := _panel(Vector2(120, 66), C_CARD2, C_BORDER, 7.0)
	_lbl_at(arena, "Arena",    13, C_TEXT,    Vector2(8, 5))
	_lbl_at(arena, "PVP",       9, C_TEXT2,   Vector2(8, 21))
	_lbl_at(arena, "💠",       16, C_DIAMOND, Vector2(8, 32))
	_lbl_at(arena, "Diamond I", 8, C_TEXT2,   Vector2(32, 34))
	_lbl_at(arena, "3200/3500", 7, C_TEXT3,   Vector2(32, 46))
	_lbl_at(arena, "▶",        11, C_ACCENT,  Vector2(102, 22))
	arena.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index==MOUSE_BUTTON_LEFT: _goto(SC_BATTLE))
	arena.mouse_filter = Control.MOUSE_FILTER_STOP
	battle_row.add_child(arena)

	var exped := _panel(Vector2(126, 66), C_CARD2, C_BORDER, 7.0)
	_lbl_at(exped, "Expedition", 12, C_TEXT,   Vector2(8, 5))
	_lbl_at(exped, "CHALLENGE",   9, C_TEXT2,  Vector2(8, 21))
	_rect(exped, Vector2(62, 4), Vector2(60, 58), Color(0.06,0.06,0.18,0.55))
	_lbl_at(exped, "🤖", 22, C_ORANGE, Vector2(76, 14))
	_lbl_at(exped, "▶",  11, C_ORANGE, Vector2(108, 22))
	battle_row.add_child(exped)

	# Domain circle — bottom right
	var outer := _panel_at(Rect2(1014, 466, 132, 132), Color(0,0,0,0), C_ACCENT, 66.0)
	add_child(outer)
	var inner := _panel_at(Rect2(1020, 472, 120, 120), Color(0.04,0.07,0.20,0.94), C_ACCENT, 60.0)
	add_child(inner)
	_lbl_at(inner, "🛡",          20, C_ACCENT, Vector2(40, 8))
	_lbl_at(inner, "Domain",      13, C_TEXT,   Vector2(26, 38))
	_lbl_at(inner, "BONUS REWARD", 7, C_TEXT2,  Vector2(18, 57))
	var pct := _panel_at(Rect2(1148, 502, 52, 52), Color(0.02,0.04,0.12,0.94), C_GOLD, 26.0)
	add_child(pct)
	_lbl_at(pct, "100%", 10, C_GOLD, Vector2(6, 19))

# ── Chat bar ──────────────────────────────────────────────────────────────────
func _chat_bar() -> void:
	var bar := ColorRect.new()
	bar.position = Vector2(0, 566); bar.size = Vector2(982, 26)
	bar.color    = Color(0.02, 0.05, 0.15, 0.88)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_hline(bar, 0, 0, 982, C_BDR2)
	_lbl_at(bar, "💬", 12, C_ACCENT, Vector2(8, 5))
	_lbl_at(bar, "[World] Alchemist : สวัสดีทุกคน!", 10, C_TEXT2, Vector2(28, 6))

# ── Bottom nav  left half only (576px) ───────────────────────────────────────
func _bottom_nav() -> void:
	const NW := W * 0.5

	var bar := ColorRect.new()
	bar.position = Vector2(0, 592); bar.size = Vector2(NW, 56)
	bar.color    = Color(0.02, 0.04, 0.14, 0.94)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_hline(bar, 0, 0, NW, C_BORDER)

	var nav : Array = [
		["⚗",  "Alchemist", C_ACCENT, true ],
		["⚔",  "Lineup",    C_TEXT2,  false],
		["🔮", "Arcanum",   C_TEXT2,  false],
		["🎒", "Inventory", C_TEXT2,  false],
		["🛡",  "Guild",     C_TEXT2,  false],
	]

	# Use HBoxContainer so items fill evenly
	var hbox := HBoxContainer.new()
	hbox.position = Vector2(0, 0)
	hbox.size     = Vector2(NW, 56)
	hbox.add_theme_constant_override("separation", 0)
	bar.add_child(hbox)

	for i in range(nav.size()):
		var n : Array = nav[i]
		var active : bool = n[3]

		var slot := Control.new()
		slot.custom_minimum_size = Vector2(NW / nav.size(), 56)
		hbox.add_child(slot)

		if active:
			var hi := ColorRect.new()
			hi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			hi.color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.12)
			hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(hi)
			_rect(slot, Vector2(0, 0), Vector2(NW / nav.size(), 2), C_ACCENT)

		# notification dot
		if i == 0 or i == 2:
			_rect(slot, Vector2(slot.custom_minimum_size.x * 0.5 + 8, 7), Vector2(7, 7), C_RED)

		var ic := _lbl(n[0], 20, n[2])
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic.position = Vector2(0, 5)
		ic.size     = Vector2(NW / nav.size(), 24)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(ic)

		var tx := _lbl(n[1], 9, C_ACCENT if active else C_TEXT3)
		tx.position = Vector2(0, 33)
		tx.size     = Vector2(NW / nav.size(), 14)
		tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(tx)

# ── Toggle character ──────────────────────────────────────────────────────────
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
func _panel(sz: Vector2, fill: Color, border: Color, radius: float) -> PanelContainer:
	var p := PanelContainer.new(); p.size = sz
	_style(p, fill, border, radius); return p

func _panel_at(r: Rect2, fill: Color, border: Color, radius: float) -> PanelContainer:
	var p := PanelContainer.new(); p.position = r.position; p.size = r.size
	_style(p, fill, border, radius); return p

func _style(node: Control, fill: Color, border: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(int(radius))
	node.add_theme_stylebox_override("panel", sb)

func _portrait(accent: Color, pos: Vector2, sz: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.position    = pos; t.size = sz
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture     = PortraitGen.make(accent, int(sz.x), int(sz.y))
	t.mouse_filter= Control.MOUSE_FILTER_IGNORE
	return t

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
