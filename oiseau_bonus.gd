extends VolatileBody3D
class_name OiseauBonus

@export var texture : Texture2D
var mesh : MeshInstance3D

# Autre volatile (ou n'importe quoi) qu'on est censé suivre
var leader : Node3D = null
var tomarker : Marker3D = null
# Ecart à conserver derrière le leader pour éviter le choc
const ECART_DERRIERE_MARKER : float = 1.0
# Ecart où on est bien
const ECART_PROCHE : float = 0.8
# Ecart où on comence à être loin du leader
const ECART_LOIN : float = 0.5
# Ecart où on est trop loin, et qu'on perd le leader
const ECART_TROP_LOIN : float = 20.0
# facteur d'accélération dans certains cas
var acceleration : float = 1.0
# Altitude sous laquelle on repart en attente
var altitudemin : float = 2.0 # TODO

signal perdu(me : VolatileBody3D) # appelé avec self
# pour envoyer des messages à game
signal pushtext(txt : String)

func _ready():
	#print (self.name, " ready")
	nodeoie = $OIE
	super._ready()
	tailleY = 0.8 # TODO
	
	en_vol = true  # on considère bien qu'on est en vol puisqu'on démarre dans le ciel
	# on part en avant...
	speedVect = Vector3.FORWARD * speedfront
	# on démarre en se mettant en attente, ce qui va réduire la vitesse
	mise_en_attente()
	
	mesh = $OIE/Armature/Skeleton3D/Cube
	if texture:
		mesh.material_override = StandardMaterial3D.new()
		mesh.material_override.albedo_texture = texture

func meurt():
	queue_free()
	pass

func mise_en_attente():
	# vitese réduite pour nous, mais on ne touche pas à la direction ici
	speedVect *= 0.5
	attente()


func devient_suiveur_de(_leader : Node3D, atmarks : Marker3D) -> bool :
	if self.leader != null :
		# on suit déjà un leader
		return false # on ne devrait jamais passer là !!!
	
	$AudioPlayerFollow.play(2.0)
	self.leader = _leader
	self.tomarker = atmarks
	print (self.name, " suit ", atmarks.name)
	speedVect = speedVect.normalized() * speedfront
	if actionencours == action.ATTENTE :
		print(self.name," en décrochage")
		decroche() # on décroche
	# On désactive les layers 2 et 3? pour ne plus déclencher la capture
	self.set_collision_layer_value(3, false)
	
	return true

func distance_au_leader():
	if leader == null:
		return 10000.0
	else:
		return (position - leader.position).length()

func distance_au_marker():
	if leader == null:
		return 10000.0
	else:
		return (global_position - tomarker.global_position).length()

func do_decolle():
	# pour couvrir l'abstract de volatile, mais pas prévu pour bonus
	pass
	
func fin_decrochage():
	# accélération pour rattraper le leader
	acceleration = 1.8
	
func _process(delta: float) -> void:
	super._process(delta)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	## On va faire simple :
	if leader == null :
		if actionencours == action.ATERRI:
			# Si on est posé, on ne fait rien, mais pour l'instant on ne sait pas vraiment aterrir : TODO à tester un jour
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
					#print ("un bisou pour", self.name)
					#Fin de correction
					actionencours = action.AUCUNE
					# on repart tout droit
					autorotspeed = 0.0
	else:
		# on va adapter l'accélération
		if distance_au_marker() <= ECART_PROCHE :
			acceleration = 1.0
		elif distance_au_leader() > ECART_LOIN :
			acceleration = 1.5
		#entre les 2 on conserve l'accélération actuelle

		# Si on est devant le marker du leader, on va surtout ralentir
		# il faut que l'angle entre la direction du leader et l'angle 
		# on va suivre un marker3D du "leader"
		var _tomarkerpos = tomarker.global_position
		var _selfpos = self.global_position
		var vectdir : Vector3 = tomarker.global_position - self.global_position
		var vectdironXZ = Vector3(vectdir.x,0,vectdir.z)
		var vectdirY = Vector3(0,vectdir.y,0)
		var _orientationleader = -leader.transform.basis.z
		var _angleorientation = angle_on_XZ(-leader.transform.basis.z, vectdir)
		pass
		var freinage
		# 
		if -dot_on_XZ(vectdir,leader.transform.basis.z) < 0 :
			# on ne va pas dans la même direction, => RALENTIR
			freinage = 0.3
		else:
			freinage = 1.0
		
		speedVect = speedVect.normalized() * speedfront * acceleration * freinage
		# on adapte un peu la vitesse pour ne pas le toucher
		speedVect *= min(vectdironXZ.length()/ECART_DERRIERE_MARKER, 1.0)
		
		if (vectdironXZ.length() < ECART_DERRIERE_MARKER):
			# on est tout près
			var anglevectleader = angle_on_XZ(vectdironXZ,leader.transform.basis.z)
			if abs(angle_on_XZ(vectdironXZ,leader.transform.basis.z)) < PI/10 :
				position.x = tomarker.global_position.x
				position.z = tomarker.global_position.z
				pass
		
		
		# on va rejoindre l'altitude
		if  is_zero_approx(vectdirY.y) :
			# on se stabilise
			speedVect.y = 0
		  #FIXME : à réadapter
		elif vectdirY.y < -0.1 :
			# 1. on plane en descente si on est trop haut
			speedVect.y = -speedup
		elif vectdirY.y > 0.1 :
			# 2. on remonte si on est trop bas, sans se préoccuper de l'inclinaison
			speedVect.y = speedup
		else:
			speedVect.y = 0
		
		var angley = angle_on_XZ(vectdir,-transform.basis.z)
		#print ("angle=",rad_to_deg(angley))
		# on tourne au maximum tant qu'on est au-dessus de 30°
		virage(min(abs(angley/(PI/6)),1)*(1 if angley<0 else -1),delta)
	
	var collisions : KinematicCollision3D
	collisions = move_and_collide(speedVect*delta)
	
	# si il y a des collisions
	if (collisions != null ):
		for i in range(0,collisions.get_collision_count()):
			var obj : Node3D = collisions.get_collider(i)
			if obj.get_parent().is_in_group("isBoid"):
				continue
			var normal : Vector3 = collisions.get_normal(i)
			if obj.is_in_group("sol"):
				print(self.name," en contact avec le sol")
				if actionencours == action.DECOLLAGE :
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
				print ("Choc de ",self.name," contre un Static : on opère un virage de correction")
				correction(normal)
				virage(autorotspeed,delta)
				# on le fait plutôt disparaitre
				#queue_free()
				# on verra le résultat au prochain cycle
			elif obj.is_in_group("Oiseau") :
				# on vient de rentrer dans un autre oiseau
				#decroche(delta)
				pass 
			elif obj.is_in_group("Bonus"):
				#print(self.name," collides avec ",obj.name," par ",normal)
				# collision entre Oiseaux Bonus
				# TODO : faire qqchose ?
				pass
	
	# altitude trop basse du leader, on se met en attente
	# Ca devrait permettre aussi, d'animer la fin de jeu
	if leader != null and leader.position.y < ALTITUDE_LIBERATION_BONUS :
		print (self.name, " a perdu le leader trop bas")
		position.y = 5.0 # FIXME : un peu trop violent
		perte_du_leader()
		
	elif leader != null and distance_au_leader() > ECART_TROP_LOIN:
		print (self.name, " a perdu le leader trop loin")
		perte_du_leader()
		

## action suite à perte du leader
func perte_du_leader() -> void:
	leader = null
	# On résactive la layer 3 pour réclencher une capture
	self.set_collision_layer_value(3, true)
	$AudioPlayerLost.play()
	mise_en_attente()
	perdu.emit(self) # à destination de oiseau et du game
