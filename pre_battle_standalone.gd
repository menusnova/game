extends Control

const SC_BATTLE   := "res://battle_scene.tscn"
const CARD_HEIGHT := 330.0   # ความสูงของ Card (landscape)
const SCREEN_H    := 648.0   # ความสูง viewport landscape
const CARD_TOP    := 280.0   # ตำแหน่ง y เมื่อ slide ขึ้นมาแล้ว

@onready var _card:  Panel      = $Card
@onready var _fade:  ColorRect  = $FadeOverlay
@onready var _start: Button     = $Card/BtnRow/BtnStart

func _ready() -> void:
	# ซ่อน Card ไว้ล่างจอก่อน
	if _card:
		_card.offset_top    = SCREEN_H
		_card.offset_bottom = SCREEN_H + CARD_HEIGHT
	if _start:
		_start.pressed.connect(_on_start)

	# fade in ก่อน แล้วค่อย slide card ขึ้น
	if _fade:
		var tf := create_tween()
		tf.tween_property(_fade, "color:a", 0.0, 0.3)
		await tf.finished

	if _card:
		var tc := create_tween()
		tc.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tc.tween_property(_card, "offset_top",    CARD_TOP,                0.38)
		tc.parallel().tween_property(_card, "offset_bottom", CARD_TOP + CARD_HEIGHT, 0.38)
		await tc.finished

func _on_start() -> void:
	DomainManager.add_points("battle")
	if _fade:
		var t := create_tween()
		t.tween_property(_fade, "color:a", 1.0, 0.28)
		await t.finished
	get_tree().change_scene_to_file(SC_BATTLE)
