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
var _skill_btns: Array[Button] = []
var _skill_name_lbl: Label
var _skill_type_lbl: Label
var _skill_desc_lbl: Label
var _skill_val_lbl:  Label

@onready var _back_btn: Panel = $RightPanel/BackBtn

func _ready() -> void:
	_tab_btns  = [$RightPanel/TabBar/SkillsBtn, $RightPanel/TabBar/ResonanceBtn, $RightPanel/TabBar/InfoBtn]
	_tab_pages = [$RightPanel/SkillsPage, $RightPanel/ResonancePage, $RightPanel/InfoPage]

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

	for i in 3:
		_tab_btns[i].pressed.connect(_switch_tab.bind(i))

	_build_skills_page(_tab_pages[0])
	_build_resonance_page(_tab_pages[1])
	_build_info_page(_tab_pages[2])
	_switch_tab(0)
	_build_fade_in()



# ── Tab: Skills ───────────────────────────────────────────────────
func _build_skills_page(page: Control) -> void:
	var skills: Array = CHARACTER["skills"]
	var ph := 648 - (HDR_H + 2 + TAB_H + 2)  # 528

	# Skill icon row (top ~110px)
	var btn_sz := Vector2(100, 100)
	var total_w := skills.size() * btn_sz.x + (skills.size() - 1) * 12
	var row_x := (PANEL_W - total_w) / 2.0

	for i in skills.size():
		var sk: Dictionary = skills[i]
		var col: Color = sk["color"]
		var bx := row_x + i * (btn_sz.x + 12)

		var btn := Button.new()
		btn.size = btn_sz
		btn.position = Vector2(bx, 14)
		btn.focus_mode = Control.FOCUS_NONE
		btn.clip_contents = true
		for s in ["normal","hover","pressed","focus","disabled"]:
			btn.add_theme_stylebox_override(s, _flat(
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

		btn.pressed.connect(_on_skill_btn.bind(null, i))

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
	var ph := 648 - (HDR_H + 2 + TAB_H + 2)  # 528
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
	var ph2 := 648 - (HDR_H + 2 + TAB_H + 2)
	lore_lbl.size = Vector2(PANEL_W - 32, ph2 - y - 40)
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
		# remove previous indicator line before adding a new one
		for child in _tab_btns[i].get_children():
			if child is ColorRect:
				child.queue_free()
		var line := ColorRect.new()
		line.size = Vector2(PANEL_W / 3.0, 2)
		line.position = Vector2(0, TAB_H - 2)
		line.color = Color(el.r, el.g, el.b, 0.85) if active else Color(0, 0, 0, 0)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tab_btns[i].add_child(line)
		_tab_pages[i].visible = active

# ── Skill button handler ──────────────────────────────────────────
func _on_skill_btn(_ev, idx: int) -> void:
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
		var sb := _flat(
			Color(sc.r * 0.22, sc.g * 0.22, sc.b * 0.30, 1.0) if active
			else Color(sc.r * 0.10, sc.g * 0.10, sc.b * 0.16, 1.0),
			Color(sc.r, sc.g, sc.b, 0.9 if active else 0.35), 14,
			2 if active else 1
		)
		for s in ["normal","hover","pressed","focus","disabled"]:
			_skill_btns[i].add_theme_stylebox_override(s, sb)

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

func _make_back_btn(pos: Vector2, sz: Vector2, callback: Callable) -> Control:
	var btn := Panel.new()
	btn.position = pos; btn.size = sz
	btn.pivot_offset = sz / 2
	btn.z_index = 20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.16, 0.92)
	sb.border_color = Color(0.35, 0.55, 1.0, 0.30)
	sb.set_border_width_all(1)
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		sb.set(r, 12)
	btn.add_theme_stylebox_override("panel", sb)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var lbl := Label.new()
	lbl.text = "\u2039"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 0.95))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)
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
	SceneTransition.fade_to(SC_ROSTER)
