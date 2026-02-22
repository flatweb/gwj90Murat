extends Node3D

@export var windWidth: float = 20
@export var windIntensity: int = 10
@export var windSpeed: float = 10
@export var rotationOffSet: Vector3 = Vector3(0,0,0) 
var wind1 = "res://res/shaders/wind1.tres"
var wind2 = "res://res/shaders/wind2.tres"
var wind3 = "res://res/shaders/wind3.tres"
var wind4 = "res://res/shaders/wind4.tres"
var wind5 = "res://res/shaders/wind5.tres"
var winds = [wind1,wind2,wind3,wind4,wind5]
var windPathScript = load("res://Boid/assets/scenes/windPath.gd")

func _ready() -> void:
	for i in range(windIntensity):
		var windPath = Path3D.new()
		add_child(windPath)
		var xPos = randf_range(-windWidth,windWidth)
		var zPos = randf_range(-10,10)
		var yPos = randf_range(0,30)
		windPath.position = Vector3(xPos,yPos,zPos)
		windPath.curve = load(winds[randi_range(0,winds.size() -1)])
		windPath.set_rotation(rotationOffSet)
		windPath.set_script(windPathScript)
		windPath.add_to_group("isWind")
		windPath.numberOfTrail = abs(10 * windSpeed)
		windPath._ready()
		windPath.set_process(true)
