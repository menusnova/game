extends Node

# ── Master character list ────────────────────────────────────────
const ALL_CHARACTERS: Array[Dictionary] = [
	{"name": "Alchemist", "element": "⚗",  "rarity": 5, "element_color": Color(0.35, 0.75, 1.0),  "owned": true},
	{"name": "Lyra",      "element": "🔥", "rarity": 5, "element_color": Color(1.0,  0.45, 0.2),   "owned": false},
	{"name": "Seraph",    "element": "✦",  "rarity": 5, "element_color": Color(1.0,  0.78, 0.2),   "owned": false},
]

# Extended stat/lore data per character
const CHAR_DATA: Dictionary = {
	"Alchemist": {
		"title": "Master of Reactions",
		"faction": "Alchemist Guild",
		"roles": ["DPS", "Support"],
		"level": 4, "level_max": 30, "insight": 0,
		"atk": 229, "hp": 1601, "rdef": 136, "mdef": 121, "crit": 178,
		"bond": 12,
		"dialogue": "วันนี้อากาศดีนะ... เหมาะกับการทดลอง",
		"skills": [
			{"name": "Element Burst", "type": "Attack", "img": "res://image/lyra_1.png"},
			{"name": "Chain Strike",  "type": "Attack", "img": "res://image/lyra_2.png"},
			{"name": "Alchemic Aura", "type": "Buff",   "img": "res://image/lyra_3.png"},
		],
	},
	"Lyra": {
		"title": "Flame Walker",
		"faction": "Free Spirit",
		"roles": ["DPS"],
		"level": 1, "level_max": 30, "insight": 0,
		"atk": 310, "hp": 1420, "rdef": 110, "mdef": 98, "crit": 205,
		"bond": 0,
		"dialogue": "ไฟไม่โกหก มันแสดงทุกอย่าง",
		"skills": [
			{"name": "Flame Slash",  "type": "Attack",  "img": "res://image/lyra_2.png"},
			{"name": "Inferno",      "type": "Attack",  "img": "res://image/lyra_1.png"},
			{"name": "Ember Field",  "type": "Buff",    "img": "res://image/lyra_3.png"},
		],
	},
	"Seraph": {
		"title": "Light Weaver",
		"faction": "Celestial Order",
		"roles": ["Support", "Control"],
		"level": 1, "level_max": 30, "insight": 0,
		"atk": 188, "hp": 1820, "rdef": 155, "mdef": 168, "crit": 142,
		"bond": 0,
		"dialogue": "แสงสว่างจะนำทางพวกเรา",
		"skills": [
			{"name": "Star Pulse",  "type": "Attack",  "img": "res://image/lyra_3.png"},
			{"name": "Holy Guard",  "type": "Support", "img": "res://image/lyra_1.png"},
			{"name": "Divine Veil", "type": "Buff",    "img": "res://image/lyra_2.png"},
		],
	},
}

# Which character is currently viewed in character_scene
var selected_character: String = "Alchemist"

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
