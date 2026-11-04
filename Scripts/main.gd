extends Node2D

@onready var board_view: Node2D = $BoardView
@onready var level_title: RichTextLabel = $UI/LevelTitle
@onready var time: RichTextLabel = $UI/Time
@onready var solved: RichTextLabel = $UI/Solved
@onready var move_label: RichTextLabel = $UI/MoveLabel
@onready var quit_panel_container: PanelContainer = $UI/QuitPanelContainer
@onready var yes: ChessButton = $UI/QuitPanelContainer/VBoxContainer/HBoxContainer/Yes
@onready var no: ChessButton = $UI/QuitPanelContainer/VBoxContainer/HBoxContainer/No
@onready var menu_button: ChessButton = $UI/MenuButton
@onready var undo_button: ChessButton = $UI/UndoButton
@onready var reset_button: ChessButton = $UI/ResetButton
@onready var next_button: ChessButton = $UI/NextButton

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
		$UI/NextButton.pressed.connect(board_view.next_level)

func _process(_delta: float) -> void:
	var t := "%.1f" % board_view.time_left
	var m := "Moves: %d/%d" % [board_view.move_count, board_view.max_moves]
	var title := "%s" % [board_view.level_name]

	level_title.text = title
	time.text = t
	move_label.text = m
	if board_view.puzzle_won:
		solved.self_modulate = Color.GREEN
		solved.text = "Solved!"
		solved.visible = true
		undo_button.disabled = true
	elif board_view.puzzle_lost:
		solved.self_modulate = Color.RED
		solved.text = board_view.lose_reason
		solved.visible = true
		undo_button.disabled = true

	if has_node("UI/NextButton"):
		next_button.visible = board_view.puzzle_won and board_view.level_index < board_view.MAX_LEVEL

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
