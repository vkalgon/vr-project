extends Node3D
@export var use_zone: Area3D
@export var recipes: Array[Recipe] = []   # список рецептов
@export var interaction_distance: float = 2.0  # максимальное расстояние для взаимодействия

func _ready():
	add_to_group("workbench")  # Добавляем в группу для поиска
	if not use_zone: use_zone = $UseZone
	# Подключаем сигналы зоны для отслеживания входа/выхода
	if use_zone:
		use_zone.body_entered.connect(_on_body_entered)
		use_zone.body_exited.connect(_on_body_exited)

func _input(event):
	if event.is_action_pressed("interact"):
		if _player_in_zone():
			# Открываем книгу рецептов вместо автоматического крафта
			_open_recipe_book()

func _on_body_entered(body: Node3D):
	# Можно добавить визуальную индикацию, что игрок в зоне
	pass

func _on_body_exited(body: Node3D):
	# Можно убрать визуальную индикацию
	pass

func _player_in_zone() -> bool:
	if use_zone == null:
		return false

	# берём активную камеру (твою DesktopCamera)
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false

	# Проверяем, находится ли камера в зоне через overlapping bodies/areas
	# Но так как камера не является телом, используем проверку расстояния
	var shape_node: Node = use_zone.get_node_or_null("CollisionShape3D")
	if shape_node == null or not shape_node is CollisionShape3D:
		# Если нет формы коллизии, используем простое расстояние
		return cam.global_position.distance_to(use_zone.global_position) <= interaction_distance
	
	# Приводим к нужному типу для доступа к global_transform
	var collision_shape: CollisionShape3D = shape_node as CollisionShape3D
	
	# Получаем глобальную трансформацию зоны и формы
	var zone_transform := use_zone.global_transform
	var shape_transform := collision_shape.global_transform
	
	# Вычисляем расстояние от камеры до центра зоны
	var zone_center := zone_transform.origin
	var distance := cam.global_position.distance_to(zone_center)
	
	# Определяем размер зоны
	var zone_size := Vector3(1.0, 1.0, 1.0)
	if collision_shape.shape is BoxShape3D:
		var box_shape: BoxShape3D = collision_shape.shape
		zone_size = box_shape.size
		# Учитываем масштаб трансформации
		zone_size *= shape_transform.basis.get_scale()
		# Используем максимальный размер для проверки
		var max_radius: float = max(zone_size.x, zone_size.z) * 0.5
		return distance <= max_radius + 0.5  # добавляем небольшой запас
	elif collision_shape.shape is SphereShape3D:
		var sphere_shape: SphereShape3D = collision_shape.shape
		var radius := sphere_shape.radius
		# Учитываем масштаб
		radius *= shape_transform.basis.get_scale().length()
		return distance <= radius + 0.5
	
	# Если форма неизвестного типа, используем простое расстояние
	return distance <= interaction_distance


func _try_craft():
	# Проверяем, что GameState доступен
	if not GameState:
		_show_message("Ошибка: GameState не найден", false)
		print("ERROR: GameState is null!")
		return
	
	if recipes.is_empty():
		_show_message("Нет доступных рецептов", false)
		return
	
	var first_recipe_missing: Array[String] = []
	var first_recipe_name: String = ""
	
	# Отладочная информация
	print("=== CRAFT ATTEMPT ===")
	print("GameState.inv: ", GameState.inv)
	print("Recipes count: ", recipes.size())
	
	# Проверяем каждый рецепт по очереди
	for recipe in recipes:
		if recipe == null:
			continue
		
		# Проверяем, есть ли все необходимые ингредиенты
		var missing_items: Array[String] = []
		var can_craft: bool = true
		
		# Если рецепт не требует ингредиентов, пропускаем его
		if recipe.cost.is_empty():
			continue
		
		print("Checking recipe: ", recipe.name, " cost: ", recipe.cost)
		
		for item_id in recipe.cost.keys():
			var required: int = recipe.cost[item_id]
			var available: int = GameState.inv.get(item_id, 0)
			
			print("  Item: ", item_id, " required: ", required, " available: ", available)
			
			if available < required:
				can_craft = false
				missing_items.append("%s (нужно: %d, есть: %d)" % [item_id, required, available])
		
		# Если все ингредиенты есть, создаем предмет
		if can_craft:
			print("Can craft! Paying cost: ", recipe.cost)
			if GameState.pay(recipe.cost):
				print("Cost paid successfully. New inv: ", GameState.inv)
				# Воспроизводим звук успешного крафта
				if AudioManager:
					AudioManager.play_craft_success()
				_spawn(recipe)
				var success_msg: String = "Скрафчено: %s" % recipe.name
				if recipe.glyph_hint != "":
					success_msg += " (%s)" % recipe.glyph_hint
				_show_message(success_msg, true)
				return
			else:
				print("ERROR: Failed to pay cost!")
		
		# Сохраняем информацию о первом рецепте для сообщения об ошибке
		if first_recipe_name == "":
			first_recipe_name = recipe.name
			first_recipe_missing = missing_items
	
	# Если дошли сюда, значит ни один рецепт не подошел
	# Показываем детальное сообщение об ошибке для первого рецепта
	if first_recipe_missing.size() > 0:
		var error_msg: String = "Недостаточно ингредиентов для '%s':\n" % first_recipe_name
		error_msg += "\n".join(first_recipe_missing)
		# Воспроизводим звук ошибки крафта
		if AudioManager:
			AudioManager.play_craft_fail()
		_show_message(error_msg, false)
	else:
		# Воспроизводим звук ошибки крафта
		if AudioManager:
			AudioManager.play_craft_fail()
		_show_message("Недостаточно ресурсов для любого рецепта", false)

func _spawn(r: Recipe):
	if r.out_scene:
		var p := r.out_scene.instantiate()
		get_tree().current_scene.add_child(p)
		p.global_transform.origin = global_transform.origin + Vector3(0, 1.1, 0)

func _show_message(text: String, is_success: bool):
	# Ищем HUD в сцене для отображения сообщения
	var hud = get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("show_craft_message"):
		hud.show_craft_message(text, is_success)
	else:
		# Если HUD не найден, выводим в консоль
		print(text)

func _open_recipe_book():
	# Ищем книгу рецептов в сцене
	var recipe_book = get_tree().get_first_node_in_group("recipe_book")
	if recipe_book == null:
		# Пытаемся найти в HUD
		var hud = get_tree().get_first_node_in_group("game_hud")
		if hud:
			recipe_book = hud.get_node_or_null("RecipeBook")
	
	# Если книга не найдена, создаем её
	if recipe_book == null:
		var recipe_book_scene = load("res://scenes/RecipeBook.tscn")
		if recipe_book_scene:
			recipe_book = recipe_book_scene.instantiate()
			recipe_book.add_to_group("recipe_book")
			# Добавляем в корень сцены или в HUD
			var hud = get_tree().get_first_node_in_group("game_hud")
			if hud:
				hud.add_child(recipe_book)
			else:
				get_tree().current_scene.add_child(recipe_book)
	
	# Открываем книгу
	if recipe_book and recipe_book.has_method("open_book"):
		recipe_book.open_book(self)
