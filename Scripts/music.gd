extends Node

const PLAYLIST := [
	"res://Assets/sounds and musics/Main.mp3",
	"res://Assets/sounds and musics/defeat.mp3",
	"res://Assets/sounds and musics/Final.mp3",
]
const LEVELS_PER_TRACK := 6
const FADE_TIME := 1.5
const VOLUME_DB := -8.0

var player_a := AudioStreamPlayer.new()
var player_b := AudioStreamPlayer.new()
var active: AudioStreamPlayer
var current_path := ""
var tense := false


func _ready() -> void:
	for p in [player_a, player_b]:
		p.volume_db = -80.0
		add_child(p)
		p.finished.connect(p.play)    # loop fallback if import Loop is off
	active = player_a


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		for p in [player_a, player_b]:
			p.stream_paused = not p.stream_paused


# Which track belongs to this level. Only tracks that exist are used,
# and the list wraps around if there are more groups than tracks.
func track_for_level(level: int) -> String:
	var available: Array[String] = []
	for path in PLAYLIST:
		if ResourceLoader.exists(path):
			available.append(path)
	if available.is_empty():
		return ""
	var group := (maxi(level, 1) - 1) / LEVELS_PER_TRACK
	return available[group % available.size()]


# Call whenever a level (or the menu) opens. Does nothing if the track is already right.
func play_for_level(level: int) -> void:
	var path := track_for_level(level)
	if path == "" or path == current_path:
		return
	var first_track := current_path == ""
	current_path = path

	var old: AudioStreamPlayer = active
	var next: AudioStreamPlayer = player_b if active == player_a else player_a
	next.stream = load(path)
	next.pitch_scale = old.pitch_scale
	next.volume_db = VOLUME_DB if first_track else -80.0
	next.play()
	active = next

	if first_track:
		old.stop()
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(next, "volume_db", VOLUME_DB, FADE_TIME)
	tw.tween_property(old, "volume_db", -80.0, FADE_TIME)
	tw.chain().tween_callback(old.stop)


func set_tension(on: bool) -> void:
	if on == tense:
		return
	tense = on
	var target := 1.12 if on else 1.0
	var tw := create_tween().set_parallel(true)
	for p in [player_a, player_b]:
		tw.tween_property(p, "pitch_scale", target, 0.8)
