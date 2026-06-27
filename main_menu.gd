extends Control

# ── Layout constants ──────────────────────────────────────────────────────────
const W       : float = 1152.0
const H       : float = 648.0
const TOP_H   : float = 50.0
const BOT_H   : float = 72.0
const CHAT_H  : float = 30.0
const L_W     : float = 220.0
const R_W     : float = 310.0

# ── Colours ───────────────────────────────────────────────────────────────────
const C_BG      := Color(0.03, 0.06, 0.16, 1.0)
const C_PANEL   := Color(0.05, 0.10, 0.22, 0.92)
const C_PANEL2  := Color(0.07, 0.13, 0.28, 0.95)
const C_PANEL3  := Color(0.04, 0.08, 0.20, 0.98)
const C_BORDER  := Color(0.15, 0.45, 0.85, 0.55)
const C_BORDER2 := Color(0.20, 0.60, 1.00, 0.35)
const C_TEXT    := Color(0.80, 0.92, 1.00, 1.0)
const C_TEXT2   := Color(0.55, 0.75, 1.00, 1.0)
const C_ACCENT  := Color(0.20, 0.70, 1.00, 1.0)
const C_GOLD    := Color(1.00, 0.82, 0.30, 1.0)
const C_PURPLE  := Color(0.65, 0.35, 1.00, 1.0)
const C_RED     := Color(1.00, 0.30, 0.30, 1.0)
const C_GREEN   := Color(0.30, 1.00, 0.55, 1.0)
const C_ORANGE  := Color(1.00, 0.60, 0.15, 1.0)
const C_DARK    := Color(0.02, 0.04, 0.12, 1.0)

# ── Character toggle state ────────────────────────────────────────────────────
var _show_female : bool = true
var _char_female : TextureRect
var _char_male   : TextureRect
var _toggle_btn  : Button

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_add_bg()
	_build_top_bar()
	_build_left_panel()
	_build_char_area()
	_build_right_panel()
	_build_chat_bar()
	_build_bottom_nav()
	_build_domain()

# ── Background ────────────────────────────────────────────────────────────────
func _add_bg() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	add_child(bg)

	# subtle grid lines
	var grid := ColorRect.new()
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.color = Color(0, 0, 0, 0)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grid)

# ── Top bar ───────────────────────────────────────────────────────────────────
func _build_top_bar() -> void:
	var bar := _panel(Rect2(0, 0, W, TOP_H), C_PANEL3, C_BORDER, 0.0)
	add_child(bar)

	# Separator line bottom
	var sep := ColorRect.new()
	sep.position = Vector2(0, TOP_H - 1)
	sep.size     = Vector2(W, 1)
	sep.color    = C_BORDER
	bar.add_child(sep)

	# ── Currency cluster (left of center) ─────────────────────────────────
	var currencies := [
		["✦", "12,450",      C_GOLD],
		["◉", "2,840,530",   C_ACCENT],
		["◈", "18,760",      C_PURPLE],
		["⚡", "240/240",    C_GREEN],
	]
	var cx : float = 12.0
	for cur in currencies:
		var icon := _lbl(cur[0], 14, cur[2])
		icon.position = Vector2(cx, 8)
		bar.add_child(icon)
		cx += 20.0

		var amt := _lbl(cur[1], 13, C_TEXT)
		amt.position = Vector2(cx, 9)
		bar.add_child(amt)
		cx += amt.text.length() * 8.0 + 20.0

		var divider := ColorRect.new()
		divider.position = Vector2(cx, 10)
		divider.size     = Vector2(1, 28)
		divider.color    = C_BORDER2
		bar.add_child(divider)
		cx += 14.0

	# ── Right icon buttons ────────────────────────────────────────────────
	var icons := ["⚙", "✉", "🔔", "≡"]
	var bx    : float = W - 16.0
	for ic in icons:
		var btn := _icon_btn(ic, 28)
		btn.position = Vector2(bx - 28, 11)
		bar.add_child(btn)
		bx -= 36.0

# ── Left panel ────────────────────────────────────────────────────────────────
func _build_left_panel() -> void:
	var content_h : float = H - TOP_H - BOT_H - CHAT_H
	var panel := _panel(Rect2(0, TOP_H, L_W, content_h + CHAT_H), C_PANEL, C_BORDER, 0.0)
	add_child(panel)

	var y : float = 8.0

	# ── Profile card ──────────────────────────────────────────────────────
	var prof := _panel(Rect2(8, y, L_W - 16, 76), C_PANEL2, C_BORDER, 6.0)
	panel.add_child(prof)

	# Avatar placeholder
	var av := _panel(Rect2(8, 8, 52, 52), C_PANEL3, C_ACCENT, 4.0)
	prof.add_child(av)
	var av_lbl := _lbl("👤", 22, C_ACCENT)
	av_lbl.position = Vector2(12, 10)
	av.add_child(av_lbl)

	# Level badge on avatar
	var lv_bg := _panel(Rect2(6, 50, 40, 14), C_DARK, C_GOLD, 3.0)
	prof.add_child(lv_bg)
	var lv_lbl := _lbl("Lv. 70", 9, C_GOLD)
	lv_lbl.position = Vector2(4, 1)
	lv_bg.add_child(lv_lbl)

	var name_lbl := _lbl("CHEMIA", 14, C_TEXT)
	name_lbl.position = Vector2(66, 10)
	prof.add_child(name_lbl)

	var uid_lbl := _lbl("UID: 100012345", 10, C_TEXT2)
	uid_lbl.position = Vector2(66, 28)
	prof.add_child(uid_lbl)

	# Tiny exp bar
	var exp_bg := _panel(Rect2(66, 46, 136, 8), C_DARK, C_BORDER2, 3.0)
	prof.add_child(exp_bg)
	var exp_fill := ColorRect.new()
	exp_fill.position = Vector2(1, 1)
	exp_fill.size     = Vector2(90, 6)
	exp_fill.color    = C_ACCENT
	exp_bg.add_child(exp_fill)

	y += 84.0

	# ── Menu items ────────────────────────────────────────────────────────
	var menu_items := [
		["🏠", "HOME",          true ],
		["👤", "CHARACTER",     false],
		["🎒", "INVENTORY",     false],
		["📖", "CODEX",         false],
		["🏆", "ACHIEVEMENTS",  false],
		["🛒", "SHOP",          false],
	]
	for item in menu_items:
		var active : bool = item[2]
		var mc := C_PANEL2 if not active else Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.18)
		var mb := C_BORDER if not active else C_ACCENT
		var mi := _panel(Rect2(8, y, L_W - 16, 34), mc, mb, 5.0)
		panel.add_child(mi)

		var icon_l := _lbl(item[0], 14, C_ACCENT if active else C_TEXT2)
		icon_l.position = Vector2(10, 8)
		mi.add_child(icon_l)

		var name_l := _lbl(item[1], 12, C_TEXT if active else C_TEXT2)
		name_l.position = Vector2(34, 10)
		mi.add_child(name_l)

		if active:
			var dot := ColorRect.new()
			dot.position = Vector2(L_W - 24, 10)
			dot.size     = Vector2(4, 14)
			dot.color    = C_ACCENT
			mi.add_child(dot)

		y += 38.0

	y += 4.0

	# ── Event banner ──────────────────────────────────────────────────────
	var ev := _panel(Rect2(8, y, L_W - 16, 50), Color(0.25, 0.08, 0.40, 0.90), C_PURPLE, 6.0)
	panel.add_child(ev)

	var ev_tag := _panel(Rect2(8, 6, 54, 14), Color(0.50, 0.10, 0.75, 1.0), Color(0,0,0,0), 3.0)
	ev.add_child(ev_tag)
	var ev_tag_lbl := _lbl("LIMITED", 8, Color(1,1,1,1))
	ev_tag_lbl.position = Vector2(4, 2)
	ev_tag.add_child(ev_tag_lbl)

	var ev_title := _lbl("STARFALL INVOCATION", 11, C_PURPLE)
	ev_title.position = Vector2(8, 22)
	ev.add_child(ev_title)

	var ev_sub := _lbl("Ends in 5d 12h 30m", 9, C_TEXT2)
	ev_sub.position = Vector2(8, 36)
	ev.add_child(ev_sub)

# ── Center character area ──────────────────────────────────────────────────────
func _build_char_area() -> void:
	var cx    : float = L_W
	var cw    : float = W - L_W - R_W
	var cy    : float = TOP_H
	var ch    : float = H - TOP_H - BOT_H - CHAT_H

	# Dark backdrop for character stage
	var stage := ColorRect.new()
	stage.position   = Vector2(cx, cy)
	stage.size       = Vector2(cw, ch)
	stage.color      = Color(0.02, 0.05, 0.14, 0.60)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)

	# Bottom glow under character
	var glow := ColorRect.new()
	glow.position = Vector2(cx, cy + ch - 60)
	glow.size     = Vector2(cw, 60)
	glow.color    = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.08)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	# ── Female character slot ─────────────────────────────────────────────
	_char_female = TextureRect.new()
	_char_female.name         = "FemaleCharacter"
	_char_female.position     = Vector2(cx + cw * 0.5 - 160, cy + 10)
	_char_female.size         = Vector2(320, ch - 30)
	_char_female.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_char_female.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_female.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_char_female)

	# Female placeholder (shown when no texture)
	var f_ph := _panel(Rect2(cx + cw * 0.5 - 80, cy + ch * 0.5 - 100, 160, 200),
						Color(0.08, 0.15, 0.30, 0.60), C_BORDER2, 8.0)
	add_child(f_ph)
	var f_ph_lbl := _lbl("♀\nCHARACTER\n(drag texture here)", 11, C_TEXT2)
	f_ph_lbl.position                                        = Vector2(10, 60)
	f_ph_lbl.autowrap_mode                                   = TextServer.AUTOWRAP_WORD
	f_ph_lbl.horizontal_alignment                            = HORIZONTAL_ALIGNMENT_CENTER
	f_ph_lbl.size                                            = Vector2(140, 100)
	f_ph.add_child(f_ph_lbl)
	_char_female.set_meta("placeholder", f_ph)

	# ── Male character slot ───────────────────────────────────────────────
	_char_male = TextureRect.new()
	_char_male.name         = "MaleCharacter"
	_char_male.position     = Vector2(cx + cw * 0.5 - 160, cy + 10)
	_char_male.size         = Vector2(320, ch - 30)
	_char_male.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_char_male.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_male.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_male.visible      = false
	add_child(_char_male)

	var m_ph := _panel(Rect2(cx + cw * 0.5 - 80, cy + ch * 0.5 - 100, 160, 200),
						Color(0.08, 0.15, 0.30, 0.60), C_BORDER2, 8.0)
	m_ph.visible = false
	add_child(m_ph)
	var m_ph_lbl := _lbl("♂\nCHARACTER\n(drag texture here)", 11, C_TEXT2)
	m_ph_lbl.position              = Vector2(10, 60)
	m_ph_lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD
	m_ph_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	m_ph_lbl.size                  = Vector2(140, 100)
	m_ph.add_child(m_ph_lbl)
	_char_male.set_meta("placeholder", m_ph)

	# ── Toggle button ♀ / ♂ ──────────────────────────────────────────────
	_toggle_btn = Button.new()
	_toggle_btn.text     = "♀"
	_toggle_btn.position = Vector2(cx + cw - 52, cy + 8)
	_toggle_btn.size     = Vector2(44, 44)
	_toggle_btn.add_theme_color_override("font_color",        C_ACCENT)
	_toggle_btn.add_theme_color_override("font_hover_color",  C_TEXT)
	_toggle_btn.add_theme_font_size_override("font_size", 20)
	_apply_panel_style(_toggle_btn, C_PANEL2, C_ACCENT, 6.0)
	_toggle_btn.pressed.connect(_on_toggle_char)
	add_child(_toggle_btn)

	# Character name plate bottom-center
	var name_bg := _panel(Rect2(cx + cw * 0.5 - 90, cy + ch - 28, 180, 24),
							C_PANEL3, C_BORDER, 5.0)
	add_child(name_bg)
	var name_lbl := _lbl("◇  SELECT CHARACTER  ◇", 10, C_TEXT2)
	name_lbl.position              = Vector2(8, 4)
	name_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.size                  = Vector2(164, 16)
	name_bg.add_child(name_lbl)

# ── Right panel ───────────────────────────────────────────────────────────────
func _build_right_panel() -> void:
	var rx    : float = W - R_W
	var ry    : float = TOP_H
	var rh    : float = H - TOP_H - BOT_H - CHAT_H
	var panel := _panel(Rect2(rx, ry, R_W, rh), C_PANEL, C_BORDER, 0.0)
	add_child(panel)

	var y : float = 8.0

	# ── NEW CHARACTER card ────────────────────────────────────────────────
	var new_card := _panel(Rect2(8, y, R_W - 16, 90), Color(0.06, 0.12, 0.28, 0.95), C_GOLD, 7.0)
	panel.add_child(new_card)

	var nc_badge := _panel(Rect2(8, 6, 42, 14), Color(0.75, 0.55, 0.0, 1.0), Color(0,0,0,0), 3.0)
	new_card.add_child(nc_badge)
	var nc_badge_lbl := _lbl("NEW", 8, Color(0,0,0,1))
	nc_badge_lbl.position = Vector2(8, 2)
	nc_badge.add_child(nc_badge_lbl)

	var nc_art := _panel(Rect2(R_W - 88, 6, 72, 78), C_PANEL3, C_GOLD, 5.0)
	new_card.add_child(nc_art)
	var nc_art_lbl := _lbl("★", 28, C_GOLD)
	nc_art_lbl.position = Vector2(18, 18)
	nc_art.add_child(nc_art_lbl)

	var nc_name := _lbl("LUXIA", 16, C_GOLD)
	nc_name.position = Vector2(10, 22)
	new_card.add_child(nc_name)

	var nc_sub := _lbl("Element: ✦ LIGHT\nRarity: ★★★★★", 10, C_TEXT2)
	nc_sub.position = Vector2(10, 42)
	new_card.add_child(nc_sub)

	y += 98.0

	# ── Content cards ─────────────────────────────────────────────────────
	var cards := [
		["⚔", "ADVENTURE",    "Explore the world",   C_ACCENT,  C_PANEL2],
		["📜", "CHRONICLE",    "Story missions",       C_PURPLE,  C_PANEL2],
		["🔬", "SIMULATION",   "Lab challenges",       C_GREEN,   C_PANEL2],
	]
	for card in cards:
		var cc := _panel(Rect2(8, y, R_W - 16, 44), card[4], card[3], 6.0)
		panel.add_child(cc)

		var ic := _lbl(card[0], 18, card[3])
		ic.position = Vector2(10, 11)
		cc.add_child(ic)

		var title := _lbl(card[1], 13, C_TEXT)
		title.position = Vector2(38, 6)
		cc.add_child(title)

		var sub := _lbl(card[2], 10, C_TEXT2)
		sub.position = Vector2(38, 22)
		cc.add_child(sub)

		var arr := _lbl("▶", 12, card[3])
		arr.position = Vector2(R_W - 34, 15)
		cc.add_child(arr)

		y += 50.0

	# ── Arena + Expedition side-by-side ───────────────────────────────────
	var half : float = (R_W - 20) * 0.5
	var side_cards := [
		["⚔\nARENA",        C_RED,    0.0],
		["🗺\nEXPEDITION",  C_ORANGE, half + 12.0],
	]
	for sc in side_cards:
		var scr := _panel(Rect2(8 + sc[2], y, half, 52), C_PANEL2,
							sc[1] if sc[2] == 0.0 else sc[1], 6.0)
		panel.add_child(scr)
		var sc_lbl := _lbl(sc[0], 11, sc[1])
		sc_lbl.position              = Vector2(8, 6)
		sc_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		sc_lbl.size                  = Vector2(half - 16, 40)
		scr.add_child(sc_lbl)

# ── Chat bar ──────────────────────────────────────────────────────────────────
func _build_chat_bar() -> void:
	var cy : float = H - BOT_H - CHAT_H
	var bar := _panel(Rect2(L_W, cy, W - L_W - R_W, CHAT_H), C_PANEL3, C_BORDER2, 0.0)
	add_child(bar)

	var chat_lbl := _lbl("💬  [World]  alchemy_master: Fire + Water = Steam? No way! 🔥", 10, C_TEXT2)
	chat_lbl.position = Vector2(10, 7)
	bar.add_child(chat_lbl)

# ── Bottom nav ────────────────────────────────────────────────────────────────
func _build_bottom_nav() -> void:
	var bar := _panel(Rect2(0, H - BOT_H, W, BOT_H), C_PANEL3, C_BORDER, 0.0)
	add_child(bar)

	# Top separator line
	var sep := ColorRect.new()
	sep.position = Vector2(0, 0)
	sep.size     = Vector2(W, 1)
	sep.color    = C_BORDER
	bar.add_child(sep)

	var nav_items := [
		["🏠", "HOME",      true ],
		["⚔",  "BATTLE",    false],
		["🌍", "WORLD",     false],
		["🔬", "LAB",       false],
		["🏆", "RANKING",   false],
		["🛒", "SHOP",      false],
		["👥", "FRIENDS",   false],
	]
	var item_w : float = W / nav_items.size()
	for i in range(nav_items.size()):
		var item  : Array = nav_items[i]
		var active: bool  = item[2]
		var nx    : float = item_w * i
		var nc    := Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.15) if active else Color(0,0,0,0)
		var nb    := C_BORDER if not active else C_ACCENT

		if active:
			var hi := _panel(Rect2(nx, 0, item_w, BOT_H), nc, Color(0,0,0,0), 0.0)
			bar.add_child(hi)
			var top_line := ColorRect.new()
			top_line.position = Vector2(nx, 0)
			top_line.size     = Vector2(item_w, 2)
			top_line.color    = C_ACCENT
			bar.add_child(top_line)

		var ic_lbl := _lbl(item[0], 18, C_ACCENT if active else C_TEXT2)
		ic_lbl.position              = Vector2(nx, 8)
		ic_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		ic_lbl.size                  = Vector2(item_w, 24)
		bar.add_child(ic_lbl)

		var tx_lbl := _lbl(item[1], 9, C_ACCENT if active else C_TEXT2)
		tx_lbl.position              = Vector2(nx, 32)
		tx_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
		tx_lbl.size                  = Vector2(item_w, 16)
		bar.add_child(tx_lbl)

# ── Domain widget (bottom-right) ──────────────────────────────────────────────
func _build_domain() -> void:
	var dw : float = 180.0
	var dh : float = 54.0
	var widget := _panel(Rect2(W - dw - 8, H - BOT_H - dh - 8, dw, dh),
							Color(0.05, 0.10, 0.24, 0.95), C_PURPLE, 7.0)
	add_child(widget)

	var d_title := _lbl("◈ DOMAIN", 10, C_PURPLE)
	d_title.position = Vector2(10, 6)
	widget.add_child(d_title)

	var d_name := _lbl("Alchemy Realm  Lv.12", 12, C_TEXT)
	d_name.position = Vector2(10, 20)
	widget.add_child(d_name)

	var d_bar_bg := _panel(Rect2(10, 38, dw - 20, 8), C_DARK, C_BORDER2, 3.0)
	widget.add_child(d_bar_bg)
	var d_fill := ColorRect.new()
	d_fill.position = Vector2(1, 1)
	d_fill.size     = Vector2(100, 6)
	d_fill.color    = C_PURPLE
	d_bar_bg.add_child(d_fill)

# ── Toggle character ──────────────────────────────────────────────────────────
func _on_toggle_char() -> void:
	_show_female = not _show_female
	_toggle_btn.text  = "♀" if _show_female else "♂"
	_char_female.visible = _show_female
	_char_male.visible   = not _show_female
	var f_ph = _char_female.get_meta("placeholder") as Node
	var m_ph = _char_male.get_meta("placeholder")   as Node
	if f_ph: f_ph.visible = _show_female
	if m_ph: m_ph.visible = not _show_female

# ── Helpers ───────────────────────────────────────────────────────────────────
func _panel(rect: Rect2, fill: Color, border: Color, radius: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = rect.position
	p.size     = rect.size
	_apply_panel_style(p, fill, border, radius)
	return p


func _apply_panel_style(node: Control, fill: Color, border: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color            = fill
	sb.border_color        = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(int(radius))
	node.add_theme_stylebox_override("panel", sb)


func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _icon_btn(icon: String, sz: int) -> Button:
	var b := Button.new()
	b.text = icon
	b.size = Vector2(sz, sz)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", C_TEXT2)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(0)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover",  sb)
	b.add_theme_stylebox_override("pressed", sb)
	return b
