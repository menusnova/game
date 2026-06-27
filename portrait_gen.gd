class_name PortraitGen

# Generate a simple character portrait texture procedurally
static func make(accent: Color, w: int = 220, h: int = 380) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	# Background gradient — dark top to slightly lighter bottom
	for y in range(h):
		var t  : float = float(y) / float(h)
		var bg := Color(0.04 + t * 0.03, 0.06 + t * 0.04, 0.16 + t * 0.06, 1.0)
		for x in range(w):
			img.set_pixel(x, y, bg)

	# Radial glow at bottom center
	var gcx : float = w * 0.5
	var gcy : float = h * 0.85
	for y in range(h):
		for x in range(w):
			var dx : float = x - gcx
			var dy : float = y - gcy
			var d  : float = sqrt(dx * dx + dy * dy)
			if d < w * 0.9:
				var ga  : float = (1.0 - d / (w * 0.9)) * 0.18
				var cur := img.get_pixel(x, y)
				img.set_pixel(x, y, Color(
					cur.r + accent.r * ga,
					cur.g + accent.g * ga,
					cur.b + accent.b * ga, 1.0))

	# Head (filled circle)
	var head_cx : int = w / 2
	var head_cy : int = h / 6
	var head_r  : int = w / 6
	for y in range(head_cy - head_r - 2, head_cy + head_r + 2):
		for x in range(head_cx - head_r - 2, head_cx + head_r + 2):
			if x < 0 or x >= w or y < 0 or y >= h:
				continue
			var dx : float = x - head_cx
			var dy : float = y - head_cy
			var d  : float = sqrt(dx * dx + dy * dy)
			if d <= float(head_r):
				var edge : float = clampf(1.0 - (d - float(head_r) + 3.0) / 3.0, 0.0, 1.0)
				var skin := Color(
					accent.r * 0.85 + 0.12,
					accent.g * 0.80 + 0.10,
					accent.b * 0.75 + 0.08, edge)
				img.set_pixel(x, y, skin)

	# Body — trapezoid (wider at hips)
	var body_top    : int = head_cy + head_r + 4
	var body_bottom : int = h - 30
	for y in range(body_top, body_bottom):
		var t_body  : float = float(y - body_top) / float(body_bottom - body_top)
		var half_w  : float = (w * 0.20) + t_body * (w * 0.08)
		var x_left  : int   = int(w * 0.5 - half_w)
		var x_right : int   = int(w * 0.5 + half_w)
		for x in range(x_left, x_right):
			if x < 0 or x >= w:
				continue
			var edge_l : float = clampf(float(x - x_left)  / 4.0, 0.0, 1.0)
			var edge_r : float = clampf(float(x_right - x) / 4.0, 0.0, 1.0)
			var edge   : float = minf(edge_l, edge_r)
			var body_c := accent.lerp(
				Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.25), t_body * 0.7)
			body_c.a = edge * 0.92
			img.set_pixel(x, y, body_c)

	# Arms (2 thin rects on sides)
	for side in [-1, 1]:
		var ax_c : int = int(w * 0.5 + side * w * 0.30)
		var arm_w : int = int(w * 0.07)
		for y in range(body_top + 6, body_top + int((body_bottom - body_top) * 0.55)):
			for x in range(ax_c - arm_w, ax_c + arm_w):
				if x < 0 or x >= w or y < 0 or y >= h:
					continue
				var t_arm : float = float(y - body_top) / float(body_bottom - body_top)
				var ac    := accent.lerp(Color(accent.r*0.3, accent.g*0.3, accent.b*0.3), t_arm)
				ac.a = 0.80
				img.set_pixel(x, y, ac)

	# Bright rim-light on left edge of body
	for y in range(body_top, body_bottom):
		var t_rim  : float = float(y - body_top) / float(body_bottom - body_top)
		var half_w : float = (w * 0.20) + t_rim * (w * 0.08)
		var xl     : int   = int(w * 0.5 - half_w)
		for rim in range(3):
			var rx : int = xl + rim
			if rx < 0 or rx >= w:
				continue
			var ra : float = (1.0 - float(rim) / 3.0) * 0.5
			var cur := img.get_pixel(rx, y)
			img.set_pixel(rx, y, Color(
				minf(cur.r + accent.r * ra * 1.5, 1.0),
				minf(cur.g + accent.g * ra * 1.5, 1.0),
				minf(cur.b + accent.b * ra * 1.5, 1.0), cur.a))

	return ImageTexture.create_from_image(img)
