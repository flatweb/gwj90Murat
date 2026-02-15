extends Node3D

#Par défaut, on considère que le gridmap sera de la même size que le $MeshGround
var gridmapSize
var zoneforet = Vector2(0,20)
var zoneprairie = Vector2(21,40)
var zones = [zoneforet, zoneprairie]
var ids : Array

func _ready():
	gridmapSize = $MeshGround.mesh.size
	#populategridmap()
	startintro()
	pass

func startintro():
	pass
	start()

func start():
	# Repositionner la camera ?
	$Camera3D.followed = $Oiseau
	$AudioStreamPlayer.play()

func populategridmap():
	var foretsid : Array
	var prairiesid : Array
	for child in get_children():
		var gmap : GridMap
		if not child is GridMap: continue # Ne prend que les enfants GridMap
		
		gmap = child as GridMap
		var meshlib : MeshLibrary = gmap.mesh_library
		for amesh in meshlib.get_item_list() :
			var meshname = meshlib.get_item_name(amesh)
			if meshname.begins_with("Foret"):
				foretsid.append(amesh)
			elif meshname.begins_with("Prairie"):
				prairiesid.append(amesh)
			
			for x in range(0,gridmapSize.x):
				for y in range(0,gridmapSize.y) :
					var vect3 = Vector3(x,0,y)
					var index = gmap.get_cell_item(vect3)
					if index != GridMap.INVALID_CELL_ITEM : continue
				
					# Nouvelle valeur de l'index
					for zone in zones :
						if y <zone.x or y > zone.y : continue
						# On a trouvé la bonne zone
						index = zone[randi_range(0,foretsid.size()-1)]
						gmap.set_cell_item(vect3,index)
						
		gmap.show()
	
	
	
func _process(_delta):
	#print ("vvvvvvv")
	#print ($Oiseau.rotation.z)
	#print ($Camera3D.rotation.z)
	#print ("^^^^^^^^")
	pass
