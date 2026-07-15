extends Node2D
# ════════════════════════════════════════════════════════════
#  CHEMIA — Battle Effects
#  Combat VFX layer: slashes, shields, heals, ultimate, hits,
#  floating damage numbers, screen flash / shake.
#  Godot 4.7 (await, create_tween). Self-contained — all textures
#  are generated procedurally, no external art required.
#
#  (Element-card reaction VFX live in element_card_system.gd and
#   the Stage-Clear/Victory screens in stage_clear_screen.gd.)
# ════════════════════════════════════════════════════════════

# ── CHEMIA palette ─────────────────────────────────────────
const COL_CYAN    := Color("#00EAFF")
const COL_VIOLET  := Color("#7F5AF0")
const COL_MAGENTA := Color("#FF3CAC")
const COL_BLUE    := Color("#2B4FFF")
const COL_BLACK   := Color("#06061A")
const COL_HEAL    := Color("#00FF88")

const SCREEN_W := 1152.0
const SCREEN_H := 648.0

# ── Anchor points (battle_scene screen-space) ──────────────
@export var player_pos: Vector2 = Vector2(160, 440)
@export var enemy_pos:  Vector2 = Vector2(560, 200)

# External node refs (set by battle_scene) used for modulate flashes / shake
var player_node: CanvasItem = null
var enemy_node:  CanvasItem = null
var shake_root:  Node       = null   # a Control whose position is nudged for screen shake

# ── Persistent nodes ───────────────────────────────────────
var shield_orb:      Node2D
var void_shield_orb: Node2D
var hit_flash:       ColorRect
var screen_flash:    ColorRect
var floating_root:   Node2D

# ── Cached procedural textures ─────────────────────────────
var _tex_dot:    ImageTexture
var _tex_streak: ImageTexture
var _tex_ring:   ImageTexture

var _shield_pulse_tween: Tween


func _ready() -> void:
	_tex_dot    = _make_dot_texture()
	_tex_streak = _make_streak_texture()
	_tex_ring   = _make_ring_texture(300)

	_build_shield_orb()
	_build_void_shield_orb()
	_build_hit_flash()
	_build_screen_flash()

	floating_root = Node2D.new()
	floating_root.name = "FloatingNumbers"
	add_child(floating_root)


# ════════════════════════════════════════════════════════════
#  1. VOID STRIKE
# ════════════════════════════════════════════════════════════
func play_void_strike() -> void:
	var start := player_pos + Vector2(90, -30)
	# Elongated cyan particles shooting toward the enemy (right)
	var slash := _spawn_particles(start, COL_CYAN, {
		"amount": 18, "lifetime": 0.3, "one_shot": true,
		"dir": Vector3(1, -0.1, 0), "spread": 12.0,
		"vmin": 700.0, "vmax": 1100.0,
		"scale_min": 1.2, "scale_max": 2.2, "texture": _tex_streak,
	})
	slash.z_index = 12

	# Persistent slash mark (Line2D) that lingers then fades
	var line := Line2D.new()
	line.width = 5.0
	line.default_color = COL_CYAN
	line.add_point(player_pos + Vector2(70, 20))
	line.add_point(enemy_pos + Vector2(-10, 10))
	line.z_index = 13
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line)
	var lt := line.create_tween()
	lt.tween_interval(0.2)
	lt.tween_property(line, "modulate:a", 0.0, 0.35)
	lt.tween_callback(line.queue_free)

	await get_tree().create_timer(0.18).timeout
	# Impact burst on the enemy (magenta)
	_spawn_particles(enemy_pos, COL_MAGENTA, {
		"amount": 26, "lifetime": 0.5, "one_shot": true, "explosive": true,
		"spread": 180.0, "vmin": 60.0, "vmax": 220.0,
		"scale_min": 0.6, "scale_max": 1.4, "texture": _tex_dot,
	})
	_flash_node(enemy_node)
	_cleanup(slash, 0.6)


# ════════════════════════════════════════════════════════════
#  2. NULL BARRIER  (persistent shield orb while guarding)
# ════════════════════════════════════════════════════════════
func _build_shield_orb() -> void:
	shield_orb = _make_orb(COL_CYAN, 0.40)
	shield_orb.visible = false
	add_child(shield_orb)

func show_shield(active: bool) -> void:
	if not is_instance_valid(shield_orb): return
	shield_orb.position = player_pos
	if active:
		shield_orb.visible = true
		shield_orb.scale = Vector2(0.4, 0.4)
		shield_orb.modulate.a = 0.0
		var t := shield_orb.create_tween()
		t.tween_property(shield_orb, "modulate:a", 1.0, 0.2)
		t.parallel().tween_property(shield_orb, "scale", Vector2(1.0, 1.0), 0.25)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_start_shield_pulse()
		# small cyan particles orbiting the shield edge
		_spawn_particles(player_pos, COL_CYAN, {
			"amount": 20, "lifetime": 1.0, "one_shot": false,
			"ring": 78.0, "vmin": 4.0, "vmax": 14.0,
			"scale_min": 0.4, "scale_max": 0.8, "texture": _tex_dot,
			"attach_to": shield_orb,
		})
	else:
		break_shield()

func _start_shield_pulse() -> void:
	if is_instance_valid(_shield_pulse_tween): _shield_pulse_tween.kill()
	_shield_pulse_tween = shield_orb.create_tween().set_loops()
	_shield_pulse_tween.tween_property(shield_orb, "scale", Vector2(1.1, 1.1), 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shield_pulse_tween.tween_property(shield_orb, "scale", Vector2(1.0, 1.0), 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func flash_shield() -> void:
	if not is_instance_valid(shield_orb) or not shield_orb.visible: return
	var t := shield_orb.create_tween()
	t.tween_property(shield_orb, "modulate", Color(2.2, 2.2, 2.4, 1.0), 0.1)
	t.tween_property(shield_orb, "modulate", Color(1, 1, 1, 1.0), 0.3)

func break_shield() -> void:
	if not is_instance_valid(shield_orb) or not shield_orb.visible: return
	if is_instance_valid(_shield_pulse_tween): _shield_pulse_tween.kill()
	_spawn_particles(player_pos, COL_CYAN, {
		"amount": 24, "lifetime": 0.5, "one_shot": true, "explosive": true,
		"spread": 180.0, "vmin": 80.0, "vmax": 240.0,
		"scale_min": 0.5, "scale_max": 1.2, "texture": _tex_dot,
	})
	var t := shield_orb.create_tween()
	t.tween_property(shield_orb, "modulate:a", 0.0, 0.25)
	t.tween_callback(func(): shield_orb.visible = false)


# ════════════════════════════════════════════════════════════
#  3. AETHER PULSE  (heal + void shield)
# ════════════════════════════════════════════════════════════
func play_aether_pulse() -> void:
	# Rising violet particles around Lyra
	var heal := _spawn_particles(player_pos + Vector2(0, 40), COL_VIOLET, {
		"amount": 30, "lifetime": 1.0, "one_shot": true, "explosive": true,
		"dir": Vector3(0, -1, 0), "spread": 40.0, "gravity": Vector3(0, -60, 0),
		"vmin": 40.0, "vmax": 110.0, "ring": 60.0,
		"scale_min": 0.6, "scale_max": 1.3, "texture": _tex_dot,
	})
	# Violet glow over the sprite
	var glow := ColorRect.new()
	glow.color = Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0)
	glow.size = Vector2(200, 260)
	glow.position = player_pos - Vector2(100, 150)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var t := glow.create_tween()
	t.tween_property(glow, "color:a", 0.20, 0.3)
	t.tween_interval(0.5)
	t.tween_property(glow, "color:a", 0.0, 0.3)
	t.tween_callback(glow.queue_free)
	_cleanup(heal, 1.2)

func show_void_shield(active: bool) -> void:
	if not is_instance_valid(void_shield_orb): return
	void_shield_orb.position = player_pos + Vector2(30, 0)
	if active:
		void_shield_orb.visible = true
		void_shield_orb.modulate.a = 0.0
		void_shield_orb.scale = Vector2(0.3, 0.3)
		var t := void_shield_orb.create_tween()
		t.tween_property(void_shield_orb, "modulate:a", 1.0, 0.2)
		t.parallel().tween_property(void_shield_orb, "scale", Vector2(0.7, 0.7), 0.25)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var t := void_shield_orb.create_tween()
		t.tween_property(void_shield_orb, "modulate:a", 0.0, 0.2)
		t.tween_callback(func(): void_shield_orb.visible = false)

func _build_void_shield_orb() -> void:
	void_shield_orb = _make_orb(COL_VIOLET, 0.45)
	void_shield_orb.scale = Vector2(0.7, 0.7)
	void_shield_orb.visible = false
	add_child(void_shield_orb)


# ════════════════════════════════════════════════════════════
#  4. ABSOLUTE ZERO FORMULA  (ultimate)
# ════════════════════════════════════════════════════════════
func play_ultimate() -> void:
	# a) Rotating alchemy formula circle (cyan+violet), 300x300
	var circle := Sprite2D.new()
	circle.texture = _tex_ring
	circle.position = enemy_pos
	circle.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0)
	circle.z_index = 14
	add_child(circle)
	var spin := circle.create_tween()
	spin.tween_property(circle, "rotation", TAU, 1.0)
	var cfade := circle.create_tween()
	cfade.tween_property(circle, "modulate:a", 0.9, 0.2)
	cfade.tween_interval(0.5)
	cfade.tween_property(circle, "modulate:a", 0.0, 0.3)
	cfade.tween_callback(circle.queue_free)

	# c) Full-screen white flash
	screen_flash.color = Color(1, 1, 1, 0.0)
	var sf := screen_flash.create_tween()
	sf.tween_property(screen_flash, "color:a", 0.8, 0.12)
	sf.tween_property(screen_flash, "color:a", 0.0, 0.3)

	# d) Screen shake
	shake(0.5, 15.0)

	await get_tree().create_timer(0.12).timeout
	# b) Explosion burst (cyan + magenta + white)
	for col in [COL_CYAN, COL_MAGENTA, Color(1, 1, 1, 1)]:
		_spawn_particles(enemy_pos, col, {
			"amount": 70, "lifetime": 0.8, "one_shot": true, "explosive": true,
			"spread": 180.0, "vmin": 120.0, "vmax": 460.0,
			"scale_min": 0.6, "scale_max": 1.8, "texture": _tex_dot,
		})
	# e) Lingering violet aftermath
	var aftermath := _spawn_particles(enemy_pos, COL_VIOLET, {
		"amount": 40, "lifetime": 2.0, "one_shot": true, "explosive": false,
		"spread": 180.0, "vmin": 10.0, "vmax": 60.0, "gravity": Vector3(0, -20, 0),
		"scale_min": 0.5, "scale_max": 1.2, "texture": _tex_dot,
	})
	aftermath.modulate.a = 0.6
	_cleanup(aftermath, 2.4)


# ════════════════════════════════════════════════════════════
#  5. PLAYER HIT
# ════════════════════════════════════════════════════════════
func play_player_hit() -> void:
	shake(0.2, 8.0)
	_screen_color_flash(hit_flash, Color(1, 0, 0, 0.3), 0.15)
	_flash_node(player_node)


# ════════════════════════════════════════════════════════════
#  6. ENEMY HIT
# ════════════════════════════════════════════════════════════
func play_enemy_hit() -> void:
	_flash_node(enemy_node)
	_shake_node(enemy_node, 10.0, 0.15)
	_spawn_particles(enemy_pos, COL_VIOLET, {
		"amount": 20, "lifetime": 0.5, "one_shot": true, "explosive": true,
		"spread": 180.0, "vmin": 60.0, "vmax": 200.0,
		"scale_min": 0.5, "scale_max": 1.1, "texture": _tex_dot,
	})


# ════════════════════════════════════════════════════════════
#  7. ENEMY ATTACK
# ════════════════════════════════════════════════════════════
func play_enemy_attack() -> void:
	if is_instance_valid(enemy_node) and (enemy_node is Node2D or enemy_node is Control):
		var orig: Vector2 = enemy_node.position
		var t := enemy_node.create_tween()
		t.tween_property(enemy_node, "position", orig + Vector2(-80, 0), 0.15).set_trans(Tween.TRANS_BACK)
		t.tween_property(enemy_node, "position", orig, 0.2)
	_spawn_particles(player_pos, COL_MAGENTA, {
		"amount": 22, "lifetime": 0.5, "one_shot": true, "explosive": true,
		"spread": 180.0, "vmin": 60.0, "vmax": 210.0,
		"scale_min": 0.5, "scale_max": 1.2, "texture": _tex_dot,
	})


# ════════════════════════════════════════════════════════════
#  9. FLOATING DAMAGE / HEAL / SHIELD NUMBER
# ════════════════════════════════════════════════════════════
## kind: "damage" (red) | "heal" (green) | "shield" (white)
func spawn_number(pos: Vector2, amount: int, kind: String = "damage") -> void:
	var col := Color(1.0, 0.35, 0.35)
	var prefix := "-"
	match kind:
		"heal":   col = COL_HEAL;              prefix = "+"
		"shield": col = Color(0.92, 0.96, 1.0); prefix = "+"
		_:        col = Color(1.0, 0.35, 0.35); prefix = "-"

	var lbl := Label.new()
	lbl.text = "%s%d" % [prefix, absi(amount)]
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = pos - Vector2(40, 10) + Vector2(randf_range(-14, 14), 0)
	lbl.size = Vector2(80, 40)
	lbl.z_index = 40
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_root.add_child(lbl)

	var t := lbl.create_tween().set_parallel(true)
	t.tween_property(lbl, "position:y", lbl.position.y - 60.0, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.2)
	t.chain().tween_callback(lbl.queue_free)


# ════════════════════════════════════════════════════════════
#  SHARED HELPERS
# ════════════════════════════════════════════════════════════
func shake(duration: float, intensity: float) -> void:
	if not is_instance_valid(shake_root) or not (shake_root is Control): return
	var root := shake_root as Control
	var base := Vector2.ZERO
	var steps := int(duration / 0.03)
	var t := root.create_tween()
	for i in steps:
		var damp := 1.0 - float(i) / float(maxi(steps, 1))
		t.tween_property(root, "position",
			base + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)) * damp, 0.03)
	t.tween_property(root, "position", base, 0.03)

func _shake_node(node: CanvasItem, intensity: float, duration: float) -> void:
	if not is_instance_valid(node) or not (node is Node2D or node is Control): return
	var base: Vector2 = node.position
	var steps := int(duration / 0.03)
	var t := node.create_tween()
	for i in steps:
		t.tween_property(node, "position", base + Vector2(randf_range(-intensity, intensity), 0), 0.03)
	t.tween_property(node, "position", base, 0.03)

func _flash_node(node: CanvasItem) -> void:
	if not is_instance_valid(node): return
	var t := node.create_tween()
	t.tween_property(node, "modulate", Color(2, 2, 2, node.modulate.a), 0.1)
	t.tween_property(node, "modulate", Color(1, 1, 1, node.modulate.a), 0.1)

func _screen_color_flash(rect: ColorRect, peak: Color, dur: float) -> void:
	rect.color = Color(peak.r, peak.g, peak.b, 0.0)
	var t := rect.create_tween()
	t.tween_property(rect, "color:a", peak.a, dur)
	t.tween_property(rect, "color:a", 0.0, dur)

func _build_hit_flash() -> void:
	hit_flash = ColorRect.new()
	hit_flash.color = Color(1, 0, 0, 0.0)
	hit_flash.size = Vector2(SCREEN_W, SCREEN_H)
	hit_flash.z_index = 45
	hit_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hit_flash)

func _build_screen_flash() -> void:
	screen_flash = ColorRect.new()
	screen_flash.color = Color(1, 1, 1, 0.0)
	screen_flash.size = Vector2(SCREEN_W, SCREEN_H)
	screen_flash.z_index = 46
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_flash)

func _cleanup(node: Node, delay: float) -> void:
	if not is_instance_valid(node): return
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_callback(func():
		if is_instance_valid(node): node.queue_free())

## Semi-transparent glowing orb (Sprite2D with a soft radial texture).
func _make_orb(color: Color, alpha: float) -> Node2D:
	var orb := Node2D.new()
	var spr := Sprite2D.new()
	spr.texture = _make_orb_texture(color)
	spr.modulate = Color(1, 1, 1, alpha)
	orb.add_child(spr)
	return orb


# ── Particle factory ───────────────────────────────────────
## opts keys: amount, lifetime, one_shot, explosive, dir(Vector3), spread,
## vmin, vmax, gravity(Vector3), ring(float), scale_min, scale_max, texture, attach_to
func _spawn_particles(pos: Vector2, color: Color, opts: Dictionary) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.position = pos
	p.amount = int(opts.get("amount", 20))
	p.lifetime = float(opts.get("lifetime", 0.5))
	p.one_shot = bool(opts.get("one_shot", true))
	p.explosiveness = 0.9 if bool(opts.get("explosive", true)) else 0.0
	p.texture = opts.get("texture", _tex_dot)
	p.z_index = 11
	p.local_coords = false

	var mat := ParticleProcessMaterial.new()
	var ring: float = float(opts.get("ring", 0.0))
	if ring > 0.0:
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		mat.emission_ring_radius = ring
		mat.emission_ring_inner_radius = ring - 6.0
		mat.emission_ring_height = 1.0
		mat.emission_ring_axis = Vector3(0, 0, 1)
	else:
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	var dir: Vector3 = opts.get("dir", Vector3(0, 0, 0))
	mat.direction = dir
	mat.spread = float(opts.get("spread", 180.0))
	mat.gravity = opts.get("gravity", Vector3(0, 0, 0))
	mat.initial_velocity_min = float(opts.get("vmin", 40.0))
	mat.initial_velocity_max = float(opts.get("vmax", 160.0))
	mat.scale_min = float(opts.get("scale_min", 0.5))
	mat.scale_max = float(opts.get("scale_max", 1.2))
	mat.color = color

	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.r, color.g, color.b, 0.0))
	ramp.add_point(0.15, Color(color.r, color.g, color.b, 1.0))
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	mat.color_ramp = ramp_tex

	p.process_material = mat
	var parent: Node = opts.get("attach_to", self)
	if not is_instance_valid(parent): parent = self
	if parent != self:
		p.position = Vector2.ZERO
	parent.add_child(p)
	p.restart()
	p.emitting = true
	return p


# ── Procedural textures ────────────────────────────────────
func _make_dot_texture() -> ImageTexture:
	var size := 12
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size * 0.5, size * 0.5)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(c) / (size * 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)

func _make_streak_texture() -> ImageTexture:
	var w := 40; var h := 8
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cy := h * 0.5
	for y in h:
		for x in w:
			var fx := float(x) / float(w)             # 0..1 along length
			var fy := 1.0 - absf(y - cy) / (h * 0.5)  # taper across width
			var a := fy * (1.0 - absf(fx - 0.5) * 1.6)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)

func _make_ring_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var outer := size * 0.5 - 6.0
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center)
			var a := 0.0
			# two concentric rings (cyan outer, violet inner) forming an "alchemy circle"
			a = maxf(a, _ring_band(d, outer * 0.88, outer))
			a = maxf(a, _ring_band(d, outer * 0.60, outer * 0.66) * 0.7)
			var col := COL_CYAN if d > outer * 0.74 else COL_VIOLET
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)

func _ring_band(d: float, inner: float, outer: float) -> float:
	if d < inner - 3.0 or d > outer + 3.0: return 0.0
	if d >= inner and d <= outer: return 1.0
	if d < inner: return 1.0 - (inner - d) / 3.0
	return 1.0 - (d - outer) / 3.0

func _make_orb_texture(color: Color) -> ImageTexture:
	var size := 180
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var r := size * 0.5 - 2.0
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center)
			var a := 0.0
			if d <= r:
				# faint fill + bright rim
				var fill := (1.0 - d / r) * 0.25
				var rim := _ring_band(d, r - 5.0, r)
				a = maxf(fill, rim)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	return ImageTexture.create_from_image(img)
