extends Control

# ── Node refs ──────────────────────────────────────────────────────────────
@onready var bar_fill_rect  : ColorRect      = $BarFillRect
@onready var bar_layer      : Control        = $BarLayer
@onready var plasma_ring    : ColorRect      = $PlasmaRing
@onready var glow_core      : TextureRect    = $GlowCore
@onready var particles_trail: GPUParticles2D = $ParticlesTrail
@onready var particles_spark: GPUParticles2D = $ParticlesSpark
@onready var msg_label      : Label          = $MsgLabel
@onready var pct_label      : Label          = $PctLabel
@onready var quote_label    : Label          = $QuoteLabel
@onready var press_label    : Label          = $PressLabel
@onready var fade           : ColorRect      = $Fade
@onready var dot_timer      : Timer          = $DotTimer

var bar_mat : ShaderMaterial

# ── Settings ───────────────────────────────────────────────────────────────
const LOAD_DURATION : float  = 4.0
const NEXT_SCENE    : String = "res://main_menu.tscn"

const BAR_X    : float = 80.0
const BAR_Y    : float = 562.0
const BAR_W    : float = 992.0
const BAR_H    : float = 44.0
const RING_SIZE: float = 140.0
const MAX_SPARKS: int  = 18

const MESSAGES : Array[String] = [
	"SYNTHESIZING ELEMENTS",
	"CALIBRATING REACTOR",
	"LOADING PERIODIC TABLE",
	"CHARGING ELECTRON ORBITS",
	"STABILIZING COMPOUNDS",
	"REACTION COMPLETE",
]

const QUOTES : Array[String] = [
	"Every atom in your body was forged in the heart of a dying star.",
	"118 elements. Infinite combinations. One reaction changes everything.",
	"Matter cannot be created — only transformed.",
	"The universe runs on chemistry. So do you.",
	"Fuse. React. Evolve. The periodic table is your weapon.",
	"Science is the only alchemy that actually works.",
]

# ── State ──────────────────────────────────────────────────────────────────
var progress        : float = 0.0
var dot_count       : int   = 0
var done            : bool  = false
var can_press       : bool  = false
var loading_started : bool  = false
var shader_time     : float = 0.0
var pulse_time      : float = 0.0
var bar_alpha       : float = 1.0
var sparks          : Array = []

# ──────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	bar_mat = bar_fill_rect.material as ShaderMaterial

	# Hide all bar/text elements — show only Background + Logo
	plasma_ring.modulate.a   = 0.0
	glow_core.modulate.a     = 0.0
	bar_fill_rect.modulate.a = 0.0
	bar_layer.modulate.a     = 0.0
	msg_label.modulate.a     = 0.0
	pct_label.modulate.a     = 0.0
	msg_label.text           = MESSAGES[0]
	pct_label.text           = "◇ 0% ◇"
	particles_trail.emitting = false
	particles_spark.emitting = false
	press_label.visible      = true
	quote_label.visible      = false
	quote_label.text         = QUOTES[randi() % QUOTES.size()]

	_move_particles(BAR_X)

	for i in range(MAX_SPARKS):
		sparks.append(_new_spark(randf()))

	bar_layer.draw.connect(_draw_bar.bind(bar_layer))

	fade.color = Color(0, 0, 0, 0)
	can_press = false   # ยังกดไม่ได้จนกว่าโหลดเสร็จ
	_start_loading()   # auto start หลัง 0.2 วิ


func _process(delta: float) -> void:
	shader_time += delta
	pulse_time  += delta

	_update_sparks(delta)
	bar_layer.queue_redraw()

	# Update shader
	var pulse : float = 0.85 + 0.15 * sin(pulse_time * 3.0)
	if bar_mat:
		bar_mat.set_shader_parameter("progress",  progress)
		bar_mat.set_shader_parameter("bar_alpha", bar_alpha)
		bar_mat.set_shader_parameter("pulse_val", pulse)
		bar_mat.set_shader_parameter("time_val",  shader_time)

	if done or not loading_started:
		return

	progress = minf(progress + delta / LOAD_DURATION, 1.0)

	var fw    : float = BAR_W * progress
	var tip_x : float = BAR_X + fw
	var bar_cy: float = BAR_Y + BAR_H * 0.5
	var show_alpha: float = clampf(progress * 5.0, 0.0, 1.0)

	# Plasma ring orb ที่ปลายบาร์
	plasma_ring.position   = Vector2(tip_x - RING_SIZE * 0.5, bar_cy - RING_SIZE * 0.5)
	var gs := glow_core.size
	glow_core.position     = Vector2(tip_x - gs.x * 0.5, bar_cy - gs.y * 0.5)
	plasma_ring.modulate.a = show_alpha
	glow_core.modulate.a   = show_alpha

	var ring_mat := plasma_ring.material as ShaderMaterial
	if ring_mat:
		ring_mat.set_shader_parameter("time", shader_time)
		ring_mat.set_shader_parameter("show", show_alpha)

	_move_particles(tip_x)

	pct_label.text = "◇ %d%% ◇" % int(progress * 100)
	var idx := clampi(int(progress * (MESSAGES.size() - 1)), 0, MESSAGES.size() - 2)
	msg_label.text = MESSAGES[idx] + ".".repeat(dot_count)

	if progress >= 1.0:
		_finish()


# ── Sparkles ───────────────────────────────────────────────────────────────
func _new_spark(t: float = 0.0) -> Dictionary:
	return {
		"x"    : BAR_X + BAR_W * t,
		"y"    : BAR_Y + randf_range(BAR_H * 0.15, BAR_H * 0.85),
		"speed": randf_range(25.0, 110.0),
		"size" : randf_range(1.0, 2.8),
		"phase": randf() * TAU,
		"freq" : randf_range(3.0, 7.0),
	}


func _update_sparks(delta: float) -> void:
	var fill_end : float = BAR_X + BAR_W * progress
	for i in range(sparks.size()):
		sparks[i]["x"] += sparks[i]["speed"] * delta
		if sparks[i]["x"] > fill_end:
			sparks[i] = _new_spark(0.0)


# ── Bar overlay draw (glow + sparkles, on top of shader bar) ──────────────
func _draw_bar(cv: CanvasItem) -> void:
	if bar_alpha <= 0.0 or progress < 0.01:
		return

	var fw    : float = BAR_W * progress
	var pulse : float = 0.85 + 0.15 * sin(pulse_time * 3.0)
	var a     : float = bar_alpha

	# Outer glow (soft, extends beyond bar — additive-style alpha)
	for i in range(8):
		var ex    : float = float(8 - i) * 4.5
		var alpha : float = (0.022 + i * 0.011) * pulse * a
		cv.draw_rect(Rect2(BAR_X, BAR_Y - ex, fw, BAR_H + ex * 2.0),
					 Color(0.05, 0.40, 1.00, alpha))

	# Floor bloom
	for i in range(5):
		var ry    : float = BAR_Y + BAR_H + float(i) * 5.0
		var alpha : float = (0.09 - float(i) * 0.016) * pulse * a
		if alpha <= 0.0:
			break
		cv.draw_rect(Rect2(BAR_X + 8.0, ry, fw - 8.0, 4.0),
					 Color(0.10, 0.55, 1.00, alpha))

	# Sparkles inside bar
	for sp in sparks:
		var sx : float = sp["x"]
		if sx < BAR_X or sx > BAR_X + fw:
			continue
		var sp_a : float = (0.3 + 0.7 * sin(pulse_time * sp["freq"] + sp["phase"])) * a
		if sp_a < 0.04:
			continue
		var sz : float = sp["size"]
		cv.draw_circle(Vector2(sx, sp["y"]), sz,       Color(0.70, 0.93, 1.0, sp_a * 0.80))
		cv.draw_circle(Vector2(sx, sp["y"]), sz * 0.38, Color(1.00, 1.00, 1.0, sp_a))


func _move_particles(tip_x: float) -> void:
	var py : float = BAR_Y + BAR_H * 0.5
	particles_trail.position = Vector2(tip_x, py)
	particles_spark.position = Vector2(tip_x, py)


func _finish() -> void:
	done = true
	dot_timer.stop()
	msg_label.text = MESSAGES[-1]
	pct_label.text = "◇ 100% ◇"
	particles_trail.emitting = false
	particles_spark.emitting = false

	await get_tree().create_timer(0.5).timeout

	var t1 := create_tween().set_parallel()
	t1.tween_property(plasma_ring, "modulate:a", 0.0, 0.6)
	t1.tween_property(glow_core,   "modulate:a", 0.0, 0.6)
	t1.tween_property(msg_label,   "modulate:a", 0.0, 0.5)
	t1.tween_property(pct_label,   "modulate:a", 0.0, 0.5)

	var bar_tween := create_tween()
	bar_tween.tween_method(
		func(v: float) -> void: bar_alpha = v,
		1.0, 0.0, 0.6
	)
	await get_tree().create_timer(0.7).timeout

	# แสดง quote และ press_label — รอให้ผู้เล่นกด
	quote_label.visible    = true
	quote_label.modulate.a = 0.0
	press_label.visible    = true
	press_label.modulate.a = 0.0

	var t2 := create_tween().set_parallel()
	t2.tween_property(quote_label, "modulate:a", 1.0, 0.9)
	t2.tween_property(press_label, "modulate:a", 1.0, 0.9)
	await t2.finished

	can_press = true   # เปิดให้กดได้หลังโหลดเสร็จแล้วเท่านั้น


func _input(event: InputEvent) -> void:
	if not can_press:
		return
	var pressed := false
	if event is InputEventMouseButton and event.pressed:                    pressed = true
	if event is InputEventKey         and event.pressed and not event.echo: pressed = true
	if event is InputEventScreenTouch and event.pressed:                    pressed = true
	if pressed:
		can_press = false
		_go()


func _start_loading() -> void:
	loading_started = true   # set ก่อน await กันการ trigger ซ้ำ
	press_label.visible = false
	await get_tree().create_timer(0.2).timeout

	# Fade in loading bar
	var t := create_tween().set_parallel()
	t.tween_property(bar_fill_rect, "modulate:a", 1.0, 0.4)
	t.tween_property(bar_layer,     "modulate:a", 1.0, 0.4)
	t.tween_property(msg_label,     "modulate:a", 1.0, 0.4)
	t.tween_property(pct_label,     "modulate:a", 1.0, 0.4)
	particles_trail.emitting = true
	particles_spark.emitting = true
	dot_timer.start()


func _go() -> void:
	SceneTransition.fade_to(NEXT_SCENE, 0.9)


func _on_dot_timer_timeout() -> void:
	dot_count = (dot_count + 1) % 4
