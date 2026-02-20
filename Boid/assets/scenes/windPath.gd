extends Path3D

var _windPaths
var speed = 20
var numberOfTrail = 20
var trailOffset = 0.01
var Radius = 0.01
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Charge les voitures sur les chemins avec le groupe isRoad
	var windPath = self
	for i in numberOfTrail:
		var windPathFollow = PathFollow3D.new()
		self.add_child(windPathFollow)
		var wind = MeshInstance3D.new()
		windPathFollow.add_child(wind)
		wind.mesh = CylinderMesh.new()
		var windMesh = wind.mesh
		var windMaterial = StandardMaterial3D.new()
		windMaterial.albedo_color = Color(1, 1, 1, 1)
		windMesh.surface_set_material(0,windMaterial)
		windMesh.bottom_radius = 0.02
		windMesh.top_radius = 0.02
		windMesh.height = 0.2
		wind.position = windPath.curve.get_point_in(0)
		wind.rotate_x(deg_to_rad(90))
	_windPaths = get_children()
	for i in _windPaths.size():
		var windPathFollow = _windPaths[i]
		windPathFollow.progress_ratio = trailOffset * i
		windPathFollow.get_children()[0].mesh.bottom_radius = 0.01 * (i + 1)
		windPathFollow.get_children()[0].mesh.top_radius = 0.01 * i
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in _windPaths.size():
		var windPath = _windPaths[i]
		windPath.progress += (delta * speed)
		windPath.get_children()[0].mesh.bottom_radius = Radius * (i) * (1-(2*abs(windPath.progress_ratio -0.5)))
		windPath.get_children()[0].mesh.top_radius = Radius * (i + 1) * (1-(2*abs(windPath.progress_ratio -0.5)))
