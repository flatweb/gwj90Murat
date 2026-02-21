extends Node3D

signal pushtext(txt : String)

var unlockcount : int = 2 # par défaut
var withlightning : bool = false :
	set(b):
		withlightning = b
		for child in get_children():
			if child.is_in_group("Nuage") or child.name.begins_with("Nuage") :
				child.withlightning = true
	get():
		return withlightning

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_area_body_entered(body: Node3D) -> void:
	print (self.name, " : collision avec ", body.name)
	if body.is_in_group("Oiseau"):
		var oiseau = body as Oiseau
		#oiseau.nbcapture = 2 # for testonly
		if oiseau.nbcapture < unlockcount :
			pushtext.emit("You need more geese partners to cross the clouds")
			return
			
		for child in get_children():
			if child.is_in_group("Nuage") or child.name.begins_with("Nuage"):
				child.endestruction = true
			if child.name.contains("Static"):
				child.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
