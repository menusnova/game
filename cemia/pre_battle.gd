extends CanvasLayer

signal start_battle
signal edit_team

func show_for_mission(mission_title: String, mission_id: String) -> void:
	$Root/Card/MissionLabel.text = mission_id
	$Root/Card/MissionName.text = mission_title
	$Root/Card.position.y = 648.0
	visible = true
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property($Root/Card, "position:y", 280.0, 0.35)
	$Root/Card/BtnRow/BtnStart.pressed.connect(_on_start, CONNECT_ONE_SHOT)
	$Root/Card/BtnRow/BtnEdit.pressed.connect(_on_edit, CONNECT_ONE_SHOT)

func _on_start() -> void:
	start_battle.emit()
	_close()

func _on_edit() -> void:
	edit_team.emit()

func _close() -> void:
	var t := create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property($Root/Card, "position:y", 648.0, 0.22)
	await t.finished
	visible = false
