extends Node

# ── Master character list ────────────────────────────────────────
const ALL_CHARACTERS: Array[Dictionary] = [
	{"name": "Alchemist", "element": "⚗",  "rarity": 5, "element_color": Color(0.35, 0.75, 1.0),  "owned": false},
	{"name": "Lyra",      "element": "🌀", "rarity": 5, "element_color": Color(0.5, 0.3, 1.0),   "owned": true},
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
			 "desc": "โจมตีเป้าหมาย 1 ตัว ดีลดาเมจ 24 DMG (รวม Passive +20% = 28.8 DMG)\nไม่มี cooldown",
			 "dmg": 24, "target": "single", "cooldown": 0},
			{"name": "Null Barrier",  "type": "Defend",    "img": "res://image/lyra_1.png",
			 "desc": "ลดดาเมจที่รับ 50% ค้างจนศัตรูตี\nไม่เสียเทิร์น — ใช้ skill/ultimate ระหว่าง guard ได้",
			 "dmg": 0, "target": "self", "cooldown": 0},
			{"name": "Aether Pulse",  "type": "Skill",     "img": "res://image/lyra_3.png",
			 "desc": "ซับพลัง void เข้าตัวเอง ฟื้น HP 15%\nสร้าง Void Shield รับดาเมจแทน HP ได้ 1 ครั้ง\ncooldown 3 เทิร์น",
			 "dmg": 0, "target": "self", "cooldown": 3},
			{"name": "Absolute Zero Formula", "type": "Ultimate", "img": "res://image/lyra_2.png",
			 "desc": "ดีลดาเมจ 55 DMG ศัตรูทุกตัว\ndebuff ลด ATK ศัตรู 30% เป็นเวลา 2 เทิร์น\nต้องสะสม Ultimate Gauge ก่อน",
			 "dmg": 55, "target": "all", "cooldown": 0},
		],
		"passive": {
			"name": "Void Resonance",
			"desc": "ทำงานอัตโนมัติตลอดเวลา\nทุกการโจมตีของ Lyra สร้างดาเมจเพิ่มขึ้น 20%",
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
