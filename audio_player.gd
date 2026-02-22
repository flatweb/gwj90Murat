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
var crossFadeState = 0
var oiseau
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready() -> void:
	oiseau = get_tree().get_nodes_in_group("Oiseau")[0]
	music1Player.play()
func _process(delta: float) -> void:
	if oiseau.get_global_position().z < music1zPosition && crossFadeState < 1:
		crossFade(delta,music1Player,music2Player,0.2)
	elif oiseau.get_global_position().z < music2zPosition && music2Player.is_playing():
		crossFade(delta,music2Player,music3Player,0.2)
	elif oiseau.get_global_position().z < music3zPosition && music3Player.is_playing():
		crossFade(delta,music3Player,music4Player,0.2)
	elif oiseau.get_global_position().z < music4zPosition && music3Player.is_playing():
		crossFade(delta,music4Player,music5Player,0.2)
func crossFade(delta,from,to,speed):
	if to.is_playing() == false:
		crossFadeState = 0
		to.play()
	crossFadeState += clampf(delta * speed, 0, 1)
	if crossFadeState >= 1:
		crossFadeState = 0.999
	from.volume_db = linear_to_db(1- crossFadeState)
	to.volume_db = linear_to_db(crossFadeState)
	if from.volume_db < -70:
		from.stop()
