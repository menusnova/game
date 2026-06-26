extends Control

func _draw() -> void:
	var root := get_parent()
	if root and root.has_method("_draw_bar"):
		root._draw_bar(self)
