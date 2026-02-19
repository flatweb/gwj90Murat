extends CollisionShape3D
class_name LimiteShape3D

@export var normal : Vector3 = Vector3.RIGHT 

func get_real_normal():
	return normal.rotated(Vector3.UP,rotation.y) \
				 .rotated(Vector3.FORWARD,rotation.z) \
				 .rotated(Vector3.RIGHT,rotation.x)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
