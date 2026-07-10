extends Control

const SC_MAIN   := "res://main_menu.tscn"
const SC_DETAIL := "res://character_scene.tscn"

# ── Layout ────────────────────────────────────────────────────
const COLS    := 6
const ROWS    := 2
const CARD_W  := 162.0
const CARD_H  := 234.0
const GAP_X   := 10.0
const GAP_Y   := 10.0
const TOP_H   := 52.0
const BOT_H   := 54.0
const VW      := 1152.0
const VH      := 648.0

# ── Colors ────────────────────────────────────────────────────
const C_BG    := Color(0.030, 0.032, 0.068, 1.0)
const C_BAR   := Color(0.020, 0.024, 0.052, 1.0)
const C_EMPTY := Color(0.040, 0.045, 0.080, 0.90)
const C_TEXT  := Color(0.92,  0.94,  1.00,  1.0)
const C_DIM   := Color(0.45,  0.55,  0.72,  0.65)
const C_LINE  := Color(1.0,   1.0,   1.0,   0.06)

# ── Portrait map ──────────────────────────────────────────────
const PORTRAITS := {
	"Alchemist": "res://image/lyra_1.png",
	"Lyra":      "res://image/lyra_2.png",
	"Seraph":    "res://image/lyra_3.png",
}

const SQUAD_LABELS  := ["1st Squad", "2nd Squad", "3rd Squad", "4th Squad"]
const NUM_SQUADS    := 4
const TOTAL_SLOTS   := COLS * ROWS  # 12

# _squads[squad_idx] = Array of TOTAL_SLOTS (Dictionary or null)
var _squads: Array = []
var _cur_squad: int = 0

var _grid_panels: Array  = []
var _tab_btns: Array[Button] = []
@onready var _fade: ColorRect = $FadeOverlay

func _ready() -> void:
	# Init squad data
	for _i in NUM_SQUADS:
		var row: Array = []
		for _j in TOTAL_SLOTS:
			row.append(null)
		_squads.append(row)

	# Pre-fill squad 0 with owned characters
	var owned := CharacterManager.get_roster().filter(func(c): return c["owned"])
	for i in mini(owned.size(), TOTAL_SLOTS):
		_squads[0][i] = owned[i]

	_build_ui()

	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.28)

# ── UI build ──────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_top_bar()
	_build_grid()
	_build_bottom_bar()
	_refresh_squad()

func _build_top_bar() -> void:
	add_child(_crect(Vector2(0, 0), Vector2(VW, TOP_H), C_BAR))
	add_child(_crect(Vector2(0, TOP_H), Vector2(VW, 1), C_LINE))

	# Back button
	var back := _icon_btn(Vector2(10, 10), Vector2(32, 32), "‹")
	back.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			SceneTransition.fade_to(SC_MAIN)
	)
	add_child(back)

	# Title
	var title := _lbl("Squad Formation", 16, C_TEXT)
	title.position = Vector2(54, 0)
	title.size = Vector2(260, TOP_H)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	# Quick Select button
	var qs := _action_btn("  Quick Select", Color(0.35, 0.65, 1.0), Vector2(140, 32))
	qs.position = Vector2(970, 10)
	add_child(qs)

	# Clear (✕) button
	var clr := _icon_btn(Vector2(1122, 10), Vector2(32, 32), "✕")
	clr.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			for i in TOTAL_SLOTS: _squads[_cur_squad][i] = null
			_refresh_squad()
	)
	add_child(clr)

func _build_grid() -> void:
	var area_h := VH - TOP_H - BOT_H
	var grid_w := COLS * CARD_W + (COLS - 1) * GAP_X
	var grid_h := ROWS * CARD_H + (ROWS - 1) * GAP_Y
	var ox     := (VW - grid_w) / 2.0
	var oy     := TOP_H + (area_h - grid_h) / 2.0

	_grid_panels = []
	for row in ROWS:
		for col in COLS:
			var px := ox + col * (CARD_W + GAP_X)
			var py := oy + row * (CARD_H + GAP_Y)
			var slot := Panel.new()
			slot.size     = Vector2(CARD_W, CARD_H)
			slot.position = Vector2(px, py)
			slot.clip_contents = true
			slot.mouse_filter = Control.MOUSE_FILTER_STOP
			_grid_panels.append(slot)
			add_child(slot)

func _build_bottom_bar() -> void:
	add_child(_crect(Vector2(0, VH - BOT_H - 1), Vector2(VW, 1), C_LINE))
	add_child(_crect(Vector2(0, VH - BOT_H), Vector2(VW, BOT_H), C_BAR))

	var tab_w := 160.0
	_tab_btns = []
	for i in NUM_SQUADS:
		var btn := Button.new()
		btn.text     = SQUAD_LABELS[i]
		btn.size     = Vector2(tab_w, BOT_H)
		btn.position = Vector2(i * tab_w, VH - BOT_H)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 13)
		var blank := _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0)
		for s in ["normal", "hover", "pressed"]:
			btn.add_theme_stylebox_override(s, blank)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(_switch_squad.bind(i))
		_tab_btns.append(btn)
		add_child(btn)

	# Mission Start button
	var ms_w := 180.0
	var ms := Button.new()
	ms.text     = "MISSION START"
	ms.size     = Vector2(ms_w, BOT_H)
	ms.position = Vector2(VW - ms_w, VH - BOT_H)
	ms.focus_mode = Control.FOCUS_NONE
	ms.add_theme_font_size_override("font_size", 13)
	ms.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88, 1.0))
	var ms_sb := _flat(Color(0.78, 0.22, 0.06, 1.0), Color(0, 0, 0, 0), 0, 0)
	for s in ["normal", "hover", "pressed", "focus"]:
		ms.add_theme_stylebox_override(s, ms_sb)
	add_child(ms)

# ── Grid refresh ──────────────────────────────────────────────

func _refresh_squad() -> void:
	var squad := _squads[_cur_squad] as Array
	for i in _grid_panels.size():
		var slot := _grid_panels[i] as Panel
		for c in slot.get_children(): c.queue_free()
		var data: Variant = squad[i] if i < squad.size() else null
		if data != null:
			_fill_character(slot, data as Dictionary)
		else:
			_fill_empty(slot)
	_update_tab_style()

func _fill_character(slot: Panel, data: Dictionary) -> void:
	var rarity: int    = int(data.get("rarity", 3))
	var name_s: String = str(data.get("name", ""))
	var elem_s: String = str(data.get("element", ""))
	var elem_col: Color = data.get("element_color", Color(0.4, 0.4, 0.6)) as Color

	var r_col: Color
	match rarity:
		5: r_col = Color(1.00, 0.80, 0.20)
		4: r_col = Color(0.72, 0.50, 1.00)
		_: r_col = Color(0.35, 0.65, 1.00)

	# Card background
	slot.add_theme_stylebox_override("panel",
		_flat(Color(elem_col.r * 0.10, elem_col.g * 0.10, elem_col.b * 0.18, 1.0),
			Color(r_col.r, r_col.g, r_col.b, 0.40), 8, 1))

	# Portrait image
	var portrait_h := CARD_H - 46.0
	var ppath: String = PORTRAITS.get(name_s, "")
	if ppath != "" and ResourceLoader.exists(ppath):
		var tex: Texture2D = load(ppath)
		if tex:
			var img := TextureRect.new()
			img.texture      = tex
			img.size         = Vector2(CARD_W, portrait_h + 12)
			img.position     = Vector2(0, 0)
			img.expand_mode  = TextureRect.EXPAND_IGNORE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(img)
	else:
		slot.add_child(_crect(Vector2(0, 0), Vector2(CARD_W, portrait_h),
			Color(elem_col.r * 0.15, elem_col.g * 0.15, elem_col.b * 0.25, 1.0)))
		var el := _lbl(elem_s, 48, Color(1, 1, 1, 0.85))
		el.size = Vector2(CARD_W, portrait_h)
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		el.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(el)

	# Rarity bar (top)
	slot.add_child(_crect(Vector2(0, 0), Vector2(CARD_W, 3),
		Color(r_col.r, r_col.g, r_col.b, 0.75)))

	# Stars (top-left)
	var stars := _lbl("★".repeat(rarity), 9, Color(r_col.r, r_col.g, r_col.b, 0.90))
	stars.size     = Vector2(CARD_W - 28, 16)
	stars.position = Vector2(4, 5)
	slot.add_child(stars)

	# Element badge (top-right)
	var el_dot := Panel.new()
	el_dot.size     = Vector2(22, 22)
	el_dot.position = Vector2(CARD_W - 25, 3)
	el_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	el_dot.add_theme_stylebox_override("panel",
		_flat(Color(elem_col.r * 0.35, elem_col.g * 0.35, elem_col.b * 0.55, 0.88),
			Color(elem_col.r, elem_col.g, elem_col.b, 0.40), 11, 1))
	slot.add_child(el_dot)
	var el_l := _lbl(elem_s, 11, Color(1, 1, 1, 0.9))
	el_l.size     = Vector2(22, 22)
	el_l.position = Vector2(CARD_W - 25, 3)
	el_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	el_l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(el_l)

	# Bottom dark strip
	slot.add_child(_crect(Vector2(0, CARD_H - 46), Vector2(CARD_W, 46),
		Color(0.01, 0.01, 0.04, 0.82)))

	# Level badge
	var lv_bg := Panel.new()
	lv_bg.size     = Vector2(52, 20)
	lv_bg.position = Vector2(5, CARD_H - 43)
	lv_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv_bg.add_theme_stylebox_override("panel",
		_flat(Color(0, 0, 0, 0.55), Color(1, 1, 1, 0.10), 4, 1))
	slot.add_child(lv_bg)
	var lv := _lbl("Lv 42", 9, Color(0.88, 0.92, 1.0, 0.95))
	lv.size     = Vector2(52, 20)
	lv.position = Vector2(5, CARD_H - 43)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(lv)

	# Name
	var nm := _lbl(name_s, 11, C_TEXT)
	nm.size     = Vector2(CARD_W, 22)
	nm.position = Vector2(0, CARD_H - 24)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(nm)

	slot.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if ResourceLoader.exists(SC_DETAIL):
				SceneTransition.fade_to(SC_DETAIL)
	)

func _fill_empty(slot: Panel) -> void:
	slot.add_theme_stylebox_override("panel",
		_flat(C_EMPTY, Color(1, 1, 1, 0.07), 8, 1))
	var plus := _lbl("+", 36, Color(1, 1, 1, 0.16))
	plus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(plus)

# ── Tab switching ─────────────────────────────────────────────

func _switch_squad(idx: int) -> void:
	_cur_squad = idx
	_refresh_squad()

func _update_tab_style() -> void:
	for i in _tab_btns.size():
		var active := (i == _cur_squad)
		_tab_btns[i].add_theme_color_override("font_color",
			Color(0.45, 0.75, 1.0, 1.0) if active else C_DIM)
		for c in _tab_btns[i].get_children():
			if c is ColorRect: c.queue_free()
		if active:
			var line := _crect(Vector2(0, 0), Vector2(160, 2), Color(0.45, 0.75, 1.0, 0.80))
			_tab_btns[i].add_child(line)

# ── Helpers ───────────────────────────────────────────────────

func _flat(col: Color, border: Color = Color(0,0,0,0), r: int = 8, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color    = col
	sb.border_color = border
	sb.corner_radius_top_left     = r; sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_right = r; sb.corner_radius_bottom_left  = r
	sb.border_width_left = bw; sb.border_width_right  = bw
	sb.border_width_top  = bw; sb.border_width_bottom = bw
	return sb

func _crect(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var cr := ColorRect.new()
	cr.position = pos; cr.size = sz; cr.color = col
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cr

func _lbl(text: String, font_sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_sz)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _icon_btn(pos: Vector2, sz: Vector2, icon: String) -> Panel:
	var btn := Panel.new()
	btn.position = pos; btn.size = sz
	btn.pivot_offset = sz / 2.0
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_stylebox_override("panel",
		_flat(Color(0, 0, 0, 0), Color(0.35, 0.55, 1.0, 0.30), 20, 1))
	var l := _lbl(icon, 16, Color(0.80, 0.90, 1.0, 0.90))
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	btn.add_child(l)
	return btn

func _action_btn(text: String, col: Color, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text; btn.size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", col)
	var sb := _flat(Color(col.r * 0.18, col.g * 0.18, col.b * 0.30, 0.92),
		Color(col.r, col.g, col.b, 0.50), 6, 1)
	for s in ["normal", "hover", "pressed"]:
		btn.add_theme_stylebox_override(s, sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn
