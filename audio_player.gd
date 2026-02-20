extends Node3D
@onready var musicLibrary = get_children()
@onready var zoneOfGame = get_tree().get_nodes_in_group("isMapArea")
@onready var oiseau = get_tree().get_nodes_in_group("Oiseau")
var sizeOfZone
# Called every frame. 'delta' is the elapsed time since the previous frame.
func ready():
	print(zoneOfGame)
	for i in zoneOfGame.size():
		sizeOfZone[i] = get_combined_aabb(zoneOfGame[i])
		print(sizeOfZone[i])
		
func _process(delta: float) -> void:
	var i = 0
	if oiseau.global_position.x > sizeOfZone[i].position.z && oiseau.global_position.x < sizeOfZone[i].end.z &&oiseau.global_position.z > sizeOfZone[i].end.z && oiseau.global_position.z < sizeOfZone[i].end.z:
		print("is in Zone 1")
	
func get_combined_aabb(node: Node) -> AABB:
	var state := [AABB(), false]
	_collect_aabb(node, state)
	return state[0]

func _collect_aabb(node: Node, state: Array) -> void:
	if node is VisualInstance3D:
		var aabb = (node as VisualInstance3D).get_transformed_aabb()
		if not state[1]:
			state[0] = aabb
			state[1] = true
		else:
			state[0] = state[0].merge(aabb)
	
	for child in node.get_children():
		_collect_aabb(child, state)
