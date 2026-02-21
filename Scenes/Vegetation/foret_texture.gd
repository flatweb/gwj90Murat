extends Node3D

func _ready() -> void:
	texture()

#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("ui_accept"):
	#	texture()

func texture():
	for node in get_tree().get_nodes_in_group("arbre"):
		#var randn = randi_range(0, textures.size()-1)
		node.apply_random_winter_texture()
