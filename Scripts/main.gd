extends Node2D

@onready var status_label: Label = $UI/StatusLabel
@onready var board_view: Node2D = $BoardView


func _ready() -> void:
	$UI/UndoButton.pressed.connect(board_view.undo)
	$UI/ResetButton.pressed.connect(board_view.reset)
	if has_node("UI/NextButton"):
		$UI/NextButton.pressed.connect(board_view.next_level)


func _process(_delta: float) -> void:
	var t := "Time: %.1f" % board_view.time_left
	var m := "Moves: %d/%d" % [board_view.move_count, board_view.max_moves]
	var title := "Level %d: %s" % [board_view.level_index, board_view.level_name]

	if board_view.puzzle_won:
		status_label.text = "%s\nSolved! %s   %s" % [title, m, t]
	elif board_view.puzzle_lost:
		status_label.text = "%s\n%s Press Reset" % [title, board_view.lose_reason]
	else:
		status_label.text = "%s\n%s   %s" % [title, t, m]

	if has_node("UI/NextButton"):
		$UI/NextButton.visible = board_view.puzzle_won and board_view.level_index < board_view.MAX_LEVEL
