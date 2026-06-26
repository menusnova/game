extends Control

# ── Node refs ──────────────────────────────────────────────────────────────
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

	fade.color = Color(0, 0, 0, 1)
	var t := create_tween()
	t.tween_property(fade, "color:a", 0.0, 1.2)
	dot_timer.start()


func _process(delta: float) -> void:
	if done:
		return

	progress    = minf(progress + delta / LOAD_DURATION, 1.0)
	shader_time += delta
	pulse_time  += delta

	var fw    := BAR_W * progress
	var tip_x := BAR_X + fw
	var bar_cy := BAR_Y + BAR_H * 0.5
	var show  := clampf(progress * 5.0, 0.0, 1.0)

	# Plasma ring + glow core ติดปลายบาร์
	plasma_ring.position = Vector2(tip_x - RING_SIZE * 0.5, bar_cy - RING_SIZE * 0.5)
	var gs := glow_core.size
	glow_core.position   = Vector2(tip_x - gs.x * 0.5, bar_cy - gs.y * 0.5)
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

	queue_redraw()

	if progress >= 1.0:
		_finish()


# ── Custom draw (วาดบาร์ทั้งหมดด้วย code) ─────────────────────────────────
func _draw() -> void:
	var fw    := BAR_W * progress
	var pulse := 0.85 + 0.15 * sin(pulse_time * 3.0)
	var fill  := Rect2(BAR_X, BAR_Y, fw, BAR_H)
	var track := Rect2(BAR_X, BAR_Y, BAR_W, BAR_H)
	var r     := BAR_H * 0.5

	# ── Track (ร่องบาร์พื้นหลัง) ─────────────────────────────────────────
	_pill(track.grow(3), Color(0.04, 0.09, 0.22, 0.85), r + 3)
	_pill(track,         Color(0.01, 0.04, 0.12, 1.00), r)
	# inner rim
	_pill(track.grow(-1), Color(0.06, 0.18, 0.45, 0.30), r - 1, false, 1.0)

	if fw < 2.0:
		return

	# ── Outer glow layers (ออร่าเรืองแสงรอบๆ บาร์) ────────────────────
	for i in range(8):
		var ex    := float(8 - i) * 4.0
		var alpha := (0.04 + i * 0.016) * pulse
		_pill(fill.grow(ex), Color(0.05, 0.42, 1.00, alpha), r + ex)

	# ── Floor bloom (แสงสะท้อนใต้บาร์) ──────────────────────────────────
	for i in range(6):
		var ry    := BAR_Y + BAR_H + float(i) * 5.0
		var alpha := (0.11 - i * 0.017) * pulse
		if alpha <= 0.0:
			break
		draw_rect(Rect2(BAR_X + 10, ry, fw - 10, 4.0), Color(0.1, 0.55, 1.0, alpha))

	# ── Fill gradient (deep navy → bright cyan, left to right) ───────────
	var steps := 16
	for s in range(steps):
		var t0  := float(s)     / float(steps)
		var t1  := float(s + 1) / float(steps)
		var tm  := (t0 + t1) * 0.5
		var col := Color(
			lerp(0.06, 0.20, tm),
			lerp(0.45, 0.88, tm) * 0.70,
			1.0,
			1.0
		)
		var sx := BAR_X + BAR_W * t0 * progress
		var sw := BAR_W * (t1 - t0) * progress + 1.5
		draw_rect(Rect2(sx, BAR_Y, sw, BAR_H), col)

	# ── Top highlight strip ───────────────────────────────────────────────
	draw_rect(Rect2(BAR_X, BAR_Y, fw, BAR_H * 0.30), Color(0.80, 0.97, 1.0, 0.48))
	# razor-thin bright line at top edge
	draw_line(
		Vector2(BAR_X + 1, BAR_Y + 1.5),
		Vector2(BAR_X + fw - 1, BAR_Y + 1.5),
		Color(1.0, 1.0, 1.0, 0.40), 1.5
	)

	# ── Frame borders ─────────────────────────────────────────────────────
	_pill(track,         Color(0.30, 0.78, 1.00, 0.75), r, false, 1.5)
	_pill(track.grow(1), Color(0.10, 0.42, 0.90, 0.28), r + 1, false, 1.0)


# ── Helpers ────────────────────────────────────────────────────────────────

# วาด pill shape (สี่เหลี่ยมขอบมน) แบบ filled หรือ outline
func _pill(rect: Rect2, color: Color, corner: float,
		   filled: bool = true, width: float = 1.0) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	var r := minf(corner, minf(rect.size.x * 0.5, rect.size.y * 0.5))
	if r < 0.5:
		if filled: draw_rect(rect, color)
		else:      draw_rect(rect, color, false, width)
		return

	if filled:
		draw_rect(Rect2(rect.position.x + r, rect.position.y,
						rect.size.x - r * 2.0, rect.size.y), color)
		draw_rect(Rect2(rect.position.x, rect.position.y + r,
						rect.size.x, rect.size.y - r * 2.0), color)
		draw_circle(rect.position + Vector2(r,               r),               r, color)
		draw_circle(rect.position + Vector2(rect.size.x - r, r),               r, color)
		draw_circle(rect.position + Vector2(r,               rect.size.y - r), r, color)
		draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	else:
		var tl := rect.position + Vector2(r, r)
		var tr := rect.position + Vector2(rect.size.x - r, r)
		var bl := rect.position + Vector2(r, rect.size.y - r)
		var br := rect.position + Vector2(rect.size.x - r, rect.size.y - r)
		draw_line(tl + Vector2(0, -r), tr + Vector2(0, -r), color, width)
		draw_line(bl + Vector2(0,  r), br + Vector2(0,  r), color, width)
		draw_line(tl + Vector2(-r, 0), bl + Vector2(-r, 0), color, width)
		draw_line(tr + Vector2( r, 0), br + Vector2( r, 0), color, width)
		_arc(tl, r, PI,       PI * 1.5, color, width)
		_arc(tr, r, PI * 1.5, TAU,      color, width)
		_arc(bl, r, PI * 0.5, PI,       color, width)
		_arc(br, r, 0.0,      PI * 0.5, color, width)


func _arc(center: Vector2, radius: float, from_a: float, to_a: float,
		  color: Color, width: float = 1.0, segs: int = 12) -> void:
	var prev : Vector2 = center + Vector2(cos(from_a), sin(from_a)) * radius
	for i in range(1, segs + 1):
		var a    : float   = from_a + (to_a - from_a) * float(i) / float(segs)
		var next : Vector2 = center + Vector2(cos(a), sin(a)) * radius
		draw_line(prev, next, color, width)
		prev = next


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
