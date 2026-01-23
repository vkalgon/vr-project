# res://scripts/pig.gd
# Скрипт для свиньи, делает её подбираемой
extends RigidBody3D

@export var item_id: String = "zhu"  # @export нужен для доступа через get()

func _ready():
	# Убеждаемся, что item_id установлен (как в grass.gd)
	if item_id == "":
		item_id = "zhu"
	
	# Устанавливаем item_id как метаданные для доступа через get_meta()
	set_meta("item_id", item_id)
	
	# Добавляем в группу pickup (точно так же, как в grass.gd)
	add_to_group("pickup")
	
	# Замораживаем физику, чтобы свинья не падала (как в grass.gd)
	freeze = true
	
	# Создаем коллизию отложенно, чтобы меш успел загрузиться
	# Но если коллизия уже создана в pig_spawner, пропускаем
	call_deferred("_create_collision")
	
	# Добавляем подсветку при приближении
	_add_highlight()
	
	# Отладочный вывод
	print("Pig _ready: item_id=", item_id, " in_group=", is_in_group("pickup"), " has_meta=", has_meta("item_id"), " collision_layer=", collision_layer, " collision_mask=", collision_mask)

func _create_collision():
	# Проверяем, есть ли уже CollisionShape3D
	for child in get_children():
		if child is CollisionShape3D:
			print("Pig: CollisionShape3D already exists")
			return
	
	# Ищем MeshInstance3D для создания коллизии
	var mesh_instance = _find_mesh_instance(self)
	if mesh_instance == null:
		print("Pig: No MeshInstance3D found, creating default collision")
		# Если меш не найден, создаем простую коллизию по умолчанию (больше, чем для травы)
		var collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(2.0, 2.0, 2.0)  # Больший размер для свиньи
		collision_shape.shape = box_shape
		add_child(collision_shape)
		print("Pig: Created default collision with size ", box_shape.size)
		return
	
	# Получаем AABB меша (в локальных координатах меша)
	var aabb = mesh_instance.get_aabb()
	if aabb.size == Vector3.ZERO:
		print("Pig: AABB size is zero, creating default collision")
		var collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(2.0, 2.0, 2.0)  # Больший размер для свиньи
		collision_shape.shape = box_shape
		add_child(collision_shape)
		return
	
	# Создаем CollisionShape3D с BoxShape3D (упрощенная версия, как у дерева)
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	
	# Создаем BoxShape3D на основе AABB (используем простой подход, как у дерева)
	var box_shape = BoxShape3D.new()
	box_shape.size = aabb.size
	collision_shape.shape = box_shape
	
	# Позиционируем коллизию относительно центра меша (в локальных координатах RigidBody3D)
	# Преобразуем локальную позицию центра AABB меша в локальные координаты RigidBody3D
	var mesh_local_center = aabb.get_center()
	var mesh_global_center = mesh_instance.to_global(mesh_local_center)
	collision_shape.position = to_local(mesh_global_center)
	
	add_child(collision_shape)
	print("Pig: Created collision with size ", box_shape.size, " at position ", collision_shape.position, " aabb=", aabb)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null

func _add_highlight():
	# Добавляем узел с скриптом подсветки
	var highlight_script = load("res://scripts/pickup_highlight.gd")
	if highlight_script:
		var highlight_node = Node.new()
		highlight_node.set_script(highlight_script)
		highlight_node.name = "PickupHighlight"
		add_child(highlight_node)
