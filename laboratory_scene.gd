extends Control

const SC_MAIN := "res://main_menu.tscn"
const TOTAL_COMPOUNDS := 29  # 13 tier-1 + 12 tier-2 + 4 tier-3

var _slot_a: String = ""
var _slot_b: String = ""

var _slot_a_panel: Panel       = null
var _slot_b_panel: Panel       = null
var _slot_a_lbl:   Label       = null
var _slot_b_lbl:   Label       = null
var _mix_btn:      Button      = null
var _result_panel: Panel       = null

@onready var _elem_grid:    GridContainer = $LeftPanel/ElemScroll/ElemGrid
@onready var _back_btn:     Panel        = $TopBar/BackBtn
@onready var _right_panel:  Panel        = $RightPanel
@onready var _fade:         ColorRect    = $FadeOverlay

# ── Ready ─────────────────────────────────────────────────────────
func _ready() -> void:
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

	_result_panel = _right_panel

	_add_stars()
	_build_center_panel()
	_populate_elements()
	_show_placeholder()
	_refresh_progress()
	create_tween().tween_property(_fade, "color:a", 0.0, 0.30)

# ── Top bar ───────────────────────────────────────────────────────
func _populate_elements() -> void:
	if not _elem_grid: return
	for ch in _elem_grid.get_children(): ch.queue_free()
	# Only show unlocked elements — hide the locked (X) tiles entirely
	for elem in ReactionDB.ELEMENTS:
		if not elem.get("unlocked", false):
			continue
		_elem_grid.add_child(_make_element_tile(elem))

func _make_element_tile(elem: Dictionary) -> Panel:
	const TW := 46.0; const TH := 54.0
	var is_unlocked: bool = elem.get("unlocked", false)
	var col: Color = elem.get("color", Color(0.5, 0.5, 0.5))

	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(TW, TH)
	if is_unlocked:
		tile.add_theme_stylebox_override("panel",
			_sb(col.darkened(0.62), col * Color(1, 1, 1, 0.45), 8, 1))
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		var sym_str: String = str(elem.get("symbol", ""))
		tile.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_element_clicked(sym_str))
	else:
		tile.add_theme_stylebox_override("panel",
			_sb(Color(0.1, 0.1, 0.15, 0.6), Color(0.3, 0.3, 0.4, 0.18), 8, 1))
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sym_lbl := Label.new()
	sym_lbl.text = str(elem.get("symbol", ""))
	sym_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sym_lbl.offset_top = 5; sym_lbl.offset_bottom = 33
	sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	sym_lbl.add_theme_font_size_override("font_size", 15)
	sym_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9 if is_unlocked else 0.25))
	sym_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(sym_lbl)

	var name_lbl := Label.new()
	name_lbl.text = str(elem.get("name", "")).left(4)
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -17; name_lbl.offset_bottom = -2
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 7)
	name_lbl.add_theme_color_override("font_color",
		Color(0.7, 0.88, 1, 0.55 if is_unlocked else 0.15))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(name_lbl)

	if not is_unlocked:
		var lock := TextureRect.new()
		lock.texture      = preload("res://image/lock_chain_x.png")
		lock.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.size         = Vector2(32, 32)
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.offset_left = -16; lock.offset_right = 16; lock.offset_top = -16; lock.offset_bottom = 16
		lock.modulate     = Color(1, 1, 1, 0.85)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lock)

	# Frame on top of all content
	var ftex := TextureRect.new()
	ftex.texture      = preload("res://image/g1.jpg")
	ftex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	ftex.stretch_mode = TextureRect.STRETCH_SCALE
	ftex.size         = Vector2(TW + 4, TH + 4)
	ftex.position     = Vector2(-2, -2)
	ftex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fmat := CanvasItemMaterial.new()
	fmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ftex.material = fmat
	tile.add_child(ftex)

	return tile

# ── Slot logic ────────────────────────────────────────────────────
func _on_element_clicked(symbol: String) -> void:
	if _slot_a == "":
		_slot_a = symbol
	elif _slot_b == "":
		_slot_b = symbol
	else:
		# Both full — shift: old B becomes A, new symbol goes to B
		_slot_a = _slot_b
		_slot_b = symbol
	_update_slots()

func _update_slots() -> void:
	_refresh_slot(_slot_a_panel, _slot_a_lbl, _slot_a)
	_refresh_slot(_slot_b_panel, _slot_b_lbl, _slot_b)
	if _mix_btn:
		_mix_btn.disabled = (_slot_a == "" or _slot_b == "")

func _refresh_slot(panel: Panel, lbl: Label, symbol: String) -> void:
	if not panel or not lbl: return
	if symbol == "":
		lbl.text = "?"
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.18))
		panel.add_theme_stylebox_override("panel",
			_sb(Color(0.05, 0.08, 0.18, 0.6), Color(0.3, 0.5, 1, 0.2), 10, 1))
	else:
		lbl.text = symbol
		var elem := _get_elem(symbol)
		var col: Color = elem.get("color", Color(0.5, 0.7, 1)) if not elem.is_empty() else Color(0.5, 0.7, 1)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		panel.add_theme_stylebox_override("panel",
			_sb(col.darkened(0.52), col * Color(1, 1, 1, 0.55), 10, 2))

func _get_elem(symbol: String) -> Dictionary:
	for e in ReactionDB.ELEMENTS:
		if e.get("symbol", "") == symbol:
			return e
	return {}

# ── Center panel — reaction chamber ──────────────────────────────
func _build_center_panel() -> void:
	const CX    := 240.0
	const CY    := 52.0
	const CW    := 380.0
	const SW    := 110.0   # card width
	const SH    := 154.0   # card height (portrait 5:7 ratio)
	const GAP   := 28.0
	const SLOT_A_X := CX + (CW - SW * 2.0 - GAP) * 0.5
	const SLOT_B_X := SLOT_A_X + SW + GAP
	const SLOTS_Y  := CY + 56.0

	_slot_a_panel = _make_slot_panel(SW, SH)
	_slot_a_panel.position = Vector2(SLOT_A_X, SLOTS_Y)
	_slot_a_lbl = _slot_a_panel.get_child(0) as Label
	_slot_a_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_slot_a = ""; _update_slots())
	add_child(_slot_a_panel)

	var plus := Label.new()
	plus.text = "+"
	plus.position = Vector2(SLOT_A_X + SW + 2, SLOTS_Y + SH * 0.5 - 14)
	plus.size = Vector2(GAP, 28)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.add_theme_font_size_override("font_size", 20)
	plus.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 0.45))
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plus)

	_slot_b_panel = _make_slot_panel(SW, SH)
	_slot_b_panel.position = Vector2(SLOT_B_X, SLOTS_Y)
	_slot_b_lbl = _slot_b_panel.get_child(0) as Label
	_slot_b_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_slot_b = ""; _update_slots())
	add_child(_slot_b_panel)

	var arrow := Label.new()
	arrow.text = "↓"
	arrow.position = Vector2(CX + CW * 0.5 - 12, SLOTS_Y + SH + 6)
	arrow.size = Vector2(24, 22)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 18)
	arrow.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 0.30))
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arrow)

	_mix_btn = Button.new()
	_mix_btn.text = "Mix"
	_mix_btn.position = Vector2(CX + (CW - 140) * 0.5, SLOTS_Y + SH + 34)
	_mix_btn.size = Vector2(140, 44)
	_mix_btn.disabled = true
	_mix_btn.add_theme_font_size_override("font_size", 15)
	_mix_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_mix_btn.add_theme_stylebox_override("normal",
		_sb(Color(0.10, 0.28, 0.70, 1.0), Color(0.40, 0.68, 1, 0.45), 10, 1))
	_mix_btn.add_theme_stylebox_override("hover",
		_sb(Color(0.15, 0.38, 0.85, 1.0), Color(0.55, 0.80, 1, 0.65), 10, 1))
	_mix_btn.add_theme_stylebox_override("pressed",
		_sb(Color(0.10, 0.28, 0.70, 1.0), Color(0.40, 0.68, 1, 0.45), 10, 1))
	_mix_btn.add_theme_stylebox_override("focus", StyleBoxFlat.new())
	_mix_btn.add_theme_stylebox_override("disabled",
		_sb(Color(0.08, 0.10, 0.20, 0.45), Color(0.25, 0.35, 0.55, 0.18), 10, 1))
	_mix_btn.pressed.connect(_do_mix)
	add_child(_mix_btn)

	var hint := Label.new()
	hint.text = "คลิก Element เพื่อใส่สล็อต • คลิกสล็อตเพื่อล้าง"
	hint.position = Vector2(CX, SLOTS_Y + SH + 86)
	hint.size = Vector2(CW, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.18))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

func _make_slot_panel(sw: float = 110.0, sh: float = 154.0, bg := Color(0.05, 0.08, 0.18, 0.6), border := Color(0.3, 0.5, 1, 0.2)) -> Panel:
	var panel := Panel.new()
	panel.size = Vector2(sw, sh)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _sb(bg, border, 10, 1))

	var lbl := Label.new()
	lbl.text = "?"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.18))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)

	# Frame on top of all content
	var sftex := TextureRect.new()
	sftex.texture      = preload("res://image/g1.jpg")
	sftex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	sftex.stretch_mode = TextureRect.STRETCH_SCALE
	sftex.size         = Vector2(sw + 4, sh + 4)
	sftex.position     = Vector2(-2, -2)
	sftex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sfmat := CanvasItemMaterial.new()
	sfmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sftex.material = sfmat
	panel.add_child(sftex)
	return panel

func _show_placeholder() -> void:
	if not _result_panel: return
	for ch in _result_panel.get_children(): ch.queue_free()
	const W := 512.0

	var hint := Label.new()
	hint.text = "เลือก 2 ธาตุแล้วกด Mix\nเพื่อดูผลลัพธ์"
	hint.position = Vector2(0, 230)
	hint.size = Vector2(W, 50)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.18))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(hint)

# ── Mix logic ─────────────────────────────────────────────────────
func _do_mix() -> void:
	if _slot_a == "" or _slot_b == "": return

	var key := ReactionDB.get_reaction(_slot_a, _slot_b)

	if key == "":
		_show_unknown()
		return

	var compound := ReactionDB.get_compound(key)
	if compound.is_empty():
		_show_unknown()
		return

	var is_new: bool = key not in PlayerData.discovered_compounds
	if is_new:
		PlayerData.discover_compound(key)
		# บันทึก recipe "A+B" และ element ที่ใช้ผสม
		var recipe_key := "%s+%s" % [_slot_a, _slot_b]
		PlayerData.discover_recipe(recipe_key)
		PlayerData.discover_element(_slot_a)
		PlayerData.discover_element(_slot_b)
		_show_new_discovery(compound)
		_refresh_progress()
	else:
		_show_known(compound)

func _show_unknown() -> void:
	if not _result_panel: return
	for ch in _result_panel.get_children(): ch.queue_free()
	const W := 512.0

	var q := Label.new()
	q.text = "?"
	q.position = Vector2(0, 60)
	q.size = Vector2(W, 80)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.add_theme_font_size_override("font_size", 60)
	q.add_theme_color_override("font_color", Color(0.85, 0.40, 0.15, 0.65))
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(q)

	var t := Label.new()
	t.text = "Unknown Reaction"
	t.position = Vector2(0, 148)
	t.size = Vector2(W, 28)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 18)
	t.add_theme_color_override("font_color", Color(0.95, 0.52, 0.20, 0.9))
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(t)

	var s := Label.new()
	s.text = _slot_a + " + " + _slot_b + " → ไม่พบปฏิกิริยา"
	s.position = Vector2(0, 184)
	s.size = Vector2(W, 24)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 12)
	s.add_theme_color_override("font_color", Color(1, 1, 1, 0.28))
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(s)

func _show_new_discovery(compound: Dictionary) -> void:
	if not _result_panel: return
	for ch in _result_panel.get_children(): ch.queue_free()
	const W := 512.0

	var banner_bg := ColorRect.new()
	banner_bg.color = Color(0.12, 0.48, 0.28, 0.18)
	banner_bg.position = Vector2.ZERO
	banner_bg.size = Vector2(W, 52)
	banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(banner_bg)

	var banner := Label.new()
	banner.text = "✦  NEW DISCOVERY!  ✦"
	banner.position = Vector2(0, 12)
	banner.size = Vector2(W, 28)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 16)
	banner.add_theme_color_override("font_color", Color(0.25, 1.0, 0.55, 1.0))
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(banner)

	_build_compound_info(compound, true)

func _show_known(compound: Dictionary) -> void:
	if not _result_panel: return
	for ch in _result_panel.get_children(): ch.queue_free()
	const W := 512.0

	var banner_bg := ColorRect.new()
	banner_bg.color = Color(0.08, 0.18, 0.38, 0.18)
	banner_bg.position = Vector2.ZERO
	banner_bg.size = Vector2(W, 52)
	banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(banner_bg)

	var banner := Label.new()
	banner.text = "Known Compound"
	banner.position = Vector2(0, 12)
	banner.size = Vector2(W, 28)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 15)
	banner.add_theme_color_override("font_color", Color(0.50, 0.78, 1, 0.85))
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(banner)

	_build_compound_info(compound, false)

func _build_compound_info(compound: Dictionary, is_new: bool) -> void:
	const W := 512.0
	var y := 62.0

	# ── Tier badge ────────────────────────────────────────────────────
	var tier: int = compound.get("tier", 1)
	var t_col: Color
	var t_label: String
	match tier:
		1: t_col = Color(0.55, 0.78, 0.55); t_label = "Basic"
		2: t_col = Color(0.45, 0.70, 1.00); t_label = "Advanced"
		_: t_col = Color(1.00, 0.72, 0.20); t_label = "Master"

	var tier_bg := ColorRect.new()
	tier_bg.color = Color(t_col.r * 0.15, t_col.g * 0.15, t_col.b * 0.15, 0.80)
	tier_bg.position = Vector2((W - 180) * 0.5, y)
	tier_bg.size = Vector2(180, 30)
	tier_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(tier_bg)

	var tier_lbl := Label.new()
	tier_lbl.text = "TIER %d  —  %s" % [tier, t_label]
	tier_lbl.position = Vector2((W - 180) * 0.5, y + 2)
	tier_lbl.size = Vector2(180, 26)
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_lbl.add_theme_font_size_override("font_size", 13)
	tier_lbl.add_theme_color_override("font_color", Color(t_col.r, t_col.g, t_col.b, 1.0))
	tier_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(tier_lbl)
	y += 38.0

	# ── Formula + Name ────────────────────────────────────────────────
	var formula_lbl := Label.new()
	formula_lbl.text = str(compound.get("formula", ""))
	formula_lbl.position = Vector2(0, y)
	formula_lbl.size = Vector2(W, 52)
	formula_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula_lbl.add_theme_font_size_override("font_size", 40)
	formula_lbl.add_theme_color_override("font_color",
		Color(0.28, 1.0, 0.58) if is_new else Color(t_col.r, t_col.g, t_col.b, 0.95))
	formula_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(formula_lbl)
	y += 56.0

	var name_lbl := Label.new()
	name_lbl.text = str(compound.get("name", ""))
	name_lbl.position = Vector2(0, y)
	name_lbl.size = Vector2(W, 24)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(name_lbl)
	y += 30.0

	var hdiv := ColorRect.new()
	hdiv.color = Color(t_col.r * 0.5, t_col.g * 0.5, t_col.b * 0.5, 0.22)
	hdiv.position = Vector2(24, y)
	hdiv.size = Vector2(W - 48, 1)
	hdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(hdiv)
	y += 10.0

	# ── ข้อมูลธาตุที่ใช้ ──────────────────────────────────────────────
	var elem_a := _get_elem(_slot_a)
	var elem_b := _get_elem(_slot_b)
	var elem_row := Label.new()
	elem_row.text = "ธาตุที่ใช้:  %s (%s)  +  %s (%s)" % [
		str(elem_a.get("name", _slot_a)), _slot_a,
		str(elem_b.get("name", _slot_b)), _slot_b
	]
	elem_row.position = Vector2(20, y)
	elem_row.size = Vector2(W - 40, 18)
	elem_row.add_theme_font_size_override("font_size", 10)
	elem_row.add_theme_color_override("font_color", Color(0.65, 0.82, 1, 0.55))
	elem_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(elem_row)
	y += 22.0

	# brief desc of each element
	for elem in [elem_a, elem_b]:
		if elem.is_empty(): continue
		var e_lbl := Label.new()
		e_lbl.text = "• %s: %s" % [str(elem.get("name", "")), str(elem.get("desc", ""))]
		e_lbl.position = Vector2(20, y)
		e_lbl.custom_minimum_size = Vector2(W - 40, 0)
		e_lbl.size = Vector2(W - 40, 28)
		e_lbl.add_theme_font_size_override("font_size", 10)
		e_lbl.add_theme_color_override("font_color", Color(0.70, 0.85, 1, 0.60))
		e_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_result_panel.add_child(e_lbl)
		y += 32.0

	var hdiv2 := ColorRect.new()
	hdiv2.color = Color(t_col.r * 0.4, t_col.g * 0.4, t_col.b * 0.4, 0.18)
	hdiv2.position = Vector2(24, y)
	hdiv2.size = Vector2(W - 48, 1)
	hdiv2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(hdiv2)
	y += 8.0

	# ── ข้อมูลสารประกอบ ───────────────────────────────────────────────
	var desc := Label.new()
	desc.text = str(compound.get("description", ""))
	desc.position = Vector2(20, y)
	desc.custom_minimum_size = Vector2(W - 40, 0)
	desc.size = Vector2(W - 40, 48)
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.88, 0.93, 1, 0.82))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(desc)
	y += 52.0

	for pair in [["ประเภท", "type"], ["สถานะ", "state"]]:
		var row := Label.new()
		row.text = "%s:  %s" % [pair[0], str(compound.get(pair[1], ""))]
		row.position = Vector2(20, y)
		row.size = Vector2(W - 40, 16)
		row.add_theme_font_size_override("font_size", 10)
		row.add_theme_color_override("font_color", Color(0.55, 0.75, 1, 0.55))
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_result_panel.add_child(row)
		y += 18.0

	y += 4.0
	var use := Label.new()
	use.text = "การใช้งาน: " + str(compound.get("real_use", ""))
	use.position = Vector2(20, y)
	use.custom_minimum_size = Vector2(W - 40, 0)
	use.size = Vector2(W - 40, 32)
	use.add_theme_font_size_override("font_size", 10)
	use.add_theme_color_override("font_color", Color(0.55, 0.85, 0.65, 0.8))
	use.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	use.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(use)
	y += 36.0

	if is_new:
		var reward_bg := ColorRect.new()
		reward_bg.color = Color(0.12, 0.32, 0.18, 0.22)
		reward_bg.position = Vector2(16, y)
		reward_bg.size = Vector2(W - 32, 56)
		reward_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_result_panel.add_child(reward_bg)

		var r_hdr := Label.new()
		r_hdr.text = "รางวัลการค้นพบครั้งแรก"
		r_hdr.position = Vector2(24, y + 6)
		r_hdr.size = Vector2(W - 48, 16)
		r_hdr.add_theme_font_size_override("font_size", 10)
		r_hdr.add_theme_color_override("font_color", Color(0.45, 0.92, 0.60, 0.72))
		r_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_result_panel.add_child(r_hdr)

		var r_vals := Label.new()
		var safe_tier := clampi(tier, 1, 3)
		var exp_r: int  = ([50, 150, 300] as Array[int])[safe_tier - 1]
		var gold_r: int = ([1000, 5000, 10000] as Array[int])[safe_tier - 1]
		var cry_r: int  = ([10,  20,  80] as Array[int])[safe_tier - 1]
		r_vals.text = "+%d EXP   +%d Aether Credit   +%d Crystal" % [exp_r, gold_r, cry_r]
		r_vals.position = Vector2(24, y + 26)
		r_vals.size = Vector2(W - 48, 22)
		r_vals.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		r_vals.add_theme_font_size_override("font_size", 13)
		r_vals.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35, 0.95))
		r_vals.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_result_panel.add_child(r_vals)

func _refresh_progress() -> void:
	pass

# ── Archive modal ─────────────────────────────────────────────────
func _open_archive() -> void:
	const PW := 700.0; const PH := 540.0
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 20
	add_child(dim)

	var panel := Panel.new()
	panel.size = Vector2(PW, PH)
	panel.position = Vector2((1152 - PW) * 0.5, (648 - PH) * 0.5)
	panel.add_theme_stylebox_override("panel",
		_sb(Color(0.03, 0.06, 0.14, 0.98), Color(0.32, 0.50, 1, 0.25), 16, 1))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.add_child(panel)

	var title := Label.new()
	title.text = "📚  Archive"
	title.position = Vector2(20, 16)
	title.size = Vector2(PW - 80, 26)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.78, 0.62, 1, 0.92))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)

	var close := Button.new()
	close.text = "✕"
	close.position = Vector2(PW - 44, 12)
	close.size = Vector2(32, 32)
	close.add_theme_font_size_override("font_size", 14)
	close.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	close.add_theme_stylebox_override("normal",  _sb(Color(0,0,0,0), Color(0,0,0,0), 6, 0))
	close.add_theme_stylebox_override("hover",   _sb(Color(1,1,1,0.10), Color(0,0,0,0), 6, 0))
	close.add_theme_stylebox_override("pressed", _sb(Color(0,0,0,0), Color(0,0,0,0), 6, 0))
	close.add_theme_stylebox_override("focus",   StyleBoxFlat.new())
	close.pressed.connect(func(): dim.queue_free())
	panel.add_child(close)

	var divider := ColorRect.new()
	divider.color = Color(0.3, 0.5, 1, 0.14)
	divider.position = Vector2(16, 48)
	divider.size = Vector2(PW - 32, 1)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(divider)

	var count := PlayerData.discovered_compounds.size()
	var pct := int(float(count) / float(TOTAL_COMPOUNDS) * 100.0)
	var prog_lbl := Label.new()
	prog_lbl.text = "ค้นพบ %d / %d สาร  (%d%%)" % [count, TOTAL_COMPOUNDS, pct]
	prog_lbl.position = Vector2(20, 54)
	prog_lbl.size = Vector2(PW - 40, 18)
	prog_lbl.add_theme_font_size_override("font_size", 11)
	prog_lbl.add_theme_color_override("font_color", Color(0.65, 0.82, 1, 0.55))
	prog_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(prog_lbl)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12, 78)
	scroll.size = Vector2(PW - 24, PH - 92)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	var discovered := PlayerData.discovered_compounds
	for key in ReactionDB.COMPOUNDS.keys():
		var compound := ReactionDB.get_compound(key)
		grid.add_child(_make_archive_card(compound, key in discovered))

	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed: dim.queue_free())

func _make_archive_card(compound: Dictionary, is_found: bool) -> Panel:
	const CW := 208.0; const CH := 82.0
	var card := Panel.new()
	card.custom_minimum_size = Vector2(CW, CH)
	if is_found:
		card.add_theme_stylebox_override("panel",
			_sb(Color(0.05, 0.10, 0.22, 0.92), Color(0.35, 0.60, 1, 0.22), 10, 1))
	else:
		card.add_theme_stylebox_override("panel",
			_sb(Color(0.04, 0.06, 0.12, 0.72), Color(0.20, 0.28, 0.48, 0.10), 10, 1))

	if is_found:
		var fml := Label.new()
		fml.text = str(compound.get("formula", ""))
		fml.position = Vector2(10, 6)
		fml.size = Vector2(CW - 20, 28)
		fml.add_theme_font_size_override("font_size", 20)
		fml.add_theme_color_override("font_color", Color(0.48, 0.84, 1, 0.92))
		fml.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(fml)

		var nm := Label.new()
		nm.text = str(compound.get("name", ""))
		nm.position = Vector2(10, 36)
		nm.size = Vector2(CW - 20, 18)
		nm.add_theme_font_size_override("font_size", 12)
		nm.add_theme_color_override("font_color", Color(0.88, 0.93, 1, 0.82))
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)

		var tp := Label.new()
		tp.text = str(compound.get("type", ""))
		tp.position = Vector2(10, 58)
		tp.size = Vector2(CW - 20, 16)
		tp.add_theme_font_size_override("font_size", 9)
		tp.add_theme_color_override("font_color", Color(0.55, 0.75, 1, 0.48))
		tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(tp)
	else:
		var unk := Label.new()
		unk.text = "???"
		unk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		unk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unk.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		unk.add_theme_font_size_override("font_size", 18)
		unk.add_theme_color_override("font_color", Color(1, 1, 1, 0.08))
		unk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(unk)

	return card

# ── Helpers ───────────────────────────────────────────────────────
func _add_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7337
	for i in 70:
		var dot := ColorRect.new()
		var sz := rng.randf_range(1.0, 2.5)
		dot.size = Vector2(sz, sz)
		dot.position = Vector2(rng.randf_range(0, 1152), rng.randf_range(0, 648))
		dot.color = Color(1, 1, 1, rng.randf_range(0.06, 0.32))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)

func _sb(bg: Color, bdr: Color, radius: int, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = bdr
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_border_width(side, bw)
	for r in ["corner_radius_top_left","corner_radius_top_right",
			  "corner_radius_bottom_right","corner_radius_bottom_left"]:
		s.set(r, radius)
	return s

func _make_back_btn(pos: Vector2, sz: Vector2, callback: Callable) -> Control:
	var btn := Panel.new()
	btn.position = pos
	btn.z_index = 20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.05, 0.15, 0.55)
	sb.border_color = Color(0.45, 0.72, 1.0, 0.90)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(22)
	btn.add_theme_stylebox_override("panel", sb)
	btn.size        = Vector2(42, 45)
	btn.pivot_offset = Vector2(21, 22)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon := TextureRect.new()
	icon.texture      = preload("res://image/back.png")
	icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)
	btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(btn, "scale", Vector2(0.78, 0.78), 0.08)
			tw.tween_property(btn, "scale", Vector2(1.0,  1.0),  0.22)
			tw.tween_callback(callback)
	)
	btn.mouse_entered.connect(func():
		var tw := btn.create_tween().set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween().set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)
	return btn

func _go_back() -> void:
	SceneTransition.fade_to(SC_MAIN)
