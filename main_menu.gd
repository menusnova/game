extends Control

const SC_BATTLE     := "res://battle_scene.tscn"
const SC_STORY_MAP  := "res://story_map.tscn"
const SC_PROFILE    := "res://profile_scene.tscn"
const SC_GACHA      := "res://gacha_scene.tscn"
const SC_SHOP       := "res://shop_scene.tscn"
const SC_CODEX      := "res://codex_scene.tscn"
const SC_ROSTER     := "res://character_roster.tscn"
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
	"SimulationCard", "ExpeditionCard",
	"EventBanner", "NewCharCard"
]

func _ready() -> void:
	var _adv: Control = get_node_or_null("AdventureCard") as Control
	if _adv: _adv.gui_input.connect(_on_adv_input)
	var _arena: Control = get_node_or_null("ArenaCard") as Control
	if _arena and not _is_locked(_arena):
		_arena.gui_input.connect(_on_arena_input)
	var _prof: Control = get_node_or_null("ProfileCard") as Control
	if _prof: _prof.gui_input.connect(_on_profile_input)
	var _newchar: Control = get_node_or_null("NewCharCard") as Control
	if _newchar: _newchar.gui_input.connect(_on_gacha_input)
	_setup_locked_nodes()
	_setup_menu_items()
	_setup_cards_fx()
	_setup_domain()
	_setup_quest_panel()
	_setup_char_switcher()
	_setup_navbar()
	_setup_ambient_fx()

func _setup_navbar() -> void:
	var db_node: Control = get_node_or_null("NavBar/Nav4_Database") as Control
	if db_node and not _is_locked(db_node):
		db_node.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_goto(SC_CODEX)
		)
		_attach_hover_bounce(db_node)

	var roster_node: Control = get_node_or_null("NavBar/Nav0_Alchemist") as Control
	if roster_node:
		roster_node.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_goto(SC_ROSTER)
		)
		_attach_hover_bounce(roster_node)

	var char_node: Control = get_node_or_null("NavBar/Nav2_Arcanum") as Control
	if char_node and not _is_locked(char_node):
		char_node.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_show_coming_soon("ห้องทดลองผสมธาตุยังไม่เปิดให้บริการ")
		)
		_attach_hover_bounce(char_node)

func _setup_quest_panel() -> void:
	_quest_panel = preload("res://quest_panel.tscn").instantiate()
	add_child(_quest_panel)
	_setup_chat_coming_soon()

func _setup_chat_coming_soon() -> void:
	var mail: Control = get_node_or_null("BtnMail") as Control
	if mail:
		mail.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_show_coming_soon("ระบบแชทยังไม่เปิดให้บริการ")
		)
	var chat_bar: Control = get_node_or_null("ChatBar") as Control
	if chat_bar:
		chat_bar.mouse_filter = Control.MOUSE_FILTER_STOP
		chat_bar.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_show_coming_soon("ระบบแชทยังไม่เปิดให้บริการ")
		)

func _setup_domain() -> void:
	DomainManager.domain_changed.connect(_on_domain_changed)
	_on_domain_changed(DomainManager.get_percent())

func _on_domain_changed(percent: float) -> void:
	var label: Label = get_node_or_null("DomainInner/DomainPercent") as Label
	if label:
		label.text = "%d%%" % int(percent)
		var t := percent / 100.0
		label.add_theme_color_override("font_color",
			Color(0.4 + t * 0.6, 0.85 + t * 0.15, 1.0, 1.0))

# ── Locked-node helper ───────────────────────────────────────────
func _is_locked(node: Control) -> bool:
	return node.get_node_or_null("LockOverlay") != null

func _setup_locked_nodes() -> void:
	var all_names := MENU_ITEMS + CARDS + [
		"NavBar/Nav3_Inventory",
		"NavBar/Nav5_Guild",
	]
	for n in all_names:
		var node: Control = get_node_or_null(n) as Control
		if node and _is_locked(node):
			node.mouse_filter = Control.MOUSE_FILTER_STOP
			node.gui_input.connect(_on_locked_click.bind(node))

func _on_locked_click(ev: InputEvent, node: Control) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_scale(node)
		_show_coming_soon("ปลดล็อคเนื้อหานี้เพื่อเข้าถึง")

# ── Menu items (left sidebar) ────────────────────────────────────
func _setup_menu_items() -> void:
	for item_name in MENU_ITEMS:
		var item: Control = get_node_or_null(item_name) as Control
		if item == null or _is_locked(item):
			continue
		var orig_y: float = item.position.y
		item.mouse_entered.connect(_on_menu_hover.bind(item, orig_y, true))
		item.mouse_exited.connect(_on_menu_hover.bind(item, orig_y, false))
		item.gui_input.connect(_on_menu_click.bind(item))
	# Top-right icon buttons (NewCharCard excluded — handled in _setup_cards_fx)
	for btn_name in ["BtnPeople", "BtnMail", "BtnMega", "BtnSettings", "ProfileCard"]:
		var n: Control = get_node_or_null(btn_name) as Control
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
		var card: Control = get_node_or_null(card_name) as Control
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
	var flash: ColorRect = node.get_node_or_null("BloomFlash") as ColorRect
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
		_goto(SC_STORY_MAP)

func _on_arena_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_goto(SC_BATTLE)

func _on_toggle_char() -> void:
	_show_female = not _show_female
	var fc: Node = get_node_or_null("FemaleCharacter") as Node
	var mc: Node = get_node_or_null("MaleCharacter") as Node
	if fc: fc.visible = _show_female
	if mc: mc.visible = not _show_female

# ── Character Switcher (carousel) ────────────────────────────────
func _setup_char_switcher() -> void:
	var old_btn := get_node_or_null("ToggleBtn")
	if old_btn:
		old_btn.visible = false

	_char_switcher = Control.new()
	_char_switcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_switcher.position = Vector2(412, 604)
	_char_switcher.size = Vector2(88, 36)
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
	const SPACING := 40.0
	const H := 36.0
	for i in _char_circles.size():
		var btn: Panel = _char_circles[i] as Panel
		var active := (i == _char_index)
		var sz := Vector2(30, 30) if active else Vector2(22, 22)
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
		var sprite_name: String = str(CHAR_DATA[i].get("sprite", ""))
		var node: Node = get_node_or_null(sprite_name) as Node
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

func _show_coming_soon(msg: String = "ระบบนี้ยังไม่เปิดให้บริการ") -> void:
	# ถ้ามี toast อยู่แล้ว ไม่ซ้อน
	if get_node_or_null("_CSToast") != null:
		return
	var toast := Panel.new()
	toast.name = "_CSToast"
	toast.z_index = 100
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.22, 0.94)
	sb.border_color = Color(0.37, 0.62, 1.0, 0.5)
	sb.set_border_width(SIDE_LEFT,   2)
	sb.set_border_width(SIDE_TOP,    1)
	sb.set_border_width(SIDE_RIGHT,  1)
	sb.set_border_width(SIDE_BOTTOM, 1)
	sb.corner_radius_top_left     = 8
	sb.corner_radius_top_right    = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left  = 8
	toast.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 1.0))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 14; lbl.offset_right = -14
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(lbl)

	var tw: int = 320
	var th: int = 44
	toast.size     = Vector2(tw, th)
	toast.position = Vector2((1152 - tw) * 0.5, 540)
	toast.modulate = Color(1, 1, 1, 0.0)
	add_child(toast)

	var t := create_tween().set_parallel(true)
	t.tween_property(toast, "modulate:a",   1.0,               0.18)
	t.tween_property(toast, "position:y",   524.0,             0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await t.finished

	await get_tree().create_timer(1.6).timeout

	var t2 := create_tween()
	t2.tween_property(toast, "modulate:a", 0.0, 0.25)
	await t2.finished
	toast.queue_free()

func _spawn_city_glows() -> void:
	# จุดแสงสะท้อนเมือง — วางตามตำแหน่งแสงในภาพ
	const GLOWS := [
		# [x, y, w, h, color, duration]
		[320.0, 310.0, 90.0,  28.0, Color(0.30, 0.55, 1.00, 0.0), 2.8],
		[510.0, 340.0, 70.0,  20.0, Color(0.55, 0.30, 1.00, 0.0), 3.5],
		[680.0, 295.0, 60.0,  18.0, Color(0.25, 0.65, 1.00, 0.0), 4.1],
		[820.0, 325.0, 80.0,  22.0, Color(0.40, 0.25, 1.00, 0.0), 3.2],
		[200.0, 360.0, 50.0,  16.0, Color(0.20, 0.50, 1.00, 0.0), 5.0],
		[920.0, 350.0, 55.0,  17.0, Color(0.50, 0.20, 0.90, 0.0), 2.5],
	]
	for g in GLOWS:
		var spot := ColorRect.new()
		spot.position    = Vector2(g[0], g[1])
		spot.size        = Vector2(g[2], g[3])
		spot.color       = g[4]
		spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spot.z_index     = 0

		# blur feel — ทำ StyleBox radius ไม่ได้บน ColorRect, ใช้ซ้อน 3 ชั้นแทน
		var sb := StyleBoxFlat.new()
		sb.bg_color = g[4]
		sb.corner_radius_top_left     = 40
		sb.corner_radius_top_right    = 40
		sb.corner_radius_bottom_right = 40
		sb.corner_radius_bottom_left  = 40

		add_child(spot)

		var delay := randf_range(0.0, 3.0)
		var dur: float = g[5]
		var peak := randf_range(0.12, 0.22)

		var t := spot.create_tween().set_loops()
		t.tween_interval(delay)
		t.tween_property(spot, "color:a", peak, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(spot, "color:a", 0.0,  dur * 1.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

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

# ── Ambient Effects ───────────────────────────────────────────────
func _setup_ambient_fx() -> void:
	_spawn_particles()
	_start_bg_pulse()
	_spawn_city_glows()
	_start_bg_spot_fx()

func _spawn_particles() -> void:
	const SYMBOLS  := ["✦", "✧", "⋆", "·", "⬡", "◈"]
	const COUNT    := 22
	const COLORS   := [
		Color(0.45, 0.75, 1.0, 0.55),
		Color(0.65, 0.45, 1.0, 0.45),
		Color(1.0,  0.85, 0.35, 0.40),
		Color(0.35, 0.90, 0.80, 0.40),
	]
	for i in COUNT:
		var lbl := Label.new()
		lbl.text = SYMBOLS[i % SYMBOLS.size()]
		lbl.add_theme_font_size_override("font_size", int(randf_range(9.0, 20.0)))
		lbl.add_theme_color_override("font_color", COLORS[i % COLORS.size()])
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.z_index = -1
		var sx := randf_range(20.0, 1132.0)
		var sy := randf_range(20.0, 628.0)
		lbl.position = Vector2(sx, sy)
		add_child(lbl)
		_animate_particle(lbl)

func _animate_particle(lbl: Label) -> void:
	var dur   := randf_range(4.0, 9.0)
	var drift := Vector2(randf_range(-40.0, 40.0), randf_range(-80.0, -20.0))
	var dest  := lbl.position + drift
	var delay := randf_range(0.0, 4.0)

	var t := lbl.create_tween().set_loops()
	t.tween_interval(delay)
	t.tween_property(lbl, "modulate:a", 0.9, dur * 0.3).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(lbl, "position",   dest, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(lbl, "modulate:a", 0.0, dur * 0.3).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		lbl.position = Vector2(randf_range(20.0, 1132.0), randf_range(300.0, 628.0))
		lbl.modulate.a = 0.0
	)

func _start_bg_pulse() -> void:
	var glow := ColorRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.10, 0.18, 0.45, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = -1
	add_child(glow)

	var t := glow.create_tween().set_loops()
	t.tween_property(glow, "color:a", 0.10, 3.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(glow, "color:a", 0.0,  3.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _start_card_bob() -> void:
	const BOB_CARDS := ["AdventureCard", "NewCharCard", "EventBanner"]
	for card_name in BOB_CARDS:
		var card: Control = get_node_or_null(card_name) as Control
		if card == null:
			continue
		var orig_y := card.position.y
		var dur    := randf_range(2.8, 4.2)
		var amp    := randf_range(3.0, 6.0)
		var t := card.create_tween().set_loops()
		t.tween_property(card, "position:y", orig_y - amp, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(card, "position:y", orig_y + amp, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ── Background Spot FX — natural movement on key image areas ─────────
func _start_bg_spot_fx() -> void:
	_fx_moon_pulse()
	_fx_star_twinkle()
	_fx_river_shimmer()
	_fx_cloud_drift()
	_fx_tower_rings()

func _fx_moon_pulse() -> void:
	# Soft blue-white halo around moon (top-right)
	var moon := ColorRect.new()
	moon.position    = Vector2(830.0, 30.0)
	moon.size        = Vector2(150.0, 140.0)
	moon.color       = Color(0.72, 0.88, 1.0, 0.0)
	moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon.z_index     = 0
	add_child(moon)
	var t := moon.create_tween().set_loops()
	t.tween_property(moon, "color:a", 0.14, 4.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(moon, "color:a", 0.03, 4.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _fx_star_twinkle() -> void:
	# 18 small bright dots scattered in sky area (y < 220)
	const STAR_POSITIONS := [
		[60.0,18.0],[130.0,35.0],[205.0,12.0],[285.0,50.0],[370.0,22.0],
		[445.0,8.0],[520.0,40.0],[600.0,18.0],[665.0,55.0],[740.0,28.0],
		[100.0,75.0],[175.0,95.0],[260.0,80.0],[340.0,110.0],[480.0,68.0],
		[555.0,92.0],[640.0,70.0],[720.0,105.0],
	]
	for sp in STAR_POSITIONS:
		var s := ColorRect.new()
		s.position    = Vector2(sp[0], sp[1])
		s.size        = Vector2(randf_range(1.5, 3.0), randf_range(1.5, 3.0))
		s.color       = Color(0.90, 0.95, 1.0, 0.0)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.z_index     = 0
		add_child(s)
		var delay := randf_range(0.0, 5.0)
		var dur   := randf_range(1.2, 3.5)
		var peak  := randf_range(0.35, 0.80)
		var t := s.create_tween().set_loops()
		t.tween_interval(delay)
		t.tween_property(s, "color:a", peak, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(s, "color:a", 0.0, dur * 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _fx_river_shimmer() -> void:
	# Horizontal shimmering bands on river/water area (y≈395-465)
	const BANDS := [
		[230.0, 398.0, 320.0, 5.0, Color(0.55, 0.75, 1.0, 0.0), 2.2],
		[380.0, 415.0, 280.0, 4.0, Color(0.40, 0.65, 1.0, 0.0), 3.1],
		[150.0, 432.0, 360.0, 3.0, Color(0.65, 0.80, 1.0, 0.0), 2.7],
		[300.0, 450.0, 240.0, 4.0, Color(0.50, 0.70, 1.0, 0.0), 1.9],
		[480.0, 408.0, 200.0, 3.0, Color(0.45, 0.72, 1.0, 0.0), 3.4],
	]
	for b in BANDS:
		var bar := ColorRect.new()
		bar.position    = Vector2(b[0], b[1])
		bar.size        = Vector2(b[2], b[3])
		bar.color       = b[4]
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.z_index     = 0
		add_child(bar)
		var delay := randf_range(0.0, 2.5)
		var dur: float = b[5]
		var peak  := randf_range(0.10, 0.20)
		var drift := randf_range(12.0, 28.0) * (1.0 if randf() > 0.5 else -1.0)
		var orig_x: float = b[0]
		var t := bar.create_tween().set_loops()
		t.tween_interval(delay)
		t.tween_property(bar, "color:a",   peak,          dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(bar, "position:x", orig_x + drift, dur * 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(bar, "color:a",   0.0,           dur * 0.5).set_ease(Tween.EASE_IN)
		t.tween_callback(func(): bar.position.x = orig_x)

func _fx_cloud_drift() -> void:
	# Subtle wind sway — 3 thin wisps that drift only a few pixels back and forth
	const WISPS := [
		[80.0,  52.0, 220.0, 14.0],
		[420.0, 80.0, 180.0, 10.0],
		[700.0, 38.0, 260.0, 12.0],
	]
	for w in WISPS:
		var wisp := ColorRect.new()
		wisp.position    = Vector2(w[0], w[1])
		wisp.size        = Vector2(w[2], w[3])
		wisp.color       = Color(0.80, 0.88, 1.0, 0.04)
		wisp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wisp.z_index     = 0
		add_child(wisp)
		var orig_x: float = w[0]
		var sway  := randf_range(6.0, 14.0)
		var dur   := randf_range(6.0, 11.0)
		var delay := randf_range(0.0, 4.0)
		var t := wisp.create_tween().set_loops()
		t.tween_interval(delay)
		t.tween_property(wisp, "position:x", orig_x + sway, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(wisp, "position:x", orig_x - sway * 0.5, dur * 0.9).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(wisp, "position:x", orig_x, dur * 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _fx_tower_rings() -> void:
	# Glowing rings on floating tower structures (mid area y≈150-350)
	const RINGS := [
		[295.0, 198.0, 28.0, 10.0, Color(0.35, 0.70, 1.0, 0.0), 3.3],
		[295.0, 248.0, 28.0, 10.0, Color(0.35, 0.70, 1.0, 0.0), 4.1],
		[480.0, 172.0, 22.0,  8.0, Color(0.55, 0.40, 1.0, 0.0), 2.9],
		[480.0, 220.0, 22.0,  8.0, Color(0.55, 0.40, 1.0, 0.0), 3.7],
		[650.0, 210.0, 30.0, 10.0, Color(0.30, 0.65, 1.0, 0.0), 3.5],
	]
	for r in RINGS:
		var ring := ColorRect.new()
		ring.position    = Vector2(r[0], r[1])
		ring.size        = Vector2(r[2], r[3])
		ring.color       = r[4]
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.z_index     = 0
		add_child(ring)
		var delay := randf_range(0.0, 3.5)
		var dur: float = r[5]
		var peak := randf_range(0.18, 0.32)
		var t := ring.create_tween().set_loops()
		t.tween_interval(delay)
		t.tween_property(ring, "color:a", peak, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(ring, "color:a", 0.0,  dur * 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
