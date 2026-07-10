extends Node

# ── Master character list ────────────────────────────────────────
const ALL_CHARACTERS: Array[Dictionary] = [
	{"name": "Alchemist", "element": "⚗",  "rarity": 5, "element_color": Color(0.35, 0.75, 1.0),  "owned": true},
	{"name": "Lyra",      "element": "🔥", "rarity": 5, "element_color": Color(1.0,  0.45, 0.2),   "owned": true},
	{"name": "Seraph",    "element": "✦",  "rarity": 5, "element_color": Color(1.0,  0.78, 0.2),   "owned": false},
]

# Extended stat/lore data per character
const CHAR_DATA: Dictionary = {
	"Alchemist": {
		"title": "Master of Reactions",
		"faction": "Alchemist Guild",
		"roles": ["DPS", "Support"],
		"level": 4, "level_max": 30, "insight": 0,
		"atk": 229, "hp": 1601, "rdef": 136, "mdef": 121, "crit": 178, "def": 128,
		"bond": 12,
		"dialogue": "วันนี้อากาศดีนะ... เหมาะกับการทดลอง",
		"skills": [
			{"name": "Alchemical Strike", "type": "Basic ATK", "img": "res://image/lyra_1.png",
			 "desc": "โจมตีศัตรู 1 เป้าหมายด้วยพลังธาตุ สร้างความเสียหาย 20 DMG และชาร์จ Ultimate +15"},
			{"name": "Barrier Compound",  "type": "Defend",    "img": "res://image/lyra_2.png",
			 "desc": "สร้างเกราะป้องกันให้ตัวเอง ลดความเสียหายที่ได้รับ 30% เป็นเวลา 1 รอบ"},
			{"name": "Chain Reaction",    "type": "Skill",     "img": "res://image/lyra_3.png",
			 "desc": "ปล่อยพลังธาตุโจมตีศัตรู 40 DMG ลดการโจมตีของศัตรู 20% เป็นเวลา 1 รอบ"},
			{"name": "Element Burst",     "type": "Ultimate",  "img": "res://image/lyra_1.png",
			 "desc": "ปลดปล่อยพลังธาตุทั้งหมดพร้อมกัน สร้างความเสียหาย 60 DMG วางพิษและเผาไหม้ศัตรู"},
		],
		"passive": {
			"name": "Reaction Master",
			"desc": "เมื่อสังเคราะห์สารประกอบสำเร็จ Ultimate Gauge ชาร์จ +10 และพิษ/เผาไหม้ +15%",
		},
	},
	"Lyra": {
		"title": "Flame Walker",
		"faction": "Free Spirit",
		"roles": ["DPS"],
		"level": 1, "level_max": 30, "insight": 0,
		"atk": 310, "hp": 1420, "rdef": 110, "mdef": 98, "crit": 205, "def": 104,
		"bond": 0,
		"dialogue": "ไฟไม่โกหก มันแสดงทุกอย่าง",
		"skills": [
			{"name": "Flame Strike",  "type": "Basic ATK", "img": "res://image/lyra_2.png",
			 "desc": "โจมตีศัตรู 1 เป้าหมายด้วยเปลวไฟ สร้างความเสียหาย 24 DMG"},
			{"name": "Heat Shield",   "type": "Defend",    "img": "res://image/lyra_1.png",
			 "desc": "ห่อหุ้มร่างด้วยเปลวไฟ สะท้อนความเสียหาย 10 DMG ต่อการโจมตีทุกครั้งใน 1 รอบ"},
			{"name": "Inferno",       "type": "Skill",     "img": "res://image/lyra_3.png",
			 "desc": "ปล่อยพลังไฟโจมตีศัตรู 1 เป้าหมาย 45 DMG และสุ่มเผาไหม้ 3 รอบ"},
			{"name": "Ember Field",   "type": "Ultimate",  "img": "res://image/lyra_2.png",
			 "desc": "สร้างสนามไฟล้อมรอบศัตรูทุกตัว 55 DMG ต่อรอบ เป็นเวลา 2 รอบ"},
		],
		"passive": {
			"name": "Wildfire",
			"desc": "เมื่อศัตรูมีสถานะเผาไหม้ ทุกการโจมตีของ Lyra สร้างความเสียหายเพิ่มขึ้น 20%",
		},
	},
	"Seraph": {
		"title": "Light Weaver",
		"faction": "Celestial Order",
		"roles": ["Support", "Control"],
		"level": 1, "level_max": 30, "insight": 0,
		"atk": 188, "hp": 1820, "rdef": 155, "mdef": 168, "crit": 142, "def": 161,
		"bond": 0,
		"dialogue": "แสงสว่างจะนำทางพวกเรา",
		"skills": [
			{"name": "Star Pulse",   "type": "Basic ATK", "img": "res://image/lyra_3.png",
			 "desc": "ยิงพลังแสงสว่างใส่ศัตรู 1 เป้าหมาย สร้างความเสียหาย 16 DMG"},
			{"name": "Holy Guard",   "type": "Defend",    "img": "res://image/lyra_1.png",
			 "desc": "สร้างเกราะแสงศักดิ์สิทธิ์ให้พันธมิตรทุกคน ลดความเสียหาย 25% เป็นเวลา 1 รอบ"},
			{"name": "Starfall",     "type": "Skill",     "img": "res://image/lyra_2.png",
			 "desc": "เรียกแสงดาวโจมตีศัตรูทุกตัว 28 DMG และชะลอความเร็ว 1 รอบ"},
			{"name": "Divine Veil",  "type": "Ultimate",  "img": "res://image/lyra_3.png",
			 "desc": "ปกคลุมพันธมิตรด้วยม่านแสงศักดิ์สิทธิ์ ฟื้นฟู HP 40 และกันความเสียหาย 1 ครั้ง"},
		],
		"passive": {
			"name": "Celestial Grace",
			"desc": "เมื่อ Seraph ใช้ Defend หรือ Ultimate HP ของพันธมิตรทุกคนฟื้นฟูเพิ่มขึ้น 10% และ MDEF +15%",
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
