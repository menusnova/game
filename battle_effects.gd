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
const BarrierRingsScript := preload("res://barrier_rings.gd")
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
var void_shield_orb: Node2D
var hit_flash:       ColorRect
var screen_flash:    ColorRect
var floating_root:   Node2D

# ── Cached procedural textures ─────────────────────────────
var _tex_dot:    ImageTexture
var _tex_streak: ImageTexture
var _tex_ring:   ImageTexture
var _tex_vignette: ImageTexture

# Background layer: soft cutscene vignette/dim (kept below 30% opacity so
# the battlefield never goes fully dark and characters stay readable).
var _backdrop: TextureRect = null

var _shield_pulse_tween: Tween

# ── Guard / Null Barrier shield visuals ────────────────────
var shield_root:       Node2D    # container: feet ring + hex shield + ambient particles
var shield_feet_ring:  Sprite2D
var shield_hex:        Sprite2D
var shield_hex_lines:  Sprite2D
var _barrier: Node2D = null      # two elliptical HUD rings (the visible barrier)
var shield_ambient:    GPUParticles2D
var shield_sparkle:    GPUParticles2D
var _shield_active         := false
var _shield_lines_tween:    Tween
var _shield_energy_tween:   Tween
var _tex_hex:        ImageTexture
var _tex_hex_lines:  ImageTexture
var _tex_ring_thin:  ImageTexture
var _tex_shard:      ImageTexture

# Small object pools — reused across "shield hit" ripples/sparks and the
# periodic idle energy pulse, instead of allocating new nodes every time.
const RIPPLE_POOL_SIZE := 3
const SPARK_POOL_SIZE  := 2
const SHARD_POOL_SIZE  := 10
var _ripple_pool: Array[Sprite2D]       = []
var _ripple_pool_idx := 0
var _spark_pool:  Array[GPUParticles2D] = []
var _spark_pool_idx  := 0
var _shard_pool:  Array[Sprite2D]       = []


func _ready() -> void:
	_tex_dot       = _make_dot_texture()
	_tex_streak    = _make_streak_texture()
	_tex_ring      = _make_ring_texture(300)
	_tex_hex       = _make_hex_texture(180, COL_CYAN)
	_tex_hex_lines = _make_hex_lines_texture(180, COL_CYAN)
	_tex_ring_thin = _make_thin_ring_texture(140)
	_tex_shard     = _make_shard_texture()
	_tex_vignette  = _make_vignette_texture(256)

	_build_backdrop()
	_build_guard_shield()
	_build_shield_pools()
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

	# The impact itself is handled by play_enemy_hit() (called on every
	# Attack), so this fallback slash just cleans up its own streak.
	_cleanup(slash, 0.6)


# ════════════════════════════════════════════════════════════
#  2. NULL BARRIER  (hexagon guard shield while defending)
#     API kept identical (show_shield/flash_shield/break_shield) —
#     only the visuals underneath changed.
# ════════════════════════════════════════════════════════════
func _build_guard_shield() -> void:
	shield_root = Node2D.new()
	shield_root.z_index = 9
	shield_root.visible = false
	add_child(shield_root)

	# The visible barrier is now the two elliptical HUD rings; the old hex
	# sprites stay in the tree (hit/break reactions reference them) but are
	# kept invisible.
	_barrier = BarrierRingsScript.new()
	_barrier.visible = false
	shield_root.add_child(_barrier)

	shield_feet_ring = Sprite2D.new()
	shield_feet_ring.texture  = _tex_ring_thin
	shield_feet_ring.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0)
	shield_feet_ring.position = Vector2(0, 62)
	shield_feet_ring.scale    = Vector2(0.15, 0.06)   # squashed flat, sits underfoot
	shield_root.add_child(shield_feet_ring)

	shield_hex = Sprite2D.new()
	shield_hex.texture  = _tex_hex
	shield_hex.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0)
	shield_hex.scale    = Vector2(0.2, 0.2)
	shield_root.add_child(shield_hex)

	shield_hex_lines = Sprite2D.new()
	shield_hex_lines.texture  = _tex_hex_lines
	shield_hex_lines.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0)
	shield_hex_lines.scale    = Vector2(0.2, 0.2)
	var lmat := CanvasItemMaterial.new()
	lmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	shield_hex_lines.material = lmat
	shield_root.add_child(shield_hex_lines)

	shield_ambient = GPUParticles2D.new()
	shield_ambient.amount        = 16
	shield_ambient.lifetime      = 1.4
	shield_ambient.one_shot      = false
	shield_ambient.explosiveness = 0.0
	shield_ambient.texture       = _tex_dot
	shield_ambient.emitting      = false
	var amat := ParticleProcessMaterial.new()
	amat.emission_shape             = ParticleProcessMaterial.EMISSION_SHAPE_RING
	amat.emission_ring_radius       = 62.0
	amat.emission_ring_inner_radius = 56.0
	amat.emission_ring_height       = 1.0
	amat.emission_ring_axis         = Vector3(0, 0, 1)
	amat.direction            = Vector3(0, -1, 0)
	amat.spread                = 20.0
	amat.gravity                = Vector3(0, -8, 0)
	amat.initial_velocity_min = 4.0
	amat.initial_velocity_max = 12.0
	amat.scale_min = 0.35
	amat.scale_max = 0.7
	amat.color      = COL_CYAN
	amat.color_ramp = _make_ramp(COL_CYAN)
	shield_ambient.process_material = amat
	shield_root.add_child(shield_ambient)

	# Faint light motes drifting upward off the shield surface
	shield_sparkle = GPUParticles2D.new()
	shield_sparkle.amount        = 10
	shield_sparkle.lifetime      = 1.6
	shield_sparkle.one_shot      = false
	shield_sparkle.explosiveness = 0.0
	shield_sparkle.texture       = _tex_dot
	shield_sparkle.emitting      = false
	var smat := ParticleProcessMaterial.new()
	smat.emission_shape        = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smat.emission_sphere_radius = 46.0
	smat.direction             = Vector3(0, -1, 0)
	smat.spread                 = 10.0
	smat.gravity                = Vector3(0, -30, 0)
	smat.initial_velocity_min  = 6.0
	smat.initial_velocity_max  = 16.0
	smat.scale_min = 0.2
	smat.scale_max = 0.45
	smat.color      = Color(0.85, 1.0, 1.0)
	smat.color_ramp = _make_ramp(Color(0.85, 1.0, 1.0))
	shield_sparkle.process_material = smat
	shield_root.add_child(shield_sparkle)

func _build_shield_pools() -> void:
	for i in RIPPLE_POOL_SIZE:
		var r := Sprite2D.new()
		r.texture  = _tex_ring_thin
		r.modulate = Color(1, 1, 1, 0.0)
		r.visible  = false
		r.z_index  = 10
		add_child(r)
		_ripple_pool.append(r)
	for i in SPARK_POOL_SIZE:
		var sp := GPUParticles2D.new()
		sp.amount        = 18
		sp.lifetime      = 0.4
		sp.one_shot      = true
		sp.explosiveness = 0.95
		sp.texture       = _tex_dot
		sp.emitting      = false
		sp.z_index       = 12
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		pm.spread         = 180.0
		pm.initial_velocity_min = 70.0
		pm.initial_velocity_max = 220.0
		pm.scale_min = 0.4
		pm.scale_max = 1.0
		pm.color      = COL_CYAN
		pm.color_ramp = _make_ramp(Color(1, 1, 1))
		sp.process_material = pm
		add_child(sp)
		_spark_pool.append(sp)
	for i in SHARD_POOL_SIZE:
		var sh := Sprite2D.new()
		sh.texture  = _tex_shard
		sh.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0)
		sh.visible  = false
		sh.z_index  = 13
		add_child(sh)
		_shard_pool.append(sh)

func _next_ripple() -> Sprite2D:
	var r := _ripple_pool[_ripple_pool_idx]
	_ripple_pool_idx = (_ripple_pool_idx + 1) % _ripple_pool.size()
	return r

func _next_spark() -> GPUParticles2D:
	var s := _spark_pool[_spark_pool_idx]
	_spark_pool_idx = (_spark_pool_idx + 1) % _spark_pool.size()
	return s

## active=true: form the guard shield (feet ring -> hexagon -> idle glow).
## active=false: dismiss it with a soft fade (used outside of a "took a hit"
## context, e.g. resetting state on a stage transition).
func show_shield(active: bool) -> void:
	if not is_instance_valid(shield_root): return
	shield_root.position = player_pos
	if active:
		_shield_active = true
		shield_root.visible = true
		_play_guard_formation()
	else:
		_shield_active = false
		_play_guard_dismiss()

func _play_guard_formation() -> void:
	# The two elliptical HUD rings fade/spin in as the barrier itself.
	if is_instance_valid(_barrier):
		_barrier.call("activate")

	# Formation beat: a soft outward wave + a few light fragments settling.
	energy_wave(player_pos, COL_CYAN, 1.15)
	_spawn_particles(player_pos, COL_CYAN, {
		"amount": 10, "lifetime": 0.5, "one_shot": true, "explosive": true,
		"ring": 60.0, "spread": 180.0, "vmin": 40.0, "vmax": 90.0,
		"scale_min": 0.4, "scale_max": 0.9, "texture": _tex_shard,
	})

	shield_ambient.restart();  shield_ambient.emitting  = true
	shield_sparkle.restart();  shield_sparkle.emitting  = true
	_start_shield_idle()

func _start_shield_idle() -> void:
	if is_instance_valid(_shield_pulse_tween): _shield_pulse_tween.kill()
	_shield_pulse_tween = shield_hex.create_tween().set_loops()
	_shield_pulse_tween.tween_property(shield_hex, "modulate:a", 0.68, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shield_pulse_tween.tween_property(shield_hex, "modulate:a", 0.95, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Flowing energy across the shield surface — a gentle sway + breath
	# rather than a constant full rotation (keeps it elegant, not spinning).
	if is_instance_valid(_shield_lines_tween): _shield_lines_tween.kill()
	shield_hex_lines.rotation = -0.1
	_shield_lines_tween = shield_hex_lines.create_tween().set_loops()
	_shield_lines_tween.tween_property(shield_hex_lines, "rotation", 0.1, 2.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shield_lines_tween.tween_property(shield_hex_lines, "rotation", -0.1, 2.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Energy pulse ring every 0.8s
	if is_instance_valid(_shield_energy_tween): _shield_energy_tween.kill()
	_shield_energy_tween = shield_hex.create_tween().set_loops()
	_shield_energy_tween.tween_interval(0.8)
	_shield_energy_tween.tween_callback(_spawn_energy_pulse)

func _spawn_energy_pulse() -> void:
	if not _shield_active: return
	var r := _next_ripple()
	r.global_position = player_pos
	r.rotation = 0.0
	r.scale    = Vector2(0.45, 0.45)
	r.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.45)
	r.visible  = true
	var t := r.create_tween().set_parallel(true)
	t.tween_property(r, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(r, "modulate:a", 0.0, 0.5)
	t.chain().tween_callback(func():
		if is_instance_valid(r): r.visible = false
	)

func _stop_shield_idle() -> void:
	if is_instance_valid(_shield_pulse_tween):  _shield_pulse_tween.kill()
	if is_instance_valid(_shield_lines_tween):  _shield_lines_tween.kill()
	if is_instance_valid(_shield_energy_tween): _shield_energy_tween.kill()

func _play_guard_dismiss() -> void:
	_stop_shield_idle()
	if not is_instance_valid(shield_root): return
	shield_ambient.emitting = false
	shield_sparkle.emitting = false
	if is_instance_valid(_barrier):
		_barrier.call("dismiss")
	var t := shield_root.create_tween()
	t.tween_interval(0.28)
	t.tween_callback(func():
		if is_instance_valid(shield_root): shield_root.visible = false)

## Shield takes a hit: ripple wave from the shield, sparks, small shock ring,
## soft white hit flash, and a light camera shake.
func flash_shield() -> void:
	if not is_instance_valid(shield_root) or not shield_root.visible: return

	var ripple := _next_ripple()
	ripple.global_position = player_pos
	ripple.rotation = 0.0
	ripple.scale    = Vector2(0.3, 0.3)
	ripple.modulate = Color(1.0, 1.0, 1.0, 0.9)
	ripple.visible  = true
	var rt := ripple.create_tween().set_parallel(true)
	rt.tween_property(ripple, "scale", Vector2(1.5, 1.5), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rt.tween_property(ripple, "modulate:a", 0.0, 0.35)
	rt.chain().tween_callback(func():
		if is_instance_valid(ripple): ripple.visible = false
	)

	# Small shock ring (slightly delayed, snappier than the ripple)
	var shock := _next_ripple()
	shock.global_position = player_pos
	shock.rotation = 0.0
	shock.scale    = Vector2(0.18, 0.18)
	shock.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 1.0)
	shock.visible  = true
	var st := shock.create_tween().set_parallel(true)
	st.tween_property(shock, "scale", Vector2(0.7, 0.7), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	st.tween_property(shock, "modulate:a", 0.0, 0.25)
	st.chain().tween_callback(func():
		if is_instance_valid(shock): shock.visible = false
	)

	var spark := _next_spark()
	spark.global_position = player_pos
	spark.restart()
	spark.emitting = true

	_screen_color_flash(hit_flash, Color(1, 1, 1, 0.22), 0.12)
	shake(0.18, 6.0)

	var ht := shield_hex.create_tween()
	ht.tween_property(shield_hex, "modulate", Color(2.0, 2.0, 2.2, shield_hex.modulate.a), 0.08)
	ht.tween_property(shield_hex, "modulate", Color(1, 1, 1, shield_hex.modulate.a), 0.25)

## Shield breaks: crack flash, shatter into crystal shards, a shock ring,
## then everything fades out.
func break_shield() -> void:
	if not is_instance_valid(shield_root) or not shield_root.visible: return
	_stop_shield_idle()
	_shield_active = false
	shield_ambient.emitting = false
	shield_sparkle.emitting = false

	# Crack — a fast bright flash right before it shatters
	var ct := shield_hex.create_tween()
	ct.tween_property(shield_hex, "modulate", Color(2.4, 2.4, 2.6, 1.0), 0.06)

	await get_tree().create_timer(0.06).timeout
	if not is_instance_valid(shield_root): return

	# Shatter into crystal shards flying outward
	for i in _shard_pool.size():
		var sh := _shard_pool[i]
		var ang := (TAU / _shard_pool.size()) * i + randf_range(-0.2, 0.2)
		var dist := randf_range(50.0, 110.0)
		sh.global_position = player_pos
		sh.rotation = ang
		sh.scale    = Vector2(1.0, 1.0)
		sh.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.9)
		sh.visible  = true
		var t := sh.create_tween().set_parallel(true)
		t.tween_property(sh, "global_position", player_pos + Vector2(cos(ang), sin(ang)) * dist, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(sh, "modulate:a", 0.0, 0.4)
		t.tween_property(sh, "scale", Vector2(0.3, 0.3), 0.4)
		t.chain().tween_callback(func():
			if is_instance_valid(sh): sh.visible = false
		)

	# Shock ring
	var shock := _next_ripple()
	shock.global_position = player_pos
	shock.rotation = 0.0
	shock.scale    = Vector2(0.2, 0.2)
	shock.modulate = Color(1, 1, 1, 1.0)
	shock.visible  = true
	var st := shock.create_tween().set_parallel(true)
	st.tween_property(shock, "scale", Vector2(1.4, 1.4), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	st.tween_property(shock, "modulate:a", 0.0, 0.3)
	st.chain().tween_callback(func():
		if is_instance_valid(shock): shock.visible = false
	)

	# Fade the rest out
	var ft := shield_root.create_tween().set_parallel(true)
	ft.tween_property(shield_hex, "modulate:a", 0.0, 0.3)
	ft.tween_property(shield_hex_lines, "modulate:a", 0.0, 0.3)
	ft.tween_property(shield_feet_ring, "modulate:a", 0.0, 0.3)
	ft.chain().tween_callback(func():
		if is_instance_valid(shield_root): shield_root.visible = false)


# ════════════════════════════════════════════════════════════
#  3. AETHER PULSE  (heal + void shield)
# ════════════════════════════════════════════════════════════
## Aether Pulse — one living current of divine energy that rises from beneath
## the feet, climbs the body (foot -> head) and wraps it in silk-like flame
## ribbons before dissolving overhead. Self-buff (heal + void shield) — no
## rings, pillars, magic circles or enemy impact. Every layer (ground glow,
## ribbons, travelling current, inner chest radiance, motes, residual) grows
## from the same upward flow. API/logic unchanged — visuals only.
func play_aether_pulse() -> void:
	var feet := player_pos + Vector2(4, 78)
	var chest := player_pos + Vector2(0, -6)
	var head := player_pos + Vector2(0, -78)

	cutscene_backdrop_in(0.2, 0.22)

	# ── PHASE 1/2/3 — energy awakens at the feet and blooms up the body as
	# silk ribbons (wrap_aura = ground glow + rising wrapping ribbons + wisps
	# + a few premium motes) ──
	wrap_aura(feet, COL_VIOLET, 8, 250.0)
	# Animated internal energy veins threading up the body (foot -> head).
	_rising_veins(feet, head, COL_CYAN)
	# Soft magical mist rising with the flow.
	var mist := _spawn_particles(feet, COL_VIOLET, {
		"amount": 10, "lifetime": 1.4, "one_shot": true,
		"dir": Vector3(0, -1, 0), "spread": 30.0, "ring": 40.0,
		"vmin": 25.0, "vmax": 60.0, "gravity": Vector3(0, -18, 0),
		"scale_min": 1.2, "scale_max": 2.4, "texture": _tex_dot,
	})
	mist.modulate.a = 0.22
	mist.z_index = 10
	_cleanup(mist, 1.6)

	# ── PHASE 2 — a bright current travels up the body, foot -> head ──
	var current := Sprite2D.new()
	current.texture = _tex_dot
	current.position = feet
	current.scale = Vector2(1.6, 1.1)
	current.modulate = Color(1.4, 1.3, 1.7, 0.0)
	current.z_index = 15
	add_child(current)
	var cut := current.create_tween()
	cut.tween_property(current, "modulate:a", 0.9, 0.12)
	cut.parallel().tween_property(current, "position", head, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cut.tween_property(current, "modulate:a", 0.0, 0.2)
	cut.tween_callback(current.queue_free)

	await get_tree().create_timer(0.34).timeout
	if not is_instance_valid(self): return

	# ── PHASE 3 — a second, inner silk layer (cyan) rising, offset timing ──
	wrap_aura(feet, COL_CYAN, 4, 230.0)
	# Shared divine-geometry motif (medium — Buff sits between Attack & Ult).
	_divine_geometry(chest, 1.1, 0.9)

	# ── PHASE 4/8 — inner radiance from the chest that softly breathes ──
	var inner := Sprite2D.new()
	inner.texture = _tex_dot
	inner.position = chest
	inner.scale = Vector2(2.2, 2.6)
	inner.modulate = Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0)
	var imat := CanvasItemMaterial.new()
	imat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	inner.material = imat
	inner.z_index = 14
	add_child(inner)
	var it := inner.create_tween()
	it.tween_property(inner, "modulate:a", 0.5, 0.22)
	it.tween_property(inner, "modulate:a", 0.3, 0.35)
	it.tween_property(inner, "modulate:a", 0.45, 0.3)
	it.tween_property(inner, "modulate:a", 0.0, 0.4)
	it.tween_callback(inner.queue_free)

	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self): return

	# ── PHASE 9 — residual: a faint upward aura keeps flowing, then fades ──
	wrap_aura(feet, COL_VIOLET, 3, 190.0)
	cutscene_backdrop_out(0.4)


func show_void_shield(_active: bool) -> void:
	# The circular void-shield orb was removed by request; the shield status
	# is already shown by the on-screen "Void Shield" label.
	if is_instance_valid(void_shield_orb):
		void_shield_orb.visible = false

func _build_void_shield_orb() -> void:
	void_shield_orb = _make_orb(COL_VIOLET, 0.45)
	void_shield_orb.scale = Vector2(0.7, 0.7)
	void_shield_orb.visible = false
	add_child(void_shield_orb)


# ════════════════════════════════════════════════════════════
#  4. ABSOLUTE ZERO FORMULA  (ultimate)
# ════════════════════════════════════════════════════════════
## Absolute Zero Formula — one gigantic living phenomenon that overwhelms the
## field (~80% of the battlefield). Three staged impacts: (1) atmospheric
## compression drags the whole field inward, (2) a divine bloom of many
## layered translucent energy sheets/ribbons with segmented geometry moving
## through it, (3) a massive multi-wave pressure release with screen-sweeping
## wind and field-wide distortion — then long residual energy. ~2.4s.
func play_ultimate() -> void:
	var epos := enemy_pos
	var eground := enemy_pos + Vector2(0, 60)
	var addm := CanvasItemMaterial.new()
	addm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	# ══ STAGE 1 — ATMOSPHERIC COMPRESSION (the field is dragged inward) ══
	cutscene_backdrop_in(0.42, 0.24)
	var seed_glow := Sprite2D.new()
	seed_glow.texture = _tex_dot
	seed_glow.position = eground
	seed_glow.scale = Vector2(4.0, 1.6)
	seed_glow.modulate = Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0)
	seed_glow.material = addm
	seed_glow.z_index = 8
	add_child(seed_glow)
	seed_glow.create_tween().tween_property(seed_glow, "modulate:a", 0.7, 0.32)
	for ci in 18:
		var ang := TAU * (float(ci) / 18) + randf_range(-0.2, 0.2)
		var d := Vector2(cos(ang), sin(ang))
		var strk := Sprite2D.new()
		strk.texture = _tex_streak
		strk.position = epos + d * randf_range(360.0, 560.0)
		strk.rotation = ang
		strk.scale = Vector2(2.0, 0.7)
		strk.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0)
		strk.material = addm
		strk.z_index = 12
		add_child(strk)
		var stt := strk.create_tween()
		stt.tween_property(strk, "modulate:a", 0.7, 0.06).set_delay(randf_range(0.0, 0.12))
		stt.parallel().tween_property(strk, "position", epos + d * 90.0, 0.24)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		stt.tween_property(strk, "modulate:a", 0.0, 0.08)
		stt.tween_callback(strk.queue_free)
	var gather := _spawn_particles(epos, COL_VIOLET, {
		"amount": 22, "lifetime": 0.8, "one_shot": false, "ring": 120.0,
		"dir": Vector3(0, -1, 0), "spread": 40.0, "gravity": Vector3(0, -20, 0),
		"vmin": 12.0, "vmax": 34.0, "scale_min": 0.4, "scale_max": 0.8,
		"texture": _tex_dot,
	})
	await get_tree().create_timer(0.42).timeout
	if not is_instance_valid(self): return

	# ══ STAGE 2 — DIVINE BLOOM (a giant body of layered translucent energy) ══
	gather.emitting = false
	# Core vertical bloom: several huge ribbon layers rising from the ground.
	rising_energy(eground, COL_VIOLET, 16, 560.0, true)
	rising_energy(eground, COL_CYAN, 10, 480.0, true)
	wrap_aura(eground, COL_VIOLET, 16, 520.0)
	wrap_aura(eground, COL_CYAN, 8, 430.0)
	_rising_veins(eground, epos + Vector2(0, -240.0), COL_CYAN)
	# 8-12 large flowing energy sheets fanning up and out, staggered timing.
	for i in 11:
		var voff := (float(i) - 5.0) * 0.34
		_wind_sheet(eground, COL_VIOLET if i % 2 == 0 else COL_CYAN, voff, i * 0.028, 4.2)
	# Segmented divine geometry moving through the body (a few, at scale).
	_divine_geometry(epos, 3.2, 1.0)
	_divine_geometry(epos + Vector2(0, -170.0), 2.2, 0.85)
	cutscene_backdrop_out(0.7)
	await get_tree().create_timer(0.24).timeout
	if not is_instance_valid(self): return

	# ══ STAGE 3 — MASSIVE PRESSURE RELEASE (multiple waves, field-wide) ══
	# Multiple broken pressure surfaces bloom outward in staggered waves —
	# huge radii, wrapping, never perfect circles.
	var ba := -1.2
	_pressure_surface(epos, Color(1, 1, 1, 1), 180.0, ba + randf_range(-0.3, 0.3), 3.2, 0.34, 0.0, 0.9)
	_pressure_surface(epos, COL_CYAN, 280.0, ba + randf_range(-0.4, 0.4), 3.8, 0.5, 0.06, 0.7)
	_pressure_surface(epos, COL_VIOLET, 380.0, ba + randf_range(-0.4, 0.4), 4.4, 0.62, 0.12, 0.55)
	_pressure_surface(epos, COL_VIOLET, 480.0, ba + randf_range(-0.5, 0.5), 4.8, 0.78, 0.2, 0.4)
	# Large wind sheets sweeping across the screen.
	for i in 6:
		_wind_sheet(epos, COL_CYAN, (float(i) - 2.5) * 0.5, i * 0.03, 5.0)
	_divine_geometry(epos, 2.8, 1.0)
	# One-frame reality crack.
	for cri in 8:
		var cang := TAU * (float(cri) / 8) + randf_range(-0.3, 0.3)
		var cdir := Vector2(cos(cang), sin(cang))
		var crk := Line2D.new()
		crk.width = 1.8
		crk.default_color = Color(1, 1, 1, 1)
		crk.add_point(cdir * 24.0)
		crk.add_point(cdir * randf_range(140.0, 260.0))
		crk.position = epos
		crk.z_index = 19
		crk.modulate.a = 0.0
		add_child(crk)
		var crt := crk.create_tween()
		crt.tween_property(crk, "modulate:a", 0.9, 0.03)
		crt.tween_property(crk, "modulate:a", 0.0, 0.1)
		crt.tween_callback(crk.queue_free)
	# Field-wide atmospheric distortion.
	var haze := Sprite2D.new()
	haze.texture = _tex_dot
	haze.position = epos
	haze.scale = Vector2(6.0, 5.0)
	haze.modulate = Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0)
	haze.material = addm
	haze.z_index = 10
	add_child(haze)
	var ht := haze.create_tween()
	ht.tween_property(haze, "modulate:a", 0.18, 0.12)
	ht.parallel().tween_property(haze, "scale", Vector2(20.0, 15.0), 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ht.tween_property(haze, "modulate:a", 0.0, 0.5)
	ht.tween_callback(haze.queue_free)
	# Screen: heavy shake, camera punch, secondary bloom pulse.
	shake(0.6, 18.0)
	_camera_zoom(epos, 0.08, 0.5)
	_screen_color_flash(hit_flash, Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.26), 0.14)
	var bpulse := Sprite2D.new()
	bpulse.texture = _tex_dot
	bpulse.position = epos
	bpulse.scale = Vector2(4.0, 4.4)
	bpulse.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0)
	bpulse.material = addm
	bpulse.z_index = 13
	add_child(bpulse)
	var bpt := bpulse.create_tween()
	bpt.tween_property(bpulse, "modulate:a", 0.42, 0.08).set_delay(0.12)
	bpt.parallel().tween_property(bpulse, "scale", Vector2(11.0, 12.0), 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bpt.tween_property(bpulse, "modulate:a", 0.0, 0.4)
	bpt.tween_callback(bpulse.queue_free)
	_cleanup(seed_glow, 0.5)
	_cleanup(gather, 0.3)
	await get_tree().create_timer(0.26).timeout
	if not is_instance_valid(self): return

	# ══ RESIDUAL — large sheets and embers linger, then slowly fade ══
	rising_energy(eground, COL_VIOLET, 8, 340.0, true)
	for i in 3:
		_wind_sheet(epos, COL_VIOLET, (float(i) - 1.0) * 0.5, i * 0.08, 3.4)
	var embers := _spawn_particles(eground, COL_VIOLET, {
		"amount": 26, "lifetime": 2.2, "one_shot": true,
		"dir": Vector3(0, -1, 0), "spread": 50.0, "ring": 60.0,
		"vmin": 20.0, "vmax": 70.0, "gravity": Vector3(0, -20, 0),
		"scale_min": 0.4, "scale_max": 1.0, "texture": _tex_dot,
	})
	embers.modulate.a = 0.5
	_cleanup(embers, 2.4)


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
	# One directional pressure wave at the enemy — the whole Attack visual —
	# plus the physical feedback (recoil, a small shake and camera punch).
	_pressure_impact(enemy_pos, COL_VIOLET)
	enemy_hit_react()
	shake(0.12, 4.0)
	_camera_zoom(enemy_pos, 0.03, 0.22)


# ════════════════════════════════════════════════════════════
#  7. ENEMY ATTACK
# ════════════════════════════════════════════════════════════
func play_enemy_attack() -> void:
	if is_instance_valid(enemy_node) and (enemy_node is Node2D or enemy_node is Control):
		var orig: Vector2 = enemy_node.position
		var t := enemy_node.create_tween()
		t.tween_property(enemy_node, "position", orig + Vector2(-80, 0), 0.1).set_trans(Tween.TRANS_BACK)
		t.tween_property(enemy_node, "position", orig, 0.14)
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
	lbl.size = Vector2(80, 40)
	lbl.pivot_offset = Vector2(40, 20)
	var arc := randf_range(-16, 16)
	lbl.position = pos - Vector2(40, 10) + Vector2(arc * 0.4, 0)
	lbl.z_index = 40
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Readable pop per spec: 90% -> 110% -> 100% (no time freeze, ~0.18s).
	lbl.scale = Vector2(0.9, 0.9)
	floating_root.add_child(lbl)

	# 1. POP — brief scale punch to 110% then settle at 100%.
	var st := lbl.create_tween()
	st.tween_property(lbl, "scale", Vector2(1.1, 1.1), 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_property(lbl, "scale", Vector2.ONE, 0.08)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 2. ARC + RISE — drift sideways a touch, float up, then fade out.
	var t := lbl.create_tween().set_parallel(true)
	t.tween_property(lbl, "position:y", lbl.position.y - 62.0, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "position:x", lbl.position.x + arc, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, 0.9).set_delay(0.3)
	t.chain().tween_callback(lbl.queue_free)


## ── MAGICAL ENERGY LANGUAGE ─────────────────────────────────
## Vertical flowing energy that builds at `base`: tapered light-ray
## ribbons sweeping upward, rising glowing particles, and soft embers.
## The shared "layered magical energy" look for skills/ultimate — no
## spinning rings, and it never covers the character (it rises past them).
func rising_energy(base: Vector2, col: Color, ribbons := 5, height := 150.0, big := false) -> void:
	# Light-ray ribbons: thin vertical streaks that rise, waver, and fade.
	for i in ribbons:
		var off := randf_range(-46.0, 46.0)
		var ln := Line2D.new()
		ln.width = randf_range(3.0, 6.0) * (1.4 if big else 1.0)
		ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ln.end_cap_mode = Line2D.LINE_CAP_ROUND
		var grad := Gradient.new()
		grad.set_color(0, Color(col.r, col.g, col.b, 0.0))
		grad.add_point(0.4, Color(col.r, col.g, col.b, 0.85))
		grad.set_color(1, Color(1, 1, 1, 0.0))
		ln.gradient = grad
		var h := height * randf_range(0.7, 1.15)
		ln.add_point(Vector2(off, 0))
		ln.add_point(Vector2(off + randf_range(-10, 10), -h * 0.5))
		ln.add_point(Vector2(off + randf_range(-14, 14), -h))
		ln.position = base
		ln.z_index = 11
		add_child(ln)
		var t := ln.create_tween()
		t.tween_property(ln, "modulate:a", 1.0, 0.14).set_delay(i * 0.03)
		t.tween_interval(0.12)
		t.tween_property(ln, "modulate:a", 0.0, 0.3)
		t.parallel().tween_property(ln, "position", base + Vector2(0, -26), 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_callback(ln.queue_free)

	# Rising glowing particles drifting upward past the caster.
	var motes := _spawn_particles(base, col, {
		"amount": 22 if big else 14, "lifetime": 0.9, "one_shot": true,
		"dir": Vector3(0, -1, 0), "spread": 22.0, "ring": 40.0,
		"vmin": 90.0, "vmax": 190.0, "gravity": Vector3(0, -30, 0),
		"scale_min": 0.35, "scale_max": 0.85, "texture": _tex_dot,
	})
	motes.z_index = 10
	_cleanup(motes, 1.1)


## Charging aura that wraps around the character's silhouette: flowing
## energy ribbons rise from the feet and curve left/right around the body
## (denser/low, spreading at the waist, dissolving overhead), faking a
## behind-the-body pass by dimming as they cross the mid-line. Rising
## motes travel up with the flow. No straight pillar, no rotating circle.
func wrap_aura(feet: Vector2, col: Color, streams := 9, height := 210.0) -> void:
	# Layer 1 — soft ground glow that gently blooms outward at the feet.
	var glow := Sprite2D.new()
	glow.texture = _tex_dot
	glow.position = feet
	glow.scale = Vector2(4.5, 1.7)
	glow.modulate = Color(col.r, col.g, col.b, 0.0)
	glow.z_index = 8
	add_child(glow)
	var gt := glow.create_tween().set_parallel(true)
	gt.tween_property(glow, "modulate:a", 0.5, 0.22)
	gt.tween_property(glow, "scale", Vector2(8.5, 3.0), 0.7)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	gt.chain().tween_property(glow, "modulate:a", 0.0, 0.4)
	gt.chain().tween_callback(glow.queue_free)

	# Layer 3 — long flowing ribbons that hug the body, weave, and vary.
	for i in streams:
		var side := 1.0 if i % 2 == 0 else -1.0
		var phase := randf_range(0.0, TAU)
		var phase2 := randf_range(0.0, TAU)
		var amp := randf_range(26.0, 48.0)          # how far it wraps sideways
		var freq := randf_range(2.4, 3.6)            # weave frequency (varied)
		var turb := randf_range(4.0, 9.0)            # turbulence amount
		var h := height * randf_range(0.8, 1.14)
		var behind := i % 3 == 0                     # some read as behind the body
		var ln := Line2D.new()
		ln.width = randf_range(2.5, 6.5)             # different widths
		ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ln.end_cap_mode = Line2D.LINE_CAP_ROUND
		ln.joint_mode = Line2D.LINE_JOINT_ROUND
		ln.width_curve = _aura_width_curve()
		var grad := Gradient.new()
		var hi_a := 0.7 if behind else 0.95
		grad.set_color(0, Color(col.r, col.g, col.b, 0.0))
		grad.add_point(0.2, Color(1, 1, 1, hi_a))
		grad.add_point(0.58, Color(col.r, col.g, col.b, 0.8 if not behind else 0.6))
		grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
		ln.gradient = grad
		var pts := PackedVector2Array()
		var segs := 18
		for s in segs + 1:
			var u := float(s) / segs                # 0 feet -> 1 overhead
			var bell := sin(u * PI)                  # widest at the waist/torso
			# Weave (two frequencies) + turbulence so no two paths match.
			var sway := sin(u * freq + phase) * amp * bell
			sway += sin(u * freq * 2.3 + phase2) * (amp * 0.28) * bell
			sway += randf_range(-turb, turb) * bell
			pts.append(Vector2(feet.x + side * sway, feet.y - u * h))
		ln.points = pts
		ln.z_index = 11 if behind else 13
		ln.modulate = Color(1, 1, 1, 0.0)
		add_child(ln)
		# Different speeds; energy accelerates slightly as it rises + fades.
		var rise := randf_range(0.42, 0.6)
		var t := ln.create_tween()
		t.tween_property(ln, "modulate:a", 1.0, 0.14).set_delay(i * 0.045)
		t.tween_interval(0.1)
		t.parallel().tween_property(ln, "position", Vector2(0, -36), rise)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(ln, "modulate:a", 0.0, 0.3)
		t.tween_callback(ln.queue_free)
		# Layer 4/5 — a wisp detaches from mid-ribbon and drifts up, fading.
		if i % 2 == 0:
			var wp: Vector2 = pts[int(segs * 0.55)]
			_aura_wisp(wp, col, i * 0.05)

	# Layer 4 — weightless motes drifting up with the flow, shrinking away.
	var motes := _spawn_particles(feet, col, {
		"amount": 18, "lifetime": 1.0, "one_shot": true,
		"dir": Vector3(0, -1, 0), "spread": 22.0, "ring": 32.0,
		"vmin": 70.0, "vmax": 150.0, "gravity": Vector3(0, -30, 0),
		"scale_min": 0.3, "scale_max": 0.75, "texture": _tex_dot,
	})
	motes.z_index = 12
	_cleanup(motes, 1.2)

	# Layer 5 — a few sparse magical sparks (low density, never noisy).
	var sparks := _spawn_particles(feet + Vector2(0, -60), Color(1, 1, 1, 1), {
		"amount": 5, "lifetime": 0.8, "one_shot": true,
		"dir": Vector3(0, -1, 0), "spread": 40.0, "ring": 46.0,
		"vmin": 40.0, "vmax": 110.0, "gravity": Vector3(0, -20, 0),
		"scale_min": 0.25, "scale_max": 0.5, "texture": _tex_dot,
	})
	sparks.z_index = 14
	_cleanup(sparks, 1.0)

## Width curve for aura ribbons — thin at the feet, fuller mid-body, tapering
## to nothing overhead, so each ribbon reads like a tongue of flame.
func _aura_width_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.2))
	c.add_point(Vector2(0.4, 1.0))
	c.add_point(Vector2(1.0, 0.15))
	return c

## A small energy wisp that detaches from a ribbon and rises, gently swaying,
## shrinking and fading — the "flowing magical flame" fine detail.
func _aura_wisp(pos: Vector2, col: Color, delay: float) -> void:
	var w := Sprite2D.new()
	w.texture = _tex_dot
	w.position = pos
	w.scale = Vector2(0.9, 0.9)
	w.modulate = Color(col.r, col.g, col.b, 0.0)
	w.z_index = 12
	add_child(w)
	var drift := Vector2(randf_range(-14, 14), randf_range(-70, -95))
	var t := w.create_tween()
	t.tween_property(w, "modulate:a", 0.85, 0.12).set_delay(delay)
	t.parallel().tween_property(w, "position", pos + drift, 0.7)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(w, "scale", Vector2(0.2, 0.2), 0.7)
	t.tween_property(w, "modulate:a", 0.0, 0.25)
	t.tween_callback(w.queue_free)


## Expanding thin shock ring at `pos` — a clean energy wave rippling out.
func energy_wave(pos: Vector2, col: Color, to_scale := 1.0) -> void:
	var ring := Sprite2D.new()
	ring.texture  = _tex_ring_thin
	ring.position = pos
	ring.modulate = Color(col.r, col.g, col.b, 0.9)
	ring.scale    = Vector2(0.1, 0.1)
	ring.z_index  = 12
	add_child(ring)
	var t := ring.create_tween().set_parallel(true)
	t.tween_property(ring, "scale", Vector2(to_scale, to_scale), 0.32)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(ring, "modulate:a", 0.0, 0.34)
	t.chain().tween_callback(ring.queue_free)


## ── BACKGROUND LAYER ────────────────────────────────────────
## Fade the cutscene backdrop in: a soft vignette that darkens the edges
## and gently dims the field, drawing the eye to the character. Capped
## well below 30% so the background never blacks out. Call _out to clear.
func cutscene_backdrop_in(peak: float = 0.26, dur: float = 0.22) -> void:
	if not is_instance_valid(_backdrop): return
	var t := _backdrop.create_tween()
	t.tween_property(_backdrop, "modulate:a", clampf(peak, 0.0, 0.29), dur)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func cutscene_backdrop_out(dur: float = 0.3) -> void:
	if not is_instance_valid(_backdrop): return
	var t := _backdrop.create_tween()
	t.tween_property(_backdrop, "modulate:a", 0.0, dur)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

## Enemy reacts to being hit: a quick recoil kick backward that springs
## back, plus a small shake and bright flash. Reusable on any impact.
func enemy_hit_react(recoil: float = 34.0) -> void:
	if not is_instance_valid(enemy_node) or not (enemy_node is Node2D or enemy_node is Control):
		return
	var orig: Vector2 = enemy_node.position
	var t := enemy_node.create_tween()
	t.tween_property(enemy_node, "position", orig + Vector2(recoil, 0), 0.07)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(enemy_node, "position", orig, 0.22)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_flash_node(enemy_node)
	_shake_node(enemy_node, 5.0, 0.12)

## Shared "divine geometry" motif — the same visual language as the defensive
## barrier benchmark: broken concentric arc segments (never a full circle) plus
## angular bracket markers that snap in and fade. Gives Attack/Buff/Ultimate one
## mechanical-fantasy layer; `s` scales it (Attack < Buff < Ultimate).
func _divine_geometry(pos: Vector2, s: float, intensity := 1.0) -> void:
	var col := COL_CYAN
	var addm := CanvasItemMaterial.new()
	addm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# Broken arc segments at three radii — segmented, not a solid ring.
	for ridx in 3:
		var rad := (30.0 + ridx * 15.0) * s
		var a := randf_range(0.0, TAU)
		var segn := 3 + ridx
		for k in segn:
			var span := randf_range(0.3, 0.65)
			var ln := Line2D.new()
			ln.width = 1.7 - ridx * 0.3
			ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
			ln.end_cap_mode = Line2D.LINE_CAP_ROUND
			ln.default_color = Color(col.r, col.g, col.b, 0.0)
			ln.material = addm
			var segs := 8
			var pts := PackedVector2Array()
			for j in segs + 1:
				var ang := a + span * (float(j) / segs)
				pts.append(Vector2(cos(ang) * rad, sin(ang) * rad))
			ln.points = pts
			ln.position = pos
			ln.z_index = 15
			ln.scale = Vector2(0.92, 0.92)
			add_child(ln)
			var t := ln.create_tween()
			t.tween_property(ln, "modulate:a", 0.7 * intensity, 0.08).set_delay(k * 0.02)
			t.tween_interval(0.12)
			t.tween_property(ln, "modulate:a", 0.0, 0.28)
			t.tween_callback(ln.queue_free)
			# Organic breathing: segments drift open slightly as they glow.
			ln.create_tween().tween_property(ln, "scale", Vector2(1.07, 1.07), 0.46)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			a += span + randf_range(0.3, 0.6)
	# Fine dot markers dusting the mid radius (internal density).
	for di in 6:
		var dang := TAU * (float(di) / 6) + randf_range(-0.25, 0.25)
		var dot := Sprite2D.new()
		dot.texture = _tex_dot
		dot.position = pos + Vector2(cos(dang), sin(dang)) * (44.0 * s)
		dot.scale = Vector2(0.35, 0.35) * s
		dot.modulate = Color(1, 1, 1, 0.0)
		dot.material = addm
		dot.z_index = 15
		add_child(dot)
		var dt := dot.create_tween()
		dt.tween_property(dot, "modulate:a", 0.85 * intensity, 0.07).set_delay(di * 0.015)
		dt.tween_interval(0.1)
		dt.tween_property(dot, "modulate:a", 0.0, 0.26)
		dt.tween_callback(dot.queue_free)
	# Angular bracket markers ringing the geometry (divine mechanical detail).
	var mk := 4
	for i in mk:
		var ang := TAU * (float(i) / mk) + randf_range(-0.2, 0.2)
		var outd := Vector2(cos(ang), sin(ang))
		var tang := Vector2(-outd.y, outd.x)
		var base := pos + outd * (56.0 * s)
		var sz := 7.0 * s
		var ln := Line2D.new()
		ln.width = 1.4
		ln.default_color = Color(1, 1, 1, 0.0)
		ln.material = addm
		ln.add_point(base - tang * sz)
		ln.add_point(base + tang * sz)
		ln.add_point(base + tang * sz + outd * (sz * 0.5))
		ln.z_index = 15
		add_child(ln)
		var t := ln.create_tween()
		t.tween_property(ln, "modulate:a", 0.8 * intensity, 0.08)
		t.tween_interval(0.1)
		t.tween_property(ln, "modulate:a", 0.0, 0.26)
		t.tween_callback(ln.queue_free)

## Animated internal energy veins climbing the body foot -> head: a few thin,
## organically curving lines that light up from the feet upward in sequence,
## like divine energy threading through the character.
func _rising_veins(feet: Vector2, head: Vector2, col: Color) -> void:
	var h := feet.y - head.y
	for i in 5:
		var side := (float(i) - 2.0) * 0.5
		var ln := Line2D.new()
		ln.width = randf_range(1.4, 2.6)
		ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ln.end_cap_mode = Line2D.LINE_CAP_ROUND
		var grad := Gradient.new()
		grad.set_color(0, Color(col.r, col.g, col.b, 0.0))
		grad.add_point(0.5, Color(1, 1, 1, 0.8))
		grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
		ln.gradient = grad
		var phase := randf_range(0.0, TAU)
		var amp := randf_range(8.0, 20.0)
		var segs := 14
		var pts := PackedVector2Array()
		for s in segs + 1:
			var u := float(s) / segs
			var bell := sin(u * PI)
			var x := feet.x + side * 14.0 + sin(u * 4.0 + phase) * amp * bell
			pts.append(Vector2(x, feet.y - u * h))
		ln.points = pts
		ln.z_index = 14
		ln.modulate.a = 0.0
		add_child(ln)
		var t := ln.create_tween()
		t.tween_property(ln, "modulate:a", 0.85, 0.16).set_delay(i * 0.06)
		t.tween_interval(0.14)
		t.tween_property(ln, "modulate:a", 0.0, 0.3)
		t.tween_callback(ln.queue_free)

## A flowing wind sheet peeling forward from `pos` along the punch (+x): a
## crescent of compressed air that widens, stretches forward and dissolves.
## `voff` offsets/tilts it so the 2-3 sheets differ and never mirror.
func _wind_sheet(pos: Vector2, col: Color, voff: float, delay: float, scl := 1.0) -> void:
	var ln := Line2D.new()
	ln.width = randf_range(3.0, 6.0) * scl
	ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ln.end_cap_mode = Line2D.LINE_CAP_ROUND
	var grad := Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 0.0))
	grad.add_point(0.5, Color(1, 1, 1, 0.8))
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	ln.gradient = grad
	var size := randf_range(30.0, 52.0) * scl
	var curv := randf_range(0.5, 0.9)
	var segs := 10
	var pts := PackedVector2Array()
	for i in segs + 1:
		var u := float(i) / segs
		var a := (u - 0.5) * PI * curv
		pts.append(Vector2(cos(a) * size * 0.55 + size * 0.2, sin(a) * size + voff * size * 0.4))
	ln.points = pts
	ln.position = pos
	ln.rotation = voff * 0.4
	ln.modulate = Color(1, 1, 1, 0.0)
	ln.scale = Vector2(0.5, 0.8)
	ln.z_index = 15
	var wmat := CanvasItemMaterial.new()
	wmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ln.material = wmat
	add_child(ln)
	var travel := pos + Vector2(randf_range(60.0, 100.0) * scl, voff * 20.0 * scl)
	var dur := randf_range(0.28, 0.42) * (1.0 + (scl - 1.0) * 0.3)
	var t := ln.create_tween()
	t.tween_property(ln, "modulate:a", randf_range(0.5, 0.85), 0.05).set_delay(delay)
	t.parallel().tween_property(ln, "position", travel, dur)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(ln, "scale", Vector2(1.4, 1.1), dur)
	# Organic twist as it peels away.
	t.parallel().tween_property(ln, "rotation", ln.rotation + randf_range(-0.3, 0.3), dur)
	t.tween_property(ln, "modulate:a", 0.0, 0.18)
	t.tween_callback(ln.queue_free)

## A large pressure surface at `pos`: a broken, organically deformed arc that
## expands outward while wrapping the target (partial span, slight vertical
## squash → not a perfect circle), then fades. Big-scale shockwave building
## block. Untyped numeric params keep the signature short.
func _pressure_surface(pos, col, rad, a0, span, dur, delay, bright) -> void:
	var ln := Line2D.new()
	ln.width = rad * 0.02 + 1.8
	ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ln.end_cap_mode = Line2D.LINE_CAP_ROUND
	var grad := Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 0.0))
	grad.add_point(0.5, Color(1, 1, 1, 0.85))
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	ln.gradient = grad
	var segs := 22
	var pts := PackedVector2Array()
	for i in segs + 1:
		var a: float = a0 + span * (float(i) / segs)
		var r: float = rad * (1.0 + randf_range(-0.1, 0.1))   # organic deform
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.82))    # squashed → oval
	ln.points = pts
	ln.position = pos
	ln.scale = Vector2(0.35, 0.35)
	ln.modulate = Color(1, 1, 1, 0.0)
	ln.z_index = 15
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ln.material = m
	add_child(ln)
	var t := ln.create_tween()
	t.tween_property(ln, "modulate:a", bright, 0.06).set_delay(delay)
	t.parallel().tween_property(ln, "scale", Vector2.ONE, dur)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_property(ln, "modulate:a", 0.0, dur * 0.5)
	t.tween_callback(ln.queue_free)

## Normal Attack — one large atmospheric pressure phenomenon (~40-60% of the
## field around the enemy). Air compresses inward, a dense core stretches
## forward, several layered broken pressure surfaces bloom and wrap the enemy,
## large wind sheets peel off, segmented divine geometry + veins add internal
## detail, a big air-distortion haze swells, and long residual wind trails off.
## Directional (+x punch) — nothing expands as a perfect circle.
func _pressure_impact(pos: Vector2, col: Color) -> void:
	var fwd := Vector2(1, 0)

	# FRAME 1 — ATMOSPHERIC COMPRESSION: air dragged inward from a wide radius.
	for ci in 12:
		var ang := TAU * (float(ci) / 12) + randf_range(-0.25, 0.25)
		var d := Vector2(cos(ang), sin(ang))
		var strk := Sprite2D.new()
		strk.texture = _tex_streak
		strk.position = pos + d * randf_range(180.0, 300.0)
		strk.rotation = ang
		strk.scale = Vector2(1.3, 0.5)
		strk.modulate = Color(col.r, col.g, col.b, 0.0)
		strk.z_index = 15
		add_child(strk)
		var stt := strk.create_tween()
		stt.tween_property(strk, "modulate:a", 0.7, 0.05)
		stt.parallel().tween_property(strk, "position", pos + d * 55.0, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		stt.tween_property(strk, "modulate:a", 0.0, 0.06)
		stt.tween_callback(strk.queue_free)

	# FRAME 2 — DENSE CORE: a wide soft body under a bright inner core, both
	# large and stretching forward.
	for layer_i in 2:
		var wide := layer_i == 0
		var core := Sprite2D.new()
		core.texture = _tex_dot
		core.position = pos
		core.scale = Vector2(1.4, 3.2) if wide else Vector2(0.8, 1.8)
		core.modulate = Color(col.r, col.g, col.b, 0.0) if wide else Color(1.9, 1.9, 2.0, 0.0)
		core.z_index = 16 if wide else 17
		var cm := CanvasItemMaterial.new()
		cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		core.material = cm
		add_child(core)
		var peak_a := 0.8 if wide else 1.0
		var end_s := Vector2(6.5, 2.0) if wide else Vector2(4.4, 1.2)
		var ct := core.create_tween()
		ct.tween_property(core, "modulate:a", peak_a, 0.04).set_delay(0.08)
		ct.parallel().tween_property(core, "scale", end_s, 0.16)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		ct.parallel().tween_property(core, "position", pos + fwd * 70.0, 0.18)
		ct.tween_property(core, "modulate:a", 0.0, 0.2)
		ct.tween_callback(core.queue_free)

	# FRAME 3 — LAYERED PRESSURE SURFACES: broken arcs that bloom outward and
	# wrap the enemy (opening biased forward, staggered speed/opacity).
	var ba := -1.0
	_pressure_surface(pos, col, 150.0, ba + randf_range(-0.3, 0.3), 3.4, 0.36, 0.08, 0.85)
	_pressure_surface(pos, Color(1, 1, 1, 1), 120.0, ba + randf_range(-0.3, 0.3), 2.6, 0.30, 0.10, 0.7)
	_pressure_surface(pos, col, 210.0, ba + randf_range(-0.4, 0.4), 3.8, 0.50, 0.13, 0.6)
	_pressure_surface(pos, col, 275.0, ba + randf_range(-0.4, 0.4), 4.2, 0.60, 0.17, 0.45)

	# FRAME 3b — WIND SHEETS: large, peeling off with different timing.
	for i in 6:
		_wind_sheet(pos, col, (float(i) - 2.5) * 0.4, 0.1 + i * 0.03, 2.6)

	# FRAME 4 — INTERNAL DETAIL: large segmented divine geometry + energy veins.
	_divine_geometry(pos, 2.2, 0.9)
	_rising_veins(pos + Vector2(0, 60), pos + Vector2(0, -120), col)

	# FRAME 5 — LARGE AIR DISTORTION: a big faint haze swelling over the field.
	var haze := Sprite2D.new()
	haze.texture = _tex_dot
	haze.position = pos
	haze.scale = Vector2(4.0, 3.4)
	haze.modulate = Color(col.r, col.g, col.b, 0.0)
	var hm := CanvasItemMaterial.new()
	hm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	haze.material = hm
	haze.z_index = 11
	add_child(haze)
	var ht := haze.create_tween()
	ht.tween_property(haze, "modulate:a", 0.15, 0.1).set_delay(0.08)
	ht.parallel().tween_property(haze, "scale", Vector2(11.0, 8.0), 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ht.tween_property(haze, "modulate:a", 0.0, 0.4)
	ht.tween_callback(haze.queue_free)

	# Fine forward fragments.
	var frags := _spawn_particles(pos, Color(1, 1, 1, 1), {
		"amount": 12, "lifetime": 0.4, "one_shot": true, "explosive": true,
		"dir": Vector3(1, 0, 0), "spread": 60.0, "vmin": 260.0, "vmax": 560.0,
		"scale_min": 0.4, "scale_max": 1.0, "texture": _tex_streak,
	})
	frags.z_index = 16
	_cleanup(frags, 0.6)

	# FRAME 6 — LONG RESIDUAL WIND: faint large sheets drift forward late.
	for i in 4:
		_wind_sheet(pos + fwd * 40.0, col, (float(i) - 1.5) * 0.4, 0.3 + i * 0.06, 2.2)






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

## Brief punch-in "camera zoom" toward `pos`, approximated by scaling the
## whole battle root (no real Camera2D exists in this Control-based scene).
func _camera_zoom(pos: Vector2, amount: float, duration: float) -> void:
	if not is_instance_valid(shake_root) or not (shake_root is Control): return
	var root := shake_root as Control
	var orig_pivot: Vector2 = root.pivot_offset
	root.pivot_offset = pos
	var t := root.create_tween()
	t.tween_property(root, "scale", Vector2(1.0 + amount, 1.0 + amount), duration * 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(root, "scale", Vector2.ONE, duration * 0.65)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		if is_instance_valid(root): root.pivot_offset = orig_pivot
	)

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

func _build_backdrop() -> void:
	_backdrop = TextureRect.new()
	_backdrop.texture = _tex_vignette
	_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	_backdrop.size = Vector2(SCREEN_W, SCREEN_H)
	_backdrop.modulate = Color(1, 1, 1, 0.0)
	_backdrop.z_index = 2   # background layer: under slashes/impacts/UI
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)

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

## Vignette: transparent center fading to dark toward the edges. The clear
## middle keeps the character bright while the edges frame the shot.
func _make_vignette_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size * 0.5, size * 0.5)
	var maxd := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(c) / maxd   # 0 center .. ~1.41 corner
			# Start darkening past ~45% radius, ease up to the edge.
			var a := clampf((d - 0.45) / 0.55, 0.0, 1.0)
			a = a * a * 0.9                                 # softer falloff, cap alpha
			img.set_pixel(x, y, Color(0, 0, 0, a))
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

func _make_ramp(color: Color) -> GradientTexture1D:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.r, color.g, color.b, 0.0))
	ramp.add_point(0.15, Color(color.r, color.g, color.b, 1.0))
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var rt := GradientTexture1D.new()
	rt.gradient = ramp
	return rt

## Signed-ish "inside distance" to a flat-top regular hexagon (apothem-radius).
## Positive = inside, 0 = on the edge, negative = outside.
func _hex_dist(p: Vector2, apothem: float) -> float:
	var d := -1e9
	for i in 3:
		var ang  := deg_to_rad(60.0 * i)
		var axis := Vector2(cos(ang), sin(ang))
		d = maxf(d, absf(p.dot(axis)))
	return apothem - d

func _make_hex_texture(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center  := Vector2(size * 0.5, size * 0.5)
	var apothem := size * 0.5 - 6.0
	for y in size:
		for x in size:
			var hd := _hex_dist(Vector2(x, y) - center, apothem)
			var rim  := clampf(1.0 - absf(hd) / 5.0, 0.0, 1.0)
			var fill := 0.0 if hd < -4.0 else clampf((hd + 4.0) / 10.0, 0.0, 0.16)
			var a := maxf(rim, fill)
			if hd < -8.0: a = 0.0
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	return ImageTexture.create_from_image(img)

## Faint spokes + concentric rings inside the hexagon — rotated over time by
## its owning Sprite2D to read as "energy lines flowing" across the surface.
func _make_hex_lines_texture(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var maxr   := size * 0.5 - 8.0
	for y in size:
		for x in size:
			var p := Vector2(x, y) - center
			var d := p.length()
			var a := 0.0
			if d < maxr and d > 4.0:
				var spoke_ang  := fmod(p.angle() + PI, PI / 3.0) - PI / 6.0
				var spoke_dist := absf(spoke_ang) * d
				a = maxf(a, clampf(1.0 - spoke_dist / 4.0, 0.0, 1.0) * 0.35)
				var ring_t := fmod(d, 18.0)
				a = maxf(a, clampf(1.0 - absf(ring_t - 9.0) / 1.5, 0.0, 1.0) * 0.12)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	return ImageTexture.create_from_image(img)

func _make_thin_ring_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var r := size * 0.5 - 4.0
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center)
			var a := _ring_band(d, r - 3.0, r)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

## Small tapered crystal shard, used for the shield-shatter burst.
func _make_shard_texture() -> ImageTexture:
	var w := 14; var h := 22
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var fx := float(x) / w - 0.5
			var fy := float(y) / h
			var half_w := 0.5 * (1.0 - absf(fy - 0.5) * 1.6)
			var a := 1.0 if absf(fx) <= half_w else 0.0
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
