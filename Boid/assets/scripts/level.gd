extends Node3D
@export var carScene: PackedScene
@export var carResScript: Script

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(carResScript)
	#Charge les voitures sur les chemins avec le groupe isRoad
	var _roads = get_tree().get_nodes_in_group("isRoad")
	for road in _roads:
		var carPathScript = carResScript.get_path()
		var carScript = load(carPathScript)
		var roadPathFollow = PathFollow3D.new()
		roadPathFollow.set_script(carScript)
		road.add_child(roadPathFollow)
		var car = carScene.instantiate()
		roadPathFollow.add_child(car)
		print("Est ce que le pathCar a un script" + String(roadPathFollow.get_path()))
		if roadPathFollow.get_script() == carScript :
			print("oui")
