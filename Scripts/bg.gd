extends Node2D

const TOP_COLOR := Color("#2b1d4a")
const BOTTOM_COLOR := Color("#0f3b4f")

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)


func _draw() -> void:
	var size := Vector2(1280, 720)

	# Vertical gradient built from horizontal strips.
	var steps := 72
	var h := size.y / steps
	for i in steps:
		var c := TOP_COLOR.lerp(BOTTOM_COLOR, float(i) / (steps - 1))
		draw_rect(Rect2(0, i * h, size.x, h + 1), c)

	# Soft decorative circles.
	draw_circle(Vector2(150, 600), 180, Color(1, 1, 1, 0.04))
	draw_circle(Vector2(1150, 120), 220, Color(1, 1, 1, 0.04))
	draw_circle(Vector2(1000, 650), 120, Color(1, 0.8, 0.4, 0.05))
