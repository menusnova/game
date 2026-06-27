class_name PortraitGen

static func make(accent: Color, w: int = 220, h: int = 380) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var t  : float = float(y) / float(h)
		var bg := Color(0.04 + t*0.03, 0.06 + t*0.04, 0.16 + t*0.06, 1.0)
		for x in range(w):
			img.set_pixel(x, y, bg)

	# Bottom glow
	var gcx : float = w * 0.5
	var gcy : float = h * 0.88
	for y in range(h):
		for x in range(w):
			var d : float = sqrt((x-gcx)*(x-gcx) + (y-gcy)*(y-gcy))
			if d < w * 0.85:
				var ga  : float = (1.0 - d/(w*0.85)) * 0.20
				var cur := img.get_pixel(x, y)
				img.set_pixel(x, y, Color(minf(cur.r+accent.r*ga,1), minf(cur.g+accent.g*ga,1), minf(cur.b+accent.b*ga,1), 1.0))

	# Head
	var hcx : int = w/2; var hcy : int = h/6; var hr : int = w/6
	for y in range(hcy-hr-2, hcy+hr+2):
		for x in range(hcx-hr-2, hcx+hr+2):
			if x<0 or x>=w or y<0 or y>=h: continue
			var d : float = sqrt(float((x-hcx)*(x-hcx)+(y-hcy)*(y-hcy)))
			if d <= float(hr):
				var e : float = clampf(1.0-(d-float(hr)+3.0)/3.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(accent.r*0.85+0.12, accent.g*0.80+0.10, accent.b*0.75+0.08, e))

	# Body
	var bt : int = hcy+hr+4; var bb : int = h-28
	for y in range(bt, bb):
		var t_b : float = float(y-bt)/float(bb-bt)
		var hw  : float = (w*0.20)+t_b*(w*0.08)
		for x in range(int(w*0.5-hw), int(w*0.5+hw)):
			if x<0 or x>=w: continue
			var el : float = clampf(float(x-int(w*0.5-hw))/4.0, 0.0, 1.0)
			var er : float = clampf(float(int(w*0.5+hw)-x)/4.0, 0.0, 1.0)
			var bc := accent.lerp(Color(accent.r*0.25,accent.g*0.25,accent.b*0.25), t_b*0.7)
			bc.a = minf(el,er)*0.92
			img.set_pixel(x, y, bc)

	# Rim light
	for y in range(bt, bb):
		var t_b : float = float(y-bt)/float(bb-bt)
		var xl  : int   = int(w*0.5-(w*0.20+t_b*w*0.08))
		for rim in range(3):
			var rx : int = xl+rim
			if rx<0 or rx>=w: continue
			var ra : float = (1.0-float(rim)/3.0)*0.5
			var cur := img.get_pixel(rx, y)
			img.set_pixel(rx, y, Color(minf(cur.r+accent.r*ra*1.5,1), minf(cur.g+accent.g*ra*1.5,1), minf(cur.b+accent.b*ra*1.5,1), cur.a))

	return ImageTexture.create_from_image(img)
