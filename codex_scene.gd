extends Control

const SC_MAIN := "res://main_menu.tscn"

# ── Element data (real-world + game) ─────────────────────────────
const ELEMENTS: Array = [
	{
		"id": "Hydrogen", "symbol": "H", "number": 1,
		"name_th": "ไฮโดรเจน", "name_en": "Hydrogen",
		"color": Color(0.5, 0.85, 1.0),
		"type": "Nonmetal",
		"real_desc": "ธาตุที่เบาที่สุดและพบมากที่สุดในจักรวาล คิดเป็น 75% ของมวลสารทั้งหมด ใช้เป็นเชื้อเพลิงจรวดและแหล่งพลังงานสะอาด",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["H + O → น้ำ (Water)"],
	},
	{
		"id": "Oxygen", "symbol": "O", "number": 8,
		"name_th": "ออกซิเจน", "name_en": "Oxygen",
		"color": Color(0.4, 0.9, 0.7),
		"type": "Nonmetal",
		"real_desc": "จำเป็นสำหรับการหายใจของสิ่งมีชีวิต คิดเป็น 21% ของบรรยากาศโลก และเป็นส่วนประกอบหลักของน้ำ",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["O + H → น้ำ (Water)", "O + Fe → สนิม (Rust)"],
	},
	{
		"id": "Iron", "symbol": "Fe", "number": 26,
		"name_th": "เหล็ก", "name_en": "Iron",
		"color": Color(0.75, 0.65, 0.55),
		"type": "Transition Metal",
		"real_desc": "โลหะที่พบมากที่สุดในโลก เป็นส่วนประกอบหลักของแกนโลก ใช้ในการก่อสร้างและอุตสาหกรรมทั่วโลก",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["Fe + O → สนิม (Rust)"],
	},
	{
		"id": "Sodium", "symbol": "Na", "number": 11,
		"name_th": "โซเดียม", "name_en": "Sodium",
		"color": Color(1.0, 0.85, 0.3),
		"type": "Alkali Metal",
		"real_desc": "โลหะอ่อนสีเงิน ระเบิดรุนแรงเมื่อสัมผัสน้ำ ร่างกายต้องการโซเดียมเพื่อควบคุมน้ำและแรงดันเลือด",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["Na + Cl → เกลือ (Salt)"],
	},
	{
		"id": "Chlorine", "symbol": "Cl", "number": 17,
		"name_th": "คลอรีน", "name_en": "Chlorine",
		"color": Color(0.7, 1.0, 0.4),
		"type": "Halogen",
		"real_desc": "แก๊สพิษสีเขียว-เหลือง เคยถูกใช้เป็นอาวุธเคมีในสงครามโลกครั้งที่ 1 ปัจจุบันใช้ฆ่าเชื้อในน้ำประปาและสระว่ายน้ำ",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["Cl + Na → เกลือ (Salt)"],
	},
	{
		"id": "Water", "symbol": "H₂O", "number": 0,
		"name_th": "น้ำ", "name_en": "Water",
		"color": Color(0.3, 0.7, 1.0),
		"type": "Compound",
		"real_desc": "สารประกอบที่จำเป็นต่อสิ่งมีชีวิตทุกชนิด ครอบคลุม 71% ของพื้นผิวโลก มีคุณสมบัติพิเศษคือมีความหนาแน่นสูงสุดที่ 4°C",
		"how_to_get": "สังเคราะห์: H + O",
		"recipes": ["ฟื้นฟู HP +20"],
	},
	{
		"id": "Salt", "symbol": "NaCl", "number": 0,
		"name_th": "เกลือ", "name_en": "Salt",
		"color": Color(0.9, 0.9, 0.95),
		"type": "Compound",
		"real_desc": "โซเดียมคลอไรด์ สารที่มนุษย์ใช้ถนอมอาหารมาหลายพันปี ร่างกายต้องการเกลือในปริมาณที่เหมาะสมเพื่อการทำงานของเซลล์ประสาท",
		"how_to_get": "สังเคราะห์: Na + Cl",
		"recipes": ["เพิ่ม Shield +20"],
	},
	{
		"id": "Rust", "symbol": "Fe₂O₃", "number": 0,
		"name_th": "สนิมเหล็ก", "name_en": "Rust",
		"color": Color(0.85, 0.4, 0.2),
		"type": "Compound",
		"real_desc": "เหล็กออกไซด์ เกิดจากปฏิกิริยาออกซิเดชันของเหล็กกับออกซิเจนในอากาศและความชื้น เป็นปัญหาใหญ่ในอุตสาหกรรมโลหะ",
		"how_to_get": "สังเคราะห์: Fe + O",
		"recipes": ["โจมตี -10 HP + วางพิษศัตรู +5"],
	},
]

# ── Achievement data ──────────────────────────────────────────────
const ACHIEVEMENTS: Array = [
	# Combat
	{"id":"first_blood",  "icon":"⚔",  "title":"First Blood",          "desc":"ชนะการต่อสู้ครั้งแรก",                "current":0, "total":1,  "reward":"crystal", "reward_n":10,  "cat":"combat"},
	{"id":"survivor",     "icon":"🛡",  "title":"Survivor",             "desc":"ชนะโดยที่ HP เหลือน้อยกว่า 10",     "current":0, "total":1,  "reward":"crystal", "reward_n":20,  "cat":"combat"},
	{"id":"veteran",      "icon":"⚔",  "title":"Veteran",              "desc":"ชนะการต่อสู้ 50 ครั้ง",             "current":0, "total":50, "reward":"🧪×500",  "cat":"combat"},
	{"id":"boss_slayer",  "icon":"💀",  "title":"Boss Slayer",          "desc":"กำจัด Boss ได้",                     "current":0, "total":1,  "reward":"crystal", "reward_n":50,  "cat":"combat"},
	{"id":"no_damage",    "icon":"✨",  "title":"Untouchable",          "desc":"ชนะโดยไม่โดนโจมตีเลย",             "current":0, "total":1,  "reward":"crystal", "reward_n":30,  "cat":"combat"},
	# Alchemy
	{"id":"first_brew",   "icon":"⚗",  "title":"First Brew",           "desc":"สังเคราะห์สารประกอบครั้งแรก",       "current":0, "total":1,  "reward":"🧪×50",  "cat":"alchemy"},
	{"id":"water_maker",  "icon":"💧",  "title":"Water Maker",          "desc":"สังเคราะห์น้ำ 10 ครั้ง",           "current":0, "total":10, "reward":"🧪×100", "cat":"alchemy"},
	{"id":"poison_master","icon":"☠",  "title":"Poison Master",        "desc":"วางพิษศัตรู 20 ครั้ง",              "current":0, "total":20, "reward":"crystal", "reward_n":25,  "cat":"alchemy"},
	{"id":"all_recipes",  "icon":"📖",  "title":"Full Formula",         "desc":"ค้นพบสูตรสังเคราะห์ครบทุกสูตร",   "current":0, "total":3,  "reward":"crystal", "reward_n":100, "cat":"alchemy"},
	# Collection
	{"id":"collector",    "icon":"🌟",  "title":"Collector",            "desc":"ปลดล็อคธาตุในสารานุกรมครบทุกตัว", "current":0, "total":8,  "reward":"crystal", "reward_n":200, "cat":"collect"},
	{"id":"gacha_once",   "icon":"🎲",  "title":"Lucky Draw",           "desc":"สุ่มกาชาครั้งแรก",                 "current":0, "total":1,  "reward":"🧪×200", "cat":"collect"},
	{"id":"pity_hit",     "icon":"⭐",  "title":"Pity Saved Me",        "desc":"ได้ตัวละคร 5★ จาก pity",           "current":0, "total":1,  "reward":"crystal", "reward_n":50,  "cat":"collect"},
	# Progression
	{"id":"stage_10",     "icon":"🗺",  "title":"Explorer",             "desc":"ผ่าน Stage 10",                    "current":0, "total":10, "reward":"crystal", "reward_n":30,  "cat":"progress"},
	{"id":"domain_full",  "icon":"🌐",  "title":"Domain Master",        "desc":"เติม Domain Gauge เต็ม",           "current":0, "total":1,  "reward":"crystal", "reward_n":40,  "cat":"progress"},
	{"id":"ultimate_x5",  "icon":"💥",  "title":"Limit Breaker",        "desc":"ใช้ Ultimate 5 ครั้ง",             "current":0, "total":5,  "reward":"🧪×150", "cat":"progress"},
]

const CAT_LABELS := {"combat":"⚔ การต่อสู้", "alchemy":"⚗ การสังเคราะห์", "collect":"🌟 การสะสม", "progress":"🗺 ความก้าวหน้า"}

# ── Colors ────────────────────────────────────────────────────────
const C_BG     := Color(0.04, 0.05, 0.10, 1.0)
const C_PANEL  := Color(0.07, 0.09, 0.16, 1.0)
const C_BORDER := Color(0.22, 0.50, 0.90, 0.30)
const C_TEXT   := Color(0.88, 0.92, 1.0,  1.0)
const C_SUB    := Color(0.55, 0.70, 0.90, 0.8)
const C_GOLD   := Color(1.00, 0.82, 0.25, 1.0)
const C_DONE   := Color(0.30, 0.85, 0.55, 1.0)
const C_LOCK   := Color(0.25, 0.28, 0.38, 1.0)

var _tab := 0  # 0=elements, 1=achievements
var _tab_btns: Array[Button] = []
var _content: ScrollContainer
var _detail_overlay: Control
var _discovered: Array[String] = []  # element ids unlocked

func _ready() -> void:
	# discovered_elements stores symbols ("H","O","Na"...) and compound keys ("Water","Salt"...)
	# _discovered stores element["id"] values — build the mapping here
	const SYM_TO_ID := {
		"H": "Hydrogen", "O": "Oxygen",  "Na": "Sodium",
		"Cl": "Chlorine", "Fe": "Iron",   "C":  "Carbon",
	}
	_discovered = []
	for entry in PlayerData.discovered_elements:
		var mapped: String = SYM_TO_ID.get(entry, entry)  # compound keys pass through as-is
		if mapped not in _discovered:
			_discovered.append(mapped)
	# Fallback: always show base 5 until story system implemented
	for base in ["Hydrogen","Oxygen","Sodium","Chlorine","Iron"]:
		if base not in _discovered:
			_discovered.append(base)
	_build_ui()

# ════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_build_header()
	_build_tabs()
	_build_content_area()
	_build_detail_overlay()
	_switch_tab(0)

func _flat(col: Color, border: Color = Color(0,0,0,0), r: int = 8, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
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

# ── Header ────────────────────────────────────────────────────────
func _build_header() -> void:
	var hdr := Panel.new()
	hdr.size = Vector2(1152, 52)
	hdr.add_theme_stylebox_override("panel", _flat(Color(0.05, 0.07, 0.14, 1.0), C_BORDER, 0, 1))
	add_child(hdr)

	var back := _make_back_btn(Vector2(10, 7), Vector2(36, 36), _go_back)
	hdr.add_child(back)

	var title := Label.new()
	title.text = "CODEX"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_TEXT)
	title.position = Vector2(110, 14)
	hdr.add_child(title)

# ── Tab bar ───────────────────────────────────────────────────────
func _build_tabs() -> void:
	var bar := Panel.new()
	bar.position = Vector2(0, 52)
	bar.size = Vector2(1152, 44)
	bar.add_theme_stylebox_override("panel", _flat(Color(0.055, 0.075, 0.15, 1.0), C_BORDER, 0, 1))
	add_child(bar)

	var tabs := [["⚗  ธาตุ & สูตร", 0], ["🏆  ความสำเร็จ", 1]]
	var x := 20.0
	for td in tabs:
		var btn := Button.new()
		btn.text = td[0]
		btn.custom_minimum_size = Vector2(180, 34)
		btn.position = Vector2(x, 5)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0)))
		btn.pressed.connect(_switch_tab.bind(td[1]))
		bar.add_child(btn)
		_tab_btns.append(btn)
		x += 190

# ── Content area ──────────────────────────────────────────────────
func _build_content_area() -> void:
	_content = ScrollContainer.new()
	_content.position = Vector2(0, 96)
	_content.size = Vector2(1152, 552)
	_content.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_content)

func _switch_tab(idx: int) -> void:
	_tab = idx
	for i in _tab_btns.size():
		var btn := _tab_btns[i]
		if i == idx:
			btn.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
			btn.add_theme_stylebox_override("normal",  _flat(Color(0.12, 0.22, 0.45, 1.0), Color(0.3, 0.6, 1.0, 0.5), 8, 1))
			btn.add_theme_stylebox_override("hover",   _flat(Color(0.12, 0.22, 0.45, 1.0), Color(0.3, 0.6, 1.0, 0.5), 8, 1))
		else:
			btn.add_theme_color_override("font_color", C_SUB)
			btn.add_theme_stylebox_override("normal", _flat(Color(0,0,0,0), Color(0,0,0,0)))
			btn.add_theme_stylebox_override("hover",  _flat(Color(1,1,1,0.05), Color(0,0,0,0)))

	for c in _content.get_children():
		c.queue_free()

	if idx == 0:
		_build_element_tab()
	else:
		_build_achievement_tab()

# ════════════════════════════════════════════════════════════════
#  TAB 0 — Elements
# ════════════════════════════════════════════════════════════════
func _build_element_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(1152, 0)
	vbox.add_theme_constant_override("separation", 0)
	_content.add_child(vbox)

	# Section label
	var sec := _section_label("ธาตุที่ค้นพบ  (%d/%d)" % [_discovered.size(), ELEMENTS.size()])
	vbox.add_child(sec)

	# Grid
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grid_wrap := MarginContainer.new()
	grid_wrap.add_theme_constant_override("margin_left", 20)
	grid_wrap.add_theme_constant_override("margin_right", 20)
	grid_wrap.add_theme_constant_override("margin_top", 12)
	grid_wrap.add_theme_constant_override("margin_bottom", 20)
	grid_wrap.add_child(grid)
	vbox.add_child(grid_wrap)

	for elem in ELEMENTS:
		grid.add_child(_make_element_card(elem))

func _make_element_card(elem: Dictionary) -> Control:
	var discovered: bool = elem["id"] in _discovered
	var card := Panel.new()
	card.custom_minimum_size = Vector2(260, 130)
	var col := elem["color"] as Color
	var border_col := Color(col.r, col.g, col.b, 0.6) if discovered else Color(0.3, 0.35, 0.5, 0.4)
	var bg_col := Color(col.r * 0.12, col.g * 0.12, col.b * 0.15, 1.0) if discovered else C_LOCK
	card.add_theme_stylebox_override("panel", _flat(bg_col, border_col, 10, 1))
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	if discovered:
		# Symbol badge
		var badge := Label.new()
		badge.text = elem["symbol"]
		badge.position = Vector2(10, 8)
		badge.add_theme_font_size_override("font_size", 28)
		badge.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.9))
		card.add_child(badge)

		# Atomic number
		if elem["number"] > 0:
			var num := Label.new()
			num.text = str(elem["number"])
			num.position = Vector2(14, 50)
			num.add_theme_font_size_override("font_size", 9)
			num.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.5))
			card.add_child(num)

		# Name
		var name_lbl := Label.new()
		name_lbl.text = elem["name_th"]
		name_lbl.position = Vector2(72, 10)
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", C_TEXT)
		card.add_child(name_lbl)

		# English name + type
		var sub := Label.new()
		sub.text = "%s  ·  %s" % [elem["name_en"], elem["type"]]
		sub.position = Vector2(72, 30)
		sub.add_theme_font_size_override("font_size", 10)
		sub.add_theme_color_override("font_color", C_SUB)
		card.add_child(sub)

		# Short desc
		var desc := Label.new()
		desc.text = elem["real_desc"].substr(0, 80) + "..."
		desc.position = Vector2(10, 68)
		desc.size = Vector2(240, 50)
		desc.add_theme_font_size_override("font_size", 9)
		desc.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.75))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(desc)

		# Tap for detail
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed:
				_open_element_detail(elem)
		)
	else:
		# Locked
		var q := Label.new()
		q.text = "?"
		q.position = Vector2(10, 8)
		q.add_theme_font_size_override("font_size", 36)
		q.add_theme_color_override("font_color", Color(0.4, 0.45, 0.6, 0.6))
		card.add_child(q)

		var locked_lbl := Label.new()
		locked_lbl.text = "ยังไม่ค้นพบ"
		locked_lbl.position = Vector2(72, 45)
		locked_lbl.add_theme_font_size_override("font_size", 12)
		locked_lbl.add_theme_color_override("font_color", Color(0.45, 0.5, 0.65, 0.7))
		card.add_child(locked_lbl)

	return card

# ════════════════════════════════════════════════════════════════
#  TAB 1 — Achievements
# ════════════════════════════════════════════════════════════════
func _build_achievement_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(1152, 0)
	vbox.add_theme_constant_override("separation", 0)
	_content.add_child(vbox)

	var done_count: int = ACHIEVEMENTS.filter(func(a): return int(a["current"]) >= int(a["total"])).size()
	vbox.add_child(_section_label("ความสำเร็จ  (%d/%d)" % [done_count, ACHIEVEMENTS.size()]))

	var categories := CAT_LABELS.keys()
	for cat in categories:
		var cat_items: Array = ACHIEVEMENTS.filter(func(a): return a["cat"] == cat)
		if cat_items.is_empty():
			continue

		# Category header
		var cat_lbl := Label.new()
		cat_lbl.text = CAT_LABELS[cat]
		cat_lbl.add_theme_font_size_override("font_size", 13)
		cat_lbl.add_theme_color_override("font_color", C_GOLD)
		var cat_wrap := MarginContainer.new()
		cat_wrap.add_theme_constant_override("margin_left", 24)
		cat_wrap.add_theme_constant_override("margin_top", 16)
		cat_wrap.add_theme_constant_override("margin_bottom", 6)
		cat_wrap.add_child(cat_lbl)
		vbox.add_child(cat_wrap)

		for ach in cat_items:
			vbox.add_child(_make_achievement_row(ach))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

func _make_achievement_row(ach: Dictionary) -> Control:
	var total: int = max(1, int(ach["total"]))
	var cur: int   = clampi(int(ach["current"]), 0, total)
	var done: bool = cur >= total

	var row := Panel.new()
	row.custom_minimum_size = Vector2(1152, 70)
	row.add_theme_stylebox_override("panel", _flat(
		Color(1,1,1,0.03) if done else Color(0,0,0,0),
		Color(0.3, 0.85, 0.55, 0.25) if done else Color(0,0,0,0),
		0, 1 if done else 0
	))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Icon
	var icon := Label.new()
	icon.text = ach["icon"]
	icon.position = Vector2(18, 18)
	icon.add_theme_font_size_override("font_size", 22)
	icon.add_theme_color_override("font_color", C_DONE if done else Color(0.5, 0.55, 0.7))
	row.add_child(icon)

	# Title
	var title := Label.new()
	title.text = ("✓  " if done else "") + ach["title"]
	title.position = Vector2(56, 10)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", C_DONE if done else C_TEXT)
	row.add_child(title)

	# Desc
	var desc := Label.new()
	desc.text = ach["desc"]
	desc.position = Vector2(56, 30)
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", C_SUB)
	row.add_child(desc)

	# Progress bar bg
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.07)
	bar_bg.size = Vector2(260, 5)
	bar_bg.position = Vector2(56, 52)
	row.add_child(bar_bg)

	var fill := ColorRect.new()
	fill.color = C_DONE if done else Color(0.35, 0.62, 1.0)
	fill.size = Vector2(260.0 * cur / total, 5)
	fill.position = Vector2(56, 52)
	row.add_child(fill)

	# Count
	var cnt := Label.new()
	cnt.text = "%d/%d" % [cur, total]
	cnt.position = Vector2(324, 46)
	cnt.add_theme_font_size_override("font_size", 10)
	cnt.add_theme_color_override("font_color", Color(1,1,1,0.35))
	row.add_child(cnt)

	# Reward
	var reward_str: String = str(ach.get("reward", ""))
	var reward_n: int = int(ach.get("reward_n", 0))
	if reward_str == "crystal" and reward_n > 0:
		var _buf := FileAccess.get_file_as_bytes("res://image/crystal_gem.png")
		if not _buf.is_empty():
			var _img := Image.new()
			if _img.load_png_from_buffer(_buf) == OK:
				var ico := TextureRect.new()
				ico.texture = ImageTexture.create_from_image(_img)
				ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
				ico.size = Vector2(18, 18)
				ico.position = Vector2(900, 26)
				row.add_child(ico)
		var rew := Label.new()
		rew.text = "×%d" % reward_n
		rew.position = Vector2(922, 22)
		rew.add_theme_font_size_override("font_size", 12)
		rew.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0, 0.95) if done else Color(0.4, 0.6, 0.75))
		row.add_child(rew)
	else:
		var rew := Label.new()
		rew.text = "🎁 " + reward_str
		rew.position = Vector2(900, 22)
		rew.add_theme_font_size_override("font_size", 12)
		rew.add_theme_color_override("font_color", C_GOLD if done else Color(0.6, 0.65, 0.8))
		row.add_child(rew)

	# Divider
	var div := ColorRect.new()
	div.color = Color(1,1,1,0.05)
	div.size = Vector2(1152, 1)
	div.position = Vector2(0, 69)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(div)

	return row

# ── Element detail overlay ────────────────────────────────────────
func _build_detail_overlay() -> void:
	_detail_overlay = Control.new()
	_detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_overlay.visible = false
	add_child(_detail_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_detail_overlay.visible = false
	)
	_detail_overlay.add_child(dim)

func _open_element_detail(elem: Dictionary) -> void:
	# Clear old card
	for c in _detail_overlay.get_children():
		if c is Panel:
			c.queue_free()

	var col: Color = elem["color"]
	var card := Panel.new()
	card.size = Vector2(480, 380)
	card.position = Vector2(336, 134)
	card.add_theme_stylebox_override("panel", _flat(
		Color(0.06, 0.08, 0.16, 1.0),
		Color(col.r, col.g, col.b, 0.7), 12, 2
	))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_overlay.add_child(card)

	# Symbol large
	var sym := Label.new()
	sym.text = elem["symbol"]
	sym.position = Vector2(20, 16)
	sym.add_theme_font_size_override("font_size", 52)
	sym.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.85))
	card.add_child(sym)

	if elem["number"] > 0:
		var num := Label.new()
		num.text = "No. %d" % elem["number"]
		num.position = Vector2(24, 76)
		num.add_theme_font_size_override("font_size", 10)
		num.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.5))
		card.add_child(num)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = elem["name_th"]
	name_lbl.position = Vector2(130, 18)
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	card.add_child(name_lbl)

	var eng := Label.new()
	eng.text = elem["name_en"] + "  ·  " + elem["type"]
	eng.position = Vector2(130, 46)
	eng.add_theme_font_size_override("font_size", 12)
	eng.add_theme_color_override("font_color", C_SUB)
	card.add_child(eng)

	# Divider
	var div := ColorRect.new()
	div.color = Color(col.r, col.g, col.b, 0.2)
	div.size = Vector2(440, 1)
	div.position = Vector2(20, 100)
	card.add_child(div)

	# Real-world desc
	var real_title := Label.new()
	real_title.text = "ข้อมูลจริง"
	real_title.position = Vector2(20, 112)
	real_title.add_theme_font_size_override("font_size", 11)
	real_title.add_theme_color_override("font_color", C_GOLD)
	card.add_child(real_title)

	var real_desc := Label.new()
	real_desc.text = elem["real_desc"]
	real_desc.position = Vector2(20, 130)
	real_desc.size = Vector2(440, 80)
	real_desc.add_theme_font_size_override("font_size", 11)
	real_desc.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0, 0.85))
	real_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(real_desc)

	# How to get
	var how_title := Label.new()
	how_title.text = "วิธีได้รับ"
	how_title.position = Vector2(20, 222)
	how_title.add_theme_font_size_override("font_size", 11)
	how_title.add_theme_color_override("font_color", C_GOLD)
	card.add_child(how_title)

	var how := Label.new()
	how.text = elem["how_to_get"]
	how.position = Vector2(20, 240)
	how.add_theme_font_size_override("font_size", 11)
	how.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0, 0.85))
	card.add_child(how)

	# Recipes / effects
	var rec_title := Label.new()
	rec_title.text = "ใช้ทำ / ผลในเกม"
	rec_title.position = Vector2(20, 268)
	rec_title.add_theme_font_size_override("font_size", 11)
	rec_title.add_theme_color_override("font_color", C_GOLD)
	card.add_child(rec_title)

	var ry := 286.0
	for r in elem["recipes"]:
		var rl := Label.new()
		rl.text = "• " + r
		rl.position = Vector2(20, ry)
		rl.add_theme_font_size_override("font_size", 11)
		rl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.65, 0.9))
		card.add_child(rl)
		ry += 18

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.size = Vector2(32, 32)
	close_btn.position = Vector2(436, 10)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", C_SUB)
	close_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
	close_btn.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.08), Color(0,0,0,0)))
	close_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	close_btn.pressed.connect(func(): _detail_overlay.visible = false)
	card.add_child(close_btn)

	_detail_overlay.visible = true

# ── Helpers ───────────────────────────────────────────────────────
func _section_label(txt: String) -> Control:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C_SUB)
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_left", 24)
	wrap.add_theme_constant_override("margin_top", 14)
	wrap.add_theme_constant_override("margin_bottom", 4)
	wrap.add_child(lbl)
	return wrap

func _make_back_btn(pos: Vector2, sz: Vector2, callback: Callable) -> TextureButton:
	var btn := TextureButton.new()
	btn.position = pos; btn.size = sz
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var buf := FileAccess.get_file_as_bytes("res://image/back.jpg")
	if not buf.is_empty():
		var img := Image.new()
		if img.load_jpg_from_buffer(buf) == OK:
			img.convert(Image.FORMAT_RGBA8)
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					var a := clampf(((c.r+c.g+c.b)/3.0 - 0.25) / 0.45, 0.0, 1.0)
					img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
			btn.texture_normal = ImageTexture.create_from_image(img)
	btn.pivot_offset = sz / 2
	btn.pressed.connect(func():
		var tw := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2(0.78, 0.78), 0.08)
		tw.tween_property(btn, "scale", Vector2(1.0,  1.0),  0.22)
		tw.tween_callback(callback)
	)
	return btn

func _go_back() -> void:
	SceneTransition.fade_to(SC_MAIN)
