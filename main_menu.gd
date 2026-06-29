extends Control

const SC_BATTLE := "res://battle_scene.tscn"
var _show_female := true

# ชื่อ MenuItem ทั้งหมดที่ต้องการ hover/click effect
const MENU_ITEMS := [
	"MenuItem_Notice", "MenuItem_Missions", "MenuItem_Event",
	"MenuItem_Pass", "MenuItem_Shop", "MenuItem_FirstPurchase"
]

func _ready() -> void:
	$AdventureCard.gui_input.connect(_on_adv_input)
	$ArenaCard.gui_input.connect(_on_arena_input)
	_setup_menu_items()

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
