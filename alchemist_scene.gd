extends Control

const SC_MAIN := "res://main_menu.tscn"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.10, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Glow center
	var glow := ColorRect.new()
	glow.color = Color(0.18, 0.35, 1.0, 0.07)
	glow.size = Vector2(600, 400)
	glow.position = Vector2(276, 124)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var icon := Label.new()
	icon.text = "⚗"
	icon.add_theme_font_size_override("font_size", 72)
	icon.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0, 0.9))
	icon.size = Vector2(1152, 200)
	icon.position = Vector2(0, 180)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)

	var title := Label.new()
	title.text = "Arcanum Lab"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 1.0))
	title.size = Vector2(1152, 60)
	title.position = Vector2(0, 310)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var sub := Label.new()
	sub.text = "ห้องปฏิบัติการผสมธาตุ — เร็วๆ นี้"
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.55, 0.70, 1.0, 0.65))
	sub.size = Vector2(1152, 40)
	sub.position = Vector2(0, 378)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	var back := Button.new()
	back.text = "◀"
	back.size = Vector2(140, 40)
	back.position = Vector2((1152 - 140) / 2.0, 460)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.22, 0.55, 1.0)
	sb.border_color = Color(0.37, 0.62, 1.0, 0.6)
	sb.set_border_width(SIDE_LEFT, 1); sb.set_border_width(SIDE_TOP, 1)
	sb.set_border_width(SIDE_RIGHT, 1); sb.set_border_width(SIDE_BOTTOM, 1)
	sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8; sb.corner_radius_bottom_left = 8
	back.add_theme_stylebox_override("normal",  sb)
	back.add_theme_stylebox_override("hover",   sb)
	back.add_theme_stylebox_override("pressed", sb)
	back.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	back.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	back.add_theme_font_size_override("font_size", 14)
	back.pressed.connect(_go_back)
	add_child(back)

	# pulse icon
	var t := icon.create_tween().set_loops()
	t.tween_property(icon, "modulate:a", 0.65, 1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(icon, "modulate:a", 1.0,  1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _go_back() -> void:
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(SC_MAIN)
