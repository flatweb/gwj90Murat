extends Area3D

var vitessesurXZ : Vector3
var limites : AABB
@export var scalemax : float

const DEFAULT_VITESSE : float = 0.2
const RATIO_X_SUR_Z : float = 4.0
const ECHELLE_1 : Vector3 = Vector3(1.0,1.0,1.0)

var encreation : bool = true
var endestruction : bool = false

func _init():
	scale = ECHELLE_1 * 0.01

func _ready():
	encreation = true
	endestruction = false

func createin(nuage_area_size):
	limites = nuage_area_size
	limites.position.y = 10.0
	limites.end.y = 30.0
	
	position.y = randf_range(limites.position.y,limites.end.y)
	position.z = randf_range(limites.position.z,limites.end.z)
	position.x = randf_range(limites.position.x,limites.end.x)
	scalemax = randf_range(1.0,2.0)
	# on commence tout petit
	scale = ECHELLE_1 * 0.01
	
	encreation = true

## Ajout d'un vent qui fait déplacer les nuages
func ajoutervent(vitesse : Vector3) -> Vector3 :
	if vitesse != Vector3.ZERO :
		vitessesurXZ = vitesse
	else:
		vitessesurXZ = Vector3(randf_range(-RATIO_X_SUR_Z,+RATIO_X_SUR_Z), \
							   0,
							   randf_range(-1,1))
		vitessesurXZ = vitessesurXZ.normalized() * DEFAULT_VITESSE
	return vitessesurXZ

func _process(delta: float) -> void:
	if encreation :
		scale = scale + ECHELLE_1 * randf_range(0.5, 3.0) * delta
		if scale.y >= scalemax :
			encreation = false
	if endestruction :
		var supscale = ECHELLE_1 * randf_range(0.5, 3.0) * delta
		if supscale.y >=scale.y :
			queue_free()
		else:
			scale = scale - supscale

	position += vitessesurXZ * delta
	var x = limites.size.x
	var p = position
	if limites.size.x > 0.0:
		if not endestruction:
			if not limites.has_point(position) :
				endestruction = true
		
