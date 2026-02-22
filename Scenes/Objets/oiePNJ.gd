extends Node3D

func _ready() -> void:
	var randomTime = randf_range(0,$AnimationPlayer.get_section_end_time())
	$AnimationPlayer.seek(randomTime)
