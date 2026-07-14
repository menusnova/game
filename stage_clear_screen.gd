extends Node
# ════════════════════════════════════════════════════════════
#  CHEMIA — Stage Clear / Victory screens
#  Godot 4.7 syntax (await, not yield).
#  Self-contained: builds its own StageClear + VictoryScreen
#  CanvasLayers in code, matching the requested node tree.
# ════════════════════════════════════════════════════════════

signal return_to_menu_requested

const COL_CYAN   := Color("#00EAFF")
const COL_VIOLET := Color("#7F5AF0")
const COL_NAVY   := Color("#0A0E23")

# ── StageClear ──────────────────────────────────────────────
var stage_clear_layer:  CanvasLayer
var stage_clear_root:   Control   # single fade target for Background + labels
var clear_label:        Label
var stage_number_label: Label
var sc_anim:             AnimationPlayer

# ── VictoryScreen ───────────────────────────────────────────
var victory_layer:  CanvasLayer
var victory_root:   Control
var victory_label:  Label
var sub_label:       Label
var return_button:   Button
var v_anim:           AnimationPlayer


func _ready() -> void:
	_build_stage_clear()
	_build_victory()


# ════════════════════════════════════════════════════════════
#  PUBLIC API
# ════════════════════════════════════════════════════════════
func show_stage_clear(stage_num: int) -> void:
	stage_number_label.text = "STAGE %d" % stage_num
	stage_clear_layer.visible = true
	sc_anim.play("fade_in")
	await sc_anim.animation_finished


func hide_stage_clear() -> void:
	sc_anim.play("fade_out")
	await sc_anim.animation_finished
	stage_clear_layer.visible = false


func show_victory() -> void:
	victory_layer.visible = true
	v_anim.play("fade_in")


# ════════════════════════════════════════════════════════════
#  STAGE CLEAR
# ════════════════════════════════════════════════════════════
func _build_stage_clear() -> void:
	stage_clear_layer = CanvasLayer.new()
	stage_clear_layer.name    = "StageClear"
	stage_clear_layer.layer   = 90
	stage_clear_layer.visible = false
	add_child(stage_clear_layer)

	stage_clear_root = Control.new()
	stage_clear_root.name = "Root"
	stage_clear_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_clear_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_clear_root.modulate = Color(1, 1, 1, 0)
	stage_clear_layer.add_child(stage_clear_root)

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	stage_clear_root.add_child(bg)

	clear_label = Label.new()
	clear_label.name = "ClearLabel"
	clear_label.text = "S T A G E   C L E A R"   # wide letter-spacing via spaced characters
	clear_label.add_theme_font_size_override("font_size", 64)
	clear_label.add_theme_color_override("font_color", COL_CYAN)
	clear_label.add_theme_color_override("font_shadow_color", Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.55))
	clear_label.add_theme_constant_override("shadow_offset_x", 0)
	clear_label.add_theme_constant_override("shadow_offset_y", 0)
	clear_label.add_theme_constant_override("shadow_outline_size", 10)
	clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	clear_label.position = Vector2(0, 254)
	clear_label.size     = Vector2(1152, 90)
	clear_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_clear_root.add_child(clear_label)

	stage_number_label = Label.new()
	stage_number_label.name = "StageNumber"
	stage_number_label.text = "STAGE 1"
	stage_number_label.add_theme_font_size_override("font_size", 20)
	stage_number_label.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0, 0.85))
	stage_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_number_label.position = Vector2(0, 344)
	stage_number_label.size     = Vector2(1152, 30)
	stage_number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_clear_root.add_child(stage_number_label)

	sc_anim = AnimationPlayer.new()
	sc_anim.name = "AnimationPlayer"
	_add_fade_animations(sc_anim, "Root")
	stage_clear_layer.add_child(sc_anim)


# ════════════════════════════════════════════════════════════
#  VICTORY SCREEN
# ════════════════════════════════════════════════════════════
func _build_victory() -> void:
	victory_layer = CanvasLayer.new()
	victory_layer.name    = "VictoryScreen"
	victory_layer.layer   = 91
	victory_layer.visible = false
	add_child(victory_layer)

	victory_root = Control.new()
	victory_root.name = "Root"
	victory_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victory_root.modulate = Color(1, 1, 1, 0)
	victory_layer.add_child(victory_root)

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	victory_root.add_child(bg)

	# Soft glow layer behind VICTORY text (blurred-look duplicate via low-alpha oversized outline)
	victory_label = Label.new()
	victory_label.name = "VictoryLabel"
	victory_label.text = "VICTORY"
	victory_label.add_theme_font_size_override("font_size", 80)
	victory_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	victory_label.add_theme_color_override("font_shadow_color", Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.65))
	victory_label.add_theme_constant_override("shadow_offset_x", 0)
	victory_label.add_theme_constant_override("shadow_offset_y", 0)
	victory_label.add_theme_constant_override("shadow_outline_size", 18)
	victory_label.add_theme_color_override("font_outline_color", Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.85))
	victory_label.add_theme_constant_override("outline_size", 4)
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	victory_label.position = Vector2(0, 220)
	victory_label.size     = Vector2(1152, 110)
	victory_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victory_root.add_child(victory_label)

	sub_label = Label.new()
	sub_label.name = "SubLabel"
	sub_label.text = "All Stages Cleared"
	sub_label.add_theme_font_size_override("font_size", 32)
	sub_label.add_theme_color_override("font_color", COL_VIOLET)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.position = Vector2(0, 340)
	sub_label.size     = Vector2(1152, 50)
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victory_root.add_child(sub_label)

	return_button = Button.new()
	return_button.name = "ReturnButton"
	return_button.text = "กลับหน้าหลัก"
	return_button.size     = Vector2(240, 56)
	return_button.position = Vector2((1152.0 - 240.0) * 0.5, 460)
	return_button.add_theme_font_size_override("font_size", 16)
	return_button.add_theme_color_override("font_color", Color(0.85, 0.97, 1.0, 1.0))
	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color     = COL_NAVY
	sb_n.border_color = COL_CYAN
	sb_n.set_border_width_all(2)
	sb_n.set_corner_radius_all(12)
	var sb_h := sb_n.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(COL_NAVY.r + 0.05, COL_NAVY.g + 0.06, COL_NAVY.b + 0.10, 1.0)
	sb_h.shadow_color = Color(COL_CYAN.r, COL_CYAN.g, COL_CYAN.b, 0.45)
	sb_h.shadow_size  = 8
	return_button.add_theme_stylebox_override("normal",  sb_n)
	return_button.add_theme_stylebox_override("hover",   sb_h)
	return_button.add_theme_stylebox_override("pressed", sb_n)
	return_button.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	return_button.pressed.connect(func(): return_to_menu_requested.emit())
	victory_root.add_child(return_button)

	v_anim = AnimationPlayer.new()
	v_anim.name = "AnimationPlayer"
	_add_fade_animations(v_anim, "Root")
	victory_layer.add_child(v_anim)


# ════════════════════════════════════════════════════════════
#  SHARED fade_in / fade_out ANIMATIONS
# ════════════════════════════════════════════════════════════
func _add_fade_animations(anim_player: AnimationPlayer, root_name: String) -> void:
	var lib := AnimationLibrary.new()

	var fade_in := Animation.new()
	var t_in := fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.set_track_path(t_in, NodePath("%s:modulate:a" % root_name))
	fade_in.track_insert_key(t_in, 0.0, 0.0)
	fade_in.track_insert_key(t_in, 0.5, 1.0)
	fade_in.length = 0.5
	lib.add_animation("fade_in", fade_in)

	var fade_out := Animation.new()
	var t_out := fade_out.add_track(Animation.TYPE_VALUE)
	fade_out.set_track_path(t_out, NodePath("%s:modulate:a" % root_name))
	fade_out.track_insert_key(t_out, 0.0, 1.0)
	fade_out.track_insert_key(t_out, 0.5, 0.0)
	fade_out.length = 0.5
	lib.add_animation("fade_out", fade_out)

	anim_player.add_animation_library("", lib)
