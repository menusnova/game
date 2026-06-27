extends Control

# ── Screen layout (1152 × 648) ────────────────────────────────────────────────
const W      : float = 1152.0
const H      : float = 648.0
const TOP_H  : float = 52.0
const BOT_H  : float = 70.0
const CHAT_H : float = 28.0
const L_W    : float = 218.0          # left panel
const R_W    : float = 304.0          # right panel
# Center: x=218..848  w=630  content h=498  chat h=28  total=526

# ── Colours ───────────────────────────────────────────────────────────────────
const C_BG     := Color(0.03, 0.06, 0.16, 1.00)
const C_PANEL  := Color(0.05, 0.10, 0.22, 0.94)
const C_PANEL2 := Color(0.07, 0.13, 0.28, 0.97)
const C_DARK   := Color(0.02, 0.04, 0.12, 1.00)
const C_BORDER := Color(0.15, 0.45, 0.85, 0.55)
const C_BDR2   := Color(0.20, 0.60, 1.00, 0.30)
const C_TEXT   := Color(0.83, 0.93, 1.00, 1.00)
const C_TEXT2  := Color(0.55, 0.75, 1.00, 1.00)
const C_ACCENT := Color(0.20, 0.70, 1.00, 1.00)
const C_GOLD   := Color(1.00, 0.82, 0.30, 1.00)
const C_PURPLE := Color(0.65, 0.35, 1.00, 1.00)
const C_RED    := Color(1.00, 0.32, 0.32, 1.00)
const C_GREEN  := Color(0.28, 1.00, 0.55, 1.00)
const C_TEAL   := Color(0.10, 0.80, 0.75, 1.00)
const C_ORANGE := Color(1.00, 0.60, 0.16, 1.00)

# ── Scenes ────────────────────────────────────────────────────────────────────
const SC_BATTLE    := "res://battle_scene.tscn"
const SC_SUMMON    := "res://summon.tscn"
const SC_CHARACTER := "res://character.tscn"
const SC_LINEUP    := "res://lineup.tscn"
const SC_INVENTORY := "res://inventory.tscn"

# ── State ─────────────────────────────────────────────────────────────────────
var _show_female : bool = true
var _char_female : TextureRect
var _char_male   : TextureRect
var _toggle_btn  : Button

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_add_bg()
	_build_top_bar()
	_build_left_panel()
	_build_center()
	_build_right_panel()
	_build_chat_bar()
	_build_bottom_nav()

# ─── Background ───────────────────────────────────────────────────────────────
func _add_bg() -> void:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.color = C_BG; r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)

# ─── Top bar  (y=0..52) ──────────────────────────────────────────────────────
func _build_top_bar() -> void:
	var bar := _panel(Rect2(0, 0, W, TOP_H), Color(0.03, 0.07, 0.18, 0.98), C_BORDER, 0.0)
	add_child(bar)
	_hline(bar, 0, TOP_H - 1, W, C_BORDER)

	# Currency slots — fixed x positions so they never collide
	# [icon, label, value, color, x_start]
	var cur : Array = [
		["💎", "Crystal",   "8,500",     C_ACCENT, 14.0],
		["🪙", "Gold",      "1,240,000", C_GOLD,   180.0],
		["⚗",  "A.Core",   "3,820",     C_TEAL,   365.0],
		["⚡",  "Energy",   "120/120",   C_GREEN,  510.0],
	]
	for c : Array in cur:
		var cx : float = c[4]
		_lbl_at(bar, c[0], 15, c[3], Vector2(cx, 8))
		_lbl_at(bar, c[2], 12, C_TEXT, Vector2(cx + 22, 10))

		# Vertical divider after each slot (except last)
		if cx < 510.0:
			var dv := ColorRect.new()
			dv.color = C_BDR2
			# divider x just before next slot
			var nx : float = [180.0, 365.0, 510.0, 660.0][cur.find(c)]
			dv.position = Vector2(nx - 8, 10); dv.size = Vector2(1, 30)
			bar.add_child(dv)

	# Right icon buttons — Mail / Friends / Settings
	var rbtn : Array = [["✉", "Mail", C_ACCENT], ["👥", "Friends", C_TEXT2], ["⚙", "Settings", C_TEXT2]]
	var bx : float = W - 10.0
	for rb : Array in rbtn:
		var b := _icon_btn(rb[0], rb[1], Rect2(bx - 104, 8, 102, 36))
		b.add_theme_color_override("font_color", rb[2])
		bar.add_child(b)
		bx -= 110.0

# ─── Left panel  (x=0, y=52, w=218, h=526) ───────────────────────────────────
func _build_left_panel() -> void:
	var ph : float = H - TOP_H - BOT_H      # 526
	var bg := _panel(Rect2(0, TOP_H, L_W, ph), Color(0.04, 0.08, 0.20, 0.96), C_BORDER, 0.0)
	add_child(bg)
	_vline(bg, L_W - 1, 0, ph, C_BORDER)

	# ── Profile card  (y=8, h=82) ────────────────────────────────────────
	var prof := _panel(Rect2(8, 8, 202, 82), C_PANEL2, C_BORDER, 6.0)
	bg.add_child(prof)

	var av := Button.new()
	av.text = "👤"; av.position = Vector2(8, 8); av.size = Vector2(52, 52)
	av.add_theme_font_size_override("font_size", 22)
	_apply_style(av, C_DARK, C_ACCENT, 5.0)
	prof.add_child(av)

	var lv_bg := _panel(Rect2(8, 56, 52, 14), Color(0,0,0,0.85), C_GOLD, 3.0)
	prof.add_child(lv_bg)
	_lbl_at(lv_bg, "Lv. 70", 9, C_GOLD, Vector2(6, 2))

	_lbl_at(prof, "CHEMIA",        14, C_TEXT,  Vector2(66, 10))
	_lbl_at(prof, "UID: 100012345", 9, C_TEXT2, Vector2(66, 28))

	var eb := _panel(Rect2(66, 46, 126, 8), C_DARK, C_BDR2, 3.0)
	prof.add_child(eb)
	var ef := ColorRect.new(); ef.position = Vector2(1,1); ef.size = Vector2(126,6); ef.color = C_GREEN
	eb.add_child(ef)
	_lbl_at(prof, "⚡ 120/120", 8, C_GREEN, Vector2(66, 56))

	# ── Menu items  (y=98 → 6×35 = 210 → bottom=308) ────────────────────
	var menu : Array = [
		["📢", "Notice",         C_ACCENT ],
		["📋", "Missions",       C_GOLD   ],
		["🎉", "Event",          C_ORANGE ],
		["🎫", "Pass",           C_PURPLE ],
		["🛒", "Shop",           C_TEAL   ],
		["🎁", "First Purchase", C_RED    ],
	]
	for i in range(menu.size()):
		var m : Array = menu[i]
		var my : float = 98.0 + i * 35.0
		var row := _panel(Rect2(8, my, 202, 31), C_PANEL2, C_BDR2, 5.0)
		bg.add_child(row)
		_lbl_at(row, m[0], 13, m[2], Vector2(8, 6))
		_lbl_at(row, m[1], 11, C_TEXT, Vector2(30, 8))
		_lbl_at(row, "▶",  10, m[2],   Vector2(183, 8))

	# ── Event Banner  (y=318, h=58) ──────────────────────────────────────
	var ev := _panel(Rect2(8, 318, 202, 58), Color(0.22, 0.06, 0.38, 0.93), C_PURPLE, 7.0)
	bg.add_child(ev)

	var ev_tag := _panel(Rect2(8, 6, 56, 14), Color(0.50, 0.08, 0.75, 1), Color(0,0,0,0), 3.0)
	ev.add_child(ev_tag)
	_lbl_at(ev_tag, "LIMITED", 8, Color(1,1,1,1), Vector2(6, 2))

	_lbl_at(ev, "STARFALL INVOCATION", 11, C_PURPLE, Vector2(8, 22))
	_lbl_at(ev, "Ends in 5d 12h 30m",   9, C_TEXT2,  Vector2(8, 38))

# ─── Center  (x=218, y=52, w=630, content-h=498, chat-h=28) ──────────────────
func _build_center() -> void:
	var cx : float = L_W                     # 218
	var cw : float = W - L_W - R_W          # 630
	var cy : float = TOP_H                   # 52
	var ch : float = H - TOP_H - BOT_H - CHAT_H   # 498

	# Dark stage background
	var stage := ColorRect.new()
	stage.position = Vector2(cx, cy); stage.size = Vector2(cw, ch)
	stage.color    = Color(0.02, 0.04, 0.14, 0.60)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)

	# Bottom glow strip
	var glow := ColorRect.new()
	glow.position = Vector2(cx, cy + ch - 50); glow.size = Vector2(cw, 50)
	glow.color    = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.07)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	# Portrait size & positions
	var pw   : float = 240.0
	var ph_h : float = 430.0
	var px   : float = cx + (cw - pw) * 0.5   # centered
	var py   : float = cy + (ch - ph_h) * 0.5

	# ── Female portrait ───────────────────────────────────────────────────
	_char_female = TextureRect.new()
	_char_female.name         = "FemaleCharacter"
	_char_female.position     = Vector2(px, py)
	_char_female.size         = Vector2(pw, ph_h)
	_char_female.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_char_female.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_female.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Generated placeholder portrait (cyan/female theme)
	_char_female.texture = PortraitGen.make(Color(0.30, 0.75, 1.00), int(pw), int(ph_h))
	add_child(_char_female)

	# ── Male portrait ─────────────────────────────────────────────────────
	_char_male = TextureRect.new()
	_char_male.name         = "MaleCharacter"
	_char_male.position     = Vector2(px, py)
	_char_male.size         = Vector2(pw, ph_h)
	_char_male.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_char_male.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_male.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_male.visible      = false
	# Generated placeholder portrait (orange/male theme)
	_char_male.texture = PortraitGen.make(Color(1.00, 0.55, 0.15), int(pw), int(ph_h))
	add_child(_char_male)

	# Toggle ♀/♂ — top-right of center area
	_toggle_btn = Button.new()
	_toggle_btn.text     = "♀"
	_toggle_btn.position = Vector2(cx + cw - 46, cy + 8)
	_toggle_btn.size     = Vector2(38, 38)
	_toggle_btn.add_theme_font_size_override("font_size", 18)
	_toggle_btn.add_theme_color_override("font_color", C_ACCENT)
	_apply_style(_toggle_btn, C_PANEL2, C_ACCENT, 6.0)
	_toggle_btn.pressed.connect(_on_toggle_char)
	add_child(_toggle_btn)

	# Name plate — bottom center of center area
	var np := _panel(Rect2(cx + cw*0.5 - 90, cy + ch - 22, 180, 18),
					  C_DARK, C_BORDER, 4.0)
	add_child(np)
	var nl := _lbl("◇  SELECT CHARACTER  ◇", 9, C_TEXT2)
	nl.position = Vector2(0, 3); nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.size = Vector2(180, 12)
	np.add_child(nl)

# ─── Right panel  (x=848, y=52, w=304, h=526) ────────────────────────────────
func _build_right_panel() -> void:
	var rx : float = W - R_W    # 848
	var ph : float = H - TOP_H - BOT_H   # 526

	var bg := _panel(Rect2(rx, TOP_H, R_W, ph), Color(0.04, 0.08, 0.20, 0.96), C_BORDER, 0.0)
	add_child(bg)
	_vline(bg, 0, 0, ph, C_BORDER)

	var iw : float = R_W - 16.0   # 288  (inner width with 8px margin each side)

	# ── Gacha Banner  (y=8, h=92) ────────────────────────────────────────
	var bn := _panel(Rect2(8, 8, iw, 92), Color(0.18, 0.05, 0.30, 0.95), C_PURPLE, 7.0)
	bg.add_child(bn)

	var bn_tag := _panel(Rect2(8, 6, 64, 14), Color(0.50, 0.08, 0.72, 1), Color(0,0,0,0), 3.0)
	bn.add_child(bn_tag)
	_lbl_at(bn_tag, "LIMITED", 8, Color(1,1,1,1), Vector2(7, 2))

	var bn_art := _panel(Rect2(iw - 76, 8, 68, 76), Color(0.12,0.05,0.25,0.9), C_PURPLE, 5.0)
	bn.add_child(bn_art)
	_lbl_at(bn_art, "★", 30, C_GOLD, Vector2(16, 14))

	_lbl_at(bn, "LUXIA  ★★★★★",    13, C_GOLD,   Vector2(10, 18))
	_lbl_at(bn, "Element: ✦ LIGHT",  10, C_TEXT2,  Vector2(10, 36))
	_lbl_at(bn, "Rate-UP Limited",    9, C_PURPLE,  Vector2(10, 52))

	var sb_btn := Button.new()
	sb_btn.text     = "✦ SUMMON"
	sb_btn.position = Vector2(10, 68); sb_btn.size = Vector2(82, 18)
	sb_btn.add_theme_font_size_override("font_size", 10)
	sb_btn.add_theme_color_override("font_color", Color(1,1,1,1))
	_apply_style(sb_btn, C_PURPLE, C_PURPLE, 4.0)
	sb_btn.pressed.connect(func(): _goto(SC_SUMMON))
	bn.add_child(sb_btn)

	# ── Content cards  y=108, each h=44, gap=4 ───────────────────────────
	var cards : Array = [
		["⚔", "ADVENTURE",  "Main Story  Ch.1–20", C_ACCENT, SC_BATTLE],
		["📜", "CHRONICLE",  "Side Stories",        C_PURPLE, ""],
		["🔬", "SIMULATION", "Farm Resources",      C_GREEN,  ""],
	]
	for i in range(cards.size()):
		var c  : Array  = cards[i]
		var cy : float  = 108.0 + i * 48.0
		var cc := _panel(Rect2(8, cy, iw, 44), C_PANEL2, c[3], 6.0)
		bg.add_child(cc)
		_lbl_at(cc, c[0], 16, c[3], Vector2(9, 12))
		_lbl_at(cc, c[1], 12, C_TEXT, Vector2(36, 6))
		_lbl_at(cc, c[2], 9,  C_TEXT2, Vector2(36, 22))
		_lbl_at(cc, "▶",  11, c[3], Vector2(iw - 22, 14))
		var sp : String = c[4]
		if sp != "":
			cc.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_goto(sp))
			cc.mouse_filter = Control.MOUSE_FILTER_STOP

	# ── Arena + Expedition  y=252, each h=50 ─────────────────────────────
	var hw : float = (iw - 6) * 0.5   # 141
	var side : Array = [
		["⚔\nARENA",       C_RED,    0.0,     SC_BATTLE],
		["🗺\nEXPEDITION", C_ORANGE, hw + 6,  ""],
	]
	for sc : Array in side:
		var sr := _panel(Rect2(8 + sc[2], 252, hw, 50), C_PANEL2, sc[1], 6.0)
		bg.add_child(sr)
		var sl := _lbl(sc[0], 11, sc[1])
		sl.position = Vector2(0, 4); sl.size = Vector2(hw, 40)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sr.add_child(sl)
		var sp2 : String = sc[3]
		if sp2 != "":
			sr.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_goto(sp2))
			sr.mouse_filter = Control.MOUSE_FILTER_STOP

	# ── Domain  y=310, h=46 ───────────────────────────────────────────────
	var dom := _panel(Rect2(8, 310, iw, 46), Color(0.06, 0.12, 0.28, 0.95), C_TEAL, 6.0)
	bg.add_child(dom)
	var dt := _panel(Rect2(8, 5, 46, 14), Color(0.0,0.3,0.4,1), Color(0,0,0,0), 3.0)
	dom.add_child(dt)
	_lbl_at(dt, "END", 8, C_TEAL, Vector2(6, 2))
	_lbl_at(dom, "◈ DOMAIN", 12, C_TEAL,   Vector2(12, 22))
	_lbl_at(dom, "Boss  ·  Raid  ·  Weekly", 9, C_TEXT2, Vector2(95, 25))
	_lbl_at(dom, "▶", 10, C_TEAL, Vector2(iw - 22, 15))

# ─── Chat bar  (x=218, y=550, w=630, h=28) ───────────────────────────────────
func _build_chat_bar() -> void:
	var cy : float = H - BOT_H - CHAT_H   # 550
	var cw : float = W - L_W - R_W        # 630
	var bar := _panel(Rect2(L_W, cy, cw, CHAT_H),
					   Color(0.03, 0.06, 0.16, 0.96), C_BDR2, 0.0)
	add_child(bar)

	# Tabs
	var tabs : Array = ["🌍 World", "⚔ Guild", "👥 Friend"]
	for i in range(tabs.size()):
		var tb := Button.new()
		tb.text     = tabs[i]
		tb.position = Vector2(4 + i * 76, 3)
		tb.size     = Vector2(72, 22)
		tb.add_theme_font_size_override("font_size", 9)
		var active : bool = (i == 0)
		tb.add_theme_color_override("font_color", C_ACCENT if active else C_TEXT2)
		_apply_style(tb,
			Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.18) if active else Color(0,0,0,0),
			C_ACCENT if active else Color(0,0,0,0), 3.0)
		bar.add_child(tb)

	_lbl_at(bar, "💬  alchemy_master: Fire + Water = Steam?  🔥", 9, C_TEXT2, Vector2(238, 7))

# ─── Bottom nav  (y=578, h=70) ───────────────────────────────────────────────
func _build_bottom_nav() -> void:
	var bar := _panel(Rect2(0, H - BOT_H, W, BOT_H),
					   Color(0.03, 0.06, 0.18, 0.98), C_BORDER, 0.0)
	add_child(bar)
	_hline(bar, 0, 0, W, C_BORDER)

	var nav : Array = [
		["👤", "Alchemist", true,  SC_CHARACTER],
		["⚔",  "Lineup",    false, SC_LINEUP   ],
		["⚗",  "Arcanum",   false, ""          ],
		["🎒", "Inventory", false, SC_INVENTORY],
		["📖", "Database",  false, ""          ],
		["🛡",  "Guild",     false, ""          ],
		["📚", "Archive",   false, ""          ],
	]
	var iw : float = W / nav.size()    # ~164.6 px per item
	for i in range(nav.size()):
		var item   : Array = nav[i]
		var active : bool  = item[2]
		var nx     : float = iw * i

		if active:
			var hi := ColorRect.new()
			hi.position = Vector2(nx, 0); hi.size = Vector2(iw, BOT_H)
			hi.color    = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.13)
			hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bar.add_child(hi)
			var tl := ColorRect.new()
			tl.position = Vector2(nx, 0); tl.size = Vector2(iw, 2); tl.color = C_ACCENT
			bar.add_child(tl)

		var ic := _lbl(item[0], 20, C_ACCENT if active else C_TEXT2)
		ic.position = Vector2(nx, 8); ic.size = Vector2(iw, 26)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar.add_child(ic)

		var tx := _lbl(item[1], 9, C_ACCENT if active else C_TEXT2)
		tx.position = Vector2(nx, 36); tx.size = Vector2(iw, 16)
		tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar.add_child(tx)

		var sp : String = item[3]
		if sp != "" and not active:
			var btn := Button.new()
			btn.position = Vector2(nx, 0); btn.size = Vector2(iw, BOT_H)
			_apply_style(btn, Color(0,0,0,0), Color(0,0,0,0), 0.0)
			btn.pressed.connect(func(): _goto(sp))
			bar.add_child(btn)

# ─── Toggle character ─────────────────────────────────────────────────────────
func _on_toggle_char() -> void:
	_show_female       = not _show_female
	_toggle_btn.text   = "♀" if _show_female else "♂"
	_char_female.visible = _show_female
	_char_male.visible   = not _show_female

# ─── Scene transition ─────────────────────────────────────────────────────────
func _goto(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color        = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var t := create_tween()
	t.tween_property(overlay, "color:a", 1.0, 0.30)
	await t.finished
	get_tree().change_scene_to_file(path)

# ─── Helpers ──────────────────────────────────────────────────────────────────
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
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _lbl_at(parent: Control, text: String, size: int, color: Color, pos: Vector2) -> Label:
	var l := _lbl(text, size, color); l.position = pos; parent.add_child(l); return l

func _icon_btn(icon: String, label: String, rect: Rect2) -> Button:
	var b := Button.new()
	b.text = icon + "  " + label; b.position = rect.position; b.size = rect.size
	b.add_theme_font_size_override("font_size", 11)
	_apply_style(b, Color(0,0,0,0), Color(0,0,0,0), 0.0)
	return b

func _hline(parent: Control, x: float, y: float, length: float, color: Color) -> void:
	var l := ColorRect.new(); l.position = Vector2(x,y); l.size = Vector2(length,1); l.color = color
	parent.add_child(l)

func _vline(parent: Control, x: float, y: float, length: float, color: Color) -> void:
	var l := ColorRect.new(); l.position = Vector2(x,y); l.size = Vector2(1,length); l.color = color
	parent.add_child(l)
