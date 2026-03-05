extends Node3D
@export var carScene: PackedScene
@export var carResScript: Script
@export var numberOfCarByRoad: int = 10
@export var carTextures : Array[Texture2D]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Limites/StaticBody3D17.queue_free()
	$Limites/StaticBody3D.queue_free()
	
	#FIXME : introduit pour éviter un crash du Godot sur les PC du fablab
	# il suffit de passer --nocol en argument pour supprimer les collisions des montagnes
	for argument in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			#arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			if argument == "--nocol":
				if OS.is_debug_build():
					$MONTAGNES_TERRAIN/montagnes_collisions.queue_free()
	
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
			apply_texture(car.get_child(0))
			roadPathFollow.add_child(car)
			roadPathFollow.progress_ratio = randf()
			
		#print("Est ce que le pathCar a un script" + String(roadPathFollow.get_path()))
			if roadPathFollow.get_script() == carScript :
				pass
				#print("oui")

func apply_texture(mesh:MeshInstance3D):
	var randn = randi_range(0, carTextures.size()-1)
	if mesh.material_override == null:
		mesh.material_override = StandardMaterial3D.new()
	mesh.material_override.albedo_texture = carTextures[randn]
	pass
