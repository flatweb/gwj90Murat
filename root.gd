extends Node

# Racine du jeu pour gérer les étapes off-play

## true si en attente du tout premier Start du jeu avant le niveau 1
var waitingtostart : bool

@export var newlevel_timer : float = 3.0
@export_range(0, 1, 0.1) var master_volume : float = 1
@export_range(0, 1, 0.1) var music_volume : float = 0.2
@export_range(0, 1, 0.1) var SFX_volume : float = 1

var game : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PauseContainer.hide()
	resized()
	loadgame()

func resized():
	var vp : Viewport = get_viewport()
	$PanelContainer.size = vp.size
	$PauseContainer.size = vp.size

func loadgame():
	# On vide la partie précédente
	if game != null :
		game.queue_free()
		
	var gametscn = load("res://game.tscn")
	game = gametscn.instantiate()
	game.fini.connect(endofgame.bind())
	game.process_mode = Node.PROCESS_MODE_ALWAYS
	$PanelContainer.add_sibling(game)
	
	%IntroContainer.show()
	%Label.hide()
	%VBoxScore.hide()
	%StartButton.text = "  Start !  "
	%StartButton.show()
	%AideButton.show()
	%StartButton.grab_focus()
	$TimerInactivite.stop()
	waitingtostart = true
	
	get_tree().paused = true

func _on_aide_button_pressed() -> void:
	showaide() # Replace with function body.

func _on_aide_button_gui_input(event: InputEvent) -> void:
	if %AideButton.visible and event is InputEventJoypadButton:
		showaide()

func _on_popup_child_exiting_tree(node: Node) -> void:
	%IntroContainer.show()
	%StartButton.grab_focus()

func showaide():
	const aideScene = preload("res://aide.tscn")
	%IntroContainer.hide()
	$Popup.add_child(aideScene.instantiate())

func _on_start_button_pressed() -> void:
	if waitingtostart: return
	start()

# Horreur qui permet de distinguer le shortcut (via manette) du clic sur le bouton de la souris
func _on_start_button_up() -> void:
	if %StartButton.visible:
		start()

func start():
	# Start ou Continue
	waitingtostart = false
	#
	$TimerInactivite.stop()
	%VBoxScore.hide()
	%StartButton.hide()
	%AideButton.hide()
	%IntroContainer.hide()
	$PanelContainer.hide()
	$Musique.stop()
	get_tree().paused = false
	
	game.start()
	
func endofgame(_score : int):
	$Musique.play()
	get_tree().paused = true
	
	%Label.text = "You flew : %d km" % _score
	%Label.show()

	# Fin de partie ?
	# Il n'y a plus de niveaux - Fin de partie
	%StartButton.text = " Restart "
	%StartButton.show()
	%StartButton.grab_focus()
	%AideButton.show()
	%IntroContainer.show()
	$TimerInactivite.start()

func _on_timer_inactivite_timeout() -> void:
	# Se déclenche quand on a fini une partie et qu'on ne fait par Restart
	loadgame()

func _input(event : InputEvent):
	if not waitingtostart: return
	#FIXME : en attente d'une interaction
	if Input.is_action_just_pressed("start"):
		waitingtostart = false
		start()
	
func _unhandled_input(event: InputEvent):
	if (event.is_action_released("ui_cancel")):
		if not get_tree().paused :
			# Mise en pause
			topause()
		else:
			# Sortie de la pause
			# FIXME : on ne passe jamais ici
			outpause()

func topause():
	# Mise en pause
	get_tree().paused = true
	$PauseContainer.show()

func _on_out_pause_button_up() -> void:
	outpause()

func outpause():
	$PauseContainer.hide()
	get_tree().paused = false

func _on_giveup_button_up() -> void:
	pass # Replace with function body.
	$PauseContainer.hide()
	get_tree().paused = false
	endofgame(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	#AudioServer.set_bus_volume_db(1, linear_to_db(music_volume))
	#AudioServer.set_bus_volume_db(2, linear_to_db(SFX_volume))
