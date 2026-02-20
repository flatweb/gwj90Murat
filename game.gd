extends Node3D

@export var camera : Camera3D

#Par défaut, on considère que le gridmap sera de la même size que le $MeshGround
var gridmapSize : Vector2
var game_area_size : AABB
@export var nbnuages : int = 50

var nbcapture = 0
var nbcaptureattendu = 0 # sera calculé fonction des noeuds OiseauBonus
var indices = 3

# signal émis à la fin du jeu pour prévenir le noeud off-play
signal fini(score : int)

func _ready():
	gridmapSize = $Ground/MeshGround.mesh.size
	game_area_size = get_node_aabb(get_node("Level"))
	game_area_size.position.y = 0.0  # TODO constante ou autre ?
	game_area_size.end.y = 40.0  # TODO constante ou autre ?
	
	#populategridmap()
	populatenuages()
	
	$Ground/CollisionGround.shape.size.x = game_area_size.size.x
	$Ground/CollisionGround.shape.size.y = 1.0
	$Ground/CollisionGround.shape.size.z = game_area_size.size.z
	$Ground.position = $Level.position
	$Ground.position.x += game_area_size.position.x+game_area_size.size.x/2
	$Ground.position.y = -0.5
	$Ground.position.z += game_area_size.position.z+game_area_size.size.z/2
	
	startintro()
	pass

func init():
	pass

func startintro():
	pass
	start()

func start():
	$Oiseau.aterri.connect(fin.bind())
	for child in get_children():
		if child.is_in_group("Bonus"):
			child.perdu.connect(losebonus.bind())
			nbcaptureattendu += 1

	$Oiseau.capture.connect(addcapture.bind())
	%LabelCaptures.text = "%d / %d" % [nbcapture, nbcaptureattendu]
	$Oiseau.start_aterri_at($Marker3DStart.position)

	$AudioStreamPlayer.play()
	
func fin(distance):
	if inzonefin :
		print("aterrissage réussi à l'arrivée")
		if nbcapture >= nbcaptureattendu :
			# fin de partie, on renvoie la distance parcourue comme score
			fini.emit(distance)
		else:
			print("pas assez de bonus")
	else:
		print("pas encore à l'arrivée")

func populategridmap():
	var zones : Dictionary[String,Vector2]
	
	var startmapy = gridmapSize.y/2
	zones = {"Foret":Vector2(startmapy-20,startmapy-0), \
			"Prairie":Vector2(startmapy-40,startmapy-21)  \
			}
	
	var tabindex : Dictionary[String,Array]
	
	
	for child in get_children():
		var gmap : GridMap
		if not child is GridMap: continue # Ne prend que les enfants GridMap
		
		gmap = child as GridMap
	
		var rotations = Array()
		for q in range(0,4):
			rotations.append(gmap.get_orthogonal_index_from_basis(Basis.IDENTITY.rotated(Vector3.UP,PI/2*q)))
		
		var meshlib : MeshLibrary = gmap.mesh_library
		for imesh in meshlib.get_item_list() :
			var meshname = meshlib.get_item_name(imesh)
			for zone in zones :
				if meshname.begins_with(zone):
					var array : Array
					if tabindex.has(zone):
						array = tabindex.get(zone)
					else:
						array = Array()
					array.append(imesh)
					tabindex[zone] = array
			
		print (tabindex)
		#var cells = gmap.get_used_cells()
			
		for x in range(-gridmapSize.x/2,+gridmapSize.x/2):
			for y in range(gridmapSize.y/2,-gridmapSize.y/2,-1) :
				var vect3 = Vector3(x,0,y)
				var index = gmap.get_cell_item(vect3)
				if index != GridMap.INVALID_CELL_ITEM :
					continue
			
				# Nouvelle valeur de l'index
				for zone in zones :
					# On utilise des limites de zones éventuellement inversées
					if y >=zones[zone].x and y < zones[zone].y  or \
						y >=zones[zone].y and y < zones[zone].x :
						# On a trouvé la bonne zone
						# on prend l'un des meshs au hasard parmi ceux de la zone
						index = tabindex[zone][randi_range(0,tabindex[zone].size()-1)]
						# on positionne
						gmap.set_cell_item(vect3, index, rotations[randi_range(0,3)])
		
		gmap.show()
	
func populatenuages():
	var scene = preload("res://nuage.tscn") 
	var instance : Node
	var vent : Vector3 = Vector3.ZERO
	
	var nuage_area_size : AABB = game_area_size
	nuage_area_size.position.y = 5.0  # TODO constante ou réglage
	nuage_area_size.end.y = 25.0  # TODO constante ou réglage
	
	for i in range(0,100):  #FIXME constante ou réglage
		instance = scene.instantiate()
		instance.createin(nuage_area_size)
		vent = instance.ajoutervent(vent)
		# on va réutilser le vent pour les suivants
		
		add_child(instance)
		instance.show()

# Code récupéré sur internet pour calculer la taille totale d'un noeud

func get_node_aabb(node : Node3D = null, ignore_top_level : bool = true, bounds_transform : Transform3D = Transform3D()) -> AABB:
	var box : AABB
	var transform : Transform3D

	# we are going down the child chain, we want the aabb of each subsequent node to be on the same axis as the parent
	if bounds_transform.is_equal_approx(Transform3D()):
		transform = node.global_transform
	else:
		transform = bounds_transform
	
	# no more nodes. return default aabb
	if node == null:
		return AABB(Vector3(-0.2, -0.2, -0.2), Vector3(0.4, 0.4, 0.4))
	# makes sure the transform we get isn't distorted
	var top_xform : Transform3D = transform.affine_inverse() * node.global_transform

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
			var child_box : AABB = get_node_aabb(child, ignore_top_level, transform)
			box = box.merge(child_box)
	
	return box

#------------------------------------------------------------
# Gestion des captures de Bonus
#------------------------------------------------------------
func refresh_captures():
	%LabelCaptures.text = "%d / %d" % [nbcapture, nbcaptureattendu]
	
func addcapture():
	nbcapture += 1
	refresh_captures()

func losebonus():
	nbcapture -= 1
	refresh_captures()

func _input(event: InputEvent) -> void:
	if (event.is_action_released("indice")):
		if indices <= 0 : return
		var distmin = 100000.0
		var bonusproche = -1
		for child in get_children():
			if child.is_in_group("Bonus"):
				var bonus = child
				var dist = (bonus.position - $Oiseau.position).length()
				if dist < distmin and bonus.leader == null:
					distmin = dist
					bonusproche = bonus
		
		$Oiseau.show_indice(bonusproche)
		indices -= 1
		var txt = ""
		for i in range(0,indices) :
			txt = txt + "X"
		%LabelIndices.text = txt
	
	
func _process(_delta):
	#print ("vvvvvvv")
	#print ($Oiseau.rotation.z)
	#print ($Camera3D.rotation.z)
	#print ("^^^^^^^^")
	pass


func _on_area_porte1_body_entered(body: Node3D) -> void:
	print ("collision avec ", body.name)
	if body.is_in_group("Oiseau"):
		for child in $Porte1Nuages.get_children():
			if child.is_in_group("Nuage"):
				child.endestruction = true
		pass # Replace with function body.

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
