# res://scripts/tree.gd
extends RigidBody3D
@export var item_id := "mu"
@export var tree_scale: float = 100.0  # Масштаб дерева

func _ready():
	add_to_group("pickup") # помечаем, что это подбираемый предмет
	
	# Замораживаем физику, чтобы дерево не падало
	freeze = true
	
	# Применяем масштаб к дереву (увеличиваем, так как они маленькие)
	scale = Vector3(tree_scale, tree_scale, tree_scale)
	
	# Создаем коллизию, если её еще нет
	_create_collision()
	
	# Добавляем подсветку при приближении
	_add_highlight()

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

