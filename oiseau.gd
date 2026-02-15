extends CharacterBody3D

# Vitesse de rotation sur virage
const ROTSPEED = 0.2
# Vitesse de rotation sur retour naturel à la position stable
const ROTBACKSPEED = 0.04
# angle de rotation par seconde lors d'un virage
const ANGLE_VIRAGE = 1.2

# Vitesse de vol horizontal
var speedfront : float = 4.0
# Vitesse de vol latéral
var speedlat : float = 2.0
 
var speedVect : Vector3

func _ready():
	speedVect = Vector3(0,0,-speedfront)
	pass

func _physics_process(delta: float) -> void:
	var change = Input.get_axis("droite","gauche")
	
	if change:
		# changement de direction
		var angle : float = change*ANGLE_VIRAGE*delta
		self.rotate_y(angle)
		speedVect = speedVect.rotated(Vector3.UP, angle)
		# changement d'inclinaison
		if abs(rotation.z) < PI/4 :
			self.rotate_z(change*ROTSPEED*delta)
	else:
		# retour naturel à une inclinaison normale sans action
		if abs(rotation.z) < ROTBACKSPEED*delta :
			rotation.z = 0
		else:
			self.rotate_z(-sign(rotation.z)*ROTBACKSPEED*delta)
			#self.rotate_y(change*0.2*delta)
	
	move_and_collide(speedVect*delta)
