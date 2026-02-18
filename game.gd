extends Node3D

#Par défaut, on considère que le gridmap sera de la même size que le $MeshGround
var gridmapSize : Vector2

# signal émis à la fin du jeu pour prévenir le noeud off-play
signal fini(score : int)

func _ready():
	gridmapSize = $Ground/MeshGround.mesh.size
	#populategridmap()
	populatenuages()
	
	$Ground/CollisionGround.shape.size.x = gridmapSize.x
	$Ground/CollisionGround.shape.size.z = gridmapSize.y
	
	$Oiseau.set_limite_x(gridmapSize.x*0.75)
	$Oiseau.arrive.connect(fin.bind())
	
	startintro()
	pass

func init():
	pass

func startintro():
	pass
	start()

func start():
	$Oiseau.start_atterri_at($Marker3DStart.position)

	# Repositionner la camera ?
	$Camera3D.followed = $Oiseau
	$Camera3D.make_current()
	$AudioStreamPlayer.play()
	

func fin(distance,nb):
	# fin de partie, on renvoie la distance parcourue comme score
	fini.emit(distance)

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
	const ECHELLE_1 : Vector3 = Vector3(1.0,1.0,1.0)
	var instance : Node
	for i in range(0,15):  #FIXME
		instance = scene.instantiate()
		instance.position.y = randf_range(5.0,12.0) #FIXME
		instance.position.z = randf_range(40,82) #FIXME
		instance.position.x = randf_range(-10,10) #FIXME : en fonction de la géométie
		instance.scale = ECHELLE_1 * randf_range(1.0,2.0)
		
		add_child(instance)
		instance.show()

func _input(event: InputEvent) -> void:
	if event.is_action_released("decolle"):
		$OiseauBonus.capture($Oiseau)

func _process(_delta):
	#print ("vvvvvvv")
	#print ($Oiseau.rotation.z)
	#print ($Camera3D.rotation.z)
	#print ("^^^^^^^^")
	pass
