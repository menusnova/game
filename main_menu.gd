extends Control

const SC_BATTLE     := "res://battle_scene.tscn"
const SC_TRANSITION := "res://transition_scene.tscn"
const SC_PROFILE    := "res://profile_scene.tscn"
const SC_GACHA      := "res://gacha_scene.tscn"
const SC_SHOP       := "res://shop_scene.tscn"
const SC_CODEX      := "res://codex_scene.tscn"
const SC_CHARACTER  := "res://character_scene.tscn"
var _show_female := true
var _quest_panel: CanvasLayer
var _navigating := false

var _char_index := 0
var _char_circles: Array = []
var _char_switcher: Control
var _char_switching := false

const CHAR_DATA := [
	{"color": Color(1.0, 0.55, 0.82), "sprite": "FemaleCharacter"},
	{"color": Color(0.35, 0.72, 1.0),  "sprite": "MaleCharacter"},
]

const MENU_ITEMS := [
	"MenuItem_Notice", "MenuItem_Missions", "MenuItem_Event",
	"MenuItem_Pass", "MenuItem_Shop"
]

const CARDS := [
	"AdventureCard", "ArenaCard",
	"ChronicleCard", "SimulationCard", "ExpeditionCard",
	"EventBanner", "NewCharCard"
]

func _ready() -> void:
	var _adv = get_node_or_null("AdventureCard")
	if _adv: _adv.gui_input.connect(_on_adv_input)
	var _arena = get_node_or_null("ArenaCard")
	if _arena and not _is_locked(_arena):
		_arena.gui_input.connect(_on_arena_input)
	var _prof = get_node_or_null("ProfileCard")
	if _prof: _prof.gui_input.connect(_on_profile_input)
	var _newchar = get_node_or_null("NewCharCard")
	if _newchar: _newchar.gui_input.connect(_on_gacha_input)
	_setup_locked_nodes()
	_setup_menu_items()
	_setup_cards_fx()
	_setup_domain()
	_setup_quest_panel()
	_setup_char_switcher()
	_setup_navbar()

func _setup_navbar() -> void:
	var db_node: Control = get_node_or_null("NavBar/Nav4_Database")
	if db_node and not _is_locked(db_node):
		db_node.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_goto(SC_CODEX)
		)
		_attach_hover_bounce(db_node)

	var char_node: Control = get_node_or_null("NavBar/Nav2_Character")
	if char_node and not _is_locked(char_node):
		char_node.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_goto(SC_CHARACTER)
		)
		_attach_hover_bounce(char_node)

func _setup_quest_panel() -> void:
	_quest_panel = preload("res://quest_panel.tscn").instantiate()
	add_child(_quest_panel)

func _setup_domain() -> void:
	DomainManager.domain_changed.connect(_on_domain_changed)
	_on_domain_changed(DomainManager.get_percent())

func _on_domain_changed(percent: float) -> void:
	var label: Label = get_node_or_null("DomainInner/DomainPercent")
	if label:
		label.text = "%d%%" % int(percent)
		var t := percent / 100.0
		label.add_theme_color_override("font_color",
			Color(0.4 + t * 0.6, 0.85 + t * 0.15, 1.0, 1.0))

# ── Locked-node helper ───────────────────────────────────────────
func _is_locked(node: Control) -> bool:
	return node.get_node_or_null("LockOverlay") != null

func _setup_locked_nodes() -> void:
	# Disable all nodes that have a LockOverlay child
	var all_names := MENU_ITEMS + CARDS + [
		"NavBar/Nav3_Inventory",
		"NavBar/Nav5_Guild",
	]
	for n in all_names:
		var node: Control = get_node_or_null(n)
		if node and _is_locked(node):
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ── Menu items (left sidebar) ────────────────────────────────────
func _setup_menu_items() -> void:
	for item_name in MENU_ITEMS:
		var item: Control = get_node_or_null(item_name)
		if item == null or _is_locked(item):
			continue
		var orig_y: float = item.position.y
		item.mouse_entered.connect(_on_menu_hover.bind(item, orig_y, true))
		item.mouse_exited.connect(_on_menu_hover.bind(item, orig_y, false))
		item.gui_input.connect(_on_menu_click.bind(item))
	# Top-right icon buttons
	for btn_name in ["BtnPeople", "BtnMail", "BtnMega", "BtnSettings",
					  "ProfileCard", "NewCharCard"]:
		var n: Control = get_node_or_null(btn_name)
		if n:
			_attach_hover_bounce(n)

func _on_menu_hover(item: Control, orig_y: float, hovered: bool) -> void:
	var t := item.create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var target_y := orig_y - 4.0 if hovered else orig_y
	t.tween_property(item, "position:y", target_y, 0.12)

func _on_menu_click(ev: InputEvent, item: Control) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_flash(item)
		_fx_scale(item)
		_fx_ripple(item, ev.position)
		if item.name == "MenuItem_Missions":
			_quest_panel.open()
		elif item.name == "MenuItem_Shop":
			_goto(SC_SHOP)

# ── Cards (ripple + scale on tap) ────────────────────────────────
func _setup_cards_fx() -> void:
	for card_name in CARDS:
		var card: Control = get_node_or_null(card_name)
		if card == null or _is_locked(card):
			continue
		_attach_hover_bounce(card)
		card.gui_input.connect(_on_card_fx.bind(card))

func _on_card_fx(ev: InputEvent, card: Control) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_scale(card)
		_fx_ripple(card, ev.position)

# ── Effects ───────────────────────────────────────────────────────
func _attach_hover_bounce(node: Control) -> void:
	node.mouse_entered.connect(func():
		var t := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(node, "scale", Vector2(1.06, 1.06), 0.12)
	)
	node.mouse_exited.connect(func():
		var t := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(node, "scale", Vector2(1.0, 1.0), 0.14)
	)

func _fx_flash(node: Control) -> void:
	var flash: ColorRect = node.get_node_or_null("BloomFlash")
	if flash:
		flash.color = Color(1, 1, 1, 0.45)
		var t := flash.create_tween()
		t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		t.tween_property(flash, "color:a", 0.0, 0.35)

func _fx_scale(node: Control) -> void:
	var t := node.create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(node, "scale", Vector2(0.93, 0.93), 0.08)
	t.tween_property(node, "scale", Vector2(1.0,  1.0),  0.18)

func _fx_ripple(node: Control, local_pos: Vector2) -> void:
	const SPARK_COLORS := [
		Color(0.55, 0.75, 1.0, 1.0),
		Color(0.75, 0.45, 1.0, 1.0),
		Color(1.0,  1.0,  1.0, 1.0),
		Color(0.4,  0.6,  1.0, 1.0),
		Color(0.9,  0.6,  1.0, 1.0),
	]
	const SPARK_SYMBOLS := ["✦", "✧", "⋆", "·", "✦"]
	const COUNT := 10

	for i in COUNT:
		var lbl := Label.new()
		lbl.text = SPARK_SYMBOLS[i % SPARK_SYMBOLS.size()]
		lbl.add_theme_font_size_override("font_size", int(randf_range(9.0, 16.0)))
		lbl.add_theme_color_override("font_color", SPARK_COLORS[i % SPARK_COLORS.size()])
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.position = local_pos + Vector2(-6, -6)
		lbl.z_index = 10
		node.add_child(lbl)

		var angle := (TAU / COUNT) * i + randf_range(-0.4, 0.4)
		var dest  := local_pos + Vector2(cos(angle), sin(angle)) * randf_range(28.0, 62.0)

		var t := lbl.create_tween().set_parallel(true)
		t.tween_property(lbl, "position",   dest,             0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(lbl, "modulate:a", 0.0,              0.42).set_ease(Tween.EASE_IN)
		t.tween_property(lbl, "scale",      Vector2(0.3, 0.3), 0.42).set_ease(Tween.EASE_IN)
		t.finished.connect(lbl.queue_free)

# ── Global click sparkle ─────────────────────────────────────────
func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_ripple(self, get_local_mouse_position())

# ── Navigation ────────────────────────────────────────────────────
func _on_profile_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_scale($ProfileCard)
		_fx_ripple($ProfileCard, ev.position)
		_goto(SC_PROFILE)

func _on_gacha_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_goto(SC_GACHA)

func _on_adv_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_start_adventure()

func _start_adventure() -> void:
	_goto(SC_TRANSITION)

func _on_arena_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_goto(SC_BATTLE)

func _on_toggle_char() -> void:
	_show_female = not _show_female
	var fc = get_node_or_null("FemaleCharacter")
	var mc = get_node_or_null("MaleCharacter")
	if fc: fc.visible = _show_female
	if mc: mc.visible = not _show_female

# ── Character Switcher (carousel) ────────────────────────────────
func _setup_char_switcher() -> void:
	var old_btn := get_node_or_null("ToggleBtn")
	if old_btn:
		old_btn.visible = false

	_char_switcher = Control.new()
	_char_switcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_switcher.position = Vector2(472, 558)
	_char_switcher.size = Vector2(160, 68)
	add_child(_char_switcher)

	_build_char_circles()
	_refresh_char_circles(false)
	_update_char_sprites()

func _build_char_circles() -> void:
	for c in _char_switcher.get_children():
		c.queue_free()
	_char_circles.clear()

	for i in CHAR_DATA.size():
		var btn := Panel.new()
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		_char_switcher.add_child(btn)
		_char_circles.append(btn)

		# placeholder label (replace with chibi TextureRect later)
		var lbl := Label.new()
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.text = ""
		btn.add_child(lbl)

		btn.gui_input.connect(_on_char_circle_input.bind(i))

func _refresh_char_circles(animate: bool = true) -> void:
	const SPACING := 70.0
	const H := 68.0
	for i in _char_circles.size():
		var btn: Panel = _char_circles[i]
		var active := (i == _char_index)
		var sz := Vector2(58, 58) if active else Vector2(42, 42)
		var col: Color = CHAR_DATA[i]["color"]

		var sb := StyleBoxFlat.new()
		sb.corner_radius_top_left     = 50
		sb.corner_radius_top_right    = 50
		sb.corner_radius_bottom_right = 50
		sb.corner_radius_bottom_left  = 50
		sb.bg_color = col if active else Color(col.r, col.g, col.b, 0.30)
		if active:
			sb.border_width_left   = 3
			sb.border_width_right  = 3
			sb.border_width_top    = 3
			sb.border_width_bottom = 3
			sb.border_color = Color(1, 1, 1, 0.9)
		btn.add_theme_stylebox_override("panel", sb)

		var target_pos := Vector2(i * SPACING + (SPACING - sz.x) / 2.0, (H - sz.y) / 2.0)

		if animate:
			var t := btn.create_tween().set_parallel(true)
			t.tween_property(btn, "size",     sz,         0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			t.tween_property(btn, "position", target_pos, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		else:
			btn.size     = sz
			btn.position = target_pos

func _update_char_sprites() -> void:
	for i in CHAR_DATA.size():
		var node = get_node_or_null(CHAR_DATA[i]["sprite"])
		if node:
			node.visible = (i == _char_index)

func _on_char_circle_input(ev: InputEvent, idx: int) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if _char_switching:
			return
		_char_switching = true
		_char_index = (idx + 1) % CHAR_DATA.size() if idx == _char_index else idx

		# slide right animation on switcher container
		var orig_x := _char_switcher.position.x
		var t := _char_switcher.create_tween()
		t.tween_property(_char_switcher, "position:x", orig_x + 22, 0.10).set_ease(Tween.EASE_OUT)
		t.tween_property(_char_switcher, "position:x", orig_x, 0.18).set_ease(Tween.EASE_IN_OUT)
		await t.finished

		_refresh_char_circles(true)
		_update_char_sprites()
		_char_switching = false

func _goto(path: String) -> void:
	if _navigating or not ResourceLoader.exists(path): return
	_navigating = true
	if DomainManager.domain_changed.is_connected(_on_domain_changed):
		DomainManager.domain_changed.disconnect(_on_domain_changed)
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.28)
	await t.finished
	get_tree().change_scene_to_file(path)
