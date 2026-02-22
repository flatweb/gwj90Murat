extends VolatileBody3D
class_name Oiseau

# de quel côté on a atteint la limite ?
var acorriger = false

# autre camera 
var prevcam : Camera3D

# position de départ, notamment pour remonter à l'altitude Y
var startpos : Vector3

var nbcapture = 0
var nbmaxcapture = 0

# signal quand on fait une capture
signal capture
# tableau des markers et des markers libres
var arrmarks : Array
var arrfreemarks : Array
# signal à émettre quand l'oiseau est arrivé, avec nb autres
signal aterri(dist : float, nb : int)
# distance parcourue au total
var distance : float

# étapes et limite max de retour possible en arrière
var stepsnoback : Array = [80.0, 60.0, 40.0, 20.0, 10.0] #TODO
var maximumz : float
const MARGE_MAXIMUMZ = 5.0

# pour envoyer des messages à game
signal pushtext(txt : String)

func _init():
	super._init()
	stepsnoback.sort()
	
func _ready():
	nodeoie=$OIE
	super._ready()
	demarre()
	# Par défaut on considère que c'est la taille de la collisionShape
	tailleY=$CollisionShape3D.shape.height #FIXME : trop grand, effets de bord

	for child in $PositionSuiveurs.get_children():
		arrmarks.append(child)
		arrfreemarks.append(true)

func start_aterri_at(pos : Vector3):
	_anim_repos()
	speedVect = Vector3.ZERO
	self.position = pos
	enaction = true
	actionencours = action.ATERRI
	
func demarre():
	$Indicateurs.hide()
	hide_indice()
	speedVect = Vector3(0,0,-speedfront)
	self.rotation = Vector3.ZERO
	startpos = self.position
	maximumz = startpos.z + MARGE_MAXIMUMZ 
	en_vol = true
	#_anim_start_vol()

var cibleindice : VolatileBody3D = null
func hide_indice():
	$SpriteIndice3D.hide()
	cibleindice = null
	$SpriteIndice3D/Timer.stop()  # au cas où on fait le hide manuel

func refresh_indice():
	if cibleindice != null :
		var cible = cibleindice.position
		#cible.y = self.position.y # on va reste à plat
		$SpriteIndice3D.look_at(cible)
		$SpriteIndice3D.rotation.x = -PI/2

func show_indice(bonus : VolatileBody3D):
	cibleindice = bonus
	$SpriteIndice3D.show()
	$SpriteIndice3D/Timer.start(10.0)
	refresh_indice()

func losebonus():
	nbmaxcapture += 1
	nbcapture -= 1
	pass

# -----------------------------------------------------------------
#   GESTION DES MOUVEMENTS
# -----------------------------------------------------------------

func do_decolle():
	enaction = true
	actionencours = action.DECOLLAGE
	nbmaxcapture = 0
	speedVect.z = -speedfront
	self.rotation = Vector3.ZERO

func looping():
	pass

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
			speedVect.y = -speeddown
		# changement progressif d'inclinaison (axe X vers le bas)
		if abs($OIE.rotation.x) < INCLINAISON_MAX_PIQUE :
			$OIE.rotate_x(-0.1*ROTSPEED*delta)

func monter(delta):
	remonte(delta)
	

const FORCE_FREINAGE = 0.2
var forcefreinage : float = FORCE_FREINAGE
func freinage(delta : float):
	if speedVect.length() <= 0.2 : # TODO : une constante à régler
		# on s'arrête
		speedVect = Vector3.ZERO
		#rotation.y = 0.0
		position.y = tailleY # FIXME
		return

	forcefreinage *= (1+delta)
	#print("freinage avant=",speedVect.length()," * ",(1-forcefreinage)*(1-delta))
	speedVect.y =  0.0
	speedVect.rotated(Vector3.UP,-rotation.y /3)
	speedVect.x *=  (1-forcefreinage)*(1-delta)
	speedVect.z *=  (1-forcefreinage)*(1-delta)
	#rotate_y(-rotation.y /2) #FIXME constante à régler
	queue_next_anim(ANIM_RESET)
	#print("freinage final=",speedVect.length())
	
func aterrissage():
	enaction = true
	actionencours = action.ATERRISSAGE
	speedVect.y = 0.0
	position.y = 0.5 #tailleY/2
	$OIE.rotation.x = 0.0
	$OIE.rotation.y = 0.0 # FIXME
	forcefreinage = FORCE_FREINAGE
	queue_next_anim(ANIM_PLANE)
	$AudioPlayerCri.play(3.0)

#---------------------------------------------------------------
# Evénements liés à la mission
#---------------------------------------------------------------
func mission_remplie(node : Node):
	if node.name == "Mission":
		print ("Mission 1 terminée")
		
	
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
	
	refresh_indice()

func start_correction(normal):
	acorriger = true
	correction_direction = normal

# pour surcharger la méthode abstract de VolatileBOdy3D
func fin_decrochage():
	pass

func do_no_action():
	pass

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	var vire = Input.get_axis("droite","gauche")
	var monte = Input.is_action_pressed("monte")
	var pique = Input.is_action_pressed("descend")
	var mouvement :bool = false
	var mouvementupdown :bool = false # ne sert à rien ?
	
	#pour mettre un point d'arrêt
	if speedVect.y > 0 and pique :
		pass
		
	# Si il y a une action automatique en cours, on privilégie l'action
	# TODO : déplacer ça en résultat de do_action ?
	if enaction and actionencours == action.ATTENTE \
				and (vire != 0 or pique or monte):
		# sortie du mode attente, pour se remettre dans l'axe
		enaction = false
		correction()
	if enaction and actionencours == action.ATERRI \
		and (Input.is_action_pressed("decolle") or monte):
			do_decolle()
	
	# Si pas d'action automatique, on cherche une commande
	if not enaction:
		if pique :
			descendre(delta)
			mouvement = true
			mouvementupdown = true
			# on ne combine pas pique et changement de direction
		elif monte :
			monter(delta)
			mouvement = true
			mouvementupdown = true
		# on ne combine pas montée et changement de direction ?!?: TODO: a faire
		if vire != 0:
			# changement de direction
			virage(vire,delta)
			mouvement = true
		else:
			# Pas d'interaction
			# 1. retour naturel à une inclinaison normale latérale sans action
			redresse(delta)

	elif enaction:
		if autorotspeed != 0.0 :
			virage(-autorotspeed,delta)
		if actionencours == action.CORRECTION:
			#print ("",speedVect.z," angle ",angle_correction)
			
			if abs(angle_on_XZ(correction_direction,speedVect)) <= 0.1 : # FIXME : risque d'aller trop loin
				print("Fin de correction pour ", self.name)
				enaction = false
				# on repart tout droit
				autorotspeed = 0.0
		elif actionencours == action.ATERRISSAGE:
			if speedVect != Vector3.ZERO :
				freinage(delta)
			else:
				# on est arrêté
				enaction = true
				actionencours = action.ATERRI
				$OIE.rotation.z = 0.0
				print("Aterrissage réussi")
				aterri.emit(distance)
				queue_next_anim(ANIM_REPOS)
				# on va libérer les bonus :
		elif actionencours == action.DECOLLAGE:
			queue_next_anim(ANIM_VOL)
			remonte(delta)
			mouvement = pique or monte # FIXME à supprimer après test
			if position.y > 1.0 :
				enaction = false
		elif actionencours == action.ATTENTE:
			# on laisse tourner
			pass

	#pour mettre un point d'arrêt
	if speedVect.y > 0 and pique:
		pass

	# S'assurer qu'on ne va pas toucher les limites en X de la zone de vol
	if acorriger:
		correction(correction_direction)
		virage(-autorotspeed,delta)
		acorriger = false

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

	#pour mettre un point d'arrêt
	if speedVect.y > 0 and pique:
		pass

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
			if obj.get_parent().is_in_group("isBoid"): #TODO/FIXME : comprendre
				continue
			var normal : Vector3 = collisions.get_normal(i)
			if obj.is_in_group("sol"):
				print(self.name, "en collision avec le sol")
				if enaction and \
					  (actionencours == action.DECOLLAGE or \
					   actionencours == action.ATERRI) :
					#on ignore la collision résiduelle
					pass
				else:
					# on finit l'aterrissage
					aterrissage()
			elif obj.name.contains("Static") or obj.is_in_group("limite"):
				if not (enaction and actionencours == action.CORRECTION):
					print("Oiseau collides avec ",obj.name," par ",normal)
					# on vient de rentrer dans un mur
				start_correction(normal)
				# on verra le résultat au prochain cycle
			elif obj.is_in_group("Bonus"):
				# on est rentré dans un autre oiseau (bonus), on va dévier simplement
				if not (enaction and actionencours == action.CORRECTION):
					pass
					#correction()
				#virage(autorotspeed,delta)

	#pour mettre un point d'arrêt
	if speedVect.y > 0 and pique :
		pass


	# la distance parcourue se cumule
	distance += (self.position - positionavant).length()

	# on empêche de revenir en arrière
	#for stepz in stepsnoback :
		#if self.position.z < stepz :
			#var newmaxz = stepz + MARGE_MAXIMUMZ
			#if newmaxz < maximumz :
				## Il faudra aussi tenir compte des missions non réalisées ? #TODO
				#print("On a franchi une nouvelle étape à ", stepz)
				#maximumz = newmaxz
				#break

# Un élément vient de rentrer dans notre zone d'influence
func _on_area_influence_body_entered(body: Node3D) -> void:
	# si c'est un oiseau bonus
	if body.is_in_group( "Bonus" ) and body.leader == null :
	# si c'est un oiseau bonus
		if position.y <= ALTITUDE_LIBERATION_BONUS :
			# on est trop bas, on ne peut plus accrocher un bonus (cas de fin de partie)
			return
		print("", body.name)
		nbcapture += 1  # Et c'est gam qui nous décrémente si on en perd un
		capture.emit()
		hide_indice()
		var bonus = body as OiseauBonus
		for i in range(arrfreemarks.size()):
			if arrfreemarks[i] == true:
				arrfreemarks[i] = false
				bonus.devient_suiveur_de(self, arrmarks[i]) #TODO : check return
				break


func _on_area_influence_area_entered(area: Area3D) -> void:
	if area.is_in_group("limite"):
		pass #FIXME : ça sert à quoi ?
	pass # Replace with function body.
