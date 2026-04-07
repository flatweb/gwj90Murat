extends Node3D

@export var camera : Camera3D

var game_area_size : AABB
@export var nbnuages : int = 100

var nbcapture = 0
var nbcaptureattendu = 0 # sera calculé fonction des noeuds OiseauBonus
var indices = 4
var endofgame : bool = false

# Nombre de nuages que l'on fait aparaitre aléatoirement
const MAXNUAGES : int = 100

# signal émis à la fin du jeu pour prévenir le noeud off-play
signal fini(score : int)

# Demande d'affichage d'un texte (mis en file)
func pushtext(texte : String , _delai : float = 3.0):
	$UI.pushtext(texte)
	
func _ready():
	game_area_size = get_node_aabb(get_node("Level"))
	game_area_size.position.y = 0.0  # TODO constante ou autre ?
	game_area_size.end.y = 40.0  # TODO constante ou autre ?
	
	populatenuages()
	
	#$Ground/CollisionGround.shape.size.x = game_area_size.size.x
	#$Ground/CollisionGround.shape.size.y = 1.0
	#$Ground/CollisionGround.shape.size.z = game_area_size.size.z
	#$Ground.position = $Level.position
	#$Ground.position.x += game_area_size.position.x+game_area_size.size.x/2
	#$Ground.position.y = -0.5
	#$Ground.position.z += game_area_size.position.z+game_area_size.size.z/2
	
	$Porte1Nuages.unlockcount = 2
	$Porte1Nuages.pushtext.connect(pushtext.bind)
	$Porte2Nuages.unlockcount = 8
	$Porte2Nuages.withlightning = true
	$Porte2Nuages.pushtext.connect(pushtext.bind)
	
	$Oiseau.pushtext.connect(pushtext.bind())
	for child in get_children():
		if child.is_in_group("Bonus"):
			child.pushtext.connect(pushtext.bind())
	
	#Mise en place pour commencer le jeu au début
	init()

## Mise en place pour commencer le jeu au début
func init():
	$UI.hide()
	$Oiseau.aterri.connect(fin.bind())
	for child in get_children():
		if child.is_in_group("Bonus"):
			child.perdu.connect(losebonus.bind())
			nbcaptureattendu += 1

	$Oiseau.capture.connect(addcapture.bind())
	refresh_captures()
	$Oiseau.start_aterri_at($Marker3DStart.position)
	$Oiseau.msg.connect(pushtext.bind())

		
	# remplissage des indices
	
	for i in range(0,indices):
		var clue : TextureRect = TextureRect.new()
		clue.texture = load("res://res/texture/UI_fleche.png")
		
		var pngsize = clue.texture.get_size()
		var pngpos : Vector2 = Vector2(pngsize.x*(0.5 + nbcapture), pngsize.y/2)
		clue.position = pngpos
		%HBoxIndices.add_child(clue)

	if (self.get_parent() == get_node("/root")):
		# scène lancée en standalone => autostart
		start()

func start():
	$UI.show()
	$UI.pushtext("It is time to migrate bro !")
	$UI.pushtext("I need to find my friends")
	
func fin(distance):
	if inzonefin :
		print("aterrissage réussi")
		# on considère qui si on est arrivé là, c'est qu'on a eu tous les bonus
		# avant de passer la porte2
		if true : # max(nbcapture,$Oiseau.nbmaxcapture) >= nbcaptureattendu  :
			# fin de partie, on renvoie la distance parcourue comme score
			# en théorie, il faudrait avoir parcouru le moins possible
			print("fin de la partie ?")
			pushtext("We are arrived !!! ")			
			endofgame = true
			await get_tree().create_timer(5.0).timeout
			fini.emit(distance)
		else:
			print("pas assez de bonus à l'arrivée")
			pushtext("Oh ! where are my other friends ?")
	else:
		pushtext("Dodo ?")

func populatenuages():
	var scene = preload("res://nuageblanc.tscn") 
	var instance : Node
	var vent : Vector3 = Vector3.ZERO
	
	var nuage_area_size : AABB = game_area_size
	nuage_area_size.position.y = 5.0  # TODO constante ou réglage
	nuage_area_size.end.y = 30.0  # TODO constante ou réglage
	
	for i in range(0,MAXNUAGES):  #FIXME constante ou réglage
		instance = scene.instantiate()
		instance.process_mode = Node.PROCESS_MODE_DISABLED
		instance.createin(nuage_area_size)
		vent = instance.ajoutervent(vent)
		# on va réutilser le vent pour les suivants
		
		add_child(instance)
		instance.show()

# Code récupéré sur internet pour calculer la taille totale d'un noeud

func get_node_aabb(node : Node3D = null, ignore_top_level : bool = true, bounds_transform : Transform3D = Transform3D()) -> AABB:
	var box : AABB
	var t : Transform3D

	# we are going down the child chain, we want the aabb of each subsequent node to be on the same axis as the parent
	if bounds_transform.is_equal_approx(Transform3D()):
		t = node.global_transform
	else:
		t = bounds_transform
	
	# no more nodes. return default aabb
	if node == null:
		return AABB(Vector3(-0.2, -0.2, -0.2), Vector3(0.4, 0.4, 0.4))
	# makes sure the transform we get isn't distorted
	var top_xform : Transform3D = t.affine_inverse() * node.global_transform

	# convert the node into visualinstance3D to access get_aabb() function.
	var visual_result : VisualInstance3D = node as VisualInstance3D
	if visual_result != null:
		box = visual_result.get_aabb()
	else:
		box = AABB()
	
	# xforms the transform with the box aabb for proper alignment I believe?
	box = top_xform * box
	# recursion
	for i : int in range(0,node.get_child_count()):
		var child : Node3D = node.get_child(i) as Node3D
		if child && !(ignore_top_level && child.top_level):
			var child_box : AABB = get_node_aabb(child, ignore_top_level, t)
			box = box.merge(child_box)
	
	return box

#------------------------------------------------------------
# Gestion des captures de Bonus
#------------------------------------------------------------
func refresh_captures():
	%LabelCaptures.text = "%d" % nbcapture
	if nbcapture > 0 :
		%LabelMaxCaptures.show()
		%LabelMaxCaptures.text = "/ %d" % [nbcaptureattendu]
	else :
		$%LabelMaxCaptures.hide()
	
func addcapture():
	if not inzonefin:
		nbcapture += 1
		pushtext("Yes ! a new friend goose to go further", nbcapture)

		if %HBoxCaptures.visible :
			# utilisé tant que les captures étaient affichées sous forme d'icones
			var bird : TextureRect = TextureRect.new()
			bird.texture = load("res://res/sprites/bird.png")
			var pngsize = bird.texture.get_size()
			var pngpos : Vector2 = Vector2(pngsize.x*(0.5 + nbcapture), pngsize.y/2)
			bird.position = pngpos
			%HBoxCaptures.add_child(bird)
		refresh_captures()

func losebonus(_bonus : Node3D):
	if not inzonefin:
		pushtext("Eh ! why do you leave me ?")
		nbcapture -= 1

		if %HBoxCaptures.visible :
			# utilisé tant que les captures étaient affichées sous forme d'icones
			var textrect = %HBoxCaptures.get_child(0)
			if textrect != null :
				textrect.queue_free()
		
		refresh_captures()

func cheatmode(event : InputEvent):
	# Pour les tests : CheatMode pour démarrer plus loin
	if (event.is_action_released("start1")):
		$Marker3DStart.position.z = -50
		$Oiseau.nbcapture = 2
		$Oiseau.start_aterri_at($Marker3DStart.position)
		pass
	elif (event.is_action_released("start2")):
		# Avant la zone centrale
		nbcapture = 2
		$Oiseau.nbcapture = 2
		$Marker3DStart.position.z = -167
		$Oiseau.start_aterri_at($Marker3DStart.position)
		pass
	elif (event.is_action_released("start3")):
		# dans la zone centrale
		nbcapture = 5
		$Oiseau.nbcapture = 5
		$Marker3DStart.position.z = -288
		$Oiseau.start_aterri_at($Marker3DStart.position)
		pass
	elif (event.is_action_released("start4")):
		# A la sortie de la zone centrale
		nbcapture = 7
		$Oiseau.nbcapture = 7
		$Marker3DStart.position.z = -449
		$Oiseau.start_aterri_at($Marker3DStart.position)
		pass
	elif (event.is_action_released("start5")):
		# Presque à l'arrivée
		nbcapture = 8
		$Oiseau.nbcapture = 8
		$Marker3DStart.position.z = -591
		$Oiseau.start_aterri_at($Marker3DStart.position)
		pass

	# force une fin immédiate pour tests
	if (event.is_action_released("fin")): #Shift+8
		inzonefin = true
		nbcaptureattendu = 0
		fin(123) # on ne peut pas mettre $Oiseau ici
		return
	
	# fait disparaitre les boids
	if (event.is_action_released("noboids")): #Shift+9
		$Flock.queue_free()
		
	if (event.is_action_released("getbonus")): #Shift+0
		# déplacer l'un des bonus libres juste devant soi
		var decalage = Vector3.ZERO
		for bonus in get_tree().get_nodes_in_group("Bonus"):
			if bonus.leader == null :
				decalage +=  Vector3 (2.0,0.0,-4.0)
				bonus.position = $Oiseau.position + decalage
				break

func _input(event: InputEvent) -> void:
	# traitement des touches cheat mode
	cheatmode(event)
	refresh_captures()
		
	if (event.is_action_released("indice")):
		if indices <= 0 :
			pushtext("No more clues")
			return
		
		var distmin = 100000.0
		var bonusproche = -1
		for child in get_children():
			if child.is_in_group("Bonus"):
				var bonus = child
				var dist = (bonus.position - $Oiseau.position).length()
				if dist < distmin and bonus.leader == null:
					distmin = dist
					bonusproche = bonus
		pushtext("Maybe that can help you ?")
		$Oiseau.show_indice(bonusproche)
		indices -= 1
		
		var clue = %HBoxIndices.get_child(0)
		if clue != null:
			clue.queue_free()
	
func _process(delta):
	if endofgame : 
		# unzoom
		$CameraRig.unzoom(delta * 10)
		
	#print ("vvvvvvv")
	#print ($Oiseau.rotation.z)
	#print ($Camera3D.rotation.z)
	#print ("^^^^^^^^")
	pass


var inzonefin : bool = false
func _on_zonefin_body_entered(body: Node3D) -> void:
	if body.is_in_group("Oiseau"):
		print("entrée dans la zone fin")
		inzonefin = true
	pass # Replace with function body.


func _on_zonefin_body_exited(body: Node3D) -> void:
	if body.is_in_group("Oiseau"):
		print("sortie de la zone fin")
		inzonefin = false
	pass # Replace with function body.
