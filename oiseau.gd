extends CharacterBody3D

# Vitesse de rotation sur virage
const ROTSPEED = 5.0
# Vitesse de rotation sur retour naturel à la position stable
const ROTBACKSPEED = 2.0
# angle de rotation par seconde lors d'un virage
const ANGLE_VIRAGE = 1.2
# inclinaison maximale sur X en piqué
const INCLINAISON_MAX_PIQUE = PI*3/8
# altitude à partir de laquelle on se cabre pour freiner
const ALTITUDE_MIN_CABRAGE = 2.0
# angle de rotation par seconde lors d'un virage
const INCLINAISON_MAX_VIRAGE = PI*3/8
# inclinaison maximale sur X en remontée
const INCLINAISON_MAX_MONTEE = PI/6
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
# Vitesse de remontée
var speedup : float = speeddown / 3
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
# taille de l'oiseau en hauteur
var tailleY : float

func _ready():
	speedVect = Vector3(0,0,-speedfront)
	self.rotation = Vector3.ZERO
	startpos = self.position
	$Indicateurs.hide()
	# FIXME, par défaut on considère que c'est la taille de la collisionShape
	# FIXME, mais ça pourrait plutôt se basé sur le Mesh
	tailleY=$CollisionShape3D.shape.height
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
	if abs($Forme.rotation.z) < INCLINAISON_MAX_VIRAGE :
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
		# Si on est déjà très bas, 
		if position.y < 1.0: # FIXME : constante ou calcul
			newspeedY = -VITESSE_Y_MIN #FIXME ? C'est un peu brutal
		speedVect.y=newspeedY
		#print("en freinage à ",position.y,", speedY=",speedVect.y)
		# changement progressif d'inclinaison (axe X vers le haut)
		$Forme.rotation.x = max($Forme.rotation.x,-INCLINAISON_MAX_PIQUE*(position.y-ALTITUDE_MIN_CABRAGE)/altitudefreinage) # FIXME : intégrer la taille de l'oiseau ?
		# correction de l'assiette
		redresse(delta)
	# accélération :
	if speedVect.y > -speeddown:
		# on accélère un peu
		speedVect.y -= delta * (0.5)*speeddown
		if speedVect.y < -speeddown :
			speedVect.y = speeddown
		# changement progressif d'inclinaison (axe X vers le bas)
		if abs($Forme.rotation.x) < INCLINAISON_MAX_PIQUE :
			$Forme.rotate_x(-0.1*ROTSPEED*delta)

func redresse(delta : float):
	if abs($Forme.rotation.z) < ROTBACKSPEED*delta :
		$Forme.rotation.z = 0
	else:
		$Forme.rotate_z(-sign($Forme.rotation.z)*ROTBACKSPEED*delta)


func remonte(delta : float):
	if speedVect.y < 0:
		# on est toujours en descente, on commence par freiner, assez fort
		speedVect.y += delta * (0.9)*speeddown
		if speedVect.y > 0 :
			# on se stabilise
			speedVect.y = 0
	elif speedVect.y < speedup :
		# on commence à remonter, lentement
		speedVect.y += delta * (0.25)*speeddown
		if speedVect.y > -speeddown :
			speedVect.y = speeddown
		#print("altitude=",self.position.y,",vers=",startpos.y)
		if self.position.y >= startpos.y:
			speedVect.y = 0.0
	# changement d'inclinaison (axe X), un peu lente
	if $Forme.rotation.x < INCLINAISON_MAX_MONTEE :
		#print ("rot X=",$Forme.rotation.x)
		#print ("max ",INCLINAISON_MAX_MONTEE - $Forme.rotation.x)
		#print ("min ",0.2*ROTSPEED*delta)
		if $Forme.rotation.x <0 :
			$Forme.rotate_x(min(0.5*ROTSPEED*delta,INCLINAISON_MAX_MONTEE - $Forme.rotation.x))
		else:
			$Forme.rotate_x(min(0.2*ROTSPEED*delta,INCLINAISON_MAX_MONTEE - $Forme.rotation.x))
		#print ("--> rot X=",$Forme.rotation.x)

const FORCE_FREINAGE = 0.2
var forcefreinage : float = FORCE_FREINAGE
func freinage(delta : float):
	if speedVect.length() <= 0.2 : # TODO : une constante à régler
		# on s'arrête
		speedVect = Vector3.ZERO
		rotation.y = 0.0
		position.y = tailleY # FIXME
		return

	forcefreinage *= (1+delta)
	#print("freinage avant=",speedVect.length()," * ",(1-forcefreinage)*(1-delta))
	speedVect.y =  0.0
	speedVect.rotated(Vector3.UP,-rotation.y /3)
	speedVect.x *=  (1-forcefreinage)*(1-delta)
	speedVect.z *=  (1-forcefreinage)*(1-delta)
	rotate_y(-rotation.y /2) #FIXME constante à régler
	#print("freinage final=",speedVect.length())
	
func atterrissage():
	enaction = true
	actionencours = action.ATTERRISSAGE
	speedVect.y = 0.0
	position.y = tailleY/2
	$Forme.rotation.x = 0.0
	$Forme.rotation.y = 0.0 # FIXME
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
	var vire = Input.get_axis("droite","gauche")
	var pique = Input.is_action_pressed("bas")
	var mouvement :bool = false
	
	if enaction and actionencours == action.ATTENTE \
				and (vire != 0 or pique):
		# sortie du mode attente, pour se remettre dans l'axe
		enaction = false
		correction()
	if enaction and actionencours == action.ATTERRI \
		and Input.is_action_pressed("decolle"):
			enaction = true
			actionencours = action.DECOLLAGE
			
			speedVect.z = -speedfront
			self.rotation = Vector3.ZERO
	if not enaction:
		if pique :
			descente(delta)
			mouvement = true
			# on ne combine pas pique et changement de direction
		elif vire != 0:
			# changement de direction
			virage(vire,delta)
			mouvement = true
		else:
			# Pas d'interaction
			
			# 1. retour naturel à une inclinaison normale latérale sans action
			redresse(delta)

			# 2. remontée suite à un piqué ou en décollage
			if self.position.y < startpos.y:
				remonte(delta)
				mouvement = true
				
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
		elif actionencours == action.DECOLLAGE:
			remonte(delta)
			if position.y > tailleY*4 : #TODO pourrait être affiné
				enaction = false
		elif actionencours == action.ATTENTE:
			# on laisse tourner
			pass


	# S'assurer qu'on ne va pas toucher les limites en X de la zone de vol
	if not enaction and abs(speedVect.x * 3.0 + position.x) > limite_x :
		# on approche trop du bord
		# on force un virage
		correction()
		virage(autorotspeed,delta)


	# Equilibrage vertical
	if not enaction and not mouvement:
		if self.position.y > startpos.y:
			speedVect.y = -(self.position.y - startpos.y)*delta
		else:
			speedVect.y = 0.0
		
	# Equilibrage assiette
	if not enaction and not mouvement and $Forme.rotation.x != 0 :
		# changement d'inclinaison (axe X), un peu lente
		#print("Avant chg rotX=",$Forme.rotation.x)
		if $Forme.rotation.x != 0 :
			if $Forme.rotation.x <0 :
				$Forme.rotate_x(min(0.25*ROTSPEED*delta,-$Forme.rotation.x))
			else:
				$Forme.rotate_x(-min(0.25*ROTSPEED*delta,$Forme.rotation.x))
		#print("Après chg rotX=",$Forme.rotation.x)

	if $Indicateurs.visible :
		$Indicateurs/Altitude.text = "\u2191%d" % roundi(position.y)
		$Indicateurs/Vitesses.text = "(%2.1f,%2.1f)" % [speedVect.y,Vector2(speedVect.x,speedVect.z).length()]
		$Indicateurs/AngleX.text = "(\u03B1:%d)" % [roundi(rad_to_deg($Forme.rotation.x))]

	var collisions : KinematicCollision3D
	collisions = move_and_collide(speedVect*delta)
	
	if (collisions != null):
		for i in range(0,collisions.get_collision_count()):
			var obj : Node3D = collisions.get_collider(i)
			print(obj.name)
			if obj.name.contains("Ground"):
				if enaction and actionencours == action.DECOLLAGE :
					#on ignore la collision résiduelle
					pass
				else:
					# atterrissage
					atterrissage()
