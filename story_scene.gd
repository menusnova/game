extends Control

const TYPEWRITER_SPEED := 0.032

# ── ใส่ภาพตรงนี้เมื่อมีไฟล์: เปลี่ยน null เป็น preload("res://image/xxx.png") ──
var bg_texture:   Texture2D = null   # ภาพพื้นหลัง scene สนทนา
var char_lyra:    Texture2D = null   # portrait Lyra (ซ้าย)
var char_kael:    Texture2D = null   # portrait Kael (ขวา)

# map ชื่อตัวละคร → side ("left" / "right")
const CHAR_SIDE := {
	"Lyra": "left",
	"Kael": "right",
}

# ── บทสนทนา: Array ของ {speaker, text} ──
const LINES: Array = [
	{"speaker": "Lyra",  "text": "สูตรนี้... มันไม่ธรรมดาเลย"},
	{"speaker": "Lyra",  "text": "ใครบางคนแอบแก้สมการหลักไว้ก่อนที่ฉันจะมาถึง"},
	{"speaker": "Kael",  "text": "รู้จักฝีมือพวกนั้นดี ต้องเป็น Void Syndicate แน่ๆ"},
	{"speaker": "Lyra",  "text": "ถ้าปล่อยไว้อีกคืนเดียว ห้องทดลองทั้งหมดจะระเบิด"},
	{"speaker": "Kael",  "text": "งั้นเราต้องหยุดพวกเขาที่นี่และตอนนี้เลย"},
	{"speaker": "Lyra",  "text": "...เตรียมพร้อม"},
]

var _current := 0
var _typing  := false
var _full_text := ""

@onready var _bg:         TextureRect   = $Background
@onready var _char_l:     TextureRect   = $CharacterLeft
@onready var _char_r:     TextureRect   = $CharacterRight
@onready var _panel:      Panel         = $DialoguePanel
@onready var _name_label: Label         = $DialoguePanel/NameTag/SpeakerName
@onready var _text:       RichTextLabel = $DialoguePanel/DialogueText
@onready var _next_btn:   Button        = $DialoguePanel/NextBtn
@onready var _fade:       ColorRect     = $FadeOverlay

func _ready() -> void:
	if _bg:
		_bg.texture = bg_texture
	if _char_l:
		_char_l.texture = char_lyra
	if _char_r:
		_char_r.texture = char_kael
	if _next_btn:
		_next_btn.pressed.connect(_on_next)
	# fade in
	if _fade:
		var ti := create_tween()
		ti.tween_property(_fade, "color:a", 0.0, 0.4)
		await ti.finished
	_show_line(0)

func _show_line(idx: int) -> void:
	if idx >= LINES.size():
		_finish()
		return
	var entry: Dictionary = LINES[idx]
	var speaker: String = entry.get("speaker", "")
	var line: String    = entry.get("text", "")

	_name_label.text = speaker
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
		await get_tree().create_timer(TYPEWRITER_SPEED).timeout
	_text.text = text
	_typing = false
	_next_btn.visible = true

func _update_portraits(active_speaker: String) -> void:
	if not _char_l or not _char_r:
		return
	var side: String = CHAR_SIDE.get(active_speaker, "left")
	var t := create_tween().set_parallel(true)
	if side == "left":
		t.tween_property(_char_l, "modulate:a", 1.0, 0.2)
		t.tween_property(_char_r, "modulate:a", 0.4, 0.2)
	else:
		t.tween_property(_char_r, "modulate:a", 1.0, 0.2)
		t.tween_property(_char_l, "modulate:a", 0.4, 0.2)

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
