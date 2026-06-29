extends Control

# ใส่ภาพฉากเดินทาง 3 ฉากตรงนี้
# ถ้ายังไม่มีภาพ ปล่อย null ไว้ได้ — จะแสดงเป็นพื้นดำ
const SLIDES: Array = [
	null,  # ฉาก 1: จุดเริ่มต้น เช่น ทางเข้าเมือง  → ใส่ preload("res://image/xxx.png")
	null,  # ฉาก 2: ระหว่างทาง เช่น ป่า / ถนน
	null,  # ฉาก 3: ถึงปลายทาง เช่น หน้าห้องทดลอง
]

const SLIDE_LABELS: Array[String] = [
	"ชานเมืองทางเหนือ...",
	"ป่าต้องห้าม...",
	"ห้องปฏิบัติการต้องห้าม",
]

const HOLD_TIME   := 1.6   # วินาทีที่แสดงแต่ละฉาก
const FADE_TIME   := 0.45  # วินาที fade ระหว่างฉาก

const SC_STORY := "res://story_scene.tscn"

@onready var _bg: TextureRect  = $BgSlot
@onready var _fade: ColorRect  = $FadeOverlay
@onready var _label: Label     = $SlideLabel

func _ready() -> void:
	_fade.color.a = 1.0
	_run()

func _run() -> void:
	for i in SLIDES.size():
		# ตั้งฉากและข้อความ
		_bg.texture = SLIDES[i]
		_label.text = SLIDE_LABELS[i] if i < SLIDE_LABELS.size() else ""

		# fade in
		var ti := create_tween()
		ti.tween_property(_fade, "color:a", 0.0, FADE_TIME)
		await ti.finished

		await get_tree().create_timer(HOLD_TIME).timeout

		# fade out
		var to := create_tween()
		to.tween_property(_fade, "color:a", 1.0, FADE_TIME)
		await to.finished

	get_tree().change_scene_to_file(SC_STORY)
