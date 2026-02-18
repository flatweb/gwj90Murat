extends Area3D

var vitessesurXZ : Vector3
var limites : AABB

const DEFAULT_VITESSE : float = 0.2
const RATIO_X_SUR_Z : float = 4.0

func initlimites(aabb : AABB):
	limites = aabb
	limites.position.y = 10.0
	limites.end.y = 30.0
	
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
	position += vitessesurXZ * delta
	var x = position
	if not limites.has_point(position) :
		queue_free()
		
