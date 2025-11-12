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
		_place_from_collection(type_scenes[type], container, count, map_size, min_distance, min_distance_from_workbench, workbench_position, base_scale, placed_positions, main_scene)
	
	print("Placed objects on the map!")

func _place_from_collection(scene_paths: Array, container: Node3D, count: int, map_size: Vector2, min_distance: float, min_distance_from_workbench: float, workbench_position: Vector3, base_scale: Vector3, placed_positions: Array, main_scene: Node):
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

