extends Control

const SC_MAIN   := "res://main_menu.tscn"
const SC_DETAIL := "res://character_scene.tscn"

# ── Layout ────────────────────────────────────────────────────
const COLS   := 6
const ROWS   := 2
const CARD_W := 162.0
const CARD_H := 234.0
const GAP_X  := 10.0
const GAP_Y  := 10.0
const TOP_H  := 52.0
const VW     := 1152.0
const VH     := 648.0

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

var _grid_panels: Array = []
@onready var _fade: ColorRect = $FadeOverlay

func _ready() -> void:
	_build_ui()
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.28)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_top_bar()
	_build_grid()
	_fill_grid()

func _build_top_bar() -> void:
	add_child(_crect(Vector2(0, 0), Vector2(VW, TOP_H), C_BAR))
	add_child(_crect(Vector2(0, TOP_H), Vector2(VW, 1), C_LINE))

	var back := _icon_btn(Vector2(10, 10), Vector2(32, 32), "‹")
	back.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			SceneTransition.fade_to(SC_MAIN)
	)
	add_child(back)

	var title := _lbl("Characters", 16, C_TEXT)
	title.position = Vector2(54, 0)
	title.size = Vector2(260, TOP_H)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

func _build_grid() -> void:
	var area_h := VH - TOP_H
	var grid_w := COLS * CARD_W + (COLS - 1) * GAP_X
	var grid_h := ROWS * CARD_H + (ROWS - 1) * GAP_Y
	var ox := (VW - grid_w) / 2.0
	var oy := TOP_H + (area_h - grid_h) / 2.0

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

func _fill_grid() -> void:
	var roster := CharacterManager.get_roster()
	for i in _grid_panels.size():
		var slot := _grid_panels[i] as Panel
		if i < roster.size():
			var data := roster[i] as Dictionary
			if bool(data.get("owned", false)):
				_fill_character(slot, data)
			else:
				_fill_locked(slot, data)
		else:
			slot.visible = false

func _fill_character(slot: Panel, data: Dictionary) -> void:
	var rarity: int     = int(data.get("rarity", 3))
	var name_s: String  = str(data.get("name", ""))
	var elem_s: String  = str(data.get("element", ""))
	var elem_col: Color = data.get("element_color", Color(0.4, 0.4, 0.6)) as Color

	var r_col: Color
	match rarity:
		5: r_col = Color(1.00, 0.80, 0.20)
		4: r_col = Color(0.72, 0.50, 1.00)
		_: r_col = Color(0.35, 0.65, 1.00)

	slot.add_theme_stylebox_override("panel",
		_flat(Color(elem_col.r * 0.10, elem_col.g * 0.10, elem_col.b * 0.18, 1.0),
			Color(r_col.r, r_col.g, r_col.b, 0.40), 8, 1))

	var portrait_h := CARD_H - 46.0
	var ppath: String = PORTRAITS.get(name_s, "")
	if ppath != "" and ResourceLoader.exists(ppath):
		var tex: Texture2D = load(ppath)
		if tex:
			var img := TextureRect.new()
			img.texture      = tex
			img.size         = Vector2(CARD_W, portrait_h + 12)
			img.position     = Vector2(0, 0)
			img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
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

	slot.add_child(_crect(Vector2(0, 0), Vector2(CARD_W, 3),
		Color(r_col.r, r_col.g, r_col.b, 0.75)))

	var stars := _lbl("★".repeat(rarity), 9, Color(r_col.r, r_col.g, r_col.b, 0.90))
	stars.size     = Vector2(CARD_W - 28, 16)
	stars.position = Vector2(4, 5)
	slot.add_child(stars)

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

	slot.add_child(_crect(Vector2(0, CARD_H - 46), Vector2(CARD_W, 46),
		Color(0.01, 0.01, 0.04, 0.82)))

	var char_data := CharacterManager.get_character_data(name_s)
	var lv_str := "Lv %d" % int(char_data.get("level", 1)) if not char_data.is_empty() else "Lv 1"
	var lv_bg := Panel.new()
	lv_bg.size     = Vector2(52, 20)
	lv_bg.position = Vector2(5, CARD_H - 43)
	lv_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv_bg.add_theme_stylebox_override("panel",
		_flat(Color(0, 0, 0, 0.55), Color(1, 1, 1, 0.10), 4, 1))
	slot.add_child(lv_bg)
	var lv := _lbl(lv_str, 9, Color(0.88, 0.92, 1.0, 0.95))
	lv.size     = Vector2(52, 20)
	lv.position = Vector2(5, CARD_H - 43)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(lv)

	var nm := _lbl(name_s, 11, C_TEXT)
	nm.size     = Vector2(CARD_W, 22)
	nm.position = Vector2(0, CARD_H - 24)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(nm)

	slot.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			CharacterManager.selected_character = name_s
			if ResourceLoader.exists(SC_DETAIL):
				SceneTransition.fade_to(SC_DETAIL)
	)

func _fill_locked(slot: Panel, data: Dictionary) -> void:
	var rarity: int     = int(data.get("rarity", 3))
	var name_s: String  = str(data.get("name", ""))
	var elem_col: Color = data.get("element_color", Color(0.4, 0.4, 0.6)) as Color

	var r_col: Color
	match rarity:
		5: r_col = Color(1.00, 0.80, 0.20)
		4: r_col = Color(0.72, 0.50, 1.00)
		_: r_col = Color(0.35, 0.65, 1.00)

	slot.add_theme_stylebox_override("panel",
		_flat(Color(elem_col.r * 0.05, elem_col.g * 0.05, elem_col.b * 0.09, 1.0),
			Color(r_col.r * 0.4, r_col.g * 0.4, r_col.b * 0.4, 0.25), 8, 1))

	var portrait_h := CARD_H - 46.0
	var ppath: String = PORTRAITS.get(name_s, "")
	if ppath != "" and ResourceLoader.exists(ppath):
		var tex: Texture2D = load(ppath)
		if tex:
			var img := TextureRect.new()
			img.texture      = tex
			img.size         = Vector2(CARD_W, portrait_h + 12)
			img.position     = Vector2(0, 0)
			img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img.modulate     = Color(0.35, 0.35, 0.40, 0.70)
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(img)

	slot.add_child(_crect(Vector2(0, 0), Vector2(CARD_W, 3),
		Color(r_col.r * 0.35, r_col.g * 0.35, r_col.b * 0.35, 0.40)))
	slot.add_child(_crect(Vector2(0, 0), Vector2(CARD_W, CARD_H),
		Color(0.01, 0.01, 0.05, 0.55)))

	var lock := _lbl("🔒", 28, Color(1, 1, 1, 0.55))
	lock.size     = Vector2(CARD_W, CARD_H - 60)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(lock)

	var gacha_l := _lbl("Gacha", 10, Color(r_col.r, r_col.g, r_col.b, 0.55))
	gacha_l.size     = Vector2(CARD_W, 20)
	gacha_l.position = Vector2(0, CARD_H / 2.0 + 6)
	gacha_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gacha_l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(gacha_l)

	slot.add_child(_crect(Vector2(0, CARD_H - 46), Vector2(CARD_W, 46),
		Color(0.01, 0.01, 0.04, 0.75)))
	var stars := _lbl("★".repeat(rarity), 9, Color(r_col.r * 0.5, r_col.g * 0.5, r_col.b * 0.5, 0.55))
	stars.size     = Vector2(CARD_W - 8, 16)
	stars.position = Vector2(4, CARD_H - 43)
	slot.add_child(stars)
	var nm := _lbl(name_s, 11, Color(0.55, 0.58, 0.65, 0.70))
	nm.size     = Vector2(CARD_W, 22)
	nm.position = Vector2(0, CARD_H - 24)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(nm)

func _fill_empty(slot: Panel) -> void:
	slot.add_theme_stylebox_override("panel",
		_flat(C_EMPTY, Color(1, 1, 1, 0.07), 8, 1))
	var plus := _lbl("+", 36, Color(1, 1, 1, 0.16))
	plus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(plus)

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
