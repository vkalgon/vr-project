# res://scripts/nature_object.gd
extends MeshInstance3D

# Типы объектов
enum ObjectType {
	TREE,        # Деревья, пни, ветки
	ROCK,        # Камни
	MUSHROOM,    # Грибы
	GRASS,       # Трава, растения, цветы
	STRUCTURE,   # Дома, заборы, мосты, руины
	DECORATION,  # Фонари, кристаллы, надгробия, указатели
	EFFECT,      # Огонь
	TOOL,        # Инструменты (топор и т.д.)
	OTHER        # Остальное
}

# Текущий тип объекта
@export var object_type: ObjectType = ObjectType.OTHER

# Уникальный ID объекта (для сохранения)
var object_id: String = ""

# Группа для поиска объектов природы
const NATURE_GROUP = "nature_object"

func _ready():
	add_to_group(NATURE_GROUP)
	# Создаем уникальный ID на основе имени и позиции
	if object_id == "":
		object_id = _generate_id()
	# Загружаем сохраненный тип
	_load_type()

func _generate_id() -> String:
	# Генерируем уникальный ID на основе имени исходного меша и позиции
	var base_name = name
	# Убираем номера из имени (если есть) для получения исходного имени
	var clean_name = base_name.replace("@", "").split("(")[0].strip_edges()
	return clean_name + "_" + str(hash(global_position))

func set_object_type(new_type: ObjectType):
	object_type = new_type
	_save_type()

func get_object_type() -> ObjectType:
	return object_type

func get_type_name() -> String:
	match object_type:
		ObjectType.TREE:
			return "Дерево"
		ObjectType.ROCK:
			return "Камень"
		ObjectType.MUSHROOM:
			return "Гриб"
		ObjectType.GRASS:
			return "Трава"
		ObjectType.STRUCTURE:
			return "Строение"
		ObjectType.DECORATION:
			return "Декор"
		ObjectType.EFFECT:
			return "Эффект"
		ObjectType.TOOL:
			return "Инструмент"
		_:
			return "Другое"

func _save_type():
	# Сохраняем тип объекта в ConfigFile
	var config = ConfigFile.new()
	var err = config.load("user://nature_object_types.cfg")
	if err != OK:
		config = ConfigFile.new()
	
	# Получаем исходное имя меша из метаданных или используем текущее имя
	var base_name = get_meta("source_name", name)
	# Убираем номера и специальные символы для получения чистого имени
	base_name = base_name.replace("@", "").split("(")[0].strip_edges()
	
	config.set_value("object_types", base_name, object_type)
	config.save("user://nature_object_types.cfg")
	print("Сохранен тип для ", base_name, ": ", object_type, " (", get_type_name(), ")")

func _load_type():
	# Загружаем сохраненный тип объекта по исходному имени
	var config = ConfigFile.new()
	var err = config.load("user://nature_object_types.cfg")
	if err == OK:
		# Получаем исходное имя меша из метаданных или используем текущее имя
		var base_name = get_meta("source_name", name)
		base_name = base_name.replace("@", "").split("(")[0].strip_edges()
		
		var saved_type = config.get_value("object_types", base_name, null)
		if saved_type != null:
			object_type = saved_type as ObjectType
			print("Загружен тип для ", base_name, ": ", object_type, " (", get_type_name(), ")")

