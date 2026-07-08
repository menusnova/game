extends Node

const SAVE_PATH := "user://player_data.cfg"

signal profile_changed

var player_name:        String        = "Trailblazer"
var signature:          String        = "\"ความลับของสูตรนั้น... ยังไม่จบ\""
var avatar_idx:         int           = 0
var level:              int           = 42
var uid:                String        = "000000001"
var discovered_compounds:  Array[String] = []
var discovered_elements:   Array[String] = []
var discovered_recipes:    Array[String] = []

func _ready() -> void:
	pass

func save_profile(new_name: String, new_sig: String, new_avatar: int) -> void:
	player_name = new_name
	signature   = new_sig
	avatar_idx  = new_avatar
	_save()
	profile_changed.emit()

func discover_compound(key: String) -> void:
	if key not in discovered_compounds:
		discovered_compounds.append(key)
		_save()

func discover_element(id: String) -> void:
	if id not in discovered_elements:
		discovered_elements.append(id)
		_save()

func discover_recipe(key: String) -> void:
	if key not in discovered_recipes:
		discovered_recipes.append(key)
		_save()

func set_avatar(idx: int) -> void:
	avatar_idx = idx
	_save()
	profile_changed.emit()

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "player_name", player_name)
	cfg.set_value("profile", "signature",   signature)
	cfg.set_value("profile", "avatar_idx",  avatar_idx)
	cfg.set_value("profile", "level",       level)
	cfg.set_value("profile", "uid",               uid)
	cfg.set_value("profile", "discovered_compounds", discovered_compounds)
	cfg.set_value("profile", "discovered_elements",  discovered_elements)
	cfg.set_value("profile", "discovered_recipes",   discovered_recipes)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	player_name = cfg.get_value("profile", "player_name", player_name)
	signature   = cfg.get_value("profile", "signature",   signature)
	avatar_idx  = cfg.get_value("profile", "avatar_idx",  avatar_idx)
	level       = cfg.get_value("profile", "level",       level)
	uid         = cfg.get_value("profile", "uid",         uid)
	discovered_compounds.assign(cfg.get_value("profile", "discovered_compounds", []))
	discovered_elements.assign(cfg.get_value("profile",  "discovered_elements",  []))
	discovered_recipes.assign(cfg.get_value("profile",   "discovered_recipes",   []))
