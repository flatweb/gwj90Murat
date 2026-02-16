extends Node3D

# General configuration
@export var boidScene: PackedScene
@export var numberOfBoids: int = 140
@export var visualRange: float = 300
@export var separationDistance: float = 80
@export var predator: NodePath 
@export var predatorMinDist: float = 400
@export var repulsorMinDIst: float = 5
@export var maxNeighborsColor: int = 20
var _predatorRef

# Rule weights
@export var cohesionWeight: float = 0.3
@export var separationWeight: float = 50
@export var alignmentWeight: float = 1

@export var bordersWeight: float = 300
@export var predatorWeight: float = 2000
@export var repulsorWeight: float = 1000

var _boids = []
var _repulsors = []

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	randomize()
	_predatorRef = get_node(predator)
	
	for i in range(numberOfBoids):
		var instance = boidScene.instantiate()
		add_child(instance)
		_boids.append(instance)
		
		var x = randf_range(-12, 12)
		var z = randf_range(-100, 100)
		instance.set_position(Vector3(x, 5 ,z))
	_repulsors = get_tree().get_nodes_in_group("Repulsor")

func _process(delta):
	_detectNeighbors()
	
	_cohesion()	
	_separation()
	_alignment()
	_borders(delta)
	
	_repulsor()
	_attractor()

func _detectNeighbors():
	for i in range(_boids.size()):
		_boids[i].neighbors.clear()
		_boids[i].neighborsDistances.clear()
	
	for i in range(_boids.size()):		
		for j in range(i+1, _boids.size()):
			var distance = _boids[i].get_position().distance_to(_boids[j].get_position())
			if (distance <= visualRange):
				_boids[i].neighbors.append(_boids[j])
				_boids[j].neighbors.append(_boids[i])
				_boids[i].neighborsDistances.append(distance)
				_boids[j].neighborsDistances.append(distance)

func _cohesion():
	for i in range(_boids.size()):
		var neighbors = _boids[i].neighbors
		
		if (neighbors.is_empty()):
			continue;
		
		var averagePos = Vector3(0,5, 0)
		for closeBoid in neighbors:
			averagePos += closeBoid.get_position()
		averagePos /= neighbors.size()
		
		var direction = averagePos - _boids[i].get_position()
		_boids[i].acceleration += direction * cohesionWeight

func _separation():
	for i in range(_boids.size()):
		var neighbors = _boids[i].neighbors
		var distances = _boids[i].neighborsDistances
		
		if (neighbors.is_empty()):
			continue;
			
		for j in range(neighbors.size()):
			if (distances[j] >= separationDistance):
				continue
			
			var distMultiplier = 1 - (distances[j] / separationDistance)
			var direction = _boids[i].get_position() - neighbors[j].get_position()
			direction = direction.normalized()
			_boids[i].acceleration += direction * distMultiplier * separationWeight
			
func _borders(delta):
	for boid in _boids:
		var pos = boid.get_position()
		var _envDims = Vector4(-12,12,-100,100)
		if (pos.x > 50 or pos.x < -50 or pos.z > 100 or pos.z < -100):
			boid.timeOutOfBorders += delta
			var midPoint = Vector3(0,5,0)
			var dir = (midPoint - boid.get_position()).normalized()
			boid.acceleration += dir * boid.timeOutOfBorders * bordersWeight
		else:
			boid.timeOutOfBorders = 0
			if boid == _boids[1]:
				print("entre bordure")
			
			
func _alignment():
	for i in range(_boids.size()):
		var neighbors = _boids[i].neighbors
		
		if (neighbors.is_empty()):
			continue;
		
		var averageVel = Vector3(0, 0, 0)
		for j in range(neighbors.size()):
			averageVel += neighbors[j].velocity
		averageVel /= neighbors.size()
		
		_boids[i].acceleration += Vector3(averageVel.x,0,averageVel.z) * alignmentWeight

func _attractor():
	for boid in _boids:
		var dist = boid.get_position().distance_to(_predatorRef.get_position())
		if (dist < predatorMinDist):
			var dir =  (_predatorRef.get_position() - boid.get_position()).normalized()
			var multiplier = sqrt( (1 - dist / predatorMinDist))
			boid.acceleration += Vector3(dir.x,0,dir.z) * multiplier * predatorWeight
			
func _repulsor():
	for boid in _boids:
		for repulsor in _repulsors:
			var dist = boid.get_position().distance_to(repulsor.get_position())
			if (dist < repulsorMinDIst):
				var dir = (boid.get_position() - repulsor.get_position()).normalized()
				var multiplier = sqrt( (1 - dist / repulsorMinDIst))
				boid.acceleration += dir * multiplier * repulsorWeight
