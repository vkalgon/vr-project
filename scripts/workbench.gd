extends Node3D
@export var use_zone: Area3D
@export var recipes: Array[Recipe] = []   # список рецептов

func _ready():
	if not use_zone: use_zone = $UseZone

func _input(event):
	if event.is_action_pressed("interact"):
		print("E pressed; in_zone =", _player_in_zone())
		if _player_in_zone():
			_try_craft()


func _player_in_zone() -> bool:
	if use_zone == null:
		return false

	# берём активную камеру (твою DesktopCamera)
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false

	# оценим "радиус" зоны по её CollisionShape3D
	var r := 1.2
	var shape_node := use_zone.get_node_or_null("CollisionShape3D")
	if shape_node and shape_node.shape is BoxShape3D:
		var s: Vector3 = shape_node.shape.size
		r = max(s.x, s.z) * 0.5
	elif shape_node and shape_node.shape is SphereShape3D:
		r = shape_node.shape.radius

	return cam.global_position.distance_to(use_zone.global_position) <= r


func _try_craft():
	# ищем первый доступный рецепт
	for r in recipes:
		if r and GameState.can_pay(r.cost):
			if GameState.pay(r.cost):
				_spawn(r)
				print("Скрафчено:", r.name, r.glyph_hint)
				return
	print("Недостаточно ресурсов для любого рецепта")

func _spawn(r: Recipe):
	if r.out_scene:
		var p := r.out_scene.instantiate()
		get_tree().current_scene.add_child(p)
		p.global_transform.origin = global_transform.origin + Vector3(0, 1.1, 0)
