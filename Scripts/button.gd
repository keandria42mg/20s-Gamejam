class_name ChessButton
extends Button

@export var gold := Color("35bfdb")
@export var fill := Color("0c2454")
@export var fill_hover := Color("0b5db6")
@export var fill_pressed := Color("000b35")
@export var text_color := Color("f5ecd7")

var _shine_mat: ShaderMaterial

func _ready() -> void:
	custom_minimum_size = Vector2(260, 56)
	focus_mode = Control.FOCUS_ALL

	# Box styles for each state
	add_theme_stylebox_override("normal",  _make_style(fill, gold.darkened(0.45), 2, 6))
	add_theme_stylebox_override("hover",   _make_style(fill_hover, fill_hover, 3, 12))
	add_theme_stylebox_override("focus",   _make_style(fill_hover, gold, 3, 12))
	add_theme_stylebox_override("pressed", _make_style(fill_pressed, gold.lightened(0.3), 3, 2))
	add_theme_stylebox_override("disabled", _make_style(fill.darkened(0.3), Color(0.3, 0.3, 0.3), 2, 0))

	# Text
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_hover_color", gold.lightened(0.4))
	add_theme_color_override("font_focus_color", gold.lightened(0.4))
	add_theme_color_override("font_pressed_color", gold)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	add_theme_constant_override("outline_size", 4)

	# Shine sweep (unique material per button)
	_shine_mat = ShaderMaterial.new()
	_shine_mat.shader = preload("res://Shaders/button.gdshader")
	material = _shine_mat

	mouse_entered.connect(_play_shine)
	focus_entered.connect(_play_shine)

func _make_style(bg: Color, border: Color, border_w: int, shadow: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(10)
	s.set_content_margin_all(14)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = shadow
	s.shadow_offset = Vector2(0, 3)
	s.anti_aliasing = true
	return s

func _play_shine() -> void:
	_shine_mat.set_shader_parameter("progress", -0.3)
	var tw := create_tween()
	tw.tween_property(_shine_mat, "shader_parameter/progress", 1.3, 0.55)
