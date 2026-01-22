# res://scripts/nature_spawner.gd
extends Node3D

# Сцена с объектами природы (загружается динамически)
var nature_scene: PackedScene = null

# Параметры размещения
@export var map_size: Vector2 = Vector2(100, 100)  # Размер карты по XZ
@export var y_position: float = 0.0  # Высота размещения объектов

# Количество объектов каждого типа (увеличено для заполнения большой карты)
@export var tree_count: int = 0  # Отключено, деревья теперь спавнятся через TreeSpawner
@export var rock_count: int = 200
@export var mushroom_count: int = 250
@export var grass_patch_count: int = 1000
@export var structure_count: int = 50  # Дома, заборы, мосты, руины
@export var decoration_count: int = 100  # Фонари, кристаллы, надгробия, указатели
@export var effect_count: int = 20  # Огонь
@export var tool_count: int = 10  # Инструменты
@export var other_count: int = 30  # Остальные объекты

# Минимальное расстояние между объектами (уменьшено для более плотного размещения)
@export var min_distance: float = 0.2
# Минимальное расстояние от верстака
@export var min_distance_from_workbench: float = 3.0

# Масштаб объектов природы (реалистичные размеры, близкие к оригинальным из Blender)
@export var tree_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Деревья - оригинальный размер
@export var rock_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Камни - оригинальный размер
@export var mushroom_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Грибы - оригинальный размер
@export var grass_patch_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Участки травы - оригинальный размер
@export var structure_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Строения - оригинальный размер
@export var decoration_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Декор - оригинальный размер
@export var effect_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Эффекты - оригинальный размер
@export var tool_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Инструменты - оригинальный размер
@export var other_scale: Vector3 = Vector3(1.0, 1.0, 1.0)  # Остальное - оригинальный размер
# Позиция верстака (будет найдена автоматически)
var workbench_position: Vector3 = Vector3.ZERO

var placed_positions: Array[Vector3] = []

# Словарь для сохранения типов объектов (имя объекта -> тип)
var saved_object_types: Dictionary = {}

func _ready():
	randomize()
	# Находим позицию верстака
	_find_workbench_position()
	# Загружаем сцену динамически
	var scene_path = "res://.godot/imported/NaturePack_AllModels.fbx-32b326b5cb41483963e05eb421cf1b60.scn"
	nature_scene = load(scene_path) as PackedScene
	if nature_scene == null:
		push_warning("Failed to load nature scene from: " + scene_path)
		return
	_spawn_nature_objects()
	# Обрабатываем уже существующие объекты на сцене
	_make_existing_objects_pickable()

func _find_workbench_position():
	# Ищем верстак в сцене
	var workbench = get_tree().get_first_node_in_group("workbench")
	if workbench == null:
		# Пытаемся найти по имени
		workbench = get_node_or_null("../Workbench")
		if workbench == null:
			# Пытаемся найти в корне сцены
			workbench = get_node_or_null("/root/Main_tscn/Workbench")
	if workbench != null and workbench is Node3D:
		workbench_position = (workbench as Node3D).global_position
		print("Workbench found at: ", workbench_position)

func _spawn_nature_objects():
	if nature_scene == null:
		push_warning("Nature scene not loaded!")
		return
	
	# Загружаем сцену
	var nature_root = nature_scene.instantiate()
	if nature_root == null:
		push_warning("Failed to instantiate nature scene!")
		return
	
	# Создаем контейнеры для разных типов объектов
	var trees_container = Node3D.new()
	trees_container.name = "Trees"
	add_child(trees_container)
	
	var rocks_container = Node3D.new()
	rocks_container.name = "Rocks"
	add_child(rocks_container)
	
	var mushrooms_container = Node3D.new()
	mushrooms_container.name = "Mushrooms"
	add_child(mushrooms_container)
	
	var grass_container = Node3D.new()
	grass_container.name = "GrassPatches"
	add_child(grass_container)
	
	var structures_container = Node3D.new()
	structures_container.name = "Structures"
	add_child(structures_container)
	
	var decorations_container = Node3D.new()
	decorations_container.name = "Decorations"
	add_child(decorations_container)
	
	var effects_container = Node3D.new()
	effects_container.name = "Effects"
	add_child(effects_container)
	
	var tools_container = Node3D.new()
	tools_container.name = "Tools"
	add_child(tools_container)
	
	var other_container = Node3D.new()
	other_container.name = "Other"
	add_child(other_container)
	
	# Ищем объекты в сцене
	_find_and_place_objects(nature_root, trees_container, rocks_container, mushrooms_container, grass_container, structures_container, decorations_container, effects_container, tools_container, other_container)
	
	# Удаляем временный корневой узел
	nature_root.queue_free()

func _find_and_place_objects(root: Node, trees: Node3D, rocks: Node3D, mushrooms: Node3D, grass: Node3D, structures: Node3D, decorations: Node3D, effects: Node3D, tools: Node3D, other: Node3D):
	# Рекурсивно ищем MeshInstance3D узлы
	var all_meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, all_meshes)
	
	# Группируем объекты по типу
	var tree_meshes: Array[MeshInstance3D] = []
	var rock_meshes: Array[MeshInstance3D] = []
	var mushroom_meshes: Array[MeshInstance3D] = []
	var grass_meshes: Array[MeshInstance3D] = []
	var structure_meshes: Array[MeshInstance3D] = []
	var decoration_meshes: Array[MeshInstance3D] = []
	var effect_meshes: Array[MeshInstance3D] = []
	var tool_meshes: Array[MeshInstance3D] = []
	var other_meshes: Array[MeshInstance3D] = []
	
	# Выводим все найденные объекты для идентификации
	print("=== ВСЕ НАЙДЕННЫЕ ОБЪЕКТЫ В АССЕТЕ ===")
	var all_names: Array[String] = []
	for mesh in all_meshes:
		all_names.append(mesh.name)
	all_names.sort()
	for name in all_names:
		print("  - ", name)
	print("=======================================")
	
	# Группируем объекты по типу
	# Сначала загружаем сохраненные типы
	_load_object_types()
	
	# Загружаем маппер типов объектов
	var mapper = load("res://scripts/nature_object_mapper.gd")
	
	for mesh in all_meshes:
		# Пропускаем фоны (BG, BG2)
		var mesh_name_lower = mesh.name.to_lower()
		if "bg" in mesh_name_lower:
			continue
		
		# Сначала проверяем сохраненный тип объекта
		var saved_type = _get_saved_object_type(mesh.name)
		var object_type: int = -1
		
		if saved_type != null:
			object_type = saved_type
		else:
			# Если тип не сохранен, используем маппер на основе имени
			object_type = mapper.get_object_type_by_name(mesh.name)
		
		# Группируем по типу
		match object_type:
			0:  # TREE
				tree_meshes.append(mesh)
			1:  # ROCK
				rock_meshes.append(mesh)
			2:  # MUSHROOM
				mushroom_meshes.append(mesh)
			3:  # GRASS
				grass_meshes.append(mesh)
			5:  # STRUCTURE
				structure_meshes.append(mesh)
			6:  # DECORATION
				decoration_meshes.append(mesh)
			7:  # EFFECT
				effect_meshes.append(mesh)
			8:  # TOOL
				tool_meshes.append(mesh)
			_:  # OTHER или не определен
				other_meshes.append(mesh)
	
	# Размещаем объекты
	print("Found meshes - Trees: ", tree_meshes.size(), ", Rocks: ", rock_meshes.size(), ", Mushrooms: ", mushroom_meshes.size(), ", Grass: ", grass_meshes.size())
	print("Found meshes - Structures: ", structure_meshes.size(), ", Decorations: ", decoration_meshes.size(), ", Effects: ", effect_meshes.size(), ", Tools: ", tool_meshes.size(), ", Other: ", other_meshes.size())
	
	if tree_meshes.size() > 0:
		_place_from_collection(tree_meshes, trees, tree_count)
		print("Placed ", tree_count, " trees")
	if rock_meshes.size() > 0:
		_place_from_collection(rock_meshes, rocks, rock_count)
		print("Placed ", rock_count, " rocks")
	if mushroom_meshes.size() > 0:
		_place_from_collection(mushroom_meshes, mushrooms, mushroom_count)
		print("Placed ", mushroom_count, " mushrooms")
	if grass_meshes.size() > 0:
		_place_from_collection(grass_meshes, grass, grass_patch_count)
		print("Placed ", grass_patch_count, " grass patches")
	if structure_meshes.size() > 0:
		_place_from_collection(structure_meshes, structures, structure_count)
		print("Placed ", structure_count, " structures")
	if decoration_meshes.size() > 0:
		_place_from_collection(decoration_meshes, decorations, decoration_count)
		print("Placed ", decoration_count, " decorations")
	if effect_meshes.size() > 0:
		_place_from_collection(effect_meshes, effects, effect_count)
		print("Placed ", effect_count, " effects")
	if tool_meshes.size() > 0:
		_place_from_collection(tool_meshes, tools, tool_count)
		print("Placed ", tool_count, " tools")
	if other_meshes.size() > 0:
		_place_from_collection(other_meshes, other, other_count)
		print("Placed ", other_count, " other objects")

func _collect_meshes(node: Node, meshes: Array):
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	
	for child in node.get_children():
		_collect_meshes(child, meshes)

func _add_nature_object_script(mesh: MeshInstance3D):
	# Добавляем скрипт nature_object.gd к объекту, если его еще нет
	if mesh.get_script() == null:
		var script = load("res://scripts/nature_object.gd")
		if script:
			mesh.set_script(script)

func _place_from_collection(source_meshes: Array[MeshInstance3D], container: Node3D, count: int):
	# Определяем базовый масштаб в зависимости от типа контейнера
	var base_scale: Vector3 = Vector3.ONE
	if container.name == "Trees":
		base_scale = tree_scale
	elif container.name == "Rocks":
		base_scale = rock_scale
	elif container.name == "Mushrooms":
		base_scale = mushroom_scale
	elif container.name == "GrassPatches":
		base_scale = grass_patch_scale
	elif container.name == "Structures":
		base_scale = structure_scale
	elif container.name == "Decorations":
		base_scale = decoration_scale
	elif container.name == "Effects":
		base_scale = effect_scale
	elif container.name == "Tools":
		base_scale = tool_scale
	elif container.name == "Other":
		base_scale = other_scale
	
	# Используем сетку для более равномерного распределения
	var grid_size = ceil(sqrt(count * 2))  # Размер сетки для равномерного покрытия
	var cell_size_x = map_size.x / grid_size
	var cell_size_z = map_size.y / grid_size
	var placed_in_grid = 0
	
	# Создаем список доступных ячеек
	var available_cells: Array[Vector2i] = []
	for x in range(grid_size):
		for z in range(grid_size):
			available_cells.append(Vector2i(x, z))
	
	# Перемешиваем ячейки для случайности
	available_cells.shuffle()
	
	# Размещаем объекты в ячейках сетки
	for i in range(min(count, available_cells.size())):
		var cell = available_cells[i]
		# Центр ячейки с небольшим случайным смещением
		var cell_center_x = -map_size.x / 2.0 + (cell.x + 0.5) * cell_size_x
		var cell_center_z = -map_size.y / 2.0 + (cell.y + 0.5) * cell_size_z
		
		# Добавляем случайное смещение внутри ячейки (до 40% размера ячейки)
		var offset_x = randf_range(-cell_size_x * 0.4, cell_size_x * 0.4)
		var offset_z = randf_range(-cell_size_z * 0.4, cell_size_z * 0.4)
		
		var position = Vector3(cell_center_x + offset_x, y_position, cell_center_z + offset_z)
		
		# Проверяем расстояние от верстака
		var too_close_to_workbench = false
		if workbench_position != Vector3.ZERO:
			if position.distance_to(workbench_position) < min_distance_from_workbench:
				too_close_to_workbench = true
		
		# Если слишком близко к верстаку, пропускаем эту ячейку
		if too_close_to_workbench:
			continue
		
		# Выбираем случайный меш из коллекции
		var source_mesh = source_meshes[randi() % source_meshes.size()]
		var source_name = source_mesh.name  # Сохраняем исходное имя
		var new_mesh = source_mesh.duplicate() as MeshInstance3D
		
		# Сохраняем исходное имя в метаданных для правильного сохранения типа
		new_mesh.set_meta("source_name", source_name)
		
		new_mesh.position = position
		
		# Случайное вращение
		new_mesh.rotation.y = randf() * TAU
		
		# Применяем базовый масштаб с небольшими вариациями (0.9 - 1.1)
		var scale_variation = randf_range(0.9, 1.1)
		new_mesh.scale = base_scale * scale_variation
		
		# Добавляем скрипт для изменения типа объекта
		_add_nature_object_script(new_mesh)
		
		container.add_child(new_mesh)
		
		# Делаем объект подбираемым, если это дерево или трава
		if container.name == "Trees" or container.name == "GrassPatches":
			_make_pickable(new_mesh, container.name)
		
		placed_positions.append(position)
		placed_in_grid += 1
	
	# Если не все объекты размещены через сетку, размещаем оставшиеся случайно
	var remaining = count - placed_in_grid
	for i in range(remaining):
		var position = _get_random_position()
		if position == null:
			continue
		
		# Выбираем случайный меш из коллекции
		var source_mesh = source_meshes[randi() % source_meshes.size()]
		var source_name = source_mesh.name  # Сохраняем исходное имя
		var new_mesh = source_mesh.duplicate() as MeshInstance3D
		
		# Сохраняем исходное имя в метаданных для правильного сохранения типа
		new_mesh.set_meta("source_name", source_name)
		
		new_mesh.position = position
		new_mesh.rotation.y = randf() * TAU
		var scale_variation = randf_range(0.9, 1.1)
		new_mesh.scale = base_scale * scale_variation
		
		# Добавляем скрипт для изменения типа объекта
		_add_nature_object_script(new_mesh)
		
		container.add_child(new_mesh)
		
		# Делаем объект подбираемым, если это дерево или трава
		if container.name == "Trees" or container.name == "GrassPatches":
			_make_pickable(new_mesh, container.name)
		
		placed_positions.append(position)


func _get_random_position() -> Vector3:
	var attempts = 0
	var max_attempts = 100
	
	while attempts < max_attempts:
		var x = randf_range(-map_size.x / 2.0, map_size.x / 2.0)
		var z = randf_range(-map_size.y / 2.0, map_size.y / 2.0)
		var pos = Vector3(x, y_position, z)
		
		# Проверяем минимальное расстояние от других объектов
		var too_close = false
		for placed_pos in placed_positions:
			if pos.distance_to(placed_pos) < min_distance:
				too_close = true
				break
		
		# Проверяем расстояние от верстака
		if not too_close and workbench_position != Vector3.ZERO:
			if pos.distance_to(workbench_position) < min_distance_from_workbench:
				too_close = true
		
		if not too_close:
			return pos
		
		attempts += 1
	
	# Если не удалось найти позицию, возвращаем случайную без проверки
	var x = randf_range(-map_size.x / 2.0, map_size.x / 2.0)
	var z = randf_range(-map_size.y / 2.0, map_size.y / 2.0)
	return Vector3(x, y_position, z)

func _load_object_types():
	# Загружаем сохраненные типы объектов из файла
	var config = ConfigFile.new()
	var err = config.load("user://nature_object_types.cfg")
	if err == OK:
		var section = "object_types"
		if config.has_section(section):
			var keys = config.get_section_keys(section)
			for key in keys:
				var type = config.get_value(section, key)
				saved_object_types[key] = type

func _get_saved_object_type(object_name: String):
	# Получаем сохраненный тип объекта
	return saved_object_types.get(object_name, null)

# Делает объект подбираемым, оборачивая его в RigidBody3D если нужно
func _make_pickable(mesh_instance: MeshInstance3D, container_name: String):
	if mesh_instance == null:
		return
	
	# Определяем тип объекта и item_id
	var item_id: String = ""
	var script_path: String = ""
	
	if container_name == "Trees":
		item_id = "mu"
		script_path = "res://scripts/tree.gd"
	elif container_name == "GrassPatches":
		item_id = "cao"
		script_path = "res://scripts/grass.gd"
	else:
		return
	
	# Проверяем, не является ли уже родитель RigidBody3D
	var parent = mesh_instance.get_parent()
	if parent is RigidBody3D:
		# Если уже в RigidBody3D, просто добавляем скрипт
		var rigid_body = parent as RigidBody3D
		if rigid_body.get_script() == null:
			var script = load(script_path)
			if script:
				rigid_body.set_script(script)
				# Устанавливаем item_id после установки скрипта
				rigid_body.item_id = item_id
		return
	
	# Создаем RigidBody3D
	var rigid_body = RigidBody3D.new()
	rigid_body.name = mesh_instance.name + "_RigidBody"
	rigid_body.position = mesh_instance.position
	rigid_body.rotation = mesh_instance.rotation
	rigid_body.scale = mesh_instance.scale
	# Устанавливаем collision_layer для взаимодействия
	rigid_body.collision_layer = 1  # Слой 1 для физических объектов
	rigid_body.collision_mask = 1   # Маска для взаимодействия с другими объектами
	
	# Переносим MeshInstance3D в RigidBody3D
	parent = mesh_instance.get_parent()
	if parent:
		parent.remove_child(mesh_instance)
	
	rigid_body.add_child(mesh_instance)
	mesh_instance.position = Vector3.ZERO
	mesh_instance.rotation = Vector3.ZERO
	mesh_instance.scale = Vector3.ONE
	
	# Добавляем скрипт
	var script = load(script_path)
	if script:
		rigid_body.set_script(script)
		# Устанавливаем item_id после установки скрипта
		rigid_body.item_id = item_id
	
	# Создаем коллизию для RigidBody3D
	_create_collision_for_rigid_body(rigid_body, mesh_instance)
	
	# Добавляем RigidBody3D в контейнер
	if parent:
		parent.add_child(rigid_body)
		rigid_body.owner = parent

# Обрабатывает уже существующие объекты на сцене, делая их подбираемыми
func _make_existing_objects_pickable():
	# Ищем контейнеры Trees и GrassPatches в разных местах
	var trees_container = get_node_or_null("Trees")
	var grass_container = get_node_or_null("GrassPatches")
	
	# Если не найдены как дочерние узлы, ищем в корне сцены
	if not trees_container:
		var scene_root = get_tree().current_scene
		if scene_root:
			trees_container = scene_root.get_node_or_null("Trees")
	
	if not grass_container:
		var scene_root = get_tree().current_scene
		if scene_root:
			grass_container = scene_root.get_node_or_null("GrassPatches")
	
	# Обрабатываем деревья
	if trees_container:
		for child in trees_container.get_children():
			if child is MeshInstance3D:
				_make_pickable(child as MeshInstance3D, "Trees")
			elif child is RigidBody3D:
				# Если уже RigidBody3D, просто добавляем скрипт
				var rigid_body = child as RigidBody3D
				if rigid_body.get_script() == null:
					var script = load("res://scripts/tree.gd")
					if script:
						rigid_body.set_script(script)
						rigid_body.item_id = "mu"
				# Убеждаемся, что есть коллизия
				var mesh_instance = _find_mesh_instance_in_rigid_body(rigid_body)
				if mesh_instance:
					_create_collision_for_rigid_body(rigid_body, mesh_instance)
			# Также проверяем вложенные узлы (на случай, если структура сложнее)
			_process_children_for_pickup(child, "Trees")
	
	# Обрабатываем траву
	if grass_container:
		for child in grass_container.get_children():
			if child is MeshInstance3D:
				_make_pickable(child as MeshInstance3D, "GrassPatches")
			elif child is RigidBody3D:
				# Если уже RigidBody3D, просто добавляем скрипт
				var rigid_body = child as RigidBody3D
				if rigid_body.get_script() == null:
					var script = load("res://scripts/grass.gd")
					if script:
						rigid_body.set_script(script)
						rigid_body.item_id = "cao"
				# Убеждаемся, что есть коллизия
				var mesh_instance = _find_mesh_instance_in_rigid_body(rigid_body)
				if mesh_instance:
					_create_collision_for_rigid_body(rigid_body, mesh_instance)
			# Также проверяем вложенные узлы
			_process_children_for_pickup(child, "GrassPatches")

# Рекурсивно обрабатывает дочерние узлы для подбора
func _process_children_for_pickup(node: Node, container_name: String):
	for child in node.get_children():
		if child is MeshInstance3D:
			_make_pickable(child as MeshInstance3D, container_name)
		elif child is RigidBody3D:
			var rigid_body = child as RigidBody3D
			if rigid_body.get_script() == null:
				var script_path = "res://scripts/tree.gd" if container_name == "Trees" else "res://scripts/grass.gd"
				var item_id = "mu" if container_name == "Trees" else "cao"
				var script = load(script_path)
				if script:
					rigid_body.set_script(script)
					rigid_body.item_id = item_id
		# Рекурсивно обрабатываем вложенные узлы
		_process_children_for_pickup(child, container_name)

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

# Находит MeshInstance3D внутри RigidBody3D
func _find_mesh_instance_in_rigid_body(rigid_body: RigidBody3D) -> MeshInstance3D:
	for child in rigid_body.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
		var result = _find_mesh_instance_in_node(child)
		if result:
			return result
	return null

# Рекурсивно ищет MeshInstance3D в узле
func _find_mesh_instance_in_node(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result = _find_mesh_instance_in_node(child)
		if result:
			return result
	return null
