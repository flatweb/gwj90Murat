extends CharacterBody3D

# Vitesse de rotation sur virage
const ROTSPEED = 0.1
# Vitesse de rotation sur retour naturel à la position stable
const ROTBACKSPEED = 0.02

# Vitesse de vol horizontal
var speed : float = 4.0
# Vitesse de vol latéral
var speedlat : float = 2.0
 
func _ready():
	pass

func _physics_process(delta: float) -> void:
	var change = Input.get_axis("droite","gauche")
	
	if change:
		if abs(rotation.z) < PI/4 :
			self.rotate_z(change*ROTSPEED*delta)
	else:
		if abs(rotation.z) < ROTBACKSPEED*delta :
			rotation.z = 0
		else:
			self.rotate_y(-sign(rotation.z)*ROTBACKSPEED*delta)
	
	var moving : Vector3 = Vector3(-change*speedlat*delta,0,-speed*delta)
	move_and_collide(moving)
