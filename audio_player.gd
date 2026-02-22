extends Node3D
@onready var music1zPosition = $Marker1.global_position.z
@onready var music2zPosition = $Marker2.global_position.z
@onready var music3zPosition = $Marker3.global_position.z
@onready var music4zPosition = $Marker4.global_position.z
@onready var music1Player = $Music1
@onready var music2Player = $Music2
@onready var music3Player = $Music3
@onready var music4Player = $Music4
@onready var music5Player = $Music5
@onready var titleMusicPlayer = $TitleMusic
var crossFadeState = 0
var oiseau
var musicPlayed
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready() -> void:
	oiseau = get_tree().get_nodes_in_group("Oiseau")[0]
	titleMusicPlayer.play()
	titleMusicPlayer.stream_paused = false
	musicPlayed = music1Player
func _process(delta: float) -> void:
	if get_tree().paused == true:
		if musicPlayed.stream_paused == false:
			crossFade(delta,musicPlayed, titleMusicPlayer,0.5)
	else:
		print(musicPlayed)
		if titleMusicPlayer.stream_paused == false :
			crossFade(delta,titleMusicPlayer,musicPlayed,.5)
		else:
			print(crossFadeState)
			if oiseau.get_global_position().z < music1zPosition && musicPlayed != music2Player:
				crossFade(delta,musicPlayed,music2Player,0.2)
			elif oiseau.get_global_position().z < music2zPosition && musicPlayed != music3Player:
				crossFade(delta,musicPlayed,music3Player,0.2)
			elif oiseau.get_global_position().z < music3zPosition && musicPlayed != music4Player:
				crossFade(delta,musicPlayed,music4Player,0.2)
			elif oiseau.get_global_position().z < music4zPosition && musicPlayed != music5Player:
				crossFade(delta,musicPlayed,music5Player,0.2)

func crossFade(delta,from,to,speed):
	if to.stream_paused or to.is_playing() == false:

		to.set_stream_paused(false)
		if to.is_playing() == false:
			to.play()
	crossFadeState += clampf(delta * speed, 0, 1)
	if crossFadeState >= 1:
		crossFadeState = 1
	from.volume_db = linear_to_db(1- crossFadeState)
	to.volume_db = linear_to_db(crossFadeState)
	print(from.volume_db)
	if from.volume_db < -59:
		from.set_stream_paused(true)
		from.volume_db = 0
		if to != titleMusicPlayer:
			musicPlayed = to
		crossFadeState = 0
