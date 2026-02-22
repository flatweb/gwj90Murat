extends Node3D

@export var mesh : MeshInstance3D
#@export var default_texture : String
@export var textures_hiver : Array[Texture2D]
@export var textures_printemps : Array[Texture2D]
@export var textures_ete : Array[Texture2D]

func _ready() -> void:
	#apply_texture(textures_hiver[3])
	#apply_random_winter_texture()
	pass

func apply_texture(texture_to_apply : Texture2D):
	if mesh.material_override == null:
		mesh.material_override = StandardMaterial3D.new()
	if texture_to_apply:
		mesh.material_override.albedo_texture = texture_to_apply
		#print("TEXTURE ", texture_to_apply, " APPLIED TO ", mesh)

func apply_random_texture_from_array(texture_array : Array):
	var randn = randi_range(0, texture_array.size()-1)
	#print("random number is : ", randn, " -> which is :", texture_array[randn])
	apply_texture(texture_array[randn])
	
func apply_random_winter_texture():
	apply_random_texture_from_array(textures_hiver)
	
func apply_random_spring_texture():
	apply_random_texture_from_array(textures_printemps)
	
func apply_random_summer_texture():
	apply_random_texture_from_array(textures_ete)
