extends Node3D

@export var joueur : CharacterBody3D
@export var angle : int
@export var camera : Camera3D
@export var camera_distance_default : float = 39 #defaut = 39
var camera_distance
@export var camera_min_distance : int = 10
@export var camera_max_distance : int = 60
@export var zoom_increment : float = 3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_distance = camera_distance_default
	update_camera_distance()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#var joueurXZ = Vector3(joueur.position.x, 0, joueur.position.z)
	#self.position = joueurXZ
	#rotation.y = angle
	var rot = Vector3(0, angle, 0)
	set_rotation_degrees(rot)

	self.position = joueur.position
	
	var zoom = camera_distance
	if Input.is_action_just_pressed("scroll_down"):
		zoom += zoom_increment
		update_camera_distance()
	if Input.is_action_just_pressed("scroll_up"):
		zoom -= zoom_increment
		update_camera_distance()
	camera_distance = clamp(zoom, camera_min_distance, camera_max_distance)

func update_camera_distance():
	camera.position.y = camera_distance
	camera.look_at(self.position)
