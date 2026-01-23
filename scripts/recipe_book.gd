# res://scripts/recipe_book.gd
# Скрипт для управления книгой рецептов

extends Control

@onready var recipes_container: VBoxContainer = $BookPanel/BookContent/ContentContainer/RecipesContent/RecipesContainer
@onready var radicals_grid: GridContainer = $BookPanel/BookContent/ContentContainer/InventoryContent/RadicalsGrid
@onready var inventory_content: ScrollContainer = $BookPanel/BookContent/ContentContainer/InventoryContent
@onready var recipes_content: ScrollContainer = $BookPanel/BookContent/ContentContainer/RecipesContent
@onready var inventory_tab_button: Button = $BookPanel/BookContent/TabButtons/InventoryTabButton
@onready var recipes_tab_button: Button = $BookPanel/BookContent/TabButtons/RecipesTabButton
@onready var close_button: Button = $CloseButton
@onready var book_panel: Panel = $BookPanel

var workbench: Node3D = null
var recipes: Array[Recipe] = []
var recipe_items: Array[Control] = []
var current_tab: String = "recipes"  # "inventory" или "recipes"

# Словарь для отслеживания открытых ингредиентов (item_id -> открыт ли)
var discovered_ingredients: Dictionary = {}

# Все доступные радикалы (из данных React компонента)
var all_radicals: Array[Dictionary] = [
	{"character": "木", "pinyin": "mù", "meaning": "дерево", "item_id": "mu"},
	{"character": "水", "pinyin": "shuǐ", "meaning": "вода", "item_id": "shui"},
	{"character": "火", "pinyin": "huǒ", "meaning": "огонь", "item_id": "huo"},
	{"character": "土", "pinyin": "tǔ", "meaning": "земля", "item_id": "tu"},
	{"character": "日", "pinyin": "rì", "meaning": "солнце", "item_id": ""},
	{"character": "月", "pinyin": "yuè", "meaning": "луна", "item_id": ""},
	{"character": "人", "pinyin": "rén", "meaning": "человек", "item_id": ""},
	{"character": "心", "pinyin": "xīn", "meaning": "сердце", "item_id": ""},
	{"character": "口", "pinyin": "kǒu", "meaning": "рот", "item_id": ""},
	{"character": "手", "pinyin": "shǒu", "meaning": "рука", "item_id": ""},
	{"character": "目", "pinyin": "mù", "meaning": "глаз", "item_id": ""},
	{"character": "田", "pinyin": "tián", "meaning": "поле", "item_id": ""},
	{"character": "山", "pinyin": "shān", "meaning": "гора", "item_id": ""},
	{"character": "石", "pinyin": "shí", "meaning": "камень", "item_id": "shi"},
	{"character": "金", "pinyin": "jīn", "meaning": "металл", "item_id": "jin"},
	{"character": "雨", "pinyin": "yǔ", "meaning": "дождь", "item_id": ""},
	{"character": "艹", "pinyin": "cǎo", "meaning": "трава", "item_id": "cao"},
	{"character": "豕", "pinyin": "shǐ", "meaning": "свинья", "item_id": "zhu"},
]

func _ready():
	# Скрываем книгу при старте
	visible = false
	
	# Подключаем кнопки вкладок
	if inventory_tab_button:
		inventory_tab_button.pressed.connect(_on_inventory_tab_pressed)
		_style_tab_button(inventory_tab_button, false)
		inventory_tab_button.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
		inventory_tab_button.add_theme_color_override("font_hover_color", Color(0.3, 0.25, 0.2))
		inventory_tab_button.add_theme_color_override("font_pressed_color", Color(0.15, 0.1, 0.05))
	if recipes_tab_button:
		recipes_tab_button.pressed.connect(_on_recipes_tab_pressed)
		_style_tab_button(recipes_tab_button, true)
		recipes_tab_button.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
		recipes_tab_button.add_theme_color_override("font_hover_color", Color(0.3, 0.25, 0.2))
		recipes_tab_button.add_theme_color_override("font_pressed_color", Color(0.15, 0.1, 0.05))
	
	# Подключаем кнопку закрытия
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
		# Применяем стиль кнопки из ассетов
		_style_close_button(close_button)
	
	# Загружаем открытые ингредиенты из GameState (если есть)
	_update_discovered_ingredients()
	
	# Показываем вкладку рецептов по умолчанию
	_switch_tab("recipes")

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
			if current_tab == "inventory":
				_update_radicals_display()
			else:
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
	
	# Обновляем отображение в зависимости от текущей вкладки
	if current_tab == "inventory":
		_update_radicals_display()
	else:
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
			
			# Также отмечаем радикал по символу, если есть соответствие
			var radical_mapper = load("res://scripts/radical_mapper.gd")
			var radical = radical_mapper.get_radical(item_id)
			if radical != "":
				discovered_ingredients[radical] = true
		
	# Также проверяем все ингредиенты из рецептов
	for recipe in recipes:
		if recipe == null:
			continue
		for item_id in recipe.cost.keys():
			# Если ингредиент есть в инвентаре, он открыт
			if GameState.inv.has(item_id) and GameState.inv[item_id] > 0:
				discovered_ingredients[item_id] = true
				
				# Также отмечаем радикал по символу
				var radical_mapper = load("res://scripts/radical_mapper.gd")
				var radical = radical_mapper.get_radical(item_id)
				if radical != "":
					discovered_ingredients[radical] = true

func _on_inventory_tab_pressed():
	_switch_tab("inventory")

func _on_recipes_tab_pressed():
	_switch_tab("recipes")

func _switch_tab(tab_name: String):
	current_tab = tab_name
	
	# Обновляем видимость контейнеров
	if inventory_content:
		inventory_content.visible = (tab_name == "inventory")
	if recipes_content:
		recipes_content.visible = (tab_name == "recipes")
	
	# Обновляем стиль кнопок
	if inventory_tab_button:
		_style_tab_button(inventory_tab_button, tab_name == "inventory")
		# Устанавливаем темный цвет текста
		inventory_tab_button.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
		inventory_tab_button.add_theme_color_override("font_hover_color", Color(0.3, 0.25, 0.2))
		inventory_tab_button.add_theme_color_override("font_pressed_color", Color(0.15, 0.1, 0.05))
	if recipes_tab_button:
		_style_tab_button(recipes_tab_button, tab_name == "recipes")
		# Устанавливаем темный цвет текста
		recipes_tab_button.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
		recipes_tab_button.add_theme_color_override("font_hover_color", Color(0.3, 0.25, 0.2))
		recipes_tab_button.add_theme_color_override("font_pressed_color", Color(0.15, 0.1, 0.05))
	
	# Обновляем содержимое
	if tab_name == "inventory":
		_update_radicals_display()
	else:
		_update_recipes_display()

func _style_tab_button(button: Button, is_active: bool):
	if is_active:
		button.modulate = Color(1, 1, 1, 1)
		# Используем активный стиль
		var active_style = StyleBoxFlat.new()
		active_style.bg_color = Color(0.95, 0.9, 0.7, 1)  # Светло-желтый
		active_style.border_color = Color(0.8, 0.6, 0.3, 1)  # Коричневый
		active_style.border_width_left = 2
		active_style.border_width_top = 2
		active_style.border_width_right = 2
		active_style.border_width_bottom = 2
		active_style.corner_radius_top_left = 8
		active_style.corner_radius_top_right = 8
		button.add_theme_stylebox_override("normal", active_style)
	else:
		button.modulate = Color(0.7, 0.7, 0.7, 0.8)
		# Используем неактивный стиль
		var inactive_style = StyleBoxFlat.new()
		inactive_style.bg_color = Color(0.9, 0.85, 0.75, 0.5)  # Полупрозрачный
		inactive_style.border_color = Color(0.6, 0.5, 0.4, 0.5)
		inactive_style.border_width_left = 1
		inactive_style.border_width_top = 1
		inactive_style.border_width_right = 1
		inactive_style.border_width_bottom = 1
		inactive_style.corner_radius_top_left = 8
		inactive_style.corner_radius_top_right = 8
		button.add_theme_stylebox_override("normal", inactive_style)

func _update_radicals_display():
	# Очищаем сетку
	for child in radicals_grid.get_children():
		child.queue_free()
	
	# Подсчитываем собранные радикалы
	var collected_count = 0
	for radical_data in all_radicals:
		var item_id = radical_data.get("item_id", "")
		var character = radical_data.get("character", "")
		var is_collected = false
		
		if item_id != "":
			if GameState and GameState.inv.has(item_id) and GameState.inv[item_id] > 0:
				is_collected = true
		elif discovered_ingredients.has(character):
			is_collected = true
		
		if is_collected:
			collected_count += 1
	
	# Обновляем текст кнопки вкладки
	if inventory_tab_button:
		inventory_tab_button.text = "📦 Собранные радикалы (%d/%d)" % [collected_count, all_radicals.size()]
	
	# Создаем элементы для каждого радикала
	for radical_data in all_radicals:
		var radical_item = _create_radical_item(radical_data)
		radicals_grid.add_child(radical_item)

func _create_radical_item(radical_data: Dictionary) -> Control:
	var radical_panel = Panel.new()
	radical_panel.custom_minimum_size = Vector2(120, 140)
	
	# Проверяем, собран ли радикал
	var is_collected = false
	var item_id = radical_data.get("item_id", "")
	var character = radical_data.get("character", "")
	
	if item_id != "":
		if GameState and GameState.inv.has(item_id) and GameState.inv[item_id] > 0:
			is_collected = true
	if not is_collected and discovered_ingredients.has(character):
		is_collected = true
	
	# Стиль панели в зависимости от того, собран ли радикал
	var panel_style = StyleBoxFlat.new()
	if is_collected:
		panel_style.bg_color = Color(1, 1, 1, 1)
		panel_style.border_color = Color(0.8, 0.6, 0.3, 1)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.corner_radius_top_left = 8
		panel_style.corner_radius_top_right = 8
		panel_style.corner_radius_bottom_left = 8
		panel_style.corner_radius_bottom_right = 8
	else:
		panel_style.bg_color = Color(0.8, 0.8, 0.8, 0.5)
		panel_style.border_color = Color(0.5, 0.5, 0.5, 0.6)
		panel_style.border_width_left = 1
		panel_style.border_width_top = 1
		panel_style.border_width_right = 1
		panel_style.border_width_bottom = 1
		panel_style.corner_radius_top_left = 8
		panel_style.corner_radius_top_right = 8
		panel_style.corner_radius_bottom_left = 8
		panel_style.corner_radius_bottom_right = 8
	radical_panel.add_theme_stylebox_override("panel", panel_style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	radical_panel.add_child(vbox)
	
	# Иконка замка для не собранных
	if not is_collected:
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 20)
		vbox.add_child(lock_label)
	
	# Радикал (иероглиф)
	var radical_label = Label.new()
	radical_label.text = radical_data.character
	radical_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	radical_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	radical_label.custom_minimum_size = Vector2(80, 60)
	# Загружаем китайский шрифт
	var font_path = "res://assets/font/Ma_Shan_Zheng/MaShanZheng-Regular.ttf"
	var font_file = load(font_path) as FontFile
	if font_file:
		radical_label.add_theme_font_override("font", font_file)
	radical_label.add_theme_font_size_override("font_size", 36)
	if not is_collected:
		radical_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		radical_label.modulate = Color(1, 1, 1, 0.6)
	else:
		radical_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	vbox.add_child(radical_label)
	
	# Пиньинь
	var pinyin_label = Label.new()
	pinyin_label.text = radical_data.pinyin
	pinyin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pinyin_label.add_theme_font_size_override("font_size", 11)
	if not is_collected:
		pinyin_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	else:
		pinyin_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	vbox.add_child(pinyin_label)
	
	# Значение
	var meaning_label = Label.new()
	meaning_label.text = radical_data.meaning
	meaning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meaning_label.add_theme_font_size_override("font_size", 12)
	if not is_collected:
		meaning_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	else:
		meaning_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	vbox.add_child(meaning_label)
	
	# Галочка для собранных
	if is_collected:
		var check_label = Label.new()
		check_label.text = "✓"
		check_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		check_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		check_label.custom_minimum_size = Vector2(20, 20)
		check_label.add_theme_font_size_override("font_size", 16)
		check_label.modulate = Color(0.2, 0.8, 0.2)
		check_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		check_label.offset_left = -24
		check_label.offset_top = 4
		radical_panel.add_child(check_label)
	
	return radical_panel

func _update_recipes_display():
	# Очищаем контейнер
	for child in recipes_container.get_children():
		child.queue_free()
	recipe_items.clear()
	
	if recipes.is_empty():
		var no_recipes_label = Label.new()
		no_recipes_label.text = "Нет доступных рецептов"
		no_recipes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_recipes_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		recipes_container.add_child(no_recipes_label)
		return
	
	# Разделяем рецепты на доступные и заблокированные
	var available_recipes: Array[Recipe] = []
	var locked_recipes: Array[Recipe] = []
	
	for recipe in recipes:
		if recipe == null:
			continue
		
		var can_craft = true
		var all_ingredients_discovered = true
		
		# Проверяем, можем ли скрафтить и все ли ингредиенты открыты
		for item_id in recipe.cost.keys():
			var required = recipe.cost[item_id]
			var available = GameState.inv.get(item_id, 0) if GameState else 0
			var is_discovered = discovered_ingredients.get(item_id, false)
			
			if available < required:
				can_craft = false
			if not is_discovered:
				all_ingredients_discovered = false
		
		if can_craft and all_ingredients_discovered:
			available_recipes.append(recipe)
		else:
			locked_recipes.append(recipe)
	
	# Обновляем текст кнопки вкладки
	if recipes_tab_button:
		recipes_tab_button.text = "✨ Рецепты (%d/%d)" % [available_recipes.size(), recipes.size()]
	
	# Отображаем доступные рецепты
	if available_recipes.size() > 0:
		var available_header = Label.new()
		available_header.text = "🎯 Доступные рецепты (%d)" % available_recipes.size()
		available_header.add_theme_font_size_override("font_size", 22)  # Увеличенный размер
		available_header.add_theme_color_override("font_color", Color(0.0, 0.7, 0.0))  # Более яркий зеленый
		available_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		available_header.add_theme_constant_override("outline_size", 4)  # Обводка для читаемости
		available_header.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
		recipes_container.add_child(available_header)
		
		# Создаем GridContainer для доступных рецептов
		var available_grid = GridContainer.new()
		available_grid.columns = 1  # Один столбец для лучшей читаемости
		available_grid.add_theme_constant_override("h_separation", 20)
		available_grid.add_theme_constant_override("v_separation", 20)  # Увеличенные отступы
		recipes_container.add_child(available_grid)
		
		for recipe in available_recipes:
			var recipe_item = _create_recipe_item(recipe, false)
			available_grid.add_child(recipe_item)
			recipe_items.append(recipe_item)
	
	# Отображаем заблокированные рецепты
	if locked_recipes.size() > 0:
		var locked_header = Label.new()
		locked_header.text = "🔒 Заблокированные рецепты (%d)" % locked_recipes.size()
		locked_header.add_theme_font_size_override("font_size", 22)  # Увеличенный размер
		locked_header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		locked_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		locked_header.add_theme_constant_override("outline_size", 4)  # Обводка для читаемости
		locked_header.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.8))
		recipes_container.add_child(locked_header)
		
		# Создаем GridContainer для заблокированных рецептов
		var locked_grid = GridContainer.new()
		locked_grid.columns = 1  # Один столбец для лучшей читаемости
		locked_grid.add_theme_constant_override("h_separation", 20)
		locked_grid.add_theme_constant_override("v_separation", 20)  # Увеличенные отступы
		recipes_container.add_child(locked_grid)
		
		for recipe in locked_recipes:
			var recipe_item = _create_recipe_item(recipe, true)
			locked_grid.add_child(recipe_item)
			recipe_items.append(recipe_item)
	
	if available_recipes.size() == 0 and locked_recipes.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Собирайте радикалы, чтобы открыть рецепты!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		recipes_container.add_child(empty_label)

func _create_recipe_item(recipe: Recipe, is_locked: bool = false) -> Control:
	# Создаем контейнер для рецепта с использованием ассетов книги
	var recipe_panel = Panel.new()
	recipe_panel.custom_minimum_size = Vector2(420, 220)  # Увеличенный размер для лучшей читаемости
	
	# Стиль панели в зависимости от блокировки
	var panel_style = StyleBoxFlat.new()
	if is_locked:
		panel_style.bg_color = Color(0.8, 0.8, 0.8, 0.5)
		panel_style.border_color = Color(0.5, 0.5, 0.5, 0.7)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.corner_radius_top_left = 8
		panel_style.corner_radius_top_right = 8
		panel_style.corner_radius_bottom_left = 8
		panel_style.corner_radius_bottom_right = 8
		recipe_panel.modulate = Color(1, 1, 1, 0.7)
	else:
		panel_style.bg_color = Color(1, 0.98, 0.9, 1)  # Светло-желтый
		panel_style.border_color = Color(0.8, 0.6, 0.3, 1)  # Коричневый
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.corner_radius_top_left = 8
		panel_style.corner_radius_top_right = 8
		panel_style.corner_radius_bottom_left = 8
		panel_style.corner_radius_bottom_right = 8
	recipe_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Иконка замка для заблокированных
	if is_locked:
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lock_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lock_label.custom_minimum_size = Vector2(20, 20)
		lock_label.add_theme_font_size_override("font_size", 16)
		lock_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		lock_label.offset_left = -24
		lock_label.offset_top = 4
		recipe_panel.add_child(lock_label)
	
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
	vbox.offset_left = 16
	vbox.offset_top = 16
	vbox.offset_right = -16
	vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 12)  # Увеличенные отступы
	recipe_panel.add_child(vbox)
	
	# Контейнер для формулы крафта (ингредиент1 + ингредиент2 = результат)
	var formula_container = HBoxContainer.new()
	formula_container.add_theme_constant_override("separation", 20)  # Увеличенное расстояние между элементами
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
			plus_label.add_theme_font_size_override("font_size", 28)  # Увеличенный размер
			plus_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.3))  # Более контрастный цвет
			plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			plus_label.custom_minimum_size = Vector2(35, 35)
			formula_container.add_child(plus_label)
		
		if available < required:
			can_craft = false
		
		if not is_discovered:
			all_ingredients_discovered = false
	
	# Добавляем знак "=" перед результатом
	if not recipe.cost.is_empty():
		var equals_label = Label.new()
		equals_label.text = "="
		equals_label.add_theme_font_size_override("font_size", 28)  # Увеличенный размер
		equals_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.3))  # Более контрастный цвет
		equals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equals_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		equals_label.custom_minimum_size = Vector2(35, 35)
		formula_container.add_child(equals_label)
		
		# Показываем результат только если все ингредиенты собраны и открыты
		if all_ingredients_discovered:
			var result_item = _create_result_item(recipe)
			formula_container.add_child(result_item)
		else:
			# Показываем "?" если не все ингредиенты открыты
			var unknown_result = _create_unknown_result()
			formula_container.add_child(unknown_result)
	
	# Информация о результате (если доступна)
	if all_ingredients_discovered and not is_locked:
		var result_info = HSeparator.new()
		vbox.add_child(result_info)
		
		var result_name_label = Label.new()
		result_name_label.text = recipe.name
		result_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_name_label.add_theme_font_size_override("font_size", 14)  # Увеличенный размер
		result_name_label.add_theme_color_override("font_color", Color(0.5, 0.3, 0.1))  # Более темный цвет для лучшей читаемости
		vbox.add_child(result_name_label)
	
	# Кнопка крафта (только если не заблокирован и все ингредиенты собраны)
	if not is_locked and can_craft and not recipe.cost.is_empty():
		var craft_button = _create_animated_button("✨ Скрафтить", _on_craft_button_pressed.bind(recipe))
		craft_button.custom_minimum_size = Vector2(160, 40)  # Увеличенная кнопка
		craft_button.add_theme_font_size_override("font_size", 16)  # Увеличенный шрифт
		craft_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Центрируем кнопку
		vbox.add_child(craft_button)
	elif not is_locked:
		var status_label = Label.new()
		if recipe.cost.is_empty():
			status_label.text = "Рецепт не требует ингредиентов"
		else:
			status_label.text = "❌ Недостаточно ингредиентов"  # Добавили иконку
		status_label.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3))  # Красноватый цвет для предупреждения
		status_label.add_theme_font_size_override("font_size", 13)  # Увеличенный размер
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(status_label)
	
	return recipe_panel

func _create_ingredient_item(item_id: String, required: int, available: int, is_discovered: bool) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(75, 100)  # Увеличенный размер
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 6)  # Увеличенные отступы
	
	# Используем слот из ассетов для фона
	var slot_panel = Panel.new()
	slot_panel.custom_minimum_size = Vector2(65, 65)  # Увеличенный размер слота
	
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
	icon_label.custom_minimum_size = Vector2(60, 60)  # Увеличенный размер иконки
	slot_panel.add_child(icon_label)
	
	if is_discovered:
		# Показываем радикал или название
		var radical_mapper = load("res://scripts/radical_mapper.gd")
		var radical = radical_mapper.get_radical(item_id)
		if radical != "":
			icon_label.text = radical
			icon_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
			# Загружаем китайский шрифт
			var font_path = "res://assets/font/Ma_Shan_Zheng/MaShanZheng-Regular.ttf"
			var font_file = load(font_path) as FontFile
			if font_file:
				icon_label.add_theme_font_override("font", font_file)
			icon_label.add_theme_font_size_override("font_size", 32)  # Увеличенный размер иероглифа
		else:
			icon_label.text = item_id
			icon_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
			icon_label.add_theme_font_size_override("font_size", 14)
	else:
		# Показываем знак вопроса
		icon_label.text = "?"
		icon_label.add_theme_font_size_override("font_size", 32)  # Увеличенный размер
		icon_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))  # Более заметный серый
		slot_panel.modulate = Color(0.8, 0.8, 0.8, 0.6)  # Затемняем слот для неоткрытых
	
	# Количество
	var count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 13)  # Увеличенный размер
	if is_discovered:
		count_label.text = "%d/%d" % [available, required]
		if available >= required:
			count_label.add_theme_color_override("font_color", Color(0.0, 0.8, 0.0))  # Яркий зеленый
			# Добавляем визуальную подсказку - зеленую рамку поверх слота
			var success_frame = Panel.new()
			success_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			success_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
			var success_style = StyleBoxFlat.new()
			success_style.bg_color = Color(0.0, 0.8, 0.0, 0.0)  # Прозрачный фон
			success_style.border_color = Color(0.0, 0.8, 0.0, 0.9)  # Зеленая рамка
			success_style.border_width_left = 3
			success_style.border_width_top = 3
			success_style.border_width_right = 3
			success_style.border_width_bottom = 3
			success_style.corner_radius_top_left = 4
			success_style.corner_radius_top_right = 4
			success_style.corner_radius_bottom_left = 4
			success_style.corner_radius_bottom_right = 4
			success_frame.add_theme_stylebox_override("panel", success_style)
			slot_panel.add_child(success_frame)
		else:
			count_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))  # Яркий красный
			# Добавляем визуальную подсказку - красную рамку поверх слота
			var warning_frame = Panel.new()
			warning_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			warning_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
			var warning_style = StyleBoxFlat.new()
			warning_style.bg_color = Color(0.9, 0.2, 0.2, 0.0)  # Прозрачный фон
			warning_style.border_color = Color(0.9, 0.2, 0.2, 0.9)  # Красная рамка
			warning_style.border_width_left = 3
			warning_style.border_width_top = 3
			warning_style.border_width_right = 3
			warning_style.border_width_bottom = 3
			warning_style.corner_radius_top_left = 4
			warning_style.corner_radius_top_right = 4
			warning_style.corner_radius_bottom_left = 4
			warning_style.corner_radius_bottom_right = 4
			warning_frame.add_theme_stylebox_override("panel", warning_style)
			slot_panel.add_child(warning_frame)
	else:
		count_label.text = "?/?"
		count_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	
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
		result_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		# Загружаем китайский шрифт
		var font_path = "res://assets/font/Ma_Shan_Zheng/MaShanZheng-Regular.ttf"
		var font_file = load(font_path) as FontFile
		if font_file:
			result_label.add_theme_font_override("font", font_file)
		result_label.add_theme_font_size_override("font_size", 28)
	else:
		result_label.text = recipe.name.substr(0, 1)  # Первая буква названия
		result_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		result_label.add_theme_font_size_override("font_size", 24)
	
	slot_panel.add_child(result_label)
	
	# Название результата под слотом
	var name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
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
	question_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	slot_panel.add_child(question_label)
	
	# Текст под слотом
	var text_label = Label.new()
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 11)
	text_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	text_label.text = "?"
	container.add_child(text_label)
	
	return container

func _create_animated_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	# Устанавливаем темный цвет текста для кнопки
	button.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	button.add_theme_color_override("font_hover_color", Color(0.2, 0.2, 0.2))
	button.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.05))
	
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
