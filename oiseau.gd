extends CharacterBody3D

# Vitesse de rotation sur virage
const ROTSPEED = 5.0
# Vitesse de rotation sur retour naturel à la position stable
const ROTBACKSPEED = 2.0
# angle de rotation par seconde lors d'un virage
const ANGLE_VIRAGE = 1.2
# facteur de rotation pour ne pas sortir de la zone
const FACTEUR_CORRECTION = 3.0
# facteur de rotation pour l'attente en boucle, rotation lente
const FACTEUR_ATTENTE = 0.7

# Vitesse de vol horizontal
var speedfront : float = 4.0
# Vitesse de vol latéral
var speedlat : float = 2.0
# Vitesse de vol en piqué
var speeddown : float = speedfront * 1.5
# Altitude où on commence à freiner le piqué pour atterrir
var altitudefreinage : float = 5.0
# vitesse de descente sous laquelle on ne passe pas en descente
const VITESSE_Y_MIN = 3.0

# limite en +X ou -X de la position de l'oiseau
var limite_x : float = 10.0 # valeur arbitraire à fixer par set_limite_x
# de quel côté on a atteint la limite ?
var autorotspeed = 0

enum action { AUCUNE, CORRECTION, ATTENTE, LOOPING, ATTERRISSAGE, ATTERRI, DECOLLAGE }

# indicateur de correction de trajectoire.
# On perd le contrôle tant qu'on est pas revenu dans la zone et de face
var enaction : bool = false
var actionencours : action = action.AUCUNE

# autre camera 
var prevcam : Camera3D

# Vitesse de croisière
var speedVect : Vector3
# position de départ, notamment pour remonter à l'altitude Y
var startpos : Vector3

func _ready():
	speedVect = Vector3(0,0,-speedfront)
	self.rotation = Vector3.ZERO
	startpos = self.position
	$Indicateurs.hide()
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

func calc_rot_speed(_act : action, facteur : float) -> float :
		var signx : int
		if position.x == 0:
			# si on est vraiment dans l'axe, on choisit le côté au hasard
			signx = randi_range(0,1)*2-1
		else :
			signx = sign(position.x)
		var signz = -1
		if speedVect.z != 0 :
			signz = sign(speedVect.z)
		var rotspeed : float = -signz*signx*facteur
		#print ("rotspeed auto=", rotspeed)
		return rotspeed
	
func attente():
	if enaction == false :
		enaction = true
		actionencours = action.ATTENTE
		autorotspeed = calc_rot_speed(actionencours,FACTEUR_ATTENTE)
		#print ("angle auto=", angle_correction)

func correction():
	if enaction == false :
		enaction = true
		actionencours = action.CORRECTION
		autorotspeed = calc_rot_speed(actionencours,FACTEUR_CORRECTION)
		#print ("angle auto=", angle_correction)

func descente(delta : float):
	# Note : comme on descend la vitesse en Y est négative
	# si on est trop bas, on freine en Y, mais aussi en front
	if position.y < altitudefreinage:
		var newspeedY = speedVect.y * position.y/altitudefreinage*(1-delta)
		newspeedY = min(-VITESSE_Y_MIN,newspeedY)
		# on risque de remonter ?
		if newspeedY >= 0:  # mais avec la formule, ça ne risque pas
			# donc on se contente d'un décélération lente
			newspeedY = min(-VITESSE_Y_MIN,speedVect.y * 0.9*(1-delta))
		# Si on est déjà très bas, 
		if position.y < 1.0: # FIXME : constante ou calcul
			newspeedY = VITESSE_Y_MIN #FIXME ? C'est un peu brutal
		speedVect.y=newspeedY
		print("en freinage à ",position.y,", speedY=",speedVect.y)
		# changement progressif d'inclinaison (axe X vers le haut)
		$Forme.rotation.x *= position.y/altitudefreinage
	# accélération :
	if speedVect.y > -speeddown:
		# on accélère un peu
		speedVect.y -= delta * (0.5)*speeddown
		if speedVect.y < -speeddown :
			speedVect.y = speeddown
		# changement progressif d'inclinaison (axe X vers le bas)
		if abs($Forme.rotation.x) < PI/4 :
			#print("vire from ",$Forme.rotation.z, " for ",rad_to_deg(change*ROTSPEED*delta))
			$Forme.rotate_x(-0.1*ROTSPEED*delta)
	print ("vit descente Y=",speedVect.y)
	
func remonte(delta : float):
	if speedVect.y < 0:
		# on est toujours en descente, on commence par freiner, assez fort
		speedVect.y += delta * (0.75)*speeddown
		if speedVect.y > 0 :
			# on se stabilise
			speedVect.y = 0
	elif speedVect.y < speeddown/2:
		# on commence à remonter, lentement
		speedVect.y += delta * (0.25)*speeddown
		if speedVect.y > -speeddown :
			speedVect.y = speeddown
		print("altitude=",self.position.y,",vers=",startpos.y)
		if self.position.y >= startpos.y:
			speedVect.y = 0.0
	# changement d'inclinaison (axe X)
	if $Forme.rotation.x < PI/6 :
		$Forme.rotate_x(1.0*ROTSPEED*delta)

const FORCE_FREINAGE = 0.5
var forcefreinage : float = FORCE_FREINAGE
func freinage(delta : float):
	forcefreinage *= (1+delta)
	speedVect.z *=  forcefreinage*(1-delta)
	speedVect.x *=  forcefreinage*(1-delta)
	if speedVect.length() <= 0.5 : # TODO : une constante à régler
		# s'arrête
		speedVect = Vector3.ZERO
	
func atterrissage():
	enaction = true
	actionencours = action.ATTERRISSAGE
	speedVect.y = 0.0
	self.position.y = 0.5 # FIXME
	self.rotation.x = 0.0
	forcefreinage = FORCE_FREINAGE
	
func _process(_delta):
	if Input.is_action_just_pressed("attente",true):
		attente()
	elif Input.is_action_just_pressed("camera",true):
		# changement de caméra (pour tests surtout)
		if prevcam != null :
			prevcam.make_current()
			prevcam = null
		else:
			prevcam = get_viewport().get_camera_3d()
			$Camera3D.make_current()
			$Indicateurs.show()
		
func _physics_process(delta: float) -> void:
	var change = Input.get_axis("droite","gauche")
	var pique = Input.is_action_pressed("bas")
	
	if enaction and actionencours == action.ATTENTE \
				and (change != 0 or pique):
		# sortie du mode attente, pour se remettre dans l'axe
		enaction = false
		correction()
	if enaction and actionencours== action.ATTERRI \
		and Input.is_action_pressed("decolle"):
			enaction = false
			speedVect.z = -speedfront
			self.rotation = Vector3.ZERO
	if not enaction:
		if pique :
			descente(delta)
			# on ne combine pas pique et changement de direction
		elif change != 0:
			# changement de direction
			virage(change,delta)
		else:
			# Pas d'interaction
			
			# 1. retour naturel à une inclinaison normale sans action
			if abs($Forme.rotation.z) < ROTBACKSPEED*delta :
				$Forme.rotation.z = 0
			else:
				$Forme.rotate_z(-sign($Forme.rotation.z)*ROTBACKSPEED*delta)

			# 2. remontée suite à un piqué
			if self.position.y < startpos.y:
				remonte(delta)
			if $Forme.rotation.x <0 :
				$Forme.rotate_x(min(0.2*ROTSPEED*delta,-$Forme.rotation.x))
			if $Forme.rotation.x >0 :
				$Forme.rotate_x(-min(0.5*ROTSPEED*delta,$Forme.rotation.x))

	elif enaction:
		virage(autorotspeed,delta)
		if actionencours == action.CORRECTION:
			#print ("",speedVect.z," angle ",angle_correction)
			if abs(rotation.y) <= 0.01 :
				enaction = false
				# on repart tout droit
				autorotspeed = 0.0
		elif actionencours == action.ATTERRISSAGE:
			if speedVect != Vector3.ZERO :
				freinage(delta)
			else:
				# on est arrêté
				enaction = true
				actionencours = action.ATTERRI
			
		elif actionencours == action.ATTENTE:
			# on laisse tourner
			pass


	# S'assurer qu'on ne va pas toucher les limites en X de la zone de vol
	if not enaction and abs(speedVect.x * 3.0 + position.x) > limite_x :
		# on approche trop du bord
		# on force un virage
		correction()
		virage(autorotspeed,delta)

	if $Indicateurs.visible :
		$Indicateurs/Altitude.text = "%d" % roundi(position.y)
		$Indicateurs/Vitesses.text = "(%2.1f,%2.1f)" % [speedVect.y,Vector2(speedVect.x,speedVect.z).length()]
	var collisions : KinematicCollision3D
	collisions = move_and_collide(speedVect*delta)
	
	if (collisions != null):
		for i in range(0,collisions.get_collision_count()):
			var obj = collisions.get_collider(i)
			print(obj.name)
			if obj.name == "Ground":
				# atterrissage (surement violent)
				atterrissage()

	if not enaction and self.position.y > startpos.y:
		speedVect.y = 0
		position.y = startpos.y
		$Forme.rotation.x = 0.0 #TODO redressement à améliorer
