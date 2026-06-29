extends Control

const SC_BATTLE := "res://battle_scene.tscn"
var _show_female := true

const MENU_ITEMS := [
	"MenuItem_Notice", "MenuItem_Missions", "MenuItem_Event",
	"MenuItem_Pass", "MenuItem_Shop", "MenuItem_FirstPurchase"
]

# dialogue data for chapter 1 intro
const CH1_SPEAKERS: Array[String] = ["Lyra", "Lyra", "Lyra", "Kael", "Lyra"]
const CH1_LINES: Array[String] = [
	"สูตรนี้... มันไม่ธรรมดาเลย",
	"ใครบางคนแอบแก้สมการหลักไว้ก่อนที่ฉันจะมาถึง",
	"ถ้าปล่อยไว้อีกคืนเดียว ห้องทดลองทั้งหมดจะระเบิด",
	"รู้จักฝีมือพวกนั้นดี ต้องเป็น Void Syndicate แน่ๆ",
	"ไม่ว่าจะเป็นใครก็ตาม... เราต้องหยุดพวกเขาที่นี่",
]

var _dialogue_box: CanvasLayer
var _pre_battle: CanvasLayer

func _ready() -> void:
	$AdventureCard.gui_input.connect(_on_adv_input)
	$ArenaCard.gui_input.connect(_on_arena_input)
	_setup_menu_items()
	_setup_domain()
	_setup_dialogue()

func _setup_dialogue() -> void:
	_dialogue_box = preload("res://dialogue_box.tscn").instantiate()
	_dialogue_box.visible = false
	add_child(_dialogue_box)

	_pre_battle = preload("res://pre_battle.tscn").instantiate()
	_pre_battle.visible = false
	add_child(_pre_battle)
	_pre_battle.start_battle.connect(_on_battle_start)

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
		var flash: ColorRect = item.get_node_or_null("BloomFlash")
		if flash == null:
			return
		flash.color = Color(1, 1, 1, 0.45)
		var t := flash.create_tween()
		t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		t.tween_property(flash, "color:a", 0.0, 0.35)

func _on_adv_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_start_adventure()

func _start_adventure() -> void:
	_dialogue_box.start(CH1_LINES, CH1_SPEAKERS)
	await _dialogue_box.dialogue_finished
	_pre_battle.show_for_mission("ห้องปฏิบัติการต้องห้าม", "MISSION · 1-1")

func _on_battle_start() -> void:
	DomainManager.add_points("battle")
	_goto(SC_BATTLE)

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
