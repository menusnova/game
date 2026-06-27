extends Control

# ── Screen 1152 × 648 ─────────────────────────────────────────────────────────
const W : float = 1152.0
const H : float = 648.0

# ── Colours (dark navy-blue sci-fi palette) ───────────────────────────────────
const C_BG      := Color(0.02, 0.05, 0.14, 1.00)
const C_CARD    := Color(0.04, 0.08, 0.20, 0.90)
const C_CARD2   := Color(0.06, 0.11, 0.26, 0.92)
const C_DARK    := Color(0.02, 0.04, 0.12, 0.95)
const C_BORDER  := Color(0.18, 0.50, 0.90, 0.48)
const C_BDR2    := Color(0.22, 0.62, 1.00, 0.28)
const C_TEXT    := Color(0.92, 0.95, 1.00, 1.00)
const C_TEXT2   := Color(0.58, 0.78, 1.00, 1.00)
const C_TEXT3   := Color(0.40, 0.60, 0.90, 0.75)
const C_ACCENT  := Color(0.22, 0.72, 1.00, 1.00)
const C_GOLD    := Color(1.00, 0.82, 0.28, 1.00)
const C_PURPLE  := Color(0.65, 0.35, 1.00, 1.00)
const C_RED     := Color(1.00, 0.32, 0.32, 1.00)
const C_GREEN   := Color(0.28, 1.00, 0.55, 1.00)
const C_ORANGE  := Color(1.00, 0.58, 0.14, 1.00)
const C_DIAMOND := Color(0.55, 0.78, 1.00, 1.00)

# ── Scenes ────────────────────────────────────────────────────────────────────
const SC_BATTLE    := "res://battle_scene.tscn"
const SC_SUMMON    := "res://summon.tscn"
const SC_CHARACTER := "res://character.tscn"
const SC_LINEUP    := "res://lineup.tscn"
const SC_INVENTORY := "res://inventory.tscn"

# ── Character toggle ──────────────────────────────────────────────────────────
var _show_female : bool = true
var _char_female : TextureRect
var _char_male   : TextureRect

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_add_bg()
	_build_char_stage()   # must be early so UI draws on top
	_build_top_bar()
	_build_profile()
	_build_left_menu()
	_build_limited_event()
	_build_top_right()
	_build_content_cards()
	_build_domain()
	_build_chat()
	_build_bottom_nav()

# ── Full-screen background ────────────────────────────────────────────────────
func _add_bg() -> void:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.color        = C_BG
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	# Background TextureRect (user sets texture in editor)
	var bg_tex := TextureRect.new()
	bg_tex.name        = "Background"
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.mouse_filter= Control.MOUSE_FILTER_IGNORE
	add_child(bg_tex)

# ── Character stage (behind UI) ───────────────────────────────────────────────
func _build_char_stage() -> void:
	# Bottom glow
	var glow := ColorRect.new()
	glow.position   = Vector2(200, 480)
	glow.size       = Vector2(760, 168)
	glow.color      = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.06)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	# Female portrait
	_char_female = TextureRect.new()
	_char_female.name         = "FemaleCharacter"
	_char_female.position     = Vector2(320, 30)
	_char_female.size         = Vector2(480, 590)
	_char_female.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_char_female.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_female.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_female.texture      = PortraitGen.make(Color(0.60, 0.80, 1.00), 480, 590)
	add_child(_char_female)

	# Male portrait
	_char_male = TextureRect.new()
	_char_male.name         = "MaleCharacter"
	_char_male.position     = Vector2(320, 30)
	_char_male.size         = Vector2(480, 590)
	_char_male.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_char_male.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_male.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_male.texture      = PortraitGen.make(Color(1.00, 0.60, 0.20), 480, 590)
	_char_male.visible      = false
	add_child(_char_male)

	# ♀/♂ toggle — top center of stage
	var tog := Button.new()
	tog.text     = "♀ / ♂"
	tog.position = Vector2(524, 36)
	tog.size     = Vector2(80, 28)
	tog.add_theme_font_size_override("font_size", 11)
	tog.add_theme_color_override("font_color", C_TEXT2)
	_apply_style(tog, Color(0,0,0,0.45), C_BDR2, 6.0)
	tog.pressed.connect(_on_toggle_char)
	add_child(tog)

# ── Top bar  (y=0, h=48) ─────────────────────────────────────────────────────
# Currencies CENTERED, right icons on far right — matches reference image
func _build_top_bar() -> void:
	var bar := ColorRect.new()
	bar.position   = Vector2(0, 0)
	bar.size       = Vector2(W, 48.0)
	bar.color      = Color(0.02, 0.04, 0.14, 0.86)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	var sep := ColorRect.new()
	sep.position = Vector2(0, 47); sep.size = Vector2(W, 1)
	sep.color    = Color(0.18, 0.45, 0.85, 0.38)
	bar.add_child(sep)

	# 4 currencies — spaced evenly, centered in x=310..940
	# [icon, value, color, x_pos]
	var cur : Array = [
		["✦", "12,450",    C_ACCENT,  316.0],
		["🪙", "2,840,530", C_GOLD,   476.0],
		["💎", "18,760",    C_DIAMOND, 654.0],
		["⚡", "240/240",   C_GREEN,   812.0],
	]
	for c : Array in cur:
		var icon := _lbl(c[0], 15, c[2])
		icon.position = Vector2(c[3], 9); bar.add_child(icon)

		var val := _lbl(c[1], 13, C_TEXT)
		val.position = Vector2(c[3] + 22, 11); bar.add_child(val)

		# + circle button
		var plus := _lbl("+", 14, c[2])
		plus.position = Vector2(c[3] + 22 + _str_px(c[1], 13) + 4, 10)
		bar.add_child(plus)

		# Thin divider after (except last)
		if c[3] < 812.0:
			var div := ColorRect.new()
			div.color    = C_BDR2
			div.position = Vector2(c[3] + 22 + _str_px(c[1], 13) + 24, 10)
			div.size     = Vector2(1, 26)
			bar.add_child(div)

	# Right icons: Friends, Mail, Megaphone, Settings
	var ricons : Array = ["👥", "✉", "📢", "⚙"]
	for i in range(ricons.size()):
		var btn := Button.new()
		btn.text     = ricons[i]
		btn.size     = Vector2(32, 32)
		btn.position = Vector2(W - 44 - i * 38, 8)
		btn.add_theme_font_size_override("font_size", 17)
		_apply_style(btn, Color(0,0,0,0), Color(0,0,0,0), 0.0)
		bar.add_child(btn)

# ── Profile card  (x=8, y=52, w=248, h=80) ──────────────────────────────────
func _build_profile() -> void:
	var card := _card(Rect2(8, 52, 248, 80), C_CARD, C_BORDER, 8.0)
	add_child(card)

	# Avatar circle
	var av := Button.new()
	av.text = ""; av.position = Vector2(8, 8); av.size = Vector2(56, 56)
	_apply_style(av, Color(0.08, 0.15, 0.30, 0.95), C_ACCENT, 28.0)
	# Notification badge
	var badge := ColorRect.new()
	badge.position = Vector2(40, 0); badge.size = Vector2(16, 16); badge.color = C_RED
	var sb_b := StyleBoxFlat.new(); sb_b.bg_color = C_RED; sb_b.set_corner_radius_all(8)
	badge.add_theme_stylebox_override("panel", sb_b)
	var badge_l := _lbl("!", 10, Color(1,1,1,1))
	badge_l.position = Vector2(40, 0); card.add_child(badge_l)
	card.add_child(av)

	# Portrait inside avatar
	var av_port := TextureRect.new()
	av_port.position    = Vector2(8, 8); av_port.size = Vector2(56, 56)
	av_port.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_port.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av_port.texture     = PortraitGen.make(Color(0.55, 0.75, 1.0), 56, 56)
	av_port.mouse_filter= Control.MOUSE_FILTER_IGNORE
	card.add_child(av_port)

	# Text info
	_lbl_at(card, "CHEMIA",        14, C_TEXT,  Vector2(70, 8))
	_lbl_at(card, "Lv.70",         11, C_TEXT2, Vector2(70, 27))
	_lbl_at(card, "MAX",           10, C_RED,   Vector2(108, 27))

	# EXP bar
	var exp_bg := ColorRect.new()
	exp_bg.position = Vector2(70, 42); exp_bg.size = Vector2(164, 6); exp_bg.color = C_DARK
	card.add_child(exp_bg)
	var exp_fill := ColorRect.new()
	exp_fill.position = Vector2(70, 42); exp_fill.size = Vector2(164, 6)
	exp_fill.color    = C_RED
	card.add_child(exp_fill)

	_lbl_at(card, "UID 10000001  📋", 9, C_TEXT2, Vector2(70, 52))

# ── Left menu items (floating, NO background panel) ──────────────────────────
# Each item: icon + text, with optional notification dot
func _build_left_menu() -> void:
	# menu: [icon, text, accent_color, has_notif]
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
		var my : float = 144.0 + i * 37.0

		var ic := _lbl(m[0], 14, m[2])
		ic.position = Vector2(16, my); add_child(ic)

		var tx := _lbl(m[1], 13, C_TEXT)
		tx.position = Vector2(40, my + 1); add_child(tx)

		if m[3]:
			var dot := ColorRect.new()
			dot.position = Vector2(36, my + 1); dot.size = Vector2(8, 8)
			dot.color    = C_RED
			var sb := StyleBoxFlat.new(); sb.bg_color = C_RED; sb.set_corner_radius_all(4)
			add_child(dot)

# ── Limited Event banner  (x=8, y=488, w=248, h=102) ─────────────────────────
func _build_limited_event() -> void:
	var card := _card(Rect2(8, 488, 248, 102), Color(0.12, 0.04, 0.26, 0.94), C_PURPLE, 8.0)
	add_child(card)

	# "LIMITED EVENT" tag
	var tag := _card(Rect2(8, 6, 90, 14), Color(0.45, 0.08, 0.68, 1), Color(0,0,0,0), 3.0)
	card.add_child(tag)
	_lbl_at(tag, "LIMITED EVENT", 7, Color(1,1,1,1), Vector2(6, 2))

	_lbl_at(card, "STARFALL",     15, Color(1,1,1,1),  Vector2(8, 24))
	_lbl_at(card, "INVOCATION",   15, C_PURPLE,         Vector2(8, 42))
	_lbl_at(card, "New Character Rate UP!", 9, C_TEXT2, Vector2(8, 64))

	# Pagination dots
	for d in range(7):
		var dot := ColorRect.new()
		dot.position = Vector2(8 + d * 12, 84); dot.size = Vector2(8, 4)
		dot.color    = C_PURPLE if d == 0 else Color(1,1,1,0.25)
		var sb := StyleBoxFlat.new(); sb.bg_color = dot.color; sb.set_corner_radius_all(2)
		card.add_child(dot)

	# Character art panel (right)
	var art := _card(Rect2(148, 6, 92, 88), Color(0.15, 0.05, 0.30, 0.7), Color(0,0,0,0), 6.0)
	card.add_child(art)
	var art_tex := TextureRect.new()
	art_tex.position    = Vector2(0, 0); art_tex.size = Vector2(92, 88)
	art_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_tex.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_tex.texture     = PortraitGen.make(Color(0.65, 0.35, 1.0), 92, 88)
	art_tex.mouse_filter= Control.MOUSE_FILTER_IGNORE
	art.add_child(art_tex)

	# Click → summon
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_goto(SC_SUMMON))
	card.mouse_filter = Control.MOUSE_FILTER_STOP

# ── Top-right: Guide widget + New Character banner ────────────────────────────
# Guide: x=888, y=52, w=86, h=86
# NewChar: x=982, y=52, w=162, h=86
func _build_top_right() -> void:
	# Guide widget
	var guide := _card(Rect2(888, 52, 86, 86), Color(0.06, 0.10, 0.26, 0.92), C_BORDER, 7.0)
	add_child(guide)
	_lbl_at(guide, "🛡", 28, C_ACCENT,  Vector2(24, 6))
	_lbl_at(guide, "Guide",       11, C_TEXT,   Vector2(14, 46))
	_lbl_at(guide, "New Player",   8, C_TEXT2,  Vector2(8, 62))

	# New Character banner
	var nc := _card(Rect2(982, 52, 162, 86), Color(0.08, 0.04, 0.20, 0.94), C_GOLD, 7.0)
	add_child(nc)

	# Header tag
	var nc_tag := _card(Rect2(0, 0, 162, 18), Color(0.10, 0.06, 0.28, 1), Color(0,0,0,0), 0.0)
	nc.add_child(nc_tag)
	_lbl_at(nc_tag, "NEW CHARACTER", 8, C_TEXT2, Vector2(6, 3))

	_lbl_at(nc, "LUXIA",          18, C_GOLD,   Vector2(8, 22))
	_lbl_at(nc, "✦ WHITE STAR ✦",  9, C_ACCENT, Vector2(8, 46))

	# Art
	var art := TextureRect.new()
	art.position    = Vector2(96, 4); art.size = Vector2(62, 78)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture     = PortraitGen.make(Color(1.0, 0.85, 0.3), 62, 78)
	art.mouse_filter= Control.MOUSE_FILTER_IGNORE
	nc.add_child(art)

	# Dots
	for d in range(7):
		var dot := ColorRect.new()
		dot.position = Vector2(8 + d * 9, 74); dot.size = Vector2(6, 4)
		dot.color    = C_GOLD if d == 0 else Color(1,1,1,0.25)
		nc.add_child(dot)

	nc.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_goto(SC_SUMMON))
	nc.mouse_filter = Control.MOUSE_FILTER_STOP

# ── Content cards  (x=888, right side stacked) ───────────────────────────────
# Adventure y=146 h=70 | Chronicle y=222 h=60 | Simulation y=288 h=60
# Arena y=354 w=122 h=68 | Expedition x=1018 w=126 h=68
func _build_content_cards() -> void:
	var rx  : float = 888.0
	var cw  : float = 256.0   # card width
	var iw  : float = 240.0   # inner width

	# ── Adventure ────────────────────────────────────────────────────────
	var adv := _card(Rect2(rx, 146, cw, 70), C_CARD2, C_BORDER, 7.0)
	add_child(adv)
	_lbl_at(adv, "Adventure",  16, C_TEXT,   Vector2(10, 8))
	_lbl_at(adv, "MAIN STORY",  9, C_TEXT2,  Vector2(10, 28))
	_lbl_at(adv, "CHAPTER 12-9",8, C_TEXT3,  Vector2(10, 52))
	_lbl_at(adv, "▶",          14, C_ACCENT, Vector2(iw - 6, 24))
	# Art thumbnail
	var adv_art := _card(Rect2(130, 4, 100, 62), Color(0.04,0.08,0.22,0.8), Color(0,0,0,0), 5.0)
	adv.add_child(adv_art)
	_lbl_at(adv_art, "💠", 28, C_ACCENT, Vector2(34, 14))
	adv.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed: _goto(SC_BATTLE))
	adv.mouse_filter = Control.MOUSE_FILTER_STOP

	# ── Chronicle ────────────────────────────────────────────────────────
	var chr := _card(Rect2(rx, 222, cw, 60), C_CARD2, C_BORDER, 7.0)
	add_child(chr)
	_lbl_at(chr, "Chronicle",  14, C_TEXT,   Vector2(10, 8))
	_lbl_at(chr, "SIDE STORY",  9, C_TEXT2,  Vector2(10, 26))
	_lbl_at(chr, "▶",          14, C_PURPLE, Vector2(iw - 6, 18))
	var chr_art := _card(Rect2(130, 4, 100, 52), Color(0.08,0.04,0.22,0.8), Color(0,0,0,0), 5.0)
	chr.add_child(chr_art)
	var chr_tex := TextureRect.new()
	chr_tex.position=Vector2(0,0); chr_tex.size=Vector2(100,52)
	chr_tex.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	chr_tex.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chr_tex.texture=PortraitGen.make(Color(0.65,0.35,1.0),100,52)
	chr_tex.mouse_filter=Control.MOUSE_FILTER_IGNORE
	chr_art.add_child(chr_tex)

	# ── Simulation ────────────────────────────────────────────────────────
	var sim := _card(Rect2(rx, 288, cw, 60), C_CARD2, C_BORDER, 7.0)
	add_child(sim)
	_lbl_at(sim, "Simulation",  14, C_TEXT,  Vector2(10, 8))
	_lbl_at(sim, "RESOURCE",     9, C_TEXT2, Vector2(10, 26))
	_lbl_at(sim, "▶",           14, C_GREEN, Vector2(iw - 6, 18))
	var sim_art := _card(Rect2(130, 4, 100, 52), Color(0.03,0.12,0.10,0.8), Color(0,0,0,0), 5.0)
	sim.add_child(sim_art)
	_lbl_at(sim_art, "🔬", 26, C_GREEN, Vector2(34, 10))

	# ── Arena (x=888, y=354, w=122, h=68) ────────────────────────────────
	var arena := _card(Rect2(rx, 354, 122, 68), C_CARD2, C_BORDER, 7.0)
	add_child(arena)
	_lbl_at(arena, "Arena",    14, C_TEXT,  Vector2(10, 6))
	_lbl_at(arena, "PVP",       9, C_TEXT2, Vector2(10, 24))
	_lbl_at(arena, "💠",       18, C_DIAMOND, Vector2(10, 36))
	_lbl_at(arena, "Diamond I", 9, C_TEXT2, Vector2(36, 38))
	_lbl_at(arena, "3200/3500", 8, C_TEXT3, Vector2(36, 50))
	_lbl_at(arena, "▶",        12, C_ACCENT, Vector2(104, 26))
	arena.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed: _goto(SC_BATTLE))
	arena.mouse_filter = Control.MOUSE_FILTER_STOP

	# ── Expedition (x=1018, y=354, w=126, h=68) ──────────────────────────
	var exp := _card(Rect2(1018, 354, 126, 68), C_CARD2, C_BORDER, 7.0)
	add_child(exp)
	_lbl_at(exp, "Expedition",  13, C_TEXT,   Vector2(10, 6))
	_lbl_at(exp, "CHALLENGE",    9, C_TEXT2,  Vector2(10, 24))
	var exp_art := _card(Rect2(64, 4, 56, 60), Color(0.06,0.06,0.18,0.8), Color(0,0,0,0), 4.0)
	exp.add_child(exp_art)
	_lbl_at(exp_art, "🤖", 20, C_ORANGE, Vector2(14, 14))
	_lbl_at(exp, "▶", 12, C_ORANGE, Vector2(108, 26))

# ── Domain widget  (x=1016, y=472, w=128, h=120) — overlaps above nav ────────
func _build_domain() -> void:
	# Outer ring decoration
	var ring := ColorRect.new()
	ring.position   = Vector2(1010, 468)
	ring.size       = Vector2(134, 134)
	ring.color      = Color(0, 0, 0, 0)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ring)

	# Main domain card
	var dom := _card(Rect2(1016, 474, 120, 116), Color(0.04,0.08,0.22,0.92), C_ACCENT, 60.0)
	add_child(dom)

	_lbl_at(dom, "🛡",            22, C_ACCENT, Vector2(38, 12))
	_lbl_at(dom, "Domain",        13, C_TEXT,   Vector2(22, 44))
	_lbl_at(dom, "BONUS REWARD",   7, C_TEXT2,  Vector2(14, 62))

	# 100% circle indicator (using a colored arc via concentric panels)
	var circ_bg := _card(Rect2(14, 74, 92, 34), Color(0,0,0,0.5), C_GOLD, 17.0)
	dom.add_child(circ_bg)
	_lbl_at(circ_bg, "100%", 12, C_GOLD, Vector2(24, 8))

# ── Chat bar  (y=566, h=26) ──────────────────────────────────────────────────
func _build_chat() -> void:
	var bar := ColorRect.new()
	bar.position   = Vector2(0, 566)
	bar.size       = Vector2(980, 26)
	bar.color      = Color(0.03, 0.06, 0.16, 0.88)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	var sep := ColorRect.new()
	sep.position = Vector2(0,0); sep.size = Vector2(980, 1); sep.color = C_BDR2
	bar.add_child(sep)

	_lbl_at(bar, "💬", 12, C_ACCENT, Vector2(8, 5))
	_lbl_at(bar, "[World] Alchemist : สวัสดีทุกคน!", 10, C_TEXT2, Vector2(28, 6))

# ── Bottom nav  (y=592, h=56) ────────────────────────────────────────────────
func _build_bottom_nav() -> void:
	var bar := ColorRect.new()
	bar.position   = Vector2(0, 592)
	bar.size       = Vector2(W, 56)
	bar.color      = Color(0.02, 0.05, 0.14, 0.94)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	var sep := ColorRect.new()
	sep.position = Vector2(0,0); sep.size = Vector2(W, 1); sep.color = C_BORDER
	bar.add_child(sep)

	# 7 nav items, evenly spaced. Domain overlaps right corner so nav items end ~x=1000
	var nav : Array = [
		["⚗",  "Alchemist", true,  SC_CHARACTER],
		["⚔",  "Lineup",    false, SC_LINEUP   ],
		["🔮", "Arcanum",   false, ""          ],
		["🎒", "Inventory", false, SC_INVENTORY],
		["📖", "Database",  false, ""          ],
		["🛡",  "Guild",     false, ""          ],
		["📚", "Archive",   false, ""          ],
	]
	var item_w : float = W / nav.size()
	for i in range(nav.size()):
		var item   : Array = nav[i]
		var active : bool  = item[2]
		var nx     : float = item_w * i

		if active:
			var hi := ColorRect.new()
			hi.position = Vector2(nx, 0); hi.size = Vector2(item_w, 56)
			hi.color    = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.12)
			hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bar.add_child(hi)
			var tl := ColorRect.new()
			tl.position = Vector2(nx, 0); tl.size = Vector2(item_w, 2)
			tl.color    = C_ACCENT
			bar.add_child(tl)

		# Notification badge (Alchemist + Missions example)
		if i == 0 or i == 3:
			var nb := ColorRect.new()
			nb.position = Vector2(nx + item_w*0.5 + 8, 6); nb.size = Vector2(8, 8)
			nb.color    = C_RED
			bar.add_child(nb)

		var ic := _lbl(item[0], 20, C_ACCENT if active else C_TEXT2)
		ic.position = Vector2(nx, 6); ic.size = Vector2(item_w, 26)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar.add_child(ic)

		var tx := _lbl(item[1], 9, C_ACCENT if active else C_TEXT3)
		tx.position = Vector2(nx, 32); tx.size = Vector2(item_w, 14)
		tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar.add_child(tx)

		var sp : String = item[3]
		if sp != "" and not active:
			var btn := Button.new()
			btn.position = Vector2(nx, 0); btn.size = Vector2(item_w, 56)
			_apply_style(btn, Color(0,0,0,0), Color(0,0,0,0), 0.0)
			btn.pressed.connect(func(): _goto(sp))
			bar.add_child(btn)

# ── Toggle ♀/♂ ───────────────────────────────────────────────────────────────
func _on_toggle_char() -> void:
	_show_female       = not _show_female
	_char_female.visible = _show_female
	_char_male.visible   = not _show_female

# ── Scene transition ──────────────────────────────────────────────────────────
func _goto(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0); overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var t := create_tween()
	t.tween_property(overlay, "color:a", 1.0, 0.28)
	await t.finished
	get_tree().change_scene_to_file(path)

# ── Helpers ───────────────────────────────────────────────────────────────────
func _card(rect: Rect2, fill: Color, border: Color, radius: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = rect.position; p.size = rect.size
	_apply_style(p, fill, border, radius); return p

func _apply_style(node: Control, fill: Color, border: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(int(radius))
	node.add_theme_stylebox_override("panel", sb)

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; return l

func _lbl_at(parent: Control, text: String, size: int, color: Color, pos: Vector2) -> Label:
	var l := _lbl(text, size, color); l.position = pos; parent.add_child(l); return l

# Rough pixel width estimate for a string at given font size
func _str_px(s: String, size: int) -> float:
	return s.length() * size * 0.62

var C_TEAL := Color(0.10, 0.80, 0.75, 1.00)
