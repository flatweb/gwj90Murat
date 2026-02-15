extends CharacterBody3D

# Vitesse de rotation sur virage
const ROTSPEED = 5.0
# Vitesse de rotation sur retour naturel à la position stable
const ROTBACKSPEED = 2.0
# angle de rotation par seconde lors d'un virage
const ANGLE_VIRAGE = 1.2
# facteur de rotation pour ne pas sortir de la zone
const FACTEUR_CORRECTION = 5.0

# Vitesse de vol horizontal
var speedfront : float = 4.0
# Vitesse de vol latéral
var speedlat : float = 2.0
# limite en +X ou -X de la position de l'oiseau
var limite_x : float = 10.0 # valeur arbitraire à fixer par set_limite_x

var speedVect : Vector3

func _ready():
	speedVect = Vector3(0,0,-speedfront)
	pass

func set_limite_x(value):
	limite_x = value

func virage(change : float, delta : float):
	var angle : float = change*ANGLE_VIRAGE*delta
	self.rotate_y(angle)
	speedVect = speedVect.rotated(Vector3.UP, angle)
	
	# changement d'inclinaison (axe Z)
	if abs($Forme.rotation.z) < PI*3/8 :
		#print("vire from ",$Forme.rotation.z, " for ",rad_to_deg(change*ROTSPEED*delta))
		$Forme.rotate_z(min(max(change,-1),1)*ROTSPEED*delta)
	else:
		#print($Forme.rotation.z)
		pass
	
func _physics_process(delta: float) -> void:
	var change = Input.get_axis("droite","gauche")
	
	if change:
		# changement de direction
		virage(change,delta)
	else:
		# retour naturel à une inclinaison normale sans action
		if abs($Forme.rotation.z) < ROTBACKSPEED*delta :
			$Forme.rotation.z = 0
		else:
			$Forme.rotate_z(-sign($Forme.rotation.z)*ROTBACKSPEED*delta)
	
	# S'assurer qu'on ne va pas toucher les limites en X de la zone de vol
	if abs(speedVect.x * 3.0 + position.x) > limite_x :
		# on approche trop du bord
		# on force un virage
		var cote_ecart = sign(speedVect.x * 3.0 + position.x - limite_x)
		virage(-sign(speedVect.z)*cote_ecart*FACTEUR_CORRECTION,delta)
	
	# On pourrait aussi tester par rapport à des CollisionShapes latérales sur le game
	#move_and_collide(speedVect*???, true)
	
	move_and_collide(speedVect*delta)
