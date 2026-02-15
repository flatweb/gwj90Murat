extends Camera3D

# élément à suivre
var followed : Node3D :
	set(value):
		followed = value
		distancez = self.position.z - followed.position.z
		distancex = self.position.x - followed.position.x
		pass
	get():
		return followed
# distance sur l'axe z à respecter
# Note : la caméra a un Z > followed, distancez > 0
var distancez : float
# distance sur l'axe x à respecter (à l'écart ECART_MAX_X près)
# Note : la caméra a un Z > followed, distancez > 0
var distancex : float
# écart absolu max toléré pour le suivi sur l'axe des x
const ECART_MAX_X = 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Si la caméra est trop loin derrière, on avance la caméra
	if self.position.z - followed.position.z > distancez:
		self.position.z = followed.position.z + distancez
	# Si on est troip près on ne fait rien
	
	# TODO : gérer aussi le latéral
	
