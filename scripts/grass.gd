# res://scripts/grass.gd
extends RigidBody3D
@export var item_id := "cao"

# Параметры ветра (влияют на скорость анимации)
@export var wind_strength: float = 1.0  # Множитель скорости анимации (0.5 - 2.0)
@export var wind_speed: float = 1.0     # Базовая скорость анимации

var animation_player: AnimationPlayer = null
var wind_controller: Node3D = null  # Глобальный контроллер ветра

func _ready():
	add_to_group("pickup") # помечаем, что это подбираемый предмет
	
	# Замораживаем физику, чтобы трава не падала
	freeze = true
	
	# Уменьшаем модель травы в 3 раза
	scale = Vector3(1.0/3.0, 1.0/3.0, 1.0/3.0)
	
	# Находим AnimationPlayer если он есть
	animation_player = _find_animation_player(self)
	
	# Если есть AnimationPlayer, запускаем анимацию
	if animation_player:
		if animation_player.has_animation("Object_0"):
			var anim = animation_player.get_animation("Object_0")
			# Устанавливаем зацикливание анимации
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			animation_player.play("Object_0")
			# Применяем начальную скорость ветра
			_update_animation_speed()
	
	# Находим глобальный контроллер ветра
	var controllers = get_tree().get_nodes_in_group("wind_controller")
	if controllers.size() > 0:
		wind_controller = controllers[0] as Node3D
		if wind_controller and wind_controller.has_signal("wind_changed"):
			wind_controller.wind_changed.connect(_on_wind_changed)
			# Получаем начальные параметры
			if wind_controller.has_method("get_wind_strength"):
				wind_strength = wind_controller.get_wind_strength()
			if wind_controller.has_method("get_wind_speed"):
				wind_speed = wind_controller.get_wind_speed()
				_update_animation_speed()

func _update_animation_speed():
	# Обновляем скорость анимации на основе параметров ветра
	if animation_player and animation_player.has_animation("Object_0"):
		var final_speed = wind_speed * wind_strength
		animation_player.set_speed_scale(final_speed)

func _on_wind_changed(strength: float, speed: float, direction: Vector3):
	wind_strength = strength
	wind_speed = speed
	_update_animation_speed()

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null
