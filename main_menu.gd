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
	_setup_profile_avatar()
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
	_setup_tutorial_button()
	_refresh_hud()
	if not CurrencyManager.currency_changed.is_connected(_refresh_hud):
		CurrencyManager.currency_changed.connect(_refresh_hud)
	if not NewPlayerGuide.has_seen():
		_open_new_player_guide.call_deferred()

## Crops just the head/face out of Lyra's full-body art for the small profile-card avatar.
func _setup_profile_avatar() -> void:
	var avatar := get_node_or_null("ProfileCard/Avatar") as TextureRect
	if not avatar: return
	var full_tex: Texture2D = AssetLoader.tex("res://image/lyra_guard.png")
	if not full_tex: return
	var full_img: Image = full_tex.get_image()
	if full_img == null: return
	full_img = full_img.duplicate()
	# Already-imported textures are usually VRAM-compressed by default —
	# get_pixel()/get_region() silently misbehave on a compressed Image.
	# Decompress before touching any pixels; if that fails, fall back to a
	# plain (un-keyed) atlas crop rather than risk a corrupted result.
	if full_img.is_compressed() and full_img.decompress() != OK:
		var atlas := AtlasTexture.new()
		atlas.atlas  = full_tex
		atlas.region = Rect2(136, 12, 240, 240)
		avatar.texture = atlas
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if ResourceLoader.exists("res://shaders/circle_mask.gdshader"):
			var fail_mat := ShaderMaterial.new()
			fail_mat.shader = load("res://shaders/circle_mask.gdshader")
			avatar.material = fail_mat
		return
	full_img.convert(Image.FORMAT_RGBA8)
	# lyra_guard.png is 512x1024 (full body); head sits near the top, roughly centered.
	var region_img: Image = full_img.get_region(Rect2i(136, 12, 240, 240))
	# The crop still has the art's flat background around Lyra's head/hair —
	# key it out so the circle mask below shows Lyra, not a white disc with a
	# face floating in it.
	region_img = _key_out_background(region_img)
	avatar.texture = ImageTexture.create_from_image(region_img)
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Clip the square avatar art into a circle so it fits the round AvatarRing
	if ResourceLoader.exists("res://shaders/circle_mask.gdshader"):
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/circle_mask.gdshader")
		avatar.material = mat

## Border flood-fill background removal: samples the image's own corner pixel
## as the background color, then only keys out pixels connected to the edge
## and similar to it — enclosed same-color regions inside the subject (e.g.
## light hair strands) are left untouched. Also feathers anti-aliased edge
## pixels left behind by the hard flood-fill so no white fringe remains.
func _key_out_background(src_img: Image) -> Image:
	var img := src_img.duplicate() as Image
	var w := img.get_width()
	var h := img.get_height()
	var bg_col := img.get_pixel(0, 0)
	var TOLERANCE := 0.08
	var visited := PackedByteArray()
	visited.resize(w * h)
	var queue: Array[Vector2i] = []

	var is_bg := func(x: int, y: int) -> bool:
		var c := img.get_pixel(x, y)
		return absf(c.r - bg_col.r) <= TOLERANCE and absf(c.g - bg_col.g) <= TOLERANCE and absf(c.b - bg_col.b) <= TOLERANCE

	for x in w:
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y in h:
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))

	var qi := 0
	var cleared := 0
	while qi < queue.size():
		var p: Vector2i = queue[qi]
		qi += 1
		if p.x < 0 or p.x >= w or p.y < 0 or p.y >= h: continue
		var idx := p.y * w + p.x
		if visited[idx] == 1: continue
		visited[idx] = 1
		if not is_bg.call(p.x, p.y): continue
		var c := img.get_pixel(p.x, p.y)
		img.set_pixel(p.x, p.y, Color(c.r, c.g, c.b, 0.0))
		cleared += 1
		queue.append(Vector2i(p.x + 1, p.y))
		queue.append(Vector2i(p.x - 1, p.y))
		queue.append(Vector2i(p.x, p.y + 1))
		queue.append(Vector2i(p.x, p.y - 1))

	if float(cleared) / float(w * h) > 0.70:
		return src_img   # likely a leak through a flat/dark subject — keep the original art

	# If the background isn't a simple flat/gradient color (e.g. real
	# scenery bleeding into the crop corner), color-based keying can only
	# clear a small sliver and leaves a hard, torn-looking edge around
	# whatever solid background remains. Fade the crop's own outer edges to
	# transparent instead of attempting a partial, broken key.
	if float(cleared) / float(w * h) < 0.20:
		var faded := src_img.duplicate() as Image
		const EDGE_X := 0.16
		const EDGE_Y := 0.16
		for fy0 in h:
			var fy: float = minf(float(fy0) / (h * EDGE_Y), minf(float(h - 1 - fy0) / (h * EDGE_Y), 1.0))
			for fx0 in w:
				var fx: float = minf(float(fx0) / (w * EDGE_X), minf(float(w - 1 - fx0) / (w * EDGE_X), 1.0))
				var fc := faded.get_pixel(fx0, fy0)
				faded.set_pixel(fx0, fy0, Color(fc.r, fc.g, fc.b, fc.a * fx * fy))
		return faded

	# Some art has background-colored gaps fully enclosed by the silhouette
	# (e.g. the negative space between an arm and the body) — not connected
	# to the image border, so the flood-fill above correctly leaves them
	# alone (that's what keeps small enclosed details like light hair
	# intact). But a big enclosed patch is almost always a real gap, not a
	# detail worth keeping, and left solid it reads as a torn/broken image.
	# Clear any such patch above a minimum size. Real limb/body gaps run
	# ~8,000-11,000px; a bright enclosed hair highlight can be ~2,000px and
	# must NOT be caught here (that punched a visible hole through the
	# hair) — 5,000 sits safely between the two.
	var HOLE_MIN_SIZE := 5000
	var hole_visited := PackedByteArray()
	hole_visited.resize(w * h)
	for y0 in h:
		for x0 in w:
			var idx0 := y0 * w + x0
			if hole_visited[idx0] == 1: continue
			if img.get_pixel(x0, y0).a <= 0.01:
				hole_visited[idx0] = 1
				continue
			if not is_bg.call(x0, y0):
				hole_visited[idx0] = 1
				continue
			var comp: Array[Vector2i] = [Vector2i(x0, y0)]
			hole_visited[idx0] = 1
			var head := 0
			while head < comp.size():
				var cp: Vector2i = comp[head]
				head += 1
				for nb in [Vector2i(cp.x + 1, cp.y), Vector2i(cp.x - 1, cp.y), Vector2i(cp.x, cp.y + 1), Vector2i(cp.x, cp.y - 1)]:
					if nb.x < 0 or nb.x >= w or nb.y < 0 or nb.y >= h: continue
					var nidx: int = nb.y * w + nb.x
					if hole_visited[nidx] == 1: continue
					hole_visited[nidx] = 1
					if img.get_pixel(nb.x, nb.y).a <= 0.01: continue
					if not is_bg.call(nb.x, nb.y): continue
					comp.append(nb)
			if comp.size() >= HOLE_MIN_SIZE:
				for cp2 in comp:
					var c2 := img.get_pixel(cp2.x, cp2.y)
					img.set_pixel(cp2.x, cp2.y, Color(c2.r, c2.g, c2.b, 0.0))

	var EDGE_TOLERANCE := 0.55
	var feathered := img.duplicate() as Image
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a <= 0.01: continue
			var touches_cleared := false
			for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or nx >= w or ny < 0 or ny >= h: continue
				if img.get_pixel(nx, ny).a <= 0.01:
					touches_cleared = true
					break
			if not touches_cleared: continue
			var c := img.get_pixel(x, y)
			var dist := (absf(c.r - bg_col.r) + absf(c.g - bg_col.g) + absf(c.b - bg_col.b)) / 3.0
			if dist < EDGE_TOLERANCE:
				var keep := clampf(dist / EDGE_TOLERANCE, 0.0, 1.0)
				feathered.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * keep))
	return feathered

func _load_icon_textures() -> void:
	var icons := [
		["CurrBox1/CurrIcon1",               preload("res://image/icon_gold.png")],
		["CurrBox2/CurrIcon2",               preload("res://image/crystal_gem.png")],
		["CurrBox3/CurrIcon3",               preload("res://image/icon_paid.png")],
		["CurrBox4/CurrIcon4",               preload("res://image/icon_energy.png")],
		["MenuItem_Notice/Icon",             preload("res://image/icon_notice.png")],
		["MenuItem_Missions/Icon",           preload("res://image/icon_missions.png")],
		["MenuItem_Event/Icon",              preload("res://image/icon_event.png")],
		["MenuItem_Pass/Icon",               preload("res://image/icon_pass.png")],
		["MenuItem_Shop/Icon",               preload("res://image/icon_shop.png")],
		["AdventureCard/AdventureArt",       preload("res://image/bstory.jpg")],
		["SimulationCard/SimulationArt",     preload("res://image/bsimu.jpg")],
		["ArenaCard/ArenaArt",               preload("res://image/barena.jpg")],
		["ExpeditionCard/ExpeditionArt",     preload("res://image/chl.jpg")],
		["NavBar/Nav0_Alchemist/Icon",       preload("res://image/icon_nav_character.png")],
		["NavBar/Nav2_Lab/Icon",             preload("res://image/icon_nav_lab.png")],
		["NavBar/Nav_Gacha/Icon",            preload("res://image/icon_nav_gacha.png")],
		["NavBar/Nav3_Inventory/Icon",       preload("res://image/icon_nav_inventory.png")],
		["NavBar/Nav4_Database/Icon",        preload("res://image/icon_nav_achievement.png")],
		["NavBar/Nav5_Guild/Icon",           preload("res://image/icon_nav_guild.png")],
	]
	for pair in icons:
		var node := get_node_or_null(pair[0]) as TextureRect
		if node:
			node.texture = pair[1]
			if pair[0].begins_with("NavBar/"):
				node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			elif pair[0].ends_with("Art"):
				node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE
				if node.get_parent() is Control:
					(node.get_parent() as Control).clip_contents = true
					node.get_parent().move_child(node, 0)
					var art_bg := node.get_parent().get_node_or_null("ArtBg")
					if art_bg:
						art_bg.visible = false


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

## Top-right "สอนเล่น" (How to play) button — reopens the New Player Guide
## on demand. Sits in the empty gap between the currency row and the
## (hidden) settings button, both already anchored near the top-right corner.
func _setup_tutorial_button() -> void:
	var btn := Panel.new()
	btn.name = "BtnTutorial"
	# Right-anchored to stay consistent with the right-anchored currency pills
	# (fixed position drifted into the energy pill on wide screens).
	btn.anchor_left  = 1.0
	btn.anchor_right = 1.0
	btn.offset_left   = -170.0
	btn.offset_top    = 9.0
	btn.offset_right  = -74.0
	btn.offset_bottom = 37.0
	btn.z_index  = 10
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.05, 0.09, 0.20, 0.90)
	sb.border_color = Color(0.35, 0.70, 1.0, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("panel", sb)
	add_child(btn)

	var lbl := Label.new()
	lbl.text = "สอนเล่น"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0, 0.95))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var t := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			t.tween_property(btn, "scale", Vector2(0.90, 0.90), 0.06)
			t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.14)
			t.tween_callback(_open_new_player_guide)
	)
	btn.mouse_entered.connect(func():
		btn.create_tween().tween_property(btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	btn.mouse_exited.connect(func():
		btn.create_tween().tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)

func _open_new_player_guide() -> void:
	if get_node_or_null("_NewPlayerGuide") != null:
		return
	var guide := NewPlayerGuide.new()
	guide.name = "_NewPlayerGuide"
	add_child(guide)

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
	_setup_home_character()

# ── Home character + speech bubble ───────────────────────────────
func _setup_home_character() -> void:
	const DIALOGUES := [
		"วันนี้อากาศดีนะ...\nเหมาะกับการทดลองมาก",
		"สูตรใหม่สำเร็จแล้ว!\nลองดูด้วยกันไหม?",
		"พร้อมออกเดินทางแล้วหรือยัง?\nฉันรอนานมากแล้ว",
	]

	const CX    := 580.0   # center x
	const CW    := 520.0   # character width
	const CH    := 720.0   # character height
	const BOT_Y := 860.0   # bottom of character (knees visible)

	var char_root := Control.new()
	char_root.name = "_HomeChar"
	char_root.position = Vector2(CX - CW * 0.5, BOT_Y - CH)
	char_root.size     = Vector2(CW, CH)
	char_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_root.z_index  = 0
	add_child(char_root)
	# Move before NavBar so NavBar renders on top
	var _nb := get_node_or_null("NavBar")
	if _nb:
		move_child(char_root, _nb.get_index())

	# Portrait image — full body
	var portrait := TextureRect.new()
	portrait.texture      = preload("res://image/lyra_1.png")
	portrait.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size         = Vector2(CW, CH)
	portrait.position     = Vector2(0, 0)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_root.add_child(portrait)

	# Idle float animation
	var base_y := char_root.position.y
	var float_tw := char_root.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tw.tween_property(char_root, "position:y", base_y - 8.0, 2.2)
	float_tw.tween_property(char_root, "position:y", base_y,       2.2)

	# Speech bubble
	const BW := 250.0
	const BH := 66.0
	var bubble := Panel.new()
	bubble.name = "_Bubble"
	bubble.size     = Vector2(BW, BH)
	bubble.position = Vector2(CX - BW * 0.5, BOT_Y - CH - BH - 14)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.z_index  = 4
	var bsb := StyleBoxFlat.new()
	bsb.bg_color    = Color(0.04, 0.07, 0.18, 0.92)
	bsb.border_color = Color(0.35, 0.75, 1.0, 0.55)
	bsb.set_border_width(SIDE_LEFT,   1)
	bsb.set_border_width(SIDE_TOP,    1)
	bsb.set_border_width(SIDE_RIGHT,  1)
	bsb.set_border_width(SIDE_BOTTOM, 1)
	bsb.corner_radius_top_left     = 12
	bsb.corner_radius_top_right    = 12
	bsb.corner_radius_bottom_right = 12
	bsb.corner_radius_bottom_left  = 12
	bubble.add_theme_stylebox_override("panel", bsb)
	add_child(bubble)

	# Tail triangle (▼ label trick)
	var tail := Label.new()
	tail.text = "▼"
	tail.add_theme_font_size_override("font_size", 12)
	tail.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0, 0.55))
	tail.size     = Vector2(20, 14)
	tail.position = Vector2(BW * 0.5 - 10, BH - 2)
	tail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(tail)

	# Text label inside bubble
	var dlg_lbl := Label.new()
	dlg_lbl.name = "_DlgLbl"
	dlg_lbl.text = DIALOGUES[0]
	dlg_lbl.add_theme_font_size_override("font_size", 12)
	dlg_lbl.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 1.0))
	dlg_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dlg_lbl.offset_left = 14; dlg_lbl.offset_right = -14
	dlg_lbl.offset_top  = 6;  dlg_lbl.offset_bottom = -6
	dlg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dlg_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	dlg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(dlg_lbl)

	# Cycle dialogue every 12 s with fade (random)
	var dlg_idx := 0
	var cycle := create_tween().set_loops()
	cycle.tween_interval(12.0)
	cycle.tween_callback(func():
		if not is_instance_valid(dlg_lbl) or not is_instance_valid(bubble): return
		var next := randi() % DIALOGUES.size()
		if next == dlg_idx: next = (next + 1) % DIALOGUES.size()
		dlg_idx = next
		var fade := dlg_lbl.create_tween()
		fade.tween_property(dlg_lbl, "modulate:a", 0.0, 0.25)
		fade.tween_callback(func():
			if is_instance_valid(dlg_lbl):
				dlg_lbl.text = DIALOGUES[dlg_idx]  # dlg_idx already updated above
		)
		fade.tween_property(dlg_lbl, "modulate:a", 1.0, 0.35)
	)

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
		_show_coming_soon("โหมดต่อสู้ยังไม่เปิดให้บริการ")



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
	toast.position = Vector2((1152 - tw) / 2.0, (648 - th) / 2.0)
	toast.modulate = Color(1, 1, 1, 0.0)
	add_child(toast)

	var t := create_tween()
	t.tween_property(toast, "modulate:a", 1.0, 0.18)
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

