extends Control

const SC_MAIN := "res://main_menu.tscn"

# ── Character data ────────────────────────────────────────────────
const CHARACTER := {
	"name":    "Alchemist",
	"title":   "Master of Reactions",
	"element": "⚗",
	"element_color": Color(0.35, 0.75, 1.0),
	"rarity":  5,
	"level":   42,
	"max_level": 80,
	"faction": "Alchemist Guild",
	"lore":    "นักเล่นแร่แปรธาตุผู้เชี่ยวชาญในการรวมธาตุและสร้างปฏิกิริยาเคมีที่ทรงพลัง\nความลับของสูตรที่สมบูรณ์... ยังรอการค้นพบ",
	"stats": {
		"HP":  {"val": 4280, "max": 6500, "icon": "❤"},
		"ATK": {"val": 2140, "max": 3200, "icon": "⚔"},
		"DEF": {"val": 1050, "max": 1800, "icon": "🛡"},
		"SPD": {"val":  98,  "max": 160,  "icon": "💨"},
		"CRIT Rate":  {"val": 52,  "max": 100, "icon": "✦", "pct": true},
		"CRIT DMG":   {"val": 118, "max": 300, "icon": "💥", "pct": true},
	},
	"passive": {
		"name": "Reaction Master",
		"desc": "เมื่อสังเคราะห์สารประกอบสำเร็จ Ultimate Gauge ชาร์จ +10\nและสถานะเชิงลบที่ปล่อยออกไปมีพลังเพิ่มขึ้น 15%",
	},
	"skills": [
		{
			"key": "Basic",
			"icon": "⚗",
			"name": "Alchemical Strike",
			"type": "Basic ATK",
			"desc": "โจมตีศัตรู 1 เป้าหมายด้วยพลังธาตุ\nสร้างความเสียหาย 20 และชาร์จ Ultimate +15",
			"value": "20 DMG",
			"color": Color(0.55, 0.85, 1.0),
		},
		{
			"key": "Skill",
			"icon": "⚡",
			"name": "Power Strike",
			"type": "Skill  ·  CD 2",
			"desc": "ปล่อยพลังรวมทุกธาตุโจมตีศัตรู\nสร้างความเสียหาย 40 ลดการโจมตีศัตรู 1 รอบ",
			"value": "40 DMG",
			"color": Color(0.9, 0.65, 1.0),
		},
		{
			"key": "Ultimate",
			"icon": "💥",
			"name": "Element Burst",
			"type": "Ultimate  ·  100 Gauge",
			"desc": "ปลดปล่อยพลังธาตุทั้งหมดออกมาพร้อมกัน\nสร้างความเสียหาย 60 และวางพิษ+เผาไหม้ศัตรู",
			"value": "60 DMG",
			"color": Color(1.0, 0.75, 0.25),
		},
		{
			"key": "Passive",
			"icon": "🔮",
			"name": "Reaction Master",
			"type": "Passive",
			"desc": "เมื่อสังเคราะห์สารประกอบสำเร็จ\nUltimate Gauge ชาร์จ +10 พิษ/เผาไหม้ +15%",
			"value": "Passive",
			"color": Color(0.4, 1.0, 0.7),
		},
	],
	"eidolons": [
		{"name": "สูตรที่ 1", "desc": "พิษจาก Rust เพิ่ม +3 ต่อรอบ",           "unlocked": true},
		{"name": "สูตรที่ 2", "desc": "Skill Cooldown ลดลง 1 รอบ",              "unlocked": true},
		{"name": "สูตรที่ 3", "desc": "Ultimate Burst ระเบิดพื้นที่กว้างขึ้น", "unlocked": false},
		{"name": "สูตรที่ 4", "desc": "Water Heal เพิ่มเป็น +35 HP",            "unlocked": false},
		{"name": "สูตรที่ 5", "desc": "เพิ่มพลัง ATK 20% เมื่อ HP < 50%",      "unlocked": false},
		{"name": "สูตรที่ 6", "desc": "Ultimate ไม่มี Gauge หลังจากใช้ 1 ครั้ง","unlocked": false},
	],
}

# ── Colors ────────────────────────────────────────────────────────
const C_BG     := Color(0.04, 0.045, 0.10, 1.0)
const C_PANEL  := Color(0.07, 0.09,  0.17, 1.0)
const C_BORDER := Color(0.22, 0.50,  0.90, 0.25)
const C_TEXT   := Color(0.90, 0.93,  1.0,  1.0)
const C_SUB    := Color(0.55, 0.68,  0.90, 0.75)
const C_GOLD   := Color(1.00, 0.82,  0.25, 1.0)

var _selected_skill: int = -1
var _skill_desc_lbl: Label
var _skill_name_lbl: Label
var _skill_type_lbl: Label
var _skill_val_lbl:  Label
var _skill_btns: Array[Panel] = []

func _ready() -> void:
	_build_ui()

# ════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	# BG gradient
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Element color glow behind character area
	var glow := ColorRect.new()
	glow.color = Color(CHARACTER["element_color"].r,
					   CHARACTER["element_color"].g,
					   CHARACTER["element_color"].b, 0.06)
	glow.size     = Vector2(520, 648)
	glow.position = Vector2(0, 0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	_build_header()
	_build_char_art_panel()
	_build_stats_panel()
	_build_skill_row()
	_build_eidolon_panel()

# ── Header ────────────────────────────────────────────────────────
func _build_header() -> void:
	var hdr := Panel.new()
	hdr.size = Vector2(1152, 52)
	hdr.add_theme_stylebox_override("panel", _flat(Color(0.04, 0.05, 0.12, 0.92), C_BORDER, 0, 1))
	add_child(hdr)

	var back := Button.new()
	back.text = "← BACK"
	back.size = Vector2(80, 36)
	back.position = Vector2(10, 8)
	back.add_theme_font_size_override("font_size", 13)
	back.add_theme_color_override("font_color", C_SUB)
	for s in ["normal","hover","pressed","focus"]:
		back.add_theme_stylebox_override(s, _flat(Color(0,0,0,0), Color(0,0,0,0)))
	back.pressed.connect(_go_back)
	hdr.add_child(back)

	var title := Label.new()
	title.text = "CHARACTER"
	title.position = Vector2(110, 14)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", C_TEXT)
	hdr.add_child(title)

# ── Left: Character art panel ──────────────────────────────────────
func _build_char_art_panel() -> void:
	# Art placeholder panel
	var art_bg := Panel.new()
	art_bg.size = Vector2(480, 480)
	art_bg.position = Vector2(20, 60)
	art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_bg.add_theme_stylebox_override("panel", _flat(Color(0,0,0,0), Color(0,0,0,0)))
	add_child(art_bg)

	# Placeholder art circle (replace with TextureRect later)
	var circle := Panel.new()
	circle.size = Vector2(280, 280)
	circle.position = Vector2(100, 80)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var el_col: Color = CHARACTER["element_color"]
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(el_col.r * 0.15, el_col.g * 0.15, el_col.b * 0.2, 1.0)
	sb.border_color = Color(el_col.r, el_col.g, el_col.b, 0.5)
	sb.corner_radius_top_left     = 140
	sb.corner_radius_top_right    = 140
	sb.corner_radius_bottom_right = 140
	sb.corner_radius_bottom_left  = 140
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	circle.add_theme_stylebox_override("panel", sb)
	art_bg.add_child(circle)

	var icon_lbl := Label.new()
	icon_lbl.text = CHARACTER["element"]
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 80)
	icon_lbl.add_theme_color_override("font_color", Color(el_col.r, el_col.g, el_col.b, 0.7))
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(icon_lbl)

	# Name + title
	var name_lbl := Label.new()
	name_lbl.text = CHARACTER["name"]
	name_lbl.position = Vector2(0, 374)
	name_lbl.size = Vector2(480, 40)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	art_bg.add_child(name_lbl)

	var title_lbl := Label.new()
	title_lbl.text = CHARACTER["title"]
	title_lbl.position = Vector2(0, 408)
	title_lbl.size = Vector2(480, 24)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color(el_col.r, el_col.g, el_col.b, 0.85))
	art_bg.add_child(title_lbl)

	# Stars
	var stars := Label.new()
	stars.text = "★".repeat(CHARACTER["rarity"])
	stars.position = Vector2(0, 432)
	stars.size = Vector2(480, 24)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 18)
	stars.add_theme_color_override("font_color", C_GOLD)
	art_bg.add_child(stars)

	# Element badge
	var badge := Panel.new()
	badge.size = Vector2(40, 40)
	badge.position = Vector2(20, 20)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _flat(
		Color(el_col.r * 0.2, el_col.g * 0.2, el_col.b * 0.3, 0.9),
		Color(el_col.r, el_col.g, el_col.b, 0.7), 20, 1
	))
	art_bg.add_child(badge)
	var badge_lbl := Label.new()
	badge_lbl.text = CHARACTER["element"]
	badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	badge_lbl.add_theme_font_size_override("font_size", 18)
	badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_lbl)

	# Level badge
	var lv_bg := Panel.new()
	lv_bg.size = Vector2(80, 28)
	lv_bg.position = Vector2(68, 26)
	lv_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv_bg.add_theme_stylebox_override("panel", _flat(Color(0.1, 0.12, 0.22, 0.9), C_BORDER, 6, 1))
	art_bg.add_child(lv_bg)
	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d" % CHARACTER["level"]
	lv_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lv_lbl.add_theme_font_size_override("font_size", 12)
	lv_lbl.add_theme_color_override("font_color", C_TEXT)
	lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv_bg.add_child(lv_lbl)

# ── Right: Stats panel ─────────────────────────────────────────────
func _build_stats_panel() -> void:
	var panel := Panel.new()
	panel.size = Vector2(390, 310)
	panel.position = Vector2(520, 60)
	panel.add_theme_stylebox_override("panel", _flat(C_PANEL, C_BORDER, 10, 1))
	add_child(panel)

	var sec := Label.new()
	sec.text = "STATS"
	sec.position = Vector2(16, 12)
	sec.add_theme_font_size_override("font_size", 11)
	sec.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(sec)

	var div := ColorRect.new()
	div.color = C_BORDER
	div.size = Vector2(358, 1)
	div.position = Vector2(16, 30)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	var y := 42.0
	for stat_key in CHARACTER["stats"]:
		var stat: Dictionary = CHARACTER["stats"][stat_key]
		var is_pct: bool = stat.get("pct", false)
		var val: float = stat["val"]
		var mx: float  = stat["max"]

		# Icon + name
		var row_icon := Label.new()
		row_icon.text = stat["icon"]
		row_icon.position = Vector2(16, y)
		row_icon.add_theme_font_size_override("font_size", 13)
		panel.add_child(row_icon)

		var name_lbl := Label.new()
		name_lbl.text = stat_key
		name_lbl.position = Vector2(36, y + 1)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", C_SUB)
		panel.add_child(name_lbl)

		# Value
		var val_lbl := Label.new()
		val_lbl.text = "%d%s" % [int(val), "%" if is_pct else ""]
		val_lbl.position = Vector2(290, y + 1)
		val_lbl.size = Vector2(80, 18)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", 13)
		val_lbl.add_theme_color_override("font_color", C_TEXT)
		panel.add_child(val_lbl)

		# Bar bg
		var bar_bg := ColorRect.new()
		bar_bg.color = Color(1, 1, 1, 0.07)
		bar_bg.size = Vector2(358, 4)
		bar_bg.position = Vector2(16, y + 22)
		panel.add_child(bar_bg)

		var el_col: Color = CHARACTER["element_color"]
		var fill := ColorRect.new()
		fill.color = Color(el_col.r, el_col.g, el_col.b, 0.75)
		fill.size = Vector2(358.0 * (val / mx), 4)
		fill.position = Vector2(16, y + 22)
		panel.add_child(fill)

		y += 44.0

	# Passive box
	var pass_panel := Panel.new()
	pass_panel.size = Vector2(390, 68)
	pass_panel.position = Vector2(520, 378)
	var el_col2: Color = CHARACTER["element_color"]
	pass_panel.add_theme_stylebox_override("panel", _flat(
		Color(el_col2.r * 0.10, el_col2.g * 0.10, el_col2.b * 0.16, 1.0),
		Color(el_col2.r, el_col2.g, el_col2.b, 0.3), 10, 1
	))
	add_child(pass_panel)

	var pass_title := Label.new()
	pass_title.text = "✦ " + CHARACTER["passive"]["name"]
	pass_title.position = Vector2(14, 10)
	pass_title.add_theme_font_size_override("font_size", 12)
	pass_title.add_theme_color_override("font_color", Color(el_col2.r, el_col2.g, el_col2.b, 1.0))
	pass_panel.add_child(pass_title)

	var pass_desc := Label.new()
	pass_desc.text = CHARACTER["passive"]["desc"].split("\n")[0]
	pass_desc.position = Vector2(14, 30)
	pass_desc.size = Vector2(362, 32)
	pass_desc.add_theme_font_size_override("font_size", 10)
	pass_desc.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 0.8))
	pass_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pass_panel.add_child(pass_desc)

# ── Bottom: Skill row ──────────────────────────────────────────────
func _build_skill_row() -> void:
	var skills: Array = CHARACTER["skills"]
	var btn_size := Vector2(80, 80)
	var start_x := 20.0
	var row_y   := 552.0
	var spacing := 90.0

	# Skill detail panel (right side)
	var detail := Panel.new()
	detail.size = Vector2(570, 88)
	detail.position = Vector2(start_x + skills.size() * spacing + 10, row_y - 4)
	detail.add_theme_stylebox_override("panel", _flat(C_PANEL, C_BORDER, 10, 1))
	add_child(detail)

	_skill_name_lbl = Label.new()
	_skill_name_lbl.position = Vector2(14, 10)
	_skill_name_lbl.add_theme_font_size_override("font_size", 14)
	_skill_name_lbl.add_theme_color_override("font_color", C_TEXT)
	_skill_name_lbl.text = "← เลือก Skill"
	detail.add_child(_skill_name_lbl)

	_skill_type_lbl = Label.new()
	_skill_type_lbl.position = Vector2(14, 30)
	_skill_type_lbl.add_theme_font_size_override("font_size", 10)
	_skill_type_lbl.add_theme_color_override("font_color", C_SUB)
	detail.add_child(_skill_type_lbl)

	_skill_desc_lbl = Label.new()
	_skill_desc_lbl.position = Vector2(14, 46)
	_skill_desc_lbl.size = Vector2(542, 36)
	_skill_desc_lbl.add_theme_font_size_override("font_size", 10)
	_skill_desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 0.85))
	_skill_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_skill_desc_lbl)

	_skill_val_lbl = Label.new()
	_skill_val_lbl.position = Vector2(490, 10)
	_skill_val_lbl.size = Vector2(70, 20)
	_skill_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skill_val_lbl.add_theme_font_size_override("font_size", 12)
	_skill_val_lbl.add_theme_color_override("font_color", C_GOLD)
	detail.add_child(_skill_val_lbl)

	# Skill buttons
	for i in skills.size():
		var skill: Dictionary = skills[i]
		var col: Color = skill["color"]

		var btn := Panel.new()
		btn.size = btn_size
		btn.position = Vector2(start_x + i * spacing, row_y)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.add_theme_stylebox_override("panel", _flat(
			Color(col.r * 0.12, col.g * 0.12, col.b * 0.18, 1.0),
			Color(col.r, col.g, col.b, 0.45), 12, 1
		))
		add_child(btn)
		_skill_btns.append(btn)

		var icon_lbl := Label.new()
		icon_lbl.text = skill["icon"]
		icon_lbl.position = Vector2(0, 10)
		icon_lbl.size = Vector2(80, 36)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 24)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_lbl)

		var key_lbl := Label.new()
		key_lbl.text = skill["key"]
		key_lbl.position = Vector2(0, 50)
		key_lbl.size = Vector2(80, 20)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.add_theme_font_size_override("font_size", 9)
		key_lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.8))
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(key_lbl)

		btn.gui_input.connect(_on_skill_btn.bind(i))

# ── Right: Eidolon panel ───────────────────────────────────────────
func _build_eidolon_panel() -> void:
	var panel := Panel.new()
	panel.size = Vector2(220, 310)
	panel.position = Vector2(920, 60)
	panel.add_theme_stylebox_override("panel", _flat(C_PANEL, C_BORDER, 10, 1))
	add_child(panel)

	var title := Label.new()
	title.text = "RESONANCE"
	title.position = Vector2(14, 12)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(title)

	var div := ColorRect.new()
	div.color = C_BORDER
	div.size = Vector2(192, 1)
	div.position = Vector2(14, 30)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	var eidolons: Array = CHARACTER["eidolons"]
	var el_col: Color = CHARACTER["element_color"]
	var y := 42.0
	for i in eidolons.size():
		var e: Dictionary = eidolons[i]
		var unlocked: bool = e["unlocked"]

		var dot := Panel.new()
		dot.size = Vector2(20, 20)
		dot.position = Vector2(14, y + 2)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot_col := Color(el_col.r, el_col.g, el_col.b, 0.9) if unlocked else Color(0.25, 0.28, 0.4, 1.0)
		dot.add_theme_stylebox_override("panel", _flat(dot_col, Color(0,0,0,0), 10))
		panel.add_child(dot)

		var num := Label.new()
		num.text = str(i + 1)
		num.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		num.add_theme_font_size_override("font_size", 9)
		num.add_theme_color_override("font_color", Color(1,1,1,0.9) if unlocked else Color(0.4,0.45,0.6))
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(num)

		var e_lbl := Label.new()
		e_lbl.text = e["desc"]
		e_lbl.position = Vector2(40, y)
		e_lbl.size = Vector2(172, 40)
		e_lbl.add_theme_font_size_override("font_size", 9)
		e_lbl.add_theme_color_override("font_color",
			Color(0.85, 0.92, 1.0, 0.9) if unlocked else Color(0.35, 0.38, 0.52, 0.7)
		)
		e_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(e_lbl)

		y += 42.0

# ── Skill button handler ──────────────────────────────────────────
func _on_skill_btn(ev: InputEvent, idx: int) -> void:
	if not (ev is InputEventMouseButton and ev.pressed):
		return
	_selected_skill = idx
	var skill: Dictionary = CHARACTER["skills"][idx]
	var col: Color = skill["color"]

	_skill_name_lbl.text = skill["name"]
	_skill_name_lbl.add_theme_color_override("font_color", col)
	_skill_type_lbl.text = skill["type"]
	_skill_desc_lbl.text = skill["desc"]
	_skill_val_lbl.text  = skill["value"]

	for i in _skill_btns.size():
		var s: Dictionary = CHARACTER["skills"][i]
		var sc: Color = s["color"]
		var active := (i == idx)
		_skill_btns[i].add_theme_stylebox_override("panel", _flat(
			Color(sc.r * 0.20, sc.g * 0.20, sc.b * 0.28, 1.0) if active else Color(sc.r * 0.12, sc.g * 0.12, sc.b * 0.18, 1.0),
			Color(sc.r, sc.g, sc.b, 0.9 if active else 0.45), 12, 2 if active else 1
		))

# ── Helpers ───────────────────────────────────────────────────────
func _flat(col: Color, border: Color = Color(0,0,0,0), r: int = 8, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color    = col
	sb.border_color = border
	sb.corner_radius_top_left     = r
	sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_right = r
	sb.corner_radius_bottom_left  = r
	sb.border_width_left   = bw
	sb.border_width_right  = bw
	sb.border_width_top    = bw
	sb.border_width_bottom = bw
	return sb

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
