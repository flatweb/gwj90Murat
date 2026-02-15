extends CharacterBody3D

# Vitesse de rotation sur virage
const ROTSPEED = 5.0
# Vitesse de rotation sur retour naturel à la position stable
const ROTBACKSPEED = 2.0
# angle de rotation par seconde lors d'un virage
const ANGLE_VIRAGE = 1.2
# facteur de rotation pour ne pas sortir de la zone
const FACTEUR_CORRECTION = 4.0

# Vitesse de vol horizontal
var speedfront : float = 4.0 / 2
# Vitesse de vol latéral
var speedlat : float = 2.0
# limite en +X ou -X de la position de l'oiseau
var limite_x : float = 10.0 # valeur arbitraire à fixer par set_limite_x
# de quel côté on a atteint la limite ?
var angle_correction = 0

enum action { AUCUNE, CORRECTION, ATTENTE, LOOPING }

# indicateur de correction de trajectoire.
# On perd le contrôle tant qu'on est pas revenu dans la zone et de face
var enaction : bool = false
var actionencours : action = action.AUCUNE

var speedVect : Vector3

func _ready():
	speedVect = Vector3(0,0,-speedfront)
	pass

func set_limite_x(value):
	limite_x = value

func virage(change : float, delta : float):
	var angle : float = change*ANGLE_VIRAGE*delta
	if enaction and actionencours == action.CORRECTION:
		#print (rotation.y)
		if rotation.y == 0.0:
			angle = 0.0
		elif sign (rotation.y+angle) != sign(rotation.y):
			# on a dépassé la remise dans l'axe
			angle = -rotation.y
	if angle != 0.0: self.rotate_y(angle)
	speedVect = speedVect.rotated(Vector3.UP, angle)
	
	# changement d'inclinaison (axe Z)
	if abs($Forme.rotation.z) < PI*3/8 :
		#print("vire from ",$Forme.rotation.z, " for ",rad_to_deg(change*ROTSPEED*delta))
		$Forme.rotate_z(min(max(change,-1),1)*ROTSPEED*delta)
	else:
		#print($Forme.rotation.z)
		pass

func looping():
	pass

func attente():
	enaction = true
	actionencours == action.CORRECTION
	pass

func _process(_delta):
	if Input.is_action_just_pressed("attente"):
		attente()
		
func _physics_process(delta: float) -> void:
	var change = Input.get_axis("droite","gauche")
	
	if not enaction:
		if change != 0:
			# changement de direction
			virage(change,delta)
		else:
			#print("roty=",rotation.y)
			# retour naturel à une inclinaison normale sans action
			if abs($Forme.rotation.z) < ROTBACKSPEED*delta :
				$Forme.rotation.z = 0
			else:
				$Forme.rotate_z(-sign($Forme.rotation.z)*ROTBACKSPEED*delta)
	elif enaction and actionencours == action.CORRECTION:
		#print ("",speedVect.z," angle ",angle_correction)
		virage(angle_correction,delta)
		if abs(rotation.y) <= 0.01 :
			enaction = false
			angle_correction = 0.0
	
	# S'assurer qu'on ne va pas toucher les limites en X de la zone de vol
	if not enaction and abs(speedVect.x * 3.0 + position.x) > limite_x :
		# on approche trop du bord
		# on force un virage
		angle_correction = -sign(speedVect.z)* sign(position.x)*FACTEUR_CORRECTION
		virage(angle_correction,delta)
		enaction = true
		actionencours = action.CORRECTION
	
	# On pourrait aussi tester par rapport à des CollisionShapes latérales sur le game
	#move_and_collide(speedVect*???, true)
	
	move_and_collide(speedVect*delta)
