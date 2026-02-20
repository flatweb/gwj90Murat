extends VolatileBody3D

# Autre volatile (ou n'importe quoi) qu'on est censé suivre
var leader : Node3D = null
# Ecart à conserver derrière le leader pour éviter le choc
const ECART_DERRIERE_LEADER : float = 2.0
# Ecart où on est bien
const ECART_PROCHE : float = 5.0
# Ecart où on comence à être loin du leader
const ECART_LOIN : float = 10.0
# Ecart où on est trop loin, et qu'on perd le leader
const ECART_TROP_LOIN : float = 20.0
# facteur d'accélération dans certains cas
var acceleration : float = 1.0

signal perdu

func _ready():
	print (self.name, " ready")
	nodeoie = $OIE
	super._ready()
	tailleY = 0.8 # TODO
	
	# on démarre en se mettant en attente, à vitese réduite
	en_vol = true  # on considère bien qu'on est en vol puisqu'on démarre dans le ciel
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
		# on suit déjà un leader
		return
	
	self.leader = _leader
	speedVect = speedVect.normalized() * speedfront
	if enaction :
		if actionencours == action.ATTENTE :
			enaction = false
			print(self.name," en décrochage")
			decroche() # on décroche
	# On désactive les layers 2 et 3? pour ne plus déclencher la capture
	self.set_collision_layer_value(2, false)
	self.set_collision_layer_value(3, false)

func distance_au_leader():
	if leader == null:
		return 10000.0
	else:
		return (position - leader.position).length()

func fin_decrochage():
	# accélération pour rattraper le leader
	if distance_au_leader() > ECART_LOIN : # je pense qu'on ne rentre jamais là
		acceleration = 1.5
	
func _process(delta: float) -> void:
	super._process(delta)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	## On va faire simple :
	if leader == null :
		if enaction and actionencours == action.ATERRI:
			# Si on est posé, on ne fait rien
			pass
		else:
			# sinon on continue le mouvement en cours
			if autorotspeed != 0.0 :
				#on continue le virage en cours
				virage(autorotspeed,delta)
			# sauf si on est en correction...
			if actionencours == action.CORRECTION:
				#print ("",speedVect.z," angle ",angle_correction)
				if abs(rotation.y) <= 0.01 : # FIXME :
					print ("fin de correction pour ", self.name)
					#Fin de correction
					enaction = false
					# on repart tout droit
					autorotspeed = 0.0
	else:
		# on va adapter l'accélération
		if distance_au_leader() <= ECART_PROCHE :
			acceleration = 1.0
		elif distance_au_leader() > ECART_LOIN :
			acceleration = 1.5
		#entre les 2 on conserve l'accélération actuelle
		
		# on va suivre le "leader"
		var vectdir : Vector3 = leader.position - self.position
		speedVect = speedVect.normalized() * speedfront * acceleration
		# on adapte la vitesse pour ne pas le toucher
		speedVect *= min(vectdir.length()/ECART_DERRIERE_LEADER, 1.0)
		# on adapte aussi en Y
		
		# on va rejoindre l'altitude
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
			var normal : Vector3 = collisions.get_normal(i)
			if obj.is_in_group("sol"):
				print(self.name," en contact avec le sol")
				if enaction and actionencours == action.DECOLLAGE :
					#on ignore la collision résiduelle
					pass
				else:
					# aterrissage
					#aterrissage()  #TODO : est-ce bien raisonnable
					pass
			elif obj.name.contains("Static"):
				print(self.name," collides avec un static ",obj.name," par ",normal)
				# on vient de rentrer dans un mur ou un boids, ce n'est pas normal
				var groups = obj.get_groups()
				print ("Choc de ",self.name," contre un Static : free de ",obj.name, " dans groupe ", obj.get_groups())
				correction(normal)
				virage(autorotspeed,delta)
				# on le fait plutôt disparaitre
				#queue_free()
				# on verra le résultat au prochain cycle
			elif obj.is_in_group("Oiseau") :
				# on vient de rentrer dans un autre oiseau
				decroche(delta)
			elif obj.is_in_group("Bonus"):
				#print(self.name," collides avec ",obj.name," par ",normal)
				# collision entre Oiseaux Bonus
				# TODO : faire qqchose
				pass
	
	elif enaction and actionencours == action.CORRECTION :
		# plus de collision, on reprend son chemin
		print ("fin de correction pour Oiseau Bonus")
		enaction = false

	if leader != null and distance_au_leader() > ECART_TROP_LOIN:
		leader = null
		mise_en_attente()
		perdu.emit() # à destination du game
		
