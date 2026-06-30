extends CanvasLayer


const PANEL_HEIGHT := 380.0
const SCREEN_H     := 648.0
const OPEN_Y       := SCREEN_H - PANEL_HEIGHT

enum Tab { DAILY, STORY, WEEKLY }

# ── Quest data ──────────────────────────────────────────────────
# แต่ละ quest: { id, label, current, total, go_scene }
# go_scene = "" หมายถึงไม่มีปุ่ม "ไป"
const QUESTS := {
	Tab.DAILY: [
		{"id": "battle",    "label": "ต่อสู้ให้ครบ",     "current": 0, "total": 3, "go": "battle"},
		{"id": "gacha",     "label": "สุ่มกาชา",          "current": 0, "total": 1, "go": "gacha"},
		{"id": "expedition","label": "ส่งสำรวจ",           "current": 0, "total": 1, "go": "expedition"},
		{"id": "alchemist", "label": "ใช้ห้องปฏิบัติการ",  "current": 0, "total": 1, "go": "alchemist"},
	],
	Tab.STORY: [
		{"id": "story_1_1", "label": "Chapter 1-1: ห้องปฏิบัติการต้องห้าม", "current": 0, "total": 1, "go": "adventure"},
		{"id": "story_1_2", "label": "Chapter 1-2: ความลับของสูตร",          "current": 0, "total": 1, "go": "adventure"},
		{"id": "story_1_3", "label": "Chapter 1-3: เผชิญหน้า",               "current": 0, "total": 1, "go": "adventure"},
	],
	Tab.WEEKLY: [
		{"id": "arena_5",   "label": "ชนะ Arena 5 ครั้ง",  "current": 0, "total": 5, "go": "arena"},
		{"id": "mission_3", "label": "ทำภารกิจหลัก 3 ครั้ง","current": 0, "total": 3, "go": "adventure"},
	],
}

var _current_tab: Tab = Tab.DAILY
var _is_open := false

@onready var _sheet:     Panel        = $Sheet
@onready var _dim:       ColorRect    = $Dim
@onready var _tab_daily: Button       = $Sheet/Header/Tabs/TabDaily
@onready var _tab_story: Button       = $Sheet/Header/Tabs/TabStory
@onready var _tab_week:  Button       = $Sheet/Header/Tabs/TabWeekly
@onready var _list:      VBoxContainer = $Sheet/ScrollContainer/QuestList
@onready var _close_btn: Button       = $Sheet/Header/CloseBtn

func _ready() -> void:
	if _sheet:
		_sheet.position.y = SCREEN_H
	if _dim:
		_dim.modulate.a   = 0.0
		_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _tab_daily:
		_tab_daily.pressed.connect(func(): _switch_tab(Tab.DAILY))
	if _tab_story:
		_tab_story.pressed.connect(func(): _switch_tab(Tab.STORY))
	if _tab_week:
		_tab_week.pressed.connect(func():  _switch_tab(Tab.WEEKLY))
	if _close_btn:
		_close_btn.pressed.connect(close)
	if _dim:
		_dim.gui_input.connect(_on_dim_input)
	_rebuild_list()

func open() -> void:
	if _is_open:
		return
	_is_open = true
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween().set_parallel(true)
	t.tween_property(_sheet, "position:y", OPEN_Y, 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_dim, "modulate:a", 1.0, 0.22)

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween().set_parallel(true)
	t.tween_property(_sheet, "position:y", SCREEN_H, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_dim, "modulate:a", 0.0, 0.2)

func _on_dim_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		close()

func _switch_tab(tab: Tab) -> void:
	_current_tab = tab
	_update_tab_style()
	_rebuild_list()

func _update_tab_style() -> void:
	for btn in [_tab_daily, _tab_story, _tab_week]:
		btn.modulate = Color(1, 1, 1, 0.4)
	match _current_tab:
		Tab.DAILY: _tab_daily.modulate = Color(1, 1, 1, 1.0)
		Tab.STORY: _tab_story.modulate = Color(1, 1, 1, 1.0)
		Tab.WEEKLY: _tab_week.modulate = Color(1, 1, 1, 1.0)

func _rebuild_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	var quests: Array = QUESTS.get(_current_tab, [])
	for q in quests:
		_list.add_child(_make_row(q))

func _make_row(q: Dictionary) -> Control:
	var row := _QuestRow.new(q)
	return row

# ── Inner class: one quest row ────────────────────────────────
class _QuestRow extends Control:
	func _init(q: Dictionary) -> void:
		custom_minimum_size = Vector2(0, 64)

		# background
		var bg := ColorRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(1, 1, 1, 0.03)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)

		# done tint
		var done: bool = int(q.get("current", 0)) >= int(q.get("total", 1))

		# label
		var lbl := Label.new()
		lbl.text = ("✓  " if done else "○  ") + str(q.get("label", ""))
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 1.0, 0.6, 0.9) if done else Color(0.9, 0.93, 1.0, 0.95))
		lbl.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		lbl.offset_left   = 18
		lbl.offset_right  = 800
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(lbl)

		# progress bar
		var bar_bg := ColorRect.new()
		bar_bg.color = Color(1, 1, 1, 0.07)
		bar_bg.size = Vector2(220, 6)
		bar_bg.position = Vector2(18, 46)
		add_child(bar_bg)

		var total: int = max(1, int(q.get("total", 1)))
		var cur:   int = clampi(int(q.get("current", 0)), 0, total)
		var fill := ColorRect.new()
		fill.color = Color(0.3, 0.85, 0.5, 0.9) if done else Color(0.37, 0.62, 1.0, 0.9)
		fill.size  = Vector2(220.0 * cur / total, 6)
		fill.position = Vector2(18, 46)
		add_child(fill)

		# progress count
		var cnt := Label.new()
		cnt.text = "%d/%d" % [cur, total]
		cnt.add_theme_font_size_override("font_size", 11)
		cnt.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
		cnt.position = Vector2(246, 40)
		add_child(cnt)

		# "ไป" button (only if not done)
		if not done and str(q.get("go", "")) != "":
			var btn := Button.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.15, 0.33, 0.78, 1.0)
			sb.corner_radius_top_left    = 8
			sb.corner_radius_top_right   = 8
			sb.corner_radius_bottom_right = 8
			sb.corner_radius_bottom_left  = 8
			btn.add_theme_stylebox_override("normal",  sb)
			btn.add_theme_stylebox_override("hover",   sb)
			btn.add_theme_stylebox_override("pressed", sb)
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			btn.add_theme_font_size_override("font_size", 12)
			btn.text = "ไป ›"
			btn.size = Vector2(64, 32)
			btn.position = Vector2(1060, 16)
			add_child(btn)

		# divider
		var div := ColorRect.new()
		div.color = Color(1, 1, 1, 0.05)
		div.size  = Vector2(1152, 1)
		div.position = Vector2(0, 63)
		div.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(div)
