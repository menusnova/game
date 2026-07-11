extends CanvasLayer

enum Tab { DAILY, WEEKLY, CHALLENGE }

var _current_tab := Tab.DAILY
var _is_open     := false

const TAB_COLORS := {
	Tab.DAILY:     Color(0.95, 0.79, 0.32, 1.0),
	Tab.WEEKLY:    Color(0.42, 0.72, 1.00, 1.0),
	Tab.CHALLENGE: Color(1.00, 0.48, 0.28, 1.0),
}

const DAILY_MILESTONES := [
	{"pts": 20, "val": 10},
	{"pts": 40, "val": 10},
	{"pts": 60, "val": 10},
	{"pts": 80, "val": 20},
]
const DAILY_MAX_PTS := 80

const QUESTS := {
	Tab.DAILY: [
		{"id": "d_login",  "label": "ล็อกอินประจำวัน",    "desc": "เข้าสู่ระบบเกม",               "current": 0, "total": 1, "go": "",          "exp": 100,  "gold": 10000},
		{"id": "d_battle", "label": "ต่อสู้ 3 ครั้ง",       "desc": "เข้าสู่โหมดต่อสู้",             "current": 0, "total": 3, "go": "battle",    "exp": 100, "gold": 10000},
		{"id": "d_gacha",  "label": "สุ่มกาชา 1 ครั้ง",     "desc": "ใช้การสุ่มในพื้นที่ Gacha",     "current": 0, "total": 1, "go": "gacha",     "exp": 100,  "gold": 10000},
		{"id": "d_alch",   "label": "ใช้ห้องปฏิบัติการ",    "desc": "เปิดห้องปฏิบัติการเคมี",       "current": 0, "total": 1, "go": "alchemist", "exp": 100,  "gold": 10000},
	],
	Tab.WEEKLY: [
		{"id": "w_boss",    "label": "สังหาร Boss รายสัปดาห์",     "desc": "ท้าทาย Weekly Boss",        "current": 0, "total": 1,  "go": "battle",    "exp": 300, "gold": 3000, "crystal": 120, "upgrade": 2, "bond": 200},
		{"id": "w_battle5", "label": "ต่อสู้ 5 ครั้งในสัปดาห์",      "desc": "เข้าร่วมการต่อสู้ใดก็ได้",  "current": 0, "total": 5,  "go": "battle",    "exp": 250, "gold": 2500, "crystal": 100, "upgrade": 1, "bond": 200},
		{"id": "w_gacha3",  "label": "สุ่มกาชา 3 ครั้งในสัปดาห์",    "desc": "ใช้การสุ่มใน Gacha",       "current": 0, "total": 3,  "go": "gacha",     "exp": 220, "gold": 2200, "crystal": 90,  "upgrade": 1, "bond": 200},
		{"id": "w_alch5",   "label": "ผสมสารเคมี 5 ครั้งในสัปดาห์",  "desc": "ใช้ Laboratory",           "current": 0, "total": 5,  "go": "alchemist", "exp": 200, "gold": 2000, "crystal": 80,  "upgrade": 1, "bond": 200},
		{"id": "w_elem3",   "label": "ใช้ธาตุ 3 ชนิดในการต่อสู้",    "desc": "ผสมปฏิกิริยาธาตุ",         "current": 0, "total": 3,  "go": "battle",    "exp": 180, "gold": 1800, "crystal": 70,  "upgrade": 1, "bond": 200},
	],
	Tab.CHALLENGE: [
		{"id": "ch_win3",  "label": "ชนะ 3 ครั้งในสัปดาห์",  "desc": "ชนะการต่อสู้ใดก็ได้",     "current": 0, "total": 3,  "go": "battle", "exp": 400, "gold": 4000, "crystal": 160, "upgrade": 3, "bond": 200},
		{"id": "ch_5star", "label": "รับตัวละคร 5★ จากกาชา", "desc": "สุ่มจนได้ตัวละคร 5 ดาว", "current": 0, "total": 1,  "go": "gacha",  "exp": 500, "gold": 5000, "crystal": 200, "upgrade": 5, "bond": 200},
		{"id": "ch_elem",  "label": "ทำปฏิกิริยา 10 ครั้ง",   "desc": "ใช้ธาตุผสมกันในการต่อสู้", "current": 0, "total": 10, "go": "battle", "exp": 250, "gold": 2500, "crystal": 100, "upgrade": 2, "bond": 200},
	],
}

const _GO_SCENES := {
	"battle":    "res://battle_scene.tscn",
	"gacha":     "res://gacha_scene.tscn",
	"alchemist": "res://laboratory_scene.tscn",
}

@onready var _sheet:    Panel           = $Sheet
@onready var _dim:      ColorRect       = $Dim
@onready var _list:     VBoxContainer   = $Sheet/ContentArea/QuestList
@onready var _close_btn: Button         = $Sheet/TopBar/CloseBtn
@onready var _daily_bar: Panel          = $Sheet/DailyBar
@onready var _content:   ScrollContainer = $Sheet/ContentArea
@onready var _sub_title: Label          = $Sheet/TopBar/SubTitle

var _tab_btns: Array[Button] = []
var _claimed_daily: Array[String] = []  # quest ids that have been claimed

func _ready() -> void:
	if _sheet:
		_sheet.scale        = Vector2(0.88, 0.88)
		_sheet.modulate     = Color(1, 1, 1, 0)
		_sheet.pivot_offset = Vector2(524, 294)
		_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sheet.visible      = false
	if _dim:
		_dim.modulate.a   = 0.0
		_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_tab_btns = [
		$Sheet/TabStrip/TabRow/TabDaily    as Button,
		$Sheet/TabStrip/TabRow/TabWeekly   as Button,
		$Sheet/TabStrip/TabRow/TabChallenge as Button,
	]
	var tab_keys: Array[Tab] = [Tab.DAILY, Tab.WEEKLY, Tab.CHALLENGE]
	for i in _tab_btns.size():
		var key := tab_keys[i]
		_tab_btns[i].pressed.connect(func(): _switch_tab(key))

	if _close_btn: _close_btn.pressed.connect(close)
	if _dim:       _dim.gui_input.connect(_on_dim_input)

	_build_daily_bar()
	_update_tab_style()
	_rebuild_list()

# ── Open / Close ─────────────────────────────────────────────────────────────

func open() -> void:
	if _is_open or not _sheet or not _dim: return
	_is_open = true
	_sheet.visible      = true
	_dim.mouse_filter   = Control.MOUSE_FILTER_STOP
	_sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween().set_parallel(true)
	t.tween_property(_sheet, "scale",      Vector2(1.0, 1.0), 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(_sheet, "modulate:a", 1.0,               0.22)
	t.tween_property(_dim,   "modulate:a", 1.0,               0.22)

func close() -> void:
	if not _is_open or not _sheet or not _dim: return
	_is_open = false
	_dim.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween().set_parallel(true)
	t.tween_property(_sheet, "scale",      Vector2(0.88, 0.88), 0.20).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_property(_sheet, "modulate:a", 0.0,                 0.18)
	t.tween_property(_dim,   "modulate:a", 0.0,                 0.18)
	t.finished.connect(func(): if not _is_open and _sheet: _sheet.visible = false)

func _on_dim_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed: close()

# ── Tab ──────────────────────────────────────────────────────────────────────

func _switch_tab(tab: Tab) -> void:
	_current_tab = tab
	_update_tab_style()
	_rebuild_list()

func _update_tab_style() -> void:
	var tab_keys: Array[Tab] = [Tab.DAILY, Tab.WEEKLY, Tab.CHALLENGE]
	var tab_names := ["ภารกิจรายวัน", "ภารกิจรายสัปดาห์", "Challenge"]
	for i in _tab_btns.size():
		var btn := _tab_btns[i]
		if not btn: continue
		var active := (tab_keys[i] == _current_tab)
		var col: Color = TAB_COLORS[tab_keys[i]]

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(col.r * 0.07, col.g * 0.07, col.b * 0.07, 0.9) if active else Color(0, 0, 0, 0)
		if active:
			sb.border_width_bottom = 2
			sb.border_color        = col
		sb.content_margin_left   = 22
		sb.content_margin_right  = 22
		sb.content_margin_top    = 12
		sb.content_margin_bottom = 12

		var sb_blank := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal",  sb)
		btn.add_theme_stylebox_override("hover",   sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus",   sb_blank)
		btn.add_theme_color_override("font_color",
			Color(1.0, 1.0, 1.0, 1.0) if active else Color(0.55, 0.60, 0.72, 0.65))
		btn.add_theme_font_size_override("font_size", 12)

	if _sub_title:
		_sub_title.text = tab_names[_current_tab] if _current_tab < tab_names.size() else ""

# ── Daily bar ────────────────────────────────────────────────────────────────

func _calc_daily_pts() -> int:
	var pts := 0
	for q in QUESTS[Tab.DAILY]:
		if str(q.get("id", "")) in _claimed_daily:
			pts += 20
	return pts

func _build_daily_bar() -> void:
	if not _daily_bar: return
	for c in _daily_bar.get_children(): c.queue_free()

	var pts := _calc_daily_pts()

	# Header row
	var hdr := Label.new()
	hdr.text = "Training Points"
	hdr.size     = Vector2(130, 24)
	hdr.position = Vector2(22, 8)
	hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 10)
	hdr.add_theme_color_override("font_color", Color(0.60, 0.65, 0.78, 0.70))
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daily_bar.add_child(hdr)

	var pts_lbl := Label.new()
	pts_lbl.text = "%d / %d" % [pts, DAILY_MAX_PTS]
	pts_lbl.size     = Vector2(80, 24)
	pts_lbl.position = Vector2(152, 8)
	pts_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pts_lbl.add_theme_font_size_override("font_size", 13)
	pts_lbl.add_theme_color_override("font_color", Color(0.94, 0.80, 0.32, 1.0))
	pts_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daily_bar.add_child(pts_lbl)

	# Progress track
	const BX := 22.0; const BY := 34.0; const BW := 960.0; const BH := 4.0
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.08)
	track.size  = Vector2(BW, BH)
	track.position = Vector2(BX, BY)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daily_bar.add_child(track)

	var fill := ColorRect.new()
	fill.color = Color(0.92, 0.79, 0.32, 0.9)
	fill.size  = Vector2(BW * float(pts) / DAILY_MAX_PTS, BH)
	fill.position = Vector2(BX, BY)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daily_bar.add_child(fill)

	# Milestones
	for m in DAILY_MILESTONES:
		var pct  := float(m["pts"]) / float(DAILY_MAX_PTS)
		var mx   := BX + BW * pct
		var reached := pts >= int(m["pts"])
		var mcol := Color(0.92, 0.79, 0.32, 1.0) if reached else Color(0.28, 0.30, 0.42, 1.0)

		# Dot on bar
		var dot := ColorRect.new()
		dot.color    = mcol
		dot.size     = Vector2(10, 10)
		dot.position = Vector2(mx - 5, BY - 3)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_daily_bar.add_child(dot)

		# Reward box below bar
		var box := Panel.new()
		box.size     = Vector2(54, 54)
		box.position = Vector2(mx - 27, BY + 8)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb_box := StyleBoxFlat.new()
		sb_box.bg_color    = Color(0.14, 0.11, 0.05, 0.95) if reached else Color(0.06, 0.06, 0.10, 0.90)
		sb_box.border_color = Color(0.92, 0.79, 0.32, 0.55) if reached else Color(0.28, 0.30, 0.42, 0.35)
		sb_box.border_width_left  = 1; sb_box.border_width_right  = 1
		sb_box.border_width_top   = 1; sb_box.border_width_bottom = 1
		sb_box.corner_radius_top_left     = 27; sb_box.corner_radius_top_right    = 27
		sb_box.corner_radius_bottom_right = 27; sb_box.corner_radius_bottom_left  = 27
		box.add_theme_stylebox_override("panel", sb_box)
		_daily_bar.add_child(box)

		var icon_tx := TextureRect.new()
		var gem_tex: Texture2D = preload("res://image/crystal_gem.png")
		if gem_tex:
			icon_tx.texture = gem_tex
		icon_tx.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon_tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_tx.size     = Vector2(54, 32)
		icon_tx.position = Vector2(0, 4)
		icon_tx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon_tx)

		var val_l := Label.new()
		val_l.text = "×%d" % m["val"]
		val_l.size = Vector2(54, 14)
		val_l.position = Vector2(0, 36)
		val_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		val_l.add_theme_font_size_override("font_size", 9)
		val_l.add_theme_color_override("font_color",
			Color(0.55, 0.92, 1.00, 0.90) if reached else Color(0.40, 0.44, 0.55, 0.60))
		val_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(val_l)

# ── List ─────────────────────────────────────────────────────────────────────

func _rebuild_list() -> void:
	if not _list: return
	for child in _list.get_children(): child.queue_free()

	if _daily_bar:
		_daily_bar.visible = (_current_tab == Tab.DAILY)
	if _content:
		_content.offset_top = 192.0 if _current_tab == Tab.DAILY else 97.0

	var accent: Color = TAB_COLORS[_current_tab]
	var quests := QUESTS.get(_current_tab, []) as Array
	for q in quests:
		var go_key: String = str(q.get("go", ""))
		var nav := Callable()
		if go_key != "" and _GO_SCENES.has(go_key):
			var sc: String = _GO_SCENES[go_key]
			nav = func(): SceneTransition.fade_to(sc)
		var qid: String = str(q.get("id", ""))
		var claimed: bool = qid in _claimed_daily
		var claim_cb := Callable()
		if _current_tab == Tab.DAILY:
			claim_cb = func():
				if qid not in _claimed_daily:
					_claimed_daily.append(qid)
				_build_daily_bar()
				_rebuild_list()
		_list.add_child(_QuestRow.new(q, nav, accent, claimed, claim_cb))

# ── Quest row (HSR style) ─────────────────────────────────────────────────────
class _QuestRow extends Control:
	func _init(q: Dictionary, nav: Callable, accent: Color, claimed: bool = false, claim_cb: Callable = Callable()) -> void:
		custom_minimum_size = Vector2(0, 90)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var done: bool = int(q.get("current", 0)) >= int(q.get("total", 1))

		# Subtle hover bg
		var bg := ColorRect.new()
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(1, 1, 1, 0.018)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)

		# Left accent stripe
		var stripe := ColorRect.new()
		stripe.color    = Color(accent.r, accent.g, accent.b, 0.85) if not done else Color(0.35, 0.90, 0.55, 0.60)
		stripe.size     = Vector2(3, 90)
		stripe.position = Vector2(0, 0)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(stripe)

		# Category circle
		var circ := Panel.new()
		circ.size     = Vector2(42, 42)
		circ.position = Vector2(16, 24)
		circ.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb_c := StyleBoxFlat.new()
		sb_c.bg_color    = Color(accent.r * 0.14, accent.g * 0.14, accent.b * 0.14, 0.95)
		sb_c.border_color = Color(accent.r, accent.g, accent.b, 0.38)
		sb_c.border_width_left  = 1; sb_c.border_width_right  = 1
		sb_c.border_width_top   = 1; sb_c.border_width_bottom = 1
		sb_c.corner_radius_top_left     = 21; sb_c.corner_radius_top_right    = 21
		sb_c.corner_radius_bottom_right = 21; sb_c.corner_radius_bottom_left  = 21
		circ.add_theme_stylebox_override("panel", sb_c)
		add_child(circ)

		var cat_lbl := Label.new()
		cat_lbl.text = "✓" if done else "◎"
		cat_lbl.size = Vector2(42, 42)
		cat_lbl.position = Vector2(16, 24)
		cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cat_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		cat_lbl.add_theme_font_size_override("font_size", 16)
		cat_lbl.add_theme_color_override("font_color",
			Color(0.35, 1.0, 0.55, 1.0) if done else accent)
		cat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cat_lbl)

		# Quest name
		var name_lbl := Label.new()
		name_lbl.text          = str(q.get("label", ""))
		name_lbl.position      = Vector2(70, 16)
		name_lbl.size          = Vector2(410, 22)
		name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color",
			Color(0.50, 0.56, 0.52, 0.70) if done else Color(0.96, 0.97, 1.0, 1.0))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(name_lbl)

		# Sub-description
		var desc_lbl := Label.new()
		desc_lbl.text          = str(q.get("desc", ""))
		desc_lbl.position      = Vector2(70, 38)
		desc_lbl.size          = Vector2(410, 16)
		desc_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72, 0.50))
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(desc_lbl)

		# Progress bar
		var total: int = max(1, int(q.get("total", 1)))
		var cur:   int = clampi(int(q.get("current", 0)), 0, total)

		var bar_bg := ColorRect.new()
		bar_bg.color    = Color(1, 1, 1, 0.08)
		bar_bg.size     = Vector2(370, 3)
		bar_bg.position = Vector2(70, 56)
		bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar_bg)

		var bar_fill := ColorRect.new()
		bar_fill.color    = Color(0.35, 1.0, 0.55, 1.0) if done else accent
		bar_fill.size     = Vector2(370.0 * cur / total, 3)
		bar_fill.position = Vector2(70, 56)
		bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar_fill)

		var prog_lbl := Label.new()
		prog_lbl.text     = "%d / %d" % [cur, total]
		prog_lbl.position = Vector2(70, 62)
		prog_lbl.size     = Vector2(140, 16)
		prog_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		prog_lbl.add_theme_font_size_override("font_size", 10)
		prog_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.32))
		prog_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(prog_lbl)

		# Reward cards
		const REWARDS := [
			["exp",     "⭐", "res://image/icon_exp.png",     Color(1.00, 0.82, 0.25), "EXP"],
			["gold",    "",   "res://image/icon_gold.png",    Color(0.95, 0.72, 0.20), "Gold"],
			["crystal", "",   "res://image/crystal_gem.png",  Color(0.40, 0.88, 1.00), "Crystal"],
			["upgrade", "",   "res://image/icon_upgrade.png", Color(0.55, 0.80, 1.00), "Upgrade"],
			["bond",    "",   "res://image/icon_bond.png",    Color(0.85, 0.55, 1.00), "Bond Pt"],
		]
		const CW := 56.0; const CH := 68.0; const CG := 5.0
		# Count visible rewards to right-align the block toward the button area
		var visible_count := 0
		for ri in REWARDS.size():
			if int(q.get(REWARDS[ri][0], 0)) > 0:
				visible_count += 1
		var block_w := visible_count * (CW + CG) - CG
		var rx := 840.0 - block_w - 8.0  # right-align to just left of button
		for ri in REWARDS.size():
			var rkey      : String = REWARDS[ri][0]
			var rfallback : String = REWARDS[ri][1]
			var rpath     : String = REWARDS[ri][2]
			var rcol      : Color  = REWARDS[ri][3]
			var rlabel    : String = REWARDS[ri][4]
			var rval      : int    = int(q.get(rkey, 0))
			if rval <= 0: continue

			var card := Panel.new()
			card.size          = Vector2(CW, CH)
			card.position      = Vector2(rx, 11)
			card.clip_contents = true
			card.mouse_filter  = Control.MOUSE_FILTER_IGNORE
			var sb_card := StyleBoxFlat.new()
			sb_card.bg_color    = Color(rcol.r * 0.08, rcol.g * 0.08, rcol.b * 0.13, 0.95)
			sb_card.border_color = Color(rcol.r, rcol.g, rcol.b, 0.28)
			sb_card.border_width_left  = 1; sb_card.border_width_right  = 1
			sb_card.border_width_top   = 1; sb_card.border_width_bottom = 1
			sb_card.corner_radius_top_left     = 5; sb_card.corner_radius_top_right    = 5
			sb_card.corner_radius_bottom_right = 5; sb_card.corner_radius_bottom_left  = 5
			card.add_theme_stylebox_override("panel", sb_card)
			add_child(card)

			var tex: Texture2D = load(rpath)
			if tex:
				var icon_tx := TextureRect.new()
				icon_tx.texture      = tex
				icon_tx.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
				icon_tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_tx.size         = Vector2(CW, 32)
				icon_tx.position     = Vector2(0, 2)
				icon_tx.mouse_filter = Control.MOUSE_FILTER_IGNORE
				card.add_child(icon_tx)
			else:
				var icon_l := Label.new()
				icon_l.text = rfallback
				icon_l.size = Vector2(CW, 32)
				icon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				icon_l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				icon_l.add_theme_font_size_override("font_size", 18)
				icon_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
				card.add_child(icon_l)

			var val_s := "+%dk" % (rval / 1000) if rval >= 1000 else "+%d" % rval
			var val_l := Label.new()
			val_l.text     = val_s
			val_l.size     = Vector2(CW, 15)
			val_l.position = Vector2(0, 35)
			val_l.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
			val_l.vertical_alignment     = VERTICAL_ALIGNMENT_CENTER
			val_l.text_overrun_behavior  = TextServer.OVERRUN_TRIM_ELLIPSIS
			val_l.add_theme_font_size_override("font_size", 9)
			val_l.add_theme_color_override("font_color", Color(rcol.r + 0.08, rcol.g, rcol.b, 0.95))
			val_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(val_l)

			var name_l := Label.new()
			name_l.text     = rlabel
			name_l.size     = Vector2(CW, 13)
			name_l.position = Vector2(0, 51)
			name_l.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
			name_l.vertical_alignment      = VERTICAL_ALIGNMENT_CENTER
			name_l.text_overrun_behavior   = TextServer.OVERRUN_TRIM_ELLIPSIS
			name_l.add_theme_font_size_override("font_size", 7)
			name_l.add_theme_color_override("font_color", Color(rcol.r, rcol.g, rcol.b, 0.60))
			name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(name_l)

			rx += CW + CG

		# Claim / Go button
		if done:
			var btn := Button.new()
			var sb_btn := StyleBoxFlat.new()
			if claimed:
				sb_btn.bg_color    = Color(0.10, 0.12, 0.16, 0.80)
				sb_btn.border_color = Color(0.35, 0.38, 0.48, 0.40)
			else:
				sb_btn.bg_color    = Color(0.50, 0.37, 0.06, 1.0)
				sb_btn.border_color = Color(0.92, 0.79, 0.32, 0.60)
			sb_btn.border_width_left  = 1; sb_btn.border_width_right  = 1
			sb_btn.border_width_top   = 1; sb_btn.border_width_bottom = 1
			sb_btn.corner_radius_top_left     = 6; sb_btn.corner_radius_top_right    = 6
			sb_btn.corner_radius_bottom_right = 6; sb_btn.corner_radius_bottom_left  = 6
			btn.add_theme_stylebox_override("normal",  sb_btn)
			btn.add_theme_stylebox_override("hover",   sb_btn)
			btn.add_theme_stylebox_override("pressed", sb_btn)
			btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
			btn.add_theme_color_override("font_color",
				Color(0.45, 0.48, 0.55, 0.60) if claimed else Color(1.0, 0.90, 0.50, 1.0))
			btn.add_theme_font_size_override("font_size", 12)
			btn.text     = "รับแล้ว" if claimed else "รับรางวัล"
			btn.disabled = claimed
			btn.size     = Vector2(92, 34)
			btn.position = Vector2(848, 28)
			if not claimed and claim_cb.is_valid():
				btn.pressed.connect(claim_cb)
			add_child(btn)
		elif nav.is_valid():
			var btn := Button.new()
			var sb_btn := StyleBoxFlat.new()
			sb_btn.bg_color    = Color(0.10, 0.22, 0.60, 0.0)
			sb_btn.border_color = Color(0.45, 0.65, 1.0, 0.55)
			sb_btn.border_width_left  = 1; sb_btn.border_width_right  = 1
			sb_btn.border_width_top   = 1; sb_btn.border_width_bottom = 1
			sb_btn.corner_radius_top_left     = 6; sb_btn.corner_radius_top_right    = 6
			sb_btn.corner_radius_bottom_right = 6; sb_btn.corner_radius_bottom_left  = 6
			btn.add_theme_stylebox_override("normal",  sb_btn)
			btn.add_theme_stylebox_override("hover",   sb_btn)
			btn.add_theme_stylebox_override("pressed", sb_btn)
			btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
			btn.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0, 0.95))
			btn.add_theme_font_size_override("font_size", 12)
			btn.text     = "ไป ›"
			btn.size     = Vector2(72, 34)
			btn.position = Vector2(868, 28)
			btn.pressed.connect(nav)
			add_child(btn)

		# Bottom divider
		var div := ColorRect.new()
		div.color        = Color(1, 1, 1, 0.05)
		div.size         = Vector2(1048, 1)
		div.position     = Vector2(0, 89)
		div.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(div)
