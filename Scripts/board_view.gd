extends Node2D

const TILE := 80
const LIGHT := Color("#151f38")
const DARK := Color("#0D1315")
const PLAYER_COLOR := Color("#4a90d9")
const ENEMY_COLOR := Color("#d94a4a")
const LETTERS := ["P", "N", "B", "R", "Q", "K"]
const SPRITE_SIZE := 64.0
const SPRITE_NAMES := ["pawn", "knight", "bishop", "rook", "queen", "king"]
const PIECE_NAMES := ["Pawn", "Knight", "Bishop", "Rook", "Queen", "King"]
@onready var solved: RichTextLabel = $"../UI/Solved"
@onready var reset_button: ChessButton = $"../UI/ResetButton"
@onready var undo_button: ChessButton = $"../UI/UndoButton"
@onready var move_sound: AudioStreamPlayer = $"../MoveSound"
@onready var capture_sound: AudioStreamPlayer = $"../CaptureSound"

var hover_cell := Vector2i(-1, -1)
var textures: Array[Texture2D] = []

var board: Board

const SELECT_COLOR := Color(0.514, 1.0, 0.0, 0.2)
const MOVE_COLOR := Color(0.2, 0.824, 0.898, 0.2)
const CAPTURE_COLOR := Color(1.0, 0.224, 0.102, 0.302)

var selected: Vector2i = Vector2i(-1, -1)
var has_selection := false
var legal_moves: Array[Vector2i] = []
const FADE_OUT := 0.3
const FADE_IN := 0.4
const TITLE_HOLD := 0.7

var fade_rect: ColorRect
var fade_label: Label
var transitioning := false
var history: Array[Board] = []
var puzzle_won := false
var move_count := 0

const MOVE_TIME := 0.25
const POP_TIME := 0.3

var anim_time := 0.0
var move_anim := {}
var pops := {}
var particles: Array = []
var shake := 0.0

const TIME_LIMIT := 20.0
var time_left := TIME_LIMIT
var puzzle_lost := false

var level_index := 1
var level_name := ""
var time_limit := 20.0
var max_moves := 99
var lose_reason := ""
var timer_started := false

signal state_changed

@export var MAX_LEVEL := 29

func _load_textures() -> void:
	textures.clear()
	for n in SPRITE_NAMES:
		var path := "res://Assets/pieces/%s.png" % n
		if ResourceLoader.exists(path):
			textures.append(load(path))
		else:
			textures.append(null)

func _ready() -> void:
	board = Board.new()
	_load_textures()
	_build_fade()
	load_level(1)
	queue_redraw()
	#if OS.is_debug_build():
	#	_check_all_levels()

func _process(delta: float) -> void:
	anim_time += delta
	_update_animations(delta)
	var m := get_local_mouse_position()
	var hc := Vector2i(floori(m.x / TILE), floori(m.y / TILE))
	if board.in_bounds(hc) and board.get_piece(hc) != null and move_anim.is_empty():
		hover_cell = hc
	else:
		hover_cell = Vector2i(-1, -1)
	queue_redraw()

	if not timer_started or puzzle_won or puzzle_lost:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		puzzle_lost = true
		lose_reason = "Time's up!"
		_deselect()
		state_changed.emit()

func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE / 2.0, c.y * TILE + TILE / 2.0)

func _draw_tooltip() -> void:
	var p: Piece = board.get_piece(hover_cell)
	if p == null:
		return

	var font := ThemeDB.fallback_font
	var title_size := 20
	var width := 100.0
	var pad := 10.0

	var title := "%s" % [PIECE_NAMES[p.type]]

	var title_h := font.get_height(title_size)
	var panel := Vector2(width, pad * 2.0 + title_h)

	# Position near the mouse, kept inside the screen (view sits at 320, 40)
	var pos := get_local_mouse_position() + Vector2(16, 16)
	pos.x = clampf(pos.x, -320.0 + 4.0, 960.0 - panel.x - 4.0)
	pos.y = clampf(pos.y, -40.0 + 4.0, 680.0 - panel.y - 4.0)

	var accent := _side_color(p.side)
	draw_rect(Rect2(pos + Vector2(3, 4), panel), Color(0, 0, 0, 0.35))      # shadow
	draw_rect(Rect2(pos, panel), Color(0.08, 0.08, 0.14, 0.95))             # background
	draw_rect(Rect2(pos, panel), accent, false, 2.0)                        # border

	var title_y := pos.y + pad + font.get_ascent(title_size)
	draw_string(font, Vector2(pos.x + pad, title_y), title, HORIZONTAL_ALIGNMENT_LEFT, width, title_size, accent.lightened(0.3))

func _start_move_anim(from: Vector2i, to: Vector2i, mover: Piece, victim: Piece) -> void:
	move_anim = {
		"from": from,
		"to": to,
		"type": mover.type,      # the OLD type, shown while sliding
		"side": mover.side,
		"t": 0.0,
		"ate": victim != null,
		"victim_type": victim.type if victim != null else 0,
		"victim_side": victim.side if victim != null else 0,
	}


func _clear_animations() -> void:
	move_anim = {}
	pops.clear()
	particles.clear()
	shake = 0.0

func _update_animations(delta: float) -> void:
	# Slide
	if not move_anim.is_empty():
		move_anim["t"] += delta / MOVE_TIME
		if move_anim["t"] >= 1.0:
			var to: Vector2i = move_anim["to"]
			if move_anim["ate"]:
				_spawn_particles(to, _side_color(move_anim["victim_side"]))
				shake = 6.0
				_play_sound(capture_sound)
			else:
				_play_sound(move_sound)
			pops[to] = POP_TIME
			move_anim = {}

	# Pop timers
	for k in pops.keys():
		pops[k] -= delta
		if pops[k] <= 0.0:
			pops.erase(k)

	for p in particles:
		p["life"] -= delta
		p["pos"] += p["vel"] * delta
		p["vel"].y += 500.0 * delta
	particles = particles.filter(func(p): return p["life"] > 0.0)

	shake = maxf(0.0, shake - 40.0 * delta)


func _spawn_particles(cell: Vector2i, color: Color) -> void:
	var c := cell_center(cell)
	for i in 16:
		var ang := randf() * TAU
		var spd := randf_range(90.0, 240.0)
		particles.append({
			"pos": c,
			"vel": Vector2(cos(ang), sin(ang)) * spd + Vector2(0, -60),
			"life": 0.5,
			"max": 0.5,
			"color": color,
		})

func _side_color(side: int) -> Color:
	return PLAYER_COLOR if side == Piece.Side.PLAYER else ENEMY_COLOR

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := to_local(event.position)
		var cell := Vector2i(floori(local.x / TILE), floori(local.y / TILE))
		_on_cell_clicked(cell)

func _check_all_levels() -> void:
	for i in range(1, MAX_LEVEL + 1):
		var b := Solver.load_board(i)
		if b == null:
			print("Level %d: FAILED TO LOAD" % i)
			continue
		var limit := Solver.load_max_moves(i)
		var result := Solver.solve(b, limit)
		if result == -1:
			print("Level %d: UNSOLVABLE within %d moves" % [i, limit])
		else:
			print("Level %d: OK, best %d moves (limit %d)" % [i, result, limit])

func _on_cell_clicked(cell: Vector2i) -> void:
	if not move_anim.is_empty():
		return
	if puzzle_won or puzzle_lost:
		return
	if not board.in_bounds(cell):
		_deselect()
		return

	if has_selection and cell in legal_moves:
		var mover: Piece = board.get_piece(selected)
		var victim: Piece = board.get_piece(cell)
		_start_move_anim(selected, cell, mover, victim)
		history.append(board.clone())
		board.apply_move(selected, cell)
		move_count += 1
		puzzle_won = _check_win()
		if puzzle_won == false and move_count >= max_moves:
			puzzle_lost = true
			lose_reason = "Out of moves!"
		_deselect()
		state_changed.emit()
		return

	var piece: Piece = board.get_piece(cell)
	if piece != null and piece.side == Piece.Side.PLAYER:
		timer_started = true  
		selected = cell
		has_selection = true
		legal_moves = MoveGenerator.get_moves(board, cell)
		queue_redraw()
	else:
		_deselect()


func _deselect() -> void:
	has_selection = false
	legal_moves.clear()
	queue_redraw()

func load_level(index: int) -> void:
	var path := "res://Puzzles/level_%02d.json" % index
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open " + path)
		return
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		push_error("Bad JSON in " + path)
		return

	level_index = index
	level_name = data.get("name", "")
	time_limit = float(data.get("time_limit", 20))
	max_moves = int(data.get("max_moves", 99))
	lose_reason = ""

	board = Board.new()
	for p in data["pieces"]:
		var type: int = Piece.Type[p["type"]]
		var side: int = Piece.Side[p["side"]]
		board.add_piece(Vector2i(int(p["x"]), int(p["y"])), Piece.new(type, side))

	history.clear()
	move_count = 0
	puzzle_won = false
	puzzle_lost = false
	time_left = time_limit
	timer_started = false
	_deselect()
	state_changed.emit()
	Music.play_for_level(index)

func next_level() -> void:
	if undo_button.disabled == true:
		undo_button.disabled = false
	solved.visible = false
	if level_index < MAX_LEVEL:
		change_level(level_index + 1)

func _draw() -> void:
	var shake_off := Vector2.ZERO
	if shake > 0.0:
		shake_off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	draw_set_transform(shake_off)

	var board_px := Vector2(board.size.x * TILE, board.size.y * TILE)
	draw_rect(Rect2(Vector2(-12, -12), board_px + Vector2(24, 24)), Color("0c2454ff"))
	draw_rect(Rect2(Vector2(-6, -6), board_px + Vector2(12, 12)), Color("03346bff"))

	for x in board.size.x:
		for y in board.size.y:
			var color := LIGHT if (x + y) % 2 == 0 else DARK
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), color)

	if has_selection:
		draw_rect(Rect2(selected.x * TILE, selected.y * TILE, TILE, TILE), SELECT_COLOR)
		for m in legal_moves:
			var c := CAPTURE_COLOR if board.get_piece(m) != null else MOVE_COLOR
			draw_rect(Rect2(m.x * TILE, m.y * TILE, TILE, TILE), c)
			
	var sliding := not move_anim.is_empty()
	for pos in board.cells:
		if sliding and pos == move_anim["to"]:
			continue
		var p: Piece = board.cells[pos]
		_draw_piece(pos, p.type, p.side)

	if sliding:
		_draw_slide()

	for p in particles:
		var k: float = p["life"] / p["max"]
		var col: Color = p["color"]
		col.a = k
		draw_circle(p["pos"], 3.0 + 5.0 * k, col)
	draw_set_transform(Vector2.ZERO)
	if hover_cell != Vector2i(-1, -1):
		_draw_tooltip()


func _draw_piece(pos: Vector2i, type: int, side: int) -> void:
	var phase := (pos.x * 7 + pos.y * 13) * 0.5
	var wave := sin(anim_time * 2.5 + phase)
	var bob := wave * 2.5
	@warning_ignore("shadowed_variable_base_class")
	var scale := 1.0 + wave * 0.02

	if has_selection and pos == selected:
		bob = -absf(sin(anim_time * 6.0)) * 8.0
		scale = 1.1

	if pops.has(pos):
		scale += 0.4 * (pops[pos] / POP_TIME)
	_draw_sprite(cell_center(pos) + Vector2(0, bob), type, side, scale)


func _draw_slide() -> void:
	var from_c := cell_center(move_anim["from"])
	var to_c := cell_center(move_anim["to"])
	var t: float = clampf(move_anim["t"], 0.0, 1.0)
	var e := t * t * (3.0 - 2.0 * t)
	var hop := Vector2(0, -sin(t * PI) * 24.0)

	# The victim stays on its square until the mover arrives
	if move_anim["ate"]:
		_draw_sprite(to_c, move_anim["victim_type"], move_anim["victim_side"], 1.0)

	_draw_sprite(from_c.lerp(to_c, e) + hop, move_anim["type"], move_anim["side"], 1.1)


@warning_ignore("shadowed_variable_base_class")
func _draw_sprite(center: Vector2, type: int, side: int, scale: float) -> void:
	var fill := _side_color(side)
	var tex: Texture2D = textures[type]

	if tex != null:
		var size := Vector2(SPRITE_SIZE, SPRITE_SIZE) * scale
		var rect := Rect2(center - size / 2.0, size)
		draw_texture_rect(tex, Rect2(rect.position + Vector2(2, 4), size), false, Color(0, 0, 0, 0.3))
		draw_texture_rect(tex, rect, false, fill)
		return

	var r := 30.0 * scale
	draw_circle(center + Vector2(2, 4), r, Color(0, 0, 0, 0.3))
	draw_circle(center, r, fill)
	draw_circle(center + Vector2(-10, -10) * scale, 8.0 * scale, Color(1, 1, 1, 0.25))
	draw_arc(center, r, 0.0, TAU, 32, fill.darkened(0.5), 3.0)

	var font := ThemeDB.fallback_font
	var font_size := int(32 * scale)
	var text_pos := Vector2(center.x - TILE / 2.0, center.y + font_size * 0.35)
	draw_string(font, text_pos, LETTERS[type], HORIZONTAL_ALIGNMENT_CENTER, TILE, font_size, Color.WHITE)

func _check_win() -> bool:
	for pos in board.cells:
		if board.cells[pos].side == Piece.Side.ENEMY:
			return false
	return true

func undo() -> void:
	if puzzle_lost or puzzle_won:
		return
	if history.is_empty():
		return
	board = history.pop_back()
	move_count -= 1
	puzzle_won = false
	_deselect()
	state_changed.emit()

func reset() -> void:
	if undo_button.disabled == true:
		undo_button.disabled = false
	if solved.visible == true:
		solved.visible = false
	time_left = TIME_LIMIT
	puzzle_lost = false
	board = Board.new()
	change_level(level_index)
	history.clear()
	move_count = 0
	puzzle_won = false
	_deselect()
	state_changed.emit()

func _make_player(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	if ResourceLoader.exists(path):
		player.stream = load(path)
	add_child(player)
	return player

func _play_sound(player: AudioStreamPlayer, pitch_variance := 0.08) -> void:
	if player == null or player.stream == null:
		return
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	player.play()

func _build_fade() -> void:
	var layer := CanvasLayer.new()
	var font_family = load("res://Assets/fonts/BavarianCrownBoldPersonalBold-x3gXq.otf")
	layer.layer = 100
	add_child(layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color("#0b0f1c")
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0.0
	layer.add_child(fade_rect)

	fade_label = Label.new()
	fade_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fade_label.add_theme_font_size_override("font_size", 56)
	fade_label.add_theme_font_override("font", font_family)
	fade_label.add_theme_color_override("font_color", Color("#ffffff"))
	fade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.add_child(fade_label)

func change_level(index: int, show_title := true) -> void:
	if transitioning:
		return
	transitioning = true
	fade_label.text = ""
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var out_time := FADE_OUT if show_title else 0.15
	var in_time := FADE_IN if show_title else 0.2
	var hold := TITLE_HOLD if show_title else 0.05

	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, out_time)
	tw.tween_callback(_swap_level.bind(index, show_title))
	tw.tween_interval(hold)
	tw.tween_property(fade_rect, "modulate:a", 0.0, in_time)
	tw.tween_callback(_end_transition)

func _swap_level(index: int, show_title: bool) -> void:
	undo_button.disabled = false
	solved.visible = false
	load_level(index)
	if show_title:
		fade_label.text = "%s" % [level_name]

func _end_transition() -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transitioning = false

func _intro() -> void:
	transitioning = true
	fade_rect.modulate.a = 1.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_label.text = "%s" % [level_name]
	var tw := create_tween()
	tw.tween_interval(TITLE_HOLD)
	tw.tween_property(fade_rect, "modulate:a", 0.0, FADE_IN)
	tw.tween_callback(_end_transition)
