extends Control

const SC_MAIN      := "res://main_menu.tscn"
const SC_STORY     := "res://story_scene.tscn"

# ── สีธีมการ์ดเหมือนหน้าหลัก (SB_Card2) ──────────────────────────
const CARD_BG     := Color(0.06, 0.11, 0.26, 0.92)
const CARD_BORDER := Color(0.18, 0.50, 0.90, 0.45)

# ── เนื้อเรื่องหลัก ───────────────────────────────────────────────
const MAIN_CHAPTERS: Array = [
	{
		"title":    "บทที่ 1: จุดเริ่มต้นของปฏิกิริยา",
		"sub":      "CHAPTER 1",
		"tag":      "MAIN STORY",
		"status":   "done",
		"art_col":  Color(0.04, 0.08, 0.22, 0.8),
		"arrow_col": Color(0.22, 0.72, 1, 1),
	},
	{
		"title":    "บทที่ 2: เงาของ Void Syndicate",
		"sub":      "CHAPTER 2",
		"tag":      "MAIN STORY",
		"status":   "done",
		"art_col":  Color(0.04, 0.08, 0.22, 0.8),
		"arrow_col": Color(0.22, 0.72, 1, 1),
	},
	{
		"title":    "บทที่ 3: สูตรที่สาบสูญ",
		"sub":      "CHAPTER 3  ·  กำลังดำเนินอยู่",
		"tag":      "MAIN STORY",
		"status":   "current",
		"art_col":  Color(0.05, 0.12, 0.30, 0.9),
		"arrow_col": Color(0.45, 0.78, 1, 1),
	},
	{
		"title":    "บทที่ 4: ???",
		"sub":      "CHAPTER 4",
		"tag":      "MAIN STORY",
		"status":   "locked",
		"art_col":  Color(0.02, 0.03, 0.08, 0.8),
		"arrow_col": Color(0.3, 0.3, 0.4, 0.4),
	},
	{
		"title":    "บทที่ 5: ???",
		"sub":      "CHAPTER 5",
		"tag":      "MAIN STORY",
		"status":   "locked",
		"art_col":  Color(0.02, 0.03, 0.08, 0.8),
		"arrow_col": Color(0.3, 0.3, 0.4, 0.4),
	},
]

# ── เนื้อเรื่องแยก ─────────────────────────────────────────────────
const SIDE_CHAPTERS: Array = [
	{
		"title":    "ตำนาน: อัลเคมิสต์คนแรก",
		"sub":      "Alchemist  ·  เล่นแล้ว",
		"tag":      "SIDE STORY",
		"status":   "done",
		"art_col":  Color(0.04, 0.08, 0.22, 0.8),
		"arrow_col": Color(0.22, 0.72, 1, 1),
	},
	{
		"title":    "ความทรงจำของ Lyra",
		"sub":      "Lyra  ·  กำลังดำเนินอยู่",
		"tag":      "SIDE STORY",
		"status":   "current",
		"art_col":  Color(0.12, 0.04, 0.22, 0.9),
		"arrow_col": Color(0.65, 0.35, 1, 1),
	},
	{
		"title":    "แสงและเงาของ Kael",
		"sub":      "Kael  ·  ล็อก",
		"tag":      "SIDE STORY",
		"status":   "locked",
		"art_col":  Color(0.02, 0.03, 0.08, 0.8),
		"arrow_col": Color(0.3, 0.3, 0.4, 0.4),
	},
	{
		"title":    "ความลับของ Mira",
		"sub":      "Mira  ·  ล็อก",
		"tag":      "SIDE STORY",
		"status":   "locked",
		"art_col":  Color(0.02, 0.03, 0.08, 0.8),
		"arrow_col": Color(0.3, 0.3, 0.4, 0.4),
	},
]

var _mode := "main"

func _ready() -> void:
	_build_ui()

# ── Build full UI ───────────────────────────────────────────────────
func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.02, 0.07, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_add_starfield()

	# Top bar
	add_child(_make_topbar())

	# Tab row
	var tabs := _make_tab_row()
	tabs.name = "TabRow"
	tabs.position = Vector2(0, 60)
	tabs.size     = Vector2(1152, 48)
	add_child(tabs)

	# Content
	var area := Control.new()
	area.name     = "ContentArea"
	area.position = Vector2(0, 108)
	area.size     = Vector2(1152, 540)
	add_child(area)
	_rebuild_content()

	# Fade in
	var fade := ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	var t := create_tween()
	t.tween_property(fade, "color:a", 0.0, 0.30)

# ── Star field ──────────────────────────────────────────────────────
func _add_starfield() -> void:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for _i in 80:
		var dot := ColorRect.new()
		var sz := rng.randf_range(0.8, 2.2)
		dot.size     = Vector2(sz, sz)
		dot.position = Vector2(rng.randf_range(0, 1152), rng.randf_range(0, 648))
		dot.color    = Color(1, 1, 1, rng.randf_range(0.12, 0.5))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(dot)

# ── Top bar ─────────────────────────────────────────────────────────
func _make_topbar() -> Control:
	var bar := Panel.new()
	bar.position = Vector2(0, 0)
	bar.size     = Vector2(1152, 60)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.12, 0.92)
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
	title.size     = Vector2(1152, 60)
	title.position = Vector2(0, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(title)
	return bar

# ── Tab row ─────────────────────────────────────────────────────────
func _make_tab_row() -> Control:
	var row := Control.new()

	var tab_bg := ColorRect.new()
	tab_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tab_bg.color = Color(0.015, 0.03, 0.10, 0.92)
	tab_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tab_bg)

	var sep := ColorRect.new()
	sep.size = Vector2(1152, 1); sep.position = Vector2(0, 47)
	sep.color = Color(0.25, 0.45, 1, 0.18)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sep)

	row.add_child(_make_tab_btn("📖  เนื้อเรื่อง",    "main", Vector2(100, 6)))
	row.add_child(_make_tab_btn("✦  เนื้อเรื่องแยก", "side", Vector2(320, 6)))
	return row

func _make_tab_btn(label: String, mode: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = label; btn.position = pos; btn.size = Vector2(200, 36)
	btn.add_theme_font_size_override("font_size", 13)

	var apply_style := func():
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

	apply_style.call()
	btn.pressed.connect(func():
		if _mode == mode: return
		_mode = mode
		_rebuild_content()
		# re-style all tabs
		var tr: Control = get_node_or_null("TabRow")
		if tr:
			for c in tr.get_children():
				if c is Button:
					var this_mode := "main" if "เนื้อเรื่อง" in c.text and not "แยก" in c.text else "side"
					var active := (_mode == this_mode)
					var sb2 := StyleBoxFlat.new()
					sb2.bg_color = Color(0.22, 0.42, 1, 0.14) if active else Color(0, 0, 0, 0)
					sb2.border_width_bottom = 2 if active else 0
					sb2.border_color = Color(0.5, 0.75, 1, 0.9)
					sb2.corner_radius_top_left = 6; sb2.corner_radius_top_right = 6
					c.add_theme_stylebox_override("normal",  sb2)
					c.add_theme_stylebox_override("hover",   sb2)
					c.add_theme_stylebox_override("pressed", sb2)
					c.add_theme_color_override("font_color",
						Color(0.75, 0.9, 1, 1.0) if active else Color(0.6, 0.7, 0.85, 0.55))
	)
	return btn

# ── Content rebuild ─────────────────────────────────────────────────
func _rebuild_content() -> void:
	var area: Control = get_node_or_null("ContentArea")
	if not area: return
	for c in area.get_children(): c.queue_free()

	var chapters := MAIN_CHAPTERS if _mode == "main" else SIDE_CHAPTERS

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	area.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   56)
	margin.add_theme_constant_override("margin_right",  56)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	scroll.add_child(margin)

	for data in chapters:
		vbox.add_child(_make_card(data))

# ── Card (สไตล์เหมือน AdventureCard / ChronicleCard ในหน้าหลัก) ───
func _make_card(data: Dictionary) -> Control:
	var status: String  = str(data.get("status", "locked"))
	var locked          := status == "locked"
	var is_current      := status == "current"
	var art_col: Color  = data.get("art_col",   Color(0.04, 0.08, 0.22, 0.8)) as Color
	var arrow_col: Color = data.get("arrow_col", Color(0.22, 0.72, 1, 1))      as Color

	# ── Panel (เหมือน SB_Card2) ──
	var card := Panel.new()
	card.custom_minimum_size    = Vector2(0, 88)
	card.size_flags_horizontal  = Control.SIZE_EXPAND_FILL

	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BG if not locked else Color(0.03, 0.05, 0.12, 0.85)
	if is_current:
		sb.border_color = Color(0.35, 0.62, 1.0, 0.75)
		sb.border_width_left = 3
	else:
		sb.border_color = CARD_BORDER if not locked else Color(0.15, 0.18, 0.28, 0.3)
		sb.border_width_left = 1
	sb.border_width_top = 1; sb.border_width_right = 1; sb.border_width_bottom = 1
	sb.corner_radius_top_left = 7; sb.corner_radius_top_right = 7
	sb.corner_radius_bottom_right = 7; sb.corner_radius_bottom_left = 7
	card.add_theme_stylebox_override("panel", sb)

	# ── กล่องศิลปะฝั่งขวา (เหมือน ArtBg ในหน้าหลัก) ──
	var art_w := 200
	var art_bg := ColorRect.new()
	art_bg.size     = Vector2(art_w, 84)
	art_bg.position = Vector2(840, 2)
	art_bg.color    = art_col
	art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art_bg)

	# Gradient mask ซ้ายของ art block (fade ออกจากการ์ด)
	# ใช้ ColorRect สีเดียวกับ card ลด opacity ทำ gradient effect
	if not locked:
		var art_fade := ColorRect.new()
		art_fade.size     = Vector2(32, 84)
		art_fade.position = Vector2(838, 2)
		art_fade.color    = Color(CARD_BG.r, CARD_BG.g, CARD_BG.b, 0.9)
		art_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(art_fade)

	# ── ข้อความฝั่งซ้าย (เหมือนหน้าหลัก) ──

	# Tag chip เล็กๆ (MAIN STORY / SIDE STORY)
	var tag_lbl := Label.new()
	tag_lbl.text = str(data.get("tag", ""))
	tag_lbl.add_theme_font_size_override("font_size", 9)
	tag_lbl.add_theme_color_override("font_color",
		Color(0.5, 0.72, 1, 0.7) if not locked else Color(0.3, 0.3, 0.4, 0.4))
	tag_lbl.position = Vector2(14, 10)
	tag_lbl.size     = Vector2(120, 14)
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tag_lbl)

	# Title (เหมือน Title label ในหน้าหลัก font_size 16)
	var title_lbl := Label.new()
	title_lbl.text = str(data.get("title", ""))
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color",
		Color(0.93, 0.96, 1, 1) if not locked else Color(0.4, 0.4, 0.5, 0.45))
	title_lbl.position = Vector2(14, 26)
	title_lbl.size     = Vector2(800, 26)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title_lbl)

	# Sub (เหมือน Sub label ในหน้าหลัก font_size 10)
	var sub_lbl := Label.new()
	sub_lbl.text = str(data.get("sub", ""))
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color",
		Color(0.58, 0.78, 1, 1) if not locked else Color(0.3, 0.3, 0.4, 0.4))
	sub_lbl.position = Vector2(14, 54)
	sub_lbl.size     = Vector2(800, 18)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sub_lbl)

	# Arrow ▶ (เหมือน Arrow label ในหน้าหลัก)
	var arrow := Label.new()
	arrow.text = "🔒" if locked else "▶"
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", arrow_col)
	arrow.position = Vector2(1020, 34)
	arrow.size     = Vector2(20, 20)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(arrow)

	# Lock overlay (เหมือน LockOverlay ในหน้าหลัก)
	if locked:
		var dim := ColorRect.new()
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.color = Color(0, 0, 0, 0.45)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(dim)

	# Current chapter indicator glow
	if is_current:
		var glow := ColorRect.new()
		glow.size     = Vector2(3, 88)
		glow.position = Vector2(0, 0)
		glow.color    = Color(0.45, 0.72, 1.0, 0.9)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(glow)

	# ── Click + hover (ถ้าไม่ล็อก) ──
	if not locked:
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_goto(SC_STORY)
		)
		card.mouse_entered.connect(func():
			var t := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			t.tween_property(card, "modulate", Color(1.08, 1.08, 1.12, 1), 0.10)
		)
		card.mouse_exited.connect(func():
			var t := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			t.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.16)
		)
	else:
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return card

# ── Navigation ───────────────────────────────────────────────────────
func _goto(path: String) -> void:
	if not ResourceLoader.exists(path): return
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
