extends Control

const SC_MAIN := "res://main_menu.tscn"

# ── ข้อมูล showcase ตัวละคร (ใส่เองได้) ──
# { name, level, rarity(3-5), element, art(Texture2D) }
const SHOWCASE: Array = [
	{"name": "Lyra",   "level": 42, "rarity": 5, "element": "🔥", "art": null},
	{"name": "Kael",   "level": 38, "rarity": 4, "element": "⚡", "art": null},
	{"name": "Mira",   "level": 35, "rarity": 4, "element": "🧊", "art": null},
	{"name": "",       "level": 0,  "rarity": 0, "element": "",   "art": null},
]

# ── ข้อมูล activity ──
const ACTIVITY: Array = [
	{"icon": "⚔",  "text": "ชนะการต่อสู้ใน Chapter 1-1",    "time": "2 ชม. ที่แล้ว"},
	{"icon": "🎲",  "text": "สุ่มกาชา 10 ครั้ง — ได้ Seraph 5★", "time": "5 ชม. ที่แล้ว"},
	{"icon": "🧭",  "text": "ส่งทีมสำรวจ Zone B",              "time": "เมื่อวาน"},
	{"icon": "✅",  "text": "ทำภารกิจรายวันครบ",                "time": "เมื่อวาน"},
]

@onready var _back:         Button      = $TopBar/BackBtn
@onready var _showcase_row: HBoxContainer = $ShowcaseRow
@onready var _activity_list: VBoxContainer = $ActivityCard/ActivityList
@onready var _fade:         ColorRect   = $FadeOverlay
@onready var _domain_fill:  ColorRect   = $PlayerCard/DomainRow/DomainBarBg/DomainBarFill
@onready var _domain_pct:   Label       = $PlayerCard/DomainRow/DomainPct
@onready var _domain_bar_bg: Panel      = $PlayerCard/DomainRow/DomainBarBg

func _ready() -> void:
	_back.pressed.connect(_go_back)
	_build_showcase()
	_build_activity()
	_update_domain()
	DomainManager.domain_changed.connect(_on_domain_changed)
	# fade in
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.35)

func _update_domain() -> void:
	var pct := DomainManager.get_percent()
	_on_domain_changed(pct)

func _on_domain_changed(pct: float) -> void:
	_domain_pct.text = "%d%%" % int(pct)
	# wait one frame for bar bg to lay out before reading size
	await get_tree().process_frame
	var bar_w: float = _domain_bar_bg.size.x
	_domain_fill.size.x = bar_w * (pct / 100.0)

func _build_showcase() -> void:
	for q in _showcase_row.get_children():
		q.queue_free()
	for entry in SHOWCASE:
		_showcase_row.add_child(_make_showcase_card(entry))

func _make_showcase_card(data: Dictionary) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(264, 220)
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
		card.add_theme_style_override("panel", sb)
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
	card.add_theme_style_override("panel", sb)

	# art
	var art := TextureRect.new()
	art.texture = data.get("art", null)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art)

	# bottom gradient dim
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dim.offset_top = -80
	dim.color = Color(0, 0, 0.04, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dim)

	# rarity stars
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

	# element badge
	var elem := Label.new()
	elem.text = str(data.get("element", ""))
	elem.add_theme_font_size_override("font_size", 16)
	elem.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	elem.offset_left = -32; elem.offset_right = -6
	elem.offset_top = 8; elem.offset_bottom = 30
	card.add_child(elem)

	# name
	var name_lbl := Label.new()
	name_lbl.text = str(data.get("name", ""))
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	name_lbl.offset_left = 10; name_lbl.offset_right = 200
	name_lbl.offset_bottom = -18; name_lbl.offset_top = -40
	card.add_child(name_lbl)

	# level
	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d" % int(data.get("level", 1))
	lv_lbl.add_theme_font_size_override("font_size", 11)
	lv_lbl.add_theme_color_override("font_color", Color(0.7, 0.87, 1, 0.7))
	lv_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lv_lbl.offset_left = 10; lv_lbl.offset_right = 120
	lv_lbl.offset_bottom = -4; lv_lbl.offset_top = -20
	card.add_child(lv_lbl)

	return card

func _build_activity() -> void:
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

	# divider
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.add_child(row)
	var div := ColorRect.new()
	div.color = Color(1, 1, 1, 0.05)
	div.custom_minimum_size = Vector2(0, 1)
	wrap.add_child(div)
	return wrap

func _go_back() -> void:
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(SC_MAIN)
