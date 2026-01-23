# res://scripts/pig_animation.gd
# Скрипт для анимации и движения свиньи

extends Node3D

@export var move_speed: float = 0.3  # Скорость движения (минимальная)
@export var rotation_speed: float = 2.0  # Скорость поворота
@export var wander_radius: float = 1.5  # Радиус блуждания (минимальный)
@export var min_wait_time: float = 3.0  # Минимальное время ожидания
@export var max_wait_time: float = 6.0  # Максимальное время ожидания
@export var animation_speed: float = 1.0  # Скорость анимации

var animation_player: AnimationPlayer = null
var start_position: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var is_moving: bool = false
var wait_timer: float = 0.0
var current_animation: String = ""

func _ready():
	# Ждем один кадр, чтобы все узлы были готовы
	await get_tree().process_frame
	
	# Получаем родительский узел Pig (RigidBody3D)
	var pig_parent = get_parent()
	if pig_parent == null:
		push_error("PigAnimation: No parent node found!")
		return
	
	# Родитель должен быть RigidBody3D (свинья теперь обернута в RigidBody3D)
	if not pig_parent is RigidBody3D:
		push_error("PigAnimation: Parent is not RigidBody3D!")
		return
	
	# Сохраняем начальную позицию (используем позицию родителя)
	start_position = pig_parent.global_position
	
	# Находим AnimationPlayer в модели (ищем во всех дочерних узлах RigidBody3D)
	# В новом пакете AnimationPlayer может быть в любом месте
	animation_player = _find_animation_player(pig_parent)
	
	# Если не нашли, пробуем найти в узлах с именами, содержащими "pig"
	if animation_player == null:
		for child in pig_parent.get_children():
			var child_name_lower = child.name.to_lower()
			if "pig" in child_name_lower:
				var found = _find_animation_player(child)
				if found:
					animation_player = found
					break
	
	# Запускаем анимацию
	if animation_player:
		print("PigAnimation: Found AnimationPlayer at: ", animation_player.get_path())
		_play_animation()
	else:
		push_warning("PigAnimation: AnimationPlayer not found! Searching in: ", pig_parent.name)
		# Выводим список всех дочерних узлов для отладки
		var all_children = []
		_get_all_children_names(pig_parent, all_children)
		print("PigAnimation: All children: ", all_children)
	
	# Устанавливаем случайное время ожидания
	wait_timer = randf_range(min_wait_time, max_wait_time)
	
	# Выбираем случайную целевую позицию
	_choose_new_target()

func _process(delta):
	# Получаем RigidBody3D (родитель должен быть RigidBody3D)
	var pig_parent = get_parent()
	if pig_parent == null or not pig_parent is RigidBody3D:
		return
	
	var pig_rigid_body = pig_parent as RigidBody3D
	
	if wait_timer > 0:
		wait_timer -= delta
		if wait_timer <= 0:
			# Начинаем движение
			is_moving = true
			_choose_new_target()
			_play_animation()  # Воспроизводим анимацию бега
	else:
		# Двигаемся к цели
		if is_moving:
			_move_towards_target(delta, pig_rigid_body)
			
			# Если достигли цели, останавливаемся
			if pig_rigid_body.global_position.distance_to(target_position) < 0.5:
				is_moving = false
				wait_timer = randf_range(min_wait_time, max_wait_time)
				_play_idle_animation()

func _move_towards_target(delta, pig_rigid_body: RigidBody3D):
	# Вычисляем направление к цели (используем позицию RigidBody3D)
	var direction_to_target = (target_position - pig_rigid_body.global_position).normalized()
	
	# Поворачиваемся к цели (поворачиваем RigidBody3D)
	# В Godot Z обычно направлен вперед, но модель может быть повернута
	# Используем стандартный atan2 для поворота к направлению движения
	var target_rotation = atan2(direction_to_target.x, direction_to_target.z)
	var current_rotation_y = pig_rigid_body.rotation.y
	
	# Плавный поворот
	var rotation_diff = target_rotation - current_rotation_y
	# Нормализуем угол поворота
	while rotation_diff > PI:
		rotation_diff -= TAU
	while rotation_diff < -PI:
		rotation_diff += TAU
	
	pig_rigid_body.rotation.y = lerp_angle(current_rotation_y, target_rotation, rotation_speed * delta)
	
	# Двигаемся вперед (двигаем RigidBody3D)
	# Используем направление движения на основе поворота модели
	# Модель может быть повернута на 180 градусов, поэтому пробуем разные варианты
	var move_distance = move_speed * delta
	
	# Вычисляем направление вперед модели на основе поворота
	# В Godot: forward = (sin(rotation.y), 0, cos(rotation.y))
	# Но если модель смотрит в другую сторону, нужно инвертировать
	var model_forward = Vector3(sin(pig_rigid_body.rotation.y), 0, cos(pig_rigid_body.rotation.y))
	
	# Если модель повернута на 180 градусов, инвертируем направление
	# Проверяем, совпадает ли направление модели с направлением к цели
	var dot_product = model_forward.dot(direction_to_target)
	if dot_product < 0:
		# Модель смотрит в противоположную сторону, инвертируем
		model_forward = -model_forward
	
	# Двигаемся в направлении цели (используем направление к цели, а не модели)
	# Это гарантирует, что свинья движется к цели, даже если модель повернута
	pig_rigid_body.global_position += direction_to_target * move_distance
	
	# Ограничиваем расстояние от стартовой позиции
	var distance_from_start = pig_rigid_body.global_position.distance_to(start_position)
	if distance_from_start > wander_radius:
		# Возвращаемся ближе к стартовой позиции
		var back_direction = (start_position - pig_rigid_body.global_position).normalized()
		pig_rigid_body.global_position += back_direction * move_distance

func _choose_new_target():
	# Выбираем случайную позицию в радиусе блуждания
	var angle = randf() * TAU
	var distance = randf_range(2.0, wander_radius)
	target_position = start_position + Vector3(
		cos(angle) * distance,
		0,
		sin(angle) * distance
	)
	
	# Проверяем, что позиция на земле (можно улучшить с помощью raycast)
	target_position.y = start_position.y

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null

func _get_all_children_names(node: Node, names: Array):
	names.append(node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_get_all_children_names(child, names)

func _play_animation():
	if not animation_player:
		return
	
	# Получаем список всех анимаций
	var animation_list = animation_player.get_animation_list()
	
	if animation_list.is_empty():
		push_warning("Pig: No animations found in AnimationPlayer")
		return
	
	print("PigAnimation: Found ", animation_list.size(), " animations: ", animation_list)
	
	# Ищем анимацию бега/ходьбы (обычно называется "Run", "Walk", "Idle" или похоже)
	var run_animation = ""
	var walk_animation = ""
	var idle_animation = ""
	
	for anim_name in animation_list:
		var lower_name = anim_name.to_lower()
		if "run" in lower_name or "running" in lower_name:
			run_animation = anim_name
		elif "walk" in lower_name or "walking" in lower_name:
			walk_animation = anim_name
		elif "idle" in lower_name or "standing" in lower_name:
			idle_animation = anim_name
	
	# Приоритет: run > walk > idle > первая доступная
	var anim_to_play = ""
	if run_animation != "":
		anim_to_play = run_animation
	elif walk_animation != "":
		anim_to_play = walk_animation
	elif idle_animation != "":
		anim_to_play = idle_animation
	else:
		# Используем первую доступную анимацию
		anim_to_play = animation_list[0]
	
	# Устанавливаем зацикливание
	var anim = animation_player.get_animation(anim_to_play)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR
	
	# Устанавливаем скорость анимации
	animation_player.set_speed_scale(animation_speed)
	
	# Воспроизводим анимацию
	animation_player.play(anim_to_play)
	current_animation = anim_to_play

func _play_idle_animation():
	if not animation_player:
		return
	
	# Ищем анимацию idle
	var animation_list = animation_player.get_animation_list()
	for anim_name in animation_list:
		var lower_name = anim_name.to_lower()
		if "idle" in lower_name or "standing" in lower_name:
			var anim = animation_player.get_animation(anim_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			animation_player.play(anim_name)
			current_animation = anim_name
			return
	
	# Если idle не найдена, останавливаем текущую анимацию
	if animation_player.is_playing():
		animation_player.stop()
