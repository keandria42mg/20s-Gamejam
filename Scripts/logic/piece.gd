class_name Piece
extends RefCounted

enum Type { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }
enum Side { PLAYER, ENEMY }

var type: Piece.Type
var side: Piece.Side

func _init(t: Piece.Type, s: Piece.Side) -> void:
	type = t
	side = s

func copy() -> Piece:
	return Piece.new(type, side)
