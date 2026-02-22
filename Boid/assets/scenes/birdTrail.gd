extends Node3D
var frameCount = 0
var trailResolution = 1 # plus bas = plus résolu
var trailDir = Vector3.ZERO
@export var rotationOffset = Vector3.ZERO
@onready var previousPos = get_parent().global_position
var trailCollection = Array()
var trailNumber: int = 0
var trailLength = 50
func _ready() -> void:
	trailCollection.resize(trailLength + 1)
	
func _physics_process(delta: float) -> void:
	#print(get_parent().speedVect.length())
	if $"../../../../..".speedVect.length() > 1 && frameCount > trailResolution:
		if trailNumber == trailLength+1:
			trailNumber = 0
		#printTrail(previousPos)
		previousPos = self.global_position
		frameCount = 0
		#print(trailNumber)
		killTrail(trailNumber)
		trailNumber += 1
	else:
		frameCount += 1
		
		
		
	
		
func printTrail(previousPosition: Vector3):
	var trailPivot = Node3D.new()
	var trailPath = MeshInstance3D.new()
	get_tree().root.add_child(trailPivot)
	trailPivot.add_child(trailPath)
	var trailMesh = TubeTrailMesh.new()
	trailPath.mesh = trailMesh
	var trailMaterial = StandardMaterial3D.new()
	trailMaterial.albedo_color = Color(1, 1, 1, 1)
	trailMesh.surface_set_material(0,trailMaterial)
	trailMesh.radius = 0.02
	trailMesh.section_length = 0.05
	trailPivot.look_at_from_position(self.get_global_position(), previousPos)
	trailPath.rotation = rotationOffset
	trailCollection[trailNumber] = trailPivot
	return trailPath

		#trailPath.look_at(previousPos)
func killTrail(trail):
	var trailPastNumber = trailNumber +1
	if trailPastNumber > trailLength :
		trailPastNumber = 0
	if trailCollection[trailPastNumber] != null:
		trailCollection[trailPastNumber].queue_free()
