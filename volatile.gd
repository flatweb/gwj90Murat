@abstract
extends CharacterBody3D
class_name VolatileBody3D

signal msg(text : String)

# taille de l'oiseau en hauteur (pour gérer l'aterrisage)
var tailleY : float

#------------------------------------------------------------
# paramètres du mouvement - à passer en @export var à terme
#------------------------------------------------------------
# Vitesse de rotation sur virage
const ROTSPEED = 4.0
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
# écart d'altitude toléré par rapport à la position de référence avant de décider de corriger
const ECART_ALTITUDE = 1.0
## altitude maximale au delà de laquelle on ne peut plus monter
const ALTITUDE_MAX = 36.0


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
# Altitude où on commence à freiner le piqué pour aterrir
var altitudefreinage : float = 5.0
# Altitude au delà de laquelle on cesse de monter
var altitudemax : float = ALTITUDE_MAX
# vitesse de descente sous laquelle on ne passe pas en descente
const VITESSE_Y_MIN = 3.0
const ALTITUDE_LIBERATION_BONUS = 2.0

# Vitesse de croisière
var speedVect : Vector3
# angle de rotation en virage
var autorotspeed = 0
# var 
# node de la forme OIE (ou autre) pour éviter de trop invoquer $OIE
var nodeoie : Node3D

# Action/Etat automatiques possibles
enum action { AUCUNE, CORRECTION, ATTENTE, LOOPING, ATERRISSAGE, ATERRI, DECOLLAGE, DECROCHE }

# indicateur de correction de trajectoire.
# On perd le contrôle tant qu'on est pas revenu dans la zone et de face
var actionencours : action = action.AUCUNE
# Durée restante du décrochage, avant reprise normale du vol
var decrochage_duree : float = 0.0
## Durée du décrochage, avant reprise normale du vol
const DUREE_DECROCHAGE = 0.16
# pendant une correction, direction cible (a priori la normal de collision)
var correction_direction : Vector3 = Vector3.ZERO


func _init() -> void :
	pass

func _ready() -> void:
	pass

# -----------------------------------------------------------------
#   GESTION DE L'ANIMATION
# -----------------------------------------------------------------
# Note : j'ai supprimé le bouclage auto de l'animation, pour pouvoir enchainer des animations

const ANIM_PLANE = "Vol_plane"
const ANIM_VOL = "Vol_normal"
const ANIM_RESET = "RESET"
const ANIM_REPOS = "RESET"
const ANIM_DECOLLAGE = "Vol_normal"

# indicateur de vol en cours, avec battement d'ailes
var en_vol : bool
# enchainement des animations
var nextanim : String

var animtree : AnimationTree

# On va gérer notre queue d'animation nous-mêmes TODO
func queue_next_anim(next:String):
	match next:
		ANIM_PLANE :
			animtree["parameters/conditions/to_plane"] = true
			animtree["parameters/conditions/to_vol"] = false
			animtree["parameters/conditions/aterrir"] = false
		ANIM_VOL : 
			#if animtree.get("parameters/plane_to_vol/TimeSeek/seek_request") != null :
				#animtree["parameters/plane_to_vol/TimeSeek/seek_request"] = 1.3
			animtree["parameters/conditions/to_vol"] = true
			animtree["parameters/conditions/to_plane"] = false
			animtree["parameters/conditions/aterrir"] = false

# Changement d'animation avec transition
func update_anim():
	animtree["parameters/conditions/decolle"] = (actionencours == action.DECOLLAGE)
	if actionencours == action.ATERRI :
		animtree["parameters/conditions/aterrir"] = true
		animtree["parameters/conditions/to_vol"] = false
		animtree["parameters/conditions/to_plane"] = false

## Fonction de variation aléatoire 
func anim_autoswitch(proba : float = 0.5):
	# Si on est déjà dans une phase d'action, on ignore l'autoswitch
	if actionencours != action.AUCUNE : return
	# Si on est dans une phase de retour au repos, on ignore l'autoswitch
	if nextanim == ANIM_RESET or nextanim == ANIM_REPOS : return
	
	# On passe en vol plané dans 50% des cas
	if randf() < proba :
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

func angle_on_XZ(v1 : Vector3, v2 : Vector3) -> float:
	var v1h = Vector2(v1.x, v1.z)
	var v2h = Vector2(v2.x, v2.z)
	var angle : float = v2h.angle_to(v1h)
	return angle

func dot_on_XZ(v1 : Vector3, v2 : Vector3) -> float:
	return (v1.x * v2.x) + (v1.z * v2.z)

func attente():
	if actionencours == action.AUCUNE :
		actionencours = action.ATTENTE
		autorotspeed = calc_rot_speed(FACTEUR_ATTENTE)
		queue_next_anim(ANIM_VOL)
		# on arrête de descendre ou de monter
		speedVect.y = 0.0
	# sinon on ne passe pas en attente ? TODO/FIXME à creuser
	

## Calcul de l'angle de virage, en fonction de l'action, modulé par un facteur
func calc_rot_speed(facteur : float) -> float :
	return calc_rot_speed_normal(Vector3.FORWARD,facteur) # vers Z négatif, car l'idée c'erst bien de repartir par là

## Calcul de l'angle de virage, en fonction de l'action, modulé par un facteur
func calc_rot_speed_normal(normal : Vector3, facteur : float) -> float :
	#var direction = -Vector2(transform.basis.z.x, transform.basis.z.z)
	#var normalh = Vector2(normal.x, normal.z)
	#var angley = normalh.angle_to(direction)
	var angley : float = angle_on_XZ(normal, -transform.basis.z)
	if angley == 0.0 or angley == PI or angley == -PI:
		angley = 1.0 if randi_range(0,1) == 0 else -1.0
	var rotspeed : float = sign(angley)*facteur
	#print ("rotspeed auto=", rotspeed)
	return rotspeed

# Effectue un virage début de virage vers la droite ou la gauche
# Met à jour speedVect en conséquence, et modifie l'inclinaison de l'oie
func virage(change : float, delta : float):
	if change == 0:
		print ("WARNING ! virage avec change = 0") #FIXME
		return
	var angle : float = change*ANGLE_VIRAGE*delta
	if actionencours == action.CORRECTION:
		#print (rotation.y)
		var ecart : float = angle_on_XZ(correction_direction, speedVect)
		
		if ecart == 0.0:
			angle = 0.0
		elif sign (ecart+angle) != sign(ecart):
			# on a dépassé la remise dans l'axe
			angle = -ecart
			# En fait, on va de sortir de la correction
			
	if angle != 0.0: self.rotate_y(angle)
	speedVect = speedVect.rotated(Vector3.UP, angle)
	
	# changement d'inclinaison (axe Z)
	var inclinaison = clampf(change,-1.0,1.0)
	if abs($OIE.rotation.z) < abs(inclinaison)*INCLINAISON_MAX_VIRAGE :
		#print("vire from ",$OIE.rotation.z, " for ",rad_to_deg(change*ROTSPEED*delta))
		$OIE.rotate_z(inclinaison*ROTSPEED*delta)
	elif abs($OIE.rotation.z) > abs(inclinaison)*INCLINAISON_MAX_VIRAGE * 1.2:
		# on peut commencer à redresser
		#print ("redresse ",rad_to_deg($OIE.rotation.z)," avec incl=", inclinaison)
		redresse(delta, abs(inclinaison))

func redresse(delta : float, force: float = 1.0):
	assert(force >= 0.0, "force de redresse doit être >= 0")
	if abs($OIE.rotation.z) < ROTBACKSPEED*delta :
		$OIE.rotation.z = 0
	else:
		$OIE.rotate_z(-sign($OIE.rotation.z)*force*ROTBACKSPEED*delta)

# Note: la correction est nécessairement dans le plan XZ
# donc on met tous les y à 0 et on travaille en Vector2
func correction(normal : Vector3 = Vector3.ZERO):
	if actionencours == action.AUCUNE or actionencours == action.DECOLLAGE :
		print("Début de correction pour ", self.name)
		actionencours = action.CORRECTION
		correction_direction = normal
		autorotspeed = calc_rot_speed_normal(normal,FACTEUR_CORRECTION)
		if get_node_or_null("AudioPlayerCri") != null:
			$AudioPlayerCri.play(4.0)
	#sinon on ne corrige pas ??? donc on va se planter dans le mur FIXME

func plane(delta : float):
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

	# on ne change pas d'animation
	queue_next_anim(ANIM_PLANE)

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
		
	# Si on dépasse l'altitude max :
	if position.y >= ALTITUDE_MAX :
		speedVect.y -=  delta / 0.5 * speedup
		if speedVect.y < 0 :
			# on stabilise à l'altitude actuelle
			speedVect.y = 0.0

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

	# On continue de battre des ailes
	queue_next_anim(ANIM_VOL)

@abstract func fin_decrochage() -> void

func decroche(delta : float = 0.0, duree : float = 0.0):
	if decrochage_duree == 0.0 :
		# début du décrochage
		decrochage_duree = duree if duree != 0 else DUREE_DECROCHAGE
	if actionencours == action.AUCUNE or actionencours != action.DECROCHE : #FIXME on peut avoir des cas plus particuliers
		# perturbation directe unique liée à un contact avec un obstacle
		var angle = randf_range(-PI/4,PI/4)
		speedVect = speedVect.rotated(Vector3.UP, angle)
		self.rotate_y(angle)
	actionencours = action.DECROCHE
	# on descend 
	position.y -= speeddown * 2.0 * delta
	
	decrochage_duree -= delta
	if decrochage_duree <= 0.0 :
		print ("Fin du décrochage pour ", self.name)
		decrochage_duree = 0.0
		fin_decrochage()
		actionencours = action.AUCUNE

@abstract func do_decolle()

func _physics_process(delta: float) -> void:
	if actionencours == action.DECROCHE :
		decroche(delta)
