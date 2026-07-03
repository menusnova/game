extends Node

signal currency_changed

const SAVE_PATH    := "user://currency_save.cfg"
const MAX_ENERGY   := 240
const ENERGY_REGEN := 360.0   # วินาทีต่อ 1 พลังงาน (6 นาที)

# เงิน (ทอง), คริสตัลฟรี (ฟาร์มได้), พลังงาน
var gold:        int = 5000000 # 💰 เหรียญทอง
var free_crystal: int = 100000 # 💠 คริสตัลฟรี  (สีฟ้าสด)
var energy:       int = 240    # ⚡ พลังงาน

var _regen_acc: float = 0.0   # เศษวินาทีสะสม

func _ready() -> void:
	_load()
	set_process(true)

func _process(delta: float) -> void:
	if energy >= MAX_ENERGY:
		_regen_acc = 0.0
		return
	_regen_acc += delta
	if _regen_acc >= ENERGY_REGEN:
		var gained: int = int(_regen_acc / ENERGY_REGEN)
		_regen_acc = fmod(_regen_acc, ENERGY_REGEN)
		energy = mini(energy + gained, MAX_ENERGY)
		_save()
		currency_changed.emit()

# ── Getters ───────────────────────────────────────────────────────
func total_crystal() -> int:
	return free_crystal

func total_gems() -> int:
	return total_crystal()

func energy_seconds_to_full() -> int:
	if energy >= MAX_ENERGY:
		return 0
	var needed: int = MAX_ENERGY - energy
	return int(needed * ENERGY_REGEN - _regen_acc)

func next_regen_seconds() -> int:
	if energy >= MAX_ENERGY:
		return 0
	return int(ENERGY_REGEN - _regen_acc)

# ── Spenders ──────────────────────────────────────────────────────
func spend_energy(amount: int) -> bool:
	if energy < amount:
		return false
	energy -= amount
	_regen_acc = 0.0
	_save()
	currency_changed.emit()
	return true

func spend_gems(amount: int) -> bool:
	return spend_crystal(amount)

func spend_crystal(amount: int) -> bool:
	if total_crystal() < amount:
		return false
	free_crystal -= amount
	_save()
	currency_changed.emit()
	return true

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	_save()
	currency_changed.emit()
	return true

func add_gold(amount: int) -> void:
	gold += amount
	_save()
	currency_changed.emit()

func add_free_crystal(amount: int) -> void:
	free_crystal += amount
	_save()
	currency_changed.emit()

func add_energy(amount: int) -> void:
	energy = mini(energy + amount, MAX_ENERGY)
	_save()
	currency_changed.emit()

# ── Save / Load ───────────────────────────────────────────────────
func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("currency", "gold",         gold)
	cfg.set_value("currency", "free_crystal", free_crystal)
	cfg.set_value("currency", "energy",       energy)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		gold         = int(cfg.get_value("currency", "gold",         5000000))
		free_crystal = int(cfg.get_value("currency", "free_crystal", 100000))
		energy       = int(cfg.get_value("currency", "energy",       240))
