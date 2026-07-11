extends Control

const SC_MAIN       := "res://main_menu.tscn"
const SC_STORY      := "res://story_scene.tscn"
const SC_TRANSITION := "res://transition_scene.tscn"

@onready var _back_btn:   Panel     = $BackBtn
@onready var _main_card:  Panel     = $MainStoryCard
@onready var _fade:       ColorRect = $FadeOverlay

func _ready() -> void:
	# Fade in
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.30)

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

	# Main story card
	_main_card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_start_story()
	)
	_main_card.mouse_entered.connect(func():
		_main_card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(_main_card, "modulate", Color(1.06, 1.06, 1.10, 1), 0.10)
	)
	_main_card.mouse_exited.connect(func():
		_main_card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(_main_card, "modulate", Color(1, 1, 1, 1), 0.15)
	)

func _start_story() -> void:
	if not ResourceLoader.exists(SC_STORY):
		_show_toast("ยังไม่พร้อมให้เล่น")
		return
	var target := SC_TRANSITION if ResourceLoader.exists(SC_TRANSITION) else SC_STORY
	SceneTransition.fade_to(target)

func _go_back() -> void:
	SceneTransition.fade_to(SC_MAIN)

func _show_toast(msg: String) -> void:
	if get_node_or_null("_Toast") != null:
		return
	var toast := Panel.new()
	toast.name = "_Toast"
	toast.z_index = 100
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.22, 0.94)
	sb.border_color = Color(0.37, 0.62, 1.0, 0.5)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sb.set_border_width(side, 1 if side != SIDE_LEFT else 2)
	sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8; sb.corner_radius_bottom_left = 8
	toast.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 1.0))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 14; lbl.offset_right = -14
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(lbl)
	toast.size = Vector2(320, 44)
	toast.position = Vector2((1152 - 320) * 0.5, (648 - 44) * 0.5)
	toast.modulate.a = 0.0
	add_child(toast)
	var t := create_tween()
	t.tween_property(toast, "modulate:a", 1.0, 0.18)
	await t.finished
	await get_tree().create_timer(1.6).timeout
	if not is_instance_valid(self): return
	if not is_instance_valid(toast): return
	var t2 := create_tween()
	t2.tween_property(toast, "modulate:a", 0.0, 0.25)
	await t2.finished
	if is_instance_valid(toast): toast.queue_free()
