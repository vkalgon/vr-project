# res://scripts/trees_container.gd
# Скрипт для контейнера деревьев, который автоматически делает все дочерние объекты подбираемыми

extends Node3D

func _ready():
	# Обрабатываем все дочерние объекты
	print("TreesContainer: Processing ", get_child_count(), " children")
	_process_children(self)
	print("TreesContainer: Finished processing")
	
	# Подключаемся к сигналу добавления дочерних элементов
	child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(node: Node):
	# Обрабатываем новый дочерний элемент
	print("TreesContainer: New child added: ", node.name, " (type: ", node.get_class(), ")")
	if node is MeshInstance3D:
		_make_tree_pickable(node as MeshInstance3D)
	elif node is RigidBody3D:
		_ensure_tree_script(node as RigidBody3D)
	else:
		# Рекурсивно обрабатываем вложенные узлы
		_process_children(node)

func _process_children(node: Node):
	for child in node.get_children():
		# Пропускаем уже обработанные RigidBody3D с скриптом tree.gd
		if child is RigidBody3D:
			var script = child.get_script()
			if script and script.resource_path.ends_with("tree.gd"):
				print("TreesContainer: Skipping already processed RigidBody3D: ", child.name)
				continue
		
		if child is MeshInstance3D:
			print("TreesContainer: Found MeshInstance3D: ", child.name)
			_make_tree_pickable(child as MeshInstance3D)
		elif child is RigidBody3D:
			print("TreesContainer: Found RigidBody3D: ", child.name)
			_ensure_tree_script(child as RigidBody3D)
		else:
			print("TreesContainer: Found other node: ", child.name, " (type: ", child.get_class(), ")")
		# Рекурсивно обрабатываем вложенные узлы
		_process_children(child)

func _make_tree_pickable(mesh_instance: MeshInstance3D):
	if mesh_instance == null:
		return
	
	# Проверяем, не является ли уже родитель RigidBody3D
	var parent = mesh_instance.get_parent()
	if parent is RigidBody3D:
		print("TreesContainer: MeshInstance3D already has RigidBody3D parent")
		_ensure_tree_script(parent as RigidBody3D)
		return
	
	# Ищем масштаб в метаданных перед созданием RigidBody3D
	var scale_value = _find_tree_scale_in_meta(mesh_instance)
	print("TreesContainer: Found tree_scale: ", scale_value, " for mesh: ", mesh_instance.name)
	
	# Создаем RigidBody3D
	var rigid_body = RigidBody3D.new()
	rigid_body.name = mesh_instance.name + "_RigidBody"
	rigid_body.position = mesh_instance.position
	rigid_body.rotation = mesh_instance.rotation
	
	# Масштаб будет применен в tree.gd в _ready()
	# Здесь просто копируем масштаб с родителя для начального значения
	var mesh_parent = mesh_instance.get_parent()
	if mesh_parent and mesh_parent is Node3D:
		rigid_body.scale = (mesh_parent as Node3D).scale
	else:
		rigid_body.scale = mesh_instance.scale
	
	rigid_body.collision_layer = 1
	rigid_body.collision_mask = 1
	
	# Переносим MeshInstance3D в RigidBody3D
	parent = mesh_instance.get_parent()
	if parent:
		parent.remove_child(mesh_instance)
	
	rigid_body.add_child(mesh_instance)
	mesh_instance.position = Vector3.ZERO
	mesh_instance.rotation = Vector3.ZERO
	mesh_instance.scale = Vector3.ONE
	
	# Добавляем скрипт
	var tree_script = load("res://scripts/tree.gd")
	if tree_script:
		rigid_body.set_script(tree_script)
		rigid_body.item_id = "mu"
		# Используем найденный масштаб (уже найден выше)
		if scale_value > 0:
			rigid_body.tree_scale = scale_value
			print("TreesContainer: Set tree_scale to ", scale_value, " on RigidBody3D")
	
	# Создаем коллизию
	_create_collision(rigid_body, mesh_instance)
	
	# Добавляем RigidBody3D в контейнер
	if parent:
		parent.add_child(rigid_body)
		rigid_body.owner = parent

func _ensure_tree_script(rigid_body: RigidBody3D):
	if rigid_body == null:
		return
	
	# Проверяем, есть ли уже скрипт
	if rigid_body.get_script() == null:
		var tree_script = load("res://scripts/tree.gd")
		if tree_script:
			rigid_body.set_script(tree_script)
			rigid_body.item_id = "mu"
	
	# Убеждаемся, что есть коллизия
	var has_collision = false
	for child in rigid_body.get_children():
		if child is CollisionShape3D:
			has_collision = true
			break
	
	if not has_collision:
		var mesh_instance = _find_mesh_instance(rigid_body)
		if mesh_instance:
			_create_collision(rigid_body, mesh_instance)

func _create_collision(rigid_body: RigidBody3D, mesh_instance: MeshInstance3D):
	if rigid_body == null or mesh_instance == null:
		return
	
	# Получаем AABB меша
	var aabb = mesh_instance.get_aabb()
	if aabb.size == Vector3.ZERO:
		# Если AABB пустой, создаем простую коллизию
		aabb = AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 2, 1))
	
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

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null

func _find_tree_scale_in_meta(node: Node) -> float:
	# Ищем метаданные tree_scale, поднимаясь вверх по дереву узлов
	var current = node
	while current != null:
		if current.has_meta("tree_scale"):
			return current.get_meta("tree_scale") as float
		current = current.get_parent()
	return 0.0

