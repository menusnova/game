extends Control

@onready var bar_shadow     : TextureRect    = $BarShadow
@onready var bar_frame      : TextureRect    = $BarFrame
@onready var bar_fill       : TextureRect    = $BarFrame/BarFill
@onready var bar_shine      : TextureRect    = $BarFrame/BarShine
@onready var bar_reflection : TextureRect    = $BarReflection
@onready var energy_burst   : TextureRect    = $EnergyBurst
@onready var glow_ring      : TextureRect    = $GlowRing
@onready var glow_core      : TextureRect    = $GlowCore
@onready var particles_trail: GPUParticles2D = $ParticlesTrail
@onready var particles_spark: GPUParticles2D = $ParticlesSpark
@onready var pct_label      : Label          = $PctLabel
@onready var msg_label      : Label          = $MsgLabel
@onready var quote_label    : Label          = $QuoteLabel
@onready var press_label    : Label          = $PressLabel
@onready var fade           : ColorRect      = $Fade
@onready var dot_timer      : Timer          = $DotTimer

const LOAD_DURATION : float  = 4.0
const NEXT_SCENE    : String = "res://main_menu.tscn"
const BAR_MAX_W     : float  = 880.0
const BAR_LEFT_X    : float  = 136.0
const BAR_Y         : float  = 582.0

const MESSAGES := [
	"SYNTHESIZING ELEMENTS",
	"CALIBRATING REACTOR",
	"LOADING PERIODIC TABLE",
	"CHARGING ELECTRON ORBITS",
	"STABILIZING COMPOUNDS",
	"REACTION COMPLETE",
]

const QUOTES := [
	"Every atom in your body was forged in the heart of a dying star.",
	"118 elements. Infinite combinations. One reaction changes everything.",
	"Matter cannot be created — only transformed.",
	"The universe runs on chemistry. So do you.",
	"Fuse. React. Evolve. The periodic table is your weapon.",
	"Science is the only alchemy that actually works.",
]

var progress  : float = 0.0
var dot_count : int   = 0
var done      : bool  = false
var can_press : bool  = false
var shine_x   : float = -120.0
var shine_delay: float = 0.8

func _ready() -> void:
	bar_fill.size.x         = 0.0
	bar_shine.modulate.a    = 0.0
	bar_reflection.size.x   = 0.0
	glow_ring.modulate.a    = 0.0
	glow_core.modulate.a    = 0.0
	energy_burst.modulate.a = 0.0
	quote_label.visible     = false
	press_label.visible     = false
	msg_label.text          = MESSAGES[0]
	pct_label.text          = "0%"

	# particles เริ่มที่ปลายซ้าย
	_move_particles(BAR_LEFT_X)
	particles_trail.emitting = true
	particles_spark.emitting = true

	fade.color = Color(0, 0, 0, 1)
	var t := create_tween()
	t.tween_property(fade, "color:a", 0.0, 1.0)

	dot_timer.start()
	_start_ring_pulse()
	_start_core_breathe()

func _process(delta: float) -> void:
	if done:
		return

	progress = minf(progress + delta / LOAD_DURATION, 1.0)
	var fw   := BAR_MAX_W * progress
	var tip_x := BAR_LEFT_X + fw

	# bar fill + reflection
	bar_fill.size.x       = fw
	bar_reflection.size.x = fw

	# particles ตามปลายบาร์
	_move_particles(tip_x)

	# glow ring + core + burst ติดปลาย
	glow_ring.position.x    = tip_x - glow_ring.size.x * 0.5
	glow_core.position.x    = tip_x - glow_core.size.x * 0.5
	energy_burst.position.x = tip_x - 24.0

	var show := clampf(progress * 5.0, 0.0, 1.0)
	glow_ring.modulate.a    = show
	glow_core.modulate.a    = show
	energy_burst.modulate.a = show * 0.75

	# labels
	pct_label.text = "%d%%" % int(progress * 100)
	var idx := clampi(int(progress * (MESSAGES.size()-1)), 0, MESSAGES.size()-2)
	msg_label.text = MESSAGES[idx] + ".".repeat(dot_count)

	# shine sweep
	shine_delay -= delta
	if shine_delay <= 0.0 and fw > 10.0:
		shine_x += fw * 1.6 * delta
		bar_shine.position.x = shine_x
		var st := (shine_x + 120.0) / (fw + 120.0)
		bar_shine.modulate.a = sin(clampf(st, 0.0, 1.0) * PI) * 0.9
		if shine_x > fw:
			shine_x              = -120.0
			shine_delay          = randf_range(0.7, 1.2)
			bar_shine.modulate.a = 0.0

	if progress >= 1.0:
		_finish()

func _move_particles(tip_x: float) -> void:
	particles_trail.position = Vector2(tip_x, BAR_Y)
	particles_spark.position = Vector2(tip_x, BAR_Y)

func _finish() -> void:
	done = true
	dot_timer.stop()
	msg_label.text = MESSAGES[-1]
	pct_label.text = "100%"
	particles_trail.emitting = false
	particles_spark.emitting = false

	await get_tree().create_timer(0.5).timeout

	var t1 := create_tween().set_parallel()
	t1.tween_property(bar_frame,      "modulate:a", 0.0, 0.6)
	t1.tween_property(bar_shadow,     "modulate:a", 0.0, 0.6)
	t1.tween_property(bar_reflection, "modulate:a", 0.0, 0.6)
	t1.tween_property(glow_ring,      "modulate:a", 0.0, 0.4)
	t1.tween_property(glow_core,      "modulate:a", 0.0, 0.4)
	t1.tween_property(energy_burst,   "modulate:a", 0.0, 0.4)
	t1.tween_property(msg_label,      "modulate:a", 0.0, 0.5)
	t1.tween_property(pct_label,      "modulate:a", 0.0, 0.5)
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

func _start_ring_pulse() -> void:
	var t := create_tween().set_loops()
	t.tween_property(glow_ring, "scale", Vector2(1.12, 1.12), 0.9).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(glow_ring, "scale", Vector2(0.93, 0.93), 0.9).set_ease(Tween.EASE_IN_OUT)

func _start_core_breathe() -> void:
	var t := create_tween().set_loops()
	t.tween_property(glow_core, "scale", Vector2(1.15, 1.15), 0.6).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(glow_core, "scale", Vector2(0.88, 0.88), 0.6).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	if not can_press:
		return
	var pressed := false
	if event is InputEventMouseButton and event.pressed:
		pressed = true
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = true
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
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
