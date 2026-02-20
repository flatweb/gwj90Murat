extends Node3D
var frameCount = 0
var trailResolution = 1 # plus bas = plus résolu
var trailDir = Vector3.ZERO
@export var rotationOffset = Vector3.ZERO
@onready var previousPos = get_parent().global_position


func _physics_process(delta: float) -> void:
	#printTrail()
	#print(get_parent().speedVect.length())
	if $"../../../../..".speedVect.length() > 1 && frameCount > trailResolution:
		printTrail(previousPos)
		previousPos = self.global_position
		frameCount = 0
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
	return trailPath

		#trailPath.look_at(previousPos)
func killTrail(trail):
	pass
