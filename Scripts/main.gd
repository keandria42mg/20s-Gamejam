extends Node2D

@onready var status_label: Label = $UI/StatusLabel
@onready var board_view: Node2D = $BoardView
@onready var level_title: RichTextLabel = $UI/LevelTitle
@onready var time: RichTextLabel = $UI/Time
@onready var solved: RichTextLabel = $UI/Solved


func _ready() -> void:
	$UI/UndoButton.pressed.connect(board_view.undo)
	$UI/ResetButton.pressed.connect(board_view.reset)
	if has_node("UI/NextButton"):
		$UI/NextButton.pressed.connect(board_view.next_level)


func _process(_delta: float) -> void:
	var t := "%.1f" % board_view.time_left
	var m := "Moves: %d/%d" % [board_view.move_count, board_view.max_moves]
	var title := "%s" % [board_view.level_name]

	level_title.text = title
	time.text = t
	if board_view.puzzle_won:
		solved.visible = true
	#elif board_view.puzzle_lost:
	#	status_label.text = "%s\n%s Press Reset" % [title, board_view.lose_reason]
	#else:
	#	status_label.text = "%s\n%s   %s" % [title, t, m]

	if has_node("UI/NextButton"):
		$UI/NextButton.visible = board_view.puzzle_won and board_view.level_index < board_view.MAX_LEVEL
