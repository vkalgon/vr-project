# res://scripts/button_animation.gd
# Скрипт для добавления анимации нажатия к кнопкам
extends Button

@export var press_scale: float = 0.95  # Масштаб при нажатии
@export var animation_duration: float = 0.1  # Длительность анимации

var original_scale: Vector2 = Vector2.ONE
var tween: Tween

func _ready():
	# Сохраняем оригинальный масштаб
	original_scale = scale
	
	# Подключаем сигналы для анимации
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_button_down():
	# Анимация нажатия - уменьшаем масштаб
	_animate_scale(Vector2(original_scale.x * press_scale, original_scale.y * press_scale))
	# Воспроизводим звук клика
	if AudioManager:
		AudioManager.play_ui_click()

func _on_button_up():
	# Анимация отпускания - возвращаем масштаб
	_animate_scale(original_scale)

func _on_mouse_entered():
	# Небольшое увеличение при наведении (опционально)
	_animate_scale(Vector2(original_scale.x * 1.05, original_scale.y * 1.05))
	# Воспроизводим звук наведения
	if AudioManager:
		AudioManager.play_ui_hover()

func _on_mouse_exited():
	# Возвращаем масштаб при уходе мыши
	_animate_scale(original_scale)

func _animate_scale(target_scale: Vector2):
	# Останавливаем предыдущую анимацию
	if tween:
		tween.kill()
	
	# Создаем новую анимацию
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", target_scale, animation_duration)

