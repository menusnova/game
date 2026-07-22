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

	await get_tree().create_timer(0.18).timeout
	# Impact burst on the enemy (magenta)
	_spawn_particles(enemy_pos, COL_MAGENTA, {
		"amount": 26, "lifetime": 0.5, "one_shot": true, "explosive": true,
		"spread": 180.0, "vmin": 60.0, "vmax": 220.0,
		"scale_min": 0.6, "scale_max": 1.4, "texture": _tex_dot,
	})
	# Contact juice: spark + enemy recoil + a quick white flash & light punch.
	hit_spark(enemy_pos, COL_CYAN)
	enemy_hit_react()
	_screen_color_flash(hit_flash, Color(1, 1, 1, 0.16), 0.06)
	shake(0.12, 4.0)
	_camera_zoom(enemy_pos, 0.03, 0.22)
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
	shield_feet_ring.modulate.a = 0.0
	shield_feet_ring.scale      = Vector2(0.15, 0.06)
	var ft := shield_feet_ring.create_tween().set_parallel(true)
	ft.tween_property(shield_feet_ring, "modulate:a", 0.85, 0.18)
	ft.tween_property(shield_feet_ring, "scale", Vector2(0.62, 0.24), 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.12).timeout
	if not _shield_active or not is_instance_valid(shield_hex): return

	shield_hex.modulate.a       = 0.0
	shield_hex.scale            = Vector2(0.2, 0.2)
	shield_hex_lines.modulate.a = 0.0
	shield_hex_lines.scale      = Vector2(0.2, 0.2)
	var ht := shield_hex.create_tween().set_parallel(true)
	ht.tween_property(shield_hex, "modulate:a", 0.95, 0.22)
	ht.tween_property(shield_hex, "scale", Vector2(1.0, 1.0), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var lt := shield_hex_lines.create_tween().set_parallel(true)
	lt.tween_property(shield_hex_lines, "modulate:a", 0.55, 0.28)
	lt.tween_property(shield_hex_lines, "scale", Vector2(1.0, 1.0), 0.34)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
	var t := shield_root.create_tween().set_parallel(true)
	t.tween_property(shield_hex, "modulate:a", 0.0, 0.2)
	t.tween_property(shield_hex_lines, "modulate:a", 0.0, 0.2)
	t.tween_property(shield_feet_ring, "modulate:a", 0.0, 0.2)
	t.chain().tween_callback(func():
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
## Aether Pulse — full Charge -> Release -> Travel -> Impact -> Fade sequence.
## Self-targeted (heal + void shield), so "Travel/Impact" converge the energy
## into the point in front of the caster where the void shield forms, rather
## than flying out to the enemy. API/logic unchanged — visuals only.
func play_aether_pulse() -> void:
	var cast_pos := player_pos + Vector2(0, -10)     # hands/chest — where energy gathers
	var form_pos := player_pos + Vector2(34, -6)      # where the void shield forms — "impact" point

	# ── 0. BACKGROUND — ease the vignette in to frame the cutscene ──
	cutscene_backdrop_in(0.24, 0.24)

	# ── 1. ENERGY CHARGE — rotating ring + rising particles at the cast point ──
	var ring := Sprite2D.new()
	ring.texture   = _tex_ring
	ring.position  = cast_pos
	ring.modulate  = Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0)
	ring.scale     = Vector2(0.15, 0.15)
	ring.z_index   = 14
	add_child(ring)
	var rt := ring.create_tween().set_parallel(true)
	rt.tween_property(ring, "modulate:a", 0.85, 0.28)
	rt.tween_property(ring, "scale", Vector2(0.55, 0.55), 0.32)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Layered magical energy rising at the cast point (replaces the old
	# spinning ring look); the ring stays as a soft glow underneath.
	rising_energy(player_pos + Vector2(6, 34), COL_VIOLET, 5, 150.0)

	var charge := _spawn_particles(cast_pos, COL_VIOLET, {
		"amount": 26, "lifetime": 0.55, "one_shot": true,
		"dir": Vector3(0, -1, 0), "spread": 26.0, "gravity": Vector3(0, -40, 0),
		"ring": 46.0, "vmin": 40.0, "vmax": 90.0,
		"scale_min": 0.4, "scale_max": 0.9, "texture": _tex_dot,
	})

	await get_tree().create_timer(0.32).timeout
	if not is_instance_valid(self): return

	# ── 2. SKILL RELEASE — the charge ring flares and pops ──
	speed_lines(player_pos + Vector2(10, -20), COL_VIOLET, 9)
	var flash_t := ring.create_tween().set_parallel(true)
	flash_t.tween_property(ring, "modulate", Color(2.2, 2.0, 2.6, 1.0), 0.08)
	flash_t.tween_property(ring, "scale", Vector2(0.75, 0.75), 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spawn_particles(cast_pos, COL_VIOLET, {
		"amount": 34, "lifetime": 0.4, "one_shot": true, "explosive": true,
		"spread": 180.0, "vmin": 60.0, "vmax": 160.0,
		"scale_min": 0.5, "scale_max": 1.1, "texture": _tex_dot,
	})

	# ── 3. TRAVEL EFFECT — energy arcs from the hands into the shield point ──
	var trail := Line2D.new()
	trail.width = 4.0
	trail.z_index = 13
	var trail_grad := Gradient.new()
	trail_grad.set_color(0, Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0))
	trail_grad.add_point(0.5, Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.9))
	trail_grad.set_color(1, Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0))
	trail.gradient = trail_grad
	trail.add_point(cast_pos)
	trail.add_point(cast_pos.lerp(form_pos, 0.5) + Vector2(0, -30))
	trail.add_point(form_pos)
	add_child(trail)
	var tt := trail.create_tween()
	tt.tween_interval(0.18)
	tt.tween_property(trail, "modulate:a", 0.0, 0.25)
	tt.tween_callback(trail.queue_free)

	await get_tree().create_timer(0.16).timeout
	if not is_instance_valid(self): return

	# ── 4. IMPACT — burst, shock ring, energy dust, camera punch, cyan hit flash ──
	for col in [COL_VIOLET, Color(1, 1, 1, 1)]:
		_spawn_particles(form_pos, col, {
			"amount": 24, "lifetime": 0.4, "one_shot": true, "explosive": true,
			"spread": 180.0, "vmin": 60.0, "vmax": 170.0,
			"scale_min": 0.5, "scale_max": 1.1, "texture": _tex_dot,
		})
	var dust := _spawn_particles(form_pos, COL_VIOLET, {
		"amount": 16, "lifetime": 0.7, "one_shot": true, "explosive": false,
		"spread": 180.0, "vmin": 15.0, "vmax": 45.0, "gravity": Vector3(0, -18, 0),
		"scale_min": 0.3, "scale_max": 0.7, "texture": _tex_dot,
	})
	_cleanup(dust, 1.0)

	var shock := Sprite2D.new()
	shock.texture  = _tex_ring_thin
	shock.position = form_pos
	shock.modulate = Color(1, 1, 1, 0.9)
	shock.scale    = Vector2(0.15, 0.15)
	shock.z_index  = 14
	add_child(shock)
	var st := shock.create_tween().set_parallel(true)
	st.tween_property(shock, "scale", Vector2(0.8, 0.8), 0.28)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	st.tween_property(shock, "modulate:a", 0.0, 0.3)
	st.chain().tween_callback(shock.queue_free)

	_camera_zoom(form_pos, 0.05, 0.28)
	shake(0.15, 5.0)
	_screen_color_flash(hit_flash, Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.28), 0.12)
	# Contact juice on the enemy so the skill reads as a real hit.
	hit_spark(enemy_pos, COL_VIOLET)
	enemy_hit_react(44.0)

	# Violet glow over the sprite (kept from the original effect)
	var glow := ColorRect.new()
	glow.color = Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0)
	glow.size = Vector2(200, 260)
	glow.position = player_pos - Vector2(100, 150)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var gt := glow.create_tween()
	gt.tween_property(glow, "color:a", 0.20, 0.2)
	gt.tween_interval(0.4)
	gt.tween_property(glow, "color:a", 0.0, 0.3)
	gt.tween_callback(glow.queue_free)

	# ── 5. FADE OUT — lingering embers dissolve ──
	var aftermath := _spawn_particles(form_pos, COL_VIOLET, {
		"amount": 26, "lifetime": 1.4, "one_shot": true, "explosive": false,
		"spread": 180.0, "vmin": 10.0, "vmax": 50.0, "gravity": Vector3(0, -16, 0),
		"scale_min": 0.4, "scale_max": 1.0, "texture": _tex_dot,
	})
	aftermath.modulate.a = 0.6
	_cleanup(aftermath, 1.8)
	_cleanup(ring, 0.6)
	_cleanup(charge, 0.9)

	# ── BACKGROUND — release the vignette so the field returns to normal ──
	cutscene_backdrop_out(0.32)

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
## Absolute Zero Formula — Charge -> Screen Darken -> Time Stop (0.08s) ->
## Release -> Massive Impact -> After Effect -> Fade Out. Fire-and-forget,
## same as before — the actual damage in _on_ultimate() is applied
## immediately and independently of this animation's timing.
func play_ultimate() -> void:
	# ── 1. ENERGY CHARGE — void energy gathers around the caster, a large
	# magic circle spreads out underfoot ──
	var floor_circle := Sprite2D.new()
	floor_circle.texture  = _tex_ring
	floor_circle.position = player_pos + Vector2(0, 52)
	floor_circle.modulate = Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0)
	floor_circle.scale    = Vector2(0.05, 0.02)
	floor_circle.z_index  = 8
	add_child(floor_circle)
	var fct := floor_circle.create_tween().set_parallel(true)
	fct.tween_property(floor_circle, "modulate:a", 0.85, 0.35)
	fct.tween_property(floor_circle, "scale", Vector2(1.3, 0.45), 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Slow, subtle ground rotation (ambient magic circle — not a fast
	# spinning wheel) plus a magical aura erupting upward past the caster.
	var fspin := floor_circle.create_tween().set_loops()
	fspin.tween_property(floor_circle, "rotation", TAU, 8.0).set_trans(Tween.TRANS_LINEAR)
	rising_energy(player_pos + Vector2(0, 40), COL_VIOLET, 7, 230.0, true)

	var orbit := _spawn_particles(player_pos, COL_VIOLET, {
		"amount": 28, "lifetime": 0.8, "one_shot": false,
		"ring": 58.0, "vmin": 8.0, "vmax": 20.0,
		"dir": Vector3(0, -1, 0), "spread": 30.0, "gravity": Vector3(0, -16, 0),
		"scale_min": 0.4, "scale_max": 0.9, "texture": _tex_dot,
	})

	await get_tree().create_timer(0.42).timeout
	if not is_instance_valid(self): return

	# ── 2. SCREEN DARKEN ──
	screen_flash.color = Color(0, 0, 0, 0.0)
	var dark_t := screen_flash.create_tween()
	dark_t.tween_property(screen_flash, "color", Color(0, 0, 0, 0.42), 0.16)

	await get_tree().create_timer(0.16).timeout
	if not is_instance_valid(self): return

	# ── 3. TIME STOP — a short held freeze-frame beat ──
	orbit.emitting = false
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(self): return

	# ── 4. ULTIMATE RELEASE — the circle flares, darkness clears, energy launches ──
	var release_t := floor_circle.create_tween()
	release_t.tween_property(floor_circle, "modulate", Color(2.4, 2.2, 2.6, 1.0), 0.08)
	var clear_t := screen_flash.create_tween()
	clear_t.tween_property(screen_flash, "color:a", 0.0, 0.14)

	var beam := Line2D.new()
	beam.width   = 14.0
	beam.z_index = 15
	var beam_grad := Gradient.new()
	beam_grad.set_color(0, Color(COL_VIOLET.r, COL_VIOLET.g, COL_VIOLET.b, 0.0))
	beam_grad.add_point(0.5, Color(1, 1, 1, 0.95))
	beam_grad.set_color(1, Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.0))
	beam.gradient = beam_grad
	beam.add_point(player_pos + Vector2(70, -20))
	beam.add_point(enemy_pos)
	add_child(beam)
	var bt := beam.create_tween()
	bt.tween_interval(0.12)
	bt.tween_property(beam, "modulate:a", 0.0, 0.2)
	bt.tween_callback(beam.queue_free)

	_cleanup(orbit, 0.3)
	_cleanup(floor_circle, 0.4)

	await get_tree().create_timer(0.10).timeout
	if not is_instance_valid(self): return

	# ── 5. MASSIVE IMPACT — shockwave, bloom halo, explosion, heavy shake + zoom, hit flash ──
	var shock := Sprite2D.new()
	shock.texture  = _tex_ring_thin
	shock.position = enemy_pos
	shock.modulate = Color(1, 1, 1, 1.0)
	shock.scale    = Vector2(0.1, 0.1)
	shock.z_index  = 16
	add_child(shock)
	var sht := shock.create_tween().set_parallel(true)
	sht.tween_property(shock, "scale", Vector2(3.0, 3.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sht.tween_property(shock, "modulate:a", 0.0, 0.4)
	sht.chain().tween_callback(shock.queue_free)

	# Soft additive halo standing in for bloom/distortion around the blast
	var bloom := Sprite2D.new()
	bloom.texture  = _tex_ring_thin
	bloom.position = enemy_pos
	bloom.modulate = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.55)
	bloom.scale    = Vector2(0.3, 0.3)
	var bmat := CanvasItemMaterial.new()
	bmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	bloom.material = bmat
	bloom.z_index = 15
	add_child(bloom)
	var bmt := bloom.create_tween().set_parallel(true)
	bmt.tween_property(bloom, "scale", Vector2(2.0, 2.0), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bmt.tween_property(bloom, "modulate:a", 0.0, 0.55)
	bmt.chain().tween_callback(bloom.queue_free)

	screen_flash.color = Color(1, 1, 1, 0.0)
	var sf := screen_flash.create_tween()
	sf.tween_property(screen_flash, "color", Color(1, 1, 1, 0.85), 0.10)
	sf.tween_property(screen_flash, "color", Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.25), 0.12)
	sf.tween_property(screen_flash, "color:a", 0.0, 0.25)

	shake(0.5, 16.0)
	_camera_zoom(enemy_pos, 0.07, 0.4)

	for col in [COL_VIOLET, Color(1, 1, 1, 1)]:
		_spawn_particles(enemy_pos, col, {
			"amount": 55, "lifetime": 0.7, "one_shot": true, "explosive": true,
			"spread": 180.0, "vmin": 100.0, "vmax": 420.0,
			"scale_min": 0.6, "scale_max": 1.7, "texture": _tex_dot,
		})

	await get_tree().create_timer(0.15).timeout
	if not is_instance_valid(self): return

	# ── 6. AFTER EFFECT — lingering embers and light dust ──
	var aftermath := _spawn_particles(enemy_pos, COL_VIOLET, {
		"amount": 34, "lifetime": 2.0, "one_shot": true, "explosive": false,
		"spread": 180.0, "vmin": 10.0, "vmax": 55.0, "gravity": Vector3(0, -18, 0),
		"scale_min": 0.4, "scale_max": 1.1, "texture": _tex_dot,
	})
	aftermath.modulate.a = 0.55
	var dust := _spawn_particles(enemy_pos, Color(0.9, 0.96, 1.0), {
		"amount": 18, "lifetime": 2.4, "one_shot": true, "explosive": false,
		"spread": 180.0, "vmin": 6.0, "vmax": 24.0, "gravity": Vector3(0, -10, 0),
		"scale_min": 0.2, "scale_max": 0.5, "texture": _tex_dot,
	})
	dust.modulate.a = 0.45

	# ── 7. FADE OUT ──
	_cleanup(aftermath, 2.4)
	_cleanup(dust, 2.8)


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

## Subtle converging speed lines around `center` to sell motion without
## covering the character. A handful of thin streaks sweep inward and fade.
func speed_lines(center: Vector2, color: Color = COL_CYAN, count: int = 9) -> void:
	for i in count:
		var ang := TAU * (float(i) / float(count)) + randf_range(-0.15, 0.15)
		var dir := Vector2(cos(ang), sin(ang))
		var far := center + dir * randf_range(230.0, 320.0)
		var near := center + dir * randf_range(120.0, 160.0)
		var ln := Line2D.new()
		ln.width = randf_range(2.0, 3.5)
		ln.default_color = Color(color.r, color.g, color.b, 0.0)
		ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ln.end_cap_mode = Line2D.LINE_CAP_ROUND
		ln.add_point(far)
		ln.add_point(near)
		ln.z_index = 3
		add_child(ln)
		var t := ln.create_tween()
		t.tween_property(ln, "modulate:a", 0.55, 0.1)
		t.tween_property(ln, "modulate:a", 0.0, 0.22)
		t.parallel().tween_property(ln, "position", dir * 40.0, 0.32)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_callback(ln.queue_free)


## Premium impact "hit spark" at `pos`: a bright core pop, a fast thin
## shock ring, and a few streak shards radiating out. ~0.35s, no time
## freeze — pure additive VFX to give the hit weight on contact.
func hit_spark(pos: Vector2, color: Color = COL_CYAN) -> void:
	# Bright white core that pops and vanishes fast.
	var core := Sprite2D.new()
	core.texture  = _tex_dot
	core.position = pos
	core.modulate = Color(2.4, 2.4, 2.4, 1.0)
	core.scale    = Vector2(0.2, 0.2)
	core.z_index  = 44
	add_child(core)
	var ct := core.create_tween().set_parallel(true)
	ct.tween_property(core, "scale", Vector2(1.1, 1.1), 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ct.tween_property(core, "modulate:a", 0.0, 0.18)
	ct.chain().tween_callback(core.queue_free)

	# Thin shock ring snapping outward.
	var ring := Sprite2D.new()
	ring.texture  = _tex_ring_thin
	ring.position = pos
	ring.modulate = Color(color.r, color.g, color.b, 0.95)
	ring.scale    = Vector2(0.1, 0.1)
	ring.z_index  = 43
	add_child(ring)
	var rt := ring.create_tween().set_parallel(true)
	rt.tween_property(ring, "scale", Vector2(0.7, 0.7), 0.25)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rt.tween_property(ring, "modulate:a", 0.0, 0.28)
	rt.chain().tween_callback(ring.queue_free)

	# Sharp streak shards flying off the impact point.
	_spawn_particles(pos, Color(1, 1, 1, 1), {
		"amount": 8, "lifetime": 0.28, "one_shot": true, "explosive": true,
		"spread": 180.0, "vmin": 220.0, "vmax": 460.0,
		"scale_min": 0.8, "scale_max": 1.6, "texture": _tex_streak,
	})

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
