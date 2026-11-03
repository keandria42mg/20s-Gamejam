extends Control

const GAME_SCENE := "res://Scenes/main.tscn"

@onready var title: RichTextLabel  = %Title
@onready var fade: ColorRect = %Fade
@onready var buttons: Array[Button] = [%PlayButton, %OptionsButton, %QuitButton]

var _hover_tweens := {}

func _ready() -> void:
	await get_tree().process_frame

	for b in buttons:
		b.pivot_offset = b.size / 2.0
		b.modulate.a = 0.0
		b.scale = Vector2(0.8, 0.8)
		b.mouse_entered.connect(_on_hover.bind(b, true))
		b.mouse_exited.connect(_on_hover.bind(b, false))
		b.focus_entered.connect(_on_hover.bind(b, true))
		b.focus_exited.connect(_on_hover.bind(b, false))

	title.pivot_offset = title.size / 3.0
	title.modulate.a = 0.0
	title.scale = Vector2(1.4, 1.4)

	%PlayButton.pressed.connect(_on_play)
	%OptionsButton.pressed.connect(_on_options)
	%QuitButton.pressed.connect(_on_quit)

	_play_intro()

func _play_intro() -> void:
	
	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, 0.6)

	var t := create_tween().set_parallel(true)
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(title, "modulate:a", 1.0, 0.6).set_delay(0.3)
	t.tween_property(title, "scale", Vector2.ONE, 0.8).set_delay(0.3)
	await t.finished

	_pulse_title()

	for i in buttons.size():
		var b := buttons[i]
		var bt := create_tween().set_parallel(true)
		bt.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bt.tween_property(b, "modulate:a", 1.0, 0.35)
		bt.tween_property(b, "scale", Vector2.ONE, 0.45)
		await get_tree().create_timer(0.12).timeout

func _pulse_title() -> void:
	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(title, "scale", Vector2(1.2, 1.2), 1.6)
	tw.tween_property(title, "scale", Vector2.ONE, 1.6)

func _on_hover(b: Button, hovering: bool) -> void:
	if _hover_tweens.has(b):
		_hover_tweens[b].kill()
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2.ONE * (1.08 if hovering else 1.0), 0.15)
	tw.tween_property(b, "modulate", Color(1.2, 1.15, 1.0) if hovering else Color.WHITE, 0.15)
	_hover_tweens[b] = tw

func _on_play() -> void:
	_change_scene(GAME_SCENE)

func _on_options() -> void:
	print("Open options")

func _on_quit() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.3)
	await tw.finished
	get_tree().quit()

func _change_scene(path: String) -> void:
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.4)
	await tw.finished
	get_tree().change_scene_to_file(path)
