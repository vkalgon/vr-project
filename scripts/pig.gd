# res://scripts/pig.gd
# Скрипт для свиньи, делает её подбираемой
extends RigidBody3D

@export var item_id: String = "zhu"  # @export нужен для доступа через get()

func _ready():
	# Убеждаемся, что item_id установлен
	if item_id == "":
		item_id = "zhu"
	
	# Устанавливаем item_id как метаданные для доступа через get_meta()
	set_meta("item_id", item_id)
	
	# Добавляем в группу pickup (если еще не добавлен)
	if not is_in_group("pickup"):
		add_to_group("pickup")
	
	# Убеждаемся, что свойство доступно (для @export свойств get() должен работать)
	# Но на всякий случай устанавливаем и метаданные
	
	# Замораживаем физику, чтобы свинья не падала
	freeze = true
	
	# Создаем коллизию, если её еще нет
	_create_collision()
	
	# Добавляем подсветку при приближении
	_add_highlight()
	
	# Отладочный вывод
	print("Pig _ready: item_id=", item_id, " in_group=", is_in_group("pickup"), " has_meta=", has_meta("item_id"), " get()=", get("item_id"))

func _create_collision():
	# Проверяем, есть ли уже CollisionShape3D
	for child in get_children():
		if child is CollisionShape3D:
			return
	
	# Ищем MeshInstance3D для создания коллизии
	var mesh_instance = _find_mesh_instance(self)
	if mesh_instance == null:
		return
	
	# Получаем AABB меша
	var aabb = mesh_instance.get_aabb()
	if aabb.size == Vector3.ZERO:
		return
	
	# Создаем CollisionShape3D с BoxShape3D
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	
	# Создаем BoxShape3D на основе AABB
	var box_shape = BoxShape3D.new()
	box_shape.size = aabb.size
	collision_shape.shape = box_shape
	
	# Позиционируем коллизию относительно центра меша
	collision_shape.position = aabb.get_center()
	
	add_child(collision_shape)

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
