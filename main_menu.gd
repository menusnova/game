extends Control

const SC_BATTLE     := "res://battle_scene.tscn"
const SC_STORY_MAP  := "res://story_map.tscn"
const SC_PROFILE    := "res://profile_scene.tscn"
const SC_GACHA      := "res://gacha_scene.tscn"
const SC_SHOP       := "res://shop_scene.tscn"
const SC_CODEX      := "res://codex_scene.tscn"
const SC_LAB        := "res://laboratory_scene.tscn"
const SC_ROSTER     := "res://character_roster.tscn"
var _quest_panel: CanvasLayer
var _navigating := false
var _banner_idx := 0


const MENU_ITEMS: Array[String] = [
	"MenuItem_Notice", "MenuItem_Missions", "MenuItem_Event",
	"MenuItem_Pass", "MenuItem_Shop"
]

const CARDS: Array[String] = [
	"AdventureCard", "ArenaCard",
	"SimulationCard", "ExpeditionCard",
	"EventBanner"
]

func _ready() -> void:
	_setup_ambient_fx()
	var _adv: Control = get_node_or_null("AdventureCard") as Control
	if _adv: _adv.gui_input.connect(_on_adv_input)
	var _arena: Control = get_node_or_null("ArenaCard") as Control
	if _arena and not _is_locked(_arena):
		_arena.gui_input.connect(_on_arena_input)
	var _prof: Control = get_node_or_null("ProfileCard") as Control
	if _prof: _prof.gui_input.connect(_on_profile_input)
	_load_icon_textures()
	_setup_locked_nodes()
	_setup_menu_items()
	_setup_cards_fx()
	_setup_quest_panel()
	_setup_navbar()
	_setup_banner_carousel()
	_refresh_hud()
	if not CurrencyManager.currency_changed.is_connected(_refresh_hud):
		CurrencyManager.currency_changed.connect(_refresh_hud)

func _load_icon_textures() -> void:
	var icons := [
		["CurrBox1/CurrIcon1",        "res://image/icon_gold.png"],
		["CurrBox2/CurrIcon2",        "res://image/crystal_gem.png"],
		["CurrBox3/CurrIcon3",        "res://image/icon_paid.png"],
		["CurrBox4/CurrIcon4",        "res://image/icon_energy.png"],
		["MenuItem_Notice/Icon",              "res://image/icon_notice.png"],
		["MenuItem_Missions/Icon",            "res://image/icon_missions.png"],
		["MenuItem_Event/Icon",               "res://image/icon_event.png"],
		["MenuItem_Pass/Icon",                "res://image/icon_pass.png"],
		["MenuItem_Shop/Icon",                "res://image/icon_shop.png"],
		["AdventureCard/AdventureArt",        "res://image/bstory.jpg"],
		["SimulationCard/SimulationArt",      "res://image/bsimu.jpg"],
		["ArenaCard/ArenaArt",                "res://image/barena.jpg"],
		["ExpeditionCard/ExpeditionArt",      "res://image/chl.jpg"],
		["NavBar/Nav0_Alchemist/Icon",        "res://image/icon_nav_character.png"],
		["NavBar/Nav2_Lab/Icon",              "res://image/icon_nav_lab.png"],
		["NavBar/Nav_Gacha/Icon",             "res://image/icon_nav_gacha.jpg"],
		["NavBar/Nav3_Inventory/Icon",        "res://image/icon_nav_inventory.png"],
		["NavBar/Nav4_Database/Icon",         "res://image/icon_nav_achievement.jpg"],
		["NavBar/Nav5_Guild/Icon",            "res://image/icon_nav_guild.jpg"],
	]
	for pair in icons:
		var node := get_node_or_null(pair[0]) as TextureRect
		if node:
			var buf := FileAccess.get_file_as_bytes(pair[1])
			if not buf.is_empty():
				var img := Image.new()
				var ok := false
				if pair[1].ends_with(".jpg") or pair[1].ends_with(".jpeg"):
					ok = img.load_jpg_from_buffer(buf) == OK
				else:
					ok = img.load_png_from_buffer(buf) == OK
				if ok:
					if pair[0].begins_with("NavBar/"):
						node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
						node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
						if pair[0].ends_with("Guild/Icon"):
							_remove_white_bg(img)
						else:
							_remove_bg(img)
					elif pair[0].ends_with("Art"):
						node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
						node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
						node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
						node.mouse_filter = Control.MOUSE_FILTER_IGNORE
						if node.get_parent() is Control:
							(node.get_parent() as Control).clip_contents = true
							node.get_parent().move_child(node, 0)
							# ซ่อน ArtBg ColorRect ที่อยู่ทับบนรูป
							var art_bg := node.get_parent().get_node_or_null("ArtBg")
							if art_bg:
								art_bg.visible = false
					node.texture = ImageTexture.create_from_image(img)

func _remove_white_bg(img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var whiteness := minf(c.r, minf(c.g, c.b))
			var alpha := clampf((1.0 - whiteness) / 0.45, 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, alpha))

func _remove_bg(img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var bright := (c.r + c.g + c.b) / 3.0
			# alpha ของ pixel ที่ "สว่างพอ" (icon) = ความเข้ม, พื้นหลังโปร่งใส
			var alpha := clampf((bright - 0.25) / 0.45, 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, alpha))

func _fmt_n(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)

func _refresh_hud() -> void:
	var pairs := [
		["CurrBox1/CurrVal1", _fmt_n(CurrencyManager.gold),         Color(0.65, 0.65, 0.70, 1.0)],
		["CurrBox2/CurrVal2", _fmt_n(CurrencyManager.free_crystal),  Color(0.65, 0.65, 0.70, 1.0)],
		["CurrBox3/CurrVal3", _fmt_n(CurrencyManager.paid_crystal),  Color(0.65, 0.65, 0.70, 1.0)],
		["CurrBox4/CurrVal4", "%d/%d" % [CurrencyManager.energy, CurrencyManager.MAX_ENERGY], Color(0.65, 0.65, 0.70, 1.0)],
	]
	for pair in pairs:
		var lbl := get_node_or_null(pair[0]) as Label
		if lbl:
			lbl.text = str(pair[1])
			lbl.add_theme_color_override("font_color", pair[2] as Color)

func _setup_ambient_fx() -> void:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = 1
	layer.name = "_AmbientLayer"
	add_child(layer)
	move_child(layer, 1)  # ทันทีหลัง Background

	# โซนที่โล่ง: (x_from, x_to, y_from, y_to)
	const ZONES: Array = [
		[270, 830, 55, 130],   # ท้องฟ้ากลาง (บน)
		[140, 260, 80, 380],   # ช่องซ้ายกลาง
		[270, 830, 530, 590],  # พื้นกลาง (ล่าง)
	]

	const ORBS := 28
	for i in ORBS:
		_spawn_orb(layer, ZONES[i % ZONES.size()])

	# กระพริบซ้ำทุก 2.4–4.8 วิ
	var t := create_tween().set_loops()
	t.tween_interval(randf_range(2.4, 4.8))
	t.tween_callback(func():
		if is_instance_valid(layer):
			_spawn_orb(layer, ZONES[randi() % ZONES.size()])
	)

func _spawn_orb(layer: Control, zone: Array) -> void:
	var sz  := randf_range(4.0, 9.0)
	var r   := int(sz * 0.5)
	var hue := randf_range(0.55, 0.75)
	var col := Color.from_hsv(hue, 0.5, 1.0, 0.0)

	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left     = r
	sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_right = r
	sb.corner_radius_bottom_left  = r
	sb.shadow_color = Color(col.r, col.g, col.b, 0.0)
	sb.shadow_size  = int(sz * 1.6)

	var orb := Panel.new()
	orb.size = Vector2(sz, sz)
	orb.position = Vector2(
		randf_range(zone[0], zone[1]),
		randf_range(zone[2], zone[3])
	)
	orb.add_theme_stylebox_override("panel", sb)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(orb)

	var rise  := randf_range(40.0, 90.0)
	var drift := randf_range(-18.0, 18.0)
	var dur   := randf_range(4.5, 9.0)
	var peak  := randf_range(0.55, 0.85)
	var dest_y := orb.position.y - rise
	var dest_x := orb.position.x + drift

	# เคลื่อนตลอด dur วิ
	var tw_move := orb.create_tween().set_parallel(true)
	tw_move.tween_property(orb, "position:y", dest_y, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw_move.tween_property(orb, "position:x", dest_x, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# fade in → hold → fade out ผ่าน modulate (ไม่ต้องแตะ StyleBox)
	var tw_alpha := orb.create_tween()
	tw_alpha.tween_property(orb, "modulate:a", peak, dur * 0.30)
	tw_alpha.tween_property(orb, "modulate:a", peak, dur * 0.35)
	tw_alpha.tween_property(orb, "modulate:a", 0.0,  dur * 0.35)
	tw_alpha.tween_callback(orb.queue_free)

func _setup_navbar() -> void:
	# Full-width backdrop behind NavBar to cover transparent gaps
	var nav_backdrop := ColorRect.new()
	nav_backdrop.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nav_backdrop.offset_top = -56.0
	nav_backdrop.color = Color(1.0, 1.0, 1.0, 0.08)
	nav_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var navbar := get_node_or_null("NavBar")
	if navbar:
		add_child(nav_backdrop)
		move_child(nav_backdrop, navbar.get_index())  # insert just before NavBar
	else:
		add_child(nav_backdrop)

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

	var gacha_node: Control = get_node_or_null("NavBar/Nav_Gacha") as Control
	if gacha_node:
		gacha_node.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_goto(SC_GACHA)
		)
		_attach_hover_bounce(gacha_node)

	var char_node: Control = get_node_or_null("NavBar/Nav2_Lab") as Control
	if char_node:
		char_node.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_goto(SC_LAB)
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


# ── Locked-node helper ───────────────────────────────────────────
func _is_locked(node: Control) -> bool:
	return node.get_node_or_null("LockOverlay") != null

const COMING_SOON_NODES: Array = ["ArenaCard"]

func _setup_locked_nodes() -> void:
	var all_names: Array[String] = []
	all_names.append_array(MENU_ITEMS)
	all_names.append_array(CARDS)
	all_names.append_array(["NavBar/Nav3_Inventory", "NavBar/Nav5_Guild"])
	for n in all_names:
		var node: Control = get_node_or_null(n) as Control
		if node and _is_locked(node):
			node.mouse_filter = Control.MOUSE_FILTER_STOP
			_set_descendants_ignore(node)
			var is_coming_soon: bool = n in COMING_SOON_NODES
			node.gui_input.connect(_on_locked_click.bind(node, is_coming_soon))

func _set_descendants_ignore(parent: Node) -> void:
	for child in parent.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_descendants_ignore(child)

func _on_locked_click(ev: InputEvent, node: Control, coming_soon: bool) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_scale(node)
		if coming_soon:
			_show_coming_soon("อารีน่า — กำลังจะมาเร็วๆนี้")
		else:
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
	for btn_name in ["BtnPeople", "BtnMail", "BtnMega", "BtnSettings"]:
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
		elif item.name == "MenuItem_Event":
			_show_coming_soon("กิจกรรม — กำลังจะมาเร็วๆนี้")
		elif item.name == "MenuItem_Notice":
			_show_coming_soon("ประกาศ — กำลังจะมาเร็วๆนี้")
		elif item.name == "MenuItem_Pass":
			_show_coming_soon("Battle Pass — กำลังจะมาเร็วๆนี้")

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
		_goto(SC_PROFILE)


func _on_adv_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_goto(SC_STORY_MAP)

func _on_arena_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if CurrencyManager.energy < 10:
			_show_coming_soon("พลังงานไม่เพียงพอ (ต้องการ ⚡10)")
			return
		_goto(SC_BATTLE)

func _setup_banner_carousel() -> void:
	# ซ่อน NewCharCard เดิม
	var old: Control = get_node_or_null("NewCharCard") as Control
	if old: old.visible = false

	# พื้นที่แสดง: x=924 y=52 w=221 h=76
	const BX    := 924.0
	const BY    := 52.0
	const BW    := 221.0
	const BH    := 76.0

	const BANNERS := [
		{
			"tag":   "CHARACTER",
			"tag_color": Color(0.90, 0.35, 1.0),
			"title": "ALCHEMIST",
			"sub":   "5★  Element Burst",
			"accent": Color(0.35, 0.75, 1.0),
			"icon":  "⚗",
		},
		{
			"tag":   "LIGHT CONE",
			"tag_color": Color(1.0, 0.72, 0.15),
			"title": "ARCANE FORMULA",
			"sub":   "4★  Erudition Path",
			"accent": Color(1.0, 0.80, 0.25),
			"icon":  "📖",
		},
	]

	# Clip container — hides overflow when sliding
	var clip := Control.new()
	clip.position = Vector2(BX, BY)
	clip.size     = Vector2(BW, BH)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.z_index  = 5
	add_child(clip)

	# Track container — slides horizontally
	var track := Control.new()
	track.position = Vector2(0, 0)
	track.size     = Vector2(BW * BANNERS.size(), BH)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(track)

	var banner_nodes: Array[Control] = []

	for i in BANNERS.size():
		var d: Dictionary = BANNERS[i]
		var acc: Color = d["accent"]

		var card := Panel.new()
		card.position = Vector2(-i * BW, 0)
		card.size     = Vector2(BW, BH)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.05, 0.14, 0.97)
		sb.border_color = Color(acc.r, acc.g, acc.b, 0.4)
		sb.border_width_left = 1; sb.border_width_right = 1
		sb.border_width_top = 1; sb.border_width_bottom = 1
		sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_right = 8; sb.corner_radius_bottom_left = 8
		card.add_theme_stylebox_override("panel", sb)
		track.add_child(card)
		banner_nodes.append(card)

		# Accent left bar
		var bar := ColorRect.new()
		bar.size = Vector2(3, BH)
		bar.color = Color(acc.r, acc.g, acc.b, 0.85)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(bar)

		# Tag pill
		var tag_bg := Panel.new()
		tag_bg.position = Vector2(10, 7)
		tag_bg.size = Vector2(80, 13)
		tag_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tsb := StyleBoxFlat.new()
		tsb.bg_color = Color((d["tag_color"] as Color).r * 0.25, (d["tag_color"] as Color).g * 0.25, (d["tag_color"] as Color).b * 0.35, 0.95)
		tsb.border_color = d["tag_color"]
		tsb.border_width_left = 1; tsb.border_width_right = 1
		tsb.border_width_top = 1; tsb.border_width_bottom = 1
		tsb.corner_radius_top_left = 3; tsb.corner_radius_top_right = 3
		tsb.corner_radius_bottom_right = 3; tsb.corner_radius_bottom_left = 3
		tag_bg.add_theme_stylebox_override("panel", tsb)
		card.add_child(tag_bg)
		var tag_lbl := Label.new()
		tag_lbl.text = str(d["tag"])
		tag_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		tag_lbl.add_theme_font_size_override("font_size", 7)
		tag_lbl.add_theme_color_override("font_color", d["tag_color"])
		tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag_bg.add_child(tag_lbl)

		# Title
		var title_lbl := Label.new()
		title_lbl.text = str(d["title"])
		title_lbl.position = Vector2(10, 24)
		title_lbl.size = Vector2(140, 26)
		title_lbl.add_theme_font_size_override("font_size", 18)
		title_lbl.add_theme_color_override("font_color", Color(acc.r + 0.1, acc.g + 0.05, acc.b, 1.0))
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(title_lbl)

		# Sub
		var sub_lbl := Label.new()
		sub_lbl.text = str(d["sub"])
		sub_lbl.position = Vector2(10, 52)
		sub_lbl.size = Vector2(150, 14)
		sub_lbl.add_theme_font_size_override("font_size", 9)
		sub_lbl.add_theme_color_override("font_color", Color(0.65, 0.80, 1.0, 0.75))
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(sub_lbl)

		# Icon (right side)
		var icon_lbl := Label.new()
		icon_lbl.text = str(d["icon"])
		icon_lbl.position = Vector2(BW - 56, 8)
		icon_lbl.size = Vector2(48, BH - 16)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 28)
		icon_lbl.add_theme_color_override("font_color", Color(acc.r, acc.g, acc.b, 0.55))
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(icon_lbl)

		card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Dot indicators
	var dot_row := Control.new()
	dot_row.position = Vector2(BX + 8, BY + BH - 10)
	dot_row.size     = Vector2(40, 6)
	dot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dot_row)
	var dot_nodes: Array[ColorRect] = []
	for i in BANNERS.size():
		var dot := ColorRect.new()
		dot.size = Vector2(7, 4)
		dot.position = Vector2(i * 10, 0)
		dot.color = Color(1, 1, 1, 0.9) if i == 0 else Color(1, 1, 1, 0.22)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot_row.add_child(dot)
		dot_nodes.append(dot)

	# Auto-scroll loop every 3s → slide right → wrap
	var loop_tween := create_tween().set_loops()
	loop_tween.tween_interval(3.0)
	loop_tween.tween_callback(func():
		if not is_instance_valid(track): return
		_banner_idx = (_banner_idx + 1) % BANNERS.size()
		var target_x := _banner_idx * BW
		var slide := track.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		slide.tween_property(track, "position:x", target_x, 0.45)
		for j in dot_nodes.size():
			dot_nodes[j].color = Color(1,1,1, 0.9 if j == _banner_idx else 0.22)
	)

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
	if not is_instance_valid(toast): return

	await get_tree().create_timer(1.6).timeout
	if not is_instance_valid(toast): return

	var t2 := create_tween()
	t2.tween_property(toast, "modulate:a", 0.0, 0.25)
	await t2.finished
	if is_instance_valid(toast): toast.queue_free()

func _goto(path: String) -> void:
	if _navigating or not ResourceLoader.exists(path): return
	if SceneTransition.is_busy(): return
	_navigating = true
	SceneTransition.fade_to(path)

