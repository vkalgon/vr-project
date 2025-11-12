extends Node

# Глобальные настройки игры
var fullscreen: bool = true

func _ready():
	# Загружаем настройки при старте
	_load_settings()

func _load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://game_settings.cfg")
	if err == OK:
		fullscreen = config.get_value("game", "fullscreen", true)
		_apply_fullscreen(fullscreen)
	else:
		# По умолчанию включаем полноэкранный режим
		_apply_fullscreen(true)

func _apply_fullscreen(enabled: bool):
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

