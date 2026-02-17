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
const INCLINAISON_MAX_MONTEE = PI/8
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
# Vitesse de vol en descente planée
var speeddownslow : float = speedfront / 8
# Vitesse de remontée
var speedup : float = speedfront / 2
# Altitude où on commence à freiner le piqué pour atterrir
var altitudefreinage : float = 5.0
# Altitude au delà de laquelle on cesse de monter
var altitudemax : float = 50.0
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
# écart d'altitude toléré par rapport à la startpos avant de décider de corriger
const ECART_ALTITUDE = 1.0

# taille de l'oiseau en hauteur (pour gérer l'atterrisage)
var tailleY : float

# signal à émettre quand l'oiseau est arrivé, avec nb autres
signal arrive(dist : float, nb : int)
# distance parcourue au total
var distance : float

# node de la forme OIE pour éviter de trop invoquer $OIE
var nodeoie : Node3D

func _ready():
	nodeoie=$OIE
	demarre()
	# Par défaut on considère que c'est la taille de la collisionShape
	tailleY=$CollisionShape3D.shape.height

func demarre():
	$Indicateurs.hide()
	speedVect = Vector3(0,0,-speedfront)
	self.rotation = Vector3.ZERO
	startpos = self.position
	en_vol = true
	anim_start_vol()

func set_limite_x(value):
	limite_x = value


# -----------------------------------------------------------------
#   GESTION DE L'ANIMATION
# -----------------------------------------------------------------
# Note : j'ai supprimé le bouclage auto de l'animation, pour pouvoir enchainer des animations

const ANIM_PLANE = "Vol_plane"
const ANIM_VOL = "Vol_normal"
const ANIM_RESET = "RESET"

# indicateur de vol en cours, avec battement d'ailes
var en_vol : bool
# enchainement des animations
var nextanim : String
var prevanim : String

# On va gérer notre queue d'animation nous-mêmes TODO
func queue_next_anim(anim:String):
	#TODO : il faudra peut-être être plus malin à terme, quoique...
	nextanim = anim
	# Si une animation est déjà en cours, on attend la fin
	if $OIE/AnimationPlayer.is_playing() : return
	# Si le timer est en cours, on l'attend
	if $TimerAttenteAnim.time_left > 0.0 : return
	# sinon on le redémarre
	$TimerAttenteAnim.start(1.0)
	
func _on_animation_finished(anim_name: StringName) -> void:
	# Si le timer est en cours, on l'attend
	if $TimerAttenteAnim.time_left > 0.0 :
		prevanim = anim_name
		return
	if not en_vol : # FIXME : pourquoi ? pour l'atterrissage ?
		# sinon on le redémarre
		$TimerAttenteAnim.start(1.0)
		return
	change_anim(anim_name)

# Pour les animations trop courtes, on préfère activer un timer
func _on_timer_attente_anim_timeout() -> void:
	print ("Changement sur timeout vers ", nextanim)
	change_anim(prevanim)

# Changement d'animation avec transition
func change_anim(anim_name):
	print ("Changement de ",anim_name," à ",nextanim)
	match anim_name:
		ANIM_VOL:
			match nextanim:
				ANIM_VOL:
					anim_vol()
				ANIM_PLANE:
					anim_vol_to_plane()
				_ :
					anim_vol()
		ANIM_PLANE:
			match nextanim:
				ANIM_VOL:
					anim_plane_to_vol()
				ANIM_PLANE:
					anim_plane()
				ANIM_RESET:
					anim_reset()
				_ :
					anim_plane()
		ANIM_RESET:
			match nextanim:
				ANIM_VOL:
					anim_plane_to_vol()
				ANIM_PLANE:
					anim_plane()
				ANIM_RESET:
					anim_reset()
				_ :
					anim_reset()

func anim_start_vol():
	anim_vol()
	$AudioPlayerAiles.play()
	
func anim_vol():
	nextanim = ANIM_VOL
	$OIE/AnimationPlayer.play(nextanim)

func anim_plane_to_vol():
	nextanim = ANIM_VOL
	$OIE/AnimationPlayer.play_section(ANIM_VOL, 0.3, -1.0)
	$AudioPlayerAiles.play()

func anim_vol_to_plane():
	nextanim = ANIM_PLANE
	$OIE/AnimationPlayer.play_section(ANIM_PLANE, 0.0, 0.3)

func anim_plane():
	$TimerAttenteAnim.start(1.0)
	nextanim = ANIM_PLANE
	$OIE/AnimationPlayer.play_section(ANIM_PLANE, 0.29, 0.31)

func anim_reset():
	$TimerAttenteAnim.start(1.0)
	nextanim = ANIM_RESET
	$OIE/AnimationPlayer.play(ANIM_RESET)

func anim_autoswitch():
	if enaction : return
	if nextanim == ANIM_RESET : return
	if position.y > startpos.y : return # TODO : pas joli
	
	if randf() < 0.25 :
		queue_next_anim(ANIM_PLANE)
	else:
		queue_next_anim(ANIM_VOL)

func _on_timer_change_anim_timeout() -> void:
	anim_autoswitch()

func _on_loop_sound():
	# Ne relance pas le son si on n'est plus en vol
	if en_vol :
		pass
		#$AudioPlayerAiles.play()


# -----------------------------------------------------------------
#   GESTION DES MOUVEMENTS
# -----------------------------------------------------------------

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
	if abs($OIE.rotation.z) < INCLINAISON_MAX_VIRAGE :
		#print("vire from ",$OIE.rotation.z, " for ",rad_to_deg(change*ROTSPEED*delta))
		$OIE.rotate_z(min(max(change,-1),1)*ROTSPEED*delta)
	else:
		#print($OIE.rotation.z)
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
		$AudioPlayerCri.play(4.0)

func descendre(delta : float):
	# Note : comme on descend la vitesse en Y est négative
	# si on est trop bas, on freine en Y, mais aussi en front
	if position.y < altitudefreinage:
		var newspeedY = speedVect.y * position.y/altitudefreinage*(1-delta)
		newspeedY = min(-VITESSE_Y_MIN,newspeedY)
		# Si on est déjà très bas, 
		if position.y < 1.0: # TODO : constante ou calcul
			newspeedY = -VITESSE_Y_MIN # C'est un peu brutal, mais ça marche
		speedVect.y=newspeedY
		#print("en freinage à ",position.y,", speedY=",speedVect.y)
		# changement progressif d'inclinaison (axe X vers le haut)
		$OIE.rotation.x = max($OIE.rotation.x,-INCLINAISON_MAX_PIQUE*(position.y-ALTITUDE_MIN_CABRAGE)/altitudefreinage) # FIXME : intégrer la taille de l'oiseau ?
		# correction de l'assiette
		redresse(delta)
	# accélération :
	if speedVect.y > -speeddown:
		# on accélère un peu
		speedVect.y -= delta * (0.5)*speeddown
		if speedVect.y < -speeddown :
			speedVect.y = speeddown
		# changement progressif d'inclinaison (axe X vers le bas)
		if abs($OIE.rotation.x) < INCLINAISON_MAX_PIQUE :
			$OIE.rotate_x(-0.1*ROTSPEED*delta)

func redresse(delta : float):
	if abs($OIE.rotation.z) < ROTBACKSPEED*delta :
		$OIE.rotation.z = 0
	else:
		$OIE.rotate_z(-sign($OIE.rotation.z)*ROTBACKSPEED*delta)

func monter(delta):
	remonte(delta)
	
func remonte(delta : float):
	# 1. changement de la vitesse verticale
	if speedVect.y < 0:
		# on est toujours en descente, on commence par freiner, assez fort
		speedVect.y += delta / 0.5 * speeddown  #(en 0.5 s)
		if speedVect.y > 0 :
			# on se stabilise
			speedVect.y = 0
	elif speedVect.y < speedup :
		# on va commencer à remonter, lentement
		speedVect.y += delta / 1.0 * speedup  # il faut 1s pour atteindre la vitesse normale de montée
		if speedVect.y > speedup :
			speedVect.y = speedup
		#print ("altitude=",self.position.y,",vers=",startpos.y)

	# 2. changement d'inclinaison (axe X), un peu lente
	if $OIE.rotation.x < INCLINAISON_MAX_MONTEE :
		#print ("rot X=",$OIE.rotation.x)
		#print ("max ",INCLINAISON_MAX_MONTEE - $OIE.rotation.x)
		#print ("min ",0.2*ROTSPEED*delta)
		if $OIE.rotation.x <0 :
			$OIE.rotate_x(min(0.5*ROTSPEED*delta,INCLINAISON_MAX_MONTEE - $OIE.rotation.x))
		else:
			#print ("  rot delta=",0.2*ROTSPEED*delta)
			#print ("  rot max  =",INCLINAISON_MAX_MONTEE - $OIE.rotation.x)
			$OIE.rotate_x(min(0.1*ROTSPEED*delta,INCLINAISON_MAX_MONTEE - $OIE.rotation.x))
			#print ("--> rot X=",$OIE.rotation.x)

func plane(delta):
	if speedVect.y > 0:
		# on est toujours en montée, on commence par freiner, assez fort
		speedVect.y -= delta * (0.8)*speeddown
		if speedVect.y < 0 :
			# on se stabilise
			speedVect.y = 0
	elif speedVect.y < speeddownslow :
		# on va commencer à descendre, lentement
		speedVect.y -= delta / 1.0 * speeddownslow  # il faut 1s pour atteindre la vitesse normale
		if speedVect.y < -speeddownslow :
			speedVect.y = -speeddownslow
		#print ("altitude=",self.position.y,",vers=",startpos.y)
	# on ne change pas d'inclinaison
	queue_next_anim(ANIM_PLANE)

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
	queue_next_anim(ANIM_PLANE)
	#print("freinage final=",speedVect.length())
	
func atterrissage():
	enaction = true
	actionencours = action.ATTERRISSAGE
	speedVect.y = 0.0
	position.y = tailleY/2
	$OIE.rotation.x = 0.0
	$OIE.rotation.y = 0.0 # FIXME
	forcefreinage = FORCE_FREINAGE
	queue_next_anim(ANIM_RESET)
	$AudioPlayerCri.play(3.0)

# fin de partie
func fin():
	arrive.emit(distance,0)
	
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
	elif Input.is_action_just_pressed("varieanim",true):
		anim_autoswitch()

	# fin de partie ?  FIXME
	if position.z < 0.0 : #(pour l'instant c'est le milieu)
		fin()

func do_action():
	pass

func do_no_action():
	pass
	
func _physics_process(delta: float) -> void:
	var vire = Input.get_axis("droite","gauche")
	var pique = Input.is_action_pressed("descend")
	var monte = Input.is_action_pressed("monte")
	var mouvement :bool = false
	
	# Si il y a une action automatique en cours, on privilégie l'action
	if enaction and actionencours == action.ATTENTE \
				and (vire != 0 or pique or monte):
		# sortie du mode attente, pour se remettre dans l'axe
		enaction = false
		correction()
	if enaction and actionencours == action.ATTERRI \
		and Input.is_action_pressed("decolle"):
			enaction = true
			actionencours = action.DECOLLAGE
			
			speedVect.z = -speedfront
			self.rotation = Vector3.ZERO
	
	# Si pas d'action automatique, on 
	if not enaction:
		if pique :
			descendre(delta)
			mouvement = true
			# on ne combine pas pique et changement de direction
		elif monte :
			monter(delta)
			mouvement = true
		# on ne combine pas montée et changement de direction ?!?: TODO: a faire
		elif vire != 0:
			# changement de direction
			virage(vire,delta)
			mouvement = true
		else:
			# Pas d'interaction
			
			# 1. retour naturel à une inclinaison normale latérale sans action
			redresse(delta)

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
			queue_next_anim(ANIM_VOL)
			remonte(delta)
			if position.y > tailleY*4 : #TODO pourrait être affiné
				enaction = false
		elif actionencours == action.ATTENTE:
			# on laisse tourner
			pass

	# S'assurer qu'on ne va pas toucher les limites en X de la zone de vol
	if not enaction and \
		( abs(speedVect.x*1.0 + position.x) > limite_x \
		   or speedVect.z*1.0 + position.z > startpos.z \
		):
		# on approche trop du bord
		# on force un virage
		correction()
		virage(autorotspeed,delta)

	# Quand on est en vol régulier
	if not enaction and not mouvement:
		# 1. on remonte si on est trop bas
		if self.position.y < startpos.y - ECART_ALTITUDE:
			remonte(delta)
			# on considère qu'on est quand même en mouvement (pour ne pas corriger 
			mouvement = true
		
	# Quand on est VRAIMENT en vol régulier
	if not enaction and not mouvement:
		# 2. Equilibrage vertical, pour se remettre à plat
		if $OIE.rotation.x != 0 :
			# changement d'inclinaison (axe X), un peu lente
			#print("Avant chg rotX=",$OIE.rotation.x)
			if $OIE.rotation.x != 0 :
				if $OIE.rotation.x <0 :
					$OIE.rotate_x(min(0.1*ROTSPEED*delta,-$OIE.rotation.x))
				else:
					$OIE.rotate_x(-min(0.1*ROTSPEED*delta,$OIE.rotation.x))
			#print("Après chg rotX=",$OIE.rotation.x)

		# 4. on plane en descente si on est trop haut
		if self.position.y > startpos.y + ECART_ALTITUDE:
			queue_next_anim(ANIM_VOL)
			plane(delta)

		# 5 Quand on revient vers l'altitude d'origine, on se stabilise
		if abs(self.position.y - startpos.y) <= ECART_ALTITUDE:
			speedVect.y = 0.0


	if $Indicateurs.visible :
		$Indicateurs/Altitude.text = "\u2191%d" % roundi(position.y)
		$Indicateurs/Vitesses.text = "(%2.1f,%2.1f)" % [speedVect.y,Vector2(speedVect.x,speedVect.z).length()]
		$Indicateurs/AngleX.text = "(\u03B1:%d)" % [roundi(rad_to_deg($OIE.rotation.x))]

	var positionavant = self.position
	
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
	# la distance parcourue se cumule
	distance += (self.position - positionavant).length()
	#print ("dist=",distance)
