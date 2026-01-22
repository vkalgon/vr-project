# res://scripts/radical_mapper.gd
# Маппинг item_id к китайским радикалам

extends RefCounted

# Маппинг item_id к радикалам
static var item_to_radical: Dictionary = {
	"cao": "艹",  # Трава (grass radical)
	"mu": "木",   # Дерево (tree radical)
	"shi": "石",  # Камень (stone radical)
	"jin": "金",  # Металл (metal radical)
	"shui": "水", # Вода (water radical)
	"huo": "火",  # Огонь (fire radical)
	"tu": "土",   # Земля (earth radical)
}

# Получить радикал по item_id
static func get_radical(item_id: String) -> String:
	if item_to_radical.has(item_id):
		return item_to_radical[item_id]
	# Если радикал не найден, возвращаем пустую строку
	return ""

# Получить item_id по типу объекта природы
static func get_item_id_from_nature_type(nature_type: int) -> String:
	match nature_type:
		0:  # TREE
			return "mu"
		1:  # ROCK
			return "shi"
		2:  # MUSHROOM
			return "cao"  # Грибы относим к траве
		3:  # GRASS
			return "cao"
		7:  # EFFECT (Fire)
			return "huo"
		_:
			return ""

