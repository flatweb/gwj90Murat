extends VolatileBody3D

# Autre volatile (ou n'importe quoi) qu'on est censé suivre
var leader : Node3D = null
# Ecart à conserver derrière le leader
const ECART_DERRIERE_LEADER : float = 2.0

func _ready():
	nodeoie = $OIE
	super._ready()
	tailleY = 0.8 # TODO
	
	# on démarre en se mettant en attente, à vitese réduite
	mise_en_attente()

func meurt():
	queue_free()
	pass

func mise_en_attente():
	# vitese réduite pour nous
	speedVect = Vector3(0,0,-speedfront/2)
	attente()

func devient_suiveur_de(_leader : Node3D):
	if self.leader != null :
		return
		
	self.leader = _leader
	speedVect = speedVect.normalized() * speedfront
	if enaction :
		if actionencours == action.ATTENTE :
			enaction = false
			decroche(0.0)
	# On désactive les layers 2 et 3? pour ne plus déclencher la capture
	self.set_collision_layer_value(2, false)
	self.set_collision_layer_value(3, false)
		
	
	if enaction and actionencours == action.ATTENTE :
		enaction = false
		actionencours = action.AUCUNE

func _process(delta: float) -> void:
	super._process(delta)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	## On va faire simple :
	if leader == null :
		if enaction and actionencours == action.ATTERRI:
			# Si on est posé, on ne fait rien
			pass
		else:
			# sinon on continue le mouvement en cours
			virage(autorotspeed,delta)
			# sauf si on est en correction...
			if actionencours == action.CORRECTION:
				#print ("",speedVect.z," angle ",angle_correction)
				if abs(rotation.y) <= 0.01 : # FIXME : 
					#Fin de correction
					enaction = false
					# on repart tout droit
					autorotspeed = 0.0
	else:
		# on va rejoindre l'altitude
		# on va suivre le "leader" à la même vitesse que lui
		var vectdir : Vector3 = leader.position - self.position
		speedVect = speedVect.normalized() * speedfront
		# on adapte la vitesse pour ne pas le toucher
		speedVect *= min(vectdir.length()/ECART_DERRIERE_LEADER, 1.0)
		# on adapte aussi en Y
		
		if  is_zero_approx(vectdir.y) :
			# on se stabilise
			speedVect.y = 0
		elif vectdir.y < -ECART_ALTITUDE :
			# 1. on plane en descente si on est trop haut
			plane(delta)
		elif vectdir.y > ECART_ALTITUDE :
			# 2. on remonte si on est trop bas, sans se proccuper de l'inclinaison
			remonte(delta, false)
		else:
			speedVect.y = 0

		
		var vy = Vector2(vectdir.x,vectdir.z)
		var tbz = -Vector2(transform.basis.z.x, transform.basis.z.z)
		var angley = -vy.angle_to(tbz)
		#print ("angle=",rad_to_deg(angley))
		# on tourne au maximum tant qu'on est au-dessus de 45°
		virage(min(abs(angley*4/PI),1)*(1 if angley<0 else -1),delta)
	
	var collisions : KinematicCollision3D
	collisions = move_and_collide(speedVect*delta)
	
	if (collisions != null ):
		for i in range(0,collisions.get_collision_count()):
			var obj : Node3D = collisions.get_collider(i)
			if obj.get_parent().is_in_group("isBoid"):
				break
			print("OiseauBonus collides avec ",obj.name)
			if obj.name.contains("Ground"):
				if enaction and actionencours == action.DECOLLAGE :
					#on ignore la collision résiduelle
					pass
				else:
					# atterrissage
					#atterrissage()  #TODO : est-ce bien raisonnable
					pass
			elif obj.name.contains("Static"):
				# on vient de rentrer dans un mur ou un boids, ce n'est pas normal
				var groups = obj.get_groups()
				#self.position -= speedVect
				#correction()
				#virage(autorotspeed,delta)
				# on le fait plutôt disparaitre
				print ("Choc contre un Static : free de ",obj.name, " dans ", obj.get_groups())
				queue_free()
				# on verra le résultat au prochain cycle
			elif obj.name.contains("Oiseau"):
				# on vient de rentrer dans un autre oiseau
				pass
				decroche(delta)
	elif enaction and actionencours == action.CORRECTION :
		# plus de collision, on reprend son chemin
		print ("fin des collisions pour Oiseau Bonus")
		enaction = false
	elif enaction and actionencours == action.DECROCHE :
		# plus de collision, on reprend son chemin
		print ("fin des collisions pour Oiseau Bonus")
		enaction = false
