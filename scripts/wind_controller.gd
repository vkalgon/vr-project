extends Node3D

# Глобальный контроллер ветра для управления эффектом ветра во всей сцене
@export var wind_strength: float = 1.0  # Множитель скорости анимации (0.5 - 2.0)
@export var wind_speed: float = 1.0     # Базовая скорость анимации
@export var wind_direction: Vector3 = Vector3(1, 0, 0)  # Направление ветра (для будущего использования)

signal wind_changed(strength: float, speed: float, direction: Vector3)

func _ready():
	# Добавляем в группу для легкого доступа
	add_to_group("wind_controller")
	
	# Применяем начальные настройки
	_update_wind()

func _update_wind():
	# Отправляем сигнал всем подписчикам (трава автоматически обновится через сигнал)
	wind_changed.emit(wind_strength, wind_speed, wind_direction)

func set_wind_strength(new_strength: float):
	wind_strength = max(new_strength, 0.0)  # Множитель может быть больше 1.0 для более быстрой анимации
	_update_wind()

func set_wind_speed(new_speed: float):
	wind_speed = max(new_speed, 0.0)
	_update_wind()

func set_wind_direction(new_direction: Vector3):
	wind_direction = new_direction.normalized()
	_update_wind()

func get_wind_strength() -> float:
	return wind_strength

func get_wind_speed() -> float:
	return wind_speed

