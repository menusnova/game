extends CanvasLayer

signal dialogue_finished

const TYPEWRITER_SPEED := 0.03

var _lines: Array[String] = []
var _speakers: Array[String] = []
var _current := 0
var _typing := false
var _full_text := ""

@onready var _box: Panel = $Root/Box
@onready var _speaker_label: Label = $Root/Box/SpeakerName
@onready var _text_label: RichTextLabel = $Root/Box/DialogueText
@onready var _next_hint: Label = $Root/Box/NextHint
@onready var _char_art: TextureRect = $Root/CharacterArt

func start(lines: Array[String], speakers: Array[String]) -> void:
	_lines = lines
	_speakers = speakers
	_current = 0
	_box.modulate.a = 0.0
	visible = true
	var t := create_tween()
	t.tween_property(_box, "modulate:a", 1.0, 0.25)
	await t.finished
	_show_line(_current)

func _show_line(idx: int) -> void:
	if idx >= _lines.size():
		_finish()
		return
	_speaker_label.text = _speakers[idx] if idx < _speakers.size() else ""
	_full_text = _lines[idx]
	_text_label.text = ""
	_next_hint.visible = false
	_typing = true
	_typewrite(_full_text)

func _typewrite(text: String) -> void:
	var chars := text.length()
	for i in range(chars + 1):
		if not _typing:
			break
		_text_label.text = text.substr(0, i)
		await get_tree().create_timer(TYPEWRITER_SPEED).timeout
	_text_label.text = text
	_typing = false
	_next_hint.visible = true

func _unhandled_input(ev: InputEvent) -> void:
	if not visible:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if _typing:
			_typing = false
			_text_label.text = _full_text
			_next_hint.visible = true
		else:
			_current += 1
			_show_line(_current)
		get_viewport().set_input_as_handled()

func _finish() -> void:
	var t := create_tween()
	t.tween_property(_box, "modulate:a", 0.0, 0.2)
	await t.finished
	visible = false
	dialogue_finished.emit()
