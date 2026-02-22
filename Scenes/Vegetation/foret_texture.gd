extends Node3D

@export_enum("hiver", "printemps", "ete") var saison: String
var children_trees : Array[Node]

func _ready() -> void:
	texture()

#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("ui_accept"):
	#	texture()

func texture():
	for node in get_children():
		if node.is_in_group("arbre"):
			match saison:
				"hiver":
					node.apply_random_winter_texture()
				"printemps":
					node.apply_random_spring_texture()
				"ete":
					node.apply_random_spring_texture()
		if node.is_in_group("fleur"):
			pass
