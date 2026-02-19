extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# A priori, cette fonction ne sert pas
func _on_area_limites_body_entered(body: Node3D) -> void:
	if body is StaticBody3D :
		# Les statics ne sont pas censés bouger..., on ignore
		return
	print ("limites atteinte par ", body.name) # FIXME : on fait quoi ?
	pass # Replace with function body.


func _on_limite_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	var limites = self
	if body is StaticBody3D :
		# Les statics ne sont pas censés bouger..., on ignore
		return
	print ("shape limite atteinte par ", body.name) # FIXME : on fait quoi ?
	var proprietaire_forme_local = limites.shape_find_owner(local_shape_index)
	var forme_local = limites.shape_owner_get_owner(proprietaire_forme_local)
	if body.is_in_group("Oiseau"):
		body.start_correction(forme_local.get_real_normal())
	elif body.is_in_group("Bonus"):
		body.queue_free() #TODO : mécanisme à changer
	pass


func _on_area_entered(area: Area3D) -> void:
	var node = area.get_parent()
	if node.is_in_group("isBoid"):
		node.isOutOfBorder = true
	else:
		pass


func _on_area_exited(area: Area3D) -> void:
	var node = area.get_parent()
	if node.is_in_group("isBoid"):
		node.isOutOfBorder = false
	else:
		pass
