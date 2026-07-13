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

# ── Team / deck limits ──
const MAX_CHARS      := 4
const MAX_ELEM_COPY  := 3   # copies of one element card
const MAX_SUPP_TYPES := 2   # distinct support types
const MAX_SUPP_COPY  := 2   # copies per support type

var _selected_chars: Array[String] = ["Lyra", "", "", ""]
var _elem_deck: Dictionary = {}   # elem  → count (0–3)
var _supp_deck: Dictionary = {}   # supp  → count (0–2)

var _current_stage := 0          # 0 or 1
var _edit_open     := false
var _enemy_expand  := false

@onready var _char_display_root: Control  = $CharacterDisplayRoot
@onready var _enemy_panel:       Control  = $EnemyPanel
@onready var _fade:              ColorRect = $FadeOverlay

# built at runtime
var _edit_panel:   Control  = null
var _char_slots:   Array    = []
var _elem_slots:   Array    = []
var _supp_slots:   Array    = []
var _stage_dots:   Array    = []

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
	if ResourceLoader.exists("res://image/bguio.png"):
		var bg := TextureRect.new()
		bg.texture = load("res://image/bguio.png")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.z_index = -1
		add_child(bg)
		move_child(bg, 0)

	$BottomBar/EditBtn.pressed.connect(_on_edit)
	$BottomBar/StartBtn.pressed.connect(_on_start)
	_build_edit_panel()
	_refresh_enemy_panel()
	_refresh_team_display()

	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.35)

# ── character display (center) ──
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

		# element badge (show first elem in deck)
		var elem: String = _elem_deck.keys()[0] if _elem_deck.size() > 0 else ""
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

	# char grid: 3 cols × 110px + gap, up to 2 rows = 236px
	var char_panel := Control.new()
	char_panel.position = Vector2(8, 36)
	char_panel.size = Vector2(EDIT_W - 16, 236)
	bg.add_child(char_panel)
	_build_char_grid(char_panel)

	# ── BOTTOM: cards ──
	var sep_y := 278.0
	var sep := Panel.new()
	sep.position = Vector2(0, sep_y)
	sep.size = Vector2(EDIT_W, 1)
	sep.add_theme_stylebox_override("panel", _sb(Color(0.3, 0.5, 1.0, 0.15)))
	bg.add_child(sep)

	# Element cards sub-section (discovered only)
	var elem_count := maxi(PlayerData.discovered_elements.size(), 2)
	var elem_rows  := ceili(float(elem_count) / 5.0)
	var elem_h     := elem_rows * (64 + 6) + 4

	var elem_header := Panel.new()
	elem_header.position = Vector2(0, sep_y + 2)
	elem_header.size = Vector2(EDIT_W, 24)
	elem_header.add_theme_stylebox_override("panel", _sb(Color(0.04, 0.10, 0.20, 1.0)))
	bg.add_child(elem_header)
	_lbl("การ์ดธาตุ  (แตะซ้ำเพื่อเพิ่ม ×1–×3)", 10,
		Color(0.4, 0.8, 1.0, 0.85), elem_header, Vector2(12, 5))

	var elem_panel := Control.new()
	elem_panel.position = Vector2(8, sep_y + 28)
	elem_panel.size = Vector2(EDIT_W - 16, elem_h)
	bg.add_child(elem_panel)
	_build_elem_grid(elem_panel)

	# Support cards sub-section
	var supp_sep_y := sep_y + 28 + elem_h + 6
	var supp_header := Panel.new()
	supp_header.position = Vector2(0, supp_sep_y)
	supp_header.size = Vector2(EDIT_W, 24)
	supp_header.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.04, 0.18, 1.0)))
	bg.add_child(supp_header)
	_lbl("การ์ดสนับสนุน  (สูงสุด 2 ชนิด × 2 ใบ)", 10,
		Color(0.8, 0.55, 1.0, 0.85), supp_header, Vector2(12, 5))

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

# ── rarity border color ──
func _rarity_color(r: int) -> Color:
	match r:
		5: return Color(1.00, 0.80, 0.20)
		4: return Color(0.70, 0.40, 1.00)
		_: return Color(0.35, 0.65, 1.00)

# ── count badge (top-right corner) ──
func _add_count_badge(parent: Control, count: int, badge_col: Color) -> void:
	var badge := Panel.new()
	badge.size = Vector2(20, 20)
	badge.position = Vector2(parent.size.x - 22, 2)
	badge.z_index = 2
	var bs := StyleBoxFlat.new()
	bs.bg_color = badge_col
	bs.set_corner_radius_all(10)
	badge.add_theme_stylebox_override("panel", bs)
	parent.add_child(badge)
	var bl := Label.new()
	bl.text = "×%d" % count
	bl.add_theme_font_size_override("font_size", 8)
	bl.add_theme_color_override("font_color", Color.WHITE)
	bl.set_anchors_preset(Control.PRESET_FULL_RECT)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(bl)

# ── character grid ──
func _build_char_grid(parent: Control) -> void:
	var avail: Array = []
	for entry in CharacterManager.get_roster():
		if entry.get("owned", false):
			avail.append({"name": entry["name"], "rarity": entry.get("rarity", 3),
				"elem_col": entry.get("element_color", Color(0.4, 0.7, 1.0))})
	if avail.is_empty():
		avail = [{"name": "Lyra", "rarity": 5, "elem_col": Color(0.5, 0.3, 1.0)}]

	var cols := 3
	var cw := 86.0; var ch_h := 110.0; var gap := 8.0
	for i in range(avail.size()):
		var entry: Dictionary = avail[i]
		var name_str: String  = entry["name"]
		var row := i / cols; var col := i % cols
		var is_sel := _selected_chars.has(name_str)
		var rcol: Color = _rarity_color(entry["rarity"])
		var ecol: Color = entry["elem_col"]

		var card := Panel.new()
		card.position = Vector2(col * (cw + gap), row * (ch_h + gap))
		card.size     = Vector2(cw, ch_h)
		card.clip_contents = true
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.08, 0.18, 0.95)
		sb.border_color = rcol if is_sel else Color(rcol.r, rcol.g, rcol.b, 0.25)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			sb.set_border_width(side, 2 if is_sel else 1)
		sb.set_corner_radius_all(8)
		if is_sel:
			sb.shadow_color = Color(ecol.r, ecol.g, ecol.b, 0.5)
			sb.shadow_size  = 6
		card.add_theme_stylebox_override("panel", sb)
		parent.add_child(card)

		# portrait image
		var portrait_path := "res://image/%s_1.png" % name_str.to_lower()
		if ResourceLoader.exists(portrait_path):
			var tex_rect := TextureRect.new()
			tex_rect.texture = load(portrait_path)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tex_rect.position = Vector2(0, 0)
			tex_rect.size = Vector2(cw, ch_h - 22)
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(tex_rect)
		else:
			_lbl("🧑", 36, Color.WHITE, card, Vector2(cw / 2 - 18, 10))

		# rarity stars bottom strip
		var strip := Panel.new()
		strip.position = Vector2(0, ch_h - 22)
		strip.size = Vector2(cw, 22)
		var strip_sb := StyleBoxFlat.new()
		strip_sb.bg_color = Color(0.02, 0.04, 0.12, 0.92)
		strip.add_theme_stylebox_override("panel", strip_sb)
		card.add_child(strip)

		var nl := Label.new()
		nl.text = name_str
		nl.add_theme_font_size_override("font_size", 9)
		nl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		nl.position = Vector2(2, 2)
		nl.size = Vector2(cw - 4, 12)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(nl)

		var stars_lbl := Label.new()
		var star_count: int = entry.get("rarity", 3) if entry.has("rarity") else 3
		stars_lbl.text = "★".repeat(star_count)
		stars_lbl.add_theme_font_size_override("font_size", 7)
		stars_lbl.add_theme_color_override("font_color", rcol)
		stars_lbl.position = Vector2(2, 12)
		stars_lbl.size = Vector2(cw - 4, 10)
		stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(stars_lbl)

		if is_sel:
			var sel_mark := Label.new()
			sel_mark.text = "✓"
			sel_mark.add_theme_font_size_override("font_size", 14)
			sel_mark.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 0.9))
			sel_mark.position = Vector2(cw - 20, 4)
			sel_mark.size = Vector2(16, 16)
			sel_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(sel_mark)

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

# ── element deck grid ──
func _build_elem_grid(parent: Control) -> void:
	# pull only discovered elements from PlayerData
	var owned_elems: Array = []
	if PlayerData.discovered_elements.size() > 0:
		owned_elems.assign(PlayerData.discovered_elements)
	else:
		owned_elems = ["H", "O"]  # fallback for fresh save
	var elem_colors: Dictionary = {
		"H": Color(0.3, 0.7, 1.0), "O": Color(1.0, 0.35, 0.35),
		"Na": Color(1.0, 0.75, 0.2), "C": Color(0.6, 0.6, 0.6),
		"Fe": Color(0.85, 0.5, 0.2), "N": Color(0.5, 0.8, 1.0),
		"S":  Color(0.9, 0.85, 0.1), "Ca": Color(0.9, 0.9, 0.9),
		"Mg": Color(0.55, 0.9, 0.6), "Cl": Color(0.4, 1.0, 0.5),
	}

	var cw := 54.0; var ch_h := 64.0; var gap := 6.0; var cols := 5
	for i in range(owned_elems.size()):
		var elem: String = owned_elems[i]
		var count: int   = _elem_deck.get(elem, 0)
		var ecol: Color  = elem_colors.get(elem, Color(0.5, 0.8, 1.0))
		var row := i / cols; var col := i % cols

		var card := Panel.new()
		card.position = Vector2(col * (cw + gap), row * (ch_h + gap))
		card.size     = Vector2(cw, ch_h)
		card.clip_contents = false
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(ecol.r * 0.12, ecol.g * 0.12, ecol.b * 0.18, 0.95) if count > 0 \
					else Color(0.05, 0.08, 0.16, 0.9)
		sb.border_color = Color(ecol.r, ecol.g, ecol.b, 0.85) if count > 0 \
						else Color(ecol.r, ecol.g, ecol.b, 0.2)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			sb.set_border_width(side, 2 if count > 0 else 1)
		sb.set_corner_radius_all(8)
		if count > 0:
			sb.shadow_color = Color(ecol.r, ecol.g, ecol.b, 0.4)
			sb.shadow_size  = 5
		card.add_theme_stylebox_override("panel", sb)
		parent.add_child(card)

		var sym_lbl := Label.new()
		sym_lbl.text = elem
		sym_lbl.add_theme_font_size_override("font_size", 20)
		sym_lbl.add_theme_color_override("font_color",
			Color(ecol.r + 0.2, ecol.g + 0.2, ecol.b + 0.2) if count > 0 else Color(ecol.r, ecol.g, ecol.b, 0.5))
		sym_lbl.position = Vector2(0, 8)
		sym_lbl.size = Vector2(cw, 28)
		sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(sym_lbl)

		# copy count indicator dots
		var dot_y := ch_h - 14.0
		for d in range(MAX_ELEM_COPY):
			var dot := Panel.new()
			dot.size = Vector2(8, 8)
			dot.position = Vector2(cw / 2.0 - (MAX_ELEM_COPY * 10.0) / 2.0 + d * 10.0, dot_y)
			var ds := StyleBoxFlat.new()
			ds.bg_color = Color(ecol.r, ecol.g, ecol.b, 0.9) if d < count else Color(0.2, 0.2, 0.3, 0.6)
			ds.set_corner_radius_all(4)
			dot.add_theme_stylebox_override("panel", ds)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(dot)

		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var e := elem
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_cycle_elem(e)
				_rebuild_elem_grid(parent))

func _rebuild_elem_grid(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()
	_build_elem_grid(parent)

func _cycle_elem(elem: String) -> void:
	var cur: int = _elem_deck.get(elem, 0)
	var next := (cur + 1) % (MAX_ELEM_COPY + 1)
	if next == 0:
		_elem_deck.erase(elem)
	else:
		_elem_deck[elem] = next

# ── support deck grid ──
func _build_supp_grid(parent: Control) -> void:
	var owned_supp: Array = ["Acid Flask", "Iron Shield", "Ember Seal"]

	var cw := 100.0; var ch_h := 68.0; var gap := 8.0
	for i in range(owned_supp.size()):
		var supp: String = owned_supp[i]
		var count: int   = _supp_deck.get(supp, 0)
		var is_sel       := count > 0

		var card := Panel.new()
		card.position = Vector2(i * (cw + gap), 0)
		card.size     = Vector2(cw, ch_h)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.08, 0.32, 0.95) if is_sel else Color(0.06, 0.04, 0.14, 0.9)
		sb.border_color = Color(0.85, 0.55, 1.0, 0.9) if is_sel else Color(0.5, 0.35, 0.7, 0.25)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			sb.set_border_width(side, 2 if is_sel else 1)
		sb.set_corner_radius_all(8)
		if is_sel:
			sb.shadow_color = Color(0.7, 0.3, 1.0, 0.45)
			sb.shadow_size  = 5
		card.add_theme_stylebox_override("panel", sb)
		parent.add_child(card)

		var nl := Label.new()
		nl.text = supp
		nl.add_theme_font_size_override("font_size", 9)
		nl.add_theme_color_override("font_color",
			Color(0.9, 0.75, 1.0) if is_sel else Color(0.65, 0.6, 0.8, 0.7))
		nl.position = Vector2(4, 14)
		nl.size = Vector2(cw - 8, 28)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nl)

		# copy dots
		for d in range(MAX_SUPP_COPY):
			var dot := Panel.new()
			dot.size = Vector2(10, 10)
			dot.position = Vector2(cw / 2.0 - (MAX_SUPP_COPY * 12.0) / 2.0 + d * 12.0, ch_h - 16.0)
			var ds := StyleBoxFlat.new()
			ds.bg_color = Color(0.85, 0.55, 1.0, 0.9) if d < count else Color(0.2, 0.15, 0.3, 0.6)
			ds.set_corner_radius_all(5)
			dot.add_theme_stylebox_override("panel", ds)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(dot)

		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var s := supp
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_cycle_supp(s)
				_rebuild_supp_grid(parent))

func _rebuild_supp_grid(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()
	_build_supp_grid(parent)

func _cycle_supp(supp: String) -> void:
	var cur: int = _supp_deck.get(supp, 0)
	if cur == 0:
		# only allow adding if fewer than MAX_SUPP_TYPES active
		var active_types := 0
		for k in _supp_deck:
			if _supp_deck[k] > 0:
				active_types += 1
		if active_types >= MAX_SUPP_TYPES:
			return
	var next := (cur + 1) % (MAX_SUPP_COPY + 1)
	if next == 0:
		_supp_deck.erase(supp)
	else:
		_supp_deck[supp] = next


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
