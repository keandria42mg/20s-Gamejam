extends Node2D

@onready var board_view: Node2D = $BoardView
@onready var solved: RichTextLabel = $UI/Solved
@onready var move_label: RichTextLabel = $UI/MoveLabel
@onready var quit_panel_container: PanelContainer = $UI/QuitPanelContainer
@onready var yes: ChessButton = $UI/QuitPanelContainer/VBoxContainer/HBoxContainer/Yes
@onready var no: ChessButton = $UI/QuitPanelContainer/VBoxContainer/HBoxContainer/No
@onready var menu_button: ChessButton = $UI/MenuButton
@onready var undo_button: ChessButton = $UI/UndoButton
@onready var reset_button: ChessButton = $UI/ResetButton
@onready var next_button: ChessButton = $UI/NextButton
@onready var green: CPUParticles2D = $UI/Confetti/Green
@onready var red: CPUParticles2D = $UI/Confetti/Red
@onready var yellow: CPUParticles2D = $UI/Confetti/Yellow
@onready var white: CPUParticles2D = $UI/Confetti/White
@onready var level_title: RichTextLabel = $UI/Panel/LevelTitle
@onready var time: RichTextLabel = $UI/Panel/MarginContainer/Time
@onready var victory: CanvasLayer = $Victory

var is_paused := false

func _ready() -> void:
	quit_panel_container.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_panel_container.visible = false
	undo_button.pressed.connect(board_view.undo)
	reset_button.pressed.connect(board_view.reset)
	menu_button.pressed.connect(toggle_pause)
	yes.pressed.connect(quit_game)
	no.pressed.connect(resume_game)
	if has_node("UI/NextButton"):
		next_button.pressed.connect(board_view.next_level)

func _process(_delta: float) -> void:
	var t := "%.1f" % board_view.time_left
	var m := "Moves: %d/%d" % [board_view.move_count, board_view.max_moves]
	var title := "%s" % [board_view.level_name]
	var main_menu_scene = preload("res://UI/main_menu.tscn")
	var main_menu_node = main_menu_scene.instantiate()

	level_title.text = title
	time.text = t
	move_label.text = m
	
	if board_view.puzzle_won:
		solved.modulate = Color.LIGHT_GREEN
		solved.text = "[rainbow freq=1.0]Solved![/rainbow]"
		solved.visible = true
		undo_button.disabled = true

	elif board_view.puzzle_lost:
		solved.modulate = Color.INDIAN_RED
		solved.text = "[shake]" + board_view.lose_reason + "[/shake]"
		solved.visible = true
		undo_button.disabled = true

	if has_node("UI/NextButton"):
		next_button.visible = board_view.puzzle_won and board_view.level_index < board_view.MAX_LEVEL
		
	if board_view.puzzle_won and board_view.level_index == board_view.MAX_LEVEL:
		victory.visible = true
		Global.make_level_unlocked = true
		
func toggle_pause() -> void:
	is_paused = !is_paused
	undo_button.disabled = true
	reset_button.disabled = true
	menu_button.disabled = true
	get_tree().paused = is_paused
	quit_panel_container.visible = is_paused

func resume_game() -> void:
	is_paused = false
	undo_button.disabled = false
	reset_button.disabled = false
	menu_button.disabled = false
	get_tree().paused = false
	quit_panel_container.visible = false

func quit_game() -> void:
	print("quit")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")


func _on_go_tomenu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
