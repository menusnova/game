extends Node2D
# ════════════════════════════════════════════════════════════
#  CHEMIA — Element Card Effect System
#  Plays the FormulaCircle / particle / floating-text feedback
#  when two element cards are mixed in battle.
#  Godot 4.7 syntax (await, not yield).
# ════════════════════════════════════════════════════════════

# ── CHEMIA palette ─────────────────────────────────────────
const COL_CYAN   := Color("#00EAFF")   # electric cyan
const COL_VIOLET := Color("#7F5AF0")   # void violet
const COL_MAGENTA:= Color("#FF3CAC")   # magenta
const COL_BLUE   := Color("#2B4FFF")   # royal blue
const COL_BLACK  := Color("#06061A")   # void black

const FORMULA_COLOR := {
	"Water": Color("#00EAFF"),
	"Salt":  Color("#7F5AF0"),
	"Rust":  Color("#FF3CAC"),
	"CO2":   Color(0.55, 0.55, 0.60),
	"NO":    Color(0.35, 0.50, 0.95),
	"SO2":   Color(1.00, 0.85, 0.10),
	"CaO":   Color(0.80, 0.75, 0.65),
	"MgO":   Color(0.60, 0.85, 0.60),
	"K2O":   Color(0.75, 0.30, 0.70),
}
const FORMULA_LABEL := {
	"Water": "Water  H₂O",
	"Salt":  "Salt  NaCl",
	"Rust":  "Rust  Fe₂O₃",
	"CO2":   "Carbon Dioxide  CO₂",
	"NO":    "Nitric Oxide  NO",
	"SO2":   "Sulfur Dioxide  SO₂",
	"CaO":   "Calcium Oxide  CaO",
	"MgO":   "Magnesium Oxide  MgO",
	"K2O":   "Potassium Oxide  K₂O",
}
const EFFECT_TEXT := {
	"Water": "+20 HP",
	"Salt":  "Shield +20",
	"Rust":  "Poison +5/turn",
	"CO2":   "DEF -20%",
	"NO":    "ATK -20%",
	"SO2":   "Poison +4/turn",
	"CaO":   "Shield +15",
	"MgO":   "+15 HP",
	"K2O":   "ATK +20%",
}
const EFFECT_TEXT_COLOR := {
	"Water": Color(0.35, 1.0, 0.55),
	"Salt":  Color(0.95, 0.95, 1.0),
	"Rust":  Color(1.0, 0.55, 0.75),
	"CO2":   Color(1.0, 0.6, 0.6),
	"NO":    Color(1.0, 0.6, 0.6),
	"SO2":   Color(1.0, 0.55, 0.75),
	"CaO":   Color(0.95, 0.95, 1.0),
	"MgO":   Color(0.35, 1.0, 0.55),
	"K2O":   Color(1.0, 0.85, 0.4),
}

# Reactions whose effect lands on the enemy (debuffs/poison) instead of the
# player (heal/shield/buff) — drives where the craft/use VFX plays.
const ENEMY_TARGETED := ["Rust", "CO2", "NO", "SO2"]

# ── Anchor points (battle_scene.gd screen-space, 1152×648) ──
@export var player_pos: Vector2 = Vector2(160, 440)
@export var enemy_pos:  Vector2 = Vector2(560, 200)

# ── Nodes (built in _ready, matching the ElementCardSystem tree) ──
var formula_circle: Node2D
var circle_sprite:  Sprite2D
var rotate_anim:    AnimationPlayer
var water_fx:       GPUParticles2D
var salt_fx:        GPUParticles2D
var rust_fx:        GPUParticles2D
var floating_label: Label
var shield_ring:     Control

var _busy := false


func _ready() -> void:
	_build_formula_circle()
	water_fx = _build_particles("WaterEffect", COL_CYAN)
	salt_fx  = _build_particles("SaltEffect",  Color(0.95, 0.95, 1.0))
	rust_fx  = _build_particles("RustEffect",  COL_MAGENTA)
	_build_floating_label()
	_build_shield_ring()


# ════════════════════════════════════════════════════════════
#  PUBLIC API
# ════════════════════════════════════════════════════════════

## Plays ONLY the "formula crafted" feedback (circle + label) when two element
## cards are mixed into a reaction card. No stat effect has happened yet at
## this point — the player still has to play the resulting card — so this
## must NOT show the +HP/Shield/Poison numbers or particle bursts.
func play_craft(result: String) -> void:
	if _busy: return
	_busy = true
	var pos: Vector2 = enemy_pos if result in ENEMY_TARGETED else player_pos
	await _show_formula_circle(pos, FORMULA_COLOR[result])
	var label_off: Vector2 = Vector2(0, -90) if result in ENEMY_TARGETED else Vector2(0, -110)
	_spawn_floating_label(FORMULA_LABEL[result], pos + label_off, FORMULA_COLOR[result], 15, 1.1)
	await get_tree().create_timer(0.5).timeout
	await _hide_formula_circle()
	_busy = false


## Plays the actual effect feedback (particles + number popup) at the moment
## the crafted reaction card is played, when the stat change really happens.
func play_use(result: String) -> void:
	if _busy: return
	_busy = true
	match result:
		"Water": await _play_water()
		"Salt":  await _play_salt()
		"Rust":  await _play_rust()
		_:       await _play_generic(result)
	_busy = false


## Plays the faint "No Reaction" feedback for a mismatched pair.
func play_no_reaction() -> void:
	var mid := (player_pos + enemy_pos) * 0.5
	_spawn_floating_label("No Reaction", mid, Color(1, 1, 1, 0.35), 14, 0.9)


# ════════════════════════════════════════════════════════════
#  PER-FORMULA SEQUENCES (played when the reaction card is USED)
# ════════════════════════════════════════════════════════════
func _play_water() -> void:
	water_fx.global_position = player_pos
	water_fx.restart()
	water_fx.emitting = true
	_spawn_floating_label(EFFECT_TEXT["Water"], player_pos + Vector2(0, -40), EFFECT_TEXT_COLOR["Water"], 20, 1.0)
	await get_tree().create_timer(0.65).timeout


func _play_salt() -> void:
	salt_fx.global_position = player_pos
	salt_fx.restart()
	salt_fx.emitting = true
	_play_shield_ring(player_pos, FORMULA_COLOR["Salt"])
	_spawn_floating_label(EFFECT_TEXT["Salt"], player_pos + Vector2(0, -40), EFFECT_TEXT_COLOR["Salt"], 18, 1.0)
	await get_tree().create_timer(0.65).timeout


func _play_rust() -> void:
	rust_fx.global_position = enemy_pos
	rust_fx.restart()
	rust_fx.emitting = true
	_spawn_floating_label(EFFECT_TEXT["Rust"], enemy_pos + Vector2(0, -20), EFFECT_TEXT_COLOR["Rust"], 16, 1.0)
	await get_tree().create_timer(0.65).timeout


## Fallback used-effect feedback for any reaction without a bespoke sequence
## above — a particle burst in the formula's own color plus its EFFECT_TEXT
## popup, built on demand instead of a dedicated persistent emitter.
func _play_generic(result: String) -> void:
	var pos: Vector2 = enemy_pos if result in ENEMY_TARGETED else player_pos
	var col: Color = FORMULA_COLOR.get(result, COL_CYAN)
	var fx := _build_particles("GenericEffect", col)
	add_child(fx)
	fx.global_position = pos
	fx.restart()
	fx.emitting = true
	_spawn_floating_label(EFFECT_TEXT.get(result, ""), pos + Vector2(0, -30), EFFECT_TEXT_COLOR.get(result, col), 17, 1.0)
	await get_tree().create_timer(0.65).timeout
	fx.queue_free()


# ════════════════════════════════════════════════════════════
#  FORMULA CIRCLE
# ════════════════════════════════════════════════════════════
func _build_formula_circle() -> void:
	formula_circle = Node2D.new()
	formula_circle.name = "FormulaCircle"
	formula_circle.visible = false
	add_child(formula_circle)

	circle_sprite = Sprite2D.new()
	circle_sprite.name = "CircleSprite"
	circle_sprite.texture = _make_ring_texture(200)
	formula_circle.add_child(circle_sprite)

	rotate_anim = AnimationPlayer.new()
	rotate_anim.name = "RotateAnim"
	var anim := Animation.new()
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("CircleSprite:rotation"))
	anim.track_insert_key(track, 0.0, 0.0)
	anim.track_insert_key(track, 2.0, TAU)
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = 2.0
	var lib := AnimationLibrary.new()
	lib.add_animation("spin", anim)
	rotate_anim.add_animation_library("", lib)
	formula_circle.add_child(rotate_anim)


func _show_formula_circle(pos: Vector2, color: Color) -> void:
	formula_circle.position = pos
	formula_circle.visible  = true
	circle_sprite.modulate   = Color(color.r, color.g, color.b, 0.0)
	circle_sprite.scale      = Vector2(0.3, 0.3)
	rotate_anim.play("spin")

	var t := create_tween().set_parallel(true)
	t.tween_property(circle_sprite, "modulate:a", 0.9, 0.22)
	t.tween_property(circle_sprite, "scale", Vector2(1.0, 1.0), 0.28)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await t.finished


func _hide_formula_circle() -> void:
	var t := create_tween()
	t.tween_property(circle_sprite, "modulate:a", 0.0, 0.3)
	await t.finished
	rotate_anim.stop()
	formula_circle.visible = false


## Procedurally draws a 200×200 glowing ring so no external art asset is required.
func _make_ring_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var outer  := size * 0.5 - 6.0
	var inner  := outer * 0.86
	var inner2 := outer * 0.68
	var outer2 := outer * 0.74
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center)
			var a := 0.0
			a = maxf(a, _ring_alpha(d, inner, outer))
			a = maxf(a, _ring_alpha(d, inner2, outer2) * 0.6)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _ring_alpha(d: float, inner: float, outer: float) -> float:
	if d < inner - 3.0 or d > outer + 3.0: return 0.0
	if d >= inner and d <= outer: return 1.0
	if d < inner: return 1.0 - (inner - d) / 3.0
	return 1.0 - (d - outer) / 3.0


# ════════════════════════════════════════════════════════════
#  SHIELD RING (Salt)
# ════════════════════════════════════════════════════════════
func _build_shield_ring() -> void:
	shield_ring = Control.new()
	shield_ring.name = "SaltShieldRing"
	shield_ring.visible = false
	shield_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shield_ring)

	var ring := Panel.new()
	ring.name = "Ring"
	ring.size = Vector2(160, 160)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(FORMULA_COLOR["Salt"].r, FORMULA_COLOR["Salt"].g, FORMULA_COLOR["Salt"].b, 0.0)
	sb.border_color = Color(1, 1, 1, 0.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(80)
	ring.add_theme_stylebox_override("panel", sb)
	shield_ring.add_child(ring)


func _play_shield_ring(pos: Vector2, color: Color) -> void:
	var ring: Panel = shield_ring.get_node("Ring")
	var sb: StyleBoxFlat = ring.get_theme_stylebox("panel")
	shield_ring.position = pos - Vector2(80, 80)
	shield_ring.visible = true
	sb.bg_color     = Color(color.r, color.g, color.b, 0.0)
	sb.border_color = Color(1, 1, 1, 0.0)
	var t := create_tween().set_parallel(true)
	t.tween_property(sb, "bg_color:a", 0.20, 0.2)
	t.tween_property(sb, "border_color:a", 0.85, 0.2)
	t.chain().tween_interval(0.5)
	t.chain().tween_property(sb, "bg_color:a", 0.0, 0.3)
	t.parallel().tween_property(sb, "border_color:a", 0.0, 0.3)
	t.chain().tween_callback(func(): shield_ring.visible = false)


# ════════════════════════════════════════════════════════════
#  PARTICLES
# ════════════════════════════════════════════════════════════
func _build_particles(node_name: String, color: Color) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.name = node_name
	p.one_shot = true
	p.emitting = false
	p.amount = 28
	p.lifetime = 0.8
	p.explosiveness = 0.85
	p.z_index = 5

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 46.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.gravity = Vector3(0, -40, 0)
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 60.0
	mat.scale_min = 0.5
	mat.scale_max = 1.2
	mat.color = color

	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.r, color.g, color.b, 0.0))
	ramp.add_point(0.15, Color(color.r, color.g, color.b, 1.0))
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	mat.color_ramp = ramp_tex

	match node_name:
		"WaterEffect":
			# Droplets converge inward toward the character
			mat.direction = Vector3(0, 1, 0)
			mat.gravity = Vector3(0, 90, 0)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			mat.emission_ring_radius = 70.0
			mat.emission_ring_inner_radius = 60.0
			mat.emission_ring_height = 1.0
			mat.emission_ring_axis = Vector3(0, 0, 1)
		"SaltEffect":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			mat.emission_ring_radius = 78.0
			mat.emission_ring_inner_radius = 70.0
			mat.emission_ring_height = 1.0
			mat.emission_ring_axis = Vector3(0, 0, 1)
			mat.gravity = Vector3(0, 0, 0)
			mat.initial_velocity_min = 4.0
			mat.initial_velocity_max = 14.0
		"RustEffect":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			mat.emission_sphere_radius = 60.0
			mat.gravity = Vector3(0, -30, 0)
			mat.initial_velocity_min = 8.0
			mat.initial_velocity_max = 26.0

	p.process_material = mat
	p.texture = _make_dot_texture()
	add_child(p)
	return p


func _make_dot_texture() -> ImageTexture:
	var size := 8
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center) / (size * 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


# ════════════════════════════════════════════════════════════
#  FLOATING LABEL
# ════════════════════════════════════════════════════════════
func _build_floating_label() -> void:
	floating_label = Label.new()
	floating_label.name = "FloatingLabel"
	floating_label.visible = false
	floating_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(floating_label)


## Spawns a standalone floating label so overlapping calls (e.g. formula name + amount)
## can animate independently instead of fighting over the single FloatingLabel node.
func _spawn_floating_label(text: String, pos: Vector2, color: Color, font_size: int, hold: float) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(color.r, color.g, color.b, 0.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 30
	lbl.position = pos - Vector2(90, 10)
	lbl.size = Vector2(180, 24)
	add_child(lbl)

	var t := create_tween().set_parallel(true)
	t.tween_property(lbl, "theme_override_colors/font_color:a", 1.0, 0.18)
	t.tween_property(lbl, "position:y", lbl.position.y - 46.0, hold + 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(lbl, "theme_override_colors/font_color:a", 0.0, 0.3)
	await t.finished
	lbl.queue_free()
