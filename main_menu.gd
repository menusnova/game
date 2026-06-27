@tool
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
const C_TEXT3   := Color(0.38, 0.58, 0.88, 0.70)
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

func _ready() -> void:
	# ล้าง node เก่าก่อนสร้างใหม่ (ป้องกัน node ซ้อนกันเมื่อ editor reload)
	for child in get_children():
		child.free()
	_char_stage()
	_top_bar()
	_left_panel()
	_right_panel()
	_chat_bar()
	_bottom_nav()
	_domain()

# ─────────────────────────────────────────────────────────────────────────────
# Character stage — empty TextureRect, ใส่รูปเองใน Editor
# ─────────────────────────────────────────────────────────────────────────────
func _char_stage() -> void:
	_char_female = _tex_rect("FemaleCharacter", Vector2(260, 0), Vector2(630, 648))
	add_child(_char_female)

	_char_male = _tex_rect("MaleCharacter", Vector2(260, 0), Vector2(630, 648))
	_char_male.visible = false
	add_child(_char_male)

	var tog := Button.new()
	tog.text     = "♀ · ♂"
	tog.position = Vector2(540, 582)
	tog.size     = Vector2(72, 22)
	tog.add_theme_font_size_override("font_size", 10)
	tog.add_theme_color_override("font_color", C_TEXT2)
	_style(tog, Color(0, 0, 0, 0.55), C_BDR2, 6.0)
	if not Engine.is_editor_hint():
		tog.pressed.connect(_on_toggle_char)
	add_child(tog)

# ─────────────────────────────────────────────────────────────────────────────
# Top bar  y=0  h=50
# ─────────────────────────────────────────────────────────────────────────────
func _top_bar() -> void:
	var bar := ColorRect.new()
	bar.position = Vector2(0, 0); bar.size = Vector2(W, 50)
	bar.color    = Color(0.02, 0.04, 0.14, 0.82)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_hline(bar, 0, 49, W, Color(0.20, 0.50, 0.90, 0.25))

	# ── Currencies centered ─────────────────────────────────
	# 4 items spread: gap ≈ 185px each, block x=380..1000
	var cur : Array = [
		["✦", "12,450",    C_ACCENT,  380.0],
		["🪙","2,840,530",  C_GOLD,    555.0],
		["💎","18,760",     C_DIAMOND, 730.0],
		["⚡","240/240",    C_GREEN,   895.0],
	]
	for d : Array in cur:
		var x : float = d[3]
		_lbl_at(bar, d[0], 14, d[2],   Vector2(x,      10))
		_lbl_at(bar, d[1], 12, C_TEXT,  Vector2(x + 20, 12))
		_lbl_at(bar, "+",  11, d[2],    Vector2(x + 20 + float(d[1].length()) * 7.2, 12))

	# ── Right icons ─────────────────────────────────────────
	var icons : Array = ["⚙", "📢", "✉", "👥"]   # right-to-left
	for i in range(icons.size()):
		var b := Button.new()
		b.text     = icons[i]
		b.size     = Vector2(30, 30)
		b.position = Vector2(W - 38 - i * 34, 10)
		b.add_theme_font_size_override("font_size", 15)
		_style(b, Color(0,0,0,0), Color(0,0,0,0), 0.0)
		bar.add_child(b)

# ─────────────────────────────────────────────────────────────────────────────
# Left panel  x=10
# ─────────────────────────────────────────────────────────────────────────────
func _left_panel() -> void:
	# Profile card  y=58  w=258  h=72
	var card := _panel_at(Rect2(10, 58, 258, 72), C_CARD, C_BORDER, 8.0)
	add_child(card)

	var av := _tex_rect("Avatar", Vector2(8, 8), Vector2(52, 52))
	card.add_child(av)
	# avatar ring
	var ring := _panel_at(Rect2(6, 6, 56, 56), Color(0,0,0,0), C_ACCENT, 28.0)
	card.add_child(ring)

	_lbl_at(card, "!",              8,  C_RED,   Vector2(52, 6))
	_lbl_at(card, "CHEMIA",        14,  C_TEXT,  Vector2(68, 6))
	_lbl_at(card, "Lv.70",        10,  C_TEXT2, Vector2(68, 24))
	_lbl_at(card, "MAX",            9,  C_RED,   Vector2(104, 24))
	_rect(card, Vector2(68, 40), Vector2(178, 4), C_DARK)
	_rect(card, Vector2(68, 40), Vector2(178, 4), C_RED)
	_lbl_at(card, "UID 10000001  📋", 8, C_TEXT3, Vector2(68, 48))

	# Left menu items  y starts 142
	var menu : Array = [
		["🔔", "Notice",         C_RED,    true ],
		["🎁", "Missions",       C_GOLD,   true ],
		["🎉", "Event",          C_ORANGE, false],
		["⭐", "Pass",           C_PURPLE, false],
		["🛒", "Shop",           C_TEAL,   false],
		["💎", "First Purchase", C_PURPLE, false],
	]
	for i in range(menu.size()):
		var m : Array = menu[i]
		var my : float = 142.0 + i * 40.0
		_lbl_at(self, m[0], 14, m[2],  Vector2(14, my))
		_lbl_at(self, m[1], 13, C_TEXT, Vector2(38, my + 1))
		if m[3]:
			_rect(self, Vector2(29, my), Vector2(8, 8), C_RED)

	# Limited event banner  y=548  w=258  h=148
	var ev := _panel_at(Rect2(10, 498, 258, 148), Color(0.10, 0.03, 0.24, 0.94), C_PURPLE, 8.0)
	add_child(ev)

	var tag := _panel_at(Rect2(8, 7, 96, 14), Color(0.44, 0.07, 0.66, 1), Color(0,0,0,0), 3.0)
	ev.add_child(tag)
	_lbl_at(tag, "LIMITED EVENT", 7, C_TEXT, Vector2(6, 2))

	_lbl_at(ev, "STARFALL",               16, C_TEXT,   Vector2(8, 26))
	_lbl_at(ev, "INVOCATION",             16, C_PURPLE, Vector2(8, 48))
	_lbl_at(ev, "New Character Rate UP!", 8,  C_TEXT2,  Vector2(8, 76))

	# dot indicators
	for d in range(7):
		_rect(ev, Vector2(8 + d * 12, 130), Vector2(9, 5),
			C_PURPLE if d == 0 else Color(1, 1, 1, 0.22))

	var ev_art := _tex_rect("EventArt", Vector2(155, 8), Vector2(96, 132))
	ev.add_child(ev_art)

# ─────────────────────────────────────────────────────────────────────────────
# Right panel  x=985
# ─────────────────────────────────────────────────────────────────────────────
func _right_panel() -> void:
	const RX  : float = 985.0
	const CW  : float = 352.0   # card width (fits to W=1152)

	# Guide  w=82  h=82
	var g := _panel_at(Rect2(RX, 58, 82, 82), C_CARD2, C_BORDER, 8.0)
	add_child(g)
	_lbl_at(g, "🛡",        26, C_ACCENT, Vector2(26, 6))
	_lbl_at(g, "Guide",     11, C_TEXT,   Vector2(18, 44))
	_lbl_at(g, "New Player", 8, C_TEXT2,  Vector2(10, 58))

	# New Character  x=1075  w=270  h=82
	var nc := _panel_at(Rect2(1075, 58, 270, 82), Color(0.08, 0.04, 0.20, 0.94), C_GOLD, 8.0)
	add_child(nc)
	var hdr := ColorRect.new()
	hdr.position = Vector2(0, 0); hdr.size = Vector2(270, 18)
	hdr.color    = Color(0.10, 0.06, 0.28, 0.96)
	nc.add_child(hdr)
	_lbl_at(hdr, "NEW CHARACTER", 8, C_TEXT2, Vector2(8, 3))
	_lbl_at(nc, "LUXIA",          20, C_GOLD,   Vector2(8, 20))
	_lbl_at(nc, "✦ WHITE STAR ✦",  9, C_ACCENT, Vector2(8, 46))
	for d in range(7):
		_rect(nc, Vector2(8 + d * 10, 68), Vector2(7, 5), C_GOLD if d==0 else Color(1,1,1,0.22))
	var nc_art := _tex_rect("NewCharArt", Vector2(168, 2), Vector2(100, 78))
	nc.add_child(nc_art)

	# ── Content cards stacked  y=150 ─────────────────────────────
	# Adventure  h=95
	var adv := _panel_at(Rect2(RX, 150, CW, 95), C_CARD2, C_BORDER, 7.0)
	add_child(adv)
	_lbl_at(adv, "Adventure",    16, C_TEXT,   Vector2(12, 8))
	_lbl_at(adv, "MAIN STORY",   10, C_TEXT2,  Vector2(12, 30))
	_lbl_at(adv, "CHAPTER 12-9",  9, C_TEXT3,  Vector2(12, 70))
	_lbl_at(adv, "▶",            13, C_ACCENT, Vector2(CW - 18, 38))
	_rect(adv, Vector2(CW * 0.50, 2), Vector2(CW * 0.50 - 2, 91), Color(0.04, 0.08, 0.22, 0.60))
	var adv_art := _tex_rect("AdventureArt", Vector2(CW * 0.50 + 2, 2), Vector2(CW * 0.50 - 4, 91))
	adv.add_child(adv_art)
	if not Engine.is_editor_hint():
		adv.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_goto(SC_BATTLE))
	adv.mouse_filter = Control.MOUSE_FILTER_STOP

	# Chronicle  h=82  y=253
	var chr := _panel_at(Rect2(RX, 253, CW, 82), C_CARD2, C_BORDER, 7.0)
	add_child(chr)
	_lbl_at(chr, "Chronicle",  16, C_TEXT,   Vector2(12, 8))
	_lbl_at(chr, "SIDE STORY", 10, C_TEXT2,  Vector2(12, 30))
	_lbl_at(chr, "▶",          13, C_PURPLE, Vector2(CW - 18, 32))
	var chr_art := _tex_rect("ChronicleArt", Vector2(CW * 0.50, 2), Vector2(CW * 0.50 - 2, 78))
	chr.add_child(chr_art)

	# Simulation  h=82  y=343
	var sim := _panel_at(Rect2(RX, 343, CW, 82), C_CARD2, C_BORDER, 7.0)
	add_child(sim)
	_lbl_at(sim, "Simulation", 16, C_TEXT,  Vector2(12, 8))
	_lbl_at(sim, "RESOURCE",   10, C_TEXT2, Vector2(12, 30))
	_lbl_at(sim, "▶",          13, C_GREEN, Vector2(CW - 18, 32))
	var sim_art := _tex_rect("SimulationArt", Vector2(CW * 0.50, 2), Vector2(CW * 0.50 - 2, 78))
	sim.add_child(sim_art)

	# Arena + Expedition side by side  y=433
	const AW : float = (CW - 6) * 0.48
	const EW : float = (CW - 6) * 0.52

	var arena := _panel_at(Rect2(RX, 433, AW, 90), C_CARD2, C_BORDER, 7.0)
	add_child(arena)
	_lbl_at(arena, "Arena",    14, C_TEXT,    Vector2(10, 6))
	_lbl_at(arena, "PVP",      10, C_TEXT2,   Vector2(10, 24))
	_lbl_at(arena, "💠",       14, C_DIAMOND, Vector2(10, 45))
	_lbl_at(arena, "Diamond I", 9, C_TEXT2,   Vector2(32, 47))
	_lbl_at(arena, "3200/3500", 8, C_TEXT3,   Vector2(32, 60))
	_lbl_at(arena, "▶",        11, C_ACCENT,  Vector2(AW - 16, 36))
	var arena_art := _tex_rect("ArenaArt", Vector2(AW * 0.52, 2), Vector2(AW * 0.46, 86))
	arena.add_child(arena_art)
	if not Engine.is_editor_hint():
		arena.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_goto(SC_BATTLE))
	arena.mouse_filter = Control.MOUSE_FILTER_STOP

	var exped := _panel_at(Rect2(RX + AW + 6, 433, EW, 90), C_CARD2, C_BORDER, 7.0)
	add_child(exped)
	_lbl_at(exped, "Expedition", 13, C_TEXT,   Vector2(10, 6))
	_lbl_at(exped, "CHALLENGE",  10, C_TEXT2,  Vector2(10, 24))
	_lbl_at(exped, "▶",          11, C_ORANGE, Vector2(EW - 16, 36))
	var exped_art := _tex_rect("ExpeditionArt", Vector2(EW * 0.48, 2), Vector2(EW * 0.50, 86))
	exped.add_child(exped_art)

# ─────────────────────────────────────────────────────────────────────────────
# Chat bar  y=556  h=28
# ─────────────────────────────────────────────────────────────────────────────
func _chat_bar() -> void:
	var bar := ColorRect.new()
	bar.position = Vector2(0, 556); bar.size = Vector2(975, 28)
	bar.color    = Color(0.02, 0.05, 0.15, 0.88)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_hline(bar, 0, 0, 975, C_BDR2)
	_lbl_at(bar, "💬", 12, C_ACCENT, Vector2(8, 5))
	_lbl_at(bar, "[World] Alchemist : สวัสดีทุกคน!", 10, C_TEXT2, Vector2(28, 7))

# ─────────────────────────────────────────────────────────────────────────────
# Bottom nav  y=584  h=64  FULL WIDTH  7 items
# ─────────────────────────────────────────────────────────────────────────────
func _bottom_nav() -> void:
	const NY : float = 584.0
	const NH : float = 64.0

	var bar := ColorRect.new()
	bar.position = Vector2(0, NY); bar.size = Vector2(W, NH)
	bar.color    = Color(0.02, 0.04, 0.14, 0.94)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_hline(bar, 0, 0, W, C_BORDER)

	var nav : Array = [
		["⚗",  "Alchemist", true ],
		["⚔",  "Lineup",    false],
		["🔮", "Arcanum",   false],
		["🎒", "Inventory", false],
		["📖", "Database",  false],
		["🛡",  "Guild",     false],
		["📚", "Archive",   false],
	]

	var iw : float = W / nav.size()
	for i in range(nav.size()):
		var n      : Array = nav[i]
		var active : bool  = n[2]
		var nx     : float = iw * i

		if active:
			_rect(bar, Vector2(nx, 0),  Vector2(iw, NH), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.12))
			_rect(bar, Vector2(nx, 0),  Vector2(iw, 2),  C_ACCENT)

		# notification dot
		if i == 0 or i == 2:
			_rect(bar, Vector2(nx + iw * 0.5 + 10, 8), Vector2(8, 8), C_RED)

		var ic := _lbl(n[0], 22, C_ACCENT if active else C_TEXT2)
		ic.position = Vector2(nx, 6); ic.size = Vector2(iw, 28)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar.add_child(ic)

		var tx := _lbl(n[1], 9, C_ACCENT if active else C_TEXT3)
		tx.position = Vector2(nx, 36); tx.size = Vector2(iw, 14)
		tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar.add_child(tx)

# ─────────────────────────────────────────────────────────────────────────────
# Domain widget — bottom-right, floats over nav
# ─────────────────────────────────────────────────────────────────────────────
func _domain() -> void:
	# Outer ring
	var outer := _panel_at(Rect2(1048, 520, 136, 136), Color(0, 0, 0, 0), C_ACCENT, 68.0)
	add_child(outer)
	# Inner circle
	var inner := _panel_at(Rect2(1054, 526, 124, 124), Color(0.04, 0.07, 0.20, 0.96), C_ACCENT, 62.0)
	add_child(inner)
	_lbl_at(inner, "🛡",           22, C_ACCENT, Vector2(40, 10))
	_lbl_at(inner, "Domain",       13, C_TEXT,   Vector2(28, 46))
	_lbl_at(inner, "BONUS REWARD",  7, C_TEXT2,  Vector2(18, 64))
	# 100% badge
	var pct := _panel_at(Rect2(1196, 558, 60, 60), Color(0.02, 0.04, 0.12, 0.96), C_GOLD, 30.0)
	add_child(pct)
	_lbl_at(pct, "100%", 10, C_GOLD, Vector2(7, 22))

# ─────────────────────────────────────────────────────────────────────────────
# Toggle ♀/♂
# ─────────────────────────────────────────────────────────────────────────────
func _on_toggle_char() -> void:
	if Engine.is_editor_hint(): return
	_show_female       = not _show_female
	_char_female.visible = _show_female
	_char_male.visible   = not _show_female

# ─────────────────────────────────────────────────────────────────────────────
# Scene transition
# ─────────────────────────────────────────────────────────────────────────────
func _goto(path: String) -> void:
	if Engine.is_editor_hint(): return
	if not ResourceLoader.exists(path): return
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0); ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween(); t.tween_property(ov, "color:a", 1.0, 0.28)
	await t.finished
	get_tree().change_scene_to_file(path)

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
func _tex_rect(node_name: String, pos: Vector2, sz: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.name        = node_name
	t.position    = pos;  t.size = sz
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter= Control.MOUSE_FILTER_IGNORE
	return t

func _panel_at(r: Rect2, fill: Color, border: Color, radius: float) -> PanelContainer:
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
