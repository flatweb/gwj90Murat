extends Node3D
@export var carScene: PackedScene
@export var carResScript: Script
@export var numberOfCarByRoad: int = 5
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Charge les voitures sur les chemins avec le groupe isRoad
	var _roads = get_tree().get_nodes_in_group("isRoad")
	for road in _roads:
		var carPathScript = carResScript.get_path()
		var carScript = load(carPathScript)
		for i in numberOfCarByRoad:
			var roadPathFollow = PathFollow3D.new()
			roadPathFollow.set_script(carScript)
			road.add_child(roadPathFollow)
			var car = carScene.instantiate()
			roadPathFollow.add_child(car)
			roadPathFollow.progress_ratio = randf()
			
		#print("Est ce que le pathCar a un script" + String(roadPathFollow.get_path()))
			if roadPathFollow.get_script() == carScript :
				print("oui")
