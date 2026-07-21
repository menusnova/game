extends CanvasLayer

const SC_MAIN := "res://main_menu.tscn"

# Where the Android back button should go from each scene. Scenes not
# listed here fall back to the main menu; the main menu itself asks to
# quit instead of navigating.
const BACK_TARGETS := {
	"res://battle_scene.tscn":          SC_MAIN,
	"res://story_map.tscn":             SC_MAIN,
	"res://story_scene.tscn":           SC_MAIN,
	"res://profile_scene.tscn":         SC_MAIN,
	"res://gacha_scene.tscn":           SC_MAIN,
	"res://shop_scene.tscn":            SC_MAIN,
	"res://codex_scene.tscn":           SC_MAIN,
	"res://laboratory_scene.tscn":      SC_MAIN,
	"res://character_roster.tscn":      SC_MAIN,
	"res://character_scene.tscn":       "res://character_roster.tscn",
	"res://pre_battle_standalone.tscn": SC_MAIN,
}

var _overlay: ColorRect
var _busy    := false
var _quit_ask: Control = null

func _ready() -> void:
	layer = 100
	# Take over the Android back button instead of quitting instantly.
	get_tree().set_auto_accept_quit(false)

	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 1.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 100
	add_child(_overlay)

	# Fade in every time a new scene loads
	var t := create_tween()
	t.tween_property(_overlay, "color:a", 0.0, 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func is_busy() -> bool:
	return _busy

func fade_to(path: String, duration: float = 0.28) -> void:
	if _busy or not ResourceLoader.exists(path):
		return
	_busy = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_overlay, "color:a", 1.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_overlay, "color:a", 0.0, 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await t2.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

func _notification(what: int) -> void:
	# Android back button (and desktop window-close request).
	if what == NOTIFICATION_WM_GO_BACK or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_handle_back()

func _handle_back() -> void:
	if _busy:
		return
	# If the quit prompt is already open, a second back press cancels it.
	if is_instance_valid(_quit_ask):
		_close_quit_ask()
		return
	var scene := get_tree().current_scene
	var path := ""
	if scene != null:
		path = scene.scene_file_path
	if path == SC_MAIN:
		_show_quit_ask()
	elif BACK_TARGETS.has(path):
		fade_to(BACK_TARGETS[path])
	else:
		# Unknown / transient scene: fall back to the main menu.
		fade_to(SC_MAIN)

func _show_quit_ask() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.z_index = 120
	_quit_ask = root
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var td := create_tween()
	td.tween_property(dim, "color:a", 0.72, 0.18)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(440, 210)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-220, -105)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 1.0)
	sb.border_color = Color(0.22, 0.62, 1, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	var title := Label.new()
	title.text = "ออกจากเกม?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.97, 1, 1))
	title.position = Vector2(28, 30)
	title.size = Vector2(384, 30)
	panel.add_child(title)

	var msg := Label.new()
	msg.text = "ต้องการปิดเกมตอนนี้ใช่หรือไม่"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 14)
	msg.add_theme_color_override("font_color", Color(0.72, 0.8, 0.95, 1))
	msg.position = Vector2(28, 72)
	msg.size = Vector2(384, 24)
	panel.add_child(msg)

	var btn_cancel := _make_ask_button("ยกเลิก", Color(0.16, 0.2, 0.32, 1), Color(0.85, 0.9, 1, 1))
	btn_cancel.position = Vector2(28, 132)
	btn_cancel.pressed.connect(_close_quit_ask)
	panel.add_child(btn_cancel)

	var btn_quit := _make_ask_button("ออกจากเกม", Color(0.7, 0.16, 0.24, 1), Color(1, 1, 1, 1))
	btn_quit.position = Vector2(212, 132)
	btn_quit.pressed.connect(func(): get_tree().quit())
	panel.add_child(btn_quit)

func _make_ask_button(text: String, bg: Color, fg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(172, 46)
	b.size = Vector2(172, 46)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", fg)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(8)
	var sb_h := sb.duplicate()
	sb_h.bg_color = bg.lightened(0.12)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb_h)
	b.add_theme_stylebox_override("pressed", sb_h)
	b.add_theme_stylebox_override("focus", StyleBoxFlat.new())
	return b

func _close_quit_ask() -> void:
	if is_instance_valid(_quit_ask):
		_quit_ask.queue_free()
	_quit_ask = null
