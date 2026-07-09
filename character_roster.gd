extends Control

const SC_MAIN   := "res://main_menu.tscn"
const SC_DETAIL := "res://character_scene.tscn"

@onready var _back_btn:   Panel         = $TopBar/BackBtn
@onready var _count_lbl:  Label         = $TopBar/CountLabel
@onready var _grid:       GridContainer = $ContentScroll/MarginContainer/CharacterGrid
@onready var _fade:       ColorRect     = $FadeOverlay

func _ready() -> void:
	CharacterManager.character_unlocked.connect(_on_character_unlocked)

	# Back button
	_back_btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw := _back_btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(_back_btn, "scale", Vector2(0.78, 0.78), 0.08)
			tw.tween_property(_back_btn, "scale", Vector2(1.0, 1.0), 0.22)
			tw.tween_callback(_go_back)
	)
	_back_btn.mouse_entered.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	_back_btn.mouse_exited.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)

	_rebuild_grid()

	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.28)

func _on_character_unlocked(_char_name: String) -> void:
	_rebuild_grid()

func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var roster := CharacterManager.get_roster()
	var owned_count := roster.filter(func(c): return c["owned"]).size()
	_count_lbl.text = "%d / %d" % [owned_count, roster.size()]
	for data in roster:
		_grid.add_child(_make_card(data))

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
		hint_lbl.text = ""
		hint_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.5))
	hint_lbl.size     = Vector2(152, 16)
	hint_lbl.position = Vector2(10, 166)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hint_lbl)

	# Lock toggle button (owned only)
	if owned:
		var lock_btn := Button.new()
		lock_btn.text = "🔒" if CharacterManager.is_locked(name_str) else "🔓"
		lock_btn.size     = Vector2(28, 28)
		lock_btn.position = Vector2(140, 178)
		lock_btn.add_theme_font_size_override("font_size", 13)
		var lsb := StyleBoxFlat.new()
		lsb.bg_color = Color(0, 0, 0, 0.45)
		lsb.corner_radius_top_left = 6; lsb.corner_radius_top_right = 6
		lsb.corner_radius_bottom_right = 6; lsb.corner_radius_bottom_left = 6
		lock_btn.add_theme_stylebox_override("normal",  lsb)
		lock_btn.add_theme_stylebox_override("hover",   lsb)
		lock_btn.add_theme_stylebox_override("pressed", lsb)
		lock_btn.pressed.connect(func():
			CharacterManager.toggle_lock(name_str)
			lock_btn.text = "🔒" if CharacterManager.is_locked(name_str) else "🔓")
		card.add_child(lock_btn)

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
	if not ResourceLoader.exists(SC_DETAIL): return
	SceneTransition.fade_to(SC_DETAIL)

func _go_back() -> void:
	SceneTransition.fade_to(SC_MAIN)
