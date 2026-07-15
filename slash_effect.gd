extends Node2D
# ════════════════════════════════════════════════════════════
#  CHEMIA — Slash Effect (Void Strike / Basic Attack)
#  Clean, curved, glow-driven slash — Line2D + Curve2D + gradient,
#  GPUParticles2D only for trail dust / impact shards / accents.
#  No block/square particles, no camera object (this project's
#  battle scene is a Control tree, not Camera2D-based) — the
#  "camera punch" is approximated with a root scale/position kick.
#  Godot 4.7 (await, create_tween).
# ════════════════════════════════════════════════════════════

const COL_CYAN    := Color("#00EAFF")
const COL_VIOLET  := Color("#7F5AF0")
const COL_MAGENTA := Color("#FF3CAC")
const COL_WHITE   := Color("#FFFFFF")
const COL_NAVY    := Color("#091320")

# The fixed relative slash curve (left-up -> right-down), matching the game's
# fixed player-left / enemy-right layout. Anchored around (0,0) = the impact point.
const CURVE_POINTS := [
	Vector2(-150, -95),
	Vector2(-75,  -25),
	Vector2(0,     20),
	Vector2(70,    55),
	Vector2(130,   65),
]

var slash_line:    Line2D
var slash_trail:   GPUParticles2D
var impact_burst:  GPUParticles2D
var shock_ring:    Sprite2D
var slash_mark:    Sprite2D

## Optional: a Control whose position gets a tiny "camera punch" kick on impact
## (this scene has no real Camera2D — see note above).
var shake_root: Node = null

var _tex_streak_particle: ImageTexture
var _tex_shard: ImageTexture
var _tex_ring: ImageTexture
var _tex_mark: ImageTexture


func _ready() -> void:
	_tex_streak_particle = _make_streak_particle_tex()
	_tex_shard           = _make_shard_tex()
	_tex_ring             = _make_ring_tex()
	_tex_mark            = _make_mark_tex()

	_build_slash_line()
	_build_slash_trail()
	_build_impact_burst()
	_build_shock_ring()
	_build_slash_mark()
	visible = false


# ════════════════════════════════════════════════════════════
#  PUBLIC API
# ════════════════════════════════════════════════════════════
## impact_pos: where the slash lands (world/screen position in this Node2D's parent space).
func play(impact_pos: Vector2) -> void:
	visible = true
	_position_curve(impact_pos)

	slash_line.width = 0.0
	slash_line.modulate.a = 1.0

	var tw := create_tween()
	tw.tween_property(slash_line, "width", 10.0, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	slash_trail.restart()
	slash_trail.emitting = true

	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self): return

	# ── Impact ──
	impact_burst.position = impact_pos
	impact_burst.restart()
	impact_burst.emitting = true

	shock_ring.position = impact_pos
	shock_ring.visible = true
	shock_ring.scale = Vector2(0.1, 0.1)
	shock_ring.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.5)
	var rt := shock_ring.create_tween().set_parallel(true)
	rt.tween_property(shock_ring, "scale", Vector2(1.6, 1.6), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.tween_property(shock_ring, "modulate:a", 0.0, 0.15)

	_punch(impact_pos)

	var lt := slash_line.create_tween()
	lt.tween_property(slash_line, "width", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self): return
	_show_slash_mark(impact_pos)

	await get_tree().create_timer(0.15).timeout
	if not is_instance_valid(self): return
	slash_trail.emitting = false

	await get_tree().create_timer(0.2).timeout
	if not is_instance_valid(self): return
	visible = false


# ════════════════════════════════════════════════════════════
#  a) SlashLine — curved, gradient, glow
# ════════════════════════════════════════════════════════════
func _build_slash_line() -> void:
	slash_line = Line2D.new()
	slash_line.name = "SlashLine"
	slash_line.antialiased = true
	slash_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	slash_line.end_cap_mode   = Line2D.LINE_CAP_ROUND
	slash_line.joint_mode     = Line2D.LINE_JOINT_ROUND
	slash_line.width = 10.0
	slash_line.z_index = 30

	# Width curve: thin -> thick (middle) -> thin, so the blade reads as a swing not a bar
	var wc := Curve.new()
	wc.add_point(Vector2(0.0, 0.0))
	wc.add_point(Vector2(0.22, 0.85))
	wc.add_point(Vector2(0.5, 1.0))
	wc.add_point(Vector2(0.78, 0.85))
	wc.add_point(Vector2(1.0, 0.0))
	slash_line.width_curve = wc

	# Color gradient along the stroke: transparent -> cyan -> white (hot core) -> cyan -> transparent
	var grad := Gradient.new()
	grad.set_color(0, Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0))
	grad.add_point(0.18, Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.9))
	grad.add_point(0.5,  COL_WHITE)
	grad.add_point(0.82, Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.9))
	grad.add_point(1.0,  Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0))
	slash_line.gradient = grad

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	slash_line.material = mat

	add_child(slash_line)

## Rebuilds the Curve2D-based point list, anchored so `impact_pos` sits at the curve's tip.
func _position_curve(impact_pos: Vector2) -> void:
	var curve := Curve2D.new()
	for p in CURVE_POINTS:
		curve.add_point(p)
	var baked: PackedVector2Array = curve.get_baked_points()
	var pts := PackedVector2Array()
	# Anchor so the LAST point of the curve lands exactly on impact_pos
	var tip: Vector2 = baked[baked.size() - 1]
	var offset := impact_pos - tip
	for p in baked:
		pts.append(p + offset)
	slash_line.points = pts


# ════════════════════════════════════════════════════════════
#  b) SlashTrail — thin glowing streaks along the blade, not blocks
# ════════════════════════════════════════════════════════════
func _build_slash_trail() -> void:
	slash_trail = GPUParticles2D.new()
	slash_trail.name = "SlashTrail"
	slash_trail.amount = 30
	slash_trail.lifetime = 0.25
	slash_trail.one_shot = true
	slash_trail.explosiveness = 0.7
	slash_trail.texture = _tex_streak_particle
	slash_trail.z_index = 29
	slash_trail.local_coords = true

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	# Emit along the (unanchored) curve shape so the trail hugs the blade
	var curve := Curve2D.new()
	for p in CURVE_POINTS: curve.add_point(p)
	var baked := curve.get_baked_points()
	var pts := PackedVector3Array()
	for p in baked:
		pts.append(Vector3(p.x, p.y, 0.0))
	mat.emission_point_count = pts.size()
	mat.emission_points = pts
	mat.direction = Vector3(1, 0.15, 0)
	mat.spread = 18.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 90.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.5
	mat.scale_max = 1.1
	mat.angle_min = -20.0
	mat.angle_max = 20.0

	var ramp := GradientTexture1D.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([
		Color(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1.0),
		Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.8),
		Color(COL_MAGENTA.r, COL_MAGENTA.g, COL_MAGENTA.b, 0.0),
	])
	ramp.gradient = g
	mat.color_ramp = ramp

	slash_trail.process_material = mat
	var pmat := CanvasItemMaterial.new()
	pmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	slash_trail.material = pmat

	add_child(slash_trail)


# ════════════════════════════════════════════════════════════
#  c) ImpactBurst — energy shard particles, 360°, at the hit point
# ════════════════════════════════════════════════════════════
func _build_impact_burst() -> void:
	impact_burst = GPUParticles2D.new()
	impact_burst.name = "ImpactBurst"
	impact_burst.amount = 40
	impact_burst.lifetime = 0.4
	impact_burst.one_shot = true
	impact_burst.explosiveness = 0.95
	impact_burst.texture = _tex_shard
	impact_burst.z_index = 31
	impact_burst.local_coords = false

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 90.0
	mat.initial_velocity_max = 320.0
	mat.damping_min = 40.0
	mat.damping_max = 90.0
	mat.scale_min = 0.4
	mat.scale_max = 1.0
	mat.angle_min = 0.0
	mat.angle_max = 360.0

	var ramp := GradientTexture1D.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([
		Color(COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1.0),
		Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.9),
		Color(COL_MAGENTA.r, COL_MAGENTA.g, COL_MAGENTA.b, 0.0),
	])
	ramp.gradient = g
	mat.color_ramp = ramp

	impact_burst.process_material = mat
	var pmat := CanvasItemMaterial.new()
	pmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	impact_burst.material = pmat

	add_child(impact_burst)


# ════════════════════════════════════════════════════════════
#  d) ShockRing — expanding energy ring at impact
# ════════════════════════════════════════════════════════════
func _build_shock_ring() -> void:
	shock_ring = Sprite2D.new()
	shock_ring.name = "ShockRing"
	shock_ring.texture = _tex_ring
	shock_ring.visible = false
	shock_ring.z_index = 28
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	shock_ring.material = mat
	add_child(shock_ring)


# ════════════════════════════════════════════════════════════
#  e) SlashMark — lingering fang-shaped afterimage
# ════════════════════════════════════════════════════════════
func _build_slash_mark() -> void:
	slash_mark = Sprite2D.new()
	slash_mark.name = "SlashMark"
	slash_mark.texture = _tex_mark
	slash_mark.visible = false
	slash_mark.z_index = 27
	slash_mark.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.6)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	slash_mark.material = mat
	add_child(slash_mark)

func _show_slash_mark(pos: Vector2) -> void:
	slash_mark.position = pos
	slash_mark.visible = true
	slash_mark.scale = Vector2.ZERO
	slash_mark.modulate.a = 0.6
	var t := slash_mark.create_tween()
	t.tween_property(slash_mark, "scale", Vector2(1, 1), 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.3)
	t.tween_property(slash_mark, "modulate:a", 0.0, 0.2)
	t.tween_callback(func(): slash_mark.visible = false)


# ════════════════════════════════════════════════════════════
#  Screen punch (zoom-ish kick + light shake) — no Camera2D in this
#  Control-based battle scene, so we fake it with a scale/position
#  kick on shake_root instead of a real camera zoom.
# ════════════════════════════════════════════════════════════
func _punch(_impact_pos: Vector2) -> void:
	if not is_instance_valid(shake_root): return
	var root: Node = shake_root
	if root is Control:
		var c := root as Control
		var base_scale := Vector2(1, 1)
		var base_pos := Vector2.ZERO
		var t := c.create_tween()
		t.tween_property(c, "scale", Vector2(1.02, 1.02), 0.03)
		t.tween_property(c, "scale", base_scale, 0.1)
		# light shake, decaying to 0 over 0.08s
		var st := c.create_tween()
		var steps := 3
		for i in steps:
			var damp := 1.0 - float(i) / float(steps)
			st.tween_property(c, "position",
				base_pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)) * damp, 0.025)
		st.tween_property(c, "position", base_pos, 0.02)


# ════════════════════════════════════════════════════════════
#  Screen flash helper — call with the same ColorRect used elsewhere
#  (battle_effects.gd's screen_flash), white->cyan tinted, very brief.
# ════════════════════════════════════════════════════════════
func flash_screen(rect: ColorRect) -> void:
	if not is_instance_valid(rect): return
	rect.color = Color(COL_WHITE.r * 0.5 + COL_CYAN.r * 0.5, COL_WHITE.g * 0.5 + COL_CYAN.g * 0.5, 1.0, 0.0)
	var t := rect.create_tween()
	t.tween_property(rect, "color:a", 0.12, 0.04)
	t.tween_property(rect, "color:a", 0.0, 0.06)


# ════════════════════════════════════════════════════════════
#  Procedural textures — no external art needed
# ════════════════════════════════════════════════════════════

## Small elongated soft-edged capsule (NOT a square/circle blob) for the trail particles.
func _make_streak_particle_tex() -> ImageTexture:
	var w := 24; var h := 6
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cy := h * 0.5
	for y in h:
		for x in w:
			var fx := float(x) / float(w - 1)
			var taper := sin(fx * PI)                       # 0 at both ends, 1 in the middle
			var fy := 1.0 - absf(y - cy) / (h * 0.5)
			var a := clampf(taper * fy, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

## Small angular "shard" glint (a thin diamond), reads as an energy fragment, not a dot/box.
func _make_shard_tex() -> ImageTexture:
	var size := 14
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size * 0.5, size * 0.5)
	for y in size:
		for x in size:
			var dx := absf(x - c.x) / (size * 0.5)
			var dy := absf(y - c.y) / (size * 0.18)   # thin along one axis -> diamond sliver
			var d := dx + dy
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 1.6)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

## Soft-edged ring for the shockwave.
func _make_ring_tex() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size * 0.5, size * 0.5)
	var outer := size * 0.5 - 3.0
	var inner := outer * 0.72
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(c)
			var a := 0.0
			if d >= inner and d <= outer:
				a = 1.0
			elif d < inner and d > inner - 4.0:
				a = 1.0 - (inner - d) / 4.0
			elif d > outer and d < outer + 4.0:
				a = 1.0 - (d - outer) / 4.0
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

## Curved "fang" slash-mark afterimage — two crossed crescent strokes.
func _make_mark_tex() -> ImageTexture:
	var size := 96
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var c := Vector2(size * 0.5, size * 0.5)
	var r := size * 0.36
	# Draw a crescent by sampling an arc and stamping soft dots along it
	var steps := 140
	for i in steps:
		var t := float(i) / float(steps - 1)
		var ang := lerp(-0.75, 0.75, t)   # ~86 degree arc
		var p := c + Vector2(cos(ang), sin(ang)) * r
		var fade := sin(t * PI)           # taper both ends
		_stamp_soft_dot(img, p, 5.0, fade)
	return ImageTexture.create_from_image(img)

func _stamp_soft_dot(img: Image, center: Vector2, radius: float, alpha_mul: float) -> void:
	var minx := maxi(0, int(center.x - radius))
	var maxx := mini(img.get_width() - 1, int(center.x + radius))
	var miny := maxi(0, int(center.y - radius))
	var maxy := mini(img.get_height() - 1, int(center.y + radius))
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			var d := Vector2(x, y).distance_to(center) / radius
			if d > 1.0: continue
			var a := (1.0 - d) * alpha_mul
			var existing := img.get_pixel(x, y)
			var new_a := clampf(maxf(existing.a, a), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, new_a))
