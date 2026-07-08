extends Control

const SC_MAIN := "res://main_menu.tscn"

const W := 1152.0
const H := 648.0
const TOP_H  := 48.0
const LEFT_W := 320.0

# ── Static data ───────────────────────────────────────────────────
const SHOWCASE: Array = [
	{"name": "Lyra",  "level": 42, "rarity": 5, "element": "🔥"},
	{"name": "Kael",  "level": 38, "rarity": 4, "element": "⚡"},
	{"name": "Mira",  "level": 35, "rarity": 4, "element": "🧊"},
]

const ACTIVITY: Array = [
	{"icon": "⚔",  "text": "ชนะการต่อสู้ใน Chapter 1-1",      "time": "2 ชม. ที่แล้ว"},
	{"icon": "🎲",  "text": "สุ่มกาชา 10 ครั้ง — ได้ Seraph 5★","time": "5 ชม. ที่แล้ว"},
	{"icon": "🧭",  "text": "ส่งทีมสำรวจ Zone B",                "time": "เมื่อวาน"},
	{"icon": "✅",  "text": "ทำภารกิจรายวันครบ",                 "time": "เมื่อวาน"},
]

const AVATAR_COLORS: Array = [
	Color(0.25, 0.45, 0.95),
	Color(0.8,  0.25, 0.35),
	Color(0.2,  0.75, 0.5),
	Color(0.75, 0.55, 0.1),
	Color(0.5,  0.2,  0.85),
	Color(0.15, 0.65, 0.85),
]
const AVATAR_ICONS: Array[String] = ["⚗", "⚔", "🌙", "★", "♦", "✦"]

const STATS: Array = [
	{"icon": "⏱", "label": "วันที่เล่น",    "value": "1 วัน"},
	{"icon": "⚔", "label": "การต่อสู้",      "value": "0"},
	{"icon": "✅", "label": "ความสำเร็จ",    "value": "0 / 120"},
	{"icon": "🎲", "label": "กาชาทั้งหมด",   "value": "0"},
	{"icon": "👤", "label": "ตัวละครที่มี",  "value": "2"},
	{"icon": "🌐", "label": "ระดับโลก",       "value": "1"},
]

# ── Runtime refs ──────────────────────────────────────────────────
var _name_lbl:      Label       = null
var _level_lbl:     Label       = null
var _sig_lbl:       Label       = null
var _uid_lbl:       Label       = null
var _avatar_lbl:    Label       = null
var _avatar_panel:  Panel       = null
var _domain_fill:   ColorRect   = null
var _domain_bar_bg: Control     = null
var _domain_pct:    Label       = null
var _dropdown:      Control     = null
var _dot_btn:       Button      = null
var _fade:          ColorRect   = null

# ── Ready ─────────────────────────────────────────────────────────
func _ready() -> void:
	_build_ui()
	_refresh_from_player_data()
	PlayerData.profile_changed.connect(_refresh_from_player_data)

	if _fade:
		var t := create_tween()
		t.tween_property(_fade, "color:a", 0.0, 0.35)

# ── Build full UI ─────────────────────────────────────────────────
func _build_ui() -> void:
	# Starfield background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.022, 0.028, 0.072, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	add_child(bg)
	_add_stars(bg)

	# Top bar
	_build_top_bar()

	# Left panel (player card + activity)
	_build_left_panel()

	# Right area (showcase + activity)
	_build_right_area()

	# Fade overlay (on top)
	_fade = ColorRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.z_index = 100
	add_child(_fade)

# ── Top bar ───────────────────────────────────────────────────────
func _build_top_bar() -> void:
	# Back button — top right of screen
	var back := _make_back_btn(Vector2(W - 46, 10), Vector2(36, 36), _go_back)
	back.z_index = 10
	add_child(back)

# ── Left panel ────────────────────────────────────────────────────
func _build_left_panel() -> void:
	var panel_sb := _sb(Color(0.018, 0.03, 0.09, 0.92), Color(1,1,1, 0.07), 0, 1)
	var panel := Panel.new()
	panel.size     = Vector2(LEFT_W, H)
	panel.position = Vector2(0, 0)
	panel.add_theme_stylebox_override("panel", panel_sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 3
	add_child(panel)

	# Accent top strip
	var acc_strip := ColorRect.new()
	acc_strip.size  = Vector2(LEFT_W, 2)
	acc_strip.color = Color(0.388, 0.624, 1.0, 0.5)
	acc_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(acc_strip)

	# ── UID top-left ──
	_uid_lbl = Label.new()
	_uid_lbl.add_theme_font_size_override("font_size", 10)
	_uid_lbl.add_theme_color_override("font_color", Color(0.388, 0.624, 1, 0.5))
	_uid_lbl.size     = Vector2(LEFT_W - 16, 20)
	_uid_lbl.position = Vector2(12, 8)
	_uid_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_uid_lbl)

	# ── Avatar circle ──
	var av_size := 96.0
	var av_x    := (LEFT_W - av_size) * 0.5
	var av_y    := 24.0

	_avatar_panel = Panel.new()
	var av_sb := StyleBoxFlat.new()
	av_sb.bg_color = AVATAR_COLORS[0]
	av_sb.border_color = Color(0.388, 0.624, 1.0, 0.7)
	for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: av_sb.set_border_width(s, 2)
	av_sb.corner_radius_top_left     = int(av_size / 2)
	av_sb.corner_radius_top_right    = int(av_size / 2)
	av_sb.corner_radius_bottom_right = int(av_size / 2)
	av_sb.corner_radius_bottom_left  = int(av_size / 2)
	_avatar_panel.add_theme_stylebox_override("panel", av_sb)
	_avatar_panel.size     = Vector2(av_size, av_size)
	_avatar_panel.position = Vector2(av_x, av_y)
	_avatar_panel.gui_input.connect(_on_avatar_click)
	panel.add_child(_avatar_panel)

	_avatar_lbl = Label.new()
	_avatar_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_avatar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_avatar_lbl.add_theme_font_size_override("font_size", 36)
	_avatar_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_panel.add_child(_avatar_lbl)

	# ── Player name ──
	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 20)
	_name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_name_lbl.size     = Vector2(LEFT_W, 28)
	_name_lbl.position = Vector2(0, av_y + av_size + 12)
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_name_lbl)

	# ── Level pill ──
	var lv_sb := _sb(Color(0.388, 0.624, 1, 0.18), Color(0.388, 0.624, 1, 0.35), 10, 1)
	var lv_pill := Panel.new()
	lv_pill.size     = Vector2(90, 24)
	lv_pill.position = Vector2((LEFT_W - 90) * 0.5, av_y + av_size + 46)
	lv_pill.add_theme_stylebox_override("panel", lv_sb)
	lv_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lv_pill)

	_level_lbl = Label.new()
	_level_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_level_lbl.add_theme_font_size_override("font_size", 12)
	_level_lbl.add_theme_color_override("font_color", Color(0.7, 0.87, 1, 1))
	_level_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv_pill.add_child(_level_lbl)

	# ── Signature ──
	var sig_y := av_y + av_size + 80.0
	var sig_bg := Panel.new()
	sig_bg.size     = Vector2(LEFT_W - 32, 36)
	sig_bg.position = Vector2(16, sig_y)
	var sig_sb := _sb(Color(1,1,1, 0.03), Color(0,0,0,0), 8, 0)
	sig_bg.add_theme_stylebox_override("panel", sig_sb)
	sig_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sig_bg)

	_sig_lbl = Label.new()
	_sig_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sig_lbl.offset_left = 10; _sig_lbl.offset_right = -10
	_sig_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sig_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_sig_lbl.add_theme_font_size_override("font_size", 11)
	_sig_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	_sig_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sig_bg.add_child(_sig_lbl)

	# ── Divider ──
	var div := ColorRect.new()
	div.size     = Vector2(LEFT_W - 32, 1)
	div.position = Vector2(16, sig_y + 46)
	div.color    = Color(1,1,1, 0.08)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	# ── Stats mini grid ──
	var stats_y := sig_y + 58.0
	var col_w   := (LEFT_W - 32) / 3.0
	for i in STATS.size():
		var col := i % 3
		var row := i / 3
		var sx  := 16.0 + col * col_w
		var sy  := stats_y + row * 52.0
		var stat_bg := Panel.new()
		stat_bg.size     = Vector2(col_w - 6, 44)
		stat_bg.position = Vector2(sx, sy)
		var s_sb := _sb(Color(1,1,1, 0.03), Color(0,0,0,0), 8, 0)
		stat_bg.add_theme_stylebox_override("panel", s_sb)
		stat_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(stat_bg)

		var s_val := Label.new()
		s_val.text = str(STATS[i]["value"])
		s_val.add_theme_font_size_override("font_size", 15)
		s_val.add_theme_color_override("font_color", Color(1,1,1, 0.9))
		s_val.size     = Vector2(col_w - 6, 24)
		s_val.position = Vector2(0, 4)
		s_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_val.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stat_bg.add_child(s_val)

		var s_lbl := Label.new()
		s_lbl.text = str(STATS[i]["label"])
		s_lbl.add_theme_font_size_override("font_size", 9)
		s_lbl.add_theme_color_override("font_color", Color(1,1,1, 0.35))
		s_lbl.size     = Vector2(col_w - 6, 14)
		s_lbl.position = Vector2(0, 28)
		s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stat_bg.add_child(s_lbl)

	var dom_y := stats_y + 2 * 52.0 + 14.0

	# ── ⋮ dot button (edit menu) ──
	_dot_btn = Button.new()
	_dot_btn.text = "⋮"
	_dot_btn.size     = Vector2(32, 32)
	_dot_btn.position = Vector2(LEFT_W - 42, 10)
	_dot_btn.add_theme_font_size_override("font_size", 20)
	_dot_btn.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0, 0.7))
	_dot_btn.add_theme_stylebox_override("normal",  _sb(Color(0,0,0,0), Color(0,0,0,0), 8, 0))
	_dot_btn.add_theme_stylebox_override("hover",   _sb(Color(1,1,1,0.08), Color(0,0,0,0), 8, 0))
	_dot_btn.add_theme_stylebox_override("pressed", _sb(Color(0,0,0,0), Color(0,0,0,0), 8, 0))
	_dot_btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	_dot_btn.pressed.connect(_toggle_dropdown)
	panel.add_child(_dot_btn)

	# ── No activity placeholder ──
	_build_activity_in(panel, dom_y + 14)

func _build_activity_in(parent: Panel, start_y: float) -> void:
	var no_act := Label.new()
	no_act.text = "ยังไม่มีกิจกรรม"
	no_act.add_theme_font_size_override("font_size", 11)
	no_act.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
	no_act.size     = Vector2(LEFT_W - 32, 32)
	no_act.position = Vector2(16, start_y + 16)
	no_act.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_act.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	no_act.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(no_act)

# ── Right area ────────────────────────────────────────────────────
func _build_right_area() -> void:
	var rx := LEFT_W + 16.0
	var rw := W - rx - 16.0
	var ry := 16.0

	# "CHARACTER SHOWCASE" label
	var sc_lbl := Label.new()
	sc_lbl.text = "CHARACTER SHOWCASE"
	sc_lbl.add_theme_font_size_override("font_size", 11)
	sc_lbl.add_theme_color_override("font_color", Color(0.388, 0.624, 1, 0.55))
	sc_lbl.size     = Vector2(rw, 20)
	sc_lbl.position = Vector2(rx, ry)
	sc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sc_lbl)

	# 3 showcase cards side by side
	var card_y  := ry + 26.0
	var card_h  := 340.0
	var gap     := 12.0
	var card_w  := (rw - gap * 2) / 3.0

	for i in SHOWCASE.size():
		var cx := rx + i * (card_w + gap)
		add_child(_make_showcase_card(SHOWCASE[i], cx, card_y, card_w, card_h))


func _make_showcase_card(data: Dictionary, cx: float, cy: float, cw: float, ch: float) -> Panel:
	var rarity: int = int(data.get("rarity", 3))
	var acc: Color
	match rarity:
		5: acc = Color(1.0, 0.82, 0.2)
		4: acc = Color(0.72, 0.45, 1.0)
		_: acc = Color(0.4, 0.65, 1.0)

	var card := Panel.new()
	card.size     = Vector2(cw, ch)
	card.position = Vector2(cx, cy)

	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.024, 0.05, 0.13, 0.94)
	sb.border_color = Color(acc.r, acc.g, acc.b, 0.22)
	for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: sb.set_border_width(s, 1)
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		sb.set(r, 16)
	sb.shadow_color = Color(acc.r, acc.g, acc.b, 0.15)
	sb.shadow_size  = 10
	card.add_theme_stylebox_override("panel", sb)

	# Accent top bar
	var top_bar := ColorRect.new()
	top_bar.size  = Vector2(cw, 3)
	top_bar.color = Color(acc.r, acc.g, acc.b, 0.7)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(top_bar)

	# Large emoji art (center glow)
	var art := Label.new()
	art.text = str(data.get("element", "★"))
	art.add_theme_font_size_override("font_size", 100)
	art.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 0.12))
	art.size     = Vector2(cw, ch)
	art.position = Vector2.ZERO
	art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art)

	# Pulse
	var tp := art.create_tween().set_loops()
	tp.tween_property(art, "modulate:a", 0.5, 2.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tp.tween_property(art, "modulate:a", 1.0, 2.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Bottom dim gradient
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dim.offset_top = -100
	dim.color = Color(0, 0, 0.04, 0.8)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dim)

	# Stars
	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.add_theme_font_size_override("font_size", 13)
	stars.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 0.9))
	stars.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stars.offset_left=12; stars.offset_right=200; stars.offset_bottom=-44; stars.offset_top=-64
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stars)

	# Element icon (top right)
	var elem := Label.new()
	elem.text = str(data.get("element",""))
	elem.add_theme_font_size_override("font_size", 18)
	elem.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	elem.offset_left=-36; elem.offset_right=-8; elem.offset_top=8; elem.offset_bottom=32
	elem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(elem)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = str(data.get("name",""))
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(1,1,1,0.95))
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	name_lbl.offset_left=12; name_lbl.offset_right=200; name_lbl.offset_bottom=-24; name_lbl.offset_top=-46
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# Level
	var lv := Label.new()
	lv.text = "Lv.%d" % int(data.get("level",1))
	lv.add_theme_font_size_override("font_size", 11)
	lv.add_theme_color_override("font_color", Color(0.7, 0.87, 1, 0.65))
	lv.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lv.offset_left=12; lv.offset_right=120; lv.offset_bottom=-8; lv.offset_top=-24
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(lv)

	return card

# ── Refresh player data ───────────────────────────────────────────
func _refresh_from_player_data() -> void:
	var idx := clampi(PlayerData.avatar_idx, 0, AVATAR_ICONS.size() - 1)
	if _name_lbl:   _name_lbl.text  = PlayerData.player_name
	if _sig_lbl:    _sig_lbl.text   = PlayerData.signature
	if _level_lbl:  _level_lbl.text = "Lv. %d" % PlayerData.level
	if _uid_lbl:    _uid_lbl.text   = "UID: %s  " % PlayerData.uid
	if _avatar_lbl: _avatar_lbl.text = AVATAR_ICONS[idx]
	if _avatar_panel:
		var av_sb := _avatar_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if av_sb:
			av_sb.bg_color = AVATAR_COLORS[idx]

# ── Domain bar ────────────────────────────────────────────────────
func _on_domain_changed(pct: float) -> void:
	if not is_inside_tree(): return
	if _domain_pct: _domain_pct.text = "%d%%" % int(pct)
	_apply_domain_bar.call_deferred(pct)

func _apply_domain_bar(pct: float) -> void:
	if not is_instance_valid(_domain_bar_bg) or not is_instance_valid(_domain_fill): return
	_domain_fill.size.x = _domain_bar_bg.size.x * (pct / 100.0)

# ── ⋮ dropdown ────────────────────────────────────────────────────
func _toggle_dropdown() -> void:
	if _dropdown and is_instance_valid(_dropdown): _close_dropdown(); return
	_open_dropdown()

func _close_dropdown() -> void:
	if _dropdown and is_instance_valid(_dropdown): _dropdown.queue_free()
	_dropdown = null

func _open_dropdown() -> void:
	const ITEMS := [
		{"icon": "✏",  "label": "แก้ไขโปรไฟล์", "action": "edit"},
		{"icon": "🖼",  "label": "เปลี่ยนอวตาร",  "action": "avatar"},
		{"sep": true},
		{"icon": "📊", "label": "ดูสถิติ",         "action": "stats"},
	]
	const ITEM_H  := 42.0
	const SEP_H   := 9.0
	const PANEL_W := 192.0

	var panel_h := 8.0
	for e in ITEMS: panel_h += SEP_H if e.get("sep", false) else ITEM_H

	# Drop-down position: below dot button inside left panel
	var dot_abs_x := LEFT_W - 42.0 + 0.0   # left panel at x=0
	var dot_abs_y := TOP_H + 10.0 + 32.0 + 4.0
	var panel_x   := dot_abs_x + 32.0 - PANEL_W
	var panel_y   := dot_abs_y

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 20
	add_child(dim)
	_dropdown = dim

	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.05, 0.08, 0.20, 0.97)
	sb.border_color = Color(0.42, 0.65, 1.0, 0.28)
	for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: sb.set_border_width(s, 1)
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		sb.set(r, 10)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size  = 10

	var pop := Panel.new()
	pop.size     = Vector2(PANEL_W, panel_h)
	pop.position = Vector2(panel_x, panel_y - 12)
	pop.modulate.a = 0.0
	pop.add_theme_stylebox_override("panel", sb)
	pop.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.add_child(pop)

	var ta := pop.create_tween().set_parallel(true)
	ta.tween_property(pop, "position:y", panel_y, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	ta.tween_property(pop, "modulate:a", 1.0, 0.13)

	var cy := 4.0
	for entry in ITEMS:
		if entry.get("sep", false):
			var sep := ColorRect.new()
			sep.color = Color(1,1,1, 0.07)
			sep.position = Vector2(8, cy + 3); sep.size = Vector2(PANEL_W - 16, 1)
			sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pop.add_child(sep)
			cy += SEP_H
			continue
		var btn := Button.new()
		btn.size = Vector2(PANEL_W, ITEM_H); btn.position = Vector2(0, cy)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 0.92))
		btn.add_theme_stylebox_override("normal",  _sb(Color(0,0,0,0), Color(0,0,0,0), 7, 0))
		btn.add_theme_stylebox_override("hover",   _sb(Color(0.38,0.62,1,0.13), Color(0,0,0,0), 7, 0))
		btn.add_theme_stylebox_override("pressed", _sb(Color(0,0,0,0), Color(0,0,0,0), 7, 0))
		btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())

		var ic := Label.new(); ic.text = str(entry.get("icon",""))
		ic.position = Vector2(14, (ITEM_H-20)*0.5); ic.size = Vector2(22,20)
		ic.add_theme_font_size_override("font_size", 14)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(ic)

		var tl := Label.new(); tl.text = str(entry.get("label",""))
		tl.position = Vector2(40, (ITEM_H-18)*0.5); tl.size = Vector2(PANEL_W-50, 18)
		tl.add_theme_font_size_override("font_size", 13)
		tl.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 0.92))
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tl)

		var act: String = str(entry.get("action",""))
		btn.pressed.connect(func(): _close_dropdown(); _on_dropdown_item(act))
		pop.add_child(btn)
		cy += ITEM_H

	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed: _close_dropdown())

func _on_dropdown_item(action: String) -> void:
	match action:
		"edit":   _open_edit_popup()
		"avatar": _open_avatar_popup()
		"stats":  _open_stats_modal()

# ── Avatar click ──────────────────────────────────────────────────
func _on_avatar_click(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_open_avatar_popup()

# ── Avatar picker popup ───────────────────────────────────────────
func _open_avatar_popup() -> void:
	const PW := 400.0; const PH := 200.0
	var dim := _make_dim(20)
	var panel := _make_panel(dim, PW, PH)

	_centered_label(panel, "เลือกอวตาร", 14, Color(1,1,1,0.9), 0, 14, PW, 24)

	const BTN_W := 46.0; const GAP := 10.0
	var n := AVATAR_COLORS.size()
	var row_x := (PW - (n * BTN_W + (n-1) * GAP)) * 0.5
	for i in n:
		var p := Panel.new()
		var asb := StyleBoxFlat.new()
		asb.bg_color = AVATAR_COLORS[i]
		for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
			asb.set(r, int(BTN_W / 2))
		if i == PlayerData.avatar_idx:
			for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: asb.set_border_width(s, 2)
			asb.border_color = Color(1,1,1,0.9)
		p.add_theme_stylebox_override("panel", asb)
		p.position = Vector2(row_x + i * (BTN_W + GAP), 50)
		p.size     = Vector2(BTN_W, BTN_W)
		var il := Label.new()
		il.text = AVATAR_ICONS[i]
		il.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		il.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		il.add_theme_font_size_override("font_size", 20)
		il.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(il)
		p.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				PlayerData.set_avatar(i); dim.queue_free())
		panel.add_child(p)

	var cancel := _popup_btn("ยกเลิก", false)
	cancel.position = Vector2((PW-160)*0.5, 148); cancel.size = Vector2(160, 36)
	cancel.pressed.connect(func(): dim.queue_free())
	panel.add_child(cancel)
	add_child(dim)

# ── Edit profile popup ────────────────────────────────────────────
func _open_edit_popup() -> void:
	const PW := 440.0; const PH := 280.0
	var dim := _make_dim(20)
	var panel := _make_panel(dim, PW, PH)

	_centered_label(panel, "แก้ไขโปรไฟล์", 15, Color(1,1,1,0.9), 0, 18, PW, 26)

	_centered_label(panel, "ชื่อผู้เล่น", 11, Color(0.6,0.8,1,0.7), 24, 54, PW-48, 16).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var name_edit := _make_line_edit(PlayerData.player_name)
	name_edit.position = Vector2(24, 72); name_edit.size = Vector2(PW-48, 32)
	name_edit.max_length = 20; panel.add_child(name_edit)

	_centered_label(panel, "คำขวัญ", 11, Color(0.6,0.8,1,0.7), 24, 118, PW-48, 16).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var sig_edit := _make_line_edit(PlayerData.signature)
	sig_edit.position = Vector2(24, 136); sig_edit.size = Vector2(PW-48, 32)
	sig_edit.max_length = 50; panel.add_child(sig_edit)

	const BW := 180.0; const BH := 38.0; const BY := 222.0
	var cancel := _popup_btn("ยกเลิก", false)
	cancel.position = Vector2(20, BY); cancel.size = Vector2(BW, BH)
	cancel.pressed.connect(func(): dim.queue_free())
	panel.add_child(cancel)

	var ok := _popup_btn("บันทึก", true)
	ok.position = Vector2(PW-20-BW, BY); ok.size = Vector2(BW, BH)
	ok.pressed.connect(func():
		var nn := name_edit.text.strip_edges()
		PlayerData.save_profile(
			nn if nn.length() > 0 else PlayerData.player_name,
			sig_edit.text.strip_edges(), PlayerData.avatar_idx)
		dim.queue_free())
	panel.add_child(ok)

	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed: dim.queue_free())
	add_child(dim)

# ── Stats modal ───────────────────────────────────────────────────
func _open_stats_modal() -> void:
	const PW := 460.0; const PH := 420.0
	var dim := _make_dim(20)
	var panel := _make_panel(dim, PW, PH)

	_centered_label(panel, "สถิติผู้เล่น", 15, Color(0.388,0.624,1,0.9), 20, 16, PW-60, 26).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var cb := _ghost_btn("✕", 14)
	cb.position = Vector2(PW-44, 12); cb.size = Vector2(32, 32)
	cb.pressed.connect(func(): dim.queue_free())
	panel.add_child(cb)

	var hdiv := ColorRect.new()
	hdiv.color = Color(0.388,0.624,1,0.15)
	hdiv.position = Vector2(16, 46); hdiv.size = Vector2(PW-32, 1)
	hdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hdiv)

	var sy := 56.0
	for i in STATS.size():
		var d: Dictionary = STATS[i]
		var row_bg := ColorRect.new()
		row_bg.color = Color(1,1,1,0.02) if i % 2 == 0 else Color(0,0,0,0)
		row_bg.position = Vector2(0, sy-2); row_bg.size = Vector2(PW, 46)
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(row_bg)

		var il := Label.new(); il.text = str(d["icon"])
		il.add_theme_font_size_override("font_size", 16)
		il.position = Vector2(16, sy+4); il.size = Vector2(26, 26)
		il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		il.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(il)

		_centered_label(panel, str(d["label"]), 10, Color(0.65,0.78,1,0.55), 50, sy+2,  220, 16).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_centered_label(panel, str(d["value"]), 14, Color(1,1,1,0.92),       50, sy+18, 360, 20).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sy += 48.0

	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed: dim.queue_free())
	add_child(dim)

# ── Helpers ───────────────────────────────────────────────────────
func _sb(bg: Color, bdr: Color, radius: int, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = bdr
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: s.set_border_width(side, bw)
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_right = radius
	s.corner_radius_bottom_left  = radius
	return s

func _ghost_btn(label: String, fsize: int) -> Button:
	var btn := Button.new(); btn.text = label
	btn.add_theme_font_size_override("font_size", fsize)
	btn.add_theme_color_override("font_color", Color(1,1,1, 0.65))
	btn.add_theme_stylebox_override("normal",  _sb(Color(1,1,1,0.04), Color(1,1,1,0.10), 10, 1))
	btn.add_theme_stylebox_override("hover",   _sb(Color(1,1,1,0.08), Color(1,1,1,0.18), 10, 1))
	btn.add_theme_stylebox_override("pressed", _sb(Color(1,1,1,0.04), Color(1,1,1,0.10), 10, 1))
	btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	return btn

func _make_dim(z: int) -> ColorRect:
	var d := ColorRect.new()
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d.color = Color(0,0,0,0.55); d.mouse_filter = Control.MOUSE_FILTER_STOP; d.z_index = z
	return d

func _make_panel(dim: ColorRect, pw: float, ph: float) -> Panel:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.98)
	for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: sb.set_border_width(s, 1)
	sb.border_color = Color(0.4, 0.6, 1, 0.25)
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		sb.set(r, 16)
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", sb)
	p.size     = Vector2(pw, ph)
	p.position = Vector2((W - pw) * 0.5, (H - ph) * 0.5)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.add_child(p)
	return p

func _centered_label(parent: Control, text: String, fsize: int, col: Color, x: float, y: float, w: float, h: float) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", col)
	lbl.position = Vector2(x, y); lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl

func _make_line_edit(default_text: String) -> LineEdit:
	var le := LineEdit.new(); le.text = default_text
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1,1,1,0.06)
	for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: sb.set_border_width(s, 1)
	sb.border_color = Color(0.4,0.6,1,0.35)
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		sb.set(r, 8)
	sb.content_margin_left=10; sb.content_margin_right=10
	sb.content_margin_top=4;   sb.content_margin_bottom=4
	le.add_theme_stylebox_override("normal", sb)
	le.add_theme_stylebox_override("focus",  sb)
	le.add_theme_color_override("font_color", Color(1,1,1,0.9))
	le.add_theme_font_size_override("font_size", 14)
	return le

func _popup_btn(label: String, primary: bool) -> Button:
	var btn := Button.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15,0.35,0.85,1.0) if primary else Color(1,1,1,0.07)
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		sb.set(r, 8)
	btn.add_theme_stylebox_override("normal", sb); btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Color(1,1,1,0.85))
	btn.add_theme_font_size_override("font_size", 13); btn.text = label
	return btn

func _add_stars(parent: Node) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 12345
	for _i in 80:
		var dot := ColorRect.new()
		var sz  := rng.randf_range(1.0, 2.5)
		dot.size = Vector2(sz, sz)
		dot.position = Vector2(rng.randf_range(0, W), rng.randf_range(0, H))
		var br := rng.randf_range(0.4, 1.0)
		dot.color = Color(br, br, br+0.05, rng.randf_range(0.12, 0.45))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(dot)
		var td := dot.create_tween().set_loops()
		td.tween_interval(rng.randf_range(0, 4.0))
		td.tween_property(dot, "modulate:a", rng.randf_range(0.05,0.3), rng.randf_range(1.2,3.5)).set_ease(Tween.EASE_IN_OUT)
		td.tween_property(dot, "modulate:a", 1.0, rng.randf_range(1.2,3.5)).set_ease(Tween.EASE_IN_OUT)

# ── Navigation ────────────────────────────────────────────────────
func _make_back_btn(pos: Vector2, sz: Vector2, callback: Callable) -> TextureButton:
	var btn := TextureButton.new()
	btn.position = pos; btn.size = sz
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var buf := FileAccess.get_file_as_bytes("res://image/back.jpg")
	if not buf.is_empty():
		var img := Image.new()
		if img.load_jpg_from_buffer(buf) == OK:
			img.convert(Image.FORMAT_RGBA8)
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					var a := clampf(((c.r+c.g+c.b)/3.0 - 0.25) / 0.45, 0.0, 1.0)
					img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
			btn.texture_normal = ImageTexture.create_from_image(img)
	btn.pivot_offset = sz / 2
	btn.pressed.connect(func():
		var tw := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2(0.78, 0.78), 0.08)
		tw.tween_property(btn, "scale", Vector2(1.0,  1.0),  0.22)
		tw.tween_callback(callback)
	)
	return btn

func _go_back() -> void:
	if PlayerData.profile_changed.is_connected(_refresh_from_player_data):
		PlayerData.profile_changed.disconnect(_refresh_from_player_data)
	SceneTransition.fade_to(SC_MAIN)
