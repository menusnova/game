extends Control

const TYPEWRITER_SPEED := 0.032
const TYPEWRITER_FAST  := 0.006   # speed-up mode

var lyra_portraits: Array[Texture2D] = []  # [บทพูด0, บทพูด1, บทพูด2]

# map ชื่อตัวละคร → side ("left" / "right")
const CHAR_SIDE := {
	"Lyra": "left",
	"Kael": "right",
}

# ── บทสนทนา: Array ของ {speaker, text} ──
const LINES: Array = [
	{"speaker": "Lyra",  "text": "สูตรนี้... มันไม่ธรรมดาเลย"},
	{"speaker": "Lyra",  "text": "ใครบางคนแอบแก้สมการหลักไว้ก่อนที่ฉันจะมาถึง"},
	{"speaker": "Lyra",  "text": "รู้จักฝีมือพวกนั้นดี ต้องเป็น Void Syndicate แน่ๆ"},
	{"speaker": "Lyra",  "text": "ถ้าปล่อยไว้อีกคืนเดียว ห้องทดลองทั้งหมดจะระเบิด"},
	{"speaker": "Lyra",  "text": "งั้นเราต้องหยุดพวกเขาที่นี่และตอนนี้เลย"},
	{"speaker": "Lyra",  "text": "...เตรียมพร้อม"},
]

var _current    := 0
var _typing     := false
var _full_text  := ""
var _auto_play  := false   # auto-advance after each line finishes
var _fast_mode  := false   # typewriter speed-up
var _auto_timer: SceneTreeTimer = null

@onready var _bg:         TextureRect   = $Background
@onready var _char_l:     TextureRect   = $CharacterLeftClip/CharacterLeft
@onready var _char_r:     TextureRect   = $CharacterRight
@onready var _panel:      Panel         = $DialoguePanel
@onready var _name_label: Label         = $DialoguePanel/NameTag/SpeakerName
@onready var _text:       RichTextLabel = $DialoguePanel/DialogueText
@onready var _next_btn:   Button        = $DialoguePanel/NextBtn
@onready var _fade:       ColorRect     = $FadeOverlay
@onready var _btn_skip:   Button        = $CtrlBar/BtnSkip
@onready var _btn_auto:   Button        = $CtrlBar/BtnAuto
var _btn_fast: Button = null


func _ready() -> void:
	if _bg:
		_bg.texture = preload("res://image/m3.jpg")
		_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	lyra_portraits = [
		preload("res://image/lyra_1.png"),
		preload("res://image/lyra_2.png"),
		preload("res://image/lyra_3.png"),
	]

	if _char_l:
		_char_l.texture = lyra_portraits[0]
	if _next_btn:
		_next_btn.pressed.connect(_on_next)
	_btn_skip.pressed.connect(_on_skip_all)
	_btn_auto.pressed.connect(_on_toggle_auto)
	_refresh_ctrl_buttons()
	# fade in
	if _fade:
		var ti := create_tween()
		ti.tween_property(_fade, "color:a", 0.0, 0.4)
		await ti.finished
	_show_line(0)


func _refresh_ctrl_buttons() -> void:
	if _btn_auto:
		_btn_auto.text = "⏸ Auto" if _auto_play else "▶ Auto"
		_btn_auto.add_theme_color_override("font_color",
			Color(0.25, 1.0, 0.55, 1.0) if _auto_play else Color(0.4, 1.0, 0.6, 0.85))
	if _btn_fast:
		_btn_fast.text = "⏩⏩ Fast" if _fast_mode else "⏩ เร่ง"
		_btn_fast.add_theme_color_override("font_color",
			Color(1.0, 0.95, 0.2, 1.0) if _fast_mode else Color(1.0, 0.78, 0.2, 0.85))

func _on_skip_all() -> void:
	_typing = false
	_auto_play = false
	_fast_mode = false
	_current = LINES.size()
	_finish()

func _on_toggle_fast() -> void:
	_fast_mode = not _fast_mode
	_refresh_ctrl_buttons()

func _on_toggle_auto() -> void:
	_auto_play = not _auto_play
	_refresh_ctrl_buttons()
	# If text is already shown and auto is turned on, trigger advance
	if _auto_play and not _typing:
		_schedule_auto_advance()

func _schedule_auto_advance() -> void:
	if _auto_timer and is_instance_valid(_auto_timer):
		return
	_auto_timer = get_tree().create_timer(1.8)
	_auto_timer.timeout.connect(func():
		_auto_timer = null
		if _auto_play and not _typing:
			_on_next())

func _show_line(idx: int) -> void:
	if idx >= LINES.size():
		_finish()
		return
	var entry: Dictionary = LINES[idx]
	var speaker: String = entry.get("speaker", "")
	var line: String    = entry.get("text", "")

	_name_label.text = speaker
	if _char_l and lyra_portraits.size() > 2:
		var portrait_idx := clampi(idx, 0, 2)
		_char_l.texture = lyra_portraits[portrait_idx]
	_update_portraits(speaker)
	_full_text = line
	_text.text = ""
	_next_btn.visible = false
	_typing = true
	_typewrite(line)

func _typewrite(text: String) -> void:
	for i in range(text.length() + 1):
		if not _typing:
			break
		_text.text = text.substr(0, i)
		var spd := TYPEWRITER_FAST if _fast_mode else TYPEWRITER_SPEED
		await get_tree().create_timer(spd).timeout
	_text.text = text
	_typing = false
	_next_btn.visible = true
	if _auto_play:
		_schedule_auto_advance()

func _update_portraits(_active_speaker: String) -> void:
	if _char_l: _char_l.modulate.a = 1.0
	if _char_r: _char_r.modulate.a = 1.0

func _on_next() -> void:
	if _typing:
		_typing = false
		_text.text = _full_text
		_next_btn.visible = true
	else:
		_current += 1
		_show_line(_current)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_on_next()
		get_viewport().set_input_as_handled()

func _finish() -> void:
	SceneTransition.fade_to("res://pre_battle_standalone.tscn")
