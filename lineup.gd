extends Control

const C_BG     := Color(0.03, 0.06, 0.16, 1.0)
const C_PANEL  := Color(0.05, 0.10, 0.22, 0.93)
const C_PANEL2 := Color(0.07, 0.13, 0.28, 0.96)
const C_DARK   := Color(0.02, 0.04, 0.12, 1.0)
const C_BORDER := Color(0.15, 0.45, 0.85, 0.55)
const C_BDR2   := Color(0.20, 0.60, 1.00, 0.28)
const C_TEXT   := Color(0.82, 0.93, 1.00, 1.0)
const C_TEXT2  := Color(0.55, 0.75, 1.00, 1.0)
const C_ACCENT := Color(0.20, 0.70, 1.00, 1.0)
const C_GOLD   := Color(1.00, 0.82, 0.30, 1.0)
const C_RED    := Color(1.00, 0.32, 0.32, 1.0)
const C_GREEN  := Color(0.28, 1.00, 0.55, 1.0)

const CHARS : Array = [
	{"name": "LUXIA",  "element": "✦", "lv": 80, "color": Color(1.0, 0.82, 0.30, 1)},
	{"name": "EMBER",  "element": "🔥", "lv": 70, "color": Color(1.0, 0.40, 0.20, 1)},
	{"name": "AQUA",   "element": "💧", "lv": 60, "color": Color(0.20, 0.60, 1.00, 1)},
	{"name": "TERRA",  "element": "🌿", "lv": 40, "color": Color(0.30, 0.85, 0.40, 1)},
	{"name": "VOLT",   "element": "⚡", "lv": 55, "color": Color(0.90, 0.85, 0.10, 1)},
	{"name": "FROST",  "element": "❄",  "lv": 75, "color": Color(0.60, 0.90, 1.00, 1)},
]

# Team slots: index into CHARS, -1 = empty
var _team : Array = [0, 1, 2, -1]

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new(); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(bg)

	# Top bar
	var top := _panel(Rect2(0, 0, 1152, 52), Color(0.03, 0.07, 0.18, 0.98), C_ACCENT, 0.0)
	add_child(top)
	var back := Button.new(); back.text = "◀  LOBBY"; back.position = Vector2(10,10); back.size = Vector2(100,32)
	back.add_theme_font_size_override("font_size", 12)
	back.add_theme_color_override("font_color", C_TEXT)
	_apply_style(back, Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.22), C_ACCENT, 5.0)
	back.pressed.connect(_go_lobby); top.add_child(back)

	# Battle button right
	var battle_btn := Button.new(); battle_btn.text = "⚔  GO TO BATTLE"
	battle_btn.size = Vector2(160, 32); battle_btn.position = Vector2(982, 10)
	battle_btn.add_theme_font_size_override("font_size", 12)
	_apply_style(battle_btn, C_RED, C_RED, 5.0)
	battle_btn.add_theme_color_override("font_color", Color(1,1,1,1))
	battle_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://battle_scene.tscn"))
	top.add_child(battle_btn)

	_lbl_at(top, "⚔  LINEUP", 20, C_ACCENT, Vector2(480, 8))
	_lbl_at(top, "Set up your team of 4", 10, C_TEXT2, Vector2(472, 34))
	var sep := ColorRect.new(); sep.position = Vector2(0,51); sep.size = Vector2(1152,1); sep.color = C_ACCENT
	top.add_child(sep)

	# ── Active team row ───────────────────────────────────────────────────
	_lbl_at(self, "ACTIVE TEAM", 12, C_TEXT2, Vector2(20, 68))
	for i in range(4):
		_build_slot(i)

	# ── Divider ───────────────────────────────────────────────────────────
	var div := ColorRect.new(); div.position = Vector2(20, 228); div.size = Vector2(1112, 1); div.color = C_BDR2
	add_child(div)
	_lbl_at(self, "ALL CHARACTERS", 12, C_TEXT2, Vector2(20, 238))

	# ── Character roster grid ─────────────────────────────────────────────
	for i in range(CHARS.size()):
		var ch : Dictionary = CHARS[i]
		var col : int = i % 6
		var card := _panel(Rect2(20 + col * 190, 262, 175, 100),
							Color(ch.color.r*0.1, ch.color.g*0.1, ch.color.b*0.1, 0.9),
							ch.color, 7.0)
		add_child(card)
		_lbl_at(card, ch.element, 22, ch.color, Vector2(10, 12))
		_lbl_at(card, ch.name,    13, C_TEXT,   Vector2(44, 14))
		_lbl_at(card, "Lv.%d" % ch.lv, 10, C_TEXT2, Vector2(44, 34))

		# Add to team button
		var add_btn := Button.new(); add_btn.text = "+ Add"; add_btn.size = Vector2(70, 24)
		add_btn.position = Vector2(10, 68)
		add_btn.add_theme_font_size_override("font_size", 10)
		_apply_style(add_btn, Color(C_ACCENT.r,C_ACCENT.g,C_ACCENT.b,0.20), C_ACCENT, 4.0)
		add_btn.add_theme_color_override("font_color", C_ACCENT)
		var idx : int = i
		add_btn.pressed.connect(func(): _add_to_team(idx))
		card.add_child(add_btn)

func _build_slot(slot: int) -> void:
	# Remove existing slot node
	var old := get_node_or_null("Slot%d" % slot)
	if old: old.queue_free()
	await get_tree().process_frame

	var sx : float = 20 + slot * 280.0
	var has_char : bool = (_team[slot] >= 0)
	var ch : Dictionary = CHARS[_team[slot]] if has_char else {}

	var bc : Color = ch.get("color", C_BDR2) if has_char else C_BDR2
	var card := _panel(Rect2(sx, 86, 260, 132),
						Color(bc.r*0.08, bc.g*0.08, bc.b*0.08, 0.9) if has_char else C_PANEL2,
						bc, 8.0)
	card.name = "Slot%d" % slot
	add_child(card)

	if has_char:
		_lbl_at(card, ch.element, 28, ch.color, Vector2(12, 12))
		_lbl_at(card, ch.name, 16, C_TEXT, Vector2(54, 14))
		_lbl_at(card, "Lv.%d" % ch.lv, 11, C_TEXT2, Vector2(54, 36))
		_lbl_at(card, "★★★★★" if ch.name in ["LUXIA","FROST"] else "★★★★", 10, C_GOLD, Vector2(12, 56))
		_lbl_at(card, "ATK  DEF  HP", 9, C_TEXT2, Vector2(12, 78))

		var rem := Button.new(); rem.text = "✕ Remove"; rem.size = Vector2(100, 26); rem.position = Vector2(12, 98)
		rem.add_theme_font_size_override("font_size", 10)
		_apply_style(rem, Color(C_RED.r,C_RED.g,C_RED.b,0.20), C_RED, 4.0)
		rem.add_theme_color_override("font_color", C_RED)
		var s : int = slot
		rem.pressed.connect(func(): _remove_from_team(s)); card.add_child(rem)
	else:
		_lbl_at(card, "＋\nEMPTY SLOT", 14, C_BDR2, Vector2(80, 36))

func _add_to_team(char_idx: int) -> void:
	# Find first empty slot
	for i in range(4):
		if _team[i] < 0:
			_team[i] = char_idx
			_build_slot(i)
			return
	# Replace last if full
	_team[3] = char_idx; _build_slot(3)

func _remove_from_team(slot: int) -> void:
	_team[slot] = -1; _build_slot(slot)

func _go_lobby() -> void:
	var t := create_tween()
	var fade := ColorRect.new(); fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0,0,0,0); fade.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(fade)
	t.tween_property(fade, "color:a", 1.0, 0.30); await t.finished
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _panel(rect: Rect2, fill: Color, border: Color, radius: float) -> PanelContainer:
	var p := PanelContainer.new(); p.position = rect.position; p.size = rect.size
	_apply_style(p, fill, border, radius); return p

func _apply_style(node: Control, fill: Color, border: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new(); sb.bg_color = fill; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(int(radius))
	node.add_theme_stylebox_override("panel", sb)

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; return l

func _lbl_at(parent: Control, text: String, size: int, color: Color, pos: Vector2) -> Label:
	var l := _lbl(text, size, color); l.position = pos; parent.add_child(l); return l
