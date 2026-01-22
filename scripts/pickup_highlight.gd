# res://scripts/pickup_highlight.gd
# Скрипт для подсветки объектов, которые можно подобрать

extends Node

@export var highlight_distance: float = 3.0  # Расстояние, на котором объект начинает подсвечиваться
@export var highlight_color: Color = Color(1.0, 1.0, 0.7, 1.0)  # Цвет подсветки (теплый желтоватый)
@export var highlight_intensity: float = 1.2  # Интенсивность подсветки (рассеянный свет)

var parent_node: Node3D = null
var player: Node3D = null
var original_materials: Array[StandardMaterial3D] = []
var mesh_instances: Array[MeshInstance3D] = []
var is_highlighted: bool = false

func _ready():
	# Получаем родительский узел (должен быть RigidBody3D или Node3D)
	parent_node = get_parent() as Node3D
	if parent_node == null:
		push_error("pickup_highlight.gd: Parent must be Node3D or RigidBody3D")
		return
	
	# Находим все MeshInstance3D в дереве узлов
	_find_mesh_instances(parent_node)
	
	# Сохраняем оригинальные материалы
	_save_original_materials()
	
	# Ищем игрока (камеру) в сцене
	_find_player()

func _find_mesh_instances(node: Node):
	if node is MeshInstance3D:
		mesh_instances.append(node as MeshInstance3D)
	
	for child in node.get_children():
		_find_mesh_instances(child)

func _save_original_materials():
	original_materials.clear()
	for mesh_instance in mesh_instances:
		var material: StandardMaterial3D = null
		
		# Проверяем material_override
		if mesh_instance.material_override:
			material = mesh_instance.material_override.duplicate() as StandardMaterial3D
		# Проверяем surface_override_material
		elif mesh_instance.get_surface_override_material(0):
			material = mesh_instance.get_surface_override_material(0).duplicate() as StandardMaterial3D
		# Если материала нет, создаем новый базовый
		else:
			material = StandardMaterial3D.new()
			# Пытаемся получить базовые свойства из меша
			if mesh_instance.mesh and mesh_instance.mesh.surface_get_material(0):
				var base_material = mesh_instance.mesh.surface_get_material(0)
				if base_material is StandardMaterial3D:
					material = base_material.duplicate() as StandardMaterial3D
		
		original_materials.append(material)

func _find_player():
	# Ищем камеру игрока
	var cameras = get_tree().get_nodes_in_group("player")
	if cameras.size() > 0:
		player = cameras[0] as Node3D
	
	# Если не нашли, ищем камеру напрямую
	if player == null:
		var camera = get_tree().get_first_node_in_group("camera")
		if camera:
			player = camera as Node3D
	
	# Если все еще не нашли, ищем Camera3D в сцене
	if player == null:
		var camera = get_viewport().get_camera_3d()
		if camera:
			player = camera as Node3D
	
	# Если все еще не нашли, ищем по имени
	if player == null:
		var camera = get_tree().current_scene.get_node_or_null("Camera3D")
		if camera:
			player = camera as Node3D

func _process(_delta):
	if parent_node == null or player == null:
		return
	
	# Вычисляем расстояние до игрока
	var distance = parent_node.global_position.distance_to(player.global_position)
	
	# Проверяем, нужно ли подсвечивать
	var should_highlight = distance <= highlight_distance
	
	if should_highlight != is_highlighted:
		is_highlighted = should_highlight
		if is_highlighted:
			_apply_highlight()
		else:
			_remove_highlight()

func _apply_highlight():
	# Применяем подсветку ко всем мешам
	for i in range(mesh_instances.size()):
		var mesh_instance = mesh_instances[i]
		if mesh_instance == null:
			continue
		
		# Создаем материал с подсветкой
		var highlight_material: StandardMaterial3D
		
		# Используем оригинальный материал, если есть
		if i < original_materials.size() and original_materials[i] != null:
			highlight_material = original_materials[i].duplicate() as StandardMaterial3D
		else:
			highlight_material = StandardMaterial3D.new()
			# Если материала не было, пытаемся получить из меша
			if mesh_instance.mesh and mesh_instance.mesh.surface_get_material(0):
				var base_material = mesh_instance.mesh.surface_get_material(0)
				if base_material is StandardMaterial3D:
					highlight_material = base_material.duplicate() as StandardMaterial3D
		
		# Включаем эмиссию с рассеянным светом
		highlight_material.emission_enabled = true
		
		# Используем альбедо материала как основу для эмиссии
		var base_color = highlight_material.albedo_color
		if base_color == Color.BLACK or base_color == Color.WHITE:
			# Если цвет слишком нейтральный, используем цвет подсветки как основу
			base_color = highlight_color
		
		# Смешиваем с цветом подсветки для рассеянного эффекта
		var emission_color = base_color.lerp(highlight_color, 0.5)
		# Увеличиваем яркость для рассеянного света
		emission_color = emission_color * highlight_intensity
		highlight_material.emission = emission_color
		highlight_material.emission_energy_multiplier = highlight_intensity
		
		# Добавляем легкое изменение альбедо для более заметного рассеянного эффекта
		var original_albedo = highlight_material.albedo_color
		highlight_material.albedo_color = original_albedo.lerp(highlight_color, 0.2)
		
		# Применяем материал
		mesh_instance.material_override = highlight_material

func _remove_highlight():
	# Возвращаем оригинальные материалы
	for i in range(mesh_instances.size()):
		var mesh_instance = mesh_instances[i]
		if mesh_instance == null:
			continue
		
		if i < original_materials.size() and original_materials[i] != null:
			mesh_instance.material_override = original_materials[i]
		else:
			mesh_instance.material_override = null

