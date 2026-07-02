extends Control

const SC_MAIN   := "res://main_menu.tscn"
const SC_DETAIL := "res://character_scene.tscn"

# ── Roster data ────────────────────────────────────────────────────
# owned: true = มีแล้ว / false = ยังไม่มี (มืด)
const ROSTER: Array = [
	{"name": "Alchemist", "element": "⚗",  "rarity": 5, "element_color": Color(0.35, 0.75, 1.0),  "owned": true},
	{"name": "Lyra",      "element": "🔥", "rarity": 5, "element_color": Color(1.0,  0.45, 0.2),   "owned": true},
	{"name": "Kael",      "element": "⚡", "rarity": 4, "element_color": Color(0.95, 0.85, 0.2),   "owned": true},
	{"name": "Mira",      "element": "🧊", "rarity": 4, "element_color": Color(0.4,  0.85, 1.0),   "owned": true},
	{"name": "Seraph",    "element": "✦",  "rarity": 5, "element_color": Color(1.0,  0.78, 0.2),   "owned": false},
	{"name": "Voss",      "element": "🌑", "rarity": 4, "element_color": Color(0.6,  0.35, 1.0),   "owned": false},
	{"name": "???",       "element": "?",  "rarity": 5, "element_color": Color(0.5,  0.5,  0.5),   "owned": false},
	{"name": "???",       "element": "?",  "rarity": 4, "element_color": Color(0.5,  0.5,  0.5),   "owned": false},
	{"name": "???",       "element": "?",  "rarity": 3, "element_color": Color(0.5,  0.5,  0.5),   "owned": false},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Background dim
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.10, 0.96)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Top bar
	var top := HBoxContainer.new()
	top.position = Vector2(20, 16)
	top.size     = Vector2(1112, 36)
	top.add_theme_constant_override("separation", 12)
	add_child(top)

	var back := Button.new()
	back.text = "← กลับ"
	back.custom_minimum_size = Vector2(80, 32)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(1, 1, 1, 0.05)
	bsb.border_width_top = 1; bsb.border_width_right = 1
	bsb.border_width_bottom = 1; bsb.border_width_left = 1
	bsb.border_color = Color(1, 1, 1, 0.1)
	bsb.corner_radius_top_left = 10; bsb.corner_radius_top_right = 10
	bsb.corner_radius_bottom_right = 10; bsb.corner_radius_bottom_left = 10
	back.add_theme_stylebox_override("normal",  bsb)
	back.add_theme_stylebox_override("hover",   bsb)
	back.add_theme_stylebox_override("pressed", bsb)
	back.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	back.add_theme_font_size_override("font_size", 13)
	back.pressed.connect(_go_back)
	top.add_child(back)

	var title := Label.new()
	title.text = "ตัวละคร"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)

	var count_lbl := Label.new()
	var owned_count := ROSTER.filter(func(c): return c["owned"]).size()
	count_lbl.text = "%d / %d" % [owned_count, ROSTER.size()]
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color(0.5, 0.75, 1, 0.7))
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(count_lbl)

	# Grid scroll
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 64)
	scroll.size     = Vector2(1112, 568)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   0)
	mc.add_theme_constant_override("margin_right",  0)
	mc.add_theme_constant_override("margin_top",    8)
	mc.add_theme_constant_override("margin_bottom", 16)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.add_child(grid)
	scroll.add_child(mc)

	for data in ROSTER:
		grid.add_child(_make_card(data))

	# Fade in
	var fade := ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	var t := create_tween()
	t.tween_property(fade, "color:a", 0.0, 0.28)

func _make_card(data: Dictionary) -> Control:
	var owned: bool  = bool(data.get("owned", false))
	var rarity: int  = int(data.get("rarity", 3))
	var name_str: String = str(data.get("name", ""))
	var elem: String     = str(data.get("element", ""))
	var elem_col: Color  = data.get("element_color", Color(0.5, 0.5, 0.5)) as Color

	var r_col: Color
	match rarity:
		5: r_col = Color(1.0, 0.80, 0.20)
		4: r_col = Color(0.72, 0.50, 1.0)
		_: r_col = Color(0.35, 0.65, 1.0)

	var card := Panel.new()
	card.custom_minimum_size = Vector2(172, 210)

	var sb := StyleBoxFlat.new()
	if owned:
		sb.bg_color    = Color(0.04, 0.07, 0.16, 0.95)
		sb.border_color = Color(r_col.r, r_col.g, r_col.b, 0.45)
	else:
		sb.bg_color    = Color(0.02, 0.02, 0.05, 0.95)
		sb.border_color = Color(0.2, 0.2, 0.25, 0.3)
	sb.border_width_top = 1; sb.border_width_right = 1
	sb.border_width_bottom = 1; sb.border_width_left = 1
	sb.corner_radius_top_left = 12; sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12; sb.corner_radius_bottom_left = 12
	card.add_theme_stylebox_override("panel", sb)

	# Rarity bar top
	var rbar := ColorRect.new()
	rbar.size     = Vector2(172, 3)
	rbar.position = Vector2(0, 0)
	rbar.color    = Color(r_col.r, r_col.g, r_col.b, 0.7 if owned else 0.12)
	rbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rbar)

	# Art area
	var art_bg := ColorRect.new()
	art_bg.size     = Vector2(172, 120)
	art_bg.position = Vector2(0, 3)
	art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if owned:
		art_bg.color = Color(elem_col.r * 0.15, elem_col.g * 0.15, elem_col.b * 0.25, 1.0)
	else:
		art_bg.color = Color(0.03, 0.03, 0.06, 1.0)
	card.add_child(art_bg)

	# Element icon (center of art area)
	var elem_lbl := Label.new()
	elem_lbl.text = elem if owned else "?"
	elem_lbl.add_theme_font_size_override("font_size", 42)
	elem_lbl.size     = Vector2(172, 120)
	elem_lbl.position = Vector2(0, 3)
	elem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elem_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	elem_lbl.modulate = Color(1, 1, 1, 1.0 if owned else 0.12)
	elem_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(elem_lbl)

	# Lock overlay for unowned
	if not owned:
		var dim := ColorRect.new()
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.color = Color(0, 0, 0, 0.55)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(dim)

		var lock_lbl := Label.new()
		lock_lbl.text = "🔒"
		lock_lbl.add_theme_font_size_override("font_size", 22)
		lock_lbl.size     = Vector2(172, 120)
		lock_lbl.position = Vector2(0, 3)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock_lbl)

	# Stars
	var stars := "★".repeat(rarity)
	var star_lbl := Label.new()
	star_lbl.text = stars
	star_lbl.add_theme_font_size_override("font_size", 10)
	star_lbl.add_theme_color_override("font_color",
		Color(r_col.r, r_col.g, r_col.b, 0.9 if owned else 0.2))
	star_lbl.size     = Vector2(172, 16)
	star_lbl.position = Vector2(0, 124)
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(star_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = name_str
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color",
		Color(1, 1, 1, 0.95) if owned else Color(0.4, 0.4, 0.45, 0.6))
	name_lbl.size     = Vector2(152, 22)
	name_lbl.position = Vector2(10, 142)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# Obtain hint for unowned
	var hint_lbl := Label.new()
	hint_lbl.add_theme_font_size_override("font_size", 9)
	if owned:
		hint_lbl.text = "Lv. --"
		hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.75, 1, 0.6))
	else:
		hint_lbl.text = "สุ่มกาชา"
		hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.5))
	hint_lbl.size     = Vector2(152, 16)
	hint_lbl.position = Vector2(10, 166)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hint_lbl)

	# Click → detail (owned only)
	if owned and name_str != "???":
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_go_detail())
	else:
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return card

func _go_detail() -> void:
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.22)
	await t.finished
	get_tree().change_scene_to_file(SC_DETAIL)

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
