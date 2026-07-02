extends Control

const SC_MAIN := "res://main_menu.tscn"

const SHOWCASE: Array = [
	{"name": "Lyra",   "level": 42, "rarity": 5, "element": "🔥", "art": null},
	{"name": "Kael",   "level": 38, "rarity": 4, "element": "⚡", "art": null},
	{"name": "Mira",   "level": 35, "rarity": 4, "element": "🧊", "art": null},
]

const ACTIVITY: Array = [
	{"icon": "⚔",  "text": "ชนะการต่อสู้ใน Chapter 1-1",    "time": "2 ชม. ที่แล้ว"},
	{"icon": "🎲",  "text": "สุ่มกาชา 10 ครั้ง — ได้ Seraph 5★", "time": "5 ชม. ที่แล้ว"},
	{"icon": "🧭",  "text": "ส่งทีมสำรวจ Zone B",              "time": "เมื่อวาน"},
	{"icon": "✅",  "text": "ทำภารกิจรายวันครบ",               "time": "เมื่อวาน"},
]

# preset avatar colors (index = avatar choice)
const AVATAR_COLORS: Array = [
	Color(0.25, 0.45, 0.95),  # blue
	Color(0.8,  0.25, 0.35),  # red
	Color(0.2,  0.75, 0.5),   # green
	Color(0.75, 0.55, 0.1),   # gold
	Color(0.5,  0.2,  0.85),  # purple
	Color(0.15, 0.65, 0.85),  # cyan
]
const AVATAR_ICONS: Array[String] = ["⚗", "⚔", "🌙", "★", "♦", "✦"]

var _player_name: String = "Trailblazer"
var _signature:   String = "\"ความลับของสูตรนั้น... ยังไม่จบ\""
var _avatar_idx:  int    = 0

@onready var _back:          Button        = $TopBar/BackBtn
@onready var _showcase_row:  GridContainer = $ShowcaseRow
@onready var _activity_list: VBoxContainer = $ActivityCard/ActivityList
@onready var _fade:          ColorRect     = $FadeOverlay
@onready var _domain_fill:   ColorRect     = $PlayerCard/DomainRow/DomainBarBg/DomainBarFill
@onready var _domain_pct:    Label         = $PlayerCard/DomainRow/DomainPct
@onready var _domain_bar_bg: Panel         = $PlayerCard/DomainRow/DomainBarBg
@onready var _name_lbl:      Label         = $PlayerCard/PlayerName
@onready var _sig_lbl:       Label         = $PlayerCard/SignatureBg/Signature
@onready var _edit_btn:      Button        = $PlayerCard/EditBtn
@onready var _avatar_icon:   Panel         = $PlayerCard/AvatarIcon

var _avatar_label: Label   # emoji label inside avatar (created in _ready)
var _edit_popup:   Control # edit name/sig popup
var _avatar_popup: Control # avatar picker popup

const STATS: Array = [
	{"icon": "🗓", "label": "เริ่มเล่น",          "value": "1 ม.ค. 2568"},
	{"icon": "⏱", "label": "วันที่เล่น",          "value": "12 วัน"},
	{"icon": "🌐", "label": "ระดับโลก",            "value": "3"},
	{"icon": "👤", "label": "ตัวละครที่มี",        "value": "4"},
	{"icon": "⭐", "label": "ตัวละครระดับสูงสุด",  "value": "1"},
	{"icon": "⚔",  "label": "การต่อสู้",           "value": "38"},
	{"icon": "✅", "label": "ความสำเร็จ",          "value": "7 / 120"},
	{"icon": "🎲", "label": "สุ่มกาชาทั้งหมด",    "value": "47"},
]

func _ready() -> void:
	if _back:
		_back.pressed.connect(_go_back)
	_build_showcase()
	_build_activity()
	_build_stats()
	_update_domain()
	DomainManager.domain_changed.connect(_on_domain_changed)

	# avatar emoji overlay
	_avatar_label = Label.new()
	_avatar_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_avatar_label.add_theme_font_size_override("font_size", 26)
	_avatar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _avatar_icon:
		_avatar_icon.add_child(_avatar_label)
	_refresh_avatar()

	if _edit_btn:
		_edit_btn.pressed.connect(_open_edit_popup)
	if _avatar_icon:
		_avatar_icon.gui_input.connect(_on_avatar_click)

	if _fade:
		var t := create_tween()
		t.tween_property(_fade, "color:a", 0.0, 0.35)

# ── Avatar ────────────────────────────────────────────────────────
func _refresh_avatar() -> void:
	if _avatar_label: _avatar_label.text = AVATAR_ICONS[_avatar_idx]
	if _avatar_icon:  _avatar_icon.modulate = AVATAR_COLORS[_avatar_idx]
	if _avatar_label: _avatar_label.modulate = Color(1, 1, 1, 1)

func _on_avatar_click(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if _avatar_popup and is_instance_valid(_avatar_popup):
			_avatar_popup.queue_free()
		_avatar_popup = _make_avatar_popup()
		add_child(_avatar_popup)

func _make_avatar_popup() -> Control:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.98)
	sb.border_width_top = 1; sb.border_width_right = 1
	sb.border_width_bottom = 1; sb.border_width_left = 1
	sb.border_color = Color(0.4, 0.6, 1, 0.25)
	sb.corner_radius_top_left = 16; sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_right = 16; sb.corner_radius_bottom_left = 16
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -180; panel.offset_right = 180
	panel.offset_top  = -110; panel.offset_bottom = 110

	var title := Label.new()
	title.text = "เลือกอวตาร"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 16; title.offset_bottom = 40
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var grid := HBoxContainer.new()
	grid.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grid.offset_left = -160; grid.offset_right = 160
	grid.offset_top  = -28;  grid.offset_bottom = 50
	grid.add_theme_constant_override("separation", 12)
	panel.add_child(grid)

	for i in AVATAR_COLORS.size():
		var btn := _make_avatar_btn(i)
		grid.add_child(btn)

	var close_btn := Button.new()
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(1, 1, 1, 0.07)
	csb.corner_radius_top_left = 8; csb.corner_radius_top_right = 8
	csb.corner_radius_bottom_right = 8; csb.corner_radius_bottom_left = 8
	close_btn.add_theme_stylebox_override("normal", csb)
	close_btn.add_theme_stylebox_override("hover",  csb)
	close_btn.add_theme_stylebox_override("pressed", csb)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.text = "ยกเลิก"
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	close_btn.offset_top = -44; close_btn.offset_bottom = -12
	close_btn.offset_left = 60; close_btn.offset_right = -60
	panel.add_child(close_btn)

	dim.add_child(panel)
	close_btn.pressed.connect(func(): dim.queue_free())
	dim.gui_input.connect(func(ev2: InputEvent):
		if ev2 is InputEventMouseButton and ev2.pressed:
			dim.queue_free())
	return dim

func _make_avatar_btn(idx: int) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(48, 48)
	var sb := StyleBoxFlat.new()
	sb.bg_color = AVATAR_COLORS[idx]
	sb.corner_radius_top_left = 24; sb.corner_radius_top_right = 24
	sb.corner_radius_bottom_right = 24; sb.corner_radius_bottom_left = 24
	if idx == _avatar_idx:
		sb.border_width_top = 2; sb.border_width_right = 2
		sb.border_width_bottom = 2; sb.border_width_left = 2
		sb.border_color = Color(1, 1, 1, 0.9)
	p.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = AVATAR_ICONS[idx]
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(lbl)

	p.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_avatar_idx = idx
			_refresh_avatar()
			if _avatar_popup and is_instance_valid(_avatar_popup):
				_avatar_popup.queue_free())
	return p

# ── Edit name / signature popup ──────────────────────────────────
func _open_edit_popup() -> void:
	if _edit_popup and is_instance_valid(_edit_popup):
		_edit_popup.queue_free()
	_edit_popup = _make_edit_popup()
	add_child(_edit_popup)

func _make_edit_popup() -> Control:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.98)
	sb.border_width_top = 1; sb.border_width_right = 1
	sb.border_width_bottom = 1; sb.border_width_left = 1
	sb.border_color = Color(0.4, 0.6, 1, 0.25)
	sb.corner_radius_top_left = 16; sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_right = 16; sb.corner_radius_bottom_left = 16
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -220; panel.offset_right  = 220
	panel.offset_top  = -140; panel.offset_bottom = 140

	var title := Label.new()
	title.text = "แก้ไขโปรไฟล์"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 18; title.offset_bottom = 44
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	# name field
	var name_hint := Label.new()
	name_hint.text = "ชื่อผู้เล่น"
	name_hint.add_theme_font_size_override("font_size", 11)
	name_hint.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 0.7))
	name_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_hint.offset_left = 24; name_hint.offset_right = -24
	name_hint.offset_top = 52;  name_hint.offset_bottom = 68
	panel.add_child(name_hint)

	var name_edit := _make_line_edit(_player_name)
	name_edit.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_edit.offset_left = 24;  name_edit.offset_right  = -24
	name_edit.offset_top  = 70;  name_edit.offset_bottom = 98
	name_edit.max_length  = 20
	panel.add_child(name_edit)

	# signature field
	var sig_hint := Label.new()
	sig_hint.text = "คำขวัญ"
	sig_hint.add_theme_font_size_override("font_size", 11)
	sig_hint.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 0.7))
	sig_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sig_hint.offset_left = 24; sig_hint.offset_right = -24
	sig_hint.offset_top = 108; sig_hint.offset_bottom = 124
	panel.add_child(sig_hint)

	var sig_edit := _make_line_edit(_signature)
	sig_edit.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sig_edit.offset_left = 24;  sig_edit.offset_right  = -24
	sig_edit.offset_top  = 126; sig_edit.offset_bottom = 154
	sig_edit.max_length  = 50
	panel.add_child(sig_edit)

	# buttons row
	var cancel_btn := _make_popup_btn("ยกเลิก", false)
	cancel_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	cancel_btn.offset_left = 24; cancel_btn.offset_right  = 184
	cancel_btn.offset_top  = -52; cancel_btn.offset_bottom = -16
	panel.add_child(cancel_btn)

	var ok_btn := _make_popup_btn("บันทึก", true)
	ok_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ok_btn.offset_left = -196; ok_btn.offset_right  = -24
	ok_btn.offset_top  = -52;  ok_btn.offset_bottom = -16
	panel.add_child(ok_btn)

	dim.add_child(panel)

	cancel_btn.pressed.connect(func(): dim.queue_free())
	ok_btn.pressed.connect(func():
		var new_name := name_edit.text.strip_edges()
		if new_name.length() > 0:
			_player_name = new_name
		_signature = sig_edit.text.strip_edges()
		_name_lbl.text = _player_name
		_sig_lbl.text  = _signature
		dim.queue_free())

	return dim

func _make_line_edit(default_text: String) -> LineEdit:
	var le := LineEdit.new()
	le.text = default_text
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.06)
	sb.border_width_top = 1; sb.border_width_right = 1
	sb.border_width_bottom = 1; sb.border_width_left = 1
	sb.border_color = Color(0.4, 0.6, 1, 0.35)
	sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8; sb.corner_radius_bottom_left = 8
	sb.content_margin_left = 10; sb.content_margin_right = 10
	sb.content_margin_top = 4;   sb.content_margin_bottom = 4
	le.add_theme_stylebox_override("normal", sb)
	le.add_theme_stylebox_override("focus",  sb)
	le.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	le.add_theme_font_size_override("font_size", 14)
	return le

func _make_popup_btn(label: String, primary: bool) -> Button:
	var btn := Button.new()
	var sb := StyleBoxFlat.new()
	if primary:
		sb.bg_color = Color(0.15, 0.35, 0.85, 1.0)
	else:
		sb.bg_color = Color(1, 1, 1, 0.07)
	sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8; sb.corner_radius_bottom_left = 8
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	btn.add_theme_font_size_override("font_size", 13)
	btn.text = label
	return btn

# ── Domain bar ───────────────────────────────────────────────────
func _update_domain() -> void:
	var pct := DomainManager.get_percent()
	_on_domain_changed(pct)

func _on_domain_changed(pct: float) -> void:
	if not is_inside_tree(): return
	if _domain_pct: _domain_pct.text = "%d%%" % int(pct)
	_apply_domain_bar.call_deferred(pct)

func _apply_domain_bar(pct: float) -> void:
	if not is_inside_tree() or not is_instance_valid(_domain_bar_bg): return
	var bar_w: float = _domain_bar_bg.size.x
	_domain_fill.size.x = bar_w * (pct / 100.0)

# ── Stats card ───────────────────────────────────────────────────
var _stats_card:  Panel
var _stats_open:  bool  = false
var _stats_tween: Tween

func _build_stats() -> void:
	# ⋮ button on PlayerCard (top-right corner)
	var dot_btn := Button.new()
	dot_btn.text = "⋮"
	dot_btn.position = Vector2(316, 8)
	dot_btn.size     = Vector2(28, 28)
	dot_btn.add_theme_font_size_override("font_size", 18)
	dot_btn.add_theme_color_override("font_color", Color(0.7, 0.87, 1, 0.7))
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = Color(0, 0, 0, 0)
	dot_btn.add_theme_stylebox_override("normal",  dsb)
	dot_btn.add_theme_stylebox_override("hover",   dsb)
	dot_btn.add_theme_stylebox_override("pressed", dsb)
	dot_btn.add_theme_stylebox_override("focus",   dsb)
	dot_btn.pressed.connect(_toggle_stats)
	get_node("PlayerCard").add_child(dot_btn)

	# Stats card (hidden by default, slides in from right)
	_stats_card = Panel.new()
	_stats_card.position = Vector2(784, 60)  # off-screen right
	_stats_card.size     = Vector2(370, 548)
	_stats_card.visible  = false
	_stats_card.z_index  = 10
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.024, 0.047, 0.102, 0.96)
	sb.border_width_top = 1; sb.border_width_right = 1
	sb.border_width_bottom = 1; sb.border_width_left = 1
	sb.border_color = Color(0.388, 0.624, 1, 0.25)
	sb.corner_radius_top_left = 16; sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_right = 16; sb.corner_radius_bottom_left = 16
	add_child(_stats_card)

	# Header
	var header := Label.new()
	header.text = "สถิติผู้เล่น"
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color(0.388, 0.624, 1, 0.8))
	header.position = Vector2(16, 14)
	header.size     = Vector2(320, 22)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_card.add_child(header)

	var hdiv := ColorRect.new()
	hdiv.color    = Color(0.388, 0.624, 1, 0.15)
	hdiv.position = Vector2(12, 38)
	hdiv.size     = Vector2(346, 1)
	hdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_card.add_child(hdiv)

	var y := 48.0
	for i in STATS.size():
		var data: Dictionary = STATS[i]

		var row_bg := ColorRect.new()
		row_bg.color    = Color(1, 1, 1, 0.02) if i % 2 == 0 else Color(0, 0, 0, 0)
		row_bg.position = Vector2(0, y - 4)
		row_bg.size     = Vector2(370, 52)
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stats_card.add_child(row_bg)

		var icon_lbl := Label.new()
		icon_lbl.text = str(data["icon"])
		icon_lbl.add_theme_font_size_override("font_size", 18)
		icon_lbl.position = Vector2(16, y + 6)
		icon_lbl.size     = Vector2(28, 28)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stats_card.add_child(icon_lbl)

		var lbl := Label.new()
		lbl.text = str(data["label"])
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.65, 0.78, 1.0, 0.6))
		lbl.position = Vector2(52, y + 4)
		lbl.size     = Vector2(200, 18)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stats_card.add_child(lbl)

		var val_lbl := Label.new()
		val_lbl.text = str(data["value"])
		val_lbl.add_theme_font_size_override("font_size", 15)
		val_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
		val_lbl.position = Vector2(52, y + 22)
		val_lbl.size     = Vector2(280, 22)
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stats_card.add_child(val_lbl)

		if i < STATS.size() - 1:
			var div := ColorRect.new()
			div.color    = Color(1, 1, 1, 0.05)
			div.position = Vector2(12, y + 46)
			div.size     = Vector2(346, 1)
			div.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_stats_card.add_child(div)

		y += 56.0

func _toggle_stats() -> void:
	if _stats_tween and _stats_tween.is_running():
		_stats_tween.kill()
	_stats_open = not _stats_open
	_stats_card.visible = true
	var target_x: float = 388.0 if _stats_open else 784.0
	_stats_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_stats_tween.tween_property(_stats_card, "position:x", target_x, 0.22)
	if not _stats_open:
		await _stats_tween.finished
		_stats_card.visible = false

# ── Showcase ─────────────────────────────────────────────────────
func _build_showcase() -> void:
	if not _showcase_row: return
	for q in _showcase_row.get_children():
		q.queue_free()
	for entry in SHOWCASE:
		_showcase_row.add_child(_make_showcase_card(entry))

func _make_showcase_card(data: Dictionary) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(168, 255)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var is_empty: bool = str(data.get("name", "")) == ""

	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left    = 14
	sb.corner_radius_top_right   = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left  = 14
	sb.border_width_top = 1; sb.border_width_right = 1
	sb.border_width_bottom = 1; sb.border_width_left = 1

	if is_empty:
		sb.bg_color    = Color(1, 1, 1, 0.025)
		sb.border_color = Color(1, 1, 1, 0.06)
		card.add_theme_stylebox_override("panel", sb)
		var plus := Label.new()
		plus.text = "+"
		plus.add_theme_font_size_override("font_size", 28)
		plus.add_theme_color_override("font_color", Color(1, 1, 1, 0.15))
		plus.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		plus.offset_left = -16; plus.offset_right = 16
		plus.offset_top = -18; plus.offset_bottom = 18
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(plus)
		return card

	sb.bg_color = Color(0.031, 0.063, 0.137, 0.92)
	sb.border_color = Color(0.388, 0.624, 1, 0.12)
	card.add_theme_stylebox_override("panel", sb)

	var art := TextureRect.new()
	art.texture = data.get("art", null)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dim.offset_top = -80
	dim.color = Color(0, 0, 0.04, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dim)

	var rarity: int = int(data.get("rarity", 3))
	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.add_theme_font_size_override("font_size", 12)
	match rarity:
		5: stars.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 0.95))
		4: stars.add_theme_color_override("font_color", Color(0.75, 0.55, 1.0, 0.95))
		_: stars.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.95))
	stars.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stars.offset_left = 10; stars.offset_right = 200
	stars.offset_bottom = -38; stars.offset_top = -58
	card.add_child(stars)

	var elem := Label.new()
	elem.text = str(data.get("element", ""))
	elem.add_theme_font_size_override("font_size", 16)
	elem.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	elem.offset_left = -32; elem.offset_right = -6
	elem.offset_top = 8; elem.offset_bottom = 30
	card.add_child(elem)

	var name_lbl := Label.new()
	name_lbl.text = str(data.get("name", ""))
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	name_lbl.offset_left = 10; name_lbl.offset_right = 200
	name_lbl.offset_bottom = -18; name_lbl.offset_top = -40
	card.add_child(name_lbl)

	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d" % int(data.get("level", 1))
	lv_lbl.add_theme_font_size_override("font_size", 11)
	lv_lbl.add_theme_color_override("font_color", Color(0.7, 0.87, 1, 0.7))
	lv_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lv_lbl.offset_left = 10; lv_lbl.offset_right = 120
	lv_lbl.offset_bottom = -4; lv_lbl.offset_top = -20
	card.add_child(lv_lbl)

	return card

# ── Activity ─────────────────────────────────────────────────────
func _build_activity() -> void:
	if not _activity_list: return
	for a in ACTIVITY:
		_activity_list.add_child(_make_activity_row(a))

func _make_activity_row(data: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 46)
	row.add_theme_constant_override("separation", 12)

	var icon := Label.new()
	icon.text = str(data.get("icon", ""))
	icon.add_theme_font_size_override("font_size", 18)
	icon.custom_minimum_size = Vector2(28, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)

	var txt := Label.new()
	txt.text = str(data.get("text", ""))
	txt.add_theme_font_size_override("font_size", 13)
	txt.add_theme_color_override("font_color", Color(0.9, 0.93, 1, 0.9))
	col.add_child(txt)

	var time_lbl := Label.new()
	time_lbl.text = str(data.get("time", ""))
	time_lbl.add_theme_font_size_override("font_size", 10)
	time_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	col.add_child(time_lbl)

	row.add_child(col)

	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.add_child(row)
	var div := ColorRect.new()
	div.color = Color(1, 1, 1, 0.05)
	div.custom_minimum_size = Vector2(0, 1)
	wrap.add_child(div)
	return wrap

# ── Navigation ───────────────────────────────────────────────────
func _go_back() -> void:
	if DomainManager.domain_changed.is_connected(_on_domain_changed):
		DomainManager.domain_changed.disconnect(_on_domain_changed)
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(SC_MAIN)
