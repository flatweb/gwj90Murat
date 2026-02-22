extends Node3D

class_name Boid

@export var maxVelocity: float = 5
@export var maxAcceleration: float = 20
@export var rotationOffset: Vector3 = Vector3(0,PI/2,0)

@export var baseColor: Color
@export var specialColor: Color
@export var colorTransitionSpeed: float = 1

@export var syncTrail: bool = true
@export var trail: NodePath

var spawnPoint
var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO

var neighbors := []
var neighborsDistances := []
var timeOutOfBorders := 0.0
var isOutOfBorder = false

func _ready():

	
	velocity = Vector3(randf_range(-maxVelocity, maxVelocity),
						randf_range(-maxVelocity, maxVelocity),
						randf_range(-maxVelocity, maxVelocity))
	
func _process(delta):
	velocity += acceleration.limit_length(maxAcceleration * delta)
	velocity = velocity.limit_length(maxVelocity)
	acceleration.x = 0
	acceleration.z = 0
	acceleration.y = 0
	position += velocity * delta
	if velocity != Vector3.ZERO :
		look_at(global_position + velocity)
	
	rotation += rotationOffset


func _on_static_body_3d_body_entered(body: Node3D) -> void:
	isOutOfBorder = true


func _on_static_body_3d_body_exited(body: Node3D) -> void:
	isOutOfBorder = false
