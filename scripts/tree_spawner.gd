# res://scripts/tree_spawner.gd
extends Node3D

@export var tree_scenes: Array[PackedScene] = []  # Массив сцен деревьев
@export var count: int = 20              # сколько деревьев
@export var area_size: Vector2 = Vector2(100, 100)  # размер поля по XZ
@export var y: float = 0.0                # высота над полом
@export var min_distance: float = 2.0     # минимальное расстояние между деревьями
@export var min_distance_from_workbench: float = 3.0  # минимальное расстояние от верстака
@export var tree_scale: float = 1.0       # масштаб деревьев (начинаем с 1.0 для проверки)

var placed_positions: Array[Vector3] = []
var workbench_position: Vector3 = Vector3.ZERO

func _ready():
	randomize()
	_find_workbench_position()
	
	# Если сцены не заданы, загружаем все доступные сцены деревьев
	if tree_scenes.is_empty():
		_load_tree_scenes()
	
	# Размещаем деревья
	_spawn_trees()

func _find_workbench_position():
	# Ищем верстак в сцене
	var workbench = get_tree().get_first_node_in_group("workbench")
	if workbench == null:
		# Пытаемся найти по имени
		workbench = get_node_or_null("../../Workbench")
		if workbench == null:
			# Пытаемся найти в корне сцены
			workbench = get_tree().current_scene.get_node_or_null("Workbench")
	if workbench != null and workbench is Node3D:
		workbench_position = (workbench as Node3D).global_position
		print("Workbench found at: ", workbench_position)

func _load_tree_scenes():
	# Загружаем все сцены деревьев из папки nature_objects
	var dir = DirAccess.open("res://scenes/nature_objects/")
	if dir == null:
		push_error("Failed to open nature_objects directory")
		return
	
	var tree_names = [
		"Tree1", "Tree2", "Tree3", "Tree4", "Tree5", "Tree6",
		"Tree1_5", "Tree2_1", "Tree2_3", "Tree3_2", "Tree3_3",
		"Tree4_1", "Tree4_2", "Tree5_2", "Tree5_4", "Tree6_1",
		"Tree6_2", "Tree6_3"
	]
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn"):
			var scene_name = file_name.get_basename()
			# Проверяем, является ли это деревом
			for tree_name in tree_names:
				if scene_name.begins_with(tree_name):
					var scene_path = "res://scenes/nature_objects/" + file_name
					var scene = load(scene_path) as PackedScene
					if scene:
						tree_scenes.append(scene)
					break
		file_name = dir.get_next()
	
	print("Loaded ", tree_scenes.size(), " tree scenes")

func _spawn_trees():
	if tree_scenes.is_empty():
		push_warning("No tree scenes available!")
		print("TreeSpawner: No tree scenes loaded!")
		return
	
	print("TreeSpawner: Starting to spawn ", count, " trees from ", tree_scenes.size(), " scenes")
	
	# Находим или создаем контейнер Trees
	var trees_container = get_tree().current_scene.get_node_or_null("Trees")
	if trees_container == null:
		# Если контейнера нет, создаем его
		trees_container = Node3D.new()
		trees_container.name = "Trees"
		get_tree().current_scene.add_child(trees_container)
		print("TreeSpawner: Created Trees container")
	else:
		print("TreeSpawner: Found existing Trees container")
	
	var spawned_count = 0
	for i in count:
		var position = _get_random_position()
		if position == null:
			print("TreeSpawner: Failed to find position for tree ", i)
			continue
		
		# Выбираем случайную сцену дерева
		var tree_scene = tree_scenes[randi() % tree_scenes.size()]
		var tree = tree_scene.instantiate()
		
		if tree == null:
			print("TreeSpawner: Failed to instantiate tree scene")
			continue
		
		tree.position = position
		tree.rotate_y(randf_range(0.0, TAU))
		
		# Сохраняем масштаб в метаданных для передачи в tree.gd
		tree.set_meta("tree_scale", tree_scale)
		
		# Добавляем дерево в контейнер Trees
		trees_container.add_child(tree)
		spawned_count += 1
		
		placed_positions.append(position)
	
	print("TreeSpawner: Successfully spawned ", spawned_count, " trees")

func _get_random_position() -> Vector3:
	var max_attempts = 100
	for attempt in range(max_attempts):
		var x = randf_range(-area_size.x/2.0, area_size.x/2.0)
		var z = randf_range(-area_size.y/2.0, area_size.y/2.0)
		var position = Vector3(x, y, z)
		
		# Проверяем расстояние от верстака
		if workbench_position != Vector3.ZERO:
			var dist_to_workbench = position.distance_to(workbench_position)
			if dist_to_workbench < min_distance_from_workbench:
				continue
		
		# Проверяем расстояние от других деревьев
		var too_close = false
		for placed_pos in placed_positions:
			if position.distance_to(placed_pos) < min_distance:
				too_close = true
				break
		
		if not too_close:
			return position
	
	# Если не удалось найти подходящую позицию, возвращаем случайную
	var x = randf_range(-area_size.x/2.0, area_size.x/2.0)
	var z = randf_range(-area_size.y/2.0, area_size.y/2.0)
	return Vector3(x, y, z)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	# Рекурсивно ищем MeshInstance3D в дереве узлов
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null
