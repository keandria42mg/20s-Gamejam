class_name Solver
extends RefCounted


# Unique string for a board position, used to avoid revisiting states.
static func board_key(board: Board) -> String:
	var parts: Array[String] = []
	for pos in board.cells:
		var p: Piece = board.cells[pos]
		parts.append("%d,%d,%d,%d" % [pos.x, pos.y, p.type, p.side])
	parts.sort()
	return "|".join(parts)


static func has_enemies(board: Board) -> bool:
	for pos in board.cells:
		if board.cells[pos].side == Piece.Side.ENEMY:
			return true
	return false


# Returns the minimum number of moves to win, or -1 if unsolvable.
static func solve(start: Board, max_depth := 20) -> int:
	if not has_enemies(start):
		return 0

	var queue: Array = [[start, 0]]
	var visited := {board_key(start): true}
	var head := 0

	while head < queue.size():
		var entry = queue[head]
		head += 1
		var board: Board = entry[0]
		var depth: int = entry[1]
		if depth >= max_depth:
			continue

		for pos in board.cells.keys():
			if board.cells[pos].side != Piece.Side.PLAYER:
				continue
			for to in MoveGenerator.get_moves(board, pos):
				var next := board.clone()
				next.apply_move(pos, to)
				if not has_enemies(next):
					return depth + 1
				var key := board_key(next)
				if not visited.has(key):
					visited[key] = true
					queue.append([next, depth + 1])
	return -1

static func load_max_moves(index: int) -> int:
	var path := "res://Puzzles/level_%02d.json" % index
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return int(data.get("max_moves", 99))

static func load_board(index: int) -> Board:
	var path := "res://Puzzles/level_%02d.json" % index
	if not FileAccess.file_exists(path):
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data == null:
		return null
	var board := Board.new()
	for p in data["pieces"]:
		board.add_piece(
			Vector2i(int(p["x"]), int(p["y"])),
			Piece.new(Piece.Type[p["type"]], Piece.Side[p["side"]])
		)
	return board
