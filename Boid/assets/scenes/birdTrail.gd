extends Node3D

func _process(delta: float) -> void:
	if self.velocity.length >= 2:
		var trailPath = MeshInstance3D.new()
		var trailMesh = CylinderMesh.new()
		trailPath.mesh = trailMesh
		var trailMaterial = StandardMaterial3D.new()
		trailMaterial.albedo_color = Color(1, 1, 1, 1)
		trailMesh.surface_set_material(0,trailMaterial)
		trailMesh.bottom_radius = 0.02
		trailMesh.top_radius = 0.02
		trailMesh.height = 0.2
		trailPath.position = self.get_global_position()
