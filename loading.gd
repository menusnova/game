extends Control

# ── Node refs ──────────────────────────────────────────────────────────────
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

# ── Settings ───────────────────────────────────────────────────────────────
const LOAD_DURATION : float  = 4.0
const NEXT_SCENE    : String = "res://main_menu.tscn"

const BAR_X    : float = 80.0
const BAR_Y    : float = 562.0
const BAR_W    : float = 992.0
const BAR_H    : float = 44.0
const RING_SIZE: float = 140.0

const MAX_SPARKS : int = 18

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
var progress    : float = 0.0
var dot_count   : int   = 0
var done        : bool  = false
var can_press   : bool  = false
var shader_time : float = 0.0
var pulse_time  : float = 0.0
var bar_alpha   : float = 1.0

# sparkles ภายในหลอด
var sparks : Array = []

# ──────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	plasma_ring.modulate.a   = 0.0
	glow_core.modulate.a     = 0.0
	quote_label.visible      = false
	press_label.visible      = false
	msg_label.text           = MESSAGES[0]
	pct_label.text           = "◇ 0% ◇"
	particles_trail.emitting = true
	particles_spark.emitting = true
	_move_particles(BAR_X)

	for i in range(MAX_SPARKS):
		sparks.append(_new_spark(randf()))

	fade.color = Color(0, 0, 0, 1)
	var t := create_tween()
	t.tween_property(fade, "color:a", 0.0, 1.2)
	dot_timer.start()


func _process(delta: float) -> void:
	shader_time += delta
	pulse_time  += delta

	_update_sparks(delta)

	if not done:
		progress = minf(progress + delta / LOAD_DURATION, 1.0)

		var fw    : float = BAR_W * progress
		var tip_x : float = BAR_X + fw
		var bar_cy: float = BAR_Y + BAR_H * 0.5
		var show  : float = clampf(progress * 5.0, 0.0, 1.0)

		plasma_ring.position   = Vector2(tip_x - RING_SIZE * 0.5, bar_cy - RING_SIZE * 0.5)
		var gs := glow_core.size
		glow_core.position     = Vector2(tip_x - gs.x * 0.5, bar_cy - gs.y * 0.5)
		plasma_ring.modulate.a = show
		glow_core.modulate.a   = show

		var mat := plasma_ring.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("time", shader_time)
			mat.set_shader_parameter("show", show)

		_move_particles(tip_x)

		pct_label.text = "◇ %d%% ◇" % int(progress * 100)
		var idx := clampi(int(progress * (MESSAGES.size() - 1)), 0, MESSAGES.size() - 2)
		msg_label.text = MESSAGES[idx] + ".".repeat(dot_count)

		if progress >= 1.0:
			_finish()

	bar_layer.queue_redraw()


# ── Sparkle system ─────────────────────────────────────────────────────────
func _new_spark(t: float = 0.0) -> Dictionary:
	return {
		"x"     : BAR_X + BAR_W * t,
		"y"     : BAR_Y + randf_range(BAR_H * 0.15, BAR_H * 0.85),
		"speed" : randf_range(30.0, 120.0),
		"size"  : randf_range(1.2, 3.0),
		"phase" : randf() * TAU,
		"freq"  : randf_range(3.0, 7.0),
	}


func _update_sparks(delta: float) -> void:
	var fill_end : float = BAR_X + BAR_W * progress
	for i in range(sparks.size()):
		sparks[i]["x"] += sparks[i]["speed"] * delta
		if sparks[i]["x"] > fill_end or sparks[i]["x"] > BAR_X + BAR_W:
			sparks[i] = _new_spark(0.0)


# ── Bar drawing (called from BarLayer child node) ──────────────────────────
func _draw_bar(cv: CanvasItem) -> void:
	if bar_alpha <= 0.0:
		return

	var fw    : float = BAR_W * progress
	var pulse : float = 0.85 + 0.15 * sin(pulse_time * 3.0)
	var a     : float = bar_alpha
	var r     : float = BAR_H * 0.5

	var track_rect := Rect2(BAR_X, BAR_Y, BAR_W, BAR_H)
	var fill_rect  := Rect2(BAR_X, BAR_Y, fw, BAR_H)

	# ── Track (พื้นหลังหลอด pill shape) ───────────────────────────────────
	_sbox(cv, track_rect.grow(2), Color(0.04, 0.10, 0.26, 0.80 * a), r + 2)
	_sbox(cv, track_rect,         Color(0.01, 0.04, 0.14, 1.00 * a), r)
	# inner rim เส้นขอบในจาง
	_sbox(cv, track_rect.grow(-1), Color(0.08, 0.22, 0.55, 0.25 * a), r - 1, true, 1.0)

	if fw < 2.0:
		return

	# ── Outer glow (แสงรอบบาร์) ───────────────────────────────────────────
	for i in range(7):
		var ex    : float = float(7 - i) * 5.0
		var alpha : float = (0.025 + i * 0.014) * pulse * a
		cv.draw_rect(Rect2(BAR_X, BAR_Y - ex, fw, BAR_H + ex * 2.0),
					 Color(0.05, 0.42, 1.00, alpha))

	# ── Floor bloom (แสงสะท้อนใต้หลอด) ──────────────────────────────────
	for i in range(5):
		var ry    : float = BAR_Y + BAR_H + float(i) * 5.0
		var alpha : float = (0.09 - i * 0.016) * pulse * a
		if alpha <= 0.0:
			break
		cv.draw_rect(Rect2(BAR_X + 8, ry, fw - 8, 4.0),
					 Color(0.10, 0.55, 1.00, alpha))

	# ── Fill pill (gradient: navy → cyan ซ้ายไปขวา) ──────────────────────
	var steps : int = 20
	for s in range(steps):
		var t0 : float = float(s)     / float(steps)
		var t1 : float = float(s + 1) / float(steps)
		var tm : float = (t0 + t1) * 0.5
		var col := Color(
			lerp(0.05, 0.22, tm),
			lerp(0.42, 0.88, tm) * 0.72,
			1.00,
			a
		)
		var sx : float = BAR_X + fw * t0
		var sw : float = fw * (t1 - t0) + 1.5
		cv.draw_rect(Rect2(sx, BAR_Y, sw, BAR_H), col)

	# วาด pill mask ทับเพื่อให้ขอบโค้งมน
	_sbox(cv, fill_rect, Color(0, 0, 0, 0), r)

	# ── Top highlight ─────────────────────────────────────────────────────
	_sbox(cv, Rect2(BAR_X, BAR_Y, fw, BAR_H * 0.32),
		  Color(0.80, 0.97, 1.00, 0.42 * a), r)
	cv.draw_line(
		Vector2(BAR_X + r, BAR_Y + 1.5),
		Vector2(BAR_X + fw - 1, BAR_Y + 1.5),
		Color(1.0, 1.0, 1.0, 0.35 * a), 1.5
	)

	# ── Sparkles ในหลอด ───────────────────────────────────────────────────
	for sp in sparks:
		var sx : float = sp["x"]
		if sx < BAR_X or sx > BAR_X + fw:
			continue
		var sp_alpha : float = (0.4 + 0.6 * sin(pulse_time * sp["freq"] + sp["phase"])) * a
		var sz       : float = sp["size"]
		cv.draw_circle(Vector2(sx, sp["y"]), sz,
					   Color(0.75, 0.95, 1.0, sp_alpha * 0.9))
		# inner bright core
		cv.draw_circle(Vector2(sx, sp["y"]), sz * 0.4,
					   Color(1.0, 1.0, 1.0, sp_alpha))

	# ── Frame border ──────────────────────────────────────────────────────
	_sbox(cv, track_rect,         Color(0.30, 0.78, 1.00, 0.72 * a), r, true, 1.5)
	_sbox(cv, track_rect.grow(1), Color(0.10, 0.42, 0.90, 0.25 * a), r + 1, true, 1.0)


# ── StyleBoxFlat helper ────────────────────────────────────────────────────
func _sbox(cv: CanvasItem, rect: Rect2, color: Color, radius: float,
		   border_only: bool = false, border_w: float = 0.0) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	var sb := StyleBoxFlat.new()
	var ri : int = int(minf(radius, minf(rect.size.x * 0.5, rect.size.y * 0.5)))
	sb.set_corner_radius_all(ri)
	if border_only and border_w > 0.0:
		sb.bg_color        = Color(0, 0, 0, 0)
		sb.border_color    = color
		sb.set_border_width_all(int(border_w))
		sb.draw_center     = false
	else:
		sb.bg_color = color
	sb.draw(cv.get_canvas_item(), rect)


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
		func(v: float) -> void:
			bar_alpha = v,
		1.0, 0.0, 0.6
	)
	await get_tree().create_timer(0.7).timeout

	quote_label.text       = QUOTES[randi() % QUOTES.size()]
	quote_label.visible    = true
	quote_label.modulate.a = 0.0
	press_label.visible    = true
	press_label.modulate.a = 0.0

	var t2 := create_tween()
	t2.tween_property(quote_label, "modulate:a", 1.0, 0.9)
	await t2.finished
	await get_tree().create_timer(0.5).timeout

	var t3 := create_tween().set_loops()
	t3.tween_property(press_label, "modulate:a", 1.0, 0.55)
	t3.tween_property(press_label, "modulate:a", 0.1, 0.55)
	can_press = true


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


func _go() -> void:
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.9)
	await t.finished
	get_tree().change_scene_to_file(NEXT_SCENE)


func _on_dot_timer_timeout() -> void:
	dot_count = (dot_count + 1) % 4
