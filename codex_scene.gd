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
	{"id":"first_blood",  "icon":"⚔",  "title":"First Blood",          "desc":"ชนะการต่อสู้ครั้งแรก",                "detail":"เอาชนะศัตรูในการต่อสู้ครั้งแรกของคุณ ก้าวแรกของนักรบนักเคมี",                                      "current":0, "total":1,  "reward":"crystal", "reward_n":10,  "cat":"combat", "elems":["Hydrogen","Oxygen"]},
	{"id":"survivor",     "icon":"🛡",  "title":"Survivor",             "desc":"ชนะโดยที่ HP เหลือน้อยกว่า 10",     "detail":"เอาชนะได้ทั้งที่ HP ใกล้หมด แสดงให้เห็นถึงความอดทนอย่างสูง",                                       "current":0, "total":1,  "reward":"crystal", "reward_n":20,  "cat":"combat", "elems":["Iron","Oxygen"]},
	{"id":"veteran",      "icon":"⚔",  "title":"Veteran",              "desc":"ชนะการต่อสู้ 50 ครั้ง",             "detail":"ผ่านสมรภูมิมาแล้ว 50 ครั้ง ประสบการณ์ที่สั่งสมทำให้คุณเป็นนักรบที่แท้จริง",                        "current":0, "total":50, "reward":"🧪×500",  "cat":"combat", "elems":["Iron","Chlorine"]},
	{"id":"boss_slayer",  "icon":"💀",  "title":"Boss Slayer",          "desc":"กำจัด Boss ได้",                     "detail":"เอาชนะบอสผู้ทรงพลังได้สำเร็จ ใช้สารเคมีที่ถูกต้องในเวลาที่เหมาะสม",                               "current":0, "total":1,  "reward":"crystal", "reward_n":50,  "cat":"combat", "elems":["Rust","Salt"]},
	{"id":"no_damage",    "icon":"✨",  "title":"Untouchable",          "desc":"ชนะโดยไม่โดนโจมตีเลย",             "detail":"เต้นรำในสนามรบโดยไม่โดนแตะต้องเลยแม้แต่ครั้งเดียว ความเชี่ยวชาญระดับสูงสุด",                      "current":0, "total":1,  "reward":"crystal", "reward_n":30,  "cat":"combat", "elems":["Water","Hydrogen"]},
	# Alchemy
	{"id":"first_brew",   "icon":"⚗",  "title":"First Brew",           "desc":"สังเคราะห์สารประกอบครั้งแรก",       "detail":"ทดลองผสมธาตุสองชนิดเข้าด้วยกันจนเกิดสารประกอบใหม่ครั้งแรก จุดเริ่มต้นของนักเคมี",                 "current":0, "total":1,  "reward":"🧪×50",  "cat":"alchemy", "elems":["Hydrogen","Oxygen","Water"]},
	{"id":"water_maker",  "icon":"💧",  "title":"Water Maker",          "desc":"สังเคราะห์น้ำ 10 ครั้ง",           "detail":"ผสม H + O จนได้ H₂O ถึง 10 ครั้ง น้ำคือรากฐานของสิ่งมีชีวิตทุกชนิด",                              "current":0, "total":10, "reward":"🧪×100", "cat":"alchemy", "elems":["Hydrogen","Oxygen","Water"]},
	{"id":"poison_master","icon":"☠",  "title":"Poison Master",        "desc":"วางพิษศัตรู 20 ครั้ง",              "detail":"ใช้สนิมเหล็ก (Fe₂O₃) โจมตีและวางพิษศัตรูสะสม 20 ครั้ง เชี่ยวชาญในการใช้ปฏิกิริยาเคมีเป็นอาวุธ", "current":0, "total":20, "reward":"crystal", "reward_n":25,  "cat":"alchemy", "elems":["Iron","Oxygen","Rust"]},
	{"id":"all_recipes",  "icon":"📖",  "title":"Full Formula",         "desc":"ค้นพบสูตรสังเคราะห์ครบทุกสูตร",   "detail":"ค้นพบสูตรสังเคราะห์ครบทุกสูตรในห้องปฏิบัติการ ได้แก่ น้ำ เกลือ และสนิมเหล็ก",                      "current":0, "total":3,  "reward":"crystal", "reward_n":100, "cat":"alchemy", "elems":["Water","Salt","Rust"]},
	# Collection
	{"id":"collector",    "icon":"🌟",  "title":"Collector",            "desc":"ปลดล็อคธาตุในสารานุกรมครบทุกตัว", "detail":"ค้นพบและปลดล็อคธาตุในสารานุกรมครบทุกตัว รวมทั้งธาตุและสารประกอบทั้งหมด",                            "current":0, "total":8,  "reward":"crystal", "reward_n":200, "cat":"collect", "elems":["Hydrogen","Oxygen","Iron","Sodium","Chlorine","Water","Salt","Rust"]},
	{"id":"gacha_once",   "icon":"🎲",  "title":"Lucky Draw",           "desc":"สุ่มกาชาครั้งแรก",                 "detail":"ลองโชคในระบบ Gacha ครั้งแรก ใครจะรู้ว่าจะได้ธาตุหายากแค่ไหน",                                       "current":0, "total":1,  "reward":"🧪×200", "cat":"collect", "elems":[]},
	{"id":"pity_hit",     "icon":"⭐",  "title":"Pity Saved Me",        "desc":"ได้ตัวละคร 5★ จาก pity",           "detail":"ระบบ Pity ช่วยรับประกันให้ได้ตัวละคร 5 ดาวหลังจากสะสมครบจำนวน",                                    "current":0, "total":1,  "reward":"crystal", "reward_n":50,  "cat":"collect", "elems":[]},
	# Progression
	{"id":"stage_10",     "icon":"🗺",  "title":"Explorer",             "desc":"ผ่าน Stage 10",                    "detail":"ผ่านด่านที่ 10 สำเร็จ เส้นทางการผจญภัยยังยาวไกลข้างหน้า",                                           "current":0, "total":10, "reward":"crystal", "reward_n":30,  "cat":"progress", "elems":[]},
	{"id":"domain_full",  "icon":"🌐",  "title":"Domain Master",        "desc":"เติม Domain Gauge เต็ม",           "detail":"เติม Domain Gauge จนเต็มสำเร็จ พลังงานธาตุที่สั่งสมมาถึงขีดสูงสุด",                                 "current":0, "total":1,  "reward":"crystal", "reward_n":40,  "cat":"progress", "elems":[]},
	{"id":"ultimate_x5",  "icon":"💥",  "title":"Limit Breaker",        "desc":"ใช้ Ultimate 5 ครั้ง",             "detail":"ปลดปล่อยพลังขั้นสูงสุด 5 ครั้ง ยิ่งใช้ธาตุที่ผสมได้ยิ่งแรงขึ้น",                                  "current":0, "total":5,  "reward":"🧪×150", "cat":"progress", "elems":[]},
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

var _tab := 0  # 0=elements, 1=achievements, 2=compounds
var _tab_btns: Array[Button] = []

# Compound keys already shown in elements tab — skip in compounds tab
const ELEM_COMPOUND_KEYS := ["water", "salt", "rust"]
var _detail_overlay: Control
var _discovered: Array[String] = []  # element ids unlocked

@onready var _content: ScrollContainer = $ContentScroll
@onready var _back_btn: Panel = $Header/BackBtn
@onready var _fade: ColorRect = $FadeOverlay

func _ready() -> void:
	_tab_btns = [$TabBar/ElementsBtn, $TabBar/AchievBtn]
	for i in _tab_btns.size():
		_tab_btns[i].pressed.connect(_switch_tab.bind(i))

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

	const SYM_TO_ID := {
		"H": "Hydrogen", "O": "Oxygen",  "Na": "Sodium",
		"Cl": "Chlorine", "Fe": "Iron",   "C":  "Carbon",
	}
	# Map lab compound keys → codex element ids
	const COMPOUND_TO_ELEM := {
		"water": "Water", "salt": "Salt", "rust": "Rust",
	}
	_discovered = []
	for entry in PlayerData.discovered_elements:
		var mapped: String = SYM_TO_ID.get(entry, entry)
		if mapped not in _discovered:
			_discovered.append(mapped)
	# Unlock compound-elements when discovered in lab
	for comp_key in PlayerData.discovered_compounds:
		var elem_id: String = COMPOUND_TO_ELEM.get(comp_key, "")
		if elem_id != "" and elem_id not in _discovered:
			_discovered.append(elem_id)
	for base in ["Hydrogen","Oxygen","Sodium","Chlorine","Iron"]:
		if base not in _discovered:
			_discovered.append(base)

	_build_detail_overlay()
	_switch_tab(0)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.30)

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
	elif idx == 1:
		_build_achievement_tab()

# ════════════════════════════════════════════════════════════════
#  TAB 0 — Elements
# ════════════════════════════════════════════════════════════════
func _build_element_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(1152, 0)
	vbox.add_theme_constant_override("separation", 0)
	_content.add_child(vbox)

	# ── Elements section ──
	var elem_total := ELEMENTS.filter(func(e): return e["type"] != "Compound").size()
	var elem_disc_count := ELEMENTS.filter(func(e): return e["id"] in _discovered and e["type"] != "Compound").size()
	var sec := _section_label("ธาตุที่ค้นพบ  (%d/%d)" % [elem_disc_count, elem_total])
	vbox.add_child(sec)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grid_wrap := MarginContainer.new()
	grid_wrap.add_theme_constant_override("margin_left", 28)
	grid_wrap.add_theme_constant_override("margin_right", 28)
	grid_wrap.add_theme_constant_override("margin_top", 16)
	grid_wrap.add_theme_constant_override("margin_bottom", 24)
	grid_wrap.add_child(grid)
	vbox.add_child(grid_wrap)

	# show only discovered elements here
	var elem_found := ELEMENTS.filter(func(e): return e["id"] in _discovered)
	var elem_hidden := ELEMENTS.filter(func(e): return e["id"] not in _discovered)
	for elem in elem_found:
		grid.add_child(_make_element_card(elem))

	# ── Compounds + undiscovered elements section ──
	var all_keys: Array = ReactionDB.COMPOUNDS.keys()
	var comp_keys: Array = all_keys.filter(func(k): return k not in ELEM_COMPOUND_KEYS)
	var found_count := comp_keys.filter(func(k): return k in PlayerData.discovered_compounds).size()
	var total_undiscov := comp_keys.size() + elem_hidden.size()

	vbox.add_child(_section_label("สารประกอบที่ค้นพบ  (%d/%d)" % [found_count, total_undiscov]))

	var cgrid := GridContainer.new()
	cgrid.columns = 4
	cgrid.add_theme_constant_override("h_separation", 20)
	cgrid.add_theme_constant_override("v_separation", 20)
	cgrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cgrid_wrap := MarginContainer.new()
	cgrid_wrap.add_theme_constant_override("margin_left", 28)
	cgrid_wrap.add_theme_constant_override("margin_right", 28)
	cgrid_wrap.add_theme_constant_override("margin_top", 16)
	cgrid_wrap.add_theme_constant_override("margin_bottom", 24)
	cgrid_wrap.add_child(cgrid)
	vbox.add_child(cgrid_wrap)

	var comp_found := comp_keys.filter(func(k): return k in PlayerData.discovered_compounds)
	var comp_hidden := comp_keys.filter(func(k): return k not in PlayerData.discovered_compounds)
	for key in comp_found + comp_hidden:
		var compound: Dictionary = ReactionDB.COMPOUNDS[key]
		var is_found: bool = key in PlayerData.discovered_compounds
		cgrid.add_child(_make_compound_card(compound, is_found))
	# undiscovered elements go here too
	for elem in elem_hidden:
		cgrid.add_child(_make_element_card(elem))

func _make_element_card(elem: Dictionary) -> Control:
	var discovered: bool = elem["id"] in _discovered
	var card := Panel.new()
	card.custom_minimum_size = Vector2(260, 130)
	var col := elem["color"] as Color
	var border_col := Color(col.r, col.g, col.b, 0.6) if discovered else Color(0.3, 0.35, 0.5, 0.4)
	var bg_col := Color(col.r * 0.12, col.g * 0.12, col.b * 0.15, 1.0) if discovered else C_LOCK
	card.add_theme_stylebox_override("panel", _flat(bg_col, border_col, 10, 1))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.clip_contents = true

	if discovered:
		# Atomic number — top-left small
		if elem["number"] > 0:
			var num := Label.new()
			num.text = str(elem["number"])
			num.position = Vector2(8, 6)
			num.size = Vector2(30, 14)
			num.add_theme_font_size_override("font_size", 9)
			num.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.55))
			card.add_child(num)

		# Symbol — top-left large (like lab tile)
		var badge := Label.new()
		badge.text = elem["symbol"]
		badge.position = Vector2(8, 18)
		badge.size = Vector2(56, 36)
		badge.add_theme_font_size_override("font_size", 26)
		badge.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.95))
		card.add_child(badge)

		# Thai name — right of symbol
		var name_lbl := Label.new()
		name_lbl.text = elem["name_th"]
		name_lbl.position = Vector2(68, 10)
		name_lbl.size = Vector2(182, 20)
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", C_TEXT)
		card.add_child(name_lbl)

		# English name · type
		var sub := Label.new()
		sub.text = "%s  ·  %s" % [elem["name_en"], elem["type"]]
		sub.position = Vector2(68, 32)
		sub.size = Vector2(182, 16)
		sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sub.add_theme_font_size_override("font_size", 9)
		sub.add_theme_color_override("font_color", C_SUB)
		card.add_child(sub)

		# Divider
		var div := ColorRect.new()
		div.color = Color(col.r, col.g, col.b, 0.15)
		div.size = Vector2(240, 1)
		div.position = Vector2(10, 56)
		div.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(div)

		# Short desc — bottom area, clipped + wrapped
		var desc := Label.new()
		desc.text = elem["real_desc"]
		desc.position = Vector2(10, 62)
		desc.size = Vector2(240, 58)
		desc.add_theme_font_size_override("font_size", 9)
		desc.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.70))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.add_child(desc)

		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed:
				_open_element_detail(elem)
		)
	else:
		# Locked — style same as lab tile
		var q := Label.new()
		q.text = "?"
		q.size = Vector2(260, 80)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		q.add_theme_font_size_override("font_size", 32)
		q.add_theme_color_override("font_color", Color(0.4, 0.45, 0.6, 0.5))
		card.add_child(q)

		var locked_lbl := Label.new()
		locked_lbl.text = "ยังไม่ค้นพบ"
		locked_lbl.size = Vector2(260, 30)
		locked_lbl.position = Vector2(0, 88)
		locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_lbl.add_theme_font_size_override("font_size", 11)
		locked_lbl.add_theme_color_override("font_color", Color(0.45, 0.5, 0.65, 0.65))
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
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_open_achievement_detail(ach)
	)

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
	desc.size = Vector2(600, 20)
	desc.clip_text = true
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
		var ico := TextureRect.new()
		ico.texture = preload("res://image/crystal_gem.png")
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


func _make_compound_card(compound: Dictionary, is_found: bool) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(260, 130)
	card.clip_contents = true

	if is_found:
		card.add_theme_stylebox_override("panel", _flat(
			Color(0.05, 0.10, 0.22, 0.92), Color(0.35, 0.60, 1, 0.35), 10, 1))

		var fml := Label.new()
		fml.text = str(compound.get("formula", ""))
		fml.position = Vector2(8, 14)
		fml.size = Vector2(56, 32)
		fml.add_theme_font_size_override("font_size", 22)
		fml.add_theme_color_override("font_color", Color(0.48, 0.84, 1, 0.92))
		fml.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(fml)

		var nm := Label.new()
		nm.text = str(compound.get("name", ""))
		nm.position = Vector2(68, 10)
		nm.size = Vector2(182, 20)
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.add_theme_font_size_override("font_size", 14)
		nm.add_theme_color_override("font_color", Color(0.88, 0.93, 1, 0.90))
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)

		var tp := Label.new()
		tp.text = str(compound.get("type", ""))
		tp.position = Vector2(68, 32)
		tp.size = Vector2(182, 16)
		tp.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tp.add_theme_font_size_override("font_size", 9)
		tp.add_theme_color_override("font_color", Color(0.55, 0.75, 1, 0.55))
		tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(tp)

		var div := ColorRect.new()
		div.color = Color(0.3, 0.55, 1, 0.15)
		div.size = Vector2(240, 1)
		div.position = Vector2(10, 56)
		div.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(div)

		var desc := Label.new()
		desc.text = str(compound.get("description", ""))
		desc.position = Vector2(10, 62)
		desc.size = Vector2(240, 58)
		desc.add_theme_font_size_override("font_size", 9)
		desc.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.70))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(desc)
	else:
		card.add_theme_stylebox_override("panel", _flat(
			Color(0.04, 0.06, 0.12, 0.72), Color(0.20, 0.28, 0.48, 0.15), 10, 1))

		var q := Label.new()
		q.text = "?"
		q.size = Vector2(260, 80)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		q.add_theme_font_size_override("font_size", 32)
		q.add_theme_color_override("font_color", Color(0.4, 0.45, 0.6, 0.5))
		card.add_child(q)

		var locked_lbl := Label.new()
		locked_lbl.text = "ยังไม่ค้นพบ"
		locked_lbl.size = Vector2(260, 30)
		locked_lbl.position = Vector2(0, 88)
		locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_lbl.add_theme_font_size_override("font_size", 11)
		locked_lbl.add_theme_color_override("font_color", Color(0.45, 0.5, 0.65, 0.65))
		card.add_child(locked_lbl)

	return card

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
	const CW := 480.0; const CH := 420.0
	var card := Panel.new()
	card.size = Vector2(CW, CH)
	card.position = Vector2((1152 - CW) * 0.5, (648 - CH) * 0.5)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _flat(
		Color(0.06, 0.08, 0.16, 1.0),
		Color(col.r, col.g, col.b, 0.7), 12, 2
	))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_overlay.add_child(card)

	const IW := 440.0  # inner width

	# Symbol large
	var sym := Label.new()
	sym.text = elem["symbol"]
	sym.position = Vector2(20, 14)
	sym.size = Vector2(100, 64)
	sym.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sym.add_theme_font_size_override("font_size", 48)
	sym.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.85))
	sym.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sym)

	if elem["number"] > 0:
		var num := Label.new()
		num.text = "No. %d" % elem["number"]
		num.position = Vector2(24, 78)
		num.size = Vector2(80, 14)
		num.add_theme_font_size_override("font_size", 10)
		num.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.5))
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(num)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = elem["name_th"]
	name_lbl.position = Vector2(130, 16)
	name_lbl.size = Vector2(IW - 110, 30)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	var eng := Label.new()
	eng.text = elem["name_en"] + "  ·  " + elem["type"]
	eng.position = Vector2(130, 48)
	eng.size = Vector2(IW - 110, 20)
	eng.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	eng.add_theme_font_size_override("font_size", 12)
	eng.add_theme_color_override("font_color", C_SUB)
	eng.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(eng)

	# Divider
	var div := ColorRect.new()
	div.color = Color(col.r, col.g, col.b, 0.2)
	div.size = Vector2(IW, 1)
	div.position = Vector2(20, 100)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div)

	# Real-world desc
	var real_title := Label.new()
	real_title.text = "ข้อมูลจริง"
	real_title.position = Vector2(20, 110)
	real_title.size = Vector2(IW, 16)
	real_title.add_theme_font_size_override("font_size", 11)
	real_title.add_theme_color_override("font_color", C_GOLD)
	real_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(real_title)

	# Clip wrapper so autowrap text can't bleed into sections below
	var desc_clip := Panel.new()
	desc_clip.position = Vector2(20, 128)
	desc_clip.size = Vector2(IW, 116)
	desc_clip.clip_contents = true
	desc_clip.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0)))
	desc_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_clip)

	var real_desc := Label.new()
	real_desc.text = elem["real_desc"]
	real_desc.position = Vector2(0, 0)
	real_desc.size = Vector2(IW, 116)
	real_desc.add_theme_font_size_override("font_size", 11)
	real_desc.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0, 0.85))
	real_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	real_desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	real_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_clip.add_child(real_desc)

	# Divider 2
	var div2 := ColorRect.new()
	div2.color = Color(col.r, col.g, col.b, 0.12)
	div2.size = Vector2(IW, 1)
	div2.position = Vector2(20, 250)
	div2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div2)

	# How to get
	var how_title := Label.new()
	how_title.text = "วิธีได้รับ"
	how_title.position = Vector2(20, 258)
	how_title.size = Vector2(IW, 16)
	how_title.add_theme_font_size_override("font_size", 11)
	how_title.add_theme_color_override("font_color", C_GOLD)
	how_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(how_title)

	var how_clip := Panel.new()
	how_clip.position = Vector2(20, 276)
	how_clip.size = Vector2(IW, 20)
	how_clip.clip_contents = true
	how_clip.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0)))
	how_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(how_clip)

	var how := Label.new()
	how.text = elem["how_to_get"]
	how.position = Vector2(0, 0)
	how.size = Vector2(IW, 20)
	how.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	how.add_theme_font_size_override("font_size", 11)
	how.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0, 0.85))
	how.mouse_filter = Control.MOUSE_FILTER_IGNORE
	how_clip.add_child(how)

	# Divider 3
	var div3 := ColorRect.new()
	div3.color = Color(col.r, col.g, col.b, 0.12)
	div3.size = Vector2(IW, 1)
	div3.position = Vector2(20, 302)
	div3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div3)

	# Recipes / effects
	var rec_title := Label.new()
	rec_title.text = "ใช้ทำ / ผลในเกม"
	rec_title.position = Vector2(20, 310)
	rec_title.size = Vector2(IW, 16)
	rec_title.add_theme_font_size_override("font_size", 11)
	rec_title.add_theme_color_override("font_color", C_GOLD)
	rec_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rec_title)

	var ry := 328.0
	for r in elem["recipes"]:
		var rl := Label.new()
		rl.text = "• " + r
		rl.position = Vector2(20, ry)
		rl.size = Vector2(IW, 18)
		rl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		rl.add_theme_font_size_override("font_size", 11)
		rl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.65, 0.9))
		rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(rl)
		ry += 20

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.size = Vector2(32, 32)
	close_btn.position = Vector2(CW - 44, 10)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", C_SUB)
	close_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
	close_btn.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.08), Color(0,0,0,0)))
	close_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	close_btn.pressed.connect(func(): _detail_overlay.visible = false)
	card.add_child(close_btn)

	_detail_overlay.visible = true

func _open_achievement_detail(ach: Dictionary) -> void:
	for c in _detail_overlay.get_children():
		if c is Panel:
			c.queue_free()

	const CW := 520.0; const CH := 360.0
	var card := Panel.new()
	card.size = Vector2(CW, CH)
	card.position = Vector2((1152 - CW) * 0.5, (648 - CH) * 0.5)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _flat(
		Color(0.06, 0.08, 0.16, 1.0),
		Color(0.30, 0.85, 0.55, 0.55), 12, 2
	))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_overlay.add_child(card)

	const IW := 480.0

	# Icon + title row
	var icon_lbl := Label.new()
	icon_lbl.text = ach["icon"]
	icon_lbl.position = Vector2(20, 14)
	icon_lbl.size = Vector2(44, 44)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_lbl)

	var title_lbl := Label.new()
	title_lbl.text = ach["title"]
	title_lbl.position = Vector2(72, 14)
	title_lbl.size = Vector2(IW - 60, 28)
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", C_DONE if int(ach["current"]) >= int(ach["total"]) else C_TEXT)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = ach["desc"]
	sub_lbl.position = Vector2(72, 44)
	sub_lbl.size = Vector2(IW - 60, 18)
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", C_SUB)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sub_lbl)

	var div1 := ColorRect.new()
	div1.color = Color(0.30, 0.85, 0.55, 0.2)
	div1.size = Vector2(IW, 1)
	div1.position = Vector2(20, 72)
	div1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div1)

	# Detail text
	var det_title := Label.new()
	det_title.text = "รายละเอียด"
	det_title.position = Vector2(20, 82)
	det_title.size = Vector2(IW, 16)
	det_title.add_theme_font_size_override("font_size", 11)
	det_title.add_theme_color_override("font_color", C_GOLD)
	det_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(det_title)

	var det_clip := Panel.new()
	det_clip.position = Vector2(20, 100)
	det_clip.size = Vector2(IW, 80)
	det_clip.clip_contents = true
	det_clip.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0)))
	det_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(det_clip)

	var det_lbl := Label.new()
	det_lbl.text = str(ach.get("detail", ach["desc"]))
	det_lbl.position = Vector2(0, 0)
	det_lbl.size = Vector2(IW, 80)
	det_lbl.add_theme_font_size_override("font_size", 12)
	det_lbl.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0, 0.85))
	det_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	det_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	det_clip.add_child(det_lbl)

	var div2 := ColorRect.new()
	div2.color = Color(0.30, 0.85, 0.55, 0.12)
	div2.size = Vector2(IW, 1)
	div2.position = Vector2(20, 192)
	div2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div2)

	# Element cards row
	var elems_arr: Array = ach.get("elems", [])
	if not elems_arr.is_empty():
		var elem_title := Label.new()
		elem_title.text = "ธาตุที่เกี่ยวข้อง"
		elem_title.position = Vector2(20, 202)
		elem_title.size = Vector2(IW, 16)
		elem_title.add_theme_font_size_override("font_size", 11)
		elem_title.add_theme_color_override("font_color", C_GOLD)
		elem_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(elem_title)

		const MINI_W := 88.0; const MINI_H := 70.0; const MINI_GAP := 10.0
		var total_w := elems_arr.size() * MINI_W + (elems_arr.size() - 1) * MINI_GAP
		var ex := (CW - total_w) * 0.5
		for i in elems_arr.size():
			var eid: String = elems_arr[i]
			var edata: Dictionary = {}
			for e in ELEMENTS:
				if e["id"] == eid:
					edata = e
					break
			if edata.is_empty():
				continue
			var ecol: Color = edata.get("color", Color(0.5, 0.7, 1.0))
			var mini := Panel.new()
			mini.size = Vector2(MINI_W, MINI_H)
			mini.position = Vector2(ex + i * (MINI_W + MINI_GAP), 224)
			mini.clip_contents = true
			mini.add_theme_stylebox_override("panel", _flat(
				Color(ecol.r*0.15, ecol.g*0.15, ecol.b*0.22, 1.0),
				Color(ecol.r, ecol.g, ecol.b, 0.55), 8, 1
			))
			mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(mini)

			var sym := Label.new()
			sym.text = str(edata.get("symbol", "?"))
			sym.position = Vector2(0, 6)
			sym.size = Vector2(MINI_W, 30)
			sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sym.add_theme_font_size_override("font_size", 22)
			sym.add_theme_color_override("font_color", Color(ecol.r, ecol.g, ecol.b, 0.9))
			sym.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini.add_child(sym)

			var ename := Label.new()
			ename.text = str(edata.get("name_th", eid))
			ename.position = Vector2(2, 38)
			ename.size = Vector2(MINI_W - 4, 18)
			ename.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ename.add_theme_font_size_override("font_size", 9)
			ename.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0, 0.75))
			ename.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			ename.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini.add_child(ename)

			var etype := Label.new()
			etype.text = str(edata.get("type", ""))
			etype.position = Vector2(2, 52)
			etype.size = Vector2(MINI_W - 4, 14)
			etype.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			etype.add_theme_font_size_override("font_size", 8)
			etype.add_theme_color_override("font_color", Color(ecol.r, ecol.g, ecol.b, 0.5))
			etype.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			etype.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini.add_child(etype)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.size = Vector2(32, 32)
	close_btn.position = Vector2(CW - 44, 10)
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

func _make_back_btn(pos: Vector2, sz: Vector2, callback: Callable) -> Control:
	var btn := Panel.new()
	btn.position = pos
	btn.z_index = 20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.05, 0.15, 0.55)
	sb.border_color = Color(0.45, 0.72, 1.0, 0.90)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(22)
	btn.add_theme_stylebox_override("panel", sb)
	btn.size        = Vector2(42, 45)
	btn.pivot_offset = Vector2(21, 22)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
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
	SceneTransition.fade_to(SC_MAIN)
