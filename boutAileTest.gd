extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = $"../OIE/Armature/Skeleton3D".get_bone_global_pose(8).origin
	global_basis = $"../OIE/Armature/Skeleton3D".get_bone_global_pose(8).basis
