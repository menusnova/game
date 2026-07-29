extends Control

const SLIDE_PATHS: Array[String] = [
	"res://image/m1.jpg",
	"res://image/m2.jpg",
	"res://image/m3.jpg",
]

const SLIDE_LABELS: Array[String] = [
	"ชานเมืองทางเหนือ...",
	"ป่าต้องห้าม...",
	"ห้องปฏิบัติการต้องห้าม",
]

const HOLD_TIME   := 1.6
const FADE_TIME   := 0.45

const SC_STORY := "res://story_scene.tscn"

@onready var _bg: TextureRect  = $BgSlot
@onready var _fade: ColorRect  = $FadeOverlay
@onready var _label: Label     = $SlideLabel

func _ready() -> void:
	if _fade: _fade.color.a = 1.0
	_run()

func _load_jpg(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _run() -> void:
	for i in SLIDE_PATHS.size():
		if _bg:    _bg.texture = _load_jpg(SLIDE_PATHS[i])
		if _label: _label.text = ""

		if _fade:
			var ti := create_tween()
			ti.tween_property(_fade, "color:a", 0.0, FADE_TIME)
			await ti.finished

		await get_tree().create_timer(HOLD_TIME).timeout

		if _fade:
			var to := create_tween()
			to.tween_property(_fade, "color:a", 1.0, FADE_TIME)
			await to.finished

	SceneTransition.fade_to(SC_STORY)
