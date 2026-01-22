# res://addons/nature_placer_plugin/plugin.gd
@tool
extends EditorPlugin

var dock: Control
var nature_placer_dock: Control

func _enter_tree():
	# Создаем dock панель
	var dock_scene = load("res://addons/nature_placer_plugin/nature_placer_dock.tscn") as PackedScene
	if dock_scene:
		dock = dock_scene.instantiate()
		add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
		
		# Подключаем сигналы
		var place_button = dock.get_node_or_null("ScrollContainer/VBoxContainer/PlaceButton")
		var clear_button = dock.get_node_or_null("ScrollContainer/VBoxContainer/ClearButton")
		
		if place_button:
			place_button.pressed.connect(_on_place_button_pressed)
		else:
			push_error("PlaceButton not found in dock!")
		
		if clear_button:
			clear_button.pressed.connect(_on_clear_button_pressed)
		else:
			push_error("ClearButton not found in dock!")
		
		print("Nature Placer Plugin: Dock panel loaded successfully")
	else:
		push_error("Failed to load nature_placer_dock.tscn")

func _exit_tree():
	# Удаляем dock при выгрузке плагина
	if dock:
		# В Godot 4.x метод может называться по-другому, просто удаляем
		dock.queue_free()

func _on_place_button_pressed():
	var main_scene = EditorInterface.get_edited_scene_root()
	if main_scene == null:
		EditorInterface.get_resource_filesystem().scan()
		push_error("Please open Main.tscn scene first!")
		return
	
	var vbox = dock.get_node("ScrollContainer/VBoxContainer")
	
	# Получаем параметры из UI
	var map_size_x = vbox.get_node("MapSizeX").value
	var map_size_z = vbox.get_node("MapSizeZ").value
	var min_distance = vbox.get_node("MinDistance").value
	var min_distance_from_workbench = vbox.get_node("MinDistanceFromWorkbench").value
	
	# Получаем количества объектов
	var tree_count = vbox.get_node("TreeCount").value
	var rock_count = vbox.get_node("RockCount").value
	var mushroom_count = vbox.get_node("MushroomCount").value
	var grass_count = vbox.get_node("GrassCount").value
	var structure_count = vbox.get_node("StructureCount").value
	var decoration_count = vbox.get_node("DecorationCount").value
	var effect_count = vbox.get_node("EffectCount").value
	var tool_count = vbox.get_node("ToolCount").value
	var other_count = vbox.get_node("OtherCount").value
	
	# Получаем масштабы
	var tree_scale = Vector3(
		vbox.get_node("TreeScaleX").value,
		vbox.get_node("TreeScaleY").value,
		vbox.get_node("TreeScaleZ").value
	)
	var rock_scale = Vector3(
		vbox.get_node("RockScaleX").value,
		vbox.get_node("RockScaleY").value,
		vbox.get_node("RockScaleZ").value
	)
	var mushroom_scale = Vector3(
		vbox.get_node("MushroomScaleX").value,
		vbox.get_node("MushroomScaleY").value,
		vbox.get_node("MushroomScaleZ").value
	)
	var grass_scale = Vector3(
		vbox.get_node("GrassScaleX").value,
		vbox.get_node("GrassScaleY").value,
		vbox.get_node("GrassScaleZ").value
	)
	
	# Размещаем объекты
	_place_objects(main_scene, Vector2(map_size_x, map_size_z), min_distance, min_distance_from_workbench,
		tree_count, rock_count, mushroom_count, grass_count, structure_count, decoration_count, effect_count, tool_count, other_count,
		tree_scale, rock_scale, mushroom_scale, grass_scale)
	
	print("Objects placed on the map!")

func _on_clear_button_pressed():
	var main_scene = EditorInterface.get_edited_scene_root()
	if main_scene == null:
		return
	
	# Удаляем все размещенные объекты
	var containers = ["Trees", "Rocks", "Mushrooms", "GrassPatches", "Structures", "Decorations", "Effects", "Tools", "Other"]
	for container_name in containers:
		var container = main_scene.get_node_or_null(container_name)
		if container:
			container.queue_free()
	
	print("Cleared all placed objects!")

func _place_objects(main_scene: Node, map_size: Vector2, min_distance: float, min_distance_from_workbench: float,
	tree_count: int, rock_count: int, mushroom_count: int, grass_count: int, structure_count: int, decoration_count: int, effect_count: int, tool_count: int, other_count: int,
	tree_scale: Vector3, rock_scale: Vector3, mushroom_scale: Vector3, grass_scale: Vector3):
	
	# Инициализируем генератор случайных чисел
	randomize()
	
	# Находим верстак
	var workbench_position = Vector3.ZERO
	var workbench = main_scene.get_node_or_null("Workbench")
	if workbench:
		workbench_position = workbench.global_position
	
	# Создаем контейнеры для объектов
	var containers = {
		"Trees": tree_count,
		"Rocks": rock_count,
		"Mushrooms": mushroom_count,
		"GrassPatches": grass_count,
		"Structures": structure_count,
		"Decorations": decoration_count,
		"Effects": effect_count,
		"Tools": tool_count,
		"Other": other_count
	}
	
	var scales = {
		"Trees": tree_scale,
		"Rocks": rock_scale,
		"Mushrooms": mushroom_scale,
		"GrassPatches": grass_scale,
		"Structures": Vector3(1.0, 1.0, 1.0),
		"Decorations": Vector3(1.0, 1.0, 1.0),
		"Effects": Vector3(1.0, 1.0, 1.0),
		"Tools": Vector3(1.0, 1.0, 1.0),
		"Other": Vector3(1.0, 1.0, 1.0)
	}
	
	# Загружаем маппер
	var mapper = load("res://scripts/nature_object_mapper.gd")
	var scenes_dir = "res://scenes/nature_objects/"
	
	# Сканируем папку со сценами
	var dir = DirAccess.open(scenes_dir)
	if dir == null:
		push_error("Directory not found: " + scenes_dir)
		return
	
	# Группируем сцены по типам
	var type_scenes: Dictionary = {}
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn"):
			var scene_name = file_name.get_basename()
			var object_type = mapper.get_object_type_by_name(scene_name)
			if not type_scenes.has(object_type):
				type_scenes[object_type] = []
			type_scenes[object_type].append(scenes_dir + file_name)
		file_name = dir.get_next()
	
	# Создаем контейнеры и размещаем объекты
	var type_to_container = {
		0: "Trees",
		1: "Rocks",
		2: "Mushrooms",
		3: "GrassPatches",
		5: "Structures",
		6: "Decorations",
		7: "Effects",
		8: "Tools",
		4: "Other"
	}
	
	# Собираем позиции уже размещенных объектов
	var placed_positions: Array[Vector3] = []
	var containers_dict = {}
	
	# Сначала создаем все контейнеры и собираем позиции существующих объектов
	for type in type_to_container.keys():
		var container_name = type_to_container[type]
		var container = main_scene.get_node_or_null(container_name)
		if container == null:
			container = Node3D.new()
			container.name = container_name
			main_scene.add_child(container, true)
			container.set_owner(main_scene)
		else:
			# Собираем позиции уже размещенных объектов в этом контейнере
			for child in container.get_children():
				if child is Node3D:
					placed_positions.append(child.global_position)
		containers_dict[type] = container
	
	# Затем размещаем объекты
	for type in type_to_container.keys():
		var container_name = type_to_container[type]
		var count = containers[container_name]
		if count <= 0 or not type_scenes.has(type) or type_scenes[type].is_empty():
			continue
		
		var container = containers_dict[type]
		
		# Размещаем объекты
		var base_scale = scales[container_name]
		_place_from_collection(type_scenes[type], container, count, map_size, min_distance, min_distance_from_workbench, workbench_position, base_scale, placed_positions, main_scene, type)
	
	print("Placed objects on the map!")

func _place_from_collection(scene_paths: Array, container: Node3D, count: int, map_size: Vector2, min_distance: float, min_distance_from_workbench: float, workbench_position: Vector3, base_scale: Vector3, placed_positions: Array, main_scene: Node, object_type: int):
	# Используем сетку для равномерного распределения
	var grid_size = ceil(sqrt(count * 2))
	var cell_size_x = map_size.x / grid_size
	var cell_size_z = map_size.y / grid_size
	var placed_in_grid = 0
	
	# Создаем список доступных ячеек
	var available_cells: Array[Vector2i] = []
	for x in range(grid_size):
		for z in range(grid_size):
			available_cells.append(Vector2i(x, z))
	
	available_cells.shuffle()
	
	# Собираем все экземпляры в массив перед добавлением
	var instances_to_add: Array[Node] = []
	var positions_to_add: Array[Vector3] = []
	
	# Размещаем объекты в ячейках сетки
	for i in range(min(count, available_cells.size())):
		var cell = available_cells[i]
		var cell_center_x = -map_size.x / 2.0 + (cell.x + 0.5) * cell_size_x
		var cell_center_z = -map_size.y / 2.0 + (cell.y + 0.5) * cell_size_z
		
		var offset_x = randf_range(-cell_size_x * 0.4, cell_size_x * 0.4)
		var offset_z = randf_range(-cell_size_z * 0.4, cell_size_z * 0.4)
		
		var position = Vector3(cell_center_x + offset_x, 0.0, cell_center_z + offset_z)
		
		# Проверяем расстояние от верстака
		if workbench_position != Vector3.ZERO:
			if position.distance_to(workbench_position) < min_distance_from_workbench:
				continue
		
		# Проверяем минимальное расстояние от других объектов
		var too_close = false
		for placed_pos in placed_positions:
			if position.distance_to(placed_pos) < min_distance:
				too_close = true
				break
		
		if too_close:
			continue
		
		# Загружаем случайную сцену этого типа
		var scene_path = scene_paths[randi() % scene_paths.size()]
		var scene = load(scene_path) as PackedScene
		if scene == null:
			continue
		
		var instance = scene.instantiate()
		if instance == null:
			continue
		
		instance.position = position
		instance.rotation.y = randf() * TAU
		# Применяем только base_scale без вариаций, чтобы сохранить исходные размеры и пропорции из сцены
		instance.scale = base_scale
		
		instances_to_add.append(instance)
		positions_to_add.append(position)
		placed_positions.append(position)
		placed_in_grid += 1
	
	# Размещаем оставшиеся объекты случайно
	var remaining = count - placed_in_grid
	for i in range(remaining):
		var attempts = 0
		var position: Vector3
		while attempts < 100:
			position = Vector3(
				randf_range(-map_size.x / 2.0, map_size.x / 2.0),
				0.0,
				randf_range(-map_size.y / 2.0, map_size.y / 2.0)
			)
			
			if workbench_position != Vector3.ZERO:
				if position.distance_to(workbench_position) < min_distance_from_workbench:
					attempts += 1
					continue
			
			var too_close = false
			for placed_pos in placed_positions:
				if position.distance_to(placed_pos) < min_distance:
					too_close = true
					break
			
			if not too_close:
				break
			
			attempts += 1
		
		if attempts >= 100:
			continue
		
		var scene_path = scene_paths[randi() % scene_paths.size()]
		var scene = load(scene_path) as PackedScene
		if scene == null:
			continue
		
		var instance = scene.instantiate()
		if instance == null:
			continue
		
		instance.position = position
		instance.rotation.y = randf() * TAU
		# Применяем только base_scale без вариаций, чтобы сохранить исходные размеры и пропорции из сцены
		instance.scale = base_scale
		
		instances_to_add.append(instance)
		positions_to_add.append(position)
		placed_positions.append(position)
	
	# Добавляем все узлы пакетами
	var batch_size = 50
	for i in range(0, instances_to_add.size(), batch_size):
		var end_idx = min(i + batch_size, instances_to_add.size())
		for j in range(i, end_idx):
			var instance = instances_to_add[j]
			container.add_child(instance, true)
			instance.set_owner(main_scene)
			# Делаем объект подбираемым, если это дерево или трава
			_make_pickable(instance, type)

# Делает объект подбираемым, оборачивая его в RigidBody3D если нужно
func _make_pickable(instance: Node, object_type: int):
	# Только деревья (type 0) и трава (type 3) делаем подбираемыми
	if object_type != 0 and object_type != 3:
		return
	
	# Проверяем, является ли корневой узел уже RigidBody3D
	if instance is RigidBody3D:
		# Если уже RigidBody3D, просто добавляем скрипт
		if instance.get_script() == null:
			if object_type == 0:  # Дерево
				var tree_script = load("res://scripts/tree.gd")
				if tree_script:
					instance.set_script(tree_script)
			elif object_type == 3:  # Трава
				var grass_script = load("res://scripts/grass.gd")
				if grass_script:
					instance.set_script(grass_script)
		return
	
	# Если корневой узел не RigidBody3D, ищем первый MeshInstance3D в дереве
	var mesh_instance = _find_mesh_instance(instance)
	if mesh_instance == null:
		return
	
	var parent = instance
	var mesh_parent = mesh_instance.get_parent()
	
	# Создаем RigidBody3D
	var rigid_body = RigidBody3D.new()
	rigid_body.name = instance.name + "_RigidBody"
	rigid_body.position = instance.position
	rigid_body.rotation = instance.rotation
	rigid_body.scale = instance.scale
	# Устанавливаем collision_layer для взаимодействия
	rigid_body.collision_layer = 1  # Слой 1 для физических объектов
	rigid_body.collision_mask = 1   # Маска для взаимодействия с другими объектами
	
	# Переносим все дочерние узлы instance в RigidBody3D
	var children_to_move = []
	for child in instance.get_children():
		children_to_move.append(child)
	
	for child in children_to_move:
		instance.remove_child(child)
		rigid_body.add_child(child)
		child.owner = rigid_body
	
	# Заменяем instance на rigid_body в родителе
	if parent != null:
		parent.remove_child(instance)
		parent.add_child(rigid_body)
		rigid_body.owner = parent
	
	# Добавляем скрипт
	if object_type == 0:  # Дерево
		var tree_script = load("res://scripts/tree.gd")
		if tree_script:
			rigid_body.set_script(tree_script)
	elif object_type == 3:  # Трава
		var grass_script = load("res://scripts/grass.gd")
		if grass_script:
			rigid_body.set_script(grass_script)
	
	# Создаем коллизию для RigidBody3D
	_create_collision_for_rigid_body(rigid_body, mesh_instance)

# Находит первый MeshInstance3D в дереве узлов
func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null

# Создает коллизию для RigidBody3D на основе MeshInstance3D
func _create_collision_for_rigid_body(rigid_body: RigidBody3D, mesh_instance: MeshInstance3D):
	if rigid_body == null or mesh_instance == null:
		return
	
	# Проверяем, есть ли уже CollisionShape3D
	for child in rigid_body.get_children():
		if child is CollisionShape3D:
			return
	
	# Получаем AABB меша
	var aabb = mesh_instance.get_aabb()
	if aabb.size == Vector3.ZERO:
		# Если AABB пустой, создаем простую коллизию
		aabb = AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
	
	# Создаем CollisionShape3D с BoxShape3D
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	
	# Создаем BoxShape3D на основе AABB
	var box_shape = BoxShape3D.new()
	box_shape.size = aabb.size
	collision_shape.shape = box_shape
	
	# Позиционируем коллизию относительно центра меша
	collision_shape.position = aabb.get_center()
	
	rigid_body.add_child(collision_shape)
	collision_shape.owner = rigid_body

