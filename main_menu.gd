extends Control

# ── Layout ────────────────────────────────────────────────────────────────────
const W      : float = 1152.0
const H      : float = 648.0
const TOP_H  : float = 52.0
const BOT_H  : float = 70.0
const CHAT_H : float = 28.0
const L_W    : float = 210.0
const R_W    : float = 300.0

# ── Colours ───────────────────────────────────────────────────────────────────
const C_BG     := Color(0.03, 0.06, 0.16, 1.0)
const C_PANEL  := Color(0.05, 0.10, 0.22, 0.93)
const C_PANEL2 := Color(0.07, 0.13, 0.28, 0.96)
const C_DARK   := Color(0.02, 0.04, 0.12, 1.0)
const C_BORDER := Color(0.15, 0.45, 0.85, 0.55)
const C_BDR2   := Color(0.20, 0.60, 1.00, 0.30)
const C_TEXT   := Color(0.82, 0.93, 1.00, 1.0)
const C_TEXT2  := Color(0.55, 0.75, 1.00, 1.0)
const C_ACCENT := Color(0.20, 0.70, 1.00, 1.0)
const C_GOLD   := Color(1.00, 0.82, 0.30, 1.0)
const C_PURPLE := Color(0.65, 0.35, 1.00, 1.0)
const C_RED    := Color(1.00, 0.32, 0.32, 1.0)
const C_GREEN  := Color(0.28, 1.00, 0.55, 1.0)
const C_ORANGE := Color(1.00, 0.60, 0.16, 1.0)
const C_TEAL   := Color(0.10, 0.80, 0.75, 1.0)

# ── Scenes ────────────────────────────────────────────────────────────────────
const SCENE_BATTLE    := "res://battle_scene.tscn"
const SCENE_SUMMON    := "res://summon.tscn"
const SCENE_CHARACTER := "res://character.tscn"
const SCENE_LINEUP    := "res://lineup.tscn"
const SCENE_INVENTORY := "res://inventory.tscn"

# ── Character toggle ──────────────────────────────────────────────────────────
var _show_female : bool = true
var _char_female : TextureRect
var _char_male   : TextureRect
var _toggle_btn  : Button
var _chat_tab    : int  = 0   # 0=World 1=Guild 2=Friend

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_add_bg()
	_build_top_bar()
	_build_left_panel()
	_build_char_area()
	_build_right_panel()
	_build_chat_bar()
	_build_bottom_nav()

# ── Background ────────────────────────────────────────────────────────────────
func _add_bg() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color        = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

# ── Top bar ───────────────────────────────────────────────────────────────────
func _build_top_bar() -> void:
	var bar := _panel(Rect2(0, 0, W, TOP_H), Color(0.03, 0.07, 0.18, 0.98), C_BORDER, 0.0)
	add_child(bar)
	_hline(bar, Vector2(0, TOP_H - 1), W, C_BORDER)

	# Currencies
	var cur_data : Array = [
		["💎", "Crystal",      "8,500",    C_ACCENT],
		["🪙", "Gold",         "1,240,000",C_GOLD  ],
		["⚗",  "Alchemy Core", "3,820",    C_TEAL  ],
		["⚡",  "Energy",       "120/120",  C_GREEN ],
	]
	var cx : float = 12.0
	for cur : Array in cur_data:
		var ic := _lbl(cur[0], 15, cur[3])
		ic.position = Vector2(cx, 9)
		bar.add_child(ic)
		cx += 22.0

		var val := _lbl(cur[2], 12, C_TEXT)
		val.position = Vector2(cx, 11)
		bar.add_child(val)
		cx += cur[2].length() * 7.5 + 16.0

		var div := ColorRect.new()
		div.position = Vector2(cx, 10); div.size = Vector2(1, 30); div.color = C_BDR2
		bar.add_child(div)
		cx += 12.0

	# Right buttons: Mail / Friends / Settings
	var rbtn_data : Array = [["✉ Mail", C_ACCENT], ["👥 Friends", C_TEXT2], ["⚙ Settings", C_TEXT2]]
	var bx : float = W - 10.0
	for rb : Array in rbtn_data:
		var b := _text_btn(rb[0], 11, rb[1], Rect2(0, 0, 90, 30))
		bx -= 94.0
		b.position = Vector2(bx, 10)
		bar.add_child(b)

# ── Left panel ────────────────────────────────────────────────────────────────
func _build_left_panel() -> void:
	var ph   : float = H - TOP_H - BOT_H - CHAT_H
	var panel := _panel(Rect2(0, TOP_H, L_W, ph + CHAT_H), Color(0.04, 0.08, 0.20, 0.95), C_BORDER, 0.0)
	add_child(panel)
	_vline(panel, Vector2(L_W - 1, 0), ph + CHAT_H, C_BORDER)

	var y : float = 8.0

	# ── Profile card ──────────────────────────────────────────────────────
	var prof := _panel(Rect2(8, y, L_W - 16, 72), C_PANEL2, C_BORDER, 6.0)
	panel.add_child(prof)

	# Avatar button
	var av_btn := Button.new()
	av_btn.position = Vector2(8, 8); av_btn.size = Vector2(48, 48)
	av_btn.text = "👤"
	av_btn.add_theme_font_size_override("font_size", 20)
	_apply_style(av_btn, C_DARK, C_ACCENT, 5.0)
	prof.add_child(av_btn)

	# Lv badge
	var lv_bg := _panel(Rect2(7, 48, 50, 14), Color(0.0, 0.0, 0.0, 0.85), C_GOLD, 3.0)
	prof.add_child(lv_bg)
	_lbl_at(lv_bg, "Lv. 70", 9, C_GOLD, Vector2(5, 2))

	_lbl_at(prof, "CHEMIA",       14, C_TEXT,  Vector2(62, 8))
	_lbl_at(prof, "UID: 100012345", 9, C_TEXT2, Vector2(62, 26))

	# Energy mini bar
	var eb := _panel(Rect2(62, 44, 120, 8), C_DARK, C_BDR2, 3.0)
	prof.add_child(eb)
	var ef := ColorRect.new(); ef.position = Vector2(1,1); ef.size = Vector2(120*120.0/120.0 - 2, 6); ef.color = C_GREEN
	eb.add_child(ef)
	_lbl_at(prof, "⚡ 120/120", 8, C_GREEN, Vector2(62, 55))

	y += 80.0

	# ── Left menu items ───────────────────────────────────────────────────
	var menu_items : Array = [
		["📢", "Notice",        C_ACCENT, false],
		["📋", "Missions",      C_GOLD,   false],
		["🎉", "Event",         C_ORANGE, false],
		["🎫", "Pass",          C_PURPLE, false],
		["🛒", "Shop",          C_TEAL,   false],
		["🎁", "First Purchase",C_RED,    false],
	]
	for mi : Array in menu_items:
		var row := _panel(Rect2(8, y, L_W - 16, 32), C_PANEL2, C_BDR2, 5.0)
		panel.add_child(row)
		_lbl_at(row, mi[0], 13, mi[2], Vector2(9, 7))
		_lbl_at(row, mi[1], 11, C_TEXT, Vector2(32, 9))
		_lbl_at(row, "▶",   10, mi[2],  Vector2(L_W - 36, 9))
		y += 36.0

	y += 4.0

	# ── Event Banner ──────────────────────────────────────────────────────
	var ev := _panel(Rect2(8, y, L_W - 16, 48),
					  Color(0.22, 0.06, 0.38, 0.92), C_PURPLE, 7.0)
	panel.add_child(ev)
	var ev_badge := _panel(Rect2(8, 5, 52, 13), Color(0.5, 0.08, 0.75, 1), Color(0,0,0,0), 3.0)
	ev.add_child(ev_badge)
	_lbl_at(ev_badge, "EVENT", 8, Color(1,1,1,1), Vector2(6, 2))
	_lbl_at(ev, "STARFALL INVOCATION", 10, C_PURPLE, Vector2(8, 20))
	_lbl_at(ev, "Ends 5d 12h 30m",      9, C_TEXT2,  Vector2(8, 34))

# ── Center character area ──────────────────────────────────────────────────────
func _build_char_area() -> void:
	var cx : float = L_W
	var cw : float = W - L_W - R_W
	var cy : float = TOP_H
	var ch : float = H - TOP_H - BOT_H - CHAT_H

	var bg := ColorRect.new()
	bg.position   = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color      = Color(0.02, 0.04, 0.14, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Bottom stage glow
	var gl := ColorRect.new()
	gl.position   = Vector2(cx, cy + ch - 55); gl.size = Vector2(cw, 55)
	gl.color      = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.07)
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gl)

	# Female character slot
	_char_female = TextureRect.new()
	_char_female.name = "FemaleCharacter"
	_char_female.position    = Vector2(cx + cw * 0.5 - 150, cy + 8)
	_char_female.size        = Vector2(300, ch - 24)
	_char_female.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_char_female.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_female.mouse_filter= Control.MOUSE_FILTER_IGNORE
	add_child(_char_female)

	var f_ph := _panel(Rect2(cx + cw*0.5 - 72, cy + ch*0.5 - 90, 144, 180),
						Color(0.07, 0.14, 0.28, 0.55), C_BDR2, 8.0)
	add_child(f_ph)
	var f_t := _lbl("♀\n\nCHARACTER\n(ใส่ texture\nในEditor)", 10, C_TEXT2)
	f_t.position = Vector2(10, 30); f_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_t.size = Vector2(124, 130); f_t.autowrap_mode = TextServer.AUTOWRAP_WORD
	f_ph.add_child(f_t)
	_char_female.set_meta("ph", f_ph)

	# Male character slot
	_char_male = TextureRect.new()
	_char_male.name = "MaleCharacter"
	_char_male.position    = Vector2(cx + cw * 0.5 - 150, cy + 8)
	_char_male.size        = Vector2(300, ch - 24)
	_char_male.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_char_male.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_male.mouse_filter= Control.MOUSE_FILTER_IGNORE
	_char_male.visible     = false
	add_child(_char_male)

	var m_ph := _panel(Rect2(cx + cw*0.5 - 72, cy + ch*0.5 - 90, 144, 180),
						Color(0.07, 0.14, 0.28, 0.55), C_BDR2, 8.0)
	m_ph.visible = false
	add_child(m_ph)
	var m_t := _lbl("♂\n\nCHARACTER\n(ใส่ texture\nในEditor)", 10, C_TEXT2)
	m_t.position = Vector2(10, 30); m_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_t.size = Vector2(124, 130); m_t.autowrap_mode = TextServer.AUTOWRAP_WORD
	m_ph.add_child(m_t)
	_char_male.set_meta("ph", m_ph)

	# Toggle ♀/♂
	_toggle_btn = Button.new()
	_toggle_btn.text = "♀"; _toggle_btn.size = Vector2(40, 40)
	_toggle_btn.position = Vector2(cx + cw - 48, cy + 8)
	_toggle_btn.add_theme_font_size_override("font_size", 18)
	_toggle_btn.add_theme_color_override("font_color", C_ACCENT)
	_apply_style(_toggle_btn, C_PANEL2, C_ACCENT, 6.0)
	_toggle_btn.pressed.connect(_on_toggle_char)
	add_child(_toggle_btn)

	# Name plate
	var np := _panel(Rect2(cx + cw*0.5 - 85, cy + ch - 24, 170, 20), C_DARK, C_BORDER, 5.0)
	add_child(np)
	_lbl_at(np, "◇  SELECT CHARACTER  ◇", 9, C_TEXT2, Vector2(0, 4)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	(np.get_child(np.get_child_count()-1) as Label).size = Vector2(170, 12)

# ── Right panel ────────────────────────────────────────────────────────────────
func _build_right_panel() -> void:
	var rx : float = W - R_W
	var ry : float = TOP_H
	var rh : float = H - TOP_H - BOT_H - CHAT_H
	var panel := _panel(Rect2(rx, ry, R_W, rh), Color(0.04, 0.08, 0.20, 0.95), C_BORDER, 0.0)
	add_child(panel)
	_vline(panel, Vector2(0, 0), rh, C_BORDER)

	var y : float = 8.0

	# ── Gacha Banner ──────────────────────────────────────────────────────
	var banner := _panel(Rect2(8, y, R_W - 16, 88), Color(0.18, 0.05, 0.30, 0.95), C_PURPLE, 7.0)
	panel.add_child(banner)

	var b_badge := _panel(Rect2(8, 6, 62, 14), Color(0.50, 0.08, 0.72, 1), Color(0,0,0,0), 3.0)
	banner.add_child(b_badge)
	_lbl_at(b_badge, "LIMITED", 8, Color(1,1,1,1), Vector2(6, 2))

	var b_art := _panel(Rect2(R_W - 92, 8, 76, 72), Color(0.12, 0.05, 0.25, 0.9), C_PURPLE, 5.0)
	banner.add_child(b_art)
	_lbl_at(b_art, "★", 30, C_GOLD, Vector2(20, 14))

	_lbl_at(banner, "LUXIA  ✦★★★★★",  13, C_GOLD,   Vector2(10, 20))
	_lbl_at(banner, "Element: LIGHT",   10, C_TEXT2,  Vector2(10, 37))
	_lbl_at(banner, "Rate-UP Banner",   9,  C_PURPLE, Vector2(10, 51))

	var summon_btn := _text_btn("✦ SUMMON", 12, C_DARK, Rect2(10, 66, 80, 16))
	_apply_style(summon_btn, C_PURPLE, C_PURPLE, 4.0)
	summon_btn.add_theme_color_override("font_color", Color(1,1,1,1))
	summon_btn.pressed.connect(func(): _goto(SCENE_SUMMON))
	banner.add_child(summon_btn)

	y += 96.0

	# ── Content cards ─────────────────────────────────────────────────────
	var cards : Array = [
		["⚔", "ADVENTURE",    "Main Story  Ch.1–20", C_ACCENT,  SCENE_BATTLE],
		["📜", "CHRONICLE",    "Side Stories",        C_PURPLE,  ""],
		["🔬", "SIMULATION",   "Farm Resources",      C_GREEN,   ""],
	]
	for card : Array in cards:
		var cc := _panel(Rect2(8, y, R_W - 16, 42), C_PANEL2, card[3], 6.0)
		panel.add_child(cc)
		_lbl_at(cc, card[0], 16, card[3], Vector2(9, 10))
		_lbl_at(cc, card[1], 12, C_TEXT,  Vector2(36, 5))
		_lbl_at(cc, card[2], 9,  C_TEXT2, Vector2(36, 21))
		_lbl_at(cc, "▶",     10, card[3], Vector2(R_W - 32, 13))
		var scene_path : String = card[4]
		if scene_path != "":
			cc.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_goto(scene_path))
			cc.mouse_filter = Control.MOUSE_FILTER_STOP
		y += 48.0

	# ── Arena + Expedition ────────────────────────────────────────────────
	var hw : float = (R_W - 20.0) * 0.5
	var side : Array = [
		["⚔\nARENA",       C_RED,    0.0,     SCENE_BATTLE],
		["🗺\nEXPEDITION", C_ORANGE, hw + 12, ""],
	]
	for sc : Array in side:
		var scr := _panel(Rect2(8 + sc[2], y, hw, 50), C_PANEL2, sc[1], 6.0)
		panel.add_child(scr)
		var sl := _lbl(sc[0], 11, sc[1])
		sl.position = Vector2(0, 4); sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.size = Vector2(hw, 40)
		scr.add_child(sl)
		var sp : String = sc[3]
		if sp != "":
			scr.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_goto(sp))
			scr.mouse_filter = Control.MOUSE_FILTER_STOP

	y += 58.0

	# ── Domain ────────────────────────────────────────────────────────────
	var dom := _panel(Rect2(8, y, R_W - 16, 46), Color(0.06, 0.12, 0.28, 0.95), C_TEAL, 6.0)
	panel.add_child(dom)
	var db := _panel(Rect2(8, 6, 46, 14), Color(0.0, 0.3, 0.4, 1), Color(0,0,0,0), 3.0)
	dom.add_child(db)
	_lbl_at(db, "END", 8, C_TEAL, Vector2(6, 2))
	_lbl_at(dom, "◈ DOMAIN", 11, C_TEAL,  Vector2(10, 22))
	_lbl_at(dom, "Boss  •  Raid  •  Weekly", 9, C_TEXT2, Vector2(80, 25))
	_lbl_at(dom, "▶", 10, C_TEAL, Vector2(R_W - 30, 15))

# ── Chat bar ──────────────────────────────────────────────────────────────────
func _build_chat_bar() -> void:
	var cy : float = H - BOT_H - CHAT_H
	var bar := _panel(Rect2(L_W, cy, W - L_W - R_W, CHAT_H),
					   Color(0.03, 0.06, 0.16, 0.95), C_BDR2, 0.0)
	add_child(bar)
	var cw : float = W - L_W - R_W

	# Tab buttons
	var tabs : Array = ["🌍 World", "⚔ Guild", "👥 Friend"]
	var tx : float = 4.0
	for i in range(tabs.size()):
		var tab := Button.new()
		tab.text = tabs[i]; tab.size = Vector2(72, 22); tab.position = Vector2(tx, 3)
		tab.add_theme_font_size_override("font_size", 9)
		var active : bool = (i == _chat_tab)
		tab.add_theme_color_override("font_color", C_ACCENT if active else C_TEXT2)
		_apply_style(tab, Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.18) if active else Color(0,0,0,0),
					 C_ACCENT if active else Color(0,0,0,0), 3.0)
		bar.add_child(tab)
		tx += 76.0

	# Chat sample text
	var ct := _lbl("💬  alchemy_master: Fire + Water = Steam? 🔥", 9, C_TEXT2)
	ct.position = Vector2(235, 6)
	bar.add_child(ct)

# ── Bottom nav ────────────────────────────────────────────────────────────────
func _build_bottom_nav() -> void:
	var bar := _panel(Rect2(0, H - BOT_H, W, BOT_H), Color(0.03, 0.06, 0.18, 0.98), C_BORDER, 0.0)
	add_child(bar)
	_hline(bar, Vector2(0, 0), W, C_BORDER)

	var nav_items : Array = [
		["👤", "Alchemist", true,  SCENE_CHARACTER],
		["⚔",  "Lineup",    false, SCENE_LINEUP   ],
		["⚗",  "Arcanum",   false, ""             ],
		["🎒", "Inventory", false, SCENE_INVENTORY],
		["📖", "Database",  false, ""             ],
		["🛡",  "Guild",     false, ""             ],
		["📚", "Archive",   false, ""             ],
	]
	var iw : float = W / nav_items.size()
	for i in range(nav_items.size()):
		var item   : Array  = nav_items[i]
		var active : bool   = item[2]
		var nx     : float  = iw * i

		if active:
			var hi := ColorRect.new()
			hi.position = Vector2(nx, 0); hi.size = Vector2(iw, BOT_H)
			hi.color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.13)
			hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bar.add_child(hi)
			var tl := ColorRect.new()
			tl.position = Vector2(nx, 0); tl.size = Vector2(iw, 2); tl.color = C_ACCENT
			bar.add_child(tl)

		var ic := _lbl(item[0], 20, C_ACCENT if active else C_TEXT2)
		ic.position = Vector2(nx, 8); ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.size = Vector2(iw, 26)
		bar.add_child(ic)

		var tx := _lbl(item[1], 9, C_ACCENT if active else C_TEXT2)
		tx.position = Vector2(nx, 36); tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tx.size = Vector2(iw, 14)
		bar.add_child(tx)

		# Clickable area
		var scene_path : String = item[3]
		if scene_path != "" and not active:
			var btn := Button.new()
			btn.position = Vector2(nx, 0); btn.size = Vector2(iw, BOT_H)
			_apply_style(btn, Color(0,0,0,0), Color(0,0,0,0), 0.0)
			btn.pressed.connect(func(): _goto(scene_path))
			bar.add_child(btn)

# ── Toggle character ──────────────────────────────────────────────────────────
func _on_toggle_char() -> void:
	_show_female = not _show_female
	_toggle_btn.text = "♀" if _show_female else "♂"
	_char_female.visible = _show_female
	_char_male.visible   = not _show_female
	var f_ph = _char_female.get_meta("ph") as Node
	var m_ph = _char_male.get_meta("ph")   as Node
	if f_ph: f_ph.visible = _show_female
	if m_ph: m_ph.visible = not _show_female

# ── Scene transition ──────────────────────────────────────────────────────────
func _goto(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var t := create_tween()
	var fade := ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color        = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	t.tween_property(fade, "color:a", 1.0, 0.35)
	await t.finished
	get_tree().change_scene_to_file(path)

# ── Helpers ───────────────────────────────────────────────────────────────────
func _panel(rect: Rect2, fill: Color, border: Color, radius: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = rect.position; p.size = rect.size
	_apply_style(p, fill, border, radius)
	return p

func _apply_style(node: Control, fill: Color, border: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(int(radius))
	node.add_theme_stylebox_override("panel", sb)

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _lbl_at(parent: Control, text: String, size: int, color: Color, pos: Vector2) -> Label:
	var l := _lbl(text, size, color)
	l.position = pos
	parent.add_child(l)
	return l

func _text_btn(text: String, size: int, color: Color, rect: Rect2) -> Button:
	var b := Button.new()
	b.text = text; b.position = rect.position; b.size = rect.size
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", color)
	_apply_style(b, Color(0,0,0,0), Color(0,0,0,0), 0.0)
	return b

func _hline(parent: Control, pos: Vector2, length: float, color: Color) -> void:
	var l := ColorRect.new(); l.position = pos; l.size = Vector2(length, 1); l.color = color
	parent.add_child(l)

func _vline(parent: Control, pos: Vector2, length: float, color: Color) -> void:
	var l := ColorRect.new(); l.position = pos; l.size = Vector2(1, length); l.color = color
	parent.add_child(l)
