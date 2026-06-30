extends Control

const SC_MAIN := "res://main_menu.tscn"
const PULL_COST_1  := 160
const PULL_COST_10 := 1600
const PITY_HARD    := 90
const PITY_SOFT    := 75
const RATE_5 := 0.016
const RATE_4 := 0.051
# ที่เหลือเป็น 3★

# pool ตัวอย่าง — key=ชื่อ, value=rarity (5/4/3)
const POOL_5: Array[String] = ["Lyra", "Seraph"]
const POOL_4: Array[String] = ["Kael", "Mira", "Voss"]
const POOL_3: Array[String] = ["Common Shard", "Iron Catalyst", "Void Dust"]

var _gems    := 3200   # เริ่มต้น demo
var _pity    := 0
var _pity_4  := 0      # pity 4★ (รับประกัน 10)

@onready var _pull1:      Button      = $PullBtn1
@onready var _pull10:     Button      = $PullBtn10
@onready var _back:       Button      = $BackBtn
@onready var _pity_bar:   ProgressBar = $BannerCard/PityBar
@onready var _pity_lbl:   Label       = $BannerCard/PityLabel
@onready var _gem_lbl:    Label       = $InfoPanel/CurrencyRow/GemCount
@onready var _result_ov:  Control     = $ResultOverlay
@onready var _result_con: HBoxContainer = $ResultOverlay/ResultContainer
@onready var _skip_btn:   Button      = $ResultOverlay/SkipBtn

func _ready() -> void:
	_pull1.pressed.connect(func(): _do_pull(1))
	_pull10.pressed.connect(func(): _do_pull(10))
	_back.pressed.connect(_go_back)
	_skip_btn.pressed.connect(func(): _result_ov.visible = false)
	_refresh_ui()

func _refresh_ui() -> void:
	_gem_lbl.text = str(_gems)
	_pity_bar.value = _pity
	_pity_lbl.text = "%d / %d" % [_pity, PITY_HARD]
	_pull1.disabled  = _gems < PULL_COST_1
	_pull10.disabled = _gems < PULL_COST_10

func _do_pull(count: int) -> void:
	var cost := PULL_COST_10 if count == 10 else PULL_COST_1 * count
	if _gems < cost:
		return
	_gems -= cost
	var results:  Array[String] = []
	var rarities: Array[int]    = []
	for i in count:
		var r: Array = _roll()
		results.append(str(r[0]))
		rarities.append(int(r[1]))
	DomainManager.add_points("gacha")
	_refresh_ui()
	_show_results(results, rarities)

func _roll() -> Array:
	_pity   += 1
	_pity_4 += 1
	# hard pity
	if _pity >= PITY_HARD:
		_pity = 0
		_pity_4 = 0
		return [POOL_5[randi() % POOL_5.size()], 5]
	# 4★ pity
	if _pity_4 >= 10:
		_pity_4 = 0
		return [POOL_4[randi() % POOL_4.size()], 4]
	# soft pity (linear ramp 75→90)
	var rate5 := RATE_5
	if _pity >= PITY_SOFT:
		rate5 = RATE_5 + 0.06 * (_pity - PITY_SOFT)
	rate5 = minf(rate5, 1.0)
	var roll := randf()
	if roll < rate5:
		_pity = 0
		return [POOL_5[randi() % POOL_5.size()], 5]
	if roll < rate5 + RATE_4:
		_pity_4 = 0
		return [POOL_4[randi() % POOL_4.size()], 4]
	return [POOL_3[randi() % POOL_3.size()], 3]

func _show_results(names: Array[String], rarities: Array[int]) -> void:
	for child in _result_con.get_children():
		child.queue_free()
	for i in names.size():
		_result_con.add_child(_make_card(names[i], rarities[i], names.size()))
	_result_ov.visible = true

func _make_card(char_name: String, rarity: int, total: int) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(88, 120) if total > 1 else Vector2(160, 280)
	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_width_left = 1
	match rarity:
		5:
			sb.bg_color = Color(0.15, 0.12, 0.04, 0.95)
			sb.border_color = Color(1.0, 0.82, 0.2, 0.8)
		4:
			sb.bg_color = Color(0.1, 0.06, 0.18, 0.95)
			sb.border_color = Color(0.65, 0.45, 1.0, 0.8)
		_:
			sb.bg_color = Color(0.06, 0.1, 0.2, 0.95)
			sb.border_color = Color(0.37, 0.62, 1.0, 0.3)
	card.add_theme_stylebox_override("panel", sb)

	var stars_lbl := Label.new()
	var star_char := "★"
	stars_lbl.text = star_char.repeat(rarity)
	stars_lbl.add_theme_font_size_override("font_size", 10)
	match rarity:
		5: stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
		4: stars_lbl.add_theme_color_override("font_color", Color(0.75, 0.55, 1.0))
		_: stars_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	stars_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stars_lbl.offset_bottom = -6
	stars_lbl.offset_left = 6
	stars_lbl.offset_right = 84
	stars_lbl.offset_top = -22
	card.add_child(stars_lbl)

	var name_lbl := Label.new()
	name_lbl.text = char_name
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -24
	name_lbl.offset_bottom = -6
	card.add_child(name_lbl)

	return card

func _go_back() -> void:
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(SC_MAIN)
