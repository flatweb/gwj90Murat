extends CharacterBody3D
class_name VolatileBody3D

# Vitesse de croisière
var speedVect : Vector3
# Action/Etat automatiques possibles
enum action { AUCUNE, CORRECTION, ATTENTE, LOOPING, ATTERRISSAGE, ATTERRI, DECOLLAGE }

# indicateur de correction de trajectoire.
# On perd le contrôle tant qu'on est pas revenu dans la zone et de face
var enaction : bool = false
var actionencours : action = action.AUCUNE

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

# indicateur de vol en cours, avec battement d'ailes
var en_vol : bool
# enchainement des animations
var nextanim : String
var prevanim : String

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


func _physics_process(delta: float) -> void:
	pass
	
func _process(delta: float) -> void:
	pass
	
