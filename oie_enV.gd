extends Path3D

@onready var path = $PathFollow3D

func _ready() -> void:
	path.set_script("res://Boid/assets/scripts/roadFollow.gd")
	
