extends Control

const SC_ROSTER := "res://character_roster.tscn"

const PORTRAITS := {
	"Caelum Voss": "res://image/caelum_voss.png",
	"Lyra":        "res://image/lyra_2.png",
}

const VW      := 1152.0
const VH      := 648.0
const LEFT_W  := 440.0
const RIGHT_X := 448.0
const RIGHT_W := VW - RIGHT_X   # 704

const C_TEXT  := Color(0.92,  0.94,  1.00,  1.0)
const C_LINE  := Color(1.0,   1.0,   1.0,   0.07)

const SKILL_ICONS := {"Basic ATK": "⚔", "Defend": "🛡", "Skill": "✦", "Ultimate": "💥"}

@onready var _fade: ColorRect = $FadeOverlay

@onready var _portrait: TextureRect      = $Portrait
@onready var _elem_fallback_bg: ColorRect = $ElementFallbackBg
@onready var _elem_fallback_sym: Label    = $ElementFallbackSym

@onready var _stat_boxes: Array[Panel] = [$StatBox0, $StatBox1, $StatBox2]
const STAT_KEYS := ["atk", "hp", "def"]

@onready var _name_lbl:  Label = $NameLabel
@onready var _stars_lbl: Label = $StarsLabel
@onready var _title_lbl: Label = $TitleLabel
@onready var _separator: ColorRect = $SeparatorLine

@onready var _back_btn: Panel = $BackBtn
@onready var _lvup_btn: Panel = $LevelUpBtn
@onready var _lvup_lbl: Label = $LevelUpBtn/Label

@onready var _skill_rows: Array[Panel] = [$SkillRow0, $SkillRow1, $SkillRow2, $SkillRow3]
@onready var _passive_row: Panel = $PassiveRow
@onready var _passive_divider: ColorRect = $PassiveDivider

@onready var _dialogue_lbl: Label = $DialogueLabel

func _ready() -> void:
	var char_name := CharacterManager.selected_character
	var data := CharacterManager.get_character_data(char_name)
	if data.is_empty():
		char_name = "Caelum Voss"
		data = CharacterManager.get_character_data(char_name)

	var base: Dictionary = {}
	for c in CharacterManager.ALL_CHARACTERS:
		if c["name"] == char_name:
			base = c
			break

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
	var tex: Texture2D = AssetLoader.tex(ppath)
	if tex:
		_portrait.texture = tex
		_portrait.visible  = true
		_elem_fallback_bg.visible  = false
		_elem_fallback_sym.visible = false
	else:
		_portrait.visible = false
		_elem_fallback_bg.color = Color(elem_col.r * 0.12, elem_col.g * 0.12, elem_col.b * 0.22, 1.0)
		_elem_fallback_bg.visible = true
		_elem_fallback_sym.text = str(base.get("element", "⚗"))
		_elem_fallback_sym.add_theme_color_override("font_color", Color(elem_col.r, elem_col.g, elem_col.b, 0.18))
		_elem_fallback_sym.visible = true

	# Stats table (ATK / HP / DEF)
	for i in _stat_boxes.size():
		var box := _stat_boxes[i]
		box.add_theme_stylebox_override("panel",
			_flat(Color(0, 0, 0, 0.45), Color(elem_col.r, elem_col.g, elem_col.b, 0.20), 6, 1))
		var key_lbl := box.get_node("KeyLabel") as Label
		key_lbl.add_theme_color_override("font_color", Color(elem_col.r, elem_col.g, elem_col.b, 0.80))
		var val_lbl := box.get_node("ValueLabel") as Label
		val_lbl.text = str(int(data.get(STAT_KEYS[i], 0)))
		val_lbl.add_theme_color_override("font_color", C_TEXT)

	# Name + title
	_name_lbl.text = char_name.to_upper()
	_stars_lbl.text = "★".repeat(rarity)
	_stars_lbl.add_theme_color_override("font_color", r_col)
	_title_lbl.text = str(data.get("title", ""))
	_title_lbl.add_theme_color_override("font_color", Color(elem_col.r, elem_col.g, elem_col.b, 0.90))

	_separator.color = Color(elem_col.r, elem_col.g, elem_col.b, 0.20)

# ── Right panel: level/insight + skills + passive + buttons ──────────────────
func _build_right(_char_name: String, data: Dictionary, base: Dictionary) -> void:
	var elem_col: Color = base.get("element_color", Color(0.35, 0.75, 1.0)) as Color
	var skills: Array   = data.get("skills", [])
	var passive: Dictionary = data.get("passive", {})

	_setup_back_btn()
	_setup_levelup_btn(elem_col)

	# Skill rows — fill each of the 4 fixed slots; hide unused ones
	for i in _skill_rows.size():
		if i < skills.size():
			_skill_rows[i].visible = true
			_fill_skill_row(_skill_rows[i], skills[i], SKILL_ICONS)
		else:
			_skill_rows[i].visible = false

	# Passive section
	if not passive.is_empty():
		var passive_sk := {
			"name": passive.get("name", "Passive"),
			"type": "Passive",
			"icon": passive.get("icon", ""),
			"desc_short": passive.get("desc_short", ""),
			"desc": passive.get("desc", ""),
		}
		_passive_divider.visible = true
		_passive_row.visible = true
		_fill_skill_row(_passive_row, passive_sk, {"Passive": "🔮"})
	else:
		_passive_divider.visible = false
		_passive_row.visible = false

	# Dialogue quote
	var dialogue: String = str(data.get("dialogue", ""))
	if dialogue != "":
		_dialogue_lbl.text = "\"  " + dialogue + "  \""
		_dialogue_lbl.visible = true
	else:
		_dialogue_lbl.visible = false

func _setup_back_btn() -> void:
	if _back_btn.has_meta("_wired"):
		return
	_back_btn.set_meta("_wired", true)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.05, 0.15, 0.55)
	sb.border_color = Color(0.45, 0.72, 1.0, 0.90)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(22)
	_back_btn.add_theme_stylebox_override("panel", sb)
	_back_btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw := _back_btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(_back_btn, "scale", Vector2(0.78, 0.78), 0.08)
			tw.tween_property(_back_btn, "scale", Vector2(1.0, 1.0), 0.22)
			tw.tween_callback(SceneTransition.fade_to.bind(SC_ROSTER))
	)
	_back_btn.mouse_entered.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	_back_btn.mouse_exited.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)

func _setup_levelup_btn(elem_col: Color) -> void:
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
	_lvup_btn.add_theme_stylebox_override("panel", lvup_sb)

	var lvup_txt_col := Color(0.4, 0.95, 1.0, 1.0) if is_void else Color(elem_col.r + 0.15, elem_col.g + 0.1, elem_col.b + 0.1, 1.0)
	_lvup_lbl.add_theme_color_override("font_color", lvup_txt_col)

	if not _lvup_btn.has_meta("_wired"):
		_lvup_btn.set_meta("_wired", true)
		_lvup_btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				var t := _lvup_btn.create_tween().set_trans(Tween.TRANS_BACK)
				t.tween_property(_lvup_btn, "scale", Vector2(0.93, 0.93), 0.08)
				t.tween_property(_lvup_btn, "scale", Vector2(1.0,  1.0),  0.12)
		)

# ── fill a pre-built skill row node with this skill's data ───────────────────
func _fill_skill_row(card: Panel, sk: Dictionary, icon_map: Dictionary) -> void:
	var sk_type: String = str(sk.get("type", ""))
	var type_col: Color = _skill_type_color(sk_type)
	card.add_theme_stylebox_override("panel",
		_flat(Color(type_col.r * 0.06, type_col.g * 0.06, type_col.b * 0.10, 0.95),
			Color(type_col.r, type_col.g, type_col.b, 0.15), 6, 1))

	var icon_bg  := card.get_node("IconBg") as Panel
	var icon_tex := icon_bg.get_node("Icon") as TextureRect
	var icon_em  := card.get_node("IconEmoji") as Label
	var icon_path: String = str(sk.get("icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon_tex.texture = load(icon_path)
		var icon_mat := CanvasItemMaterial.new()
		icon_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		icon_tex.material = icon_mat
		icon_bg.add_theme_stylebox_override("panel",
			_flat(Color(type_col.r * 0.15, type_col.g * 0.15, type_col.b * 0.25, 0.95),
				Color(type_col.r, type_col.g, type_col.b, 0.35), 6, 1))
		icon_bg.visible = true
		icon_em.visible  = false
	else:
		icon_bg.visible = false
		icon_em.text = icon_map.get(sk_type, "✦")
		icon_em.add_theme_color_override("font_color", Color(type_col.r, type_col.g, type_col.b, 0.90))
		icon_em.visible = true

	var type_tag := card.get_node("TypeTag") as Panel
	type_tag.add_theme_stylebox_override("panel",
		_flat(Color(type_col.r * 0.18, type_col.g * 0.18, type_col.b * 0.22, 0.95),
			Color(type_col.r, type_col.g, type_col.b, 0.40), 4, 1))
	var type_lbl := type_tag.get_node("TypeLabel") as Label
	type_lbl.text = sk_type
	type_lbl.add_theme_color_override("font_color", Color(type_col.r + 0.05, type_col.g + 0.05, type_col.b + 0.05, 1.0))

	var name_lbl := card.get_node("NameLabel") as Label
	name_lbl.text = str(sk.get("name", ""))

	var desc_short: String = str(sk.get("desc_short", ""))
	if desc_short == "":
		desc_short = str(sk.get("desc", "")).split("\n")[0]
	var desc_lbl := card.get_node("DescLabel") as Label
	desc_lbl.text = desc_short
	desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95, 0.70))
	desc_lbl.visible = desc_short != ""

	var more_lbl := card.get_node("MoreLabel") as Label
	more_lbl.add_theme_color_override("font_color", Color(type_col.r, type_col.g, type_col.b, 0.65))

	if not card.has_meta("_wired"):
		card.set_meta("_wired", true)
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_show_skill_detail(card.get_meta("_sk", {}), card.get_meta("_type_col", Color.WHITE), card.get_meta("_icon_path", ""))
		)
	card.set_meta("_sk", sk)
	card.set_meta("_type_col", type_col)
	card.set_meta("_icon_path", icon_path)

func _skill_type_color(sk_type: String) -> Color:
	match sk_type:
		"Basic ATK": return Color(0.55, 0.85, 1.00)
		"Defend":    return Color(0.45, 0.90, 0.65)
		"Skill":     return Color(0.80, 0.55, 1.00)
		"Ultimate":  return Color(1.00, 0.72, 0.28)
		"Passive":   return Color(0.65, 0.80, 0.55)
		_:           return Color(0.70, 0.75, 0.85)

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

# ── Skill detail popup (tap a skill card to see the full description) ──
# Kept as runtime-generated: this is a transient modal, not persistent
# scene structure, so instancing it on demand is the appropriate pattern.
func _show_skill_detail(sk: Dictionary, type_col: Color, icon_path: String) -> void:
	if get_node_or_null("_SkillDetailOv") != null:
		return

	var dim := ColorRect.new()
	dim.name = "_SkillDetailOv"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 60
	add_child(dim)
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			dim.queue_free()
	)

	var bw := 520.0; var bh := 400.0
	var box := Panel.new()
	box.size = Vector2(bw, bh)
	box.position = Vector2((VW - bw) * 0.5, (VH - bh) * 0.5)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_theme_stylebox_override("panel",
		_flat(Color(0.05, 0.06, 0.12, 0.98), Color(type_col.r, type_col.g, type_col.b, 0.5), 14, 1))
	dim.add_child(box)
	box.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			get_viewport().set_input_as_handled()
	)

	var icon_sz := 56.0
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon_bg := Panel.new()
		icon_bg.size = Vector2(icon_sz, icon_sz)
		icon_bg.position = Vector2(20, 20)
		icon_bg.clip_contents = true
		icon_bg.add_theme_stylebox_override("panel",
			_flat(Color(type_col.r * 0.15, type_col.g * 0.15, type_col.b * 0.25, 0.95),
				Color(type_col.r, type_col.g, type_col.b, 0.45), 8, 1))
		box.add_child(icon_bg)
		var ico := TextureRect.new()
		ico.texture      = load(icon_path)
		ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		ico.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var ico_mat := CanvasItemMaterial.new()
		ico_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		ico.material = ico_mat
		icon_bg.add_child(ico)

	var name_lbl := _lbl(str(sk.get("name", "")), 18, C_TEXT)
	name_lbl.position = Vector2(20 + icon_sz + 14, 22)
	name_lbl.size = Vector2(bw - icon_sz - 54, 24)
	box.add_child(name_lbl)

	var type_lbl := _lbl(str(sk.get("type", "")), 11, Color(type_col.r, type_col.g, type_col.b, 0.9))
	type_lbl.position = Vector2(20 + icon_sz + 14, 50)
	type_lbl.size = Vector2(bw - icon_sz - 54, 18)
	box.add_child(type_lbl)

	box.add_child(_crect(Vector2(20, 20 + icon_sz + 14), Vector2(bw - 40, 1),
		Color(type_col.r, type_col.g, type_col.b, 0.2)))

	var desc_clip := Control.new()
	desc_clip.position = Vector2(20, 20 + icon_sz + 26)
	desc_clip.size = Vector2(bw - 40, bh - icon_sz - 100)
	desc_clip.clip_contents = true
	desc_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(desc_clip)

	var desc_lbl := _lbl(str(sk.get("desc", "")), 12, Color(0.85, 0.90, 1.0, 0.90))
	desc_lbl.position = Vector2(0, 0)
	# Fixed width forces the wrap point; custom_minimum_size must match or a
	# Label outside a Container can still report its unwrapped natural size
	# as its effective minimum and paint past the given rect on some lines.
	desc_lbl.custom_minimum_size = Vector2(desc_clip.size.x, 0)
	desc_lbl.size = Vector2(desc_clip.size.x, desc_clip.size.y + 80)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_clip.add_child(desc_lbl)

	var close_btn := Button.new()
	close_btn.text = "ปิด"
	close_btn.size = Vector2(90, 34)
	close_btn.position = Vector2((bw - 90) * 0.5, bh - 46)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.add_theme_color_override("font_color", Color(type_col.r + 0.1, type_col.g + 0.1, type_col.b + 0.1, 1.0))
	var close_sb := _flat(Color(type_col.r * 0.18, type_col.g * 0.18, type_col.b * 0.30, 0.95),
		Color(type_col.r, type_col.g, type_col.b, 0.55), 8, 1)
	for s in ["normal", "hover", "pressed"]:
		close_btn.add_theme_stylebox_override(s, close_sb)
	close_btn.pressed.connect(func(): dim.queue_free())
	box.add_child(close_btn)

	var t := dim.create_tween()
	t.tween_property(dim, "color:a", 0.65, 0.15)

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
