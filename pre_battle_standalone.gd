extends Control

const SC_BATTLE    := "res://battle_scene.tscn"
const CARD_TOP     := 280.0
const CARD_BOTTOM  := 648.0

@onready var _card:  Panel      = $Card
@onready var _fade:  ColorRect  = $FadeOverlay
@onready var _start: Button     = $Card/BtnRow/BtnStart

func _ready() -> void:
	_card.offset_top    = CARD_BOTTOM
	_card.offset_bottom = CARD_BOTTOM
	_start.pressed.connect(_on_start)

	# fade in scene + slide card up
	var tf := create_tween()
	tf.tween_property(_fade, "color:a", 0.0, 0.3)
	await tf.finished

	var tc := create_tween()
	tc.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tc.tween_property(_card, "offset_top",   CARD_TOP,    0.38)
	tc.parallel().tween_property(_card, "offset_bottom", CARD_TOP + 368.0, 0.38)
	await tc.finished

func _on_start() -> void:
	DomainManager.add_points("battle")
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.28)
	await t.finished
	get_tree().change_scene_to_file(SC_BATTLE)
