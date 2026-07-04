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

var _pity   := 0
var _pity_4 := 0

var _revealing   := false
var _skip_to_end := false

# New UI refs built in code (HSR style)
var _new_gem_lbl:   Label = null
var _new_pity_lbl:  Label = null
var _new_pity_bar:  ProgressBar = null
var _new_pull1:     Button = null
var _new_pull10:    Button = null

# Keep .tscn overlay nodes for reveal animation
@onready var _result_ov:  Control       = $ResultOverlay
@onready var _result_con: HBoxContainer = $ResultOverlay/ResultContainer
@onready var _skip_btn:   Button        = $ResultOverlay/SkipBtn

# These are still referenced for compat — hidden in _ready
@onready var _pull1:      Button      = $PullBtn1
@onready var _pull10:     Button      = $PullBtn10
@onready var _back:       Button      = $BackBtn
@onready var _pity_bar:   ProgressBar = $BannerCard/PityBar
@onready var _pity_lbl:   Label       = $BannerCard/PityLabel
@onready var _gem_lbl:    Label       = $InfoPanel/CurrencyRow/GemCount

func _ready() -> void:
	# Hide legacy .tscn layout nodes — we draw everything in code
	for n in ["Background","BgDim","BannerCard","InfoPanel","PullBtn1","PullBtn10","HistoryBtn","BackBtn"]:
		var node := get_node_or_null(n)
		if node:
			node.visible = false

	if _skip_btn:
		_skip_btn.pressed.connect(_on_skip)
	if _result_ov:
		_result_ov.visible = false

	_build_hsr_ui()
	_refresh_ui()

# ── HSR-style UI builder ──────────────────────────────────────────
func _build_hsr_ui() -> void:
	const W := 1152.0
	const H := 648.0

	# ── Deep space background ──
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.10, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	add_child(bg)

	# Star particles layer (static dots for depth)
	var stars_layer := Control.new()
	stars_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stars_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars_layer.z_index = -9
	add_child(stars_layer)
	_add_stars(stars_layer, W, H)

	# ── Character art area (left 68%) ──
	var art_w := W * 0.68
	var art_area := ColorRect.new()
	art_area.size = Vector2(art_w + 60, H)
	art_area.position = Vector2.ZERO
	art_area.color = Color(0.06, 0.10, 0.22, 0.35)
	art_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_area.z_index = 0
	add_child(art_area)

	# Diagonal accent stripe
	var stripe := ColorRect.new()
	stripe.size = Vector2(6, H)
	stripe.position = Vector2(art_w - 10, 0)
	stripe.color = Color(0.37, 0.65, 1.0, 0.18)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stripe.z_index = 1
	add_child(stripe)

	# Character art placeholder (large icon)
	var art_icon := Label.new()
	art_icon.text = "✦"
	art_icon.add_theme_font_size_override("font_size", 160)
	art_icon.add_theme_color_override("font_color", Color(0.37, 0.65, 1.0, 0.12))
	art_icon.size = Vector2(art_w, H)
	art_icon.position = Vector2.ZERO
	art_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_icon.z_index = 1
	add_child(art_icon)

	# Gentle pulse on art icon
	var tp := art_icon.create_tween().set_loops()
	tp.tween_property(art_icon, "modulate:a", 0.6, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tp.tween_property(art_icon, "modulate:a", 1.0, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Banner label (bottom-left of art area)
	var warp_type := Label.new()
	warp_type.text = "CHARACTER EVENT WARP"
	warp_type.add_theme_font_size_override("font_size", 11)
	warp_type.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0, 0.65))
	warp_type.size = Vector2(art_w - 32, 20)
	warp_type.position = Vector2(24, H - 110)
	warp_type.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warp_type.z_index = 2
	add_child(warp_type)

	var banner_name := Label.new()
	banner_name.text = "Lyra · นักเล่นแร่แรงสูง"
	banner_name.add_theme_font_size_override("font_size", 26)
	banner_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	banner_name.size = Vector2(art_w - 32, 36)
	banner_name.position = Vector2(24, H - 88)
	banner_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_name.z_index = 2
	add_child(banner_name)

	# Rate-up tag
	var tag_bg := _make_stylebox(Color(0.37, 0.62, 1.0, 0.25), Color(0.37, 0.62, 1.0, 0.5), 6, 1)
	var tag := Panel.new()
	tag.size = Vector2(110, 26)
	tag.position = Vector2(24, H - 48)
	tag.add_theme_stylebox_override("panel", tag_bg)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.z_index = 2
	add_child(tag)
	var tag_lbl := Label.new()
	tag_lbl.text = "5★  Rate Up"
	tag_lbl.add_theme_font_size_override("font_size", 11)
	tag_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0, 1.0))
	tag_lbl.size = Vector2(110, 26)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(tag_lbl)

	# ── Right info panel ──
	var panel_x := art_w + 8
	var panel_w := W - panel_x - 16
	var rp_sb := _make_stylebox(Color(0.04, 0.07, 0.18, 0.88), Color(0.37, 0.62, 1.0, 0.15), 16, 1)
	var right_panel := Panel.new()
	right_panel.size = Vector2(panel_w, H - 32)
	right_panel.position = Vector2(panel_x, 16)
	right_panel.add_theme_stylebox_override("panel", rp_sb)
	right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.z_index = 2
	add_child(right_panel)

	var py := 24.0  # cursor y inside right_panel

	# WARP header
	var hdr := Label.new()
	hdr.text = "WARP"
	hdr.add_theme_font_size_override("font_size", 28)
	hdr.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0, 1.0))
	hdr.size = Vector2(panel_w - 32, 38)
	hdr.position = Vector2(16, py)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_panel.add_child(hdr)
	py += 44

	# Separator line
	var sep := ColorRect.new()
	sep.size = Vector2(panel_w - 32, 1)
	sep.position = Vector2(16, py)
	sep.color = Color(0.37, 0.62, 1.0, 0.25)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_child(sep)
	py += 12

	# Rate 5★
	var rate5_lbl := Label.new()
	rate5_lbl.text = "5★ อัตราขั้นพื้นฐาน"
	rate5_lbl.add_theme_font_size_override("font_size", 11)
	rate5_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.45))
	rate5_lbl.size = Vector2(panel_w - 32, 18)
	rate5_lbl.position = Vector2(16, py)
	right_panel.add_child(rate5_lbl)
	py += 20

	var rate5_val := Label.new()
	rate5_val.text = "1.600%"
	rate5_val.add_theme_font_size_override("font_size", 22)
	rate5_val.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	rate5_val.size = Vector2(panel_w - 32, 30)
	rate5_val.position = Vector2(16, py)
	right_panel.add_child(rate5_val)
	py += 34

	# Rate 4★
	var rate4_val := Label.new()
	rate4_val.text = "5.100%  (4★)"
	rate4_val.add_theme_font_size_override("font_size", 14)
	rate4_val.add_theme_color_override("font_color", Color(0.72, 0.52, 1.0, 0.9))
	rate4_val.size = Vector2(panel_w - 32, 22)
	rate4_val.position = Vector2(16, py)
	right_panel.add_child(rate4_val)
	py += 28

	# Pity info
	var pity_info := Label.new()
	pity_info.text = "รับประกัน 90 ครั้ง  •  Soft pity 75"
	pity_info.add_theme_font_size_override("font_size", 10)
	pity_info.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.3))
	pity_info.size = Vector2(panel_w - 32, 16)
	pity_info.position = Vector2(16, py)
	right_panel.add_child(pity_info)
	py += 24

	# Separator
	var sep2 := ColorRect.new()
	sep2.size = Vector2(panel_w - 32, 1)
	sep2.position = Vector2(16, py)
	sep2.color = Color(0.37, 0.62, 1.0, 0.15)
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_child(sep2)
	py += 14

	# Pity counter
	var pity_cap := Label.new()
	pity_cap.text = "จำนวนครั้งที่วอร์ปแล้ว"
	pity_cap.add_theme_font_size_override("font_size", 10)
	pity_cap.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.4))
	pity_cap.size = Vector2(panel_w - 32, 16)
	pity_cap.position = Vector2(16, py)
	right_panel.add_child(pity_cap)
	py += 18

	_new_pity_lbl = Label.new()
	_new_pity_lbl.text = "0 / 90"
	_new_pity_lbl.add_theme_font_size_override("font_size", 20)
	_new_pity_lbl.add_theme_color_override("font_color", Color(0.85, 0.93, 1.0, 1.0))
	_new_pity_lbl.size = Vector2(panel_w - 32, 28)
	_new_pity_lbl.position = Vector2(16, py)
	right_panel.add_child(_new_pity_lbl)
	py += 32

	_new_pity_bar = ProgressBar.new()
	_new_pity_bar.max_value = PITY_HARD
	_new_pity_bar.value = 0
	_new_pity_bar.show_percentage = false
	_new_pity_bar.size = Vector2(panel_w - 32, 8)
	_new_pity_bar.position = Vector2(16, py)
	right_panel.add_child(_new_pity_bar)
	py += 20

	# Separator
	var sep3 := ColorRect.new()
	sep3.size = Vector2(panel_w - 32, 1)
	sep3.position = Vector2(16, py)
	sep3.color = Color(0.37, 0.62, 1.0, 0.15)
	sep3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_child(sep3)
	py += 14

	# Gem count
	var gem_row := HBoxContainer.new()
	gem_row.size = Vector2(panel_w - 32, 30)
	gem_row.position = Vector2(16, py)
	right_panel.add_child(gem_row)

	var gem_icon := Label.new()
	gem_icon.text = "💎"
	gem_icon.add_theme_font_size_override("font_size", 20)
	gem_row.add_child(gem_icon)

	_new_gem_lbl = Label.new()
	_new_gem_lbl.text = str(CurrencyManager.total_crystal())
	_new_gem_lbl.add_theme_font_size_override("font_size", 20)
	_new_gem_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	gem_row.add_child(_new_gem_lbl)
	py += 36

	# Pull buttons
	var btn_w := panel_w - 32
	var btn_h := 52.0

	_new_pull1 = _make_pull_btn("Warp ×1   160 💎", Color(0.13, 0.24, 0.58, 1.0), Color(0.18, 0.32, 0.68, 1.0))
	_new_pull1.size = Vector2(btn_w, btn_h)
	_new_pull1.position = Vector2(16, py)
	_new_pull1.pressed.connect(func(): _do_pull(1))
	right_panel.add_child(_new_pull1)
	py += btn_h + 10

	_new_pull10 = _make_pull_btn("Warp ×10   1,600 💎", Color(0.35, 0.60, 1.0, 1.0), Color(0.45, 0.70, 1.0, 1.0))
	_new_pull10.size = Vector2(btn_w, btn_h)
	_new_pull10.position = Vector2(16, py)
	_new_pull10.pressed.connect(func(): _do_pull(10))
	right_panel.add_child(_new_pull10)
	py += btn_h + 10

	# History button (small ghost)
	var hist_btn := _make_ghost_btn("ประวัติการวอร์ป")
	hist_btn.size = Vector2(btn_w, 36)
	hist_btn.position = Vector2(16, py)
	right_panel.add_child(hist_btn)

	# ── Back button (top-left) ──
	var back_btn := _make_ghost_btn("◀")
	back_btn.size = Vector2(52, 36)
	back_btn.position = Vector2(16, 16)
	back_btn.z_index = 10
	back_btn.pressed.connect(_go_back)
	add_child(back_btn)

	# ── Ensure result overlay is on top ──
	if _result_ov:
		_result_ov.z_index = 50
		move_child(_result_ov, get_child_count() - 1)

# ── Helper builders ───────────────────────────────────────────────
func _make_stylebox(bg: Color, border: Color, radius: int, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sb.set_border_width(s, bw)
	sb.corner_radius_top_left     = radius
	sb.corner_radius_top_right    = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left  = radius
	return sb

func _make_pull_btn(label_text: String, col_normal: Color, col_hover: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var sb  := _make_stylebox(col_normal, col_normal, 14, 0)
	var sbh := _make_stylebox(col_hover,  col_hover,  14, 0)
	var sbf := StyleBoxFlat.new()
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sbh)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus",   sbf)
	return btn

func _make_ghost_btn(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	var sb := _make_stylebox(Color(1,1,1,0.04), Color(1,1,1,0.10), 10, 1)
	var sbf := StyleBoxFlat.new()
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus",   sbf)
	return btn

func _add_stars(parent: Control, w: float, h: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for _i in 80:
		var dot := ColorRect.new()
		var sz := rng.randf_range(1.0, 2.5)
		dot.size = Vector2(sz, sz)
		dot.position = Vector2(rng.randf_range(0, w), rng.randf_range(0, h))
		var br := rng.randf_range(0.3, 0.9)
		dot.color = Color(br, br, br + 0.1, rng.randf_range(0.2, 0.7))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(dot)
		# slow twinkle
		var td := dot.create_tween().set_loops()
		var delay := rng.randf_range(0, 3.0)
		td.tween_interval(delay)
		td.tween_property(dot, "modulate:a", rng.randf_range(0.1, 0.4), rng.randf_range(1.0, 3.0)).set_ease(Tween.EASE_IN_OUT)
		td.tween_property(dot, "modulate:a", 1.0, rng.randf_range(1.0, 3.0)).set_ease(Tween.EASE_IN_OUT)

# ── Input / skip ─────────────────────────────────────────────────
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
	var gems: int = CurrencyManager.total_crystal()
	if _new_gem_lbl:
		_new_gem_lbl.text = str(gems)
	if _new_pity_bar:
		_new_pity_bar.value = _pity
	if _new_pity_lbl:
		_new_pity_lbl.text = "%d / %d" % [_pity, PITY_HARD]
	if _new_pull1:
		_new_pull1.disabled = gems < PULL_COST_1
	if _new_pull10:
		_new_pull10.disabled = gems < PULL_COST_10

# ── Pull ──────────────────────────────────────────────────────────
func _do_pull(count: int) -> void:
	if _revealing:
		return
	var cost: int = PULL_COST_10 if count == 10 else PULL_COST_1 * count
	if not CurrencyManager.spend_gems(cost):
		return
	var results:  Array[String] = []
	var rarities: Array[int]    = []
	for i in count:
		var r: Array = _roll()
		results.append(str(r[0]))
		rarities.append(int(r[1]))
	DomainManager.add_points("gacha")
	for i in results.size():
		if rarities[i] >= 4:
			CharacterManager.unlock(results[i])
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

# ── Sequential reveal ─────────────────────────────────────────────
func _run_reveal(names: Array[String], rarities: Array[int]) -> void:
	_revealing   = true
	_skip_to_end = false
	_skip_btn.text = "แตะเพื่อข้าม"

	for child in _result_con.get_children():
		child.queue_free()

	_result_ov.visible = true
	_result_con.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.z_index = 5
	_result_ov.add_child(dim)
	var td := dim.create_tween()
	td.tween_property(dim, "color:a", 0.88, 0.4)
	await td.finished

	for i in names.size():
		if _skip_to_end:
			break
		await _reveal_one(names[i], rarities[i], names.size(), i)
		if not _skip_to_end:
			var delay := 0.55 if rarities[i] == 5 else 0.28
			await get_tree().create_timer(delay).timeout

	dim.queue_free()
	_result_con.visible = true
	for i in names.size():
		_result_con.add_child(_make_summary_card(names[i], rarities[i]))

	_revealing   = false
	_skip_to_end = false
	_skip_btn.text = "CLOSE"

func _reveal_one(char_name: String, rarity: int, _total: int, _idx: int) -> void:
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

	var card := _build_reveal_card(char_name, 5,
		Color(1.0, 0.82, 0.2, 1.0),
		Color(1.0, 0.7, 0.1, 0.6),
		Color(1.0, 0.88, 0.25),
		280, 380)
	card.pivot_offset = Vector2(140, 190)
	card.scale = Vector2(0.0, 1.0)
	_result_ov.add_child(card)

	var glow := ColorRect.new()
	glow.color = Color(1.0, 0.78, 0.1, 0.0)
	glow.size = Vector2(340, 440)
	glow.position = Vector2(card.position.x - 30, card.position.y - 30)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = card.z_index - 1
	_result_ov.add_child(glow)
	glow.move_to_front()
	card.move_to_front()
	flash.move_to_front()

	var tg := glow.create_tween().set_parallel(true)
	tg.tween_property(glow, "modulate:a", 0.45, 0.3)

	var tc := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tc.tween_property(card, "scale:x", 1.0, 0.28)
	await tc.finished

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

	var stars := Label.new()
	stars.text = "★".repeat(rarity)
	stars.add_theme_font_size_override("font_size", 16)
	stars.add_theme_color_override("font_color", star_color)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	stars.offset_top    = 12
	stars.offset_bottom = 34
	card.add_child(stars)

	var name_lbl := Label.new()
	name_lbl.text = char_name
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top    = -36
	name_lbl.offset_bottom = -10
	card.add_child(name_lbl)

	var rlbl := Label.new()
	match rarity:
		5: rlbl.text = "5★  CHARACTER"
		4: rlbl.text = "4★  CHARACTER"
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
