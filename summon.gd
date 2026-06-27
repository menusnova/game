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
const C_PURPLE := Color(0.65, 0.35, 1.00, 1.0)

var _pity : int = 42

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.02, 0.16, 1.0); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Top bar
	var top := _panel(Rect2(0, 0, 1152, 52), Color(0.08, 0.03, 0.22, 0.98), C_PURPLE, 0.0)
	add_child(top)
	var back := Button.new()
	back.text = "◀  LOBBY"; back.position = Vector2(10, 10); back.size = Vector2(100, 32)
	back.add_theme_font_size_override("font_size", 12)
	back.add_theme_color_override("font_color", C_TEXT)
	_apply_style(back, Color(C_PURPLE.r, C_PURPLE.g, C_PURPLE.b, 0.22), C_PURPLE, 5.0)
	back.pressed.connect(_go_lobby); top.add_child(back)
	_lbl_at(top, "✦  SUMMON", 20, C_PURPLE, Vector2(476, 8))
	_lbl_at(top, "Banner Gacha — Rate-UP Limited", 10, C_TEXT2, Vector2(446, 34))
	var sep := ColorRect.new(); sep.position = Vector2(0,51); sep.size = Vector2(1152,1); sep.color = C_PURPLE
	top.add_child(sep)

	# Banner art area
	var art := _panel(Rect2(60, 72, 540, 480), Color(0.10, 0.04, 0.28, 0.95), C_PURPLE, 12.0)
	add_child(art)
	_lbl_at(art, "★★★★★", 28, C_GOLD, Vector2(180, 20))
	_lbl_at(art, "LUXIA", 42, C_PURPLE, Vector2(160, 70))
	_lbl_at(art, "Element: ✦ LIGHT", 14, C_TEXT2, Vector2(170, 130))
	_lbl_at(art, "[ Character Art Placeholder ]", 13, C_TEXT2, Vector2(140, 200))

	# Sub-banner tabs
	var tab_data : Array = [["✦ Character", true], ["⚗ Weapon", false], ["📦 Standard", false]]
	var tx : float = 620.0
	for td : Array in tab_data:
		var tb := Button.new(); tb.text = td[0]; tb.size = Vector2(158, 36); tb.position = Vector2(tx, 72)
		tb.add_theme_font_size_override("font_size", 12)
		_apply_style(tb, Color(C_PURPLE.r, C_PURPLE.g, C_PURPLE.b, 0.25) if td[1] else C_PANEL2,
					 C_PURPLE if td[1] else C_BORDER, 6.0)
		tb.add_theme_color_override("font_color", C_PURPLE if td[1] else C_TEXT2)
		add_child(tb); tx += 164.0

	# Info panel right
	var info := _panel(Rect2(620, 116, 476, 200), C_PANEL2, C_BORDER, 8.0)
	add_child(info)
	_lbl_at(info, "BANNER INFO", 11, C_PURPLE, Vector2(12, 10))
	_lbl_at(info, "Rate-UP: LUXIA (★★★★★)", 12, C_GOLD,   Vector2(12, 32))
	_lbl_at(info, "Base 5★ Rate:  0.600%",   11, C_TEXT2,  Vector2(12, 54))
	_lbl_at(info, "Soft Pity:     75 pulls",  11, C_TEXT2,  Vector2(12, 72))
	_lbl_at(info, "Hard Pity:     90 pulls",  11, C_TEXT2,  Vector2(12, 90))
	_lbl_at(info, "Current Pity:  %d / 90" % _pity, 12, C_ACCENT, Vector2(12, 114))

	# Pity bar
	var pb := _panel(Rect2(12, 136, 448, 12), C_DARK, C_BORDER, 4.0)
	info.add_child(pb)
	var pf := ColorRect.new(); pf.position = Vector2(1,1)
	pf.size = Vector2(446 * float(_pity) / 90.0, 10); pf.color = C_PURPLE; pb.add_child(pf)

	_lbl_at(info, "◈ Crystal: 8,500  (21 pulls)", 11, C_TEXT2, Vector2(12, 162))

	# Summon buttons
	var btn1 := Button.new(); btn1.text = "✦ SUMMON ×1\n160 💎"; btn1.size = Vector2(220, 64)
	btn1.position = Vector2(620, 330); btn1.add_theme_font_size_override("font_size", 13)
	_apply_style(btn1, Color(0.25, 0.08, 0.45, 1.0), C_PURPLE, 8.0)
	btn1.add_theme_color_override("font_color", Color(1,1,1,1))
	btn1.pressed.connect(_do_summon.bind(1)); add_child(btn1)

	var btn10 := Button.new(); btn10.text = "✦ SUMMON ×10\n1,600 💎\n(+1 guaranteed 4★)"; btn10.size = Vector2(250, 64)
	btn10.position = Vector2(846, 330); btn10.add_theme_font_size_override("font_size", 13)
	_apply_style(btn10, Color(0.35, 0.08, 0.60, 1.0), C_GOLD, 8.0)
	btn10.add_theme_color_override("font_color", C_GOLD)
	btn10.pressed.connect(_do_summon.bind(10)); add_child(btn10)

	# History / detail tabs bottom
	var bottom := _panel(Rect2(620, 408, 476, 144), C_PANEL2, C_BORDER, 8.0)
	add_child(bottom)
	_lbl_at(bottom, "RECENT  (last 10 pulls)", 11, C_TEXT2, Vector2(12, 10))
	var rec_data : Array = ["3★ Catalyst", "3★ Sword", "4★ EMBER ★★★★", "3★ Shield", "3★ Bow"]
	for i in range(rec_data.size()):
		var col : Color = C_GOLD if "4★" in rec_data[i] or "5★" in rec_data[i] else C_TEXT2
		_lbl_at(bottom, rec_data[i], 10, col, Vector2(12 + int(i/2)*220, 32 + (i%2)*22))

func _do_summon(count: int) -> void:
	_pity = min(_pity + count, 90)

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
