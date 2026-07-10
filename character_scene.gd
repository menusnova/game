extends Control

const SC_ROSTER := "res://character_roster.tscn"

const PORTRAITS := {
	"Alchemist": "res://image/lyra_1.png",
	"Lyra":      "res://image/lyra_2.png",
	"Seraph":    "res://image/lyra_3.png",
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

	# Gradient overlay (bottom 320px, 5 layers)
	for i in 5:
		var layer_h := 64.0
		var alpha := 0.10 + i * 0.14
		var ly := VH - layer_h * (5 - i)
		add_child(_crect(Vector2(0, ly), Vector2(LEFT_W, layer_h + 1),
			Color(C_BG.r, C_BG.g, C_BG.b, alpha)))

	# Element badge top-left
	var elem_s: String = str(base.get("element", "⚗"))
	var badge := Panel.new()
	badge.size     = Vector2(46, 46)
	badge.position = Vector2(14, 14)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel",
		_flat(Color(elem_col.r * 0.30, elem_col.g * 0.30, elem_col.b * 0.50, 0.92),
			Color(elem_col.r, elem_col.g, elem_col.b, 0.50), 23, 1))
	add_child(badge)
	var badge_lbl := _lbl(elem_s, 20, Color(1, 1, 1, 0.95))
	badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(badge_lbl)

	# Stats table (ATK / HP / DEF) — bottom-left overlay
	var stat_y := VH - 178.0
	var stat_keys := ["atk", "hp", "def"]
	var stat_labels := ["ATK", "HP", "DEF"]
	for i in stat_keys.size():
		var col_x := 0.0 if i % 2 == 0 else LEFT_W / 2.0
		var row_y := stat_y + int(i / 2) * 46.0
		if i == 2:  # DEF centered on second row
			col_x = (LEFT_W - 110.0) / 2.0

		var sb := Panel.new()
		sb.size     = Vector2(110, 40)
		sb.position = Vector2(col_x + 10, row_y)
		sb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sb.add_theme_stylebox_override("panel",
			_flat(Color(0, 0, 0, 0.45), Color(elem_col.r, elem_col.g, elem_col.b, 0.20), 6, 1))
		add_child(sb)

		var key_lbl := _lbl(stat_labels[i], 9, Color(elem_col.r, elem_col.g, elem_col.b, 0.80))
		key_lbl.position = Vector2(8, 3)
		key_lbl.size = Vector2(94, 14)
		sb.add_child(key_lbl)

		var val_str := str(int(data.get(stat_keys[i], 0)))
		var val_lbl := _lbl(val_str, 14, C_TEXT)
		val_lbl.position = Vector2(8, 18)
		val_lbl.size = Vector2(94, 20)
		val_lbl.add_theme_color_override("font_color", C_TEXT)
		sb.add_child(val_lbl)

	# Name + title
	var name_y := VH - 70.0
	var name_lbl := _lbl(char_name.to_upper(), 28, C_TEXT)
	name_lbl.position = Vector2(14, name_y)
	name_lbl.size = Vector2(LEFT_W - 28, 34)
	add_child(name_lbl)

	var title_lbl := _lbl(str(data.get("title", "")), 11, Color(elem_col.r, elem_col.g, elem_col.b, 0.90))
	title_lbl.position = Vector2(16, name_y + 36)
	title_lbl.size = Vector2(LEFT_W - 28, 18)
	add_child(title_lbl)

	# Stars
	var stars_lbl := _lbl("★".repeat(rarity), 13, r_col)
	stars_lbl.position = Vector2(16, name_y - 22)
	stars_lbl.size = Vector2(200, 20)
	add_child(stars_lbl)

	# Faction label
	var faction_lbl := _lbl(str(data.get("faction", "")), 10, C_SUB)
	faction_lbl.position = Vector2(16, 68)
	faction_lbl.size = Vector2(LEFT_W - 32, 18)
	add_child(faction_lbl)

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

	# Back button
	var back := _make_back_btn()
	back.position = Vector2(RIGHT_X + 14, 14)
	add_child(back)

	# Character name
	var hdr_name := _lbl(char_name, 20, C_TEXT)
	hdr_name.position = Vector2(RIGHT_X + 56, 16)
	hdr_name.size = Vector2(RIGHT_W - 70, 26)
	add_child(hdr_name)

	# Level box + "+" button
	var level: int     = int(data.get("level", 1))
	var level_max: int = int(data.get("level_max", 30))
	var lv_box := _info_box(Vector2(RIGHT_X + 14, 52), Vector2(148, 44),
		"LEVEL", "%d / %d" % [level, level_max], elem_col)
	add_child(lv_box)
	var lv_plus := _plus_btn(Vector2(RIGHT_X + 166, 60), elem_col)
	add_child(lv_plus)

	# Insight box + "+" button
	var insight: int = int(data.get("insight", 0))
	var ins_box := _info_box(Vector2(RIGHT_X + 204, 52), Vector2(130, 44),
		"INSIGHT", "Phase %d" % insight, elem_col)
	add_child(ins_box)
	var ins_plus := _plus_btn(Vector2(RIGHT_X + 338, 60), elem_col)
	add_child(ins_plus)

	# "Search the Poems" button row
	var poems_btn := _action_btn("Search the Poems", Color(0.75, 0.75, 0.75), Vector2(178, 28))
	poems_btn.position = Vector2(RIGHT_X + 14, 104)
	add_child(poems_btn)

	# Resonance triangle icons (△ △△ △△△)
	var tri_lbl := _lbl("△   △△   △△△", 11, Color(elem_col.r, elem_col.g, elem_col.b, 0.55))
	tri_lbl.position = Vector2(RIGHT_X + 200, 105)
	tri_lbl.size = Vector2(200, 24)
	add_child(tri_lbl)

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

	# Bottom buttons: Portray + Resonate
	var btn_y := VH - 58.0
	var portray_btn := _action_btn("Portray", elem_col, Vector2(RIGHT_W / 2.0 - 22, 44))
	portray_btn.position = Vector2(RIGHT_X + 14, btn_y)
	add_child(portray_btn)

	var resonate_btn := _action_btn("Resonate", Color(0.75, 0.55, 1.0), Vector2(RIGHT_W / 2.0 - 22, 44))
	resonate_btn.position = Vector2(RIGHT_X + RIGHT_W / 2.0 + 8, btn_y)
	add_child(resonate_btn)

func _build_skill_row(pos: Vector2, sz: Vector2, sk: Dictionary, elem_col: Color, icon_map: Dictionary) -> void:
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

	# Left icon column
	var icon_w := sz.y - 8
	var img_ppath: String = str(sk.get("img", ""))
	if img_ppath != "" and ResourceLoader.exists(img_ppath):
		var tex: Texture2D = load(img_ppath)
		if tex:
			var img := TextureRect.new()
			img.texture      = tex
			img.size         = Vector2(icon_w, icon_w)
			img.position     = Vector2(4, 4)
			img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(img)
	else:
		# Emoji fallback
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
	btn.size        = Vector2(32, 32)
	btn.pivot_offset = Vector2(16, 16)
	btn.z_index     = 20
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_stylebox_override("panel",
		_flat(Color(0, 0, 0, 0), Color(0.35, 0.55, 1.0, 0.30), 16, 1))
	var lbl := _lbl("‹", 18, Color(0.80, 0.90, 1.0, 0.92))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	btn.add_child(lbl)
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
