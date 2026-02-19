extends Node3D

@export var joueur : CharacterBody3D
@export var angle : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#var joueurXZ = Vector3(joueur.position.x, 0, joueur.position.z)
	#self.position = joueurXZ
	#rotation.y = angle
	var rot = Vector3(0, angle, 0)
	set_rotation_degrees(rot)

	self.position = joueur.position
