extends Node

signal domain_changed(percent: float)

const SAVE_PATH := "user://domain_save.cfg"
const MAX_POINTS := 100

# คะแนนต่อกิจกรรม
const POINTS := {
	"gacha":     10,
	"battle":    15,
	"alchemist": 12,
	"mission":   20,
	"arena":      8,
	"expedition": 6,
}

var _points: float = 0.0
var _last_reset_day: int = -1

func _ready() -> void:
	_load()
	_check_daily_reset()

func add_points(source: String) -> void:
	_check_daily_reset()
	var gain: float = POINTS.get(source, 5)
	_points = minf(_points + gain, MAX_POINTS)
	_save()
	domain_changed.emit(get_percent())

func get_percent() -> float:
	return (_points / MAX_POINTS) * 100.0

func _check_daily_reset() -> void:
	var today := Time.get_date_dict_from_system()
	var day_of_year := today["day"] + today["month"] * 31
	if day_of_year != _last_reset_day:
		_points = 0.0
		_last_reset_day = day_of_year
		_save()
		domain_changed.emit(0.0)

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("domain", "points", _points)
	cfg.set_value("domain", "reset_day", _last_reset_day)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_points = cfg.get_value("domain", "points", 0.0)
		_last_reset_day = cfg.get_value("domain", "reset_day", -1)
