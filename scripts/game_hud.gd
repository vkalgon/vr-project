extends Control

@onready var inventory_items: VBoxContainer = $InventoryPanel/VBoxContainer/InventoryItems
@onready var hint_label: Label = $HintLabel
@onready var craft_message_label: Label = $CraftMessageLabel
@onready var radical_display: Control = $RadicalDisplay
@onready var radical_label: Label = $RadicalDisplay/RadicalLabel

var item_labels: Dictionary = {}
var message_timer: Timer = null
var radical_timer: Timer = null

func _ready():
	# Добавляем в группу для поиска
	add_to_group("game_hud")
	
	# Создаем таймер для автоматического скрытия сообщений
	message_timer = Timer.new()
	message_timer.wait_time = 3.0
	message_timer.one_shot = true
	message_timer.timeout.connect(_hide_craft_message)
	add_child(message_timer)
	message_timer.autostart = false
	
	# Создаем таймер для автоматического скрытия радикалов
	radical_timer = Timer.new()
	radical_timer.wait_time = 1.5
	radical_timer.one_shot = true
	radical_timer.timeout.connect(_hide_radical)
	add_child(radical_timer)
	radical_timer.autostart = false
	
	# Загружаем китайский шрифт
	if radical_label:
		var font_path = "res://assets/font/Ma_Shan_Zheng/MaShanZheng-Regular.ttf"
		var font_file = load(font_path) as FontFile
		if font_file:
			radical_label.add_theme_font_override("font", font_file)
		else:
			# Пытаемся загрузить как ресурс
			var font_resource = load(font_path)
			if font_resource:
				radical_label.add_theme_font_override("font", font_resource)
	
	# Скрываем радикал при старте
	if radical_display:
		radical_display.visible = false
	
	# Обновляем инвентарь при изменении GameState
	if GameState:
		_update_inventory()
		# Можно добавить сигнал для обновления инвентаря, если он будет в GameState
		# GameState.inventory_changed.connect(_update_inventory)
	
	# Скрываем сообщение о крафте при старте
	if craft_message_label:
		craft_message_label.visible = false

func _update_inventory():
	# Очищаем старые метки
	for child in inventory_items.get_children():
		child.queue_free()
	item_labels.clear()
	
	# Добавляем метки для каждого предмета в инвентаре
	if GameState and GameState.inv:
		for item_id in GameState.inv.keys():
			var count = GameState.inv[item_id]
			if count > 0:
				var label = Label.new()
				label.text = "%s: %d" % [item_id, count]
				inventory_items.add_child(label)
				item_labels[item_id] = label

func show_hint(text: String):
	hint_label.text = text
	hint_label.visible = true

func hide_hint():
	hint_label.visible = false

func show_craft_message(text: String, is_success: bool):
	if not craft_message_label:
		print("Craft message label not found!")
		return
	
	craft_message_label.text = text
	craft_message_label.visible = true
	
	# Устанавливаем цвет в зависимости от успеха
	if is_success:
		craft_message_label.modulate = Color.GREEN
	else:
		craft_message_label.modulate = Color.RED
	
	# Останавливаем предыдущий таймер и запускаем новый
	if message_timer:
		message_timer.stop()
		message_timer.start()
	else:
		print("Message timer not found!")

func _hide_craft_message():
	if craft_message_label:
		craft_message_label.visible = false
		print("Craft message hidden by timer")

func _process(_delta):
	# Обновляем инвентарь каждый кадр (можно оптимизировать через сигналы)
	_update_inventory()

func show_radical(item_id: String):
	# Показываем радикал для собранного предмета
	if not radical_label or not radical_display:
		return
	
	var radical_mapper = load("res://scripts/radical_mapper.gd")
	var radical = radical_mapper.get_radical(item_id)
	
	if radical != "":
		radical_label.text = radical
		radical_display.visible = true
		
		# Запускаем анимацию появления
		radical_display.modulate = Color(1, 1, 1, 0)
		var tween = create_tween()
		tween.tween_property(radical_display, "modulate", Color(1, 1, 1, 1), 0.3)
		
		# Останавливаем предыдущий таймер и запускаем новый
		if radical_timer:
			radical_timer.stop()
			radical_timer.start()
	else:
		print("Radical not found for item_id: ", item_id)

func _hide_radical():
	if radical_display:
		# Анимация исчезновения
		var tween = create_tween()
		tween.tween_property(radical_display, "modulate", Color(1, 1, 1, 0), 0.3)
		await tween.finished
		radical_display.visible = false

func _exit_tree():
	# Очищаем таймеры при выходе
	if message_timer:
		message_timer.queue_free()
	if radical_timer:
		radical_timer.queue_free()

