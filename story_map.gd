extends Control

const SC_MAIN  := "res://main_menu.tscn"
const SC_STORY := "res://story_scene.tscn"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Background — ว่างไว้ให้ใส่เอง (ColorRect มืดเป็น fallback)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.08, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Top bar
	var bar := Panel.new()
	bar.position = Vector2(0, 0)
	bar.size     = Vector2(1152, 56)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.02, 0.04, 0.12, 0.88)
	bsb.border_width_bottom = 1
	bsb.border_color = Color(0.25, 0.5, 1.0, 0.2)
	bar.add_theme_stylebox_override("panel", bsb)
	add_child(bar)

	var back := Button.new()
	back.text = "◀"
	back.position = Vector2(16, 12)
	back.size     = Vector2(80, 32)
	var bbsb := StyleBoxFlat.new()
	bbsb.bg_color = Color(1, 1, 1, 0.05)
	bbsb.border_width_left = 1; bbsb.border_width_top = 1
	bbsb.border_width_right = 1; bbsb.border_width_bottom = 1
	bbsb.border_color = Color(1, 1, 1, 0.12)
	bbsb.corner_radius_top_left = 8; bbsb.corner_radius_top_right = 8
	bbsb.corner_radius_bottom_right = 8; bbsb.corner_radius_bottom_left = 8
	back.add_theme_stylebox_override("normal",  bbsb)
	back.add_theme_stylebox_override("hover",   bbsb)
	back.add_theme_stylebox_override("pressed", bbsb)
	back.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	back.add_theme_font_size_override("font_size", 13)
	back.pressed.connect(_go_back)
	bar.add_child(back)

	var title := Label.new()
	title.text = "เนื้อเรื่อง"
	title.size     = Vector2(1152, 56)
	title.position = Vector2(0, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(title)

	# Card area — กึ่งกลางแนวตั้ง
	var card_y    := 148.0
	var card_h    := 352.0
	var card_w    := 420.0
	var gap       := 48.0
	var total_w   := card_w * 2 + gap
	var start_x   := (1152 - total_w) / 2.0

	add_child(_make_card(
		"📖  เนื้อเรื่องหลัก",
		"MAIN STORY",
		"ติดตามการผจญภัยของ Alchemist\nและการต่อสู้กับ Void Syndicate",
		Color(0.06, 0.11, 0.26, 0.92),
		Color(0.22, 0.55, 1.0, 0.5),
		Color(0.22, 0.72, 1.0, 1.0),
		Vector2(start_x, card_y),
		Vector2(card_w, card_h),
		false,
		func(): _goto(SC_STORY)
	))

	add_child(_make_card(
		"✦  เนื้อเรื่องแยก",
		"SIDE STORY",
		"เรื่องราวของตัวละครแต่ละคน\nจะเปิดให้เล่นในอนาคต",
		Color(0.06, 0.06, 0.16, 0.85),
		Color(0.3, 0.3, 0.5, 0.25),
		Color(0.4, 0.4, 0.6, 0.5),
		Vector2(start_x + card_w + gap, card_y),
		Vector2(card_w, card_h),
		true,
		Callable()
	))

	# Fade in
	var fade := ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	var t := create_tween()
	t.tween_property(fade, "color:a", 0.0, 0.30)

func _make_card(
		label: String, tag: String, desc: String,
		bg_col: Color, border_col: Color, accent_col: Color,
		pos: Vector2, sz: Vector2,
		locked: bool, on_press: Callable) -> Panel:

	var card := Panel.new()
	card.position = pos
	card.size     = sz

	var sb := StyleBoxFlat.new()
	sb.bg_color     = bg_col
	sb.border_color = border_col
	sb.border_width_left   = 1
	sb.border_width_top    = 1
	sb.border_width_right  = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left     = 12
	sb.corner_radius_top_right    = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left  = 12
	card.add_theme_stylebox_override("panel", sb)

	# Accent bar top
	var accent := ColorRect.new()
	accent.size     = Vector2(sz.x, 3)
	accent.position = Vector2(0, 0)
	accent.color    = Color(accent_col.r, accent_col.g, accent_col.b, 0.7 if not locked else 0.2)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(accent)

	# Tag chip
	var tag_lbl := Label.new()
	tag_lbl.text = tag
	tag_lbl.add_theme_font_size_override("font_size", 10)
	tag_lbl.add_theme_color_override("font_color",
		Color(accent_col.r, accent_col.g, accent_col.b, 0.8) if not locked else Color(0.4, 0.4, 0.55, 0.5))
	tag_lbl.position = Vector2(20, 24)
	tag_lbl.size     = Vector2(sz.x - 40, 18)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tag_lbl)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = label
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color",
		Color(0.93, 0.96, 1, 1) if not locked else Color(0.4, 0.4, 0.5, 0.5))
	title_lbl.position = Vector2(20, 52)
	title_lbl.size     = Vector2(sz.x - 40, 36)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title_lbl)

	# Divider
	var div := ColorRect.new()
	div.size     = Vector2(sz.x - 48, 1)
	div.position = Vector2(24, 100)
	div.color    = Color(accent_col.r, accent_col.g, accent_col.b, 0.15)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color",
		Color(0.65, 0.78, 1, 0.75) if not locked else Color(0.35, 0.35, 0.45, 0.5))
	desc_lbl.position = Vector2(24, 116)
	desc_lbl.size     = Vector2(sz.x - 48, 60)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_lbl)

	# Bottom button / lock indicator
	var btn_lbl := Label.new()
	btn_lbl.add_theme_font_size_override("font_size", 13)
	btn_lbl.size     = Vector2(sz.x - 48, 36)
	btn_lbl.position = Vector2(24, sz.y - 56)
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked:
		btn_lbl.text = "🔒  เร็วๆ นี้"
		btn_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.6, 0.6))
	else:
		btn_lbl.text = "▶  เริ่มเล่น"
		btn_lbl.add_theme_color_override("font_color", accent_col)
	card.add_child(btn_lbl)

	# Lock dim overlay
	if locked:
		var dim := ColorRect.new()
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.color = Color(0, 0, 0, 0.38)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(dim)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				on_press.call()
		)
		card.mouse_entered.connect(func():
			var tw := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(card, "modulate", Color(1.06, 1.06, 1.10, 1), 0.10)
		)
		card.mouse_exited.connect(func():
			var tw := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.15)
		)

	return card

func _goto(path: String) -> void:
	SceneTransition.fade_to(path)

func _go_back() -> void:
	SceneTransition.fade_to(SC_MAIN)
