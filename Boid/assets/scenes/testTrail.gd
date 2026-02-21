#@tool
extends GPUParticles3D
var pointPrecedent = Vector3.ZERO
func _process(delta: float) -> void:
	self.process_material.direction = (global_position - pointPrecedent).normalized()
	pointPrecedent = self.global_position
	
