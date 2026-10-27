class_name Board
extends RefCounted

var size := Vector2i(8, 8)
var cells: Dictionary = {}   # Vector2i -> Piece

func get_piece(pos: Vector2i) -> Piece:
	return cells.get(pos)

func in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < size.x and pos.y < size.y

func add_piece(pos: Vector2i, piece: Piece) -> void:
	cells[pos] = piece

# The core rule: you become what you eat.
func apply_move(from: Vector2i, to: Vector2i) -> void:
	var mover: Piece = cells[from]
	var victim: Piece = cells.get(to)
	cells.erase(from)
	if victim != null:
		mover.type = victim.type
	cells[to] = mover

# Snapshot, used later for undo.
func clone() -> Board:
	var b := Board.new()
	b.size = size
	for pos in cells:
		b.cells[pos] = cells[pos].copy()
	return b
