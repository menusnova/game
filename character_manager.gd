extends Node

# ── Master character list ────────────────────────────────────────
# owned: starts true for starter chars, false = locked until pulled
const ALL_CHARACTERS: Array[Dictionary] = [
	{"name": "Alchemist", "element": "⚗",  "rarity": 5, "element_color": Color(0.35, 0.75, 1.0),  "owned": true},
	{"name": "Lyra",      "element": "🔥", "rarity": 5, "element_color": Color(1.0,  0.45, 0.2),   "owned": true},
	{"name": "Seraph",    "element": "✦",  "rarity": 5, "element_color": Color(1.0,  0.78, 0.2),   "owned": false},
]

# runtime ownership set (name → true)
var _owned: Dictionary = {}
# locked characters cannot be used as fodder
var _locked: Dictionary = {}

signal character_unlocked(char_name: String)

func _ready() -> void:
	for c in ALL_CHARACTERS:
		if c["owned"]:
			_owned[c["name"]] = true

func is_owned(char_name: String) -> bool:
	return _owned.has(char_name)

# called by gacha after a pull
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
