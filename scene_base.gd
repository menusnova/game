extends Control

# Shared base for all demo pages — call _build_base(title, subtitle, accent_color) in _ready()

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

func _build_base(title: String, subtitle: String, accent: Color) -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color        = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Top bar
	var top := _panel(Rect2(0, 0, 1152, 52), Color(0.03, 0.07, 0.18, 0.98), accent, 0.0)
	add_child(top)

	# Back button
	var back := Button.new()
	back.text = "◀  LOBBY"; back.position = Vector2(10, 10); back.size = Vector2(100, 32)
	back.add_theme_font_size_override("font_size", 12)
	back.add_theme_color_override("font_color", C_TEXT)
	_apply_style(back, Color(accent.r, accent.g, accent.b, 0.22), accent, 5.0)
	back.pressed.connect(_go_lobby)
	top.add_child(back)

	# Title
	var t := _lbl(title, 20, accent)
	t.position = Vector2(1152 * 0.5 - 200, 8); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.size = Vector2(400, 36)
	top.add_child(t)

	# Subtitle
	var s := _lbl(subtitle, 11, C_TEXT2)
	s.position = Vector2(1152 * 0.5 - 200, 34); s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.size = Vector2(400, 14)
	top.add_child(s)

	# Separator
	var sep := ColorRect.new()
	sep.position = Vector2(0, 51); sep.size = Vector2(1152, 1); sep.color = accent
	top.add_child(sep)

func _go_lobby() -> void:
	var t := create_tween()
	var fade := ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0); fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	t.tween_property(fade, "color:a", 1.0, 0.30)
	await t.finished
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _panel(rect: Rect2, fill: Color, border: Color, radius: float) -> PanelContainer:
	var p := PanelContainer.new(); p.position = rect.position; p.size = rect.size
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
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _lbl_at(parent: Control, text: String, size: int, color: Color, pos: Vector2) -> Label:
	var l := _lbl(text, size, color); l.position = pos; parent.add_child(l); return l
