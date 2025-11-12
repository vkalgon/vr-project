# res://scripts/reference_objects.gd
# Скрипт для размещения по одному объекту каждого типа на сцене для настройки размеров
@tool
extends Node3D

@export var create_reference_objects: bool = false:
	set(value):
		create_reference_objects = value
		if value and Engine.is_editor_hint():
			_create_reference_objects()

func _ready():
	if not Engine.is_editor_hint():
		return
	# В редакторе создаем объекты автоматически
	_create_reference_objects()

func _create_reference_objects():
	# Получаем родительский узел (Main_tscn)
	var parent_scene = get_parent()
	
	# Загружаем маппер для определения типов
	var mapper = load("res://scripts/nature_object_mapper.gd")
	
	# Путь к папке со сценами объектов
	var scenes_dir = "res://scenes/nature_objects/"
	
	# Сканируем папку со сценами
	var dir = DirAccess.open("res://")
	if dir == null:
		push_error("Failed to open res:// directory")
		return
	
	# Проверяем существование папки
	if not dir.dir_exists("scenes/nature_objects"):
		push_error("Directory not found: " + scenes_dir)
		push_error("Please run 'Project -> Tools -> Create Nature Object Scenes' first")
		return
	
	# Открываем папку со сценами
	dir = DirAccess.open(scenes_dir)
	if dir == null:
		push_error("Failed to open directory: " + scenes_dir)
		return
	
	# Группируем сцены по типам
	var type_scenes: Dictionary = {}  # type -> Array[String] (пути к сценам)
	
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
	
	# Размещаем по одному объекту каждого типа
	var x_offset = 0.0
	var z_offset = 0.0
	var spacing = 5.0  # Расстояние между объектами
	
	for type in range(9):  # 0-8 типы объектов
		if not type_scenes.has(type) or type_scenes[type].is_empty():
			continue
		
		# Проверяем, не существует ли уже такой объект
		var type_name = _get_type_name(type)
		var existing = parent_scene.get_node_or_null(type_name + "_Reference")
		if existing != null:
			continue  # Пропускаем, если уже существует
		
		# Загружаем первую сцену этого типа
		var scene_path = type_scenes[type][0]
		var scene = load(scene_path) as PackedScene
		if scene == null:
			push_warning("Failed to load scene: " + scene_path)
			continue
		
		# Инстанцируем сцену
		var instance = scene.instantiate()
		if instance == null:
			push_warning("Failed to instantiate scene: " + scene_path)
			continue
		
		# Устанавливаем позицию
		instance.position = Vector3(x_offset, 0.0, z_offset)
		
		# Устанавливаем имя для удобства
		instance.name = type_name + "_Reference"
		
		# Добавляем объект в родительскую сцену (как верстак)
		parent_scene.add_child(instance)
		instance.owner = parent_scene.owner if parent_scene.owner else parent_scene
		
		# Переходим к следующей позиции
		x_offset += spacing
		if x_offset > spacing * 4:  # После 5 объектов переходим на новую строку
			x_offset = 0.0
			z_offset += spacing
	
	print("Reference objects created in scene for size adjustment")

func _get_type_name(type: int) -> String:
	match type:
		0: return "Tree"
		1: return "Rock"
		2: return "Mushroom"
		3: return "Grass"
		5: return "Structure"
		6: return "Decoration"
		7: return "Effect"
		8: return "Tool"
		_: return "Other"

