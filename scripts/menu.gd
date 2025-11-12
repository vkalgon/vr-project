extends Control

@onready var start_button: TextureButton = $VBoxContainer/StartButton
@onready var settings_button: TextureButton = $VBoxContainer/SettingsButton
@onready var quit_button: TextureButton = $VBoxContainer/QuitButton
@onready var settings_panel: Control = $SettingsPanel
@onready var back_button: TextureButton = $SettingsPanel/VBoxContainer/BackButton
@onready var inventory_button: Button = $VBoxContainer/InventoryButton
@onready var stats_button: Button = $VBoxContainer/StatsButton
@onready var inventory_panel: Panel = $InventoryPanel
@onready var stats_panel: Panel = $StatsPanel
@onready var inventory_back_button: Button = $InventoryPanel/VBoxContainer/BackButton
@onready var stats_back_button: Button = $StatsPanel/VBoxContainer/BackButton

const MAIN_SCENE_PATH = "res://scenes/Main.tscn"

func _ready():
	# Подключаем сигналы кнопок
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	stats_button.pressed.connect(_on_stats_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	inventory_back_button.pressed.connect(_on_back_button_pressed)
	stats_back_button.pressed.connect(_on_back_button_pressed)
	
	# Скрываем все панели при старте
	settings_panel.visible = false
	inventory_panel.visible = false
	stats_panel.visible = false
	
	# Устанавливаем фокус на кнопку старта
	start_button.grab_focus()
	
	# Обработка нажатия Escape для закрытия панелей
	set_process_input(true)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):  # Escape
		# Закрываем все панели и возвращаемся в главное меню
		if settings_panel.visible or inventory_panel.visible or stats_panel.visible:
			_on_back_button_pressed()

func _on_start_button_pressed():
	# Воспроизводим звук подтверждения
	if AudioManager:
		AudioManager.play_ui_confirm()
	# Небольшая задержка для звука перед переходом
	await get_tree().create_timer(0.2).timeout
	# Загружаем главную сцену игры
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_settings_button_pressed():
	# Показываем панель настроек
	settings_panel.visible = true
	back_button.grab_focus()

func _on_quit_button_pressed():
	# Выход из игры
	get_tree().quit()

func _on_inventory_button_pressed():
	# Показываем панель инвентаря
	inventory_panel.visible = true
	stats_panel.visible = false
	settings_panel.visible = false

func _on_stats_button_pressed():
	# Показываем панель статистики
	stats_panel.visible = true
	inventory_panel.visible = false
	settings_panel.visible = false

func _on_back_button_pressed():
	# Возвращаемся в главное меню
	settings_panel.visible = false
	inventory_panel.visible = false
	stats_panel.visible = false
	settings_button.grab_focus()

