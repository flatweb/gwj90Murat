extends Area3D

var vitessesurXZ : Vector3 = Vector3.ZERO # par défaut ne bouge pas
var limites : AABB
@export var scalemax : float
var withlightning : bool = false :
	set(b):
		withlightning = b
		if b : $TimerEclair.start()
		else : $Timer.stop()
	get():
		return withlightning

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
	# création progressive
	if encreation :
		scale = scale + ECHELLE_1 * randf_range(0.5, 3.0) * delta
		if scale.y >= scalemax :
			encreation = false
	# destruction progressive
	if endestruction :
		var supscale = ECHELLE_1 * randf_range(0.5, 3.0) * delta
		if supscale.y >=scale.y :
			queue_free()
		else:
			scale = scale - supscale
	
	# Eclairs (fadeout)
	if get_node_or_null("OmniLight3D") != null:
		var energy : float = $OmniLight3D.light_energy
		if energy > 0.0 :
			energy = max(0.0, energy - 20.0 * delta)
			$OmniLight3D.light_energy = energy

	# Déplacement du nuage
	position += vitessesurXZ * delta
	var x = limites.size.x
	var p = position
	if limites.size.x > 0.0:
		if not endestruction:
			if not limites.has_point(position) :
				endestruction = true
	


func _on_timer_eclair_timeout() -> void:
	if randf_range(0,1) <= 0.05 :
		$OmniLight3D.light_energy = 10.0
	pass # Replace with function body.
	
