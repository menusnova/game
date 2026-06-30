extends Control

const SC_MAIN := "res://main_menu.tscn"
const PULL_COST_1  := 160
const PULL_COST_10 := 1600
const PITY_HARD    := 90
const PITY_SOFT    := 75
const RATE_5 := 0.016
const RATE_4 := 0.051

const POOL_5: Array[String] = ["Lyra", "Seraph"]
const POOL_4: Array[String] = ["Kael", "Mira", "Voss"]
const POOL_3: Array[String] = ["Common Shard", "Iron Catalyst", "Void Dust"]

var _gems   := 3200
var _pity   := 0
var _pity_4 := 0

var _revealing   := false
var _skip_to_end := false

@onready var _pull1:      Button        = $PullBtn1
@onready var _pull10:     Button        = $PullBtn10
@onready var _back:       Button        = $BackBtn
@onready var _pity_bar:   ProgressBar   = $BannerCard/PityBar
@onready var _pity_lbl:   Label         = $BannerCard/PityLabel
@onready var _gem_lbl:    Label         = $InfoPanel/CurrencyRow/GemCount
@onready var _result_ov:  Control       = $ResultOverlay
@onready var _result_con: HBoxContainer = $ResultOverlay/ResultContainer
@onready var _skip_btn:   Button        = $ResultOverlay/SkipBtn

func _ready() -> void:
	_pull1.pressed.connect(func(): _do_pull(1))
	_pull10.pressed.connect(func(): _do_pull(10))
	_back.pressed.connect(_go_back)
	_skip_btn.pressed.connect(_on_skip)
	_result_ov.visible = false
	_refresh_ui()

func _input(ev: InputEvent) -> void:
	if not _revealing:
		return
	if ev is InputEventMouseButton and ev.pressed:
		_skip_to_end = true

func _on_skip() -> void:
	if _revealing:
		_skip_to_end = true
	else:
		_result_ov.visible = false

func _refresh_ui() -> void:
	_gem_lbl.text = str(_gems)
	_pity_bar.value = _pity
	_pity_lbl.text = "%d / %d" % [_pity, PITY_HARD]
	_pull1.disabled  = _gems < PULL_COST_1
	_pull10.disabled = _gems < PULL_COST_10

# ── Pull ──────────────────────────────────────────────────────────
func _do_pull(count: int) -> void:
	if _revealing:
		return
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
	_run_reveal(results, rarities)

func _roll() -> Array:
	_pity   += 1
	_pity_4 += 1
	if _pity >= PITY_HARD:
		_pity = 0; _pity_4 = 0
		return [POOL_5[randi() % POOL_5.size()], 5]
	if _pity_4 >= 10:
		_pity_4 = 0
		return [POOL_4[randi() % POOL_4.size()], 4]
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

# ── Arknights-style sequential reveal ────────────────────────────
func _run_reveal(names: Array[String], rarities: Array[int]) -> void:
	_revealing   = true
	_skip_to_end = false
	_skip_btn.text = "SKIP"

	for child in _result_con.get_children():
		child.queue_free()

	_result_ov.visible = true
	_result_con.visible = false

	# dim background
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.z_index = 5
	_result_ov.add_child(dim)
	var td := dim.create_tween()
	td.tween_property(dim, "color:a", 0.82, 0.4)
	await td.finished

	# reveal one by one
	for i in names.size():
		if _skip_to_end:
			break
		await _reveal_one(names[i], rarities[i], names.size(), i)
		if not _skip_to_end:
			var delay := 0.55 if rarities[i] == 5 else 0.28
			await get_tree().create_timer(delay).timeout

	# remove dim, show summary grid
	dim.queue_free()
	_result_con.visible = true
	for i in names.size():
		_result_con.add_child(_make_summary_card(names[i], rarities[i]))

	_revealing   = false
	_skip_to_end = false
	_skip_btn.text = "CLOSE"

func _reveal_one(char_name: String, rarity: int, total: int, _idx: int) -> void:
	if rarity == 5:
		await _reveal_5star(char_name)
	else:
		await _reveal_normal(char_name, rarity)

# ── Normal reveal (3★ / 4★) ──────────────────────────────────────
func _reveal_normal(char_name: String, rarity: int) -> void:
	var color_border: Color
	var color_glow:   Color
	var color_stars:  Color
	match rarity:
		4:
			color_border = Color(0.72, 0.45, 1.0, 1.0)
			color_glow   = Color(0.55, 0.25, 1.0, 0.55)
			color_stars  = Color(0.78, 0.55, 1.0)
		_:
			color_border = Color(0.35, 0.62, 1.0, 0.7)
			color_glow   = Color(0.2, 0.5, 1.0, 0.3)
			color_stars  = Color(0.5, 0.72, 1.0)

	var card := _build_reveal_card(char_name, rarity, color_border, color_glow, color_stars, 220, 310)
	card.pivot_offset = Vector2(110, 155)
	card.scale = Vector2(0.0, 1.0)
	card.modulate.a = 1.0
	_result_ov.add_child(card)

	# flip-in (scale X 0→1)
	var t := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(card, "scale:x", 1.0, 0.22)
	await t.finished

	if rarity == 4:
		_shake(card)

	await get_tree().create_timer(0.7).timeout
	var tf := card.create_tween()
	tf.tween_property(card, "modulate:a", 0.0, 0.25)
	await tf.finished
	card.queue_free()

# ── 5★ reveal ────────────────────────────────────────────────────
func _reveal_5star(char_name: String) -> void:
	# gold flash
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.88, 0.3, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 20
	_result_ov.add_child(flash)

	var tf := flash.create_tween()
	tf.tween_property(flash, "color:a", 0.75, 0.12)
	tf.tween_property(flash, "color:a", 0.0,  0.35)
	await tf.finished

	# big card
	var card := _build_reveal_card(char_name, 5,
		Color(1.0, 0.82, 0.2, 1.0),
		Color(1.0, 0.7, 0.1, 0.6),
		Color(1.0, 0.88, 0.25),
		280, 380)
	card.pivot_offset = Vector2(140, 190)
	card.scale = Vector2(0.0, 1.0)
	_result_ov.add_child(card)

	# gold glow ring behind card
	var glow := ColorRect.new()
	glow.color = Color(1.0, 0.78, 0.1, 0.0)
	glow.size = Vector2(340, 440)
	glow.position = Vector2(card.position.x - 30, card.position.y - 30)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = card.z_index - 1
	var sb_glow := StyleBoxFlat.new()
	sb_glow.bg_color = Color(0,0,0,0)
	_result_ov.add_child(glow)
	glow.move_to_front()
	card.move_to_front()
	flash.move_to_front()

	var tg := glow.create_tween().set_parallel(true)
	tg.tween_property(glow, "modulate:a", 0.45, 0.3)

	var tc := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tc.tween_property(card, "scale:x", 1.0, 0.28)
	await tc.finished

	# name label appears slowly
	var name_big := Label.new()
	name_big.text = char_name
	name_big.add_theme_font_size_override("font_size", 32)
	name_big.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 0.0))
	name_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_big.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	name_big.offset_top  = 110
	name_big.offset_left = -200
	name_big.offset_right = 200
	name_big.z_index = 25
	_result_ov.add_child(name_big)

	var tn := name_big.create_tween()
	tn.tween_property(name_big, "theme_override_colors/font_color",
		Color(1.0, 0.92, 0.4, 1.0), 0.6)
	await tn.finished

	await get_tree().create_timer(1.0).timeout

	# fade out card + glow + name
	var tf2 := create_tween().set_parallel(true)
	tf2.tween_property(card,     "modulate:a", 0.0, 0.3)
	tf2.tween_property(glow,     "modulate:a", 0.0, 0.3)
	tf2.tween_property(name_big, "modulate:a", 0.0, 0.3)
	await tf2.finished

	card.queue_free()
	glow.queue_free()
	name_big.queue_free()
	flash.queue_free()

# ── Build a centered reveal card ─────────────────────────────────
func _build_reveal_card(char_name: String, rarity: int,
		border: Color, glow: Color, star_color: Color,
		w: float, h: float) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(w, h)
	card.size = Vector2(w, h)
	# center on screen (1152×648)
	card.position = Vector2((1152 - w) * 0.5, (648 - h) * 0.5)
	card.z_index = 15

	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left    = 14
	sb.corner_radius_top_right   = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left  = 14
	sb.border_width_top    = 2
	sb.border_width_right  = 2
	sb.border_width_bottom = 2
	sb.border_width_left   = 2
	sb.border_color  = border
	sb.shadow_color  = glow
	sb.shadow_size   = 12
	match rarity:
		5: sb.bg_color = Color(0.12, 0.09, 0.02, 0.97)
		4: sb.bg_color = Color(0.09, 0.05, 0.16, 0.97)
		_: sb.bg_color = Color(0.05, 0.09, 0.18, 0.97)
	card.add_theme_stylebox_override("panel", sb)

	# stars
	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.add_theme_font_size_override("font_size", 16)
	stars.add_theme_color_override("font_color", star_color)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	stars.offset_top    = 12
	stars.offset_bottom = 34
	card.add_child(stars)

	# name
	var name_lbl := Label.new()
	name_lbl.text = char_name
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top    = -36
	name_lbl.offset_bottom = -10
	card.add_child(name_lbl)

	# rarity label
	var rlbl := Label.new()
	match rarity:
		5: rlbl.text = "5★  OPERATOR"
		4: rlbl.text = "4★  OPERATOR"
		_: rlbl.text = "3★  MATERIAL"
	rlbl.add_theme_font_size_override("font_size", 10)
	rlbl.add_theme_color_override("font_color", Color(border.r, border.g, border.b, 0.8))
	rlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rlbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	rlbl.offset_top    = -56
	rlbl.offset_bottom = -38
	card.add_child(rlbl)

	return card

# ── Summary card (shown after all reveals) ────────────────────────
func _make_summary_card(char_name: String, rarity: int) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(88, 120)
	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left    = 8
	sb.corner_radius_top_right   = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left  = 8
	sb.border_width_top    = 1
	sb.border_width_right  = 1
	sb.border_width_bottom = 1
	sb.border_width_left   = 1
	match rarity:
		5:
			sb.bg_color    = Color(0.15, 0.12, 0.04, 0.95)
			sb.border_color = Color(1.0, 0.82, 0.2, 0.9)
			sb.shadow_color = Color(1.0, 0.7, 0.1, 0.5)
			sb.shadow_size  = 8
		4:
			sb.bg_color    = Color(0.1, 0.06, 0.18, 0.95)
			sb.border_color = Color(0.65, 0.45, 1.0, 0.9)
			sb.shadow_color = Color(0.5, 0.2, 1.0, 0.4)
			sb.shadow_size  = 6
		_:
			sb.bg_color    = Color(0.06, 0.1, 0.2, 0.95)
			sb.border_color = Color(0.37, 0.62, 1.0, 0.4)
	card.add_theme_stylebox_override("panel", sb)

	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.add_theme_font_size_override("font_size", 9)
	match rarity:
		5: stars.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
		4: stars.add_theme_color_override("font_color", Color(0.75, 0.55, 1.0))
		_: stars.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	stars.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stars.offset_bottom = -6; stars.offset_left = 4
	stars.offset_right = 84; stars.offset_top = -18
	card.add_child(stars)

	var name_lbl := Label.new()
	name_lbl.text = char_name
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -22; name_lbl.offset_bottom = -4
	card.add_child(name_lbl)

	# fade-in
	card.modulate.a = 0.0
	var t := card.create_tween()
	t.tween_property(card, "modulate:a", 1.0, 0.3)

	return card

# ── Shake (4★) ───────────────────────────────────────────────────
func _shake(node: Control) -> void:
	var orig := node.position
	var t := node.create_tween()
	for _i in 5:
		t.tween_property(node, "position:x", orig.x + randf_range(-5, 5), 0.04)
	t.tween_property(node, "position:x", orig.x, 0.04)

# ── Navigation ────────────────────────────────────────────────────
func _go_back() -> void:
	if _revealing:
		return
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(SC_MAIN)
