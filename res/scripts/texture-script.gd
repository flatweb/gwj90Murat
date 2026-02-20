extends Node3D

@export var tex : Texture2D
#var children : MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var child := get_node_or_null("Child") as MeshInstance3D
	#child.albedo_texture = tex
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
