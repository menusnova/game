extends Control

const SC_BATTLE := "res://battle_scene.tscn"
const SC_MAIN   := "res://main_menu.tscn"
const SW := 1152.0
const SH := 648.0

var _keyed_enemy_tex_cache: Dictionary = {}   # path -> ImageTexture (background-keyed, cached once)

## Loads an enemy PNG and removes its flat background via a border flood-fill
## (same technique as battle_scene.gd's _get_keyed_texture): samples the
## image's own corner pixel as the background color, then only keys out
## pixels connected to the edge and similar to it, feathering the anti-
## aliased edge left behind so no white fringe remains.
func _get_keyed_enemy_texture(path: String) -> Texture2D:
	if _keyed_enemy_tex_cache.has(path):
		return _keyed_enemy_tex_cache[path]
	var src: Texture2D = AssetLoader.tex(path)
	if not src:
		return null
	var img: Image = src.get_image()
	if img == null:
		_keyed_enemy_tex_cache[path] = src
		return src
	img = img.duplicate()
	# Already-imported textures are usually VRAM-compressed by default —
	# get_pixel()/set_pixel() silently fail on a compressed Image, which
	# would corrupt this whole pass. Decompress before touching any pixels,
	# and if that fails for any reason, bail out with the plain original
	# rather than risk a half-corrupted result.
	if img.is_compressed():
		if img.decompress() != OK:
			_keyed_enemy_tex_cache[path] = src
			return src
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	# Already a proper cutout (corner pixel already transparent) — nothing
	# to key out, use as-is.
	if img.get_pixel(0, 0).a <= 0.02:
		_keyed_enemy_tex_cache[path] = src
		return src
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
		_keyed_enemy_tex_cache[path] = src
		return src

	# Some full illustrations (a painted scene, not a flat-color cutout)
	# only have a small matching sliver near one corner — color-based
	# keying can't isolate the character from painted scenery and leaves
	# a hard, torn-looking edge around whatever solid background remains.
	# Don't attempt to key those at all; instead fade the art's own outer
	# edges to transparent so it blends into the UI without any hard box.
	if float(cleared) / float(w * h) < 0.20:
		var faded: Image = src.get_image().duplicate()
		if faded.is_compressed():
			if faded.decompress() != OK:
				_keyed_enemy_tex_cache[path] = src
				return src
		faded.convert(Image.FORMAT_RGBA8)
		const EDGE_X := 0.14
		const EDGE_Y := 0.10
		for fy0 in h:
			var fy: float = minf(float(fy0) / (h * EDGE_Y), minf(float(h - 1 - fy0) / (h * EDGE_Y), 1.0))
			for fx0 in w:
				var fx: float = minf(float(fx0) / (w * EDGE_X), minf(float(w - 1 - fx0) / (w * EDGE_X), 1.0))
				var fc := faded.get_pixel(fx0, fy0)
				faded.set_pixel(fx0, fy0, Color(fc.r, fc.g, fc.b, fc.a * fx * fy))
		var faded_tex := ImageTexture.create_from_image(faded)
		_keyed_enemy_tex_cache[path] = faded_tex
		return faded_tex

	# Some art has background-colored gaps fully enclosed by the silhouette
	# (e.g. the negative space between an arm and the body) — not connected
	# to the image border, so the flood-fill above correctly leaves them
	# alone (that's what keeps small enclosed details intact). But a big
	# enclosed patch is almost always a real gap, not a detail worth
	# keeping, and left solid it reads as a torn/broken image. Clear any
	# such patch above a minimum size. Real limb/body gaps run
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

	var tex := ImageTexture.create_from_image(feathered)
	_keyed_enemy_tex_cache[path] = tex
	return tex

# ── Enemy data: 2 stages ──
const STAGE_ENEMIES := [
	[
		{"name": "Void Beast",  "hp": 1000, "weak": ["Rust (สนิม)"],   "icon": "💀", "img": "res://image/void_beast.png"},
	],
	[
		{"name": "Void Dragon", "hp": 1000, "weak": ["Water (น้ำ)"],  "icon": "☢", "img": "res://image/void_dragon.png"},
	],
]

# ── Team / deck limits ──
const MAX_CHARS      := 4
const MAX_ELEM_COPY  := 3   # copies of one element card
const MAX_SUPP_TYPES := 2   # distinct support types
const MAX_SUPP_COPY  := 2   # copies per support type

var _selected_chars: Array[String] = ["Lyra", "", "", ""]
var _elem_deck: Dictionary = {}   # elem  → count (0–3)
var _supp_deck: Dictionary = {}   # supp  → count (0–2)

var _current_stage := 0          # 0 or 1
var _edit_open     := false
var _enemy_expand  := false

@onready var _char_display_root: Control  = $CharacterDisplayRoot
@onready var _enemy_panel:       Control  = $EnemyPanel
@onready var _fade:              ColorRect = $FadeOverlay

# built at runtime
var _edit_panel:   Control  = null
var _char_slots:   Array    = []
var _elem_slots:   Array    = []
var _supp_slots:   Array    = []
var _stage_dots:   Array    = []
var _deck_total_lbl: Label  = null
var _deck_preview_panel: Control = null
var _deck_preview_list:  Control = null
var _elem_grid_ref: Control = null
var _supp_grid_ref: Control = null

# ── helpers ──
func _sb(col: Color, border: Color = Color(1,1,1,0), radius: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	if border.a > 0:
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			s.set_border_width(side, 1)
		s.border_color = border
	for r in ["corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]:
		s.set(r, radius)
	return s

func _lbl(txt: String, sz: int, col: Color, parent: Control, pos: Vector2, dims: Vector2 = Vector2.ZERO) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.position = pos
	if dims != Vector2.ZERO:
		l.size = dims
		l.clip_text = true
	parent.add_child(l)
	return l

func _btn(txt: String, sz: int, txt_col: Color, bg: StyleBoxFlat, parent: Control, pos: Vector2, dims: Vector2) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = dims
	b.add_theme_font_size_override("font_size", sz)
	b.add_theme_color_override("font_color", txt_col)
	b.add_theme_stylebox_override("normal", bg)
	b.add_theme_stylebox_override("hover", bg)
	b.add_theme_stylebox_override("pressed", bg)
	b.add_theme_stylebox_override("focus", StyleBoxFlat.new())
	parent.add_child(b)
	return b

# ── _ready ──
func _ready() -> void:
	if ResourceLoader.exists("res://image/bguio.png"):
		# The scene already has an opaque "Background" ColorRect (fallback
		# solid color) sitting at child index 0 — hide it, otherwise it
		# draws on top of / behind incorrectly and can cover this texture.
		var old_bg := get_node_or_null("Background")
		if old_bg:
			old_bg.visible = false

		var bg := TextureRect.new()
		bg.texture = load("res://image/bguio.png")
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.z_index = -1
		add_child(bg)
		move_child(bg, 0)

	$BottomBar/EditBtn.pressed.connect(_on_edit)
	$BottomBar/StartBtn.pressed.connect(_on_start)

	# Back button — top-left corner, returns to the main menu.
	var back_sb := _sb(Color(0.04, 0.07, 0.16, 0.82), Color(0.22, 0.62, 1, 0.5), 10)
	var back_b := _btn("‹  กลับ", 15, Color(0.9, 0.95, 1, 0.95), back_sb,
		self, Vector2(16, 14), Vector2(84, 40))
	back_b.z_index = 50
	back_b.pressed.connect(_on_back)
	_build_edit_panel()
	_build_deck_preview()
	_refresh_enemy_panel()
	_refresh_team_display()

	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 0.35)

# ── character display (center) ──
	# Will be populated by _refresh_team_display

func _refresh_team_display() -> void:
	for c in _char_display_root.get_children():
		c.queue_free()
	_char_slots.clear()

	var chars: Array = _selected_chars.filter(func(n): return n != "")
	var count := chars.size()
	if count == 0:
		return

	var center_y := SH / 2.0 - 20.0

	if count == 1:
		# Single selected character — stand full-body, centered on screen
		var ch: String = chars[0]
		var pw := 220.0; var ph := 340.0
		var cx := (SW - pw) / 2.0
		var cy := center_y - ph * 0.55 + 50.0   # nudged down

		# Same "<name>_1.png" pose convention first (Lyra), falling back to a
		# plain "<name>.png" for names that don't fit it (Caelum Voss ->
		# caelum_voss.png), same as the team-select grid cards.
		var portrait_path := "res://image/%s_1.png" % ch.to_lower()
		if not ResourceLoader.exists(portrait_path):
			portrait_path = "res://image/%s.png" % ch.to_lower().replace(" ", "_")
		if ResourceLoader.exists(portrait_path):
			# Soft elliptical ground shadow right at the feet
			var shadow := Panel.new()
			var shadow_w := pw * 0.42
			shadow.size = Vector2(shadow_w, 14)
			shadow.position = Vector2(cx + (pw - shadow_w) * 0.5, cy + ph - 10)
			var shadow_sb := StyleBoxFlat.new()
			shadow_sb.bg_color = Color(0, 0, 0, 0.30)
			shadow_sb.set_corner_radius_all(7)
			shadow.add_theme_stylebox_override("panel", shadow_sb)
			shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_char_display_root.add_child(shadow)

			var tex_rect := TextureRect.new()
			# Background-keyed (same border flood-fill technique used for the
			# enemy sprites) so the art's flat background doesn't show as a
			# solid box behind the standing character.
			tex_rect.texture = _get_keyed_enemy_texture(portrait_path)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.position = Vector2(cx, cy)
			tex_rect.size = Vector2(pw, ph)
			var is_char_owned := false
			for entry in CharacterManager.get_roster():
				if entry.get("name", "") == ch and entry.get("owned", false):
					is_char_owned = true
					break
			tex_rect.modulate = Color(1, 1, 1, 1.0) if is_char_owned else Color(1, 1, 1, 0.6)
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_char_display_root.add_child(tex_rect)

			_char_slots.append(tex_rect)
		else:
			var icon_lbl := Label.new()
			icon_lbl.text = "🧑"
			icon_lbl.add_theme_font_size_override("font_size", 96)
			icon_lbl.position = Vector2(cx, cy + ph * 0.3)
			icon_lbl.size = Vector2(pw, 140)
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_char_display_root.add_child(icon_lbl)
			_char_slots.append(icon_lbl)
	else:
		# Multiple characters — smaller cards side by side
		var slot_w := 110.0
		var total_w := count * slot_w + (count - 1) * 16.0
		var start_x := (SW - total_w) / 2.0

		for i in range(count):
			var ch: String = chars[i]
			var cx := start_x + i * (slot_w + 16.0)

			var card := Panel.new()
			card.position = Vector2(cx, center_y - 110.0)
			card.size = Vector2(slot_w, 150.0)
			card.clip_contents = true
			card.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.12, 0.26, 0.7), Color(0.4, 0.6, 1.0, 0.25), 12))
			_char_display_root.add_child(card)

			var portrait_path := "res://image/%s_1.png" % ch.to_lower()
			if ResourceLoader.exists(portrait_path):
				var tex_rect := TextureRect.new()
				tex_rect.texture = load(portrait_path)
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tex_rect.position = Vector2(0, 4)
				tex_rect.size = Vector2(slot_w, 84)
				tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				card.add_child(tex_rect)
			else:
				var icon_lbl := Label.new()
				icon_lbl.text = "🧑" if i % 2 == 0 else "⚔"
				icon_lbl.add_theme_font_size_override("font_size", 48)
				icon_lbl.position = Vector2(0, 12)
				icon_lbl.size = Vector2(slot_w, 70)
				icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				card.add_child(icon_lbl)

			var name_lbl := Label.new()
			name_lbl.text = ch
			name_lbl.add_theme_font_size_override("font_size", 11)
			name_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.9))
			name_lbl.position = Vector2(4, 90)
			name_lbl.size = Vector2(slot_w - 8, 20)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(name_lbl)

			_char_slots.append(card)


# ── enemy panel (top-right, compact → expandable) ──

func _refresh_enemy_panel() -> void:
	for c in _enemy_panel.get_children():
		c.queue_free()

	var enemies: Array = STAGE_ENEMIES[_current_stage]
	var panel_h := 30.0 + enemies.size() * 72.0 + 12.0

	var bg := Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(270, panel_h)
	bg.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.04, 0.10, 0.88), Color(0.8, 0.3, 0.3, 0.2), 10))
	_enemy_panel.add_child(bg)

	# stage dots
	_stage_dots.clear()
	var dots_row := Control.new()
	dots_row.position = Vector2(8, 8)
	dots_row.size = Vector2(254, 16)
	bg.add_child(dots_row)

	for s in range(STAGE_ENEMIES.size()):
		var dot := Panel.new()
		dot.position = Vector2(s * 20, 2)
		dot.size = Vector2(14, 12)
		var col := Color(1.0, 0.6, 0.3, 0.9) if s == _current_stage else Color(0.4, 0.4, 0.4, 0.5)
		dot.add_theme_stylebox_override("panel", _sb(col, Color(0,0,0,0), 3))
		dots_row.add_child(dot)
		_stage_dots.append(dot)

	_lbl("STAGE %d" % (_current_stage + 1) + (" · FINAL" if _current_stage == STAGE_ENEMIES.size() - 1 else ""),
		10, Color(1.0, 0.7, 0.3, 0.8), bg, Vector2(50, 5))

	for i in range(enemies.size()):
		var en: Dictionary = enemies[i]
		var ey := 28.0 + i * 74.0

		var chip := Panel.new()
		chip.position = Vector2(8, ey)
		chip.size = Vector2(254, 64)
		chip.add_theme_stylebox_override("panel", _sb(Color(0.12, 0.04, 0.04, 0.7), Color(0.8, 0.25, 0.25, 0.18), 8))
		bg.add_child(chip)

		_lbl(en["icon"] + " " + en["name"].to_upper(), 12, Color(1.0, 0.65, 0.65, 0.95), chip, Vector2(8, 6))
		_lbl("HP  %d" % en["hp"], 10, Color(0.7, 1.0, 0.7, 0.7), chip, Vector2(8, 24))
		_lbl("อ่อนแอ: " + "  ".join(en["weak"]), 10, Color(0.5, 0.8, 1.0, 0.8), chip, Vector2(8, 42))

		# expand button
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_toggle_enemy_expand())

	# stage toggle row
	var tog_y := 28.0 + enemies.size() * 74.0 + 4.0
	for s in range(STAGE_ENEMIES.size()):
		var tb_lbl := "S%d" % (s+1)
		var tb := _btn(tb_lbl, 10,
			Color(1.0, 0.85, 0.4) if s == _current_stage else Color(0.6, 0.6, 0.6),
			_sb(Color(0.15, 0.1, 0.05, 0.6) if s == _current_stage else Color(0.08, 0.08, 0.08, 0.5),
				Color(1.0,0.6,0.2,0.3) if s == _current_stage else Color(0.3,0.3,0.3,0.3), 4),
			bg, Vector2(8 + s * 42, tog_y), Vector2(36, 20))
		var stage_idx := s
		tb.pressed.connect(func():
			_current_stage = stage_idx
			_refresh_enemy_panel())

	_enemy_panel.size = Vector2(270, panel_h + 28.0)

# ── enemy expand overlay ──
var _expand_overlay: Control = null
func _toggle_enemy_expand() -> void:
	if _expand_overlay and is_instance_valid(_expand_overlay):
		_expand_overlay.queue_free()
		_expand_overlay = null
		return

	_expand_overlay = Control.new()
	_expand_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_expand_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.75)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_toggle_enemy_expand())
	_expand_overlay.add_child(dim)

	var pw := 700.0; var ph := 500.0
	var px := (SW - pw) / 2.0; var py := (SH - ph) / 2.0
	var pop := Panel.new()
	pop.position = Vector2(px, py)
	pop.size = Vector2(pw, ph)
	pop.add_theme_stylebox_override("panel", _sb(Color(0.07, 0.04, 0.12, 0.97), Color(0.8, 0.3, 0.3, 0.3), 14))
	_expand_overlay.add_child(pop)

	_lbl("ข้อมูลศัตรู", 18, Color(1, 0.7, 0.7), pop, Vector2(24, 18))
	var close_b := _btn("✕", 14, Color(1,1,1,0.6), _sb(Color(0,0,0,0)), pop,
		Vector2(pw - 40, 12), Vector2(28, 28))
	close_b.pressed.connect(_toggle_enemy_expand)

	var all_enemies: Array = []
	for stage in STAGE_ENEMIES:
		all_enemies.append_array(stage)

	var ey := 56.0
	for i in range(all_enemies.size()):
		var en: Dictionary = all_enemies[i]
		var stage_of := 0 if i < STAGE_ENEMIES[0].size() else 1

		var chip := Panel.new()
		chip.position = Vector2(20, ey)
		chip.size = Vector2(pw - 40, 116)
		chip.add_theme_stylebox_override("panel", _sb(Color(0.12, 0.04, 0.06, 0.85), Color(0.8,0.25,0.25,0.2), 10))
		pop.add_child(chip)

		var icon_box := Control.new()
		icon_box.position = Vector2(12, 12)
		icon_box.size = Vector2(92, 92)
		icon_box.clip_contents = true
		icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(icon_box)
		var icon_sb := StyleBoxFlat.new()
		icon_sb.bg_color = Color(0.03, 0.02, 0.05, 0.6)
		icon_sb.set_corner_radius_all(10)
		var icon_bg := Panel.new()
		icon_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_bg.add_theme_stylebox_override("panel", icon_sb)
		icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_box.add_child(icon_bg)
		var img_path: String = str(en.get("img", ""))
		var img_tex: Texture2D = _get_keyed_enemy_texture(img_path)
		if img_tex:
			var itex := TextureRect.new()
			itex.texture = img_tex
			itex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			itex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			itex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			itex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_box.add_child(itex)
		else:
			_lbl(en["icon"], 32, Color.WHITE, icon_box, Vector2(15, 13))
		# All text starts to the right of the enlarged icon (x12-104) so it
		# never overlaps the monster art.
		_lbl(en["name"].to_upper(), 15, Color(1.0, 0.7, 0.7), chip, Vector2(120, 16))
		_lbl("Stage %d%s" % [stage_of + 1, " · FINAL" if stage_of == STAGE_ENEMIES.size()-1 else ""],
			11, Color(1.0, 0.75, 0.3, 0.8), chip, Vector2(120, 46))
		_lbl("HP: %d" % en["hp"], 12, Color(0.6, 1.0, 0.6, 0.85), chip, Vector2(120, 74))
		_lbl("อ่อนแอต่อ:  " + "  /  ".join(en["weak"]), 12, Color(0.5, 0.85, 1.0, 0.9), chip, Vector2(320, 74))

		ey += 130.0

# ── edit panel (slides in from left) ──
const EDIT_W := 360.0

func _build_edit_panel() -> void:
	_edit_panel = Control.new()
	_edit_panel.position = Vector2(-EDIT_W, 0)
	_edit_panel.size = Vector2(EDIT_W, SH)
	_edit_panel.visible = false
	# Above the back button (z 50) so the sliding panel covers it instead of
	# the back button poking through on top.
	_edit_panel.z_index = 60
	add_child(_edit_panel)

	var bg := Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(EDIT_W, SH)
	bg.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.07, 0.16, 0.97), Color(0.3, 0.5, 1.0, 0.2), 0))
	_edit_panel.add_child(bg)

	# ── TOP: character selection ──
	var char_header := Panel.new()
	char_header.position = Vector2(0, 0)
	char_header.size = Vector2(EDIT_W, 32)
	char_header.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.12, 0.28, 1.0)))
	bg.add_child(char_header)
	_lbl("เลือกตัวละคร", 12, Color(0.6, 0.8, 1.0, 0.9), char_header, Vector2(12, 8))

	# char grid: 3 cols × 110px — roster is small (2 chars = 1 row)
	var char_rows := ceili(float(CharacterManager.get_roster().size()) / 3.0)
	var char_h    := maxi(char_rows, 1) * (110 + 8) + 4
	var char_panel := Control.new()
	char_panel.position = Vector2(8, 36)
	char_panel.size = Vector2(EDIT_W - 16, char_h)
	bg.add_child(char_panel)
	_build_char_grid(char_panel)

	# ── BOTTOM: cards ──
	var sep_y := 36.0 + char_h + 6.0
	var sep := Panel.new()
	sep.position = Vector2(0, sep_y)
	sep.size = Vector2(EDIT_W, 1)
	sep.add_theme_stylebox_override("panel", _sb(Color(0.3, 0.5, 1.0, 0.15)))
	bg.add_child(sep)

	# Element cards sub-section — pool = lab's unlocked elements + discovered
	var elem_count := _elem_pool().size()
	var elem_rows  := ceili(float(elem_count) / 5.0)
	var elem_h     := elem_rows * (64 + 6) + 4

	var elem_header := Panel.new()
	elem_header.position = Vector2(0, sep_y + 2)
	elem_header.size = Vector2(EDIT_W, 24)
	elem_header.add_theme_stylebox_override("panel", _sb(Color(0.04, 0.10, 0.20, 1.0)))
	bg.add_child(elem_header)
	_lbl("การ์ดธาตุ  (×1–×3 ต่อชนิด · สูงสุด 16 ใบ)", 10,
		Color(0.4, 0.8, 1.0, 0.85), elem_header, Vector2(12, 5))

	var elem_panel := Control.new()
	elem_panel.position = Vector2(8, sep_y + 28)
	elem_panel.size = Vector2(EDIT_W - 16, elem_h)
	bg.add_child(elem_panel)
	_elem_grid_ref = elem_panel
	_build_elem_grid(elem_panel)

	# Support cards sub-section
	var supp_sep_y := sep_y + 28 + elem_h + 6
	var supp_header := Panel.new()
	supp_header.position = Vector2(0, supp_sep_y)
	supp_header.size = Vector2(EDIT_W, 24)
	supp_header.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.04, 0.18, 1.0)))
	bg.add_child(supp_header)
	_lbl("การ์ดสนับสนุน  (สูงสุด 2 ชนิด × 2 ใบ)", 10,
		Color(0.8, 0.55, 1.0, 0.85), supp_header, Vector2(12, 5))

	var supp_panel := Control.new()
	supp_panel.position = Vector2(8, supp_sep_y + 28)
	supp_panel.size = Vector2(EDIT_W - 16, 80)
	bg.add_child(supp_panel)
	_supp_grid_ref = supp_panel
	_build_supp_grid(supp_panel)

	# confirm + close buttons
	var conf_sb := _sb(Color(0.12, 0.35, 0.85, 1.0), Color(0.4,0.6,1.0,0.3), 10)
	var conf_b := _btn("✓  ยืนยัน", 13, Color.WHITE, conf_sb,
		bg, Vector2(EDIT_W - 124, SH - 56), Vector2(116, 40))
	conf_b.pressed.connect(_on_edit_close)

	var cancel_sb := _sb(Color(0.1,0.1,0.1,0.6), Color(0.4,0.4,0.4,0.3), 10)
	var cancel_b := _btn("✕  ยกเลิก", 12, Color(0.8,0.8,0.8,0.8), cancel_sb,
		bg, Vector2(8, SH - 56), Vector2(110, 40))
	cancel_b.pressed.connect(_on_edit_close)

# ── rarity border color ──
func _rarity_color(r: int) -> Color:
	match r:
		5: return Color(1.00, 0.80, 0.20)
		4: return Color(0.70, 0.40, 1.00)
		_: return Color(0.35, 0.65, 1.00)

# ── count badge (top-right corner) ──
const NON_PLAYABLE_CHARS := ["Caelum Voss"]

func _build_char_grid(parent: Control) -> void:
	# Only owned AND battle-playable characters are offered here. Caelum Voss
	# is a showcase-only character: even after being summoned he must not show
	# up in the pre-battle team select.
	var roster: Array[Dictionary] = CharacterManager.get_roster().filter(
		func(e): return e.get("owned", false) and e.get("name", "") not in NON_PLAYABLE_CHARS
	)

	var cols := 3
	var cw := 86.0; var ch_h := 110.0; var gap := 8.0
	for i in range(roster.size()):
		var entry: Dictionary = roster[i]
		var name_str: String  = entry["name"]
		var owned: bool = entry.get("owned", false)
		var row := i / cols; var col := i % cols
		var is_sel := _selected_chars.has(name_str)
		var rcol: Color = _rarity_color(entry.get("rarity", 3))
		var ecol: Color = entry.get("element_color", Color(0.4, 0.7, 1.0))

		var card := Panel.new()
		card.position = Vector2(col * (cw + gap), row * (ch_h + gap))
		card.size     = Vector2(cw, ch_h)
		card.clip_contents = true
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.08, 0.18, 0.95) if owned else Color(0.04, 0.04, 0.06, 0.85)
		sb.border_color = rcol if is_sel else Color(rcol.r, rcol.g, rcol.b, 0.25 if owned else 0.12)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			sb.set_border_width(side, 2 if is_sel else 1)
		sb.set_corner_radius_all(8)
		if is_sel:
			sb.shadow_color = Color(ecol.r, ecol.g, ecol.b, 0.5)
			sb.shadow_size  = 6
		card.add_theme_stylebox_override("panel", sb)
		parent.add_child(card)

		# Portrait — shown for every character (owned or not, dimmed when
		# locked) so a locked character like Caelum still previews his own
		# art here instead of a blank lock icon. Tries the "<name>_1.png"
		# pose convention first (Lyra), then a plain "<name>.png" fallback
		# (Caelum Voss -> caelum_voss.png).
		var portrait_path := "res://image/%s_1.png" % name_str.to_lower()
		if not ResourceLoader.exists(portrait_path):
			portrait_path = "res://image/%s.png" % name_str.to_lower().replace(" ", "_")
		if ResourceLoader.exists(portrait_path):
			var tex_rect := TextureRect.new()
			tex_rect.texture = load(portrait_path)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.position = Vector2(0, 0)
			tex_rect.size = Vector2(cw, ch_h - 22)
			tex_rect.modulate = Color(1, 1, 1, 1.0) if owned else Color(1, 1, 1, 0.55)
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(tex_rect)
		else:
			_lbl("🧑", 36, Color(1, 1, 1, 1.0 if owned else 0.5), card, Vector2(cw / 2 - 18, 10))

		if not owned:
			# Dark scrim + big centered lock icon so a locked card reads as
			# clearly locked at a glance, even next to the selection
			# checkmark (selectable for preview, but still visibly locked).
			var scrim := ColorRect.new()
			scrim.color = Color(0, 0, 0, 0.38)
			scrim.size = Vector2(cw, ch_h - 22)
			scrim.position = Vector2(0, 0)
			scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(scrim)

			var lock_path := "res://image/lock_chain_x.png"
			if ResourceLoader.exists(lock_path):
				var lock_tex := TextureRect.new()
				lock_tex.texture = load(lock_path)
				lock_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				lock_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				lock_tex.size = Vector2(34, 34)
				lock_tex.position = Vector2((cw - 34) * 0.5, (ch_h - 22 - 34) * 0.5)
				lock_tex.modulate = Color(1, 1, 1, 0.95)
				lock_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
				card.add_child(lock_tex)

		# rarity stars / lock label bottom strip
		var strip := Panel.new()
		strip.position = Vector2(0, ch_h - 22)
		strip.size = Vector2(cw, 22)
		var strip_sb := StyleBoxFlat.new()
		strip_sb.bg_color = Color(0.02, 0.04, 0.12, 0.92)
		strip.add_theme_stylebox_override("panel", strip_sb)
		card.add_child(strip)

		# Rarity stars — shown for everyone; the lock badge on the portrait
		# already conveys locked status, so the strip stays stars-only.
		var stars_lbl := Label.new()
		var star_count: int = entry.get("rarity", 3)
		stars_lbl.text = "★".repeat(star_count)
		stars_lbl.add_theme_font_size_override("font_size", 9)
		stars_lbl.add_theme_color_override("font_color", rcol if owned else Color(rcol.r, rcol.g, rcol.b, 0.5))
		stars_lbl.position = Vector2(2, 5)
		stars_lbl.size = Vector2(cw - 4, 12)
		stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(stars_lbl)

		if is_sel:
			var sel_mark := Label.new()
			sel_mark.text = "✓"
			sel_mark.add_theme_font_size_override("font_size", 14)
			sel_mark.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 0.9))
			sel_mark.position = Vector2(cw - 20, 4)
			sel_mark.size = Vector2(16, 16)
			sel_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(sel_mark)

		# Locked characters are still tappable for selection/preview — they
		# just can't actually start a battle (see _on_start()).
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var n := name_str
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_toggle_char(n)
				_rebuild_char_grid(parent))

func _rebuild_char_grid(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()
	_build_char_grid(parent)
	_refresh_team_display()

## Only one character can be selected at a time — tapping a card selects it
## (clearing whatever was picked before, glow border and all, even for a
## locked character like Caelum who's previewable but not battle-ready),
## and tapping the already-selected card deselects it.
func _toggle_char(name_str: String) -> void:
	var already_selected := _selected_chars.has(name_str)
	for i in _selected_chars.size():
		_selected_chars[i] = ""
	if not already_selected:
		_selected_chars[0] = name_str

# ── element deck grid ──
# ── element pool: whatever the lab offers, plus anything discovered ──
func _elem_pool() -> Array:
	var pool: Array = []
	for e in ReactionDB.ELEMENTS:
		if e.get("unlocked", false):
			pool.append(e["symbol"])
	for sym in PlayerData.discovered_elements:
		if sym not in pool:
			pool.append(sym)
	if pool.is_empty():
		pool = ["H", "O"]
	return pool

# ── deck total helpers ──
func _elem_deck_total() -> int:
	var t := 0
	for v in _elem_deck.values(): t += v
	return t

func _supp_deck_total() -> int:
	var t := 0
	for v in _supp_deck.values(): t += v
	return t

func _build_elem_grid(parent: Control) -> void:
	# Element pool = whatever the lab offers (ReactionDB.ELEMENTS, unlocked)
	# plus anything additionally discovered — same source of truth as lab.
	var elem_colors: Dictionary = {}
	for e in ReactionDB.ELEMENTS:
		elem_colors[e["symbol"]] = e["color"]
	var owned_elems: Array = _elem_pool()

	var deck_total := _elem_deck_total()
	var cw := 54.0; var ch_h := 64.0; var gap := 6.0; var cols := 5
	for i in range(owned_elems.size()):
		var elem: String = owned_elems[i]
		var count: int   = _elem_deck.get(elem, 0)
		var ecol: Color  = elem_colors.get(elem, Color(0.5, 0.8, 1.0))
		var row := i / cols; var col := i % cols
		var at_cap := deck_total >= 16 and count == 0

		var card := Panel.new()
		card.position = Vector2(col * (cw + gap), row * (ch_h + gap))
		card.size     = Vector2(cw, ch_h)
		card.clip_contents = true
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(ecol.r * 0.12, ecol.g * 0.12, ecol.b * 0.18, 0.95) if count > 0 \
					else Color(0.05, 0.08, 0.16, 0.9)
		sb.border_color = Color(ecol.r, ecol.g, ecol.b, 0.85) if count > 0 \
						else Color(ecol.r, ecol.g, ecol.b, 0.2 if not at_cap else 0.08)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			sb.set_border_width(side, 2 if count > 0 else 1)
		sb.set_corner_radius_all(8)
		if count > 0:
			sb.shadow_color = Color(ecol.r, ecol.g, ecol.b, 0.4)
			sb.shadow_size  = 5
		card.add_theme_stylebox_override("panel", sb)
		card.modulate = Color(1, 1, 1, 0.4) if at_cap else Color(1, 1, 1, 1)
		parent.add_child(card)

		var sym_lbl := Label.new()
		sym_lbl.text = elem
		sym_lbl.add_theme_font_size_override("font_size", 20)
		sym_lbl.add_theme_color_override("font_color",
			Color(ecol.r + 0.2, ecol.g + 0.2, ecol.b + 0.2) if count > 0 else Color(ecol.r, ecol.g, ecol.b, 0.5))
		sym_lbl.position = Vector2(0, 8)
		sym_lbl.size = Vector2(cw, 28)
		sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(sym_lbl)

		# copy count indicator dots
		var dot_y := ch_h - 14.0
		for d in range(MAX_ELEM_COPY):
			var dot := Panel.new()
			dot.size = Vector2(8, 8)
			dot.position = Vector2(cw / 2.0 - (MAX_ELEM_COPY * 10.0) / 2.0 + d * 10.0, dot_y)
			var ds := StyleBoxFlat.new()
			ds.bg_color = Color(ecol.r, ecol.g, ecol.b, 0.9) if d < count else Color(0.2, 0.2, 0.3, 0.6)
			ds.set_corner_radius_all(4)
			dot.add_theme_stylebox_override("panel", ds)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(dot)

		# tier frame — elements are always tier 1 (base substances)
		var eframe := TextureRect.new()
		eframe.texture      = preload("res://image/g1.jpg")
		eframe.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		eframe.stretch_mode = TextureRect.STRETCH_SCALE
		eframe.size         = Vector2(cw + 4, ch_h + 4)
		eframe.position     = Vector2(-2, -2)
		eframe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var efmat := CanvasItemMaterial.new()
		efmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		eframe.material = efmat
		card.add_child(eframe)

		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var e := elem
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_cycle_elem(e)
				_rebuild_elem_grid(parent))

func _rebuild_elem_grid(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()
	_build_elem_grid(parent)
	_refresh_deck_total_lbl()
	_refresh_deck_preview()

func _cycle_elem(elem: String) -> void:
	var cur: int = _elem_deck.get(elem, 0)
	if cur >= MAX_ELEM_COPY:
		_elem_deck.erase(elem)
		return
	# Deck-wide caps: elements ≤16 total, whole deck ≤20 total
	if _elem_deck_total() >= 16: return
	if _elem_deck_total() + _supp_deck_total() >= 20: return
	_elem_deck[elem] = cur + 1

# ── support deck grid ──
const SUPP_LABELS := {
	"Draw2":     "จั่วการ์ด 2",
	"RecoverAP": "ฟื้นฟู AP",
}

func _build_supp_grid(parent: Control) -> void:
	var owned_supp: Array = ["Draw2", "RecoverAP"]

	var cw := 100.0; var ch_h := 68.0; var gap := 8.0
	for i in range(owned_supp.size()):
		var supp: String = owned_supp[i]
		var count: int   = _supp_deck.get(supp, 0)
		var is_sel       := count > 0

		var card := Panel.new()
		card.position = Vector2(i * (cw + gap), 0)
		card.size     = Vector2(cw, ch_h)
		card.clip_contents = true
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.08, 0.32, 0.95) if is_sel else Color(0.06, 0.04, 0.14, 0.9)
		sb.border_color = Color(0.85, 0.55, 1.0, 0.9) if is_sel else Color(0.5, 0.35, 0.7, 0.25)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			sb.set_border_width(side, 2 if is_sel else 1)
		sb.set_corner_radius_all(8)
		if is_sel:
			sb.shadow_color = Color(0.7, 0.3, 1.0, 0.45)
			sb.shadow_size  = 5
		card.add_theme_stylebox_override("panel", sb)
		parent.add_child(card)

		var nl := Label.new()
		nl.text = SUPP_LABELS.get(supp, supp)
		nl.add_theme_font_size_override("font_size", 9)
		nl.add_theme_color_override("font_color",
			Color(0.9, 0.75, 1.0) if is_sel else Color(0.65, 0.6, 0.8, 0.7))
		nl.position = Vector2(4, 14)
		nl.custom_minimum_size = Vector2(cw - 8, 0)
		nl.size = Vector2(cw - 8, 28)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nl)

		# copy dots
		for d in range(MAX_SUPP_COPY):
			var dot := Panel.new()
			dot.size = Vector2(10, 10)
			dot.position = Vector2(cw / 2.0 - (MAX_SUPP_COPY * 12.0) / 2.0 + d * 12.0, ch_h - 16.0)
			var ds := StyleBoxFlat.new()
			ds.bg_color = Color(0.85, 0.55, 1.0, 0.9) if d < count else Color(0.2, 0.15, 0.3, 0.6)
			ds.set_corner_radius_all(5)
			dot.add_theme_stylebox_override("panel", ds)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(dot)

		# tier frame — support cards are tier 2
		var sframe := TextureRect.new()
		sframe.texture      = preload("res://image/g2.jpg")
		sframe.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		sframe.stretch_mode = TextureRect.STRETCH_SCALE
		sframe.size         = Vector2(cw + 4, ch_h + 4)
		sframe.position     = Vector2(-2, -2)
		sframe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sfmat := CanvasItemMaterial.new()
		sfmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sframe.material = sfmat
		card.add_child(sframe)

		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var s := supp
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_cycle_supp(s)
				_rebuild_supp_grid(parent))

func _rebuild_supp_grid(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()
	_build_supp_grid(parent)
	_refresh_deck_total_lbl()
	_refresh_deck_preview()

func _refresh_deck_total_lbl() -> void:
	if is_instance_valid(_deck_total_lbl):
		_deck_total_lbl.text = "เด็ค: %d / 20" % (_elem_deck_total() + _supp_deck_total())

func _cycle_supp(supp: String) -> void:
	var cur: int = _supp_deck.get(supp, 0)
	if cur >= MAX_SUPP_COPY:
		_supp_deck.erase(supp)
		return
	if cur == 0:
		# only allow adding a new type if fewer than MAX_SUPP_TYPES active
		var active_types := 0
		for k in _supp_deck:
			if _supp_deck[k] > 0:
				active_types += 1
		if active_types >= MAX_SUPP_TYPES:
			return
	# Deck-wide cap: whole deck (elements + support) ≤20 total
	if _elem_deck_total() + _supp_deck_total() >= 20: return
	_supp_deck[supp] = cur + 1

# ── deck preview strip (right side) — shows picked cards, tap to remove ──
const DECK_PREVIEW_W := 260.0

func _build_deck_preview() -> void:
	_deck_preview_panel = Control.new()
	_deck_preview_panel.position = Vector2(SW - DECK_PREVIEW_W - 16, 0)
	_deck_preview_panel.size = Vector2(DECK_PREVIEW_W, SH)
	_deck_preview_panel.visible = false
	_deck_preview_panel.z_index = 5
	add_child(_deck_preview_panel)

	var bg := Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(DECK_PREVIEW_W, SH)
	bg.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.07, 0.16, 0.97), Color(0.3, 0.5, 1.0, 0.2), 0))
	_deck_preview_panel.add_child(bg)

	var header := Panel.new()
	header.position = Vector2(0, 0)
	header.size = Vector2(DECK_PREVIEW_W, 36)
	header.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.12, 0.28, 1.0)))
	bg.add_child(header)
	_lbl("เด็คของคุณ (แตะเพื่อเอาออก)", 12, Color(0.75, 0.85, 1.0, 0.9), header, Vector2(12, 10))

	# live deck total counter — top-right of the deck preview panel
	_deck_total_lbl = _lbl("เด็ค: %d / 20" % (_elem_deck_total() + _supp_deck_total()),
		11, Color(0.75, 0.85, 1.0, 0.85), header, Vector2(DECK_PREVIEW_W - 90, 10), Vector2(80, 18))
	_deck_total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 40)
	scroll.size = Vector2(DECK_PREVIEW_W, SH - 40)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bg.add_child(scroll)

	_deck_preview_list = VBoxContainer.new()
	_deck_preview_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_preview_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_deck_preview_list)

func _refresh_deck_preview() -> void:
	if not is_instance_valid(_deck_preview_list):
		return
	for c in _deck_preview_list.get_children():
		c.queue_free()

	var elem_colors: Dictionary = {}
	for e in ReactionDB.ELEMENTS:
		elem_colors[e["symbol"]] = e["color"]

	var any_cards := false
	for elem in _elem_deck.keys():
		var count: int = _elem_deck[elem]
		if count <= 0: continue
		any_cards = true
		var ecol: Color = elem_colors.get(elem, Color(0.5, 0.8, 1.0))
		_deck_preview_list.add_child(_make_deck_preview_row(elem, "ธาตุ", count, ecol,
			func():
				var cur: int = _elem_deck.get(elem, 0) - 1
				if cur <= 0: _elem_deck.erase(elem)
				else: _elem_deck[elem] = cur
				_rebuild_elem_grid(_elem_grid_ref); _refresh_deck_preview()))

	for supp in _supp_deck.keys():
		var count: int = _supp_deck[supp]
		if count <= 0: continue
		any_cards = true
		_deck_preview_list.add_child(_make_deck_preview_row(supp, "สนับสนุน", count, Color(0.85, 0.55, 1.0),
			func():
				var cur: int = _supp_deck.get(supp, 0) - 1
				if cur <= 0: _supp_deck.erase(supp)
				else: _supp_deck[supp] = cur
				_rebuild_supp_grid(_supp_grid_ref); _refresh_deck_preview()))

	if not any_cards:
		var empty_lbl := Label.new()
		empty_lbl.text = "ยังไม่ได้เลือกการ์ด"
		empty_lbl.add_theme_font_size_override("font_size", 11)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7, 0.6))
		empty_lbl.position = Vector2(12, 8)
		_deck_preview_list.add_child(empty_lbl)

func _make_deck_preview_row(name_str: String, tag: String, count: int, col: Color, on_remove: Callable) -> Panel:
	var row := Panel.new()
	row.custom_minimum_size = Vector2(DECK_PREVIEW_W - 16, 40)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r * 0.14, col.g * 0.14, col.b * 0.20, 0.9)
	sb.border_color = Color(col.r, col.g, col.b, 0.5)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sb.set_border_width(side, 1)
	sb.set_corner_radius_all(6)
	row.add_theme_stylebox_override("panel", sb)

	var name_lbl := Label.new()
	name_lbl.text = name_str
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(col.r + 0.15, col.g + 0.15, col.b + 0.15, 1.0))
	name_lbl.position = Vector2(10, 5)
	name_lbl.size = Vector2(140, 16)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_lbl)

	var tag_lbl := Label.new()
	tag_lbl.text = tag
	tag_lbl.add_theme_font_size_override("font_size", 8)
	tag_lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.6))
	tag_lbl.position = Vector2(10, 21)
	tag_lbl.size = Vector2(100, 12)
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tag_lbl)

	var count_lbl := Label.new()
	count_lbl.text = "×%d" % count
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color.WHITE)
	count_lbl.position = Vector2(row.custom_minimum_size.x - 60, 5)
	count_lbl.size = Vector2(30, 30)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(count_lbl)

	var remove_lbl := Label.new()
	remove_lbl.text = "✕"
	remove_lbl.add_theme_font_size_override("font_size", 14)
	remove_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 0.85))
	remove_lbl.position = Vector2(row.custom_minimum_size.x - 26, 5)
	remove_lbl.size = Vector2(20, 30)
	remove_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remove_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	remove_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(remove_lbl)

	row.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			on_remove.call())

	return row

# ── edit open/close ──
func _on_edit() -> void:
	if _edit_open:
		return
	_edit_open = true
	_edit_panel.visible = true
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_edit_panel, "position:x", 0.0, 0.3)

	if is_instance_valid(_deck_preview_panel):
		_deck_preview_panel.visible = true
		_deck_preview_panel.modulate.a = 0.0
		_refresh_deck_preview()
		var t2 := create_tween()
		t2.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		t2.tween_property(_deck_preview_panel, "modulate:a", 1.0, 0.3)
	# Deck preview occupies the same screen region as the enemy panel —
	# hide it while editing to avoid overlap
	if is_instance_valid(_enemy_panel):
		_enemy_panel.visible = false

func _on_edit_close() -> void:
	if not _edit_open:
		return
	var t := create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_edit_panel, "position:x", -EDIT_W, 0.25)
	if is_instance_valid(_deck_preview_panel):
		var t2 := create_tween()
		t2.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		t2.tween_property(_deck_preview_panel, "modulate:a", 0.0, 0.25)
	await t.finished
	_edit_open = false
	_edit_panel.visible = false
	if is_instance_valid(_deck_preview_panel):
		_deck_preview_panel.visible = false
	if is_instance_valid(_enemy_panel):
		_enemy_panel.visible = true
	_refresh_team_display()

# ── back ──
func _on_back() -> void:
	SceneTransition.fade_to(SC_MAIN)

# ── start ──
const DECK_REQUIRED := 20

func _on_start() -> void:
	if _has_locked_char_selected():
		_show_locked_char_msg()
		return
	if _elem_deck_total() + _supp_deck_total() < DECK_REQUIRED:
		_show_deck_required_msg()
		return
	PlayerData.battle_elem_deck = _elem_deck.duplicate()
	PlayerData.battle_supp_deck = _supp_deck.duplicate()
	var chars: Array[String] = []
	for n in _selected_chars:
		if n != "": chars.append(n)
	PlayerData.battle_chars = chars
	PlayerData.battle_deck_ready = true
	DomainManager.add_points("battle")
	SceneTransition.fade_to(SC_BATTLE)

## True if any selected slot holds a character the player hasn't unlocked yet
## (tappable for preview in the grid, but not battle-ready).
func _has_locked_char_selected() -> bool:
	for n in _selected_chars:
		if n == "": continue
		for entry in CharacterManager.get_roster():
			if entry.get("name", "") == n and not entry.get("owned", false):
				return true
	return false

func _show_locked_char_msg() -> void:
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.6)
	ov.anchor_right = 1.0; ov.anchor_bottom = 1.0
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.z_index = 100
	add_child(ov)

	var panel := Panel.new()
	panel.size = Vector2(320, 140)
	panel.position = (get_viewport_rect().size - panel.size) / 2.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.14, 0.97)
	sb.border_color = Color(1.0, 0.4, 0.4, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	ov.add_child(panel)

	var lbl_clip := Control.new()
	lbl_clip.position = Vector2(16, 12)
	lbl_clip.size = Vector2(288, 80)
	lbl_clip.clip_contents = true
	lbl_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_clip)
	var lbl := Label.new()
	lbl.text = "ตัวละครนี้ยังไม่ปลดล็อค ใช้เข้าต่อสู้ไม่ได้\nกรุณาเลือกตัวละครที่ปลดล็อคแล้ว"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	lbl.add_theme_font_size_override("font_size", 15)
	lbl_clip.add_child(lbl)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var btn := Button.new()
	btn.text = "ตกลง"
	btn.size = Vector2(120, 34)
	btn.position = Vector2((panel.size.x - 120) / 2.0, 96)
	panel.add_child(btn)
	btn.pressed.connect(func():
		ov.queue_free()
	)

func _show_deck_required_msg() -> void:
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.6)
	ov.anchor_right = 1.0; ov.anchor_bottom = 1.0
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.z_index = 100
	add_child(ov)

	var panel := Panel.new()
	panel.size = Vector2(320, 140)
	panel.position = (get_viewport_rect().size - panel.size) / 2.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.14, 0.97)
	sb.border_color = Color(1.0, 0.4, 0.4, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	ov.add_child(panel)

	var lbl_clip := Control.new()
	lbl_clip.position = Vector2(16, 12)
	lbl_clip.size = Vector2(288, 80)
	lbl_clip.clip_contents = true
	lbl_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_clip)
	var lbl := Label.new()
	var cur_total := _elem_deck_total() + _supp_deck_total()
	lbl.text = "กรุณาจัดเด็คให้ครบ %d ใบก่อนเข้าสู่การต่อสู้!\nตอนนี้มี %d / %d ใบ" % [DECK_REQUIRED, cur_total, DECK_REQUIRED]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	lbl.add_theme_font_size_override("font_size", 15)
	lbl_clip.add_child(lbl)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var btn := Button.new()
	btn.text = "ตกลง"
	btn.size = Vector2(120, 34)
	btn.position = Vector2((panel.size.x - 120) / 2.0, 96)
	panel.add_child(btn)
	btn.pressed.connect(func():
		ov.queue_free()
	)
