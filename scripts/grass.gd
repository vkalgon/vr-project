# res://scripts/grass.gd
extends RigidBody3D
@export var item_id := "cao"

func _ready():
	add_to_group("pickup") # помечаем, что это подбираемый предмет
