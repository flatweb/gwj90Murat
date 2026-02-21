extends Path3D

var windPathFollow
var speed = 10
var numberOfTrail = 20
var trailOffset = 0.01
var Radius = 0.01
var previousPosition = Vector3.ZERO
var windPath = "res://res/shaders/windParticle.tscn"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	windPathFollow = PathFollow3D.new()
	self.add_child(windPathFollow)
	windPathFollow.progress_ratio = randf_range(0,1)
	var wind = load(windPath).instantiate()
	windPathFollow.add_child(wind)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	windPathFollow.progress += (delta * speed)
	#var windPPMat = windPathFollow.get_children()[0].process_material
	#windPPMat.direction = Basis.from_euler(windPathFollow.rotation) * Vector3.UP
	
