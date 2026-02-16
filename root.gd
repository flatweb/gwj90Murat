extends Node

# Racine du jeu pour gérer les étapes off-play

## true si en attente du tout premier Start du jeu avant le niveau 1
var waitingtostart : bool

@export var newlevel_timer : float = 3.0
@export_range(0, 1, 0.1) var master_volume : float = 1
@export_range(0, 1, 0.1) var music_volume : float = 0.2
@export_range(0, 1, 0.1) var SFX_volume : float = 1
@export var disable_start_countdown : bool = false

var game : Node3D
var score : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PauseContainer.hide()
	resized()
	intro()

func resized():
	var vp : Viewport = get_viewport()
	$PanelContainer.size = vp.size
	$PauseContainer.size = vp.size

func intro():
	score = 0
	$CenterContainer.show()
	$PanelContainer/TextureRectIntro.show()
	$PanelContainer/TextureRectInter.hide()
	%Countdown.hide()
	%Label.hide()
	%VBoxScore.hide()
	%StartButton.text = "  Start !  "
	%StartButton.show()
	%AideButton.show()
	%StartButton.grab_focus()
	$TimerInactivite.stop()
	waitingtostart = true

func _on_aide_button_pressed() -> void:
	showaide() # Replace with function body.

func _on_aide_button_gui_input(event: InputEvent) -> void:
	if %AideButton.visible and event is InputEventJoypadButton:
		showaide()

func _on_popup_child_exiting_tree(node: Node) -> void:
	$CenterContainer.show()
	%StartButton.grab_focus()

func showaide():
	const aideScene = preload("res://aide.tscn")
	$CenterContainer.hide()
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
	if disable_start_countdown:
		newlevel_timer = 0.0
	$TimerInactivite.stop()
	%VBoxScore.hide()
	%StartButton.hide()
	%AideButton.hide()
	%Label.text = "Niveau %d" % 1
	%Label.show()
	startCountdown(newlevel_timer," Prêts ? ")

func startCountdown(timeout, text = ""):
	%Countdown.start(timeout,text)

func _on_countdown_timeout() -> void:
	runlevel()

func runlevel():
	$CenterContainer.hide()
	$PanelContainer.hide()
	$PanelContainer/TextureRectIntro.hide()
	$PanelContainer/TextureRectInter.hide()
	$Musique.stop()
	var gametscn = load("res://game.tscn")
	game = gametscn.instantiate()
	game.init() # FIXME : probablementy inutile ici
	game.fini.connect(endofgame.bind())
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	$PanelContainer.add_sibling(game)

func endofgame(_score : int):
	$Musique.play()
	game.call_deferred("queue_free")
	
	%Label.text = "Distance parcourue : %d" % _score
	%Label.show()
	
	# Ménage dans la VBoxScore FIXME
	for hbox in %VBoxScore.get_children():
		if hbox is HBoxContainer :
			hbox.queue_free()
	
	%VBoxScore.show()

	# Fin de partie ?
	# Il n'y a plus de niveaux - Fin de partie
	$PanelContainer/TextureRectIntro.show()
	%VBoxScore/LabelScore.text += "\n-- FIN DE PARTIE --"
	%StartButton.text = " Restart "
	%StartButton.show()
	%StartButton.grab_focus()
	%AideButton.show()
	$CenterContainer.show()
	$TimerInactivite.start()

func _on_timer_inactivite_timeout() -> void:
	# Se déclenche quand on a fini une partie et qu'on ne fait par Restart
	intro()

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	#AudioServer.set_bus_volume_db(1, linear_to_db(music_volume))
	#AudioServer.set_bus_volume_db(2, linear_to_db(SFX_volume))
