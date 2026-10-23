extends Node

var muted := false
var music: AudioStreamPlayer
var pool: Array[AudioStreamPlayer] = []
var next := 0
var music_level := 0.45
var effects_level := 0.75
var fade: Tween

func _ready() -> void:
	music = AudioStreamPlayer.new()
	var stream := load("res://assets/audio/planete-brulee.mp3") as AudioStreamMP3
	stream.loop = true
	music.stream = stream
	music.volume_db = -60
	add_child(music)
	music.play()
	fade = create_tween()
	fade.tween_property(music,"volume_db",linear_to_db(music_level),1.8)
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.volume_db = linear_to_db(effects_level)-5
		add_child(player)
		pool.append(player)

func play(cue: String) -> void:
	if muted: return
	var player := pool[next % pool.size()]
	next += 1
	player.stream = load("res://assets/audio/%s.wav" % cue)
	player.play()

func toggle() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0,muted)

func set_music(value: float) -> void:
	music_level = value
	if fade: fade.kill()
	music.volume_db = linear_to_db(maxf(0.0001,value))

func set_effects(value: float) -> void:
	effects_level = value
	for player in pool: player.volume_db = linear_to_db(maxf(0.0001,value))-5

func stop_all() -> void:
	if fade: fade.kill()
	if is_instance_valid(music): music.stop()
	for player in pool:
		if is_instance_valid(player): player.stop()

func _exit_tree() -> void:
	stop_all()
