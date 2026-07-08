extends Control

const TYPEWRITER_SPEED := 0.032
const TYPEWRITER_FAST  := 0.006   # speed-up mode

var bg_texture:   Texture2D = null
var char_kael:    Texture2D = null
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

var _btn_skip:  Button = null
var _btn_auto:  Button = null
var _btn_fast:  Button = null

@onready var _bg:         TextureRect   = $Background
@onready var _char_l:     TextureRect   = $CharacterLeft
@onready var _char_r:     TextureRect   = $CharacterRight
@onready var _panel:      Panel         = $DialoguePanel
@onready var _name_label: Label         = $DialoguePanel/NameTag/SpeakerName
@onready var _text:       RichTextLabel = $DialoguePanel/DialogueText
@onready var _next_btn:   Button        = $DialoguePanel/NextBtn
@onready var _fade:       ColorRect     = $FadeOverlay

func _load_png_remove_white(path: String) -> ImageTexture:
	var buf := FileAccess.get_file_as_bytes(path)
	if buf.is_empty(): return null
	var img := Image.new()
	if img.load_png_from_buffer(buf) != OK: return null
	img.convert(Image.FORMAT_RGBA8)
	# Check if image already has transparency (alpha channel used)
	var has_transparency := false
	for y in range(0, img.get_height(), 8):
		for x in range(0, img.get_width(), 8):
			if img.get_pixel(x, y).a < 0.99:
				has_transparency = true
				break
		if has_transparency:
			break
	if not has_transparency:
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				var whiteness := minf(c.r, minf(c.g, c.b))
				var a := clampf((1.0 - whiteness) / 0.35, 0.0, 1.0)
				img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	return ImageTexture.create_from_image(img)

func _ready() -> void:
	var _buf := FileAccess.get_file_as_bytes("res://image/m3.jpg")
	if not _buf.is_empty():
		var _img := Image.new()
		if _img.load_jpg_from_buffer(_buf) == OK:
			bg_texture = ImageTexture.create_from_image(_img)
	if _bg:
		_bg.texture = bg_texture
		_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	lyra_portraits = [
		_load_png_remove_white("res://image/lyra_1.png"),
		_load_png_remove_white("res://image/lyra_2.png"),
		_load_png_remove_white("res://image/lyra_3.png"),
	]

	if _char_l:
		_char_l.texture = lyra_portraits[0] if lyra_portraits.size() > 0 else null
		_char_l.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_char_l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_char_l.offset_left = 0
		_char_l.offset_top = 0
		_char_l.offset_right = 460
		_char_l.offset_bottom = 700
	if _char_r:
		_char_r.texture = char_kael
	if _next_btn:
		_next_btn.pressed.connect(_on_next)
	_build_dialogue_controls()
	# fade in
	if _fade:
		var ti := create_tween()
		ti.tween_property(_fade, "color:a", 0.0, 0.4)
		await ti.finished
	_show_line(0)

func _build_dialogue_controls() -> void:
	const BTN_W := 72.0; const BTN_H := 28.0
	const BY    := 10.0  # y from top of screen
	const GAP   := 6.0
	const RIGHT  := 1152.0

	var _make_ctrl_btn := func(label: String, bx: float, accent: Color) -> Button:
		var b := Button.new()
		b.text = label
		b.position = Vector2(bx, BY)
		b.size = Vector2(BTN_W, BTN_H)
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.85))
		var sb_n := StyleBoxFlat.new()
		sb_n.bg_color = Color(0.03, 0.05, 0.12, 0.78)
		sb_n.border_color = Color(accent.r, accent.g, accent.b, 0.3)
		for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: sb_n.set_border_width(s, 1)
		for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
			sb_n.set(r, 6)
		var sb_h := sb_n.duplicate() as StyleBoxFlat
		sb_h.bg_color = Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 0.92)
		sb_h.border_color = Color(accent.r, accent.g, accent.b, 0.65)
		b.add_theme_stylebox_override("normal",  sb_n)
		b.add_theme_stylebox_override("hover",   sb_h)
		b.add_theme_stylebox_override("pressed", sb_n)
		b.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
		b.z_index = 10
		add_child(b)
		return b

	var skip_x := RIGHT - BTN_W - 10
	var fast_x := skip_x - BTN_W - GAP
	var auto_x := fast_x - BTN_W - GAP

	_btn_skip = _make_ctrl_btn.call("⏭ Skip", skip_x, Color(1.0, 0.4, 0.4))
	_btn_fast = _make_ctrl_btn.call("⏩ เร่ง",  fast_x, Color(1.0, 0.78, 0.2))
	_btn_auto = _make_ctrl_btn.call("▶ Auto",  auto_x, Color(0.4, 1.0, 0.6))

	_btn_skip.pressed.connect(_on_skip_all)
	_btn_fast.pressed.connect(_on_toggle_fast)
	_btn_auto.pressed.connect(_on_toggle_auto)
	_refresh_ctrl_buttons()

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
