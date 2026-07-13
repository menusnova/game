extends Node

# ── Master character list ────────────────────────────────────────
const ALL_CHARACTERS: Array[Dictionary] = [
	{"name": "Lyra",      "element": "🌀", "rarity": 5, "element_color": Color(0.5, 0.3, 1.0),   "owned": true},
	{"name": "Alchemist", "element": "⚗",  "rarity": 5, "element_color": Color(0.35, 0.75, 1.0),  "owned": false},
]

# Extended stat/lore data per character
const CHAR_DATA: Dictionary = {
	"Alchemist": {
		"title": "Master of Reactions",
		"faction": "Alchemist Guild",
		"roles": ["DPS", "Support"],
		"level": 0, "level_max": 30, "insight": 0,
		"atk": 229, "hp": 1601, "rdef": 136, "mdef": 121, "crit": 178, "def": 128,
		"bond": 12,
		"dialogue": "วันนี้อากาศดีนะ... เหมาะกับการทดลอง",
		"skills": [
			{"name": "Alchemical Strike", "type": "Basic ATK", "img": "res://image/lyra_1.png",
			 "desc": "โจมตีศัตรู 1 เป้าหมายด้วยพลังธาตุ สร้างความเสียหาย 20 DMG และชาร์จ Ultimate +15"},
			{"name": "Barrier Compound",  "type": "Defend",    "img": "res://image/lyra_2.png",
			 "desc": "สร้างเกราะป้องกันให้ตัวเอง ลดความเสียหายที่ได้รับ 30% เป็นเวลา 1 รอบ"},
			{"name": "Chain Reaction",    "type": "Skill",     "img": "res://image/lyra_3.png",
			 "desc": "จั๋วการ์ดธาตุ 1 ใบขึ้นมือ และฟื้นฟู AP เต็มในเทิร์นถัดไป (ใช้ได้ 1 ครั้งต่อการกด)"},
			{"name": "Element Burst",     "type": "Ultimate",  "img": "res://image/lyra_1.png",
			 "desc": "จั๋วการ์ดธาตุที่ผสมกันได้ 2 ใบขึ้นมือทันที เพิ่มโอกาสสร้าง Reaction ในเทิร์นนั้น"},
		],
		"passive": {
			"name": "Reaction Master",
			"desc": "เมื่อสังเคราะห์สารประกอบสำเร็จ Ultimate Gauge ชาร์จ +10 และพิษ/เผาไหม้ +15%",
		},
	},
	"Lyra": {
		"title": "Void Walker",
		"faction": "Free Spirit",
		"roles": ["DPS"],
		"level": 0, "level_max": 30, "insight": 0,
		"atk": 310, "hp": 1420, "rdef": 110, "mdef": 98, "crit": 205, "def": 104,
		"bond": 0,
		"dialogue": "void ไม่โกหก มันแสดงทุกอย่าง",
		"skills": [
			{"name": "Void Strike",   "type": "Basic ATK", "img": "res://image/lyra_2.png",
			 "icon": "res://image/skill_void_strike.jpg",
			 "desc_short": "1 AP · โจมตี 1 เป้าหมาย 24 DMG (รวม Passive = 29)",
			 "desc": "เงื่อนไข: ใช้ 1 AP ต่อครั้ง ไม่มี cooldown\nใช้ไม่ได้ถ้ากำลัง Defend อยู่ในเทิร์นนี้ (เลือกได้แค่ Attack หรือ Defend อย่างเดียว)\n\nผล: โจมตีเป้าหมาย 1 ตัว ดีลดาเมจ 24 DMG (รวม Void Resonance +20% = 29 DMG)",
			 "dmg": 24, "target": "single", "cooldown": 0},
			{"name": "Null Barrier",  "type": "Defend",    "img": "res://image/lyra_1.png",
			 "icon": "res://image/skill_null_barrier.jpg",
			 "desc_short": "0 AP · ลดดาเมจที่รับ 50% ไม่เสียเทิร์น",
			 "desc": "เงื่อนไข: ไม่ใช้ AP ไม่มี cooldown\nใช้แทน Attack ได้อย่างเดียว (เลือกได้แค่อย่างใดอย่างหนึ่งต่อเทิร์น) แต่ยังใช้ Skill/Ultimate ต่อได้ในเทิร์นเดียวกัน\nฤทธิ์หมดทันทีที่โดนศัตรูโจมตี 1 ครั้ง\n\nผล: ลดดาเมจที่รับ 50% จนกว่าจะโดนตี",
			 "dmg": 0, "target": "self", "cooldown": 0},
			{"name": "Aether Pulse",  "type": "Skill",     "img": "res://image/lyra_3.png",
			 "icon": "res://image/skill_aether_pulse.jpg",
			 "desc_short": "0 AP · CD 3 เทิร์น · ฟื้น HP 15% + Void Shield",
			 "desc": "เงื่อนไข: ไม่ใช้ AP cooldown 3 เทิร์นหลังใช้งาน\nใช้ไม่ได้ถ้า Attack ไปแล้วในเทิร์นนี้ แต่ใช้ได้แม้ Defend ไปแล้ว\n\nผล: ฟื้น HP 15% ของ HP สูงสุด และสร้าง Void Shield ที่รับดาเมจแทน HP ได้ 1 ครั้ง (หายไปทันทีที่ถูกใช้ดูดดาเมจ)",
			 "dmg": 0, "target": "self", "cooldown": 3},
			{"name": "Absolute Zero Formula", "type": "Ultimate", "img": "res://image/lyra_2.png",
			 "icon": "res://image/skill_absolute_zero_formula.jpg",
			 "desc_short": "ต้อง Gauge เต็ม · 55 DMG ทุกตัว + ลด ATK ศัตรู 30%",
			 "desc": "เงื่อนไข: ต้องสะสม Ultimate Gauge ให้เต็ม 100/100 ก่อนถึงจะใช้ได้\nใช้ได้แค่ 1 ครั้งต่อเทิร์น ใช้ร่วมกับ Attack/Defend/Skill ได้อิสระ ไม่ผูกกัน\nGauge รีเซ็ตเป็น 0 ทันทีหลังใช้\n\nผล: ดีลดาเมจ 55 DMG ให้ศัตรูทุกตัว (รวม Void Resonance +20% = 66 DMG)\nลด ATK ศัตรูทุกตัว 30% เป็นเวลา 2 เทิร์น",
			 "dmg": 55, "target": "all", "cooldown": 0},
		],
		"passive": {
			"name": "Void Resonance",
			"icon": "res://image/skill_void_resonance.jpg",
			"desc_short": "ทำงานตลอดเวลา · โจมตีทุกครั้งเพิ่มดาเมจ 20%",
			"desc": "เงื่อนไข: ทำงานอัตโนมัติตลอดเวลา ไม่ต้องกดใช้ ไม่มีเงื่อนไขพิเศษ\n\nผล: ทุกครั้งที่ Lyra โจมตี (Basic ATK และ Ultimate) ดาเมจเพิ่มขึ้น 20%",
			"dmg_bonus": 0.20,
		},
	},
}

# Which character is currently viewed in character_scene
var selected_character: String = "Lyra"

var _owned: Dictionary = {}
var _locked: Dictionary = {}

signal character_unlocked(char_name: String)

func _ready() -> void:
	for c in ALL_CHARACTERS:
		if c["owned"]:
			_owned[c["name"]] = true

func is_owned(char_name: String) -> bool:
	return _owned.has(char_name)

func unlock(char_name: String) -> void:
	if _has_character(char_name) and not _owned.has(char_name):
		_owned[char_name] = true
		character_unlocked.emit(char_name)

func get_roster() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in ALL_CHARACTERS:
		var entry: Dictionary = c.duplicate()
		entry["owned"] = _owned.has(c["name"])
		result.append(entry)
	return result

func get_character_data(char_name: String) -> Dictionary:
	return CHAR_DATA.get(char_name, {})

func is_locked(char_name: String) -> bool:
	return _locked.has(char_name)

func toggle_lock(char_name: String) -> void:
	if _locked.has(char_name):
		_locked.erase(char_name)
	else:
		_locked[char_name] = true

func _has_character(char_name: String) -> bool:
	for c in ALL_CHARACTERS:
		if c["name"] == char_name:
			return true
	return false
