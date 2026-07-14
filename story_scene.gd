extends Control

const TYPEWRITER_SPEED := 0.032

var lyra_portraits: Array[Texture2D] = []  # [บทพูด0, บทพูด1, บทพูด2]

# map ชื่อตัวละคร → side ("left" / "right")
const CHAR_SIDE := {
	"Lyra": "left",
	"Kael": "right",
}

# ── บทสนทนา: Array ของ {speaker, text} ──
const LINES: Array = [
	{"speaker": "Lyra",  "text": "สายไปแล้ว..."},
	{"speaker": "Lyra",  "text": "เข้าไปได้แล้ว"},
	{"speaker": "Lyra",  "text": "เร็วกว่าที่คิด"},
	{"speaker": "Lyra",  "text": "ของยังอยู่ไหม..."},
	{"speaker": "Lyra",  "text": "ยังทัน"},
	{"speaker": "Lyra",  "text": "แค่นิดเดียว"},
	{"speaker": "Lyra",  "text": "พวกเขายังอยู่ในนี้"},
	{"speaker": "Lyra",  "text": "ไปไหนไม่ได้แล้ว"},
]

var _current    := 0
var _typing     := false
var _full_text  := ""
var _auto_play  := false   # auto-advance after each line finishes
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
		_btn_auto.text = "Auto"
		_btn_auto.add_theme_color_override("font_color",
			Color(0.25, 1.0, 0.55, 1.0) if _auto_play else Color(0.55, 0.65, 0.75, 0.75))
		var sb := StyleBoxFlat.new()
		sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6; sb.corner_radius_bottom_left = 6
		sb.set_border_width_all(1)
		if _auto_play:
			sb.bg_color     = Color(0.04, 0.18, 0.08, 0.92)
			sb.border_color = Color(0.25, 1.0, 0.55, 0.85)
		else:
			sb.bg_color     = Color(0.03, 0.05, 0.12, 0.78)
			sb.border_color = Color(0.35, 0.45, 0.60, 0.25)
		_btn_auto.add_theme_stylebox_override("normal",  sb)
		_btn_auto.add_theme_stylebox_override("pressed", sb)

func _on_skip_all() -> void:
	_typing = false
	_auto_play = false
	_current = LINES.size()
	_finish()


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
		var spd := TYPEWRITER_SPEED
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
