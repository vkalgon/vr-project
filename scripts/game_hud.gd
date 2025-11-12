extends Control

@onready var inventory_items: VBoxContainer = $InventoryPanel/VBoxContainer/InventoryItems
@onready var hint_label: Label = $HintLabel
@onready var craft_message_label: Label = $CraftMessageLabel

var item_labels: Dictionary = {}
var message_timer: Timer = null

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

func _exit_tree():
	# Очищаем таймер при выходе
	if message_timer:
		message_timer.queue_free()

