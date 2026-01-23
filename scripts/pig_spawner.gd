# res://scripts/pig_spawner.gd
extends Node3D

@export var pig_scene: PackedScene = null  # Сцена свиньи (если есть)
@export var pig_model_path: String = ""  # Путь к модели свиньи (GLTF/FBX)
@export var count: int = 10              # сколько свиней
@export var area_size: Vector2 = Vector2(100, 100)  # размер поля по XZ
@export var y: float = 0.0                # высота над полом
@export var min_distance: float = 3.0     # минимальное расстояние между свиньями
@export var min_distance_from_workbench: float = 5.0  # минимальное расстояние от верстака
@export var pig_scale: float = 1.0       # масштаб свиней

var placed_positions: Array[Vector3] = []
var workbench_position: Vector3 = Vector3.ZERO

func _ready():
	randomize()
	_find_workbench_position()
	
	# Если сцена не задана, загружаем сцену свиньи
	if pig_scene == null:
		_load_pig_scene()
	
	# Размещаем свиней
	_spawn_pigs()

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
		print("PigSpawner: Workbench found at: ", workbench_position)

func _load_pig_scene():
	# Если путь к модели указан, загружаем модель напрямую
	if pig_model_path != "":
		var model = load(pig_model_path) as PackedScene
		if model:
			# Создаем временную сцену из модели
			pig_scene = model
			print("PigSpawner: Loaded pig model from ", pig_model_path)
			return
		else:
			push_warning("PigSpawner: Failed to load pig model from " + pig_model_path)
	
	# Пробуем найти модель свиньи в новом пакете с животными
	var possible_paths = [
		"res://quirky-series-animals-mega-pack-vol-1/quirky-series-animals-mega-pack-vol-1.gltf",
		"res://assets/animals/pig/pig.gltf",
		"res://assets/animals/pig.gltf",
		"res://assets/creatures/pig/pig.gltf",
		"res://assets/beasts/pig/pig.gltf",
	]
	
	for path in possible_paths:
		if ResourceLoader.exists(path):
			print("PigSpawner: Trying to load from ", path)
			var model = load(path) as PackedScene
			if model:
				pig_scene = model
				pig_model_path = path
				print("PigSpawner: Successfully loaded pig model from ", path)
				# Проверяем, что можно инстанцировать
				var test_instance = model.instantiate()
				if test_instance:
					print("PigSpawner: Model can be instantiated, root: ", test_instance.name, " children: ", test_instance.get_child_count())
					test_instance.queue_free()
				return
			else:
				print("PigSpawner: Failed to load model from ", path)
	
	# Если ничего не найдено, выводим ошибку
	push_error("PigSpawner: No pig model found! Please set pig_model_path in the inspector or add pig model to assets/animals/")

func _spawn_pigs():
	if pig_scene == null:
		push_warning("PigSpawner: No pig scene available!")
		return
	
	print("PigSpawner: Starting to spawn ", count, " pigs")
	
	# Находим или создаем контейнер Other (свиньи относятся к типу OTHER)
	var other_container = get_tree().current_scene.get_node_or_null("Other")
	if other_container == null:
		# Если контейнера нет, создаем его
		other_container = Node3D.new()
		other_container.name = "Other"
		get_tree().current_scene.add_child(other_container)
		print("PigSpawner: Created Other container")
	else:
		print("PigSpawner: Found existing Other container")
	
	var spawned_count = 0
	for i in count:
		var position = _get_random_position()
		if position == null:
			print("PigSpawner: Failed to find position for pig ", i)
			continue
		
		# Инстанцируем сцену свиньи
		var pig_scene_instance = pig_scene.instantiate()
		
		if pig_scene_instance == null:
			print("PigSpawner: Failed to instantiate pig scene")
			continue
		
		print("PigSpawner: Instantiated scene, root name: ", pig_scene_instance.name, " children: ", pig_scene_instance.get_child_count())
		
		# Ищем узел свиньи внутри сцены (если это большой пак со всеми животными)
		var pig_node = _find_pig_node(pig_scene_instance)
		if pig_node == null:
			# Если не нашли отдельный узел, выводим список всех узлов для отладки
			print("PigSpawner: Pig node not found, listing all nodes:")
			var all_nodes = _list_all_nodes(pig_scene_instance)
			for node_info in all_nodes:
				print(node_info)
			# Используем всю сцену
			print("PigSpawner: Using entire scene as pig node")
			pig_node = pig_scene_instance
		else:
			print("PigSpawner: Found pig node: ", pig_node.name)
		
		# Создаем RigidBody3D для свиньи (чтобы она была подбираемой)
		var pig_rigid_body = RigidBody3D.new()
		pig_rigid_body.name = "Pig_RigidBody_" + str(spawned_count)
		
		# Находим MeshInstance3D для определения правильной высоты
		var temp_mesh = _find_mesh_instance(pig_node)
		var y_offset = 0.0
		if temp_mesh:
			var aabb = temp_mesh.get_aabb()
			if aabb.size != Vector3.ZERO:
				# Вычисляем нижнюю точку AABB (position.y - size.y/2)
				var bottom_y = aabb.position.y - aabb.size.y / 2.0
				# Поднимаем модель так, чтобы нижняя точка была на уровне земли
				# Если bottom_y отрицательный, значит модель уже выше, нужно поднять
				y_offset = -bottom_y
				print("PigSpawner: Found mesh AABB, bottom_y=", bottom_y, " y_offset=", y_offset, " aabb=", aabb)
			else:
				print("PigSpawner: Mesh AABB is zero size")
		else:
			print("PigSpawner: No mesh instance found in pig_node")
		
		# Устанавливаем позицию с учетом смещения по Y
		# Если y_offset слишком большой, возможно модель уже правильно позиционирована
		if abs(y_offset) > 10.0:
			print("PigSpawner: Warning: y_offset is very large (", y_offset, "), using position.y instead")
			pig_rigid_body.position = position
		else:
			pig_rigid_body.position = Vector3(position.x, position.y + y_offset, position.z)
		
		# Поворачиваем на 180 градусов, если модель изначально смотрит назад
		pig_rigid_body.rotation = Vector3(0, randf_range(0.0, TAU) + PI, 0)
		
		# Устанавливаем масштаб (если модель слишком маленькая, можно увеличить)
		pig_rigid_body.scale = Vector3(pig_scale, pig_scale, pig_scale)
		
		# Убеждаемся, что объект видим
		pig_rigid_body.visible = true
		pig_rigid_body.collision_layer = 1
		pig_rigid_body.collision_mask = 1
		
		# Если нашли отдельный узел свиньи, клонируем его
		if pig_node != pig_scene_instance:
			# Клонируем узел свиньи
			var pig_clone = pig_node.duplicate()
			print("PigSpawner: Cloning pig node, children count: ", pig_clone.get_child_count())
			# Переносим все дочерние узлы из клона в RigidBody3D
			var children_to_move = []
			for child in pig_clone.get_children():
				children_to_move.append(child)
			
			for child in children_to_move:
				pig_clone.remove_child(child)
				pig_rigid_body.add_child(child)
			
			# Освобождаем память
			pig_clone.queue_free()
		else:
			# Переносим все дочерние узлы из сцены в RigidBody3D
			print("PigSpawner: Moving all children from scene to RigidBody3D")
			var children_to_move = []
			for child in pig_scene_instance.get_children():
				children_to_move.append(child)
				print("PigSpawner: Moving child: ", child.name, " (", child.get_class(), ")")
			
			for child in children_to_move:
				pig_scene_instance.remove_child(child)
				pig_rigid_body.add_child(child)
			
			print("PigSpawner: RigidBody3D now has ", pig_rigid_body.get_child_count(), " children")
		
		# Добавляем скрипт анимации (если его еще нет)
		var animation_node = pig_rigid_body.get_node_or_null("PigAnimation")
		if animation_node == null:
			# Создаем узел анимации
			var animation_script = load("res://scripts/pig_animation.gd")
			if animation_script:
				animation_node = Node3D.new()
				animation_node.name = "PigAnimation"
				animation_node.set_script(animation_script)
				pig_rigid_body.add_child(animation_node)
		
		# Добавляем скрипт для подбора
		var pig_script = load("res://scripts/pig.gd")
		if pig_script:
			pig_rigid_body.set_script(pig_script)
			# Устанавливаем item_id (скрипт уже установлен, свойство доступно)
			pig_rigid_body.item_id = "zhu"
			# Также устанавливаем как метаданные для доступа через get_meta()
			pig_rigid_body.set_meta("item_id", "zhu")
			# ВАЖНО: Добавляем в группу pickup ДО добавления в сцену
			# Это нужно, чтобы группа была доступна сразу
			pig_rigid_body.add_to_group("pickup")
			# Отладочный вывод
			print("PigSpawner: Created pig with item_id=", pig_rigid_body.item_id, " in_group=", pig_rigid_body.is_in_group("pickup"))
		
		# Находим первый MeshInstance3D внутри модели и применяем скрипт nature_object
		var mesh_instance = _find_mesh_instance(pig_rigid_body)
		if mesh_instance != null:
			var script = load("res://scripts/nature_object.gd")
			if script and mesh_instance.get_script() == null:
				mesh_instance.set_script(script)
				mesh_instance.object_type = 4  # OTHER
		
		# Освобождаем память от исходной сцены
		pig_scene_instance.queue_free()
		
		# Добавляем свинью в контейнер Other
		other_container.add_child(pig_rigid_body)
		
		# После добавления в сцену _ready() будет вызван автоматически
		# Но мы уже добавили в группу выше, так что это должно работать
		spawned_count += 1
		
		placed_positions.append(position)
		
		print("PigSpawner: Spawned pig #", spawned_count, " at position: ", pig_rigid_body.global_position, " scale: ", pig_rigid_body.scale, " children: ", pig_rigid_body.get_child_count())
	
	print("PigSpawner: Successfully spawned ", spawned_count, " pigs")

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
		
		# Проверяем расстояние от других свиней
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

func _find_pig_node(node: Node) -> Node3D:
	# Ищем узел со свиньей по имени (рекурсивно)
	var node_name_lower = node.name.to_lower()
	if "pig" in node_name_lower and node is Node3D:
		print("PigSpawner: Found pig node by name: ", node.name)
		return node as Node3D
	
	# Также проверяем MeshInstance3D с мешем свиньи
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh != null:
			var mesh_name = ""
			if mesh_instance.mesh.has_method("get_resource_name"):
				mesh_name = mesh_instance.mesh.get_resource_name()
			else:
				mesh_name = str(mesh_instance.mesh)
			var mesh_name_lower = mesh_name.to_lower()
			if "pig" in mesh_name_lower:
				print("PigSpawner: Found pig by mesh name: ", mesh_name)
				# Возвращаем родителя, если это MeshInstance3D
				var parent = node.get_parent()
				if parent is Node3D:
					return parent as Node3D
				return node as Node3D
	
	for child in node.get_children():
		var result = _find_pig_node(child)
		if result:
			return result
	return null

func _list_all_nodes(node: Node, depth: int = 0, names: Array = []) -> Array:
	# Рекурсивно собираем все имена узлов для отладки
	var indent = "  ".repeat(depth)
	var node_info = indent + node.name + " (" + node.get_class() + ")"
	names.append(node_info)
	
	for child in node.get_children():
		_list_all_nodes(child, depth + 1, names)
	
	return names

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	# Рекурсивно ищем MeshInstance3D в дереве узлов
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null
