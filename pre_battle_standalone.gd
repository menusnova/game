extends Control

const SC_BATTLE := "res://battle_scene.tscn"
const SW := 1152.0
const SH := 648.0

# ── Enemy data: 2 stages ──
const STAGE_ENEMIES := [
	[
		{"name": "Bone Golem",  "hp": 4200, "weak": ["ไฟ", "กรด"],      "icon": "💀"},
		{"name": "Void Shade",  "hp": 3100, "weak": ["แสง", "ไฟฟ้า"],   "icon": "👁"},
	],
	[
		{"name": "Null Core",   "hp": 8800, "weak": ["น้ำ", "ไฟฟ้า"],   "icon": "☢"},
	],
]

# ── Team slots ──
const MAX_CHARS := 4
const MAX_ELEMS := 3
const MAX_SUPP  := 2

var _selected_chars: Array[String] = ["Lyra", "Kael", "", ""]
var _selected_elems: Array[String] = ["H", "O", ""]
var _selected_supp:  Array[String] = ["Acid Flask", ""]

var _current_stage := 0          # 0 or 1
var _edit_open     := false
var _enemy_expand  := false

# root nodes built in _ready
var _edit_panel:   Control  = null
var _enemy_panel:  Control  = null
var _char_slots:   Array    = []
var _elem_slots:   Array    = []
var _supp_slots:   Array    = []
var _stage_dots:   Array    = []
var _fade:         ColorRect = null

# ── helpers ──
func _sb(col: Color, border: Color = Color(1,1,1,0), radius: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	if border.a > 0:
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			s.set_border_width(side, 1)
		s.border_color = border
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		s.set(r, radius)
	return s

func _lbl(txt: String, sz: int, col: Color, parent: Control, pos: Vector2, size: Vector2 = Vector2.ZERO) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.position = pos
	if size != Vector2.ZERO:
		l.size = size
		l.clip_text = true
	parent.add_child(l)
	return l

func _btn(txt: String, sz: int, txt_col: Color, bg: StyleBoxFlat, parent: Control, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", sz)
	b.add_theme_color_override("font_color", txt_col)
	b.add_theme_stylebox_override("normal", bg)
	b.add_theme_stylebox_override("hover", bg)
	b.add_theme_stylebox_override("pressed", bg)
	b.add_theme_stylebox_override("focus", StyleBoxFlat.new())
	parent.add_child(b)
	return b

# ── _ready ──
func _ready() -> void:
	_build_background()
	_build_char_display()
	_build_enemy_panel()
	_build_bottom_bar()
	_build_edit_panel()
	_build_fade()
	_refresh_enemy_panel()
	_refresh_team_display()

	if _fade:
		var t := create_tween()
		t.tween_property(_fade, "color:a", 0.0, 0.35)

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.14, 1.0)
	add_child(bg)
	# subtle vignette gradient panel
	var vg := Panel.new()
	vg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	vg.add_theme_stylebox_override("panel", sb)
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vg)

# ── character display (center) ──
var _char_display_root: Control = null
func _build_char_display() -> void:
	_char_display_root = Control.new()
	_char_display_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_char_display_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_char_display_root)
	# Will be populated by _refresh_team_display

func _refresh_team_display() -> void:
	for c in _char_display_root.get_children():
		c.queue_free()
	_char_slots.clear()

	var chars: Array = _selected_chars.filter(func(n): return n != "")
	var count := chars.size()
	if count == 0:
		return

	var slot_w := 110.0
	var total_w := count * slot_w + (count - 1) * 16.0
	var start_x := (SW - total_w) / 2.0
	var center_y := SH / 2.0 - 20.0

	for i in range(count):
		var ch: String = chars[i]
		var cx := start_x + i * (slot_w + 16.0)

		var card := Panel.new()
		card.position = Vector2(cx, center_y - 110.0)
		card.size = Vector2(slot_w, 150.0)
		card.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.12, 0.26, 0.7), Color(0.4, 0.6, 1.0, 0.25), 12))
		_char_display_root.add_child(card)

		var icon_lbl := Label.new()
		icon_lbl.text = "🧑" if i % 2 == 0 else "⚔"
		icon_lbl.add_theme_font_size_override("font_size", 48)
		icon_lbl.position = Vector2(0, 12)
		icon_lbl.size = Vector2(slot_w, 70)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(icon_lbl)

		var name_lbl := Label.new()
		name_lbl.text = ch
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.9))
		name_lbl.position = Vector2(4, 90)
		name_lbl.size = Vector2(slot_w - 8, 20)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(name_lbl)

		# element badge
		var elem: String = _selected_elems[0] if _selected_elems.size() > 0 and _selected_elems[0] != "" else ""
		if elem != "" and i == 0:
			var eb := Panel.new()
			eb.position = Vector2(slot_w - 28, 6)
			eb.size = Vector2(24, 18)
			eb.add_theme_stylebox_override("panel", _sb(Color(0.2, 0.6, 1.0, 0.8), Color(0,0,0,0), 4))
			card.add_child(eb)
			var el := Label.new()
			el.text = elem
			el.add_theme_font_size_override("font_size", 9)
			el.add_theme_color_override("font_color", Color.WHITE)
			el.position = Vector2(2, 2)
			el.size = Vector2(20, 14)
			el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			eb.add_child(el)

		_char_slots.append(card)

	# Mission title (bottom center)
	var mission_lbl := _lbl("MISSION 1-1  ·  ห้องปฏิบัติการต้องห้าม",
		12, Color(0.5, 0.7, 1.0, 0.6), _char_display_root,
		Vector2(SW / 2.0 - 200, center_y + 58), Vector2(400, 20))
	mission_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# ── enemy panel (top-right, compact → expandable) ──
func _build_enemy_panel() -> void:
	_enemy_panel = Control.new()
	_enemy_panel.position = Vector2(SW - 280, 10)
	_enemy_panel.size = Vector2(270, 200)
	add_child(_enemy_panel)

func _refresh_enemy_panel() -> void:
	for c in _enemy_panel.get_children():
		c.queue_free()

	var enemies: Array = STAGE_ENEMIES[_current_stage]
	var panel_h := 30.0 + enemies.size() * 72.0 + 12.0

	var bg := Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(270, panel_h)
	bg.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.04, 0.10, 0.88), Color(0.8, 0.3, 0.3, 0.2), 10))
	_enemy_panel.add_child(bg)

	# stage dots
	_stage_dots.clear()
	var dots_row := Control.new()
	dots_row.position = Vector2(8, 8)
	dots_row.size = Vector2(254, 16)
	bg.add_child(dots_row)

	for s in range(STAGE_ENEMIES.size()):
		var dot := Panel.new()
		dot.position = Vector2(s * 20, 2)
		dot.size = Vector2(14, 12)
		var col := Color(1.0, 0.6, 0.3, 0.9) if s == _current_stage else Color(0.4, 0.4, 0.4, 0.5)
		dot.add_theme_stylebox_override("panel", _sb(col, Color(0,0,0,0), 3))
		dots_row.add_child(dot)
		_stage_dots.append(dot)

	var stage_lbl := _lbl("STAGE %d" % (_current_stage + 1) + (" · FINAL" if _current_stage == STAGE_ENEMIES.size() - 1 else ""),
		10, Color(1.0, 0.7, 0.3, 0.8), bg, Vector2(50, 5))

	for i in range(enemies.size()):
		var en: Dictionary = enemies[i]
		var ey := 28.0 + i * 74.0

		var chip := Panel.new()
		chip.position = Vector2(8, ey)
		chip.size = Vector2(254, 64)
		chip.add_theme_stylebox_override("panel", _sb(Color(0.12, 0.04, 0.04, 0.7), Color(0.8, 0.25, 0.25, 0.18), 8))
		bg.add_child(chip)

		_lbl(en["icon"] + " " + en["name"].to_upper(), 12, Color(1.0, 0.65, 0.65, 0.95), chip, Vector2(8, 6))
		_lbl("HP  %d" % en["hp"], 10, Color(0.7, 1.0, 0.7, 0.7), chip, Vector2(8, 24))
		_lbl("อ่อนแอ: " + "  ".join(en["weak"]), 10, Color(0.5, 0.8, 1.0, 0.8), chip, Vector2(8, 42))

		# expand button
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_toggle_enemy_expand())

	# stage toggle row
	var tog_y := 28.0 + enemies.size() * 74.0 + 4.0
	for s in range(STAGE_ENEMIES.size()):
		var tb_lbl := "S%d" % (s+1)
		var tb := _btn(tb_lbl, 10,
			Color(1.0, 0.85, 0.4) if s == _current_stage else Color(0.6, 0.6, 0.6),
			_sb(Color(0.15, 0.1, 0.05, 0.6) if s == _current_stage else Color(0.08, 0.08, 0.08, 0.5),
				Color(1.0,0.6,0.2,0.3) if s == _current_stage else Color(0.3,0.3,0.3,0.3), 4),
			bg, Vector2(8 + s * 42, tog_y), Vector2(36, 20))
		var stage_idx := s
		tb.pressed.connect(func():
			_current_stage = stage_idx
			_refresh_enemy_panel())

	_enemy_panel.size = Vector2(270, panel_h + 28.0)

# ── enemy expand overlay ──
var _expand_overlay: Control = null
func _toggle_enemy_expand() -> void:
	if _expand_overlay and is_instance_valid(_expand_overlay):
		_expand_overlay.queue_free()
		_expand_overlay = null
		return

	_expand_overlay = Control.new()
	_expand_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_expand_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.75)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_toggle_enemy_expand())
	_expand_overlay.add_child(dim)

	var pw := 600.0; var ph := 460.0
	var px := (SW - pw) / 2.0; var py := (SH - ph) / 2.0
	var pop := Panel.new()
	pop.position = Vector2(px, py)
	pop.size = Vector2(pw, ph)
	pop.add_theme_stylebox_override("panel", _sb(Color(0.07, 0.04, 0.12, 0.97), Color(0.8, 0.3, 0.3, 0.3), 14))
	_expand_overlay.add_child(pop)

	_lbl("ข้อมูลศัตรู", 18, Color(1, 0.7, 0.7), pop, Vector2(24, 18))
	var close_b := _btn("✕", 14, Color(1,1,1,0.6), _sb(Color(0,0,0,0)), pop,
		Vector2(pw - 40, 12), Vector2(28, 28))
	close_b.pressed.connect(_toggle_enemy_expand)

	var all_enemies: Array = []
	for stage in STAGE_ENEMIES:
		all_enemies.append_array(stage)

	var ey := 56.0
	for i in range(all_enemies.size()):
		var en: Dictionary = all_enemies[i]
		var stage_of := 0 if i < STAGE_ENEMIES[0].size() else 1

		var chip := Panel.new()
		chip.position = Vector2(20, ey)
		chip.size = Vector2(pw - 40, 82)
		chip.add_theme_stylebox_override("panel", _sb(Color(0.12, 0.04, 0.06, 0.85), Color(0.8,0.25,0.25,0.2), 10))
		pop.add_child(chip)

		_lbl(en["icon"], 32, Color.WHITE, chip, Vector2(12, 12))
		_lbl(en["name"].to_upper(), 14, Color(1.0, 0.7, 0.7), chip, Vector2(58, 10))
		_lbl("Stage %d%s" % [stage_of + 1, " · FINAL" if stage_of == STAGE_ENEMIES.size()-1 else ""],
			10, Color(1.0, 0.75, 0.3, 0.8), chip, Vector2(58, 28))
		_lbl("HP: %d" % en["hp"], 11, Color(0.6, 1.0, 0.6, 0.85), chip, Vector2(58, 46))
		_lbl("อ่อนแอต่อ:  " + "  /  ".join(en["weak"]), 11, Color(0.5, 0.85, 1.0, 0.9), chip, Vector2(200, 46))

		ey += 94.0

# ── bottom bar: edit + start buttons ──
func _build_bottom_bar() -> void:
	var bar := Control.new()
	bar.position = Vector2(0, SH - 64)
	bar.size = Vector2(SW, 64)
	add_child(bar)

	var edit_sb := _sb(Color(0.08, 0.1, 0.2, 0.88), Color(0.4, 0.6, 1.0, 0.3), 10)
	var edit_b := _btn("✏  แก้ทีม", 13, Color(0.7, 0.85, 1.0, 0.9), edit_sb,
		bar, Vector2(SW - 340, 10), Vector2(110, 44))
	edit_b.pressed.connect(_on_edit)

	var start_sb := _sb(Color(0.15, 0.35, 0.85, 1.0), Color(0.5, 0.7, 1.0, 0.3), 12)
	var start_b := _btn("⚔  เริ่มต่อสู้", 15, Color.WHITE, start_sb,
		bar, Vector2(SW - 220, 8), Vector2(210, 48))
	start_b.pressed.connect(_on_start)

# ── edit panel (slides in from left) ──
const EDIT_W := 360.0

func _build_edit_panel() -> void:
	_edit_panel = Control.new()
	_edit_panel.position = Vector2(-EDIT_W, 0)
	_edit_panel.size = Vector2(EDIT_W, SH)
	_edit_panel.visible = false
	add_child(_edit_panel)

	var bg := Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(EDIT_W, SH)
	bg.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.07, 0.16, 0.97), Color(0.3, 0.5, 1.0, 0.2), 0))
	_edit_panel.add_child(bg)

	# ── TOP: character selection ──
	var char_header := Panel.new()
	char_header.position = Vector2(0, 0)
	char_header.size = Vector2(EDIT_W, 32)
	char_header.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.12, 0.28, 1.0)))
	bg.add_child(char_header)
	_lbl("เลือกตัวละคร", 12, Color(0.6, 0.8, 1.0, 0.9), char_header, Vector2(12, 8))

	var char_panel := Control.new()
	char_panel.position = Vector2(8, 36)
	char_panel.size = Vector2(EDIT_W - 16, 220)
	bg.add_child(char_panel)
	_build_char_grid(char_panel)

	# ── BOTTOM: cards ──
	var sep_y := 266.0
	var sep := Panel.new()
	sep.position = Vector2(0, sep_y)
	sep.size = Vector2(EDIT_W, 1)
	sep.add_theme_stylebox_override("panel", _sb(Color(0.3, 0.5, 1.0, 0.15)))
	bg.add_child(sep)

	# Element cards sub-section
	var elem_header := Panel.new()
	elem_header.position = Vector2(0, sep_y + 2)
	elem_header.size = Vector2(EDIT_W, 24)
	elem_header.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.10, 0.22, 1.0)))
	bg.add_child(elem_header)
	_lbl("การ์ดธาตุ", 11, Color(0.5, 0.8, 1.0, 0.8), elem_header, Vector2(12, 5))

	var elem_panel := Control.new()
	elem_panel.position = Vector2(8, sep_y + 28)
	elem_panel.size = Vector2(EDIT_W - 16, 120)
	bg.add_child(elem_panel)
	_build_elem_grid(elem_panel)

	# Support cards sub-section
	var supp_sep_y := sep_y + 152.0
	var supp_header := Panel.new()
	supp_header.position = Vector2(0, supp_sep_y)
	supp_header.size = Vector2(EDIT_W, 24)
	supp_header.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.10, 0.22, 1.0)))
	bg.add_child(supp_header)
	_lbl("การ์ดสนับสนุน", 11, Color(0.8, 0.6, 1.0, 0.8), supp_header, Vector2(12, 5))

	var supp_panel := Control.new()
	supp_panel.position = Vector2(8, supp_sep_y + 28)
	supp_panel.size = Vector2(EDIT_W - 16, 80)
	bg.add_child(supp_panel)
	_build_supp_grid(supp_panel)

	# confirm + close buttons
	var conf_sb := _sb(Color(0.12, 0.35, 0.85, 1.0), Color(0.4,0.6,1.0,0.3), 10)
	var conf_b := _btn("✓  ยืนยัน", 13, Color.WHITE, conf_sb,
		bg, Vector2(EDIT_W - 124, SH - 56), Vector2(116, 40))
	conf_b.pressed.connect(_on_edit_close)

	var cancel_sb := _sb(Color(0.1,0.1,0.1,0.6), Color(0.4,0.4,0.4,0.3), 10)
	var cancel_b := _btn("✕  ยกเลิก", 12, Color(0.8,0.8,0.8,0.8), cancel_sb,
		bg, Vector2(8, SH - 56), Vector2(110, 40))
	cancel_b.pressed.connect(_on_edit_close)

func _build_char_grid(parent: Control) -> void:
	var avail: Array = []
	for entry in CharacterManager.get_roster():
		if entry.get("owned", false):
			avail.append(entry["name"])
	if avail.is_empty():
		avail = ["Lyra", "Kael"]

	var cols := 4
	var cw := 76.0; var ch_h := 90.0; var gap := 6.0
	for i in range(avail.size()):
		if i >= 8:
			break
		var row := i / cols; var col := i % cols
		var cx := col * (cw + gap); var cy := row * (ch_h + gap)
		var name_str: String = avail[i]

		var card := Panel.new()
		card.position = Vector2(cx, cy)
		card.size = Vector2(cw, ch_h)
		var is_sel := _selected_chars.has(name_str)
		var sb := _sb(Color(0.15, 0.25, 0.5, 0.8) if is_sel else Color(0.08, 0.12, 0.22, 0.8),
			Color(0.4, 0.7, 1.0, 0.8) if is_sel else Color(0.3, 0.4, 0.6, 0.3), 8)
		card.add_theme_stylebox_override("panel", sb)
		parent.add_child(card)

		_lbl("🧑", 28, Color.WHITE, card, Vector2(cw/2 - 16, 8))
		var nl := _lbl(name_str, 9, Color(0.8, 0.9, 1.0), card, Vector2(2, 62), Vector2(cw - 4, 14))
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var n := name_str
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_toggle_char(n)
				_rebuild_char_grid(parent))

func _rebuild_char_grid(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()
	_build_char_grid(parent)
	_refresh_team_display()

func _toggle_char(name_str: String) -> void:
	if _selected_chars.has(name_str):
		var idx := _selected_chars.find(name_str)
		_selected_chars[idx] = ""
	else:
		var empty_idx := _selected_chars.find("")
		if empty_idx >= 0:
			_selected_chars[empty_idx] = name_str

func _build_elem_grid(parent: Control) -> void:
	var owned_elems: Array = ["H", "O", "Na", "C", "Fe", "N", "S", "Ca", "Mg", "Cl"]

	var cw := 52.0; var ch_h := 52.0; var gap := 6.0; var cols := 5
	for i in range(owned_elems.size()):
		if i >= 10:
			break
		var row := i / cols; var col := i % cols
		var elem: String = owned_elems[i]
		var is_sel := _selected_elems.has(elem)

		var card := Panel.new()
		card.position = Vector2(col * (cw + gap), row * (ch_h + gap))
		card.size = Vector2(cw, ch_h)
		card.add_theme_stylebox_override("panel", _sb(
			Color(0.1, 0.3, 0.6, 0.8) if is_sel else Color(0.06, 0.12, 0.22, 0.8),
			Color(0.3, 0.7, 1.0, 0.8) if is_sel else Color(0.2, 0.4, 0.6, 0.3), 6))
		parent.add_child(card)

		_lbl(elem, 18, Color(0.6, 0.9, 1.0) if is_sel else Color(0.7, 0.85, 1.0, 0.8), card, Vector2(cw/2 - 12, 6))

		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var e := elem
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_toggle_elem(e)
				_rebuild_elem_grid(parent))

func _rebuild_elem_grid(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()
	_build_elem_grid(parent)

func _toggle_elem(elem: String) -> void:
	if _selected_elems.has(elem):
		var idx := _selected_elems.find(elem)
		_selected_elems[idx] = ""
	else:
		var empty_idx := _selected_elems.find("")
		if empty_idx >= 0:
			_selected_elems[empty_idx] = elem

func _build_supp_grid(parent: Control) -> void:
	var owned_supp: Array = ["Acid Flask", "Iron Shield", "Ember Seal"]

	var cw := 100.0; var ch_h := 52.0; var gap := 8.0
	for i in range(owned_supp.size()):
		if i >= MAX_SUPP * 2:
			break
		var supp: String = owned_supp[i]
		var is_sel := _selected_supp.has(supp)

		var card := Panel.new()
		card.position = Vector2(i * (cw + gap), 0)
		card.size = Vector2(cw, ch_h)
		card.add_theme_stylebox_override("panel", _sb(
			Color(0.25, 0.12, 0.45, 0.85) if is_sel else Color(0.08, 0.06, 0.16, 0.8),
			Color(0.8, 0.5, 1.0, 0.8) if is_sel else Color(0.4, 0.3, 0.6, 0.3), 6))
		parent.add_child(card)

		_lbl(supp, 9, Color(0.85, 0.7, 1.0) if is_sel else Color(0.7, 0.65, 0.85, 0.8),
			card, Vector2(4, 16), Vector2(cw - 8, 18))

		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var s := supp
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_toggle_supp(s)
				_rebuild_supp_grid(parent))

func _rebuild_supp_grid(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()
	_build_supp_grid(parent)

func _toggle_supp(supp: String) -> void:
	if _selected_supp.has(supp):
		var idx := _selected_supp.find(supp)
		_selected_supp[idx] = ""
	else:
		var empty_idx := _selected_supp.find("")
		if empty_idx >= 0:
			_selected_supp[empty_idx] = supp

# ── fade overlay ──
func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

# ── edit open/close ──
func _on_edit() -> void:
	if _edit_open:
		return
	_edit_open = true
	_edit_panel.visible = true
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_edit_panel, "position:x", 0.0, 0.3)

func _on_edit_close() -> void:
	if not _edit_open:
		return
	var t := create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_edit_panel, "position:x", -EDIT_W, 0.25)
	await t.finished
	_edit_open = false
	_edit_panel.visible = false
	_refresh_team_display()

# ── start ──
func _on_start() -> void:
	DomainManager.add_points("battle")
	SceneTransition.fade_to(SC_BATTLE)
