extends Control

const SC_MAIN := "res://main_menu.tscn"

const W := 1152.0
const H := 648.0

const SHOWCASE: Array = [
	{"name": "Lyra",  "level": 42, "rarity": 5, "element": "🔥"},
	{"name": "Kael",  "level": 38, "rarity": 4, "element": "⚡"},
	{"name": "Mira",  "level": 35, "rarity": 4, "element": "🧊"},
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

@onready var _back_btn:     Panel     = $BackBtn
@onready var _uid_lbl:      Label     = $LeftPanel/UIDLabel
@onready var _avatar_panel: Panel     = $LeftPanel/AvatarPanel
@onready var _avatar_lbl:   Label     = $LeftPanel/AvatarPanel/AvatarLabel
@onready var _name_lbl:     Label     = $LeftPanel/NameLabel
@onready var _level_lbl:    Label     = $LeftPanel/LevelPill/LevelLabel
@onready var _sig_lbl:      Label     = $LeftPanel/SigBg/SigLabel
@onready var _dot_btn:      Button    = $LeftPanel/DotBtn
@onready var _showcase_root: Control  = $ShowcaseRoot
@onready var _fade:         ColorRect = $FadeOverlay

var _dropdown: Control = null

func _ready() -> void:
	_add_stars($Background)
	_build_showcase_cards()

	_back_btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw := _back_btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(_back_btn, "scale", Vector2(0.78, 0.78), 0.08)
			tw.tween_property(_back_btn, "scale", Vector2(1.0, 1.0), 0.22)
			tw.tween_callback(_go_back)
	)
	_back_btn.mouse_entered.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	_back_btn.mouse_exited.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)

	_avatar_panel.gui_input.connect(_on_avatar_click)
	_dot_btn.pressed.connect(_toggle_dropdown)

	_refresh_from_player_data()
	PlayerData.profile_changed.connect(_refresh_from_player_data)

	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.35)

func _build_showcase_cards() -> void:
	var rw := 800.0
	var card_h := 340.0
	var gap := 12.0
	var card_w := (rw - gap * 2) / 3.0
	for i in SHOWCASE.size():
		var cx := i * (card_w + gap)
		var card := _make_showcase_card(SHOWCASE[i], cx, 0.0, card_w, card_h)
		_showcase_root.add_child(card)

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

	var top_bar := ColorRect.new()
	top_bar.size  = Vector2(cw, 3)
	top_bar.color = Color(acc.r, acc.g, acc.b, 0.7)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(top_bar)

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

	var tp := art.create_tween().set_loops()
	tp.tween_property(art, "modulate:a", 0.5, 2.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tp.tween_property(art, "modulate:a", 1.0, 2.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dim.offset_top = -100
	dim.color = Color(0, 0, 0.04, 0.8)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dim)

	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.add_theme_font_size_override("font_size", 13)
	stars.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 0.9))
	stars.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stars.offset_left=12; stars.offset_right=200; stars.offset_bottom=-44; stars.offset_top=-64
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stars)

	var elem := Label.new()
	elem.text = str(data.get("element",""))
	elem.add_theme_font_size_override("font_size", 18)
	elem.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	elem.offset_left=-36; elem.offset_right=-8; elem.offset_top=8; elem.offset_bottom=32
	elem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(elem)

	var name_lbl := Label.new()
	name_lbl.text = str(data.get("name",""))
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(1,1,1,0.95))
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	name_lbl.offset_left=12; name_lbl.offset_right=200; name_lbl.offset_bottom=-24; name_lbl.offset_top=-46
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	var lv := Label.new()
	lv.text = "Lv.%d" % int(data.get("level",1))
	lv.add_theme_font_size_override("font_size", 11)
	lv.add_theme_color_override("font_color", Color(0.7, 0.87, 1, 0.65))
	lv.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lv.offset_left=12; lv.offset_right=120; lv.offset_bottom=-8; lv.offset_top=-24
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(lv)

	return card

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

	var dot_abs_x := 278.0
	var dot_abs_y := 10.0 + 32.0 + 4.0
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

func _on_avatar_click(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_open_avatar_popup()

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

func _go_back() -> void:
	if PlayerData.profile_changed.is_connected(_refresh_from_player_data):
		PlayerData.profile_changed.disconnect(_refresh_from_player_data)
	SceneTransition.fade_to(SC_MAIN)
