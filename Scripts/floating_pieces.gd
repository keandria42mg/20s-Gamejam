extends Control

@export var piece_textures: Array[Texture2D]
@export var piece_count := 14
@export var piece_size := 72.0
@export var palette: Array[Color] = [
	Color("4a90d9"),
	Color("d94a4a")
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in piece_count:
		_spawn_piece(true)

func _spawn_piece(random_start := false) -> void:
	if piece_textures.is_empty():
		return

	var vp := get_viewport_rect().size
	var p := TextureRect.new()
	var c: Color = palette.pick_random()
	c.a = randf_range(0.08, 0.2)
	p.modulate = c
	p.texture = piece_textures.pick_random()
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.size = Vector2(piece_size, piece_size)
	p.pivot_offset = p.size / 2.0
	p.modulate.a = randf_range(1, 0.5)
	p.scale = Vector2.ONE * randf_range(0.7, 1.5)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)

	var start_y := randf_range(0.0, vp.y) if random_start else vp.y + 100.0
	p.position = Vector2(randf_range(0.0, vp.x), start_y)

	var distance := start_y + 150.0
	var duration := distance / randf_range(35.0, 70.0)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "position:y", -150.0, duration)
	tw.tween_property(p, "position:x", p.position.x + randf_range(-80.0, 80.0), duration)
	tw.tween_property(p, "rotation", randf_range(-0.8, 0.8), duration)
	tw.finished.connect(func():
		p.queue_free()
		_spawn_piece()
	)
