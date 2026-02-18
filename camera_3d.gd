extends Camera3D

# élément à suivre
var followed : Node3D :
	set(value):
		followed = value
		distancez = self.position.z - followed.position.z
		distancex = self.position.x - followed.position.x
		distancey = self.position.y - followed.position.y
		yminimum = self.position.y / 2
	get():
		return followed

# distance sur l'axe z à respecter
# Note : la caméra a un Z > followed, distancez > 0
var distancez : float
# distance sur l'axe x à respecter (à l'écart ECART_MAX_X près)
var distancex : float
# écart absolu max toléré pour le suivi sur l'axe des x
var distancey : float
# écart absolu max toléré pour le suivi sur l'axe des x
const ECART_MAX_X = 5.0
const ECART_MAX_Z = 1.0
const ECART_MAX_Y = 2.0
# hauteur du followed en dessous laquelle on ne le suivra plus
var yminimum : float
# indicateur d'être trop près du sujet
var troppres : bool = false
# durée max pour rattraper son retard de calage de la caméra trop près
const TEMPS_RECALAGE = 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var ecart : float = self.position.z - followed.position.z
	# Si la caméra est trop loin derrière, on avance la caméra
	if ecart > distancez:
		self.position.z = followed.position.z + distancez
	# Si on est trop près en avant on recule 
	elif ecart < distancez - ECART_MAX_Z :
		self.position.z = followed.position.z + distancez - ECART_MAX_Z
	
	# Si la caméra est trop décalé en X, on va suivre
	if abs(self.position.x - followed.position.x - distancex) > ECART_MAX_X:
		# signe de l'écart (camera trop à gauche > 0, caméra trop à droite < 0)
		var sign_ecart = sign(self.position.x - followed.position.x - distancex)
		# on recale la caméra sur l'écartmax
		self.position.x = followed.position.x + distancex + ECART_MAX_X * sign_ecart
	
	if followed.position.y >= yminimum :
		# Si la caméra est trop haute, on monte la caméra
		if ecart > distancey:
			self.position.y = followed.position.y + distancey
		# Si on est trop bas en hauteur on remonte 
		elif ecart < distancez - ECART_MAX_Y :
			self.position.y = followed.position.y + distancey - ECART_MAX_Y
	
