extends CanvasLayer

var _overlay: ColorRect
var _busy    := false

func _ready() -> void:
	layer = 100

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
