extends CanvasLayer

enum Tab { DAILY, WEEKLY, ENDGAME, CHALLENGE }

var _current_tab: Tab = Tab.DAILY
var _is_open := false

const QUESTS := {
	Tab.DAILY: [
		{"id": "d_login",  "label": "ล็อกอินประจำวัน",    "current": 1, "total": 1, "go": "",          "reward": "crystal", "reward_n": 20},
		{"id": "d_battle", "label": "ต่อสู้ 3 ครั้ง",       "current": 0, "total": 3, "go": "battle",    "reward": "crystal", "reward_n": 60},
		{"id": "d_gacha",  "label": "สุ่มกาชา 1 ครั้ง",     "current": 0, "total": 1, "go": "gacha",     "reward": "crystal", "reward_n": 30},
		{"id": "d_alch",   "label": "ใช้ห้องปฏิบัติการ",    "current": 0, "total": 1, "go": "alchemist", "reward": "crystal", "reward_n": 30},
	],
	Tab.WEEKLY: [
		{"id": "w_boss",    "label": "สังหาร Boss รายสัปดาห์",     "current": 0, "total": 1,  "go": "battle",    "reward": "crystal", "reward_n": 120},
		{"id": "w_battle5", "label": "ต่อสู้ 5 ครั้งในสัปดาห์",      "current": 0, "total": 5,  "go": "battle",    "reward": "crystal", "reward_n": 100},
		{"id": "w_gacha3",  "label": "สุ่มกาชา 3 ครั้งในสัปดาห์",    "current": 0, "total": 3,  "go": "gacha",     "reward": "crystal", "reward_n": 90},
		{"id": "w_alch5",   "label": "ผสมสารเคมี 5 ครั้งในสัปดาห์",  "current": 0, "total": 5,  "go": "alchemist", "reward": "crystal", "reward_n": 80},
		{"id": "w_elem3",   "label": "ใช้ธาตุ 3 ชนิดในการต่อสู้",    "current": 0, "total": 3,  "go": "battle",    "reward": "วัสดุ Ascend ×6"},
	],
	Tab.ENDGAME: [
		{"id": "eg_boss",   "label": "สังหาร Weekly Boss",  "current": 0, "total": 1, "go": "battle", "reward": "วัสดุ Lv.4 ×4"},
		{"id": "eg_chaos1", "label": "Memory of Chaos I",   "current": 0, "total": 1, "go": "battle", "reward": "crystal", "reward_n": 150},
		{"id": "eg_chaos2", "label": "Memory of Chaos II",  "current": 0, "total": 1, "go": "battle", "reward": "crystal", "reward_n": 150},
	],
	Tab.CHALLENGE: [
		{"id": "ch_win3",  "label": "ชนะ 3 ครั้งในสัปดาห์",  "current": 0, "total": 3,  "go": "battle", "reward": "crystal", "reward_n": 160},
		{"id": "ch_5star", "label": "รับตัวละคร 5★ จากกาชา", "current": 0, "total": 1,  "go": "gacha",  "reward": "crystal", "reward_n": 200},
		{"id": "ch_elem",  "label": "ทำปฏิกิริยา 10 ครั้ง",   "current": 0, "total": 10, "go": "battle", "reward": "crystal", "reward_n": 100},
	],
}

const _GO_SCENES := {
	"battle":    "res://battle_scene.tscn",
	"gacha":     "res://gacha_scene.tscn",
	"adventure": "res://transition_scene.tscn",
	"alchemist": "res://laboratory_scene.tscn",
}

@onready var _sheet:        Panel         = $Sheet
@onready var _dim:          ColorRect     = $Dim
@onready var _tab_daily:    Button        = $Sheet/Body/TabColWrap/TabCol/TabDaily
@onready var _tab_exp:      Button        = $Sheet/Body/TabColWrap/TabCol/TabExpedition
@onready var _tab_end:      Button        = $Sheet/Body/TabColWrap/TabCol/TabEndgame
@onready var _tab_chal:     Button        = $Sheet/Body/TabColWrap/TabCol/TabChallenge
@onready var _list:         VBoxContainer = $Sheet/Body/Content/QuestList
@onready var _close_btn:    Button        = $Sheet/Header/HeaderRow/CloseBtn

func _ready() -> void:
	if _sheet:
		_sheet.scale       = Vector2(0.88, 0.88)
		_sheet.modulate    = Color(1, 1, 1, 0.0)
		_sheet.pivot_offset = Vector2(440, 260)
		_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sheet.visible = false
	if _dim:
		_dim.modulate.a   = 0.0
		_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _tab_daily:  _tab_daily.pressed.connect(func(): _switch_tab(Tab.DAILY))
	if _tab_exp:
		_tab_exp.text = "รายสัปดาห์"
		_tab_exp.pressed.connect(func(): _switch_tab(Tab.WEEKLY))
	if _tab_end:    _tab_end.pressed.connect(func():   _switch_tab(Tab.ENDGAME))
	if _tab_chal:   _tab_chal.pressed.connect(func():  _switch_tab(Tab.CHALLENGE))
	if _close_btn:  _close_btn.pressed.connect(close)
	if _dim:        _dim.gui_input.connect(_on_dim_input)
	_update_tab_style()
	_rebuild_list()

func open() -> void:
	if _is_open or not _sheet or not _dim:
		return
	_is_open = true
	_sheet.visible = true
	_dim.mouse_filter   = Control.MOUSE_FILTER_STOP
	_sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween().set_parallel(true)
	t.tween_property(_sheet, "scale",        Vector2(1.0, 1.0), 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(_sheet, "modulate:a",   1.0,               0.22)
	t.tween_property(_dim,   "modulate:a",   1.0,               0.22)

func close() -> void:
	if not _is_open or not _sheet or not _dim:
		return
	_is_open = false
	_dim.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween().set_parallel(true)
	t.tween_property(_sheet, "scale",       Vector2(0.88, 0.88), 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_property(_sheet, "modulate:a",  0.0,                 0.18)
	t.tween_property(_dim,   "modulate:a",  0.0,                 0.18)
	t.finished.connect(func(): if not _is_open and _sheet: _sheet.visible = false)

func _on_dim_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		close()

func _switch_tab(tab: Tab) -> void:
	_current_tab = tab
	_update_tab_style()
	_rebuild_list()

func _update_tab_style() -> void:
	var tabs: Array[Button] = [_tab_daily, _tab_exp, _tab_end, _tab_chal]
	var actives: Array[bool] = [
		_current_tab == Tab.DAILY,
		_current_tab == Tab.WEEKLY,
		_current_tab == Tab.ENDGAME,
		_current_tab == Tab.CHALLENGE,
	]
	var sb_active: StyleBoxFlat = _make_tab_style(true)
	var sb_inactive: StyleBoxFlat = _make_tab_style(false)
	for i in tabs.size():
		var btn: Button = tabs[i]
		if not btn:
			continue
		var is_active: bool = actives[i]
		btn.add_theme_stylebox_override("normal",  sb_active   if is_active else sb_inactive)
		btn.add_theme_stylebox_override("hover",   sb_active   if is_active else sb_inactive)
		btn.add_theme_stylebox_override("pressed", sb_active   if is_active else sb_inactive)
		btn.add_theme_color_override("font_color",
			Color(0.75, 0.9, 1, 1.0) if is_active else Color(0.75, 0.9, 1, 0.4))

func _make_tab_style(active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.37, 0.62, 1.0, 0.18)
		sb.border_width_left = 2
		sb.border_color = Color(0.37, 0.62, 1.0, 0.9)
		sb.corner_radius_top_left    = 6
		sb.corner_radius_top_right   = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left  = 6
	else:
		sb.bg_color = Color(0, 0, 0, 0)
	sb.content_margin_left   = 14
	sb.content_margin_right  = 14
	sb.content_margin_top    = 10
	sb.content_margin_bottom = 10
	return sb

func _rebuild_list() -> void:
	if not _list:
		return
	for child in _list.get_children():
		child.queue_free()
	var quests: Array = QUESTS.get(_current_tab, []) as Array
	for q in quests:
		var nav: Callable = Callable()
		var go_key: String = str(q.get("go", ""))
		var scene_path: String = str(_GO_SCENES.get(go_key, ""))
		if scene_path != "" and ResourceLoader.exists(scene_path):
			nav = func():
				close()
				SceneTransition.fade_to(scene_path)
		_list.add_child(_QuestRow.new(q, nav))

# ── Quest row (Daily / Endgame / Challenge) ──────────────────────────────────
class _QuestRow extends Control:
	func _init(q: Dictionary, nav: Callable = Callable()) -> void:
		custom_minimum_size = Vector2(0, 68)

		var bg := ColorRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(1, 1, 1, 0.025)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)

		var done: bool = int(q.get("current", 0)) >= int(q.get("total", 1))

		# label
		var lbl := Label.new()
		lbl.text = ("✓  " if done else "○  ") + str(q.get("label", ""))
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 1.0, 0.6, 0.85) if done else Color(0.9, 0.93, 1.0, 0.95))
		lbl.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		lbl.offset_left  = 20
		lbl.offset_right = 460
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(lbl)

		# reward
		var reward_str: String = str(q.get("reward", ""))
		var reward_n: int = int(q.get("reward_n", 0))
		if reward_str == "crystal" and reward_n > 0:
			var tex := load("res://image/crystal_gem.png") as Texture2D
			if tex:
				var ico := TextureRect.new()
				ico.texture = tex
				ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				ico.size = Vector2(18, 18)
				ico.position = Vector2(20, 44)
				add_child(ico)
			var reward_lbl := Label.new()
			reward_lbl.text = "×%d" % reward_n
			reward_lbl.add_theme_font_size_override("font_size", 11)
			reward_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0, 0.95))
			reward_lbl.position = Vector2(42, 44)
			add_child(reward_lbl)
		else:
			var reward_lbl := Label.new()
			reward_lbl.text = reward_str
			reward_lbl.add_theme_font_size_override("font_size", 11)
			reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 0.9))
			reward_lbl.position = Vector2(20, 44)
			add_child(reward_lbl)

		# progress bar
		var total: int = max(1, int(q.get("total", 1)))
		var cur:   int = clampi(int(q.get("current", 0)), 0, total)

		var bar_bg := ColorRect.new()
		bar_bg.color    = Color(1, 1, 1, 0.07)
		bar_bg.size     = Vector2(260, 5)
		bar_bg.position = Vector2(20, 58)
		add_child(bar_bg)

		var fill := ColorRect.new()
		fill.color    = Color(0.3, 0.85, 0.5, 0.9) if done else Color(0.37, 0.62, 1.0, 0.9)
		fill.size     = Vector2(260.0 * cur / total, 5)
		fill.position = Vector2(20, 58)
		add_child(fill)

		var cnt := Label.new()
		cnt.text = "%d / %d" % [cur, total]
		cnt.add_theme_font_size_override("font_size", 10)
		cnt.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
		cnt.position = Vector2(290, 52)
		add_child(cnt)

		# go button
		if not done and nav.is_valid():
			var btn := Button.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.15, 0.33, 0.78, 1.0)
			sb.corner_radius_top_left     = 8
			sb.corner_radius_top_right    = 8
			sb.corner_radius_bottom_right = 8
			sb.corner_radius_bottom_left  = 8
			btn.add_theme_stylebox_override("normal",  sb)
			btn.add_theme_stylebox_override("hover",   sb)
			btn.add_theme_stylebox_override("pressed", sb)
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			btn.add_theme_font_size_override("font_size", 12)
			btn.text     = "ไป ›"
			btn.size     = Vector2(64, 32)
			btn.position = Vector2(640, 18)
			btn.pressed.connect(nav)
			add_child(btn)

		var div := ColorRect.new()
		div.color        = Color(1, 1, 1, 0.05)
		div.size         = Vector2(720, 1)
		div.position     = Vector2(0, 67)
		div.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(div)

