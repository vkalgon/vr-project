# res://scripts/nature_object_mapper.gd
# Скрипт для маппинга объектов природы по их именам

extends RefCounted

# Маппинг имен объектов на типы (на основе материалов из .mtl файла)
# Типы: 0 = TREE, 1 = ROCK, 2 = MUSHROOM, 3 = GRASS, 4 = OTHER
static var object_type_map: Dictionary = {
	# Деревья (Trees)
	"Tree1": 0, "Tree1_1": 0, "Tree1_2": 0,
	"Tree2": 0, "Tree2_1": 0, "Tree2_2": 0, "Tree2_3": 0,
	"Tree3": 0, "Tree3_1": 0, "Tree3_2": 0,
	"Tree4": 0, "Tree4_1": 0, "Tree4_2": 0,
	"Tree5": 0, "Tree5_1": 0, "Tree5_2": 0, "Tree5_3": 0,
	"Tree6": 0, "Tree6_1": 0, "Tree6_2": 0,
	
	# Пни (Stumps) - относим к деревьям
	"Stump1_1": 0, "Stump1_2": 0,
	
	# Ветки (Branches) - относим к деревьям
	"Branch1_1": 0, "Branch1_2": 0,
	
	# Грибы (Mushrooms)
	"Mushroom1": 2, "Mushroom1_1": 2, "Mushroom1_2": 2,
	"Mushroom2": 2, "Mushroom2_1": 2, "Mushroom2_2": 2, "Mushroom2-2": 2,
	"Mushroom3": 2, "Mushroom3_1": 2, "Mushroom3_2": 2,
	"Mushroom4": 2, "Mushroom4_1": 2, "Mushroom4_2": 2,
	"Mushroom5": 2, "Mushroom5_1": 2, "Mushroom5_2": 2,
	
	# Камни (Rocks)
	"Rock1": 1, "Rock1_1": 1,
	"BigRock1": 1, "BigRock1_1": 1,
	
	# Трава и растения (Grass/Plants)
	"Grass1": 3, "Grass1_1": 3, "Grass1_2": 3,
	"Reeds1": 3, "Reeds1_1": 3, "Reeds1_2": 3,
	"Hedge": 3,
	"Bush1_1": 3,
	
	# Цветы (Flowers) - относим к траве/растениям
	"Flower1_1": 3, "Flower1_2": 3, "Flower1_3": 3, "Flower1_4": 3,
	"Flower2_1": 3, "Flower2_2": 3, "Flower2_3": 3, "Flower2_4": 3, "Flower2-2": 3,
	"Flower3_1": 3, "Flower3_2": 3, "Flower3_3": 3,
	
	# Строения (Structures)
	"House1_1": 5, "House1_2": 5, "House1_3": 5, "House1_4": 5, "House1_5": 5, "House1_6": 5, "House1_7": 5,
	"Fence1_1": 5, "Fence2_1": 5, "Fence2_2": 5,
	"Bridge1_1": 5, "Bridge1_2": 5,
	"Ruins1_1": 5, "Ruins1_2": 5,
	
	# Декор (Decorations)
	"Lantern1_1": 6, "Lantern1_2": 6, "Lantern1_3": 6,
	"Crystal1_1": 6, "Crystal1_2": 6,
	"Gravestone1": 6, "Gravwstone1_2": 6,
	"Pointer1_1": 6, "Pointer1_2": 6,
	"Tile1_1": 6,
	
	# Эффекты (Effects)
	"Fire1_1": 7, "Fire1_2": 7, "Fire1_3": 7, "Fire1_4": 7,
	
	# Инструменты (Tools)
	"Ax1_1": 8, "Ax1_2": 8,
	
	# Животные (Animals) - относим к OTHER
	"Pig": 4,
}

# Получить тип объекта по его имени
static func get_object_type_by_name(object_name: String) -> int:
	# Очищаем имя от суффиксов Godot
	var clean_name = object_name.replace("@", "").split("(")[0].strip_edges()
	
	# Проверяем точное совпадение
	if object_type_map.has(clean_name):
		return object_type_map[clean_name]
	
	# Проверяем частичное совпадение
	for key in object_type_map.keys():
		if clean_name.contains(key) or key.contains(clean_name):
			return object_type_map[key]
	
	# Проверяем по ключевым словам
	var lower_name = clean_name.to_lower()
	if "tree" in lower_name or "stump" in lower_name or "branch" in lower_name:
		return 0  # TREE
	elif "rock" in lower_name or "stone" in lower_name:
		return 1  # ROCK
	elif "mushroom" in lower_name:
		return 2  # MUSHROOM
	elif "grass" in lower_name or "reed" in lower_name or "hedge" in lower_name or "bush" in lower_name or "flower" in lower_name:
		return 3  # GRASS
	elif "house" in lower_name or "fence" in lower_name or "bridge" in lower_name or "ruin" in lower_name:
		return 5  # STRUCTURE
	elif "lantern" in lower_name or "crystal" in lower_name or "grave" in lower_name or "pointer" in lower_name or "tile" in lower_name:
		return 6  # DECORATION
	elif "fire" in lower_name:
		return 7  # EFFECT
	elif "ax" in lower_name or "tool" in lower_name:
		return 8  # TOOL
	elif "pig" in lower_name:
		return 4  # OTHER (животные)
	
	return 4  # OTHER

