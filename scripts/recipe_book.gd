# res://scripts/recipe_book.gd
# Скрипт для управления книгой рецептов

extends Control

@onready var recipes_container: VBoxContainer = $BookPanel/BookContent/ScrollContainer/RecipesContainer
@onready var close_button: Button = $CloseButton
@onready var book_panel: Panel = $BookPanel

var workbench: Node3D = null
var recipes: Array[Recipe] = []
var recipe_items: Array[Control] = []

# Словарь для отслеживания открытых ингредиентов (item_id -> открыт ли)
var discovered_ingredients: Dictionary = {}

func _ready():
	# Скрываем книгу при старте
	visible = false
	
	# Подключаем кнопку закрытия
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
		# Применяем стиль кнопки из ассетов
		_style_close_button(close_button)
	
	# Загружаем открытые ингредиенты из GameState (если есть)
	_update_discovered_ingredients()

func _style_close_button(button: Button):
	# Используем иконку крестика из ассетов
	var cross_icon = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_IconCross01a.png")
	if cross_icon:
		# Создаем TextureRect для иконки
		var icon_rect = TextureRect.new()
		icon_rect.texture = cross_icon
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(20, 20)
		button.add_child(icon_rect)
		button.text = ""  # Убираем текст, используем иконку
	
	# Используем текстуры кнопок из ассетов
	var button_frame_1 = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites Animated/UI_TravelBook_Button01a_1.png")
	var button_frame_3 = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites Animated/UI_TravelBook_Button01a_3.png")
	var button_frame_5 = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites Animated/UI_TravelBook_Button01a_5.png")
	
	if button_frame_1:
		var normal_style = StyleBoxTexture.new()
		normal_style.texture = button_frame_1
		normal_style.texture_margin_left = 8
		normal_style.texture_margin_top = 8
		normal_style.texture_margin_right = 8
		normal_style.texture_margin_bottom = 8
		button.add_theme_stylebox_override("normal", normal_style)
	
	if button_frame_3:
		var pressed_style = StyleBoxTexture.new()
		pressed_style.texture = button_frame_3
		pressed_style.texture_margin_left = 8
		pressed_style.texture_margin_top = 8
		pressed_style.texture_margin_right = 8
		pressed_style.texture_margin_bottom = 8
		button.add_theme_stylebox_override("pressed", pressed_style)
	
	if button_frame_5:
		var hover_style = StyleBoxTexture.new()
		hover_style.texture = button_frame_5
		hover_style.texture_margin_left = 8
		hover_style.texture_margin_top = 8
		hover_style.texture_margin_right = 8
		hover_style.texture_margin_bottom = 8
		button.add_theme_stylebox_override("hover", hover_style)

func _process(_delta):
	# Обновляем отображение рецептов, если книга видна
	if visible:
		# Проверяем, изменился ли инвентарь
		var old_discovered = discovered_ingredients.duplicate()
		_update_discovered_ingredients()
		
		# Если список открытых ингредиентов изменился, обновляем отображение
		if old_discovered.hash() != discovered_ingredients.hash():
			_update_recipes_display()

func _input(event):
	# Закрываем книгу по Escape
	if event.is_action_pressed("ui_cancel") and visible:
		close_book()
		get_viewport().set_input_as_handled()

func open_book(workbench_node: Node3D):
	workbench = workbench_node
	if workbench and "recipes" in workbench:
		recipes = workbench.recipes
	else:
		recipes = []
	
	# Освобождаем мышь для взаимодействия с UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Обновляем открытые ингредиенты
	_update_discovered_ingredients()
	
	# Показываем книгу с анимацией
	visible = true
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.8, 0.8)
	
	# Обновляем отображение рецептов сразу
	_update_recipes_display()
	
	# Анимация появления
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Воспроизводим звук открытия книги
	if AudioManager:
		var book_open_sound = load("res://assets/400 Sounds Pack/Items/book_open.wav")
		if book_open_sound:
			AudioManager.play_sfx(book_open_sound)

func close_book():
	# Анимация закрытия
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2).set_ease(Tween.EASE_IN)
	
	await tween.finished
	visible = false
	
	# Возвращаем захват мыши для управления камерой
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Воспроизводим звук закрытия книги
	if AudioManager:
		var book_close_sound = load("res://assets/400 Sounds Pack/Items/book_close.wav")
		if book_close_sound:
			AudioManager.play_sfx(book_close_sound)

func _on_close_button_pressed():
	close_book()

func _update_discovered_ingredients():
	# Обновляем список открытых ингредиентов на основе инвентаря
	if not GameState:
		return
	
	# Если ингредиент есть в инвентаре и количество > 0, значит он открыт
	for item_id in GameState.inv.keys():
		if GameState.inv[item_id] > 0:
			discovered_ingredients[item_id] = true
		
	# Также проверяем все ингредиенты из рецептов
	for recipe in recipes:
		if recipe == null:
			continue
		for item_id in recipe.cost.keys():
			# Если ингредиент есть в инвентаре, он открыт
			if GameState.inv.has(item_id) and GameState.inv[item_id] > 0:
				discovered_ingredients[item_id] = true

func _update_recipes_display():
	# Очищаем контейнер
	for child in recipes_container.get_children():
		child.queue_free()
	recipe_items.clear()
	
	if recipes.is_empty():
		var no_recipes_label = Label.new()
		no_recipes_label.text = "Нет доступных рецептов"
		no_recipes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recipes_container.add_child(no_recipes_label)
		return
	
	# Создаем элементы для каждого рецепта
	for recipe in recipes:
		if recipe == null:
			continue
		
		var recipe_item = _create_recipe_item(recipe)
		recipes_container.add_child(recipe_item)
		recipe_items.append(recipe_item)

func _create_recipe_item(recipe: Recipe) -> Control:
	# Создаем контейнер для рецепта с использованием ассетов книги
	var recipe_panel = Panel.new()
	recipe_panel.custom_minimum_size = Vector2(800, 120)  # Широкий для формулы
	
	# Используем текстуру фрейма из ассетов
	var frame_texture = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Frame01a.png")
	if frame_texture:
		var style_box = StyleBoxTexture.new()
		style_box.texture = frame_texture
		style_box.texture_margin_left = 14
		style_box.texture_margin_top = 14
		style_box.texture_margin_right = 14
		style_box.texture_margin_bottom = 14
		recipe_panel.add_theme_stylebox_override("panel", style_box)
	
	# Добавляем легкий фон для рецепта
	var fill_texture = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Fill01a.png")
	if fill_texture:
		var fill_rect = TextureRect.new()
		fill_rect.texture = fill_texture
		fill_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		fill_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fill_rect.modulate = Color(1, 1, 1, 0.3)  # Полупрозрачный фон
		fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		# Добавляем первым, чтобы был на заднем плане
		recipe_panel.add_child(fill_rect)
		recipe_panel.move_child(fill_rect, 0)  # Перемещаем на первую позицию (задний план)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 18
	vbox.offset_top = 18
	vbox.offset_right = -18
	vbox.offset_bottom = -18
	vbox.add_theme_constant_override("separation", 10)
	recipe_panel.add_child(vbox)
	
	# Контейнер для формулы крафта (ингредиент1 + ингредиент2 = результат)
	var formula_container = HBoxContainer.new()
	formula_container.add_theme_constant_override("separation", 15)
	formula_container.alignment = BoxContainer.ALIGNMENT_CENTER
	formula_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(formula_container)
	
	# Отображаем ингредиенты в виде формулы
	var can_craft = true
	var all_ingredients_discovered = true
	var ingredient_keys = recipe.cost.keys()
	
	for i in range(ingredient_keys.size()):
		var item_id = ingredient_keys[i]
		var required = recipe.cost[item_id]
		var available = GameState.inv.get(item_id, 0) if GameState else 0
		var is_discovered = discovered_ingredients.get(item_id, false)
		
		# Создаем элемент ингредиента
		var ingredient_item = _create_ingredient_item(item_id, required, available, is_discovered)
		formula_container.add_child(ingredient_item)
		
		# Добавляем знак "+" между ингредиентами (кроме последнего)
		if i < ingredient_keys.size() - 1:
			var plus_label = Label.new()
			plus_label.text = "+"
			plus_label.add_theme_font_size_override("font_size", 24)
			plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			plus_label.custom_minimum_size = Vector2(30, 30)
			formula_container.add_child(plus_label)
		
		if available < required:
			can_craft = false
		
		if not is_discovered:
			all_ingredients_discovered = false
	
	# Добавляем знак "=" перед результатом
	if not recipe.cost.is_empty():
		var equals_label = Label.new()
		equals_label.text = "="
		equals_label.add_theme_font_size_override("font_size", 24)
		equals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equals_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		equals_label.custom_minimum_size = Vector2(30, 30)
		formula_container.add_child(equals_label)
		
		# Показываем результат только если все ингредиенты собраны и открыты
		if all_ingredients_discovered:
			var result_item = _create_result_item(recipe)
			formula_container.add_child(result_item)
		else:
			# Показываем "?" если не все ингредиенты открыты
			var unknown_result = _create_unknown_result()
			formula_container.add_child(unknown_result)
	
	# Кнопка крафта (только если все ингредиенты собраны)
	if can_craft and not recipe.cost.is_empty():
		var craft_button = _create_animated_button("Скрафтить", _on_craft_button_pressed.bind(recipe))
		craft_button.custom_minimum_size = Vector2(120, 35)
		craft_button.add_theme_font_size_override("font_size", 14)
		vbox.add_child(craft_button)
	else:
		var status_label = Label.new()
		if recipe.cost.is_empty():
			status_label.text = "Рецепт не требует ингредиентов"
		else:
			status_label.text = "Недостаточно ингредиентов"
		status_label.modulate = Color(0.6, 0.6, 0.6)
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(status_label)
	
	return recipe_panel

func _create_ingredient_item(item_id: String, required: int, available: int, is_discovered: bool) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(60, 85)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 4)
	
	# Используем слот из ассетов для фона
	var slot_panel = Panel.new()
	slot_panel.custom_minimum_size = Vector2(55, 55)
	
	var slot_texture = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Slot01a.png")
	if slot_texture:
		var slot_style = StyleBoxTexture.new()
		slot_style.texture = slot_texture
		slot_style.texture_margin_left = 6
		slot_style.texture_margin_top = 6
		slot_style.texture_margin_right = 6
		slot_style.texture_margin_bottom = 6
		slot_panel.add_theme_stylebox_override("panel", slot_style)
	
	container.add_child(slot_panel)
	
	# Иконка или знак вопроса
	var icon_label = Label.new()
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(50, 50)
	slot_panel.add_child(icon_label)
	
	if is_discovered:
		# Показываем радикал или название
		var radical_mapper = load("res://scripts/radical_mapper.gd")
		var radical = radical_mapper.get_radical(item_id)
		if radical != "":
			icon_label.text = radical
			# Загружаем китайский шрифт
			var font_path = "res://assets/font/Ma_Shan_Zheng/MaShanZheng-Regular.ttf"
			var font_file = load(font_path) as FontFile
			if font_file:
				icon_label.add_theme_font_override("font", font_file)
			icon_label.add_theme_font_size_override("font_size", 28)
		else:
			icon_label.text = item_id
	else:
		# Показываем знак вопроса
		icon_label.text = "?"
		icon_label.add_theme_font_size_override("font_size", 28)
		icon_label.modulate = Color(0.5, 0.5, 0.5)
	
	# Количество
	var count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 11)
	if is_discovered:
		count_label.text = "%d/%d" % [available, required]
		if available >= required:
			count_label.modulate = Color(0.2, 0.8, 0.2)  # Зеленый
		else:
			count_label.modulate = Color(0.9, 0.3, 0.3)  # Красный
	else:
		count_label.text = "?/?"
		count_label.modulate = Color(0.5, 0.5, 0.5)
	
	container.add_child(count_label)
	
	return container

func _create_result_item(recipe: Recipe) -> Control:
	# Создаем элемент результата крафта
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(60, 85)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 4)
	
	# Используем слот из ассетов для фона (другой цвет для результата)
	var slot_panel = Panel.new()
	slot_panel.custom_minimum_size = Vector2(55, 55)
	
	var slot_texture = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Slot01c.png")  # Используем другой слот для результата
	if not slot_texture:
		slot_texture = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Slot01b.png")
	if not slot_texture:
		slot_texture = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Slot01a.png")
	
	if slot_texture:
		var slot_style = StyleBoxTexture.new()
		slot_style.texture = slot_texture
		slot_style.texture_margin_left = 6
		slot_style.texture_margin_top = 6
		slot_style.texture_margin_right = 6
		slot_style.texture_margin_bottom = 6
		slot_panel.add_theme_stylebox_override("panel", slot_style)
	
	container.add_child(slot_panel)
	
	# Показываем иероглиф или первую букву названия
	var result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.custom_minimum_size = Vector2(50, 50)
	
	# Если есть подсказка с иероглифом, показываем её
	if recipe.glyph_hint != "":
		result_label.text = recipe.glyph_hint
		# Загружаем китайский шрифт
		var font_path = "res://assets/font/Ma_Shan_Zheng/MaShanZheng-Regular.ttf"
		var font_file = load(font_path) as FontFile
		if font_file:
			result_label.add_theme_font_override("font", font_file)
		result_label.add_theme_font_size_override("font_size", 28)
	else:
		result_label.text = recipe.name.substr(0, 1)  # Первая буква названия
		result_label.add_theme_font_size_override("font_size", 24)
	
	slot_panel.add_child(result_label)
	
	# Название результата под слотом
	var name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.text = recipe.name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(name_label)
	
	return container

func _create_unknown_result() -> Control:
	# Создаем элемент с "?" для неизвестного результата
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(60, 85)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 4)
	
	# Используем слот из ассетов для фона
	var slot_panel = Panel.new()
	slot_panel.custom_minimum_size = Vector2(55, 55)
	
	var slot_texture = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites/UI_TravelBook_Slot01a.png")
	if slot_texture:
		var slot_style = StyleBoxTexture.new()
		slot_style.texture = slot_texture
		slot_style.texture_margin_left = 6
		slot_style.texture_margin_top = 6
		slot_style.texture_margin_right = 6
		slot_style.texture_margin_bottom = 6
		slot_panel.add_theme_stylebox_override("panel", slot_style)
	
	container.add_child(slot_panel)
	
	# Показываем знак вопроса
	var question_label = Label.new()
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.custom_minimum_size = Vector2(50, 50)
	question_label.text = "?"
	question_label.add_theme_font_size_override("font_size", 28)
	question_label.modulate = Color(0.5, 0.5, 0.5)
	slot_panel.add_child(question_label)
	
	# Текст под слотом
	var text_label = Label.new()
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 11)
	text_label.text = "?"
	text_label.modulate = Color(0.5, 0.5, 0.5)
	container.add_child(text_label)
	
	return container

func _create_animated_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	
	# Используем анимированные кнопки из ассетов
	var button_frame_1 = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites Animated/UI_TravelBook_Button01a_1.png")
	var button_frame_2 = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites Animated/UI_TravelBook_Button01a_2.png")
	var button_frame_3 = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites Animated/UI_TravelBook_Button01a_3.png")
	var button_frame_4 = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites Animated/UI_TravelBook_Button01a_4.png")
	var button_frame_5 = load("res://assets/Complete_UI_Book_Styles_Pack_Free_v1.0/01_TravelBookLite/Sprites Animated/UI_TravelBook_Button01a_5.png")
	
	# Используем первый кадр для normal состояния
	if button_frame_1:
		var normal_style = StyleBoxTexture.new()
		normal_style.texture = button_frame_1
		normal_style.texture_margin_left = 8
		normal_style.texture_margin_top = 8
		normal_style.texture_margin_right = 8
		normal_style.texture_margin_bottom = 8
		button.add_theme_stylebox_override("normal", normal_style)
	
	# Используем средний кадр для pressed состояния
	if button_frame_3:
		var pressed_style = StyleBoxTexture.new()
		pressed_style.texture = button_frame_3
		pressed_style.texture_margin_left = 8
		pressed_style.texture_margin_top = 8
		pressed_style.texture_margin_right = 8
		pressed_style.texture_margin_bottom = 8
		button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Используем последний кадр для hover состояния
	if button_frame_5:
		var hover_style = StyleBoxTexture.new()
		hover_style.texture = button_frame_5
		hover_style.texture_margin_left = 8
		hover_style.texture_margin_top = 8
		hover_style.texture_margin_right = 8
		hover_style.texture_margin_bottom = 8
		button.add_theme_stylebox_override("hover", hover_style)
	
	# Подключаем callback
	button.pressed.connect(callback)
	
	return button

func _on_craft_button_pressed(recipe: Recipe):
	if not workbench or not GameState:
		return
	
	# Проверяем, можем ли скрафтить
	if not GameState.can_pay(recipe.cost):
		# Показываем сообщение об ошибке
		var hud = get_tree().get_first_node_in_group("game_hud")
		if hud and hud.has_method("show_craft_message"):
			hud.show_craft_message("Недостаточно ингредиентов", false)
		return
	
	# Платим стоимость
	if GameState.pay(recipe.cost):
		# Вызываем крафт через верстак
		if workbench.has_method("_spawn"):
			workbench._spawn(recipe)
		
		# Воспроизводим звук успешного крафта
		if AudioManager:
			AudioManager.play_craft_success()
		
		# Показываем сообщение об успехе
		var hud = get_tree().get_first_node_in_group("game_hud")
		if hud and hud.has_method("show_craft_message"):
			var success_msg = "Скрафчено: %s" % recipe.name
			if recipe.glyph_hint != "":
				success_msg += " (%s)" % recipe.glyph_hint
			hud.show_craft_message(success_msg, true)
		
		# Обновляем отображение рецептов
		_update_recipes_display()
	else:
		# Показываем сообщение об ошибке
		var hud = get_tree().get_first_node_in_group("game_hud")
		if hud and hud.has_method("show_craft_message"):
			hud.show_craft_message("Ошибка при крафте", false)
