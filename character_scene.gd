extends Control

const SC_ROSTER := "res://character_roster.tscn"

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
			"desc": "โจมตีศัตรู 1 เป้าหมายด้วยพลังธาตุ สร้างความเสียหาย 20 และชาร์จ Ultimate +15",
			"value": "20 DMG",
			"color": Color(0.55, 0.85, 1.0),
		},
		{
			"key": "Skill",
			"icon": "⚡",
			"name": "Power Strike",
			"type": "Skill  ·  CD 2",
			"desc": "ปล่อยพลังรวมทุกธาตุโจมตีศัตรู สร้างความเสียหาย 40 ลดการโจมตีศัตรู 1 รอบ",
			"value": "40 DMG",
			"color": Color(0.9, 0.65, 1.0),
		},
		{
			"key": "Ultimate",
			"icon": "💥",
			"name": "Element Burst",
			"type": "Ultimate  ·  100 Gauge",
			"desc": "ปลดปล่อยพลังธาตุทั้งหมดออกมาพร้อมกัน สร้างความเสียหาย 60 และวางพิษ+เผาไหม้ศัตรู",
			"value": "60 DMG",
			"color": Color(1.0, 0.75, 0.25),
		},
		{
			"key": "Passive",
			"icon": "🔮",
			"name": "Reaction Master",
			"type": "Passive",
			"desc": "เมื่อสังเคราะห์สารประกอบสำเร็จ Ultimate Gauge ชาร์จ +10 พิษ/เผาไหม้ +15%",
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

# ── Layout constants ──────────────────────────────────────────────
const ART_W    := 575   # art column width
const PANEL_X  := 582   # right panel x
const PANEL_W  := 570   # right panel width
const HDR_H    := 72    # header height inside right panel
const TAB_H    := 44    # tab bar height
const CONTENT_Y := 124  # content area start y (HDR_H + TAB_H + 8)

# ── Colors ────────────────────────────────────────────────────────
const C_BG     := Color(0.030, 0.032, 0.068, 1.0)
const C_PANEL  := Color(0.048, 0.055, 0.118, 1.0)
const C_PANEL2 := Color(0.038, 0.044, 0.096, 1.0)
const C_BORDER := Color(0.22, 0.48, 0.92, 0.22)
const C_TEXT   := Color(0.92, 0.94, 1.00, 1.0)
const C_SUB    := Color(0.55, 0.68, 0.88, 0.72)
const C_GOLD   := Color(1.00, 0.84, 0.28, 1.0)
const C_LOCK   := Color(0.22, 0.25, 0.38, 1.0)

enum Tab { SKILLS, RESONANCE, INFO }
var _cur_tab: Tab = Tab.SKILLS
var _tab_btns: Array[Button] = []
var _tab_pages: Array[Control] = []

var _sel_skill: int = 0
var _skill_btns: Array[Panel] = []
var _skill_name_lbl: Label
var _skill_type_lbl: Label
var _skill_desc_lbl: Label
var _skill_val_lbl:  Label

func _ready() -> void:
	_build_ui()

# ════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	# Base bg
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_art_column()
	_build_right_panel()
	_build_fade_in()

# ── Art column (left) ─────────────────────────────────────────────
func _build_art_column() -> void:
	var el: Color = CHARACTER["element_color"]

	# Subtle element glow strip behind art
	var glow := ColorRect.new()
	glow.size = Vector2(ART_W + 60, 648)
	glow.position = Vector2(0, 0)
	glow.color = Color(el.r * 0.06, el.g * 0.07, el.b * 0.14, 1.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	# Diagonal accent lines (Honkai style)
	for i in 4:
		var line := ColorRect.new()
		line.size = Vector2(1, 648)
		line.position = Vector2(40 + i * 130, 0)
		line.color = Color(el.r, el.g, el.b, 0.03 + i * 0.01)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)

	# Art placeholder (full height, no top crop)
	var art_bg := Panel.new()
	art_bg.size = Vector2(ART_W, 648)
	art_bg.position = Vector2(0, 0)
	art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_bg.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	add_child(art_bg)

	# Large element emoji as art placeholder
	var art_lbl := Label.new()
	art_lbl.text = CHARACTER["element"]
	art_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_lbl.offset_top = -80
	art_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	art_lbl.add_theme_font_size_override("font_size", 160)
	art_lbl.add_theme_color_override("font_color", Color(el.r, el.g, el.b, 0.12))
	art_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_bg.add_child(art_lbl)

	# Bottom gradient fade-out
	for i in 5:
		var grad := ColorRect.new()
		grad.size = Vector2(ART_W, 80)
		grad.position = Vector2(0, 648 - (i + 1) * 80)
		grad.color = Color(C_BG.r, C_BG.g, C_BG.b, 0.08 * (i + 1))
		grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(grad)

	# Vertical separator line (element colored)
	var sep := ColorRect.new()
	sep.size = Vector2(1, 648)
	sep.position = Vector2(ART_W - 1, 0)
	sep.color = Color(el.r, el.g, el.b, 0.18)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	# ── Bottom info overlay ───────────────────────────────────────
	# Name (large, Honkai style — bottom-left)
	var name_lbl := Label.new()
	name_lbl.text = CHARACTER["name"].to_upper()
	name_lbl.position = Vector2(24, 520)
	name_lbl.size = Vector2(ART_W - 40, 48)
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_lbl)

	# Title / subtitle
	var title_lbl := Label.new()
	title_lbl.text = CHARACTER["title"]
	title_lbl.position = Vector2(26, 562)
	title_lbl.size = Vector2(ART_W - 40, 22)
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(el.r, el.g, el.b, 0.90))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_lbl)

	# Stars row
	var stars_lbl := Label.new()
	stars_lbl.text = "★".repeat(CHARACTER["rarity"])
	stars_lbl.position = Vector2(24, 586)
	stars_lbl.size = Vector2(200, 22)
	stars_lbl.add_theme_font_size_override("font_size", 16)
	stars_lbl.add_theme_color_override("font_color", C_GOLD)
	stars_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stars_lbl)

	# Element badge (top-left corner)
	var badge := Panel.new()
	badge.size = Vector2(44, 44)
	badge.position = Vector2(16, 16)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _flat(
		Color(el.r * 0.18, el.g * 0.20, el.b * 0.28, 0.95),
		Color(el.r, el.g, el.b, 0.6), 22, 1
	))
	add_child(badge)
	var badge_lbl := Label.new()
	badge_lbl.text = CHARACTER["element"]
	badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	badge_lbl.add_theme_font_size_override("font_size", 20)
	badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_lbl)

	# Faction label under badge
	var faction_lbl := Label.new()
	faction_lbl.text = CHARACTER["faction"]
	faction_lbl.position = Vector2(68, 22)
	faction_lbl.add_theme_font_size_override("font_size", 10)
	faction_lbl.add_theme_color_override("font_color", C_SUB)
	faction_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(faction_lbl)

# ── Right panel ───────────────────────────────────────────────────
func _build_right_panel() -> void:
	var el: Color = CHARACTER["element_color"]

	# Panel background
	var panel_bg := ColorRect.new()
	panel_bg.size = Vector2(PANEL_W, 648)
	panel_bg.position = Vector2(PANEL_X, 0)
	panel_bg.color = Color(C_PANEL.r, C_PANEL.g, C_PANEL.b, 0.97)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_bg)

	# ── Header: name, level, back btn ────────────────────────────
	var hdr := ColorRect.new()
	hdr.size = Vector2(PANEL_W, HDR_H)
	hdr.position = Vector2(PANEL_X, 0)
	hdr.color = Color(C_PANEL2.r, C_PANEL2.g, C_PANEL2.b, 1.0)
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hdr)

	# Horizontal accent line under header (element color)
	var hdr_line := ColorRect.new()
	hdr_line.size = Vector2(PANEL_W, 2)
	hdr_line.position = Vector2(PANEL_X, HDR_H)
	hdr_line.color = Color(el.r, el.g, el.b, 0.55)
	hdr_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hdr_line)

	# Back button
	var back := Button.new()
	back.text = "‹ Back"
	back.size = Vector2(70, 36)
	back.position = Vector2(PANEL_X + 10, 18)
	back.add_theme_font_size_override("font_size", 13)
	back.add_theme_color_override("font_color", C_SUB)
	for s in ["normal","hover","pressed","focus"]:
		back.add_theme_stylebox_override(s, _flat(Color(0,0,0,0), Color(0,0,0,0)))
	back.pressed.connect(_go_back)
	add_child(back)

	# Character name (header)
	var h_name := Label.new()
	h_name.text = CHARACTER["name"]
	h_name.position = Vector2(PANEL_X + 88, 8)
	h_name.add_theme_font_size_override("font_size", 22)
	h_name.add_theme_color_override("font_color", C_TEXT)
	h_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h_name)

	# Faction small
	var h_faction := Label.new()
	h_faction.text = CHARACTER["faction"]
	h_faction.position = Vector2(PANEL_X + 90, 34)
	h_faction.add_theme_font_size_override("font_size", 10)
	h_faction.add_theme_color_override("font_color", C_SUB)
	h_faction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h_faction)

	# Level pill (header right)
	var lv_pill := Panel.new()
	lv_pill.size = Vector2(100, 30)
	lv_pill.position = Vector2(PANEL_X + PANEL_W - 116, 20)
	lv_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv_pill.add_theme_stylebox_override("panel", _flat(
		Color(el.r * 0.15, el.g * 0.15, el.b * 0.22, 1.0),
		Color(el.r, el.g, el.b, 0.4), 6, 1
	))
	add_child(lv_pill)
	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d / %d" % [CHARACTER["level"], CHARACTER["max_level"]]
	lv_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lv_lbl.add_theme_font_size_override("font_size", 11)
	lv_lbl.add_theme_color_override("font_color", Color(el.r, el.g, el.b, 1.0))
	lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv_pill.add_child(lv_lbl)

	# ── Tab bar ───────────────────────────────────────────────────
	var tab_labels := ["Skills", "Resonance", "Info"]
	var tab_bar := Control.new()
	tab_bar.size = Vector2(PANEL_W, TAB_H)
	tab_bar.position = Vector2(PANEL_X, HDR_H + 2)
	tab_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tab_bar)

	var tab_bg := ColorRect.new()
	tab_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tab_bg.color = Color(C_PANEL2.r, C_PANEL2.g, C_PANEL2.b, 0.8)
	tab_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_bar.add_child(tab_bg)

	for i in tab_labels.size():
		var btn := Button.new()
		btn.text = tab_labels[i]
		btn.size = Vector2(PANEL_W / 3.0, TAB_H)
		btn.position = Vector2(i * (PANEL_W / 3.0), 0)
		btn.add_theme_font_size_override("font_size", 12)
		for s in ["normal","hover","pressed","focus"]:
			btn.add_theme_stylebox_override(s, _flat(Color(0,0,0,0), Color(0,0,0,0)))
		tab_bar.add_child(btn)
		_tab_btns.append(btn)
		btn.pressed.connect(_switch_tab.bind(i))

	# ── Tab pages ─────────────────────────────────────────────────
	var pages_y := HDR_H + 2 + TAB_H + 2
	var pages_h := 648 - pages_y

	for _i in 3:
		var page := Control.new()
		page.size = Vector2(PANEL_W, pages_h)
		page.position = Vector2(PANEL_X, pages_y)
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.visible = false
		add_child(page)
		_tab_pages.append(page)

	_build_skills_page(_tab_pages[0])
	_build_resonance_page(_tab_pages[1])
	_build_info_page(_tab_pages[2])

	_switch_tab(0)

# ── Tab: Skills ───────────────────────────────────────────────────
func _build_skills_page(page: Control) -> void:
	var skills: Array = CHARACTER["skills"]
	var ph := page.size.y  # available height ~482

	# Skill icon row (top ~110px)
	var btn_sz := Vector2(100, 100)
	var total_w := skills.size() * btn_sz.x + (skills.size() - 1) * 12
	var row_x := (PANEL_W - total_w) / 2.0

	for i in skills.size():
		var sk: Dictionary = skills[i]
		var col: Color = sk["color"]
		var bx := row_x + i * (btn_sz.x + 12)

		var btn := Panel.new()
		btn.size = btn_sz
		btn.position = Vector2(bx, 14)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.add_theme_stylebox_override("panel", _flat(
			Color(col.r * 0.10, col.g * 0.10, col.b * 0.16, 1.0),
			Color(col.r, col.g, col.b, 0.35), 14, 1
		))
		page.add_child(btn)
		_skill_btns.append(btn)

		# Icon
		var icon_lbl := Label.new()
		icon_lbl.text = sk["icon"]
		icon_lbl.position = Vector2(0, 12)
		icon_lbl.size = Vector2(btn_sz.x, 40)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 28)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_lbl)

		# Key label (bottom)
		var key_lbl := Label.new()
		key_lbl.text = sk["key"]
		key_lbl.position = Vector2(0, 60)
		key_lbl.size = Vector2(btn_sz.x, 18)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.add_theme_font_size_override("font_size", 10)
		key_lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.85))
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(key_lbl)

		# Level badge
		var lv_bg := Panel.new()
		lv_bg.size = Vector2(28, 16)
		lv_bg.position = Vector2(btn_sz.x - 30, btn_sz.y - 20)
		lv_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lv_bg.add_theme_stylebox_override("panel", _flat(Color(0.08, 0.10, 0.20, 0.95), Color(col.r, col.g, col.b, 0.4), 4, 1))
		btn.add_child(lv_bg)
		var lv_lbl := Label.new()
		lv_lbl.text = "Lv1"
		lv_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lv_lbl.add_theme_font_size_override("font_size", 7)
		lv_lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.9))
		lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lv_bg.add_child(lv_lbl)

		btn.gui_input.connect(_on_skill_btn.bind(i))

	# Divider
	var div := ColorRect.new()
	div.size = Vector2(PANEL_W - 32, 1)
	div.position = Vector2(16, 126)
	div.color = C_BORDER
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(div)

	# Detail panel (rest of height)
	var detail := Panel.new()
	detail.size = Vector2(PANEL_W - 24, ph - 140)
	detail.position = Vector2(12, 136)
	detail.add_theme_stylebox_override("panel", _flat(C_PANEL2, C_BORDER, 10, 1))
	page.add_child(detail)

	# Skill name
	_skill_name_lbl = Label.new()
	_skill_name_lbl.position = Vector2(16, 16)
	_skill_name_lbl.size = Vector2(PANEL_W - 80, 28)
	_skill_name_lbl.add_theme_font_size_override("font_size", 17)
	_skill_name_lbl.add_theme_color_override("font_color", C_TEXT)
	detail.add_child(_skill_name_lbl)

	# Skill type
	_skill_type_lbl = Label.new()
	_skill_type_lbl.position = Vector2(16, 46)
	_skill_type_lbl.size = Vector2(PANEL_W - 80, 18)
	_skill_type_lbl.add_theme_font_size_override("font_size", 10)
	_skill_type_lbl.add_theme_color_override("font_color", C_SUB)
	detail.add_child(_skill_type_lbl)

	# Divider
	var det_div := ColorRect.new()
	det_div.size = Vector2(PANEL_W - 56, 1)
	det_div.position = Vector2(16, 68)
	det_div.color = C_BORDER
	det_div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(det_div)

	# Skill description
	_skill_desc_lbl = Label.new()
	_skill_desc_lbl.position = Vector2(16, 78)
	_skill_desc_lbl.size = Vector2(PANEL_W - 56, ph - 280)
	_skill_desc_lbl.add_theme_font_size_override("font_size", 12)
	_skill_desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.88, 1.0, 0.88))
	_skill_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_skill_desc_lbl)

	# Value badge (top-right of detail)
	_skill_val_lbl = Label.new()
	_skill_val_lbl.position = Vector2(PANEL_W - 120, 16)
	_skill_val_lbl.size = Vector2(96, 28)
	_skill_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skill_val_lbl.add_theme_font_size_override("font_size", 16)
	_skill_val_lbl.add_theme_color_override("font_color", C_GOLD)
	detail.add_child(_skill_val_lbl)

	# Select first skill by default
	_on_skill_btn(null, 0)

# ── Tab: Resonance (Eidolons) ─────────────────────────────────────
func _build_resonance_page(page: Control) -> void:
	var el: Color = CHARACTER["element_color"]
	var eidolons: Array = CHARACTER["eidolons"]
	var ph := page.size.y
	var item_h := (ph - 32.0) / eidolons.size()

	# Section title
	var sec := Label.new()
	sec.text = "RESONANCE CHAIN"
	sec.position = Vector2(20, 10)
	sec.add_theme_font_size_override("font_size", 10)
	sec.add_theme_color_override("font_color", Color(el.r, el.g, el.b, 0.7))
	sec.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(sec)

	# Unlocked count
	var unlocked_count := eidolons.filter(func(e): return e["unlocked"]).size()
	var count_lbl := Label.new()
	count_lbl.text = "%d / %d" % [unlocked_count, eidolons.size()]
	count_lbl.position = Vector2(PANEL_W - 60, 10)
	count_lbl.size = Vector2(46, 18)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.add_theme_color_override("font_color", Color(el.r, el.g, el.b, 0.8))
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(count_lbl)

	for i in eidolons.size():
		var e: Dictionary = eidolons[i]
		var unlocked: bool = e["unlocked"]
		var ey := 32.0 + i * item_h
		var dot_col: Color = Color(el.r, el.g, el.b, 0.9) if unlocked else C_LOCK

		# Connecting line between nodes
		if i < eidolons.size() - 1:
			var line := ColorRect.new()
			line.size = Vector2(2, item_h - 36)
			line.position = Vector2(38, ey + 34)
			line.color = dot_col if unlocked else Color(C_LOCK.r, C_LOCK.g, C_LOCK.b, 0.4)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			page.add_child(line)

		# Node circle
		var dot := Panel.new()
		dot.size = Vector2(36, 36)
		dot.position = Vector2(20, ey)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", _flat(
			Color(dot_col.r * 0.25, dot_col.g * 0.25, dot_col.b * 0.35, 1.0) if unlocked
			else Color(0.08, 0.09, 0.16, 1.0),
			dot_col, 18, 2 if unlocked else 1
		))
		page.add_child(dot)

		# Node number
		var num_lbl := Label.new()
		num_lbl.text = str(i + 1)
		num_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 13)
		num_lbl.add_theme_color_override("font_color",
			Color(el.r, el.g, el.b, 1.0) if unlocked else Color(0.35, 0.40, 0.56, 0.8))
		num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(num_lbl)

		# Row bg
		var row_bg := ColorRect.new()
		row_bg.size = Vector2(PANEL_W - 76, item_h - 8)
		row_bg.position = Vector2(66, ey + 2)
		row_bg.color = Color(1, 1, 1, 0.025 if unlocked else 0.01)
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(row_bg)

		# Name
		var name_lbl := Label.new()
		name_lbl.text = e["name"]
		name_lbl.position = Vector2(72, ey + 2)
		name_lbl.size = Vector2(PANEL_W - 90, 20)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color",
			Color(el.r + 0.1, el.g + 0.05, el.b + 0.05, 0.95) if unlocked
			else Color(0.35, 0.38, 0.52, 0.7))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(name_lbl)

		# Description
		var desc_lbl := Label.new()
		desc_lbl.text = e["desc"]
		desc_lbl.position = Vector2(72, ey + 20)
		desc_lbl.size = Vector2(PANEL_W - 90, item_h - 30)
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color",
			Color(0.78, 0.88, 1.0, 0.85) if unlocked else Color(0.28, 0.32, 0.46, 0.65))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(desc_lbl)

		# Unlock indicator
		if unlocked:
			var glow_dot := Panel.new()
			glow_dot.size = Vector2(8, 8)
			glow_dot.position = Vector2(PANEL_W - 28, ey + 14)
			glow_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glow_dot.add_theme_stylebox_override("panel", _flat(
				Color(el.r, el.g, el.b, 0.9), Color(el.r, el.g, el.b, 0.3), 4, 2
			))
			page.add_child(glow_dot)

# ── Tab: Info (Stats + Lore) ──────────────────────────────────────
func _build_info_page(page: Control) -> void:
	var el: Color = CHARACTER["element_color"]

	# Section: ATTRIBUTES
	var stats_lbl := Label.new()
	stats_lbl.text = "ATTRIBUTES"
	stats_lbl.position = Vector2(16, 10)
	stats_lbl.add_theme_font_size_override("font_size", 10)
	stats_lbl.add_theme_color_override("font_color", Color(el.r, el.g, el.b, 0.7))
	stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(stats_lbl)

	var y := 30.0
	for stat_key in CHARACTER["stats"]:
		var stat: Dictionary = CHARACTER["stats"][stat_key]
		var is_pct: bool = stat.get("pct", false)
		var val: float = stat["val"]
		var mx: float  = stat["max"]

		# Row bg (alternating)
		var row_idx := int((y - 30) / 40)
		if row_idx % 2 == 0:
			var rbg := ColorRect.new()
			rbg.size = Vector2(PANEL_W, 40)
			rbg.position = Vector2(0, y - 2)
			rbg.color = Color(1, 1, 1, 0.02)
			rbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			page.add_child(rbg)

		# Icon + name
		var icon_lbl := Label.new()
		icon_lbl.text = stat["icon"]
		icon_lbl.position = Vector2(14, y + 2)
		icon_lbl.add_theme_font_size_override("font_size", 14)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(icon_lbl)

		var n_lbl := Label.new()
		n_lbl.text = stat_key
		n_lbl.position = Vector2(38, y + 4)
		n_lbl.add_theme_font_size_override("font_size", 12)
		n_lbl.add_theme_color_override("font_color", C_SUB)
		n_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(n_lbl)

		# Value (right-aligned)
		var v_lbl := Label.new()
		v_lbl.text = "%d%s" % [int(val), "%" if is_pct else ""]
		v_lbl.position = Vector2(PANEL_W - 86, y + 4)
		v_lbl.size = Vector2(72, 20)
		v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v_lbl.add_theme_font_size_override("font_size", 14)
		v_lbl.add_theme_color_override("font_color", C_TEXT)
		v_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(v_lbl)

		# Stat bar
		var bar_bg := ColorRect.new()
		bar_bg.color = Color(1, 1, 1, 0.06)
		bar_bg.size = Vector2(PANEL_W - 28, 3)
		bar_bg.position = Vector2(14, y + 30)
		bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(bar_bg)

		var fill := ColorRect.new()
		fill.color = Color(el.r, el.g, el.b, 0.70)
		fill.size = Vector2((PANEL_W - 28) * (val / mx), 3)
		fill.position = Vector2(14, y + 30)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(fill)

		y += 40.0

	# Lore section
	var lore_div := ColorRect.new()
	lore_div.size = Vector2(PANEL_W - 28, 1)
	lore_div.position = Vector2(14, y + 6)
	lore_div.color = C_BORDER
	lore_div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(lore_div)

	var lore_title := Label.new()
	lore_title.text = "LORE"
	lore_title.position = Vector2(16, y + 14)
	lore_title.add_theme_font_size_override("font_size", 10)
	lore_title.add_theme_color_override("font_color", Color(el.r, el.g, el.b, 0.7))
	lore_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(lore_title)

	var lore_lbl := Label.new()
	lore_lbl.text = CHARACTER["lore"]
	lore_lbl.position = Vector2(16, y + 32)
	lore_lbl.size = Vector2(PANEL_W - 32, page.size.y - y - 40)
	lore_lbl.add_theme_font_size_override("font_size", 11)
	lore_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0, 0.72))
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(lore_lbl)

# ── Tab switching ─────────────────────────────────────────────────
func _switch_tab(idx: int) -> void:
	_cur_tab = idx as Tab
	var el: Color = CHARACTER["element_color"]
	for i in _tab_btns.size():
		var active := (i == idx)
		_tab_btns[i].add_theme_color_override("font_color",
			Color(el.r, el.g, el.b, 1.0) if active else C_SUB)
		var line := ColorRect.new()
		line.size = Vector2(PANEL_W / 3.0, 2)
		line.position = Vector2(i * (PANEL_W / 3.0), TAB_H - 2)
		line.color = Color(el.r, el.g, el.b, 0.85 if active else 0.0)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tab_btns[i].add_child(line)
		_tab_pages[i].visible = active

# ── Skill button handler ──────────────────────────────────────────
func _on_skill_btn(ev, idx: int) -> void:
	if ev != null and not (ev is InputEventMouseButton and ev.pressed):
		return
	_sel_skill = idx
	var skill: Dictionary = CHARACTER["skills"][idx]
	var col: Color = skill["color"]

	_skill_name_lbl.text = skill["name"]
	_skill_name_lbl.add_theme_color_override("font_color", Color(col.r + 0.1, col.g + 0.05, col.b + 0.05, 1.0))
	_skill_type_lbl.text = skill["type"]
	_skill_desc_lbl.text = skill["desc"]
	_skill_val_lbl.text  = skill["value"]
	_skill_val_lbl.add_theme_color_override("font_color", col)

	for i in _skill_btns.size():
		var sc: Color = CHARACTER["skills"][i]["color"]
		var active := (i == idx)
		_skill_btns[i].add_theme_stylebox_override("panel", _flat(
			Color(sc.r * 0.22, sc.g * 0.22, sc.b * 0.30, 1.0) if active
			else Color(sc.r * 0.10, sc.g * 0.10, sc.b * 0.16, 1.0),
			Color(sc.r, sc.g, sc.b, 0.9 if active else 0.35), 14,
			2 if active else 1
		))

# ── Fade-in overlay ───────────────────────────────────────────────
func _build_fade_in() -> void:
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 1)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.z_index = 50
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 0.0, 0.30)
	t.tween_callback(ov.queue_free)

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
	get_tree().change_scene_to_file(SC_ROSTER)
