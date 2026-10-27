class_name MoveGenerator
extends RefCounted

const KNIGHT_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1),
	Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)
]
const KING_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]
const ROOK_DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
]
const BISHOP_DIRS: Array[Vector2i] = [
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]

# Player pawns move UP the screen (y decreases), enemy pawns move down.
static func pawn_direction(side: Piece.Side) -> int:
	return -1 if side == Piece.Side.PLAYER else 1


static func get_moves(board: Board, pos: Vector2i) -> Array[Vector2i]:
	var piece: Piece = board.get_piece(pos)
	var moves: Array[Vector2i] = []
	if piece == null:
		return moves

	match piece.type:
		Piece.Type.PAWN:
			_pawn_moves(board, piece, pos, moves)
		Piece.Type.KNIGHT:
			for o in KNIGHT_OFFSETS:
				_try_add(board, piece, pos + o, moves)
		Piece.Type.KING:
			for o in KING_OFFSETS:
				_try_add(board, piece, pos + o, moves)
		Piece.Type.BISHOP:
			_slide(board, piece, pos, BISHOP_DIRS, moves)
		Piece.Type.ROOK:
			_slide(board, piece, pos, ROOK_DIRS, moves)
		Piece.Type.QUEEN:
			_slide(board, piece, pos, ROOK_DIRS, moves)
			_slide(board, piece, pos, BISHOP_DIRS, moves)
	return moves


# Adds `to` if it is empty or holds an enemy.
# Returns true only if the square was empty (so sliders can keep going).
static func _try_add(board: Board, piece: Piece, to: Vector2i, moves: Array[Vector2i]) -> bool:
	if not board.in_bounds(to):
		return false
	var target: Piece = board.get_piece(to)
	if target == null:
		moves.append(to)
		return true
	if target.side != piece.side:
		moves.append(to)
	return false


static func _slide(board: Board, piece: Piece, pos: Vector2i, dirs: Array[Vector2i], moves: Array[Vector2i]) -> void:
	for d in dirs:
		var p: Vector2i = pos + d
		while _try_add(board, piece, p, moves):
			p += d


static func _pawn_moves(board: Board, piece: Piece, pos: Vector2i, moves: Array[Vector2i]) -> void:
	var dir: int = pawn_direction(piece.side)

	# Forward one square (move only, cannot capture).
	var fwd: Vector2i = pos + Vector2i(0, dir)
	if board.in_bounds(fwd) and board.get_piece(fwd) == null:
		moves.append(fwd)

	# Diagonal captures (only if an enemy is there).
	for dx in [-1, 1]:
		var diag: Vector2i = pos + Vector2i(dx, dir)
		if board.in_bounds(diag):
			var target: Piece = board.get_piece(diag)
			if target != null and target.side != piece.side:
				moves.append(diag)
