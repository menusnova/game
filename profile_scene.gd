extends Control

const SC_MAIN := "res://main_menu.tscn"

const SHOWCASE: Array = [
	{"name": "Lyra",   "level": 42, "rarity": 5, "element": "🔥", "art": null},
	{"name": "Kael",   "level": 38, "rarity": 4, "element": "⚡", "art": null},
	{"name": "Mira",   "level": 35, "rarity": 4, "element": "🧊", "art": null},
]

const ACTIVITY: Array = [
	{"icon": "⚔",  "text": "ชนะการต่อสู้ใน Chapter 1-1",     "time": "2 ชม. ที่แล้ว"},
	{"icon": "🎲",  "text": "สุ่มกาชา 10 ครั้ง — ได้ Seraph 5★", "time": "5 ชม. ที่แล้ว"},
	{"icon": "🧭",  "text": "ส่งทีมสำรวจ Zone B",               "time": "เมื่อวาน"},
	{"icon": "✅",  "text": "ทำภารกิจรายวันครบ",                "time": "เมื่อวาน"},
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
	{"icon": "🗓", "label": "เริ่มเล่น",          "value": "1 ม.ค. 2568"},
	{"icon": "⏱", "label": "วันที่เล่น",          "value": "12 วัน"},
	{"icon": "🌐", "label": "ระดับโลก",            "value": "3"},
	{"icon": "👤", "label": "ตัวละครที่มี",        "value": "4"},
	{"icon": "⭐", "label": "ตัวละครระดับสูงสุด",  "value": "1"},
	{"icon": "⚔",  "label": "การต่อสู้",           "value": "38"},
	{"icon": "✅", "label": "ความสำเร็จ",          "value": "7 / 120"},
	{"icon": "🎲", "label": "สุ่มกาชาทั้งหมด",    "value": "47"},
]

# ── onready refs ─────────────────────────────────────────────────
@onready var _back:          Button        = $TopBar/BackBtn
@onready var _showcase_row:  GridContainer = $ShowcaseRow
@onready var _activity_list: VBoxContainer = $ActivityCard/ActivityList
@onready var _fade:          ColorRect     = $FadeOverlay
@onready var _domain_fill:   ColorRect     = $PlayerCard/DomainRow/DomainBarBg/DomainBarFill
@onready var _domain_pct:    Label         = $PlayerCard/DomainRow/DomainPct
@onready var _domain_bar_bg: Panel         = $PlayerCard/DomainRow/DomainBarBg
@onready var _name_lbl:      Label         = $PlayerCard/PlayerName
@onready var _sig_lbl:       Label         = $PlayerCard/SignatureBg/Signature
@onready var _level_lbl:     Label         = $PlayerCard/LevelPill/LevelLabel
@onready var _uid_lbl:       Label         = $TopBar/UIDLabel
@onready var _avatar_icon:   Panel         = $PlayerCard/AvatarIcon

var _avatar_label: Label   = null
var _dropdown:     Control = null  # ⋮ dropdown panel
var _dot_btn:      Button  = null  # ⋮ button ref for positioning

# ── Ready ─────────────────────────────────────────────────────────
func _ready() -> void:
	var top_bar := get_node_or_null("TopBar") as Control
	if top_bar: top_bar.z_index = 8

	var act_card := get_node_or_null("ActivityCard") as Control
	if act_card: act_card.clip_contents = true

	if _back:
		_back.pressed.connect(_go_back)

	# Avatar emoji overlay
	_avatar_label = Label.new()
	_avatar_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_avatar_label.add_theme_font_size_override("font_size", 26)
	_avatar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _avatar_icon:
		_avatar_icon.add_child(_avatar_label)
		_avatar_icon.gui_input.connect(_on_avatar_click)

	_refresh_from_player_data()
	PlayerData.profile_changed.connect(_refresh_from_player_data)

	_build_dot_menu()
	_build_showcase()
	_build_activity()
	_update_domain()
	DomainManager.domain_changed.connect(_on_domain_changed)

	if _fade:
		var t := create_tween()
		t.tween_property(_fade, "color:a", 0.0, 0.35)

# ── Read PlayerData and populate UI ──────────────────────────────
func _refresh_from_player_data() -> void:
	if _name_lbl:   _name_lbl.text  = PlayerData.player_name
	if _sig_lbl:    _sig_lbl.text   = PlayerData.signature
	if _level_lbl:  _level_lbl.text = "Lv. %d" % PlayerData.level
	if _uid_lbl:    _uid_lbl.text   = "UID: %s" % PlayerData.uid
	if _avatar_label:
		_avatar_label.text    = AVATAR_ICONS[PlayerData.avatar_idx]
	if _avatar_icon:
		_avatar_icon.modulate = AVATAR_COLORS[PlayerData.avatar_idx]

# ── ⋮ dot button + dropdown ──────────────────────────────────────
func _build_dot_menu() -> void:
	var pc: Panel = get_node_or_null("PlayerCard") as Panel
	if not pc: return

	_dot_btn = Button.new()
	_dot_btn.text = "⋮"
	_dot_btn.position = Vector2(318, 8)
	_dot_btn.size     = Vector2(28, 28)
	_dot_btn.add_theme_font_size_override("font_size", 18)
	_dot_btn.add_theme_color_override("font_color", Color(0.7, 0.87, 1, 0.7))
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = Color(0, 0, 0, 0)
	for style in ["normal","hover","pressed","focus"]:
		_dot_btn.add_theme_stylebox_override(style, dsb)
	_dot_btn.pressed.connect(_toggle_dropdown)
	pc.add_child(_dot_btn)

func _toggle_dropdown() -> void:
	if _dropdown and is_instance_valid(_dropdown):
		_dropdown.queue_free()
		_dropdown = null
		return
	_open_dropdown()

func _open_dropdown() -> void:
	# Position below the ⋮ button (PlayerCard is at y=60, dot_btn at y=8 inside it)
	# Absolute position on screen: y = 60 + 8 + 28 + 4 = 100
	const ITEMS := [
		{"icon": "✎",  "label": "แก้ไขโปรไฟล์"},
		{"icon": "👤", "label": "เปลี่ยนอวตาร"},
		{"icon": "📊", "label": "ดูสถิติ"},
	]
	const ITEM_H  := 40.0
	const PANEL_W := 180.0
	const PANEL_X := 172.0   # right-align near dot_btn (PlayerCard x=16, btn x=318 → abs=334; panel right edge=334+28=362 → panel x=362-180=182, clamped to screen)
	const PANEL_Y := 100.0   # below dot_btn

	# Dim (transparent, just catches outside clicks)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 15
	add_child(dim)
	_dropdown = dim

	# Panel
	var panel_h := ITEMS.size() * ITEM_H + 8
	var sb := StyleBoxFlat.new()
	sb.bg_color    = Color(0.04, 0.07, 0.18, 0.97)
	sb.border_color = Color(0.37, 0.62, 1.0, 0.3)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: sb.set_border_width(s, 1)
	sb.corner_radius_top_left=10; sb.corner_radius_top_right=10
	sb.corner_radius_bottom_right=10; sb.corner_radius_bottom_left=10
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size  = 8

	var panel := Panel.new()
	panel.size     = Vector2(PANEL_W, panel_h)
	panel.position = Vector2(PANEL_X, PANEL_Y)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.add_child(panel)

	# Slide in from above
	panel.position.y = PANEL_Y - 16
	panel.modulate.a = 0.0
	var ta := panel.create_tween().set_parallel(true)
	ta.tween_property(panel, "position:y", PANEL_Y, 0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	ta.tween_property(panel, "modulate:a", 1.0,     0.12)

	for i in ITEMS.size():
		var data: Dictionary = ITEMS[i]
		var btn := Button.new()
		btn.text = "%s  %s" % [str(data["icon"]), str(data["label"])]
		btn.size     = Vector2(PANEL_W, ITEM_H)
		btn.position = Vector2(0, i * ITEM_H + 4)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color(0.85, 0.93, 1.0, 0.9))

		var bsb_n := StyleBoxFlat.new()
		bsb_n.bg_color = Color(0, 0, 0, 0)
		var bsb_h := StyleBoxFlat.new()
		bsb_h.bg_color = Color(0.37, 0.62, 1.0, 0.12)
		bsb_h.corner_radius_top_left=8; bsb_h.corner_radius_top_right=8
		bsb_h.corner_radius_bottom_right=8; bsb_h.corner_radius_bottom_left=8
		btn.add_theme_stylebox_override("normal",  bsb_n)
		btn.add_theme_stylebox_override("hover",   bsb_h)
		btn.add_theme_stylebox_override("pressed", bsb_n)
		btn.add_theme_stylebox_override("focus",   StyleBoxFlat.new())

		var label_str: String = str(data["label"])
		btn.pressed.connect(func():
			dim.queue_free()
			_dropdown = null
			_on_dropdown_item(label_str)
		)
		panel.add_child(btn)

	# Click dim to close
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			dim.queue_free()
			_dropdown = null)

func _on_dropdown_item(label: String) -> void:
	match label:
		"แก้ไขโปรไฟล์": _open_edit_popup()
		"เปลี่ยนอวตาร":  _open_avatar_popup()
		"ดูสถิติ":        _open_stats_modal()

# ── Avatar picker ─────────────────────────────────────────────────
func _on_avatar_click(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_open_avatar_popup()

func _open_avatar_popup() -> void:
	const PW := 400.0; const PH := 190.0
	var dim := _make_dim(20)
	var panel := _make_panel(dim, PW, PH)

	var title := _centered_label(panel, "เลือกอวตาร", 14, Color(1,1,1,0.9), 0, 14, PW, 24)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	const BTN_W := 44.0; const GAP := 10.0
	var n := AVATAR_COLORS.size()
	var row_x := (PW - (n * BTN_W + (n-1) * GAP)) * 0.5
	for i in n:
		var p := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = AVATAR_COLORS[i]
		for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
			sb.set(r, 24)
		if i == PlayerData.avatar_idx:
			for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: sb.set_border_width(s, 2)
			sb.border_color = Color(1,1,1,0.9)
		p.add_theme_stylebox_override("panel", sb)
		p.position = Vector2(row_x + i * (BTN_W + GAP), 50)
		p.size     = Vector2(BTN_W, BTN_W)
		var lbl := Label.new()
		lbl.text = AVATAR_ICONS[i]
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(lbl)
		p.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				PlayerData.set_avatar(i)
				dim.queue_free())
		panel.add_child(p)

	var cancel := _popup_btn("ยกเลิก", false)
	cancel.position = Vector2((PW - 160) * 0.5, 136)
	cancel.size     = Vector2(160, 36)
	cancel.pressed.connect(func(): dim.queue_free())
	panel.add_child(cancel)

	add_child(dim)

# ── Edit profile popup ────────────────────────────────────────────
func _open_edit_popup() -> void:
	const PW := 440.0; const PH := 280.0
	var dim := _make_dim(20)
	var panel := _make_panel(dim, PW, PH)

	_centered_label(panel, "แก้ไขโปรไฟล์", 15, Color(1,1,1,0.9), 0, 18, PW, 26)

	var name_hint := _centered_label(panel, "ชื่อผู้เล่น", 11, Color(0.6,0.8,1,0.7), 24, 54, PW-48, 16)
	name_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var name_edit := _make_line_edit(PlayerData.player_name)
	name_edit.position = Vector2(24, 72); name_edit.size = Vector2(PW-48, 32)
	name_edit.max_length = 20
	panel.add_child(name_edit)

	var sig_hint := _centered_label(panel, "คำขวัญ", 11, Color(0.6,0.8,1,0.7), 24, 118, PW-48, 16)
	sig_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var sig_edit := _make_line_edit(PlayerData.signature)
	sig_edit.position = Vector2(24, 136); sig_edit.size = Vector2(PW-48, 32)
	sig_edit.max_length = 50
	panel.add_child(sig_edit)

	const BTN_W := 180.0; const BTN_H := 38.0; const BTN_Y := 222.0
	var cancel := _popup_btn("ยกเลิก", false)
	cancel.position = Vector2(20, BTN_Y); cancel.size = Vector2(BTN_W, BTN_H)
	cancel.pressed.connect(func(): dim.queue_free())
	panel.add_child(cancel)

	var ok := _popup_btn("บันทึก", true)
	ok.position = Vector2(PW - 20 - BTN_W, BTN_Y); ok.size = Vector2(BTN_W, BTN_H)
	ok.pressed.connect(func():
		var new_name := name_edit.text.strip_edges()
		PlayerData.save_profile(
			new_name if new_name.length() > 0 else PlayerData.player_name,
			sig_edit.text.strip_edges(),
			PlayerData.avatar_idx
		)
		dim.queue_free())
	panel.add_child(ok)

	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed: dim.queue_free())
	add_child(dim)

# ── Stats modal ───────────────────────────────────────────────────
func _open_stats_modal() -> void:
	const PW := 460.0; const PH := 520.0
	var dim := _make_dim(20)
	var panel := _make_panel(dim, PW, PH)

	_centered_label(panel, "สถิติผู้เล่น", 15, Color(0.388, 0.624, 1, 0.9), 20, 16, PW-60, 26).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var close_btn := _ghost_btn("✕", 14)
	close_btn.position = Vector2(PW - 44, 12); close_btn.size = Vector2(32, 32)
	close_btn.pressed.connect(func(): dim.queue_free())
	panel.add_child(close_btn)

	var hdiv := ColorRect.new()
	hdiv.color = Color(0.388, 0.624, 1, 0.15)
	hdiv.position = Vector2(16, 46); hdiv.size = Vector2(PW-32, 1)
	hdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hdiv)

	var y := 56.0
	for i in STATS.size():
		var data: Dictionary = STATS[i]
		var row_bg := ColorRect.new()
		row_bg.color = Color(1,1,1, 0.02) if i % 2 == 0 else Color(0,0,0,0)
		row_bg.position = Vector2(0, y-2); row_bg.size = Vector2(PW, 46)
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(row_bg)

		_icon_label(panel, str(data["icon"]), 16, Vector2(16, y+4), Vector2(26, 26))
		_centered_label(panel, str(data["label"]), 10, Color(0.65,0.78,1,0.55), 50, y+2,  220, 16).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_centered_label(panel, str(data["value"]), 14, Color(1,1,1,0.92),       50, y+18, 360, 20).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		y += 48.0

	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed: dim.queue_free())
	add_child(dim)

# ── Domain bar ────────────────────────────────────────────────────
func _update_domain() -> void:
	_on_domain_changed(DomainManager.get_percent())

func _on_domain_changed(pct: float) -> void:
	if not is_inside_tree(): return
	if _domain_pct: _domain_pct.text = "%d%%" % int(pct)
	_apply_domain_bar.call_deferred(pct)

func _apply_domain_bar(pct: float) -> void:
	if not is_inside_tree() or not is_instance_valid(_domain_bar_bg) or not is_instance_valid(_domain_fill): return
	_domain_fill.size.x = _domain_bar_bg.size.x * (pct / 100.0)

# ── Showcase ─────────────────────────────────────────────────────
func _build_showcase() -> void:
	if not _showcase_row: return
	for q in _showcase_row.get_children(): q.queue_free()
	for entry in SHOWCASE:
		_showcase_row.add_child(_make_showcase_card(entry))

func _make_showcase_card(data: Dictionary) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(160, 240)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]: sb.set(r, 14)
	for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: sb.set_border_width(s, 1)
	if str(data.get("name","")) == "":
		sb.bg_color = Color(1,1,1,0.025); sb.border_color = Color(1,1,1,0.06)
		card.add_theme_stylebox_override("panel", sb)
		var plus := Label.new()
		plus.text = "+"; plus.add_theme_font_size_override("font_size", 28)
		plus.add_theme_color_override("font_color", Color(1,1,1,0.15))
		plus.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		plus.offset_left=-16; plus.offset_right=16; plus.offset_top=-18; plus.offset_bottom=18
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
	dim.offset_top = -80; dim.color = Color(0,0,0.04,0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dim)

	var rarity: int = int(data.get("rarity", 3))
	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.add_theme_font_size_override("font_size", 12)
	match rarity:
		5: stars.add_theme_color_override("font_color", Color(1.0,0.82,0.2,0.95))
		4: stars.add_theme_color_override("font_color", Color(0.75,0.55,1.0,0.95))
		_: stars.add_theme_color_override("font_color", Color(0.5,0.7,1.0,0.95))
	stars.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stars.offset_left=10; stars.offset_right=200; stars.offset_bottom=-38; stars.offset_top=-58
	card.add_child(stars)

	var elem := Label.new()
	elem.text = str(data.get("element",""))
	elem.add_theme_font_size_override("font_size", 16)
	elem.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	elem.offset_left=-32; elem.offset_right=-6; elem.offset_top=8; elem.offset_bottom=30
	card.add_child(elem)

	var name_lbl := Label.new()
	name_lbl.text = str(data.get("name",""))
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1,1,1,0.95))
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	name_lbl.offset_left=10; name_lbl.offset_right=200; name_lbl.offset_bottom=-18; name_lbl.offset_top=-40
	card.add_child(name_lbl)

	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d" % int(data.get("level",1))
	lv_lbl.add_theme_font_size_override("font_size", 11)
	lv_lbl.add_theme_color_override("font_color", Color(0.7,0.87,1,0.7))
	lv_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lv_lbl.offset_left=10; lv_lbl.offset_right=120; lv_lbl.offset_bottom=-4; lv_lbl.offset_top=-20
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
	icon.text = str(data.get("icon",""))
	icon.add_theme_font_size_override("font_size", 18)
	icon.custom_minimum_size = Vector2(28, 0)
	icon.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	var txt := Label.new()
	txt.text = str(data.get("text",""))
	txt.add_theme_font_size_override("font_size", 13)
	txt.add_theme_color_override("font_color", Color(0.9,0.93,1,0.9))
	col.add_child(txt)
	var time_lbl := Label.new()
	time_lbl.text = str(data.get("time",""))
	time_lbl.add_theme_font_size_override("font_size", 10)
	time_lbl.add_theme_color_override("font_color", Color(1,1,1,0.35))
	col.add_child(time_lbl)
	row.add_child(col)

	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.add_child(row)
	var div := ColorRect.new()
	div.color = Color(1,1,1,0.05)
	div.custom_minimum_size = Vector2(0,1)
	wrap.add_child(div)
	return wrap

# ── Builder helpers ───────────────────────────────────────────────
func _make_dim(z: int) -> ColorRect:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0,0,0,0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = z
	return dim

func _make_panel(dim: ColorRect, pw: float, ph: float) -> Panel:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.98)
	for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: sb.set_border_width(s, 1)
	sb.border_color = Color(0.4, 0.6, 1, 0.25)
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]: sb.set(r, 16)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", sb)
	panel.size     = Vector2(pw, ph)
	panel.position = Vector2((1152 - pw) * 0.5, (648 - ph) * 0.5)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.add_child(panel)
	return panel

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

func _icon_label(parent: Control, text: String, fsize: int, pos: Vector2, size: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.position = pos; lbl.size = size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)

func _make_line_edit(default_text: String) -> LineEdit:
	var le := LineEdit.new()
	le.text = default_text
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1,1,1,0.06)
	for s in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: sb.set_border_width(s, 1)
	sb.border_color = Color(0.4,0.6,1,0.35)
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]: sb.set(r, 8)
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
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]: sb.set(r, 8)
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Color(1,1,1,0.85))
	btn.add_theme_font_size_override("font_size", 13)
	btn.text = label
	return btn

func _ghost_btn(label: String, fsize: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", fsize)
	btn.add_theme_color_override("font_color", Color(1,1,1,0.5))
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0,0,0,0)
	for style in ["normal","hover","pressed","focus"]: btn.add_theme_stylebox_override(style, sb)
	return btn

# ── Navigation ────────────────────────────────────────────────────
func _go_back() -> void:
	if DomainManager.domain_changed.is_connected(_on_domain_changed):
		DomainManager.domain_changed.disconnect(_on_domain_changed)
	if PlayerData.profile_changed.is_connected(_refresh_from_player_data):
		PlayerData.profile_changed.disconnect(_refresh_from_player_data)
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0,0,0,0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(SC_MAIN)
