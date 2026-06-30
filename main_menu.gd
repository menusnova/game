extends Control

const SC_BATTLE     := "res://battle_scene.tscn"
const SC_TRANSITION := "res://transition_scene.tscn"
const SC_PROFILE    := "res://profile_scene.tscn"
const SC_GACHA      := "res://gacha_scene.tscn"
const SC_SHOP       := "res://shop_scene.tscn"
var _show_female := true
var _quest_panel: CanvasLayer

const MENU_ITEMS := [
	"MenuItem_Notice", "MenuItem_Missions", "MenuItem_Event",
	"MenuItem_Pass", "MenuItem_Shop", "MenuItem_FirstPurchase"
]

const CARDS := [
	"AdventureCard", "ArenaCard",
	"ChronicleCard", "SimulationCard", "ExpeditionCard",
	"EventBanner", "NewCharCard", "GuideCard"
]

func _ready() -> void:
	$AdventureCard.gui_input.connect(_on_adv_input)
	$ArenaCard.gui_input.connect(_on_arena_input)
	$ProfileCard.gui_input.connect(_on_profile_input)
	$NewCharCard.gui_input.connect(_on_gacha_input)
	_setup_menu_items()
	_setup_cards_fx()
	_setup_domain()
	_setup_quest_panel()

func _setup_quest_panel() -> void:
	_quest_panel = preload("res://quest_panel.tscn").instantiate()
	add_child(_quest_panel)

func _setup_domain() -> void:
	DomainManager.domain_changed.connect(_on_domain_changed)
	_on_domain_changed(DomainManager.get_percent())

func _on_domain_changed(percent: float) -> void:
	var label: Label = get_node_or_null("DomainInner/DomainPercent")
	if label:
		label.text = "%d%%" % int(percent)
		var t := percent / 100.0
		label.add_theme_color_override("font_color",
			Color(0.4 + t * 0.6, 0.85 + t * 0.15, 1.0, 1.0))

# ── Menu items (left sidebar) ────────────────────────────────────
func _setup_menu_items() -> void:
	for item_name in MENU_ITEMS:
		var item: Control = get_node_or_null(item_name)
		if item == null:
			continue
		var orig_y: float = item.position.y
		item.mouse_entered.connect(_on_menu_hover.bind(item, orig_y, true))
		item.mouse_exited.connect(_on_menu_hover.bind(item, orig_y, false))
		item.gui_input.connect(_on_menu_click.bind(item))

func _on_menu_hover(item: Control, orig_y: float, hovered: bool) -> void:
	var t := item.create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var target_y := orig_y - 4.0 if hovered else orig_y
	t.tween_property(item, "position:y", target_y, 0.12)

func _on_menu_click(ev: InputEvent, item: Control) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_flash(item)
		_fx_scale(item)
		_fx_ripple(item, ev.position)
		if item.name == "MenuItem_Missions":
			_quest_panel.open()
		elif item.name == "MenuItem_Shop":
			_goto(SC_SHOP)

# ── Cards (ripple + scale on tap) ────────────────────────────────
func _setup_cards_fx() -> void:
	for card_name in CARDS:
		var card: Control = get_node_or_null(card_name)
		if card == null:
			continue
		card.gui_input.connect(_on_card_fx.bind(card))

func _on_card_fx(ev: InputEvent, card: Control) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_scale(card)
		_fx_ripple(card, ev.position)

# ── Effects ───────────────────────────────────────────────────────
func _fx_flash(node: Control) -> void:
	var flash: ColorRect = node.get_node_or_null("BloomFlash")
	if flash:
		flash.color = Color(1, 1, 1, 0.45)
		var t := flash.create_tween()
		t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		t.tween_property(flash, "color:a", 0.0, 0.35)

func _fx_scale(node: Control) -> void:
	var t := node.create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(node, "scale", Vector2(0.93, 0.93), 0.08)
	t.tween_property(node, "scale", Vector2(1.0,  1.0),  0.18)

func _fx_ripple(node: Control, local_pos: Vector2) -> void:
	const SPARK_COLORS := [
		Color(0.55, 0.75, 1.0, 1.0),
		Color(0.75, 0.45, 1.0, 1.0),
		Color(1.0,  1.0,  1.0, 1.0),
		Color(0.4,  0.6,  1.0, 1.0),
		Color(0.9,  0.6,  1.0, 1.0),
	]
	const SPARK_SYMBOLS := ["✦", "✧", "⋆", "·", "✦"]
	const COUNT := 10

	for i in COUNT:
		var lbl := Label.new()
		lbl.text = SPARK_SYMBOLS[i % SPARK_SYMBOLS.size()]
		lbl.add_theme_font_size_override("font_size", int(randf_range(9.0, 16.0)))
		lbl.add_theme_color_override("font_color", SPARK_COLORS[i % SPARK_COLORS.size()])
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.position = local_pos + Vector2(-6, -6)
		lbl.z_index = 10
		node.add_child(lbl)

		var angle := (TAU / COUNT) * i + randf_range(-0.4, 0.4)
		var dest  := local_pos + Vector2(cos(angle), sin(angle)) * randf_range(28.0, 62.0)

		var t := lbl.create_tween().set_parallel(true)
		t.tween_property(lbl, "position",   dest,             0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(lbl, "modulate:a", 0.0,              0.42).set_ease(Tween.EASE_IN)
		t.tween_property(lbl, "scale",      Vector2(0.3, 0.3), 0.42).set_ease(Tween.EASE_IN)
		t.finished.connect(lbl.queue_free)

# ── Global click sparkle ─────────────────────────────────────────
func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_ripple(self, get_local_mouse_position())

# ── Navigation ────────────────────────────────────────────────────
func _on_profile_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_fx_scale($ProfileCard)
		_fx_ripple($ProfileCard, ev.position)
		_goto(SC_PROFILE)

func _on_gacha_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_goto(SC_GACHA)

func _on_adv_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_start_adventure()

func _start_adventure() -> void:
	_goto(SC_TRANSITION)

func _on_arena_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_goto(SC_BATTLE)

func _on_toggle_char() -> void:
	_show_female = not _show_female
	$FemaleCharacter.visible = _show_female
	$MaleCharacter.visible   = not _show_female

func _goto(path: String) -> void:
	if not ResourceLoader.exists(path): return
	var ov := ColorRect.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var t := create_tween()
	t.tween_property(ov, "color:a", 1.0, 0.28)
	await t.finished
	get_tree().change_scene_to_file(path)
