extends Node2D
## Futuristic magical barrier: two horizontal elliptical HUD rings (upper &
## lower body) built from many independent hand-placed pieces — segmented
## arcs, brackets, triangular/rect markers, guide lines and connectors —
## rotating slowly in opposite directions with subtle floating motion and
## light pulses. Silver-gray with faint cyan. Fully procedural (_draw).

const SILVER := Color(0.80, 0.84, 0.90)
const GRAY   := Color(0.52, 0.56, 0.64)
const WHITE  := Color(0.95, 0.97, 1.00)
const CYAN   := Color(0.55, 0.85, 1.00)

# Two rings: {cy, rx, ry, dir(rotation sign), pieces:Array}
var _rings: Array = []
var _phase := 0.0
var _bob := 0.0

func _ready() -> void:
	z_index = 9
	modulate.a = 0.0
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.seed = 20260726
	_rings = [
		_build_ring(-64.0, 138.0, 36.0,  1.0, seed_rng),   # upper body
		_build_ring( 44.0, 160.0, 44.0, -1.0, seed_rng),   # lower body
	]

## Generate one ring's worth of asymmetric pieces (no repeated identical
## segments — each gets slightly different span/offset/detail).
func _build_ring(cy, rx, ry, dir, rng: RandomNumberGenerator) -> Dictionary:
	var pieces: Array = []
	# 1. Concentric segmented arcs at a few radii, broken into uneven spans.
	for r_scale in [0.82, 1.0, 1.16]:
		var a := rng.randf_range(0.0, TAU)
		while a < TAU:
			var span := rng.randf_range(0.35, 0.9)
			pieces.append({"t": "arc", "a0": a, "a1": a + span, "r": r_scale,
				"w": rng.randf_range(1.2, 2.4), "c": SILVER if r_scale == 1.0 else GRAY,
				"al": rng.randf_range(0.5, 0.9)})
			a += span + rng.randf_range(0.28, 0.7)   # intentional gaps
	# 2. Thin inner guide line (nearly full, faint).
	pieces.append({"t": "arc", "a0": 0.2, "a1": TAU - 0.5, "r": 0.62,
		"w": 1.0, "c": GRAY, "al": 0.28})
	# 3. Angular brackets, triangular + rect markers, connectors at spots.
	var marker_count := 9
	for i in marker_count:
		var a: float = TAU * (float(i) / marker_count) + rng.randf_range(-0.12, 0.12)
		var kinds := ["bracket", "tri", "rect", "conn", "tick"]
		var k: String = kinds[rng.randi() % kinds.size()]
		pieces.append({"t": k, "a": a, "r": rng.randf_range(1.02, 1.24),
			"sz": rng.randf_range(6.0, 12.0),
			"c": CYAN if rng.randf() < 0.28 else SILVER,
			"al": rng.randf_range(0.55, 0.95)})
	# 4. A couple of asymmetric outer decorative long arcs.
	pieces.append({"t": "arc", "a0": rng.randf_range(0.0, TAU), "a1": 0.0, "r": 1.3,
		"w": 1.4, "c": CYAN, "al": 0.4})
	pieces[-1]["a1"] = pieces[-1]["a0"] + rng.randf_range(0.5, 1.1)
	return {"cy": cy, "rx": rx, "ry": ry, "dir": dir, "rot": rng.randf_range(0, TAU),
		"pieces": pieces, "spin": rng.randf_range(0.32, 0.42)}

func activate() -> void:
	visible = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE)

func dismiss() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func(): visible = false)

func _process(delta: float) -> void:
	if not visible: return
	_phase += delta
	_bob = sin(_phase * 1.3) * 3.0
	for ring in _rings:
		# Slight speed variation instead of constant mechanical spin.
		var spd: float = ring["spin"] * (1.0 + 0.18 * sin(_phase * 0.9 + ring["cy"]))
		ring["rot"] += ring["dir"] * spd * delta
	queue_redraw()

func _draw() -> void:
	for ring in _rings:
		_draw_ring(ring)

func _draw_ring(ring: Dictionary) -> void:
	var cx := 0.0
	var cy: float = ring["cy"] + _bob
	var rx: float = ring["rx"]
	var ry: float = ring["ry"]
	var rot: float = ring["rot"]
	# Travelling energy highlight sweeping the ring.
	var hi := fmod(_phase * 1.1 * ring["dir"] + ring["cy"], TAU)
	for p in ring["pieces"]:
		match p["t"]:
			"arc":
				_draw_arc_seg(cx, cy, rx, ry, rot, p, hi)
			"bracket":
				_draw_bracket(cx, cy, rx, ry, rot, p)
			"tri":
				_draw_tri(cx, cy, rx, ry, rot, p)
			"rect":
				_draw_marker_rect(cx, cy, rx, ry, rot, p)
			"conn":
				_draw_conn(cx, cy, rx, ry, rot, p)
			"tick":
				_draw_tick(cx, cy, rx, ry, rot, p)

func _pt(cx: float, cy: float, rx: float, ry: float, ang: float, rs := 1.0) -> Vector2:
	return Vector2(cx + rx * rs * cos(ang), cy + ry * rs * sin(ang))

## Front pieces (lower half of the ellipse on screen) read brighter for depth.
func _depth(ang: float) -> float:
	return lerp(0.45, 1.0, (sin(ang) + 1.0) * 0.5)

func _draw_arc_seg(cx, cy, rx, ry, rot: float, p: Dictionary, hi: float) -> void:
	var a0: float = p["a0"]
	var a1: float = p["a1"]
	var segs := maxi(4, int((a1 - a0) / 0.18))
	var pts := PackedVector2Array()
	for i in segs + 1:
		var t := a0 + (a1 - a0) * (float(i) / segs)
		pts.append(_pt(cx, cy, rx, ry, t + rot, p["r"]))
	var mid := (a0 + a1) * 0.5 + rot
	var col: Color = p["c"]
	# Brighten if the travelling highlight is passing over this segment.
	var near_hi: float = 1.0 - clampf(absf(fposmod(mid - hi + PI, TAU) - PI) / 0.6, 0.0, 1.0)
	var a: float = p["al"] * _depth(mid) + near_hi * 0.5
	draw_polyline(pts, Color(col.r, col.g, col.b, clampf(a, 0.0, 1.0)), p["w"], true)

func _draw_bracket(cx: float, cy: float, rx: float, ry: float, rot: float, p: Dictionary) -> void:
	var ang: float = p["a"] + rot
	var base := _pt(cx, cy, rx, ry, ang, p["r"])
	var tang := (_pt(cx, cy, rx, ry, ang + 0.05, p["r"]) - base).normalized()
	var out := (base - Vector2(cx, cy)).normalized()
	var s: float = p["sz"]
	var col: Color = p["c"]
	var a: float = p["al"] * _depth(ang)
	var c := Color(col.r, col.g, col.b, a)
	# An L / bracket: a tangent stroke with a short inward tick at each end.
	var e0 := base - tang * s
	var e1 := base + tang * s
	draw_line(e0, e1, c, 1.6, true)
	draw_line(e0, e0 + out * (s * 0.6), c, 1.6, true)
	draw_line(e1, e1 + out * (s * 0.6), c, 1.6, true)

func _draw_tri(cx: float, cy: float, rx: float, ry: float, rot: float, p: Dictionary) -> void:
	var ang: float = p["a"] + rot
	var base := _pt(cx, cy, rx, ry, ang, p["r"])
	var out := (base - Vector2(cx, cy)).normalized()
	var side := Vector2(-out.y, out.x)
	var s: float = p["sz"] * 0.7
	var col: Color = p["c"]
	var a: float = p["al"] * _depth(ang)
	var tri := PackedVector2Array([
		base + out * s, base - out * (s * 0.3) + side * (s * 0.7),
		base - out * (s * 0.3) - side * (s * 0.7)])
	draw_colored_polygon(tri, Color(col.r, col.g, col.b, a * 0.85))

func _draw_marker_rect(cx, cy, rx, ry, rot, p: Dictionary) -> void:
	var ang: float = p["a"] + rot
	var base := _pt(cx, cy, rx, ry, ang, p["r"])
	var out := (base - Vector2(cx, cy)).normalized()
	var side := Vector2(-out.y, out.x)
	var s: float = p["sz"] * 0.5
	var col: Color = p["c"]
	var a: float = p["al"] * _depth(ang)
	var c := Color(col.r, col.g, col.b, a)
	var quad := PackedVector2Array([
		base + side * s + out * (s * 0.5), base - side * s + out * (s * 0.5),
		base - side * s - out * (s * 0.5), base + side * s - out * (s * 0.5)])
	draw_polyline(PackedVector2Array([quad[0], quad[1], quad[2], quad[3], quad[0]]), c, 1.4, true)

func _draw_conn(cx: float, cy: float, rx: float, ry: float, rot: float, p: Dictionary) -> void:
	var ang: float = p["a"] + rot
	var a_in := _pt(cx, cy, rx, ry, ang, 0.82)
	var a_out := _pt(cx, cy, rx, ry, ang, 1.2)
	var col: Color = p["c"]
	var a: float = p["al"] * _depth(ang) * 0.8
	draw_line(a_in, a_out, Color(col.r, col.g, col.b, a), 1.2, true)
	draw_circle(a_out, 2.0, Color(col.r, col.g, col.b, a))

func _draw_tick(cx: float, cy: float, rx: float, ry: float, rot: float, p: Dictionary) -> void:
	var ang: float = p["a"] + rot
	var base := _pt(cx, cy, rx, ry, ang, p["r"])
	var out := (base - Vector2(cx, cy)).normalized()
	var col: Color = p["c"]
	var a: float = p["al"] * _depth(ang)
	draw_line(base, base + out * (p["sz"] * 0.5), Color(col.r, col.g, col.b, a), 1.4, true)
