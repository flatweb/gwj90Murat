extends CharacterBody3D
class_name VolatileBody3D

# taille de l'oiseau en hauteur (pour gérer l'aterrisage)
var tailleY : float

#------------------------------------------------------------
# paramètres du mouvement - à passer en @export var à terme
#------------------------------------------------------------
# Vitesse de rotation sur virage
const  ROTSPEED = 5.0
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
const ALTITUDE_MAX = 50.0


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
var altitudemax : float = 50.0
# vitesse de descente sous laquelle on ne passe pas en descente
const VITESSE_Y_MIN = 3.0


# Vitesse de croisière
var speedVect : Vector3
# angle de rotation en virage
var autorotspeed = 0

# node de la forme OIE (ou autre) pour éviter de trop invoquer $OIE
var nodeoie : Node3D

# Action/Etat automatiques possibles
enum action { AUCUNE, CORRECTION, ATTENTE, LOOPING, ATERRISSAGE, ATERRI, DECOLLAGE, DECROCHE }

# indicateur de correction de trajectoire.
# On perd le contrôle tant qu'on est pas revenu dans la zone et de face
var enaction : bool = false
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
	#print ($TimerChangeAnim)
	#print ($TimerAttenteAnim)
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
var prevanim : String

# Inutile pour l'instant TODO
var timer_change_anim : Timer
var timer_attente_anim : Timer

func set_timers(timer_change : Timer, timer_attente : Timer):
	if timer_change_anim != null:
		timer_change_anim.queue_free()
	timer_change_anim = timer_change
	if timer_attente_anim != null:
		timer_attente_anim.queue_free()
	timer_attente_anim = timer_attente
	
	Timer.new()
	

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
	if not en_vol : # FIXME : pourquoi ? pour l'aterrissage ?
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

func anim_repos():  # TODO
	$TimerAttenteAnim.start(1.0)
	nextanim = ANIM_RESET
	$OIE/AnimationPlayer.play(ANIM_RESET)

func anim_decollage():  # TODO
	anim_start_vol()


func anim_autoswitch():
	if enaction : return
	if nextanim == ANIM_RESET : return
	#FIXME if position.y > startpos.y : return # TODO : pas joli
	
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

func angle_on_XZ(v1 : Vector3, v2 : Vector3) -> float:
	var v1h = Vector2(v1.x, v1.z)
	var v2h = Vector2(v2.x, v2.z)
	var angle : float = v1h.angle_to(v2h)
	return angle

func attente():
	if enaction == false :
		enaction = true
		actionencours = action.ATTENTE
		autorotspeed = calc_rot_speed(FACTEUR_ATTENTE)

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
		#print ("WARNING ! virage avec change = 0") #FIXME
		return
	var angle : float = change*ANGLE_VIRAGE*delta
	if enaction and actionencours == action.CORRECTION:
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
	if abs($OIE.rotation.z) < abs(change)*INCLINAISON_MAX_VIRAGE :
		#print("vire from ",$OIE.rotation.z, " for ",rad_to_deg(change*ROTSPEED*delta))
		$OIE.rotate_z(min(max(change,-1),1)*ROTSPEED*delta)
	elif abs($OIE.rotation.z) > abs(change)*INCLINAISON_MAX_VIRAGE * 1.2:
		# on peut commencer à redresser
		redresse(delta, abs(change))

func redresse(delta : float, force: float = 1.0):
	if force != 1.0 :
		pass
	if abs($OIE.rotation.z) < ROTBACKSPEED*delta :
		$OIE.rotation.z = 0
	else:
		$OIE.rotate_z(-sign($OIE.rotation.z)*force*ROTBACKSPEED*delta)

# Note: la correction est nécessairement dans le plan XZ
# donc on met tous les y à 0 et on travaille en Vector2
func correction(normal : Vector3 = Vector3.ZERO):
	if enaction == false :
		print("Début de correction pour ", self.name)
		enaction = true
		actionencours = action.CORRECTION
		correction_direction = normal
		autorotspeed = calc_rot_speed_normal(normal,FACTEUR_CORRECTION)
		#autorotspeed = autorotspeed
		if get_node_or_null("AudioPlayerCri") != null:
			$AudioPlayerCri.play(4.0)

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
	# on ne change pas d'inclinaison
	queue_next_anim(ANIM_PLANE)

func remonte(delta : float, rotx = true):
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


func decroche(delta : float = 0.0, duree : float = 0.0):
	if decrochage_duree == 0.0 :
		decrochage_duree = duree if duree != 0 else DUREE_DECROCHAGE
	if not enaction or actionencours != action.DECROCHE : #FIXME on peut avoir des cas plus particuliers
		# perturbation directe unique liée à un contact avec un obstacle
		var angle = randf_range(-PI/4,PI/4)
		speedVect = speedVect.rotated(Vector3.UP, angle)
		self.rotate_y(angle)
	enaction = true
	actionencours = action.DECROCHE
	# on descend 
	position.y -= speeddown * 2.0 * delta
	
	decrochage_duree -= delta
	if decrochage_duree <= 0.0 :
		print ("Fin du décrochage pour ", self.name)
		decrochage_duree = 0.0
		enaction = false


func do_decolle():
	enaction = true
	actionencours = action.DECOLLAGE
	
	speedVect.z = -speedfront
	self.rotation = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if enaction :
		if actionencours == action.DECROCHE :
			decroche(delta)
	
func _process(delta: float) -> void:
	pass
	
