extends Node3D
var frameCount = 0
var trailDir = Vector3.ZERO
@export var rotationOffset = Vector3.ZERO
@onready var previousPos = get_parent().global_position
var trailCollection = Array()
var trailNumber: int = 0
var trailLength = 50
func _ready() -> void:
	trailCollection.resize(trailLength + 1)
	
func _physics_process(_delta: float) -> void:
	#print(get_parent().speedVect.length())
	if trailNumber == trailLength+1:
		trailNumber = 0
	if $"../../../../..".speedVect.length() > 1:
		$GPUParticles3D.emitting = true
	else:
		$GPUParticles3D.emitting = false
