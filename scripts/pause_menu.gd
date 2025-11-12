extends Control

@onready var resume_button: TextureButton = $VBoxContainer/ResumeButton
@onready var settings_button: TextureButton = $VBoxContainer/SettingsButton
@onready var main_menu_button: TextureButton = $VBoxContainer/MainMenuButton
@onready var quit_button: TextureButton = $VBoxContainer/QuitButton
@onready var settings_panel: Panel = $SettingsPanel
@onready var back_button: Button = $SettingsPanel/VBoxContainer/BackButton
@onready var speed_slider: HSlider = $SettingsPanel/VBoxContainer/SpeedSlider
@onready var speed_label: Label = $SettingsPanel/VBoxContainer/SpeedLabel
@onready var sensitivity_slider: HSlider = $SettingsPanel/VBoxContainer/SensitivitySlider
@onready var sensitivity_label: Label = $SettingsPanel/VBoxContainer/SensitivityLabel
@onready var vsync_checkbox: CheckBox = $SettingsPanel/VBoxContainer/VSyncCheckBox
@onready var fullscreen_checkbox: CheckBox = $SettingsPanel/VBoxContainer/FullscreenCheckBox

const MENU_SCENE_PATH = "res://scenes/Menu.tscn"

var is_paused: bool = false
var camera: Camera3D = null

func _ready():
	# Находим камеру для доступа к настройкам
	camera = get_viewport().get_camera_3d()
	
	# Подключаем сигналы кнопок
	resume_button.pressed.connect(_on_resume_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Подключаем сигналы слайдеров
	speed_slider.value_changed.connect(_on_speed_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	vsync_checkbox.toggled.connect(_on_vsync_toggled)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	
	# Загружаем сохраненные настройки
	_load_settings()
	
	# Скрываем меню паузы при старте
	visible = false
	settings_panel.visible = false
	
	# Обработка ввода даже при паузе
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	set_process_input(true)
	set_process_unhandled_input(true)

func _input(event: InputEvent):
	# Обрабатываем ввод только если меню видимо или если нажата пауза
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent):
	# Обрабатываем ввод, который не был обработан другими узлами
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if not visible:  # Если меню не видимо, открываем его
			toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause():
	is_paused = !is_paused
	visible = is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		# Освобождаем мышь для взаимодействия с меню
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		resume_button.grab_focus()
	else:
		# Захватываем мышь обратно для управления камерой
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed():
	toggle_pause()

func _on_settings_button_pressed():
	settings_panel.visible = true
	back_button.grab_focus()

func _on_main_menu_button_pressed():
	# Снимаем паузу перед переходом
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE_PATH)

func _on_quit_button_pressed():
	get_tree().quit()

func _on_back_button_pressed():
	settings_panel.visible = false
	settings_button.grab_focus()
	_save_settings()

func _on_speed_changed(value: float):
	speed_label.text = "Скорость движения: %.1f" % value
	if camera and camera.has_method("set_speed"):
		camera.set_speed(value)
	elif camera:
		camera.speed = value

func _on_sensitivity_changed(value: float):
	sensitivity_label.text = "Чувствительность мыши: %.4f" % value
	if camera and camera.has_method("set_mouse_sensitivity"):
		camera.set_mouse_sensitivity(value)
	elif camera:
		camera.mouse_sensitivity = value

func _on_vsync_toggled(button_pressed: bool):
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if button_pressed else DisplayServer.VSYNC_DISABLED)

func _on_fullscreen_toggled(button_pressed: bool):
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://game_settings.cfg")
	if err == OK:
		var speed = config.get_value("game", "speed", 5.0)
		var sensitivity = config.get_value("game", "sensitivity", 0.002)
		var vsync = config.get_value("game", "vsync", false)
		var fullscreen = config.get_value("game", "fullscreen", true)
		
		speed_slider.value = speed
		sensitivity_slider.value = sensitivity
		vsync_checkbox.button_pressed = vsync
		fullscreen_checkbox.button_pressed = fullscreen
		
		# Применяем настройки
		_on_speed_changed(speed)
		_on_sensitivity_changed(sensitivity)
		_on_vsync_toggled(vsync)
		_on_fullscreen_toggled(fullscreen)
	else:
		# Устанавливаем значения по умолчанию
		_on_speed_changed(speed_slider.value)
		_on_sensitivity_changed(sensitivity_slider.value)
		_on_vsync_toggled(vsync_checkbox.button_pressed)
		# По умолчанию включаем полноэкранный режим
		fullscreen_checkbox.button_pressed = true
		_on_fullscreen_toggled(true)

func _save_settings():
	var config = ConfigFile.new()
	config.set_value("game", "speed", speed_slider.value)
	config.set_value("game", "sensitivity", sensitivity_slider.value)
	config.set_value("game", "vsync", vsync_checkbox.button_pressed)
	config.set_value("game", "fullscreen", fullscreen_checkbox.button_pressed)
	config.save("user://game_settings.cfg")

