extends Node3D
@export var use_zone: Area3D
@export var recipes: Array[Recipe] = []   # список рецептов

func _ready():
	if not use_zone: use_zone = $UseZone

func _input(event):
	if event.is_action_pressed("interact") and _player_in_zone():
		_try_craft()

func _player_in_zone() -> bool:
	for b in use_zone.get_overlapping_bodies():
		if b is Camera3D: return true
	return false

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
