extends Node3D

@export var joueur : CharacterBody3D
@export var initial_angle : int = -45
@export var camera : Camera3D
@export var camera_distance_default : float = 20 # avant c'etait 35-39
var camera_distance
@export var camera_min_distance : int = 7 # moins et on voit trop l'horizon
@export var camera_max_distance : int = 60
@export var zoom_increment : float = 3.0
@export var mouse_sensitivity : float = 0.1

func _ready() -> void:
	camera_distance = camera_distance_default
	update_camera_distance()
	set_rotation_degrees(Vector3(0, initial_angle, 0)) # initial camera rotation
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Camera3D/Boussole.rotation.z = -self.rotation.y

func _process(delta: float) -> void:
	self.position = joueur.position
	if Input.is_action_pressed("zoom_down"):
		unzoom(zoom_increment*delta*2)
	if Input.is_action_pressed("zoom_up"):
		zoom(zoom_increment*delta*2)
	if Input.is_action_just_pressed("scroll_down"):
		# ET REGARDE LE JOUEUR
		unzoom(zoom_increment)
	if Input.is_action_just_pressed("scroll_up"):
		zoom(zoom_increment)
	
	var cam_rot = Input.get_axis("cam_left","cam_right")
	if cam_rot != 0.0 :
		rotate_y(+delta*cam_rot)

func zoom(increment):
	var dist = camera_distance
	dist -= increment
	camera_distance = clamp(dist, camera_min_distance, camera_max_distance)
	update_camera_distance()

func unzoom(increment):
	var dist = camera_distance
	dist += increment
	camera_distance = clamp(dist, camera_min_distance, camera_max_distance)
	update_camera_distance()
		
	
# CHANGE LA DISTANCE ENTRE LA CAMERA ET LE CAMERA RIG (qui a la meme position que le joueur)
func update_camera_distance():
	camera.position.y = camera_distance
	camera.look_at(self.position) # la camera regarde l'orgine du CameraRig (qui a la meme position que le joueur)
	
func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("clic"):
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			# orientation de la boussole
			$Camera3D/Boussole.rotation.z = -self.rotation.y

func _unhandled_input(event: InputEvent): 
	if event is InputEventMouseButton:
		var evmouse = event as InputEventMouseButton
		if evmouse.pressed :
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#elif event.is_action_pressed("ui_cancel"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
