extends Control

const SC_ROSTER := "res://character_roster.tscn"

const PORTRAITS := {
	"Alchemist": "res://image/lyra_1.png",
	"Lyra":      "res://image/lyra_2.png",
}

const VW      := 1152.0
const VH      := 648.0
const LEFT_W  := 440.0
const RIGHT_X := 448.0
const RIGHT_W := VW - RIGHT_X   # 704

const C_BG    := Color(0.030, 0.032, 0.068, 1.0)
const C_PANEL := Color(0.042, 0.048, 0.105, 0.97)
const C_TEXT  := Color(0.92,  0.94,  1.00,  1.0)
const C_SUB   := Color(0.55,  0.68,  0.88,  0.72)
const C_GOLD  := Color(1.00,  0.84,  0.28,  1.0)
const C_LINE  := Color(1.0,   1.0,   1.0,   0.07)

@onready var _fade: ColorRect = $FadeOverlay

func _ready() -> void:
	var char_name := CharacterManager.selected_character
	var data := CharacterManager.get_character_data(char_name)
	if data.is_empty():
		char_name = "Alchemist"
		data = CharacterManager.get_character_data(char_name)

	var base: Dictionary = {}
	for c in CharacterManager.ALL_CHARACTERS:
		if c["name"] == char_name:
			base = c
			break

	# BG
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_left(char_name, data, base)
	_build_right(char_name, data, base)

	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.30)

# ── Left panel: portrait + stats overlay ──────────────────────────────────────
func _build_left(char_name: String, data: Dictionary, base: Dictionary) -> void:
	var elem_col: Color = base.get("element_color", Color(0.35, 0.75, 1.0)) as Color
	var rarity: int     = int(base.get("rarity", 5))
	var r_col: Color    = _rarity_color(rarity)

	# Portrait
	var ppath: String = PORTRAITS.get(char_name, "")
	if ppath != "" and ResourceLoader.exists(ppath):
		var tex: Texture2D = load(ppath)
		if tex:
			var img := TextureRect.new()
			img.texture      = tex
			img.size         = Vector2(LEFT_W, VH)
			img.position     = Vector2(0, 0)
			img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(img)
	else:
		# Fallback: colored bg + big element symbol
		add_child(_crect(Vector2(0, 0), Vector2(LEFT_W, VH),
			Color(elem_col.r * 0.12, elem_col.g * 0.12, elem_col.b * 0.22, 1.0)))
		var sym := _lbl(str(base.get("element", "⚗")), 120, Color(elem_col.r, elem_col.g, elem_col.b, 0.18))
		sym.size = Vector2(LEFT_W, VH)
		sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		add_child(sym)

	# Gradient overlay — starts at stat box top (VH-130), 5 layers
	for i in 5:
		var layer_h := 26.0
		var alpha := 0.10 + i * 0.14
		var ly := VH - layer_h * (5 - i)
		add_child(_crect(Vector2(0, ly), Vector2(LEFT_W, layer_h + 1),
			Color(C_BG.r, C_BG.g, C_BG.b, alpha)))

	# Element badge top-left
	# Stats table (ATK / HP / DEF) — single row left to right
	var stat_y := VH - 130.0
	var stat_keys := ["atk", "hp", "def"]
	var stat_labels := ["ATK", "HP", "DEF"]
	var stat_box_w := (LEFT_W - 28.0) / 3.0
	for i in stat_keys.size():
		var col_x := 10.0 + i * (stat_box_w + 4.0)

		var sb := Panel.new()
		sb.size     = Vector2(stat_box_w, 40)
		sb.position = Vector2(col_x, stat_y)
		sb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sb.add_theme_stylebox_override("panel",
			_flat(Color(0, 0, 0, 0.45), Color(elem_col.r, elem_col.g, elem_col.b, 0.20), 6, 1))
		add_child(sb)

		var key_lbl := _lbl(stat_labels[i], 9, Color(elem_col.r, elem_col.g, elem_col.b, 0.80))
		key_lbl.position = Vector2(8, 3)
		key_lbl.size = Vector2(stat_box_w - 14, 14)
		sb.add_child(key_lbl)

		var val_str := str(int(data.get(stat_keys[i], 0)))
		var val_lbl := _lbl(val_str, 14, C_TEXT)
		val_lbl.position = Vector2(8, 18)
		val_lbl.size = Vector2(stat_box_w - 14, 20)
		val_lbl.add_theme_color_override("font_color", C_TEXT)
		sb.add_child(val_lbl)

	# Name + title
	var name_y := VH - 70.0
	var name_lbl := _lbl(char_name.to_upper(), 28, C_TEXT)
	name_lbl.position = Vector2(14, name_y)
	name_lbl.size = Vector2(LEFT_W - 28, 34)
	add_child(name_lbl)

	# Stars — right of name, same row
	var stars_lbl := _lbl("★".repeat(rarity), 20, r_col)
	stars_lbl.position = Vector2(16, name_y + 32)
	stars_lbl.size = Vector2(LEFT_W - 28, 26)
	add_child(stars_lbl)

	var title_lbl := _lbl(str(data.get("title", "")), 11, Color(elem_col.r, elem_col.g, elem_col.b, 0.90))
	title_lbl.position = Vector2(16, name_y + 58)
	title_lbl.size = Vector2(LEFT_W - 28, 18)
	add_child(title_lbl)

	# Separator line between left and right
	add_child(_crect(Vector2(LEFT_W, 0), Vector2(1, VH),
		Color(elem_col.r, elem_col.g, elem_col.b, 0.20)))

# ── Right panel: level/insight + skills + passive + buttons ──────────────────
func _build_right(char_name: String, data: Dictionary, base: Dictionary) -> void:
	var elem_col: Color = base.get("element_color", Color(0.35, 0.75, 1.0)) as Color
	var skills: Array   = data.get("skills", [])
	var passive: Dictionary = data.get("passive", {})

	# Panel bg
	var panel_bg := ColorRect.new()
	panel_bg.position = Vector2(RIGHT_X, 0)
	panel_bg.size     = Vector2(RIGHT_W, VH)
	panel_bg.color    = C_PANEL
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_bg)

	# Back button (far right)
	var back := _make_back_btn()
	back.position = Vector2(RIGHT_X + RIGHT_W - 46, 14)
	add_child(back)

	# Level Up button
	var lvup := Panel.new()
	lvup.size     = Vector2(RIGHT_W - 80, 44)
	lvup.position = Vector2(RIGHT_X + 14, 52)
	lvup.mouse_filter = Control.MOUSE_FILTER_STOP
	var lvup_sb := StyleBoxFlat.new()
	var is_void := elem_col.b > elem_col.r and elem_col.b > elem_col.g
	if is_void:
		lvup_sb.bg_color = Color(0.04, 0.08, 0.24, 1.0)
		lvup_sb.border_color = Color(0.2, 0.85, 1.0, 0.90)
		lvup_sb.shadow_color = Color(0.0, 0.8, 1.0, 0.45)
		lvup_sb.shadow_size = 6
	else:
		lvup_sb.bg_color = Color(elem_col.r * 0.22, elem_col.g * 0.22, elem_col.b * 0.35, 1.0)
		lvup_sb.border_color = Color(elem_col.r, elem_col.g, elem_col.b, 0.70)
	lvup_sb.set_border_width_all(1)
	lvup_sb.set_corner_radius_all(8)
	lvup.add_theme_stylebox_override("panel", lvup_sb)
	add_child(lvup)

	var lvup_txt_col := Color(0.4, 0.95, 1.0, 1.0) if is_void else Color(elem_col.r + 0.15, elem_col.g + 0.1, elem_col.b + 0.1, 1.0)
	var lvup_lbl := _lbl("Level Up", 15, lvup_txt_col)
	lvup_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lvup_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvup_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lvup_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lvup.add_child(lvup_lbl)

	lvup.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var t := lvup.create_tween().set_trans(Tween.TRANS_BACK)
			t.tween_property(lvup, "scale", Vector2(0.93, 0.93), 0.08)
			t.tween_property(lvup, "scale", Vector2(1.0,  1.0),  0.12)
	)

	# Divider
	add_child(_crect(Vector2(RIGHT_X + 14, 140), Vector2(RIGHT_W - 28, 1), C_LINE))

	# Skill rows (4 skills stacked)
	const SKILL_ICONS := {"Basic ATK": "⚔", "Defend": "🛡", "Skill": "✦", "Ultimate": "💥"}
	var sk_y := 148.0
	var sk_h := 62.0
	var sk_gap := 6.0
	for i in skills.size():
		var sk: Dictionary = skills[i]
		_build_skill_row(Vector2(RIGHT_X + 14, sk_y), Vector2(RIGHT_W - 28, sk_h), sk, elem_col, SKILL_ICONS)
		sk_y += sk_h + sk_gap

	# Passive section
	if not passive.is_empty():
		add_child(_crect(Vector2(RIGHT_X + 14, sk_y + 4), Vector2(RIGHT_W - 28, 1), C_LINE))
		var passive_sk := {
			"name": passive.get("name", "Passive"),
			"type": "Passive",
			"img":  "",
			"desc": passive.get("desc", ""),
		}
		_build_skill_row(Vector2(RIGHT_X + 14, sk_y + 12), Vector2(RIGHT_W - 28, sk_h), passive_sk, elem_col, {"Passive": "🔮"})
		sk_y += sk_h + 20

	# Dialogue quote
	var dialogue: String = str(data.get("dialogue", ""))
	if dialogue != "":
		var dq := _lbl("\"  " + dialogue + "  \"", 10, Color(0.72, 0.82, 1.0, 0.55))
		dq.position = Vector2(RIGHT_X + 14, sk_y + 14)
		dq.size = Vector2(RIGHT_W - 28, 24)
		dq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(dq)


func _build_skill_row(pos: Vector2, sz: Vector2, sk: Dictionary, _elem_col: Color, icon_map: Dictionary) -> void:
	var card := Panel.new()
	card.position     = pos
	card.size         = sz
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sk_type: String = str(sk.get("type", ""))
	var type_col: Color = _skill_type_color(sk_type)
	card.add_theme_stylebox_override("panel",
		_flat(Color(type_col.r * 0.06, type_col.g * 0.06, type_col.b * 0.10, 0.95),
			Color(type_col.r, type_col.g, type_col.b, 0.15), 6, 1))
	add_child(card)

	# Left icon column — type emoji only
	var icon_w := sz.y - 8
	var em_bg := ColorRect.new()
	em_bg.size     = Vector2(icon_w, icon_w)
	em_bg.position = Vector2(4, 4)
	em_bg.color    = Color(type_col.r * 0.15, type_col.g * 0.15, type_col.b * 0.25, 0.95)
	em_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(em_bg)
	var em := _lbl(icon_map.get(sk_type, "✦"), 22, Color(type_col.r, type_col.g, type_col.b, 0.90))
	em.size = Vector2(icon_w, icon_w)
	em.position = Vector2(4, 4)
	em.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	em.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	card.add_child(em)

	# Type tag (small pill)
	var tag_w := 62.0
	var type_tag := Panel.new()
	type_tag.size     = Vector2(tag_w, 16)
	type_tag.position = Vector2(icon_w + 10, 5)
	type_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_tag.add_theme_stylebox_override("panel",
		_flat(Color(type_col.r * 0.18, type_col.g * 0.18, type_col.b * 0.22, 0.95),
			Color(type_col.r, type_col.g, type_col.b, 0.40), 4, 1))
	card.add_child(type_tag)
	var type_lbl := _lbl(sk_type, 8, Color(type_col.r + 0.05, type_col.g + 0.05, type_col.b + 0.05, 1.0))
	type_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	type_tag.add_child(type_lbl)

	# Skill name
	var name_lbl := _lbl(str(sk.get("name", "")), 13, C_TEXT)
	name_lbl.position = Vector2(icon_w + 10, 23)
	name_lbl.size = Vector2(sz.x - icon_w - 18, 18)
	card.add_child(name_lbl)

	# Description (small, wrapping)
	var desc: String = str(sk.get("desc", ""))
	if desc != "":
		var desc_lbl := _lbl(desc, 9, Color(0.72, 0.82, 0.95, 0.70))
		desc_lbl.position = Vector2(icon_w + 10, 42)
		desc_lbl.size = Vector2(sz.x - icon_w - 18, sz.y - 44)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(desc_lbl)

# ── Helper: "+" button ────────────────────────────────────────────────────────
func _plus_btn(pos: Vector2, col: Color) -> Panel:
	var btn := Panel.new()
	btn.size     = Vector2(28, 28)
	btn.position = pos
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_stylebox_override("panel",
		_flat(Color(col.r * 0.20, col.g * 0.20, col.b * 0.30, 0.95),
			Color(col.r, col.g, col.b, 0.55), 6, 1))
	var lbl := _lbl("+", 16, Color(col.r + 0.1, col.g + 0.1, col.b + 0.1, 1.0))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	btn.add_child(lbl)
	return btn

func _skill_type_color(sk_type: String) -> Color:
	match sk_type:
		"Basic ATK": return Color(0.55, 0.85, 1.00)
		"Defend":    return Color(0.45, 0.90, 0.65)
		"Skill":     return Color(0.80, 0.55, 1.00)
		"Ultimate":  return Color(1.00, 0.72, 0.28)
		"Passive":   return Color(0.65, 0.80, 0.55)
		_:           return Color(0.70, 0.75, 0.85)

# ── Helper: info box (Level / Insight) ────────────────────────────────────────
func _info_box(pos: Vector2, sz: Vector2, caption: String, value: String, col: Color) -> Panel:
	var box := Panel.new()
	box.position    = pos
	box.size        = sz
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel",
		_flat(Color(col.r * 0.08, col.g * 0.08, col.b * 0.15, 0.95),
			Color(col.r, col.g, col.b, 0.25), 6, 1))

	var cap := _lbl(caption, 9, Color(col.r, col.g, col.b, 0.75))
	cap.position = Vector2(8, 4)
	cap.size = Vector2(sz.x - 16, 14)
	box.add_child(cap)

	var val := _lbl(value, 14, C_TEXT)
	val.position = Vector2(8, 20)
	val.size = Vector2(sz.x - 16, 20)
	box.add_child(val)

	return box

# ── Helper: back button ───────────────────────────────────────────────────────
func _make_back_btn() -> Panel:
	var btn := Panel.new()
	btn.size        = Vector2(42, 45)
	btn.pivot_offset = Vector2(21, 22)
	btn.z_index     = 20
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.05, 0.15, 0.55)
	sb.border_color = Color(0.45, 0.72, 1.0, 0.90)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(22)
	btn.add_theme_stylebox_override("panel", sb)
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
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.22)
			tw.tween_callback(SceneTransition.fade_to.bind(SC_ROSTER))
	)
	btn.mouse_entered.connect(func():
		btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	btn.mouse_exited.connect(func():
		btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)
	return btn

# ── Helpers ───────────────────────────────────────────────────────────────────
func _rarity_color(rarity: int) -> Color:
	match rarity:
		5: return Color(1.00, 0.80, 0.20)
		4: return Color(0.72, 0.50, 1.00)
		_: return Color(0.35, 0.65, 1.00)

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

func _action_btn(text: String, col: Color, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text; btn.size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(col.r + 0.1, col.g + 0.1, col.b + 0.1, 1.0))
	var sb := _flat(Color(col.r * 0.18, col.g * 0.18, col.b * 0.30, 0.95),
		Color(col.r, col.g, col.b, 0.55), 8, 1)
	for s in ["normal", "hover", "pressed"]:
		btn.add_theme_stylebox_override(s, sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn
