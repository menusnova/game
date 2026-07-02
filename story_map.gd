extends Control

const SC_MAIN        := "res://main_menu.tscn"
const SC_MAIN_STORY  := "res://story_scene.tscn"
const SC_SIDE_STORY  := "res://story_scene.tscn"   # เปลี่ยนเป็น side_story_scene.tscn เมื่อมี

# ── Chapter data ────────────────────────────────────────────────
const MAIN_CHAPTERS: Array = [
	{"id": 1, "title": "บทที่ 1: จุดเริ่มต้นของปฏิกิริยา",      "subtitle": "ค้นพบความลับของห้องทดลองต้องห้าม",  "status": "done"},
	{"id": 2, "title": "บทที่ 2: เงาของ Void Syndicate",         "subtitle": "ติดตามเส้นทางขององค์กรลึกลับ",        "status": "done"},
	{"id": 3, "title": "บทที่ 3: สูตรที่สาบสูญ",                 "subtitle": "ตามหาบันทึกของนักเล่นแร่ผู้ยิ่งใหญ่", "status": "current"},
	{"id": 4, "title": "บทที่ 4: ???",                            "subtitle": "???",                                  "status": "locked"},
	{"id": 5, "title": "บทที่ 5: ???",                            "subtitle": "???",                                  "status": "locked"},
]

const SIDE_CHAPTERS: Array = [
	{"id": 1, "title": "ตำนาน: อัลเคมิสต์คนแรก",    "subtitle": "เรื่องราวก่อนยุคการสังเคราะห์",     "status": "done",    "tag": "Alchemist"},
	{"id": 2, "title": "ความทรงจำของ Lyra",           "subtitle": "อดีตที่ถูกซ่อนไว้ของ Lyra",         "status": "current", "tag": "Lyra"},
	{"id": 3, "title": "แสงและเงาของ Kael",           "subtitle": "ก่อนที่เขาจะเข้าร่วม Guild",        "status": "locked",  "tag": "Kael"},
	{"id": 4, "title": "ความลับของ Mira",             "subtitle": "???",                                 "status": "locked",  "tag": "Mira"},
]

var _mode := "main"   # "main" | "side"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# ── Background ──────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.02, 0.07, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Star field
	_add_starfield()

	# Ambient gradient overlay (top→transparent, bottom→dark)
	var grad := ColorRect.new()
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grad.color = Color(0.02, 0.05, 0.16, 0.55)
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grad)

	# ── Top bar ─────────────────────────────────────────────────
	var topbar := _make_topbar()
	add_child(topbar)

	# ── Mode selector tabs ──────────────────────────────────────
	var tab_row := _make_tab_row()
	tab_row.position = Vector2(0, 60)
	tab_row.size     = Vector2(1152, 48)
	add_child(tab_row)

	# ── Content area (chapter list) ─────────────────────────────
	var content := Control.new()
	content.name     = "ContentArea"
	content.position = Vector2(0, 108)
	content.size     = Vector2(1152, 540)
	add_child(content)

	_rebuild_content()

	# ── Fade in ─────────────────────────────────────────────────
	var fade := ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	var t := create_tween()
	t.tween_property(fade, "color:a", 0.0, 0.30)

func _add_starfield() -> void:
	var star_layer := Control.new()
	star_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	star_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(star_layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 80:
		var dot := ColorRect.new()
		var sz := rng.randf_range(0.8, 2.2)
		dot.size     = Vector2(sz, sz)
		dot.position = Vector2(rng.randf_range(0, 1152), rng.randf_range(0, 648))
		dot.color    = Color(1, 1, 1, rng.randf_range(0.15, 0.55))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_layer.add_child(dot)

func _make_topbar() -> Control:
	var bar := Panel.new()
	bar.position = Vector2(0, 0)
	bar.size     = Vector2(1152, 60)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.12, 0.88)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.3, 0.55, 1, 0.2)
	bar.add_theme_stylebox_override("panel", sb)

	var back := Button.new()
	back.text = "← กลับ"
	back.position = Vector2(16, 14)
	back.size     = Vector2(80, 32)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(1, 1, 1, 0.05)
	bsb.border_width_top = 1; bsb.border_width_right = 1
	bsb.border_width_bottom = 1; bsb.border_width_left = 1
	bsb.border_color = Color(1, 1, 1, 0.12)
	bsb.corner_radius_top_left = 8; bsb.corner_radius_top_right = 8
	bsb.corner_radius_bottom_right = 8; bsb.corner_radius_bottom_left = 8
	back.add_theme_stylebox_override("normal",  bsb)
	back.add_theme_stylebox_override("hover",   bsb)
	back.add_theme_stylebox_override("pressed", bsb)
	back.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	back.add_theme_font_size_override("font_size", 13)
	back.pressed.connect(_go_back)
	bar.add_child(back)

	var title := Label.new()
	title.text = "เนื้อเรื่อง"
	title.position = Vector2(0, 0)
	title.size     = Vector2(1152, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(title)

	return bar

func _make_tab_row() -> Control:
	var row := Control.new()
	row.name = "TabRow"

	var tab_bg := ColorRect.new()
	tab_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tab_bg.color = Color(0.015, 0.03, 0.10, 0.92)
	tab_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tab_bg)

	var sep := ColorRect.new()
	sep.size = Vector2(1152, 1)
	sep.position = Vector2(0, 47)
	sep.color = Color(0.25, 0.45, 1, 0.18)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sep)

	var tab_main := _make_tab_btn("📖  เนื้อเรื่อง", "main", Vector2(100, 6))
	var tab_side := _make_tab_btn("✦  เนื้อเรื่องแยก", "side", Vector2(320, 6))
	row.add_child(tab_main)
	row.add_child(tab_side)

	return row

func _make_tab_btn(label: String, mode: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text     = label
	btn.position = pos
	btn.size     = Vector2(200, 36)
	btn.add_theme_font_size_override("font_size", 13)

	var _update_style := func():
		var active := (_mode == mode)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.22, 0.42, 1, 0.14) if active else Color(0, 0, 0, 0)
		sb.border_width_bottom = 2 if active else 0
		sb.border_color = Color(0.5, 0.75, 1, 0.9)
		sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6
		btn.add_theme_stylebox_override("normal",  sb)
		btn.add_theme_stylebox_override("hover",   sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_color_override("font_color",
			Color(0.75, 0.9, 1, 1.0) if active else Color(0.6, 0.7, 0.85, 0.55))

	_update_style.call()

	btn.pressed.connect(func():
		if _mode == mode:
			return
		_mode = mode
		# refresh all tab buttons
		var tab_row: Control = get_node_or_null("TabRow")
		if tab_row:
			for child in tab_row.get_children():
				if child is Button:
					child.emit_signal("visibility_changed")  # workaround: just rebuild
		_rebuild_content()
		# re-style this button
		_update_style.call()
		# re-style sibling tabs by rebuilding tab row
		var tr: Control = get_node_or_null("TabRow")
		if tr:
			for c in tr.get_children():
				if c is Button and c != btn:
					var sb2 := StyleBoxFlat.new()
					sb2.bg_color = Color(0, 0, 0, 0)
					sb2.corner_radius_top_left = 6; sb2.corner_radius_top_right = 6
					c.add_theme_stylebox_override("normal",  sb2)
					c.add_theme_stylebox_override("hover",   sb2)
					c.add_theme_stylebox_override("pressed", sb2)
					c.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 0.55))
	)
	return btn

func _rebuild_content() -> void:
	var area: Control = get_node_or_null("ContentArea")
	if not area:
		return
	for c in area.get_children():
		c.queue_free()

	var chapters := MAIN_CHAPTERS if _mode == "main" else SIDE_CHAPTERS
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	area.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   60)
	margin.add_theme_constant_override("margin_right",  60)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	scroll.add_child(margin)

	for i in chapters.size():
		var card := _make_chapter_card(chapters[i], i)
		vbox.add_child(card)

func _make_chapter_card(data: Dictionary, idx: int) -> Control:
	var status: String = str(data.get("status", "locked"))
	var locked := (status == "locked")
	var is_current := (status == "current")

	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 88)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb := StyleBoxFlat.new()
	if locked:
		sb.bg_color    = Color(0.02, 0.03, 0.08, 0.8)
		sb.border_color = Color(0.2, 0.25, 0.4, 0.2)
	elif is_current:
		sb.bg_color    = Color(0.04, 0.08, 0.22, 0.95)
		sb.border_color = Color(0.4, 0.65, 1.0, 0.6)
	else:
		sb.bg_color    = Color(0.03, 0.06, 0.16, 0.88)
		sb.border_color = Color(0.25, 0.45, 0.85, 0.3)
	sb.border_width_top = 1; sb.border_width_right = 1
	sb.border_width_bottom = 1; sb.border_width_left = 1
	if is_current:
		sb.border_width_left = 3
		sb.border_color = Color(0.45, 0.72, 1.0, 0.85)
	sb.corner_radius_top_left = 12; sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12; sb.corner_radius_bottom_left = 12
	card.add_theme_stylebox_override("panel", sb)

	# Glow bar on left edge (current chapter only)
	if is_current:
		var glow := ColorRect.new()
		glow.size     = Vector2(3, 88)
		glow.position = Vector2(0, 0)
		glow.color    = Color(0.45, 0.72, 1.0, 0.9)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(glow)

	# Chapter number badge
	var badge_col: Color
	match status:
		"done":    badge_col = Color(0.3, 0.75, 0.5, 0.9)
		"current": badge_col = Color(0.35, 0.65, 1.0, 0.95)
		_:         badge_col = Color(0.25, 0.25, 0.35, 0.5)

	var num_bg := ColorRect.new()
	num_bg.size     = Vector2(48, 48)
	num_bg.position = Vector2(20, 20)
	num_bg.color    = Color(badge_col.r, badge_col.g, badge_col.b, 0.15)
	num_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(num_bg)

	var num_lbl := Label.new()
	if locked:
		num_lbl.text = "🔒"
		num_lbl.add_theme_font_size_override("font_size", 18)
	elif status == "done":
		num_lbl.text = "✓"
		num_lbl.add_theme_font_size_override("font_size", 20)
	else:
		num_lbl.text = str(data.get("id", idx + 1))
		num_lbl.add_theme_font_size_override("font_size", 22)
	num_lbl.size     = Vector2(48, 48)
	num_lbl.position = Vector2(20, 20)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	num_lbl.add_theme_color_override("font_color", badge_col)
	num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(num_lbl)

	# Tag chip (side story)
	if data.has("tag") and not locked:
		var tag_bg := ColorRect.new()
		tag_bg.size     = Vector2(56, 20)
		tag_bg.position = Vector2(84, 16)
		tag_bg.color    = Color(0.3, 0.55, 1, 0.2)
		tag_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(tag_bg)
		var tag_lbl := Label.new()
		tag_lbl.text = str(data.get("tag", ""))
		tag_lbl.add_theme_font_size_override("font_size", 9)
		tag_lbl.add_theme_color_override("font_color", Color(0.6, 0.82, 1, 0.9))
		tag_lbl.size     = Vector2(56, 20)
		tag_lbl.position = Vector2(84, 16)
		tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(tag_lbl)

	# Title
	var title_y := 20 if not data.has("tag") or locked else 42
	var title_lbl := Label.new()
	title_lbl.text = str(data.get("title", ""))
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color",
		Color(1, 1, 1, 0.9) if not locked else Color(0.5, 0.5, 0.6, 0.45))
	title_lbl.position = Vector2(84, title_y)
	title_lbl.size     = Vector2(880, 24)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title_lbl)

	# Subtitle
	var sub_lbl := Label.new()
	sub_lbl.text = str(data.get("subtitle", ""))
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color",
		Color(0.65, 0.78, 1, 0.6) if not locked else Color(0.35, 0.35, 0.45, 0.35))
	sub_lbl.position = Vector2(84, title_y + 28)
	sub_lbl.size     = Vector2(820, 20)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sub_lbl)

	# Status label (right side)
	var status_lbl := Label.new()
	match status:
		"done":    status_lbl.text = "เล่นแล้ว ✓"
		"current": status_lbl.text = "กำลังดำเนินอยู่ ▶"
		_:         status_lbl.text = "ล็อก"
	status_lbl.add_theme_font_size_override("font_size", 10)
	status_lbl.add_theme_color_override("font_color", badge_col if not locked else Color(0.3, 0.3, 0.4, 0.5))
	status_lbl.position = Vector2(900, 35)
	status_lbl.size     = Vector2(200, 20)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(status_lbl)

	# Click handler
	if not locked:
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_chapter_click(data)
		)
		# hover effect
		card.mouse_entered.connect(func():
			var t := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			t.tween_property(card, "modulate", Color(1.1, 1.1, 1.15, 1), 0.12)
		)
		card.mouse_exited.connect(func():
			var t := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			t.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.18)
		)
	else:
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return card

func _on_chapter_click(data: Dictionary) -> void:
	var target := SC_MAIN_STORY if _mode == "main" else SC_SIDE_STORY
	_goto(target)

func _goto(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(path)

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
