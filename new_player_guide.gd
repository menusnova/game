class_name NewPlayerGuide
extends CanvasLayer

## Multi-page "New Player Guide" overlay. All page content (title/body/icon)
## lives in data/new_player_guide.json — nothing page-specific is hardcoded
## here, so adding, removing, or reordering pages only ever touches the JSON
## file. Add this as a child of any scene and it lays itself out full-screen.

signal closed

const DATA_PATH := "res://data/new_player_guide.json"
const SEEN_PATH := "user://guide_seen.cfg"

const VW := 1152.0
const VH := 648.0

const COL_CYAN   := Color(0.25, 0.85, 1.00)
const COL_PURPLE := Color(0.62, 0.38, 1.00)
const COL_TEXT   := Color(0.88, 0.93, 1.00)
const COL_SUB    := Color(0.68, 0.78, 0.92, 0.85)

var _pages: Array = []
var _idx := 0
var _busy := false

var _panel: Panel
var _icon_lbl: Label
var _title_lbl: Label
var _body_lbl: Label
var _page_lbl: Label
var _prev_btn: Button
var _next_btn: Button
var _dots_row: HBoxContainer
var _content_root: Control

static func has_seen() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SEEN_PATH) != OK:
		return false
	return bool(cfg.get_value("guide", "seen", false))

static func mark_seen() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("guide", "seen", true)
	cfg.save(SEEN_PATH)

func _ready() -> void:
	layer = 90
	_pages = _load_pages()
	if _pages.is_empty():
		queue_free()
		return
	_build_ui()
	_render_page(0, false)

func _load_pages() -> Array:
	if not FileAccess.file_exists(DATA_PATH):
		push_warning("NewPlayerGuide: missing %s" % DATA_PATH)
		return []
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return []
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Array:
		return parsed
	push_warning("NewPlayerGuide: %s did not contain a JSON array" % DATA_PATH)
	return []

# ── UI construction ─────────────────────────────────────────
func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.72, 0.22)

	const PW := 760.0; const PH := 460.0
	# Soft outer glow (purple) behind the glass panel
	var glow := Panel.new()
	glow.size = Vector2(PW + 24.0, PH + 24.0)
	glow.position = Vector2((VW - glow.size.x) * 0.5, (VH - glow.size.y) * 0.5)
	var glow_sb := StyleBoxFlat.new()
	glow_sb.bg_color = Color(0, 0, 0, 0)
	glow_sb.border_color = Color(COL_PURPLE.r, COL_PURPLE.g, COL_PURPLE.b, 0.25)
	glow_sb.set_border_width_all(10)
	glow_sb.set_corner_radius_all(28)
	glow.add_theme_stylebox_override("panel", glow_sb)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(glow)

	# Glass panel
	_panel = Panel.new()
	_panel.size = Vector2(PW, PH)
	_panel.position = Vector2((VW - PW) * 0.5, (VH - PH) * 0.5)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.16, 0.62)
	sb.border_color = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.45)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	_panel.add_theme_stylebox_override("panel", sb)
	dim.add_child(_panel)
	_panel.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			get_viewport().set_input_as_handled()
	)

	# Skip — top-right corner
	var skip_btn := Button.new()
	skip_btn.text = "ข้าม"
	skip_btn.size = Vector2(64, 28)
	skip_btn.position = Vector2(PW - 76.0, 16.0)
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.add_theme_font_size_override("font_size", 12)
	skip_btn.add_theme_color_override("font_color", COL_SUB)
	var skip_sb := StyleBoxFlat.new(); skip_sb.bg_color = Color(0, 0, 0, 0)
	for s in ["normal", "hover", "pressed", "focus"]:
		skip_btn.add_theme_stylebox_override(s, skip_sb)
	skip_btn.pressed.connect(_finish)
	_panel.add_child(skip_btn)

	# Content root — this whole block slides/fades on page change
	_content_root = Control.new()
	_content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_content_root)

	_icon_lbl = Label.new()
	_icon_lbl.position = Vector2(0, 40)
	_icon_lbl.size = Vector2(PW, 70)
	_icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_lbl.add_theme_font_size_override("font_size", 48)
	_icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(_icon_lbl)

	_title_lbl = Label.new()
	_title_lbl.position = Vector2(40, 118)
	_title_lbl.custom_minimum_size = Vector2(PW - 80, 0)
	_title_lbl.size = Vector2(PW - 80, 36)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 24)
	_title_lbl.add_theme_color_override("font_color", COL_CYAN)
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(_title_lbl)

	var div := ColorRect.new()
	div.color = Color(COL_PURPLE.r, COL_PURPLE.g, COL_PURPLE.b, 0.30)
	div.size = Vector2(PW - 120, 1)
	div.position = Vector2(60, 164)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(div)

	_body_lbl = Label.new()
	_body_lbl.position = Vector2(56, 182)
	_body_lbl.custom_minimum_size = Vector2(PW - 112, 0)
	# Height stops short of the page-dots row at PH-96 (=364) so a long body
	# can never overlap the dots/page number/nav buttons below it.
	_body_lbl.size = Vector2(PW - 112, 170)
	_body_lbl.clip_text = true
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.add_theme_font_size_override("font_size", 14)
	_body_lbl.add_theme_color_override("font_color", COL_TEXT)
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_root.add_child(_body_lbl)

	# Page dots
	_dots_row = HBoxContainer.new()
	_dots_row.position = Vector2(0, PH - 96.0)
	_dots_row.size = Vector2(PW, 16)
	_dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_row.add_theme_constant_override("separation", 8)
	_dots_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_dots_row)

	# Page number "x / n"
	_page_lbl = Label.new()
	_page_lbl.position = Vector2(0, PH - 74.0)
	_page_lbl.size = Vector2(PW, 18)
	_page_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_lbl.add_theme_font_size_override("font_size", 11)
	_page_lbl.add_theme_color_override("font_color", COL_SUB)
	_page_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_page_lbl)

	# Previous / Next buttons
	_prev_btn = _make_nav_btn("‹  ก่อนหน้า", Vector2(28, PH - 58.0), Vector2(140, 40))
	_prev_btn.pressed.connect(func(): _go(-1))
	_panel.add_child(_prev_btn)

	_next_btn = _make_nav_btn("ถัดไป  ›", Vector2(PW - 168.0, PH - 58.0), Vector2(140, 40))
	_next_btn.pressed.connect(func(): _go(1))
	_panel.add_child(_next_btn)

func _make_nav_btn(txt: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.position = pos
	btn.size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", COL_TEXT)
	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = Color(COL_CYAN.r * 0.14, COL_CYAN.g * 0.14, COL_CYAN.b * 0.22, 0.9)
	normal_sb.border_color = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.55)
	normal_sb.set_border_width_all(1)
	normal_sb.set_corner_radius_all(10)
	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = Color(COL_CYAN.r * 0.28, COL_CYAN.g * 0.28, COL_CYAN.b * 0.40, 1.0)
	hover_sb.border_color = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.9)
	hover_sb.set_border_width_all(1)
	hover_sb.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover",  hover_sb)
	btn.add_theme_stylebox_override("pressed", hover_sb)
	return btn

# ── Page rendering + navigation ─────────────────────────────
func _go(dir: int) -> void:
	if _busy: return
	var next_idx := _idx + dir
	if next_idx < 0: return
	if next_idx >= _pages.size():
		_finish()
		return
	_render_page(next_idx, true, dir)

func _render_page(new_idx: int, animate: bool, dir: int = 1) -> void:
	_busy = true
	_idx = new_idx
	var page: Dictionary = _pages[_idx]

	var apply := func():
		_icon_lbl.text  = str(page.get("icon", "✨"))
		_title_lbl.text = str(page.get("title", ""))
		_body_lbl.text  = str(page.get("body", ""))
		_page_lbl.text  = "%d / %d" % [_idx + 1, _pages.size()]
		_prev_btn.visible = _idx > 0
		_next_btn.text = "เริ่มเล่น" if _idx == _pages.size() - 1 else "ถัดไป  ›"
		_refresh_dots()

	if not animate:
		apply.call()
		_content_root.modulate.a = 0.0
		create_tween().tween_property(_content_root, "modulate:a", 1.0, 0.25)
		_busy = false
		return

	var slide_out := -60.0 * dir
	var t_out := create_tween().set_parallel(true)
	t_out.tween_property(_content_root, "modulate:a", 0.0, 0.14)
	t_out.tween_property(_content_root, "position:x", slide_out, 0.14).set_trans(Tween.TRANS_QUAD)
	await t_out.finished

	apply.call()
	_content_root.position.x = -slide_out
	var t_in := create_tween().set_parallel(true)
	t_in.tween_property(_content_root, "modulate:a", 1.0, 0.18)
	t_in.tween_property(_content_root, "position:x", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t_in.finished
	_busy = false

func _refresh_dots() -> void:
	for c in _dots_row.get_children():
		c.queue_free()
	for i in _pages.size():
		var dot := Panel.new()
		var on := i == _idx
		dot.custom_minimum_size = Vector2(7, 7) if not on else Vector2(18, 7)
		var dsb := StyleBoxFlat.new()
		dsb.bg_color = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.9 if on else 0.25)
		dsb.set_corner_radius_all(4)
		dot.add_theme_stylebox_override("panel", dsb)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dots_row.add_child(dot)

func _finish() -> void:
	mark_seen()
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.15)
	t.parallel().tween_property(get_node("Dim"), "color:a", 0.0, 0.15)
	await t.finished
	closed.emit()
	queue_free()
