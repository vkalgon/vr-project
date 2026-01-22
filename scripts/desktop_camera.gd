extends Camera3D

var speed := 3.0  # Уменьшена скорость передвижения
var mouse_sensitivity := 0.002
var yaw := 0.0
var pitch := 0.0

# Параметры для реалистичного передвижения (как человек в VR)
@export var player_height: float = 2.0  # Рост игрока в метрах (увеличен для лучшего обзора)
@export var ground_check_distance: float = 2.0  # Расстояние для проверки земли

# Параметры для наклона/приседания
@export var crouch_height: float = 1.2  # Высота при приседании
@export var crouch_speed: float = 5.0  # Скорость приседания
var is_crouching: bool = false
var current_height_offset: float = 0.0  # Смещение высоты при наклоне

# Параметры взаимодействия (как вытянутая рука)
@export var interaction_range: float = 5.0  # Дальность взаимодействия (как вытянутая рука) - увеличено для удобства
@export var interaction_angle: float = 30.0  # Угол конуса взаимодействия (градусы)

@onready var zone: Area3D = $GrabZone
var local_inv := {"cao": 0}

# Для проверки земли и взаимодействия
var space_state: PhysicsDirectSpaceState3D

# Панель для изменения типа объектов
var type_panel: Control = null

# Параметры для звуков шагов
var footstep_timer: float = 0.0
var footstep_interval: float = 0.5  # Интервал между шагами (секунды)
var is_moving: bool = false

func _ready():
	add_to_group("player")  # Добавляем в группу для поиска скриптом подсветки
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Устанавливаем начальную высоту
	_update_height()
	# Находим панель для изменения типа объектов
	_find_type_panel()
	# Запускаем фоновую музыку
	if AudioManager:
		AudioManager.play_background_music()

func _input(event):
	# Обрабатываем движение мыши только если мышь захвачена
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)
		rotation = Vector3(pitch, yaw, 0)

	# Убрали обработку Escape - теперь это обрабатывается в меню паузы
	# if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
	# 	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("interact"):
		# Сначала проверяем, можно ли изменить тип объекта природы
		if _try_change_object_type():
			return
		# Если нет, пытаемся подобрать предмет
		_collect_nearest()

func _process(delta):
	# Обработка приседания/наклона
	_handle_crouch(delta)
	
	# Движение только по горизонтали (как человек ходит)
	var dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += transform.basis.x
	
	# Убираем вертикальную составляющую (движение только по горизонтали)
	dir.y = 0.0
	dir = dir.normalized()
	
	# Проверяем, движется ли игрок
	var was_moving = is_moving
	is_moving = dir.length() > 0.1
	
	# Обработка звуков шагов
	if is_moving:
		# Если только начали двигаться, играем звук сразу
		if not was_moving:
			if AudioManager:
				AudioManager.play_footstep()
			footstep_timer = 0.0
		else:
			footstep_timer += delta
			if footstep_timer >= footstep_interval:
				footstep_timer = 0.0
				if AudioManager:
					AudioManager.play_footstep()
	else:
		footstep_timer = 0.0
	
	# Двигаемся только по горизонтали
	var horizontal_movement = dir * speed * delta
	position.x += horizontal_movement.x
	position.z += horizontal_movement.z
	
	# Обновляем высоту в зависимости от земли
	_update_height()
	
	# Обновляем зону взаимодействия перед камерой (как вытянутая рука)
	_update_interaction_zone()

func _handle_crouch(delta):
	# Проверяем, нажата ли кнопка приседания (Ctrl)
	var should_crouch = Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_CTRL)
	
	if should_crouch and not is_crouching:
		is_crouching = true
	elif not should_crouch and is_crouching:
		is_crouching = false
	
	# Плавно изменяем высоту при приседании
	var target_offset = 0.0
	if is_crouching:
		target_offset = -(player_height - crouch_height)  # Смещение вниз
	
	current_height_offset = lerp(current_height_offset, target_offset, crouch_speed * delta)

func _update_height():
	# Получаем состояние физики для raycast
	space_state = get_world_3d().direct_space_state
	
	# Делаем raycast вниз для определения высоты земли
	# Начинаем с текущей позиции и идем вниз достаточно далеко
	var ray_start = global_position + Vector3(0, 1.0, 0)  # Немного выше текущей позиции
	var ray_end = global_position + Vector3(0, -ground_check_distance * 10, 0)  # Достаточно далеко вниз
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 0xFFFFFFFF  # Проверяем все слои
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Если нашли землю, устанавливаем высоту камеры на уровне роста игрока над землей
		# + смещение при приседании
		var ground_height = result.position.y
		position.y = ground_height + player_height + current_height_offset
	else:
		# Если земли нет, устанавливаем минимальную высоту (земля на y=0)
		position.y = player_height + current_height_offset

func _update_interaction_zone():
	# Обновляем позицию зоны взаимодействия перед камерой (как вытянутая рука)
	if zone == null:
		return
	
	# Размещаем зону перед камерой на расстоянии interaction_range
	var forward = -transform.basis.z  # Направление взгляда
	var hand_position = forward * interaction_range
	
	# Перемещаем зону перед камерой
	zone.position = hand_position
	
	# Увеличиваем размер зоны для лучшего захвата
	if zone.has_node("CollisionShape3D"):
		var shape = zone.get_node("CollisionShape3D")
		if shape.shape is SphereShape3D:
			var sphere = shape.shape as SphereShape3D
			sphere.radius = 0.5  # Радиус зоны захвата

func _collect_nearest():
	# Используем raycast для более точного определения объектов перед камерой
	space_state = get_world_3d().direct_space_state
	
	# Направление взгляда (как вытянутая рука)
	var forward = -transform.basis.z
	var ray_start = global_position
	var ray_end = global_position + forward * interaction_range
	
	# Raycast для определения объекта перед камерой
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 0xFFFFFFFF  # Проверяем все слои
	# Исключаем саму камеру и её дочерние узлы из проверки
	if zone != null:
		query.exclude = [zone]
	
	var result = space_state.intersect_ray(query)
	
	# Также проверяем зону взаимодействия (на случай, если raycast не попал)
	var nearest: RigidBody3D = null
	var best_distance := INF
	
	if zone != null:
		var bodies := zone.get_overlapping_bodies()
		for b in bodies:
			if b is RigidBody3D and b.is_in_group("pickup"):
				var d := global_position.distance_to(b.global_position)
				if d < best_distance and d <= interaction_range:
					best_distance = d
					nearest = b
	
	# Если raycast попал в объект, используем его
	if result and result.collider is RigidBody3D:
		var hit_body = result.collider as RigidBody3D
		if hit_body.is_in_group("pickup"):
			var d = global_position.distance_to(hit_body.global_position)
			if d < best_distance:
				nearest = hit_body
	
	# Если нашли объект, подбираем его
	if nearest:
		var id = nearest.get("item_id")
		if id == null: id = "cao"
		
		# Сохраняем позицию для эффекта
		var pickup_pos = nearest.global_position
		
		# Добавляем в локальный инвентарь (для отладки)
		local_inv[id] = local_inv.get(id, 0) + 1
		
		# Добавляем в глобальный GameState для крафта
		if GameState:
			GameState.add_item(id, 1)
		
		# Спавним визуальный эффект перед удалением объекта
		if FXSpawn:
			FXSpawn.spawn_pickup_fx(pickup_pos)
		
		# Воспроизводим звук подбора
		if AudioManager:
			AudioManager.play_pickup()
		
		# Показываем радикал в центре экрана
		var hud = get_tree().get_first_node_in_group("game_hud")
		if hud and hud.has_method("show_radical"):
			hud.show_radical(id)
		
		nearest.queue_free()
		print("Picked:", id, " local_inv:", local_inv, " GameState.inv:", GameState.inv if GameState else "N/A")

func _find_type_panel():
	# Ищем панель для изменения типа объектов
	var hud = get_tree().get_first_node_in_group("game_hud")
	if hud:
		type_panel = hud.get_node_or_null("ObjectTypePanel")
	if not type_panel:
		# Пытаемся найти в корне сцены
		type_panel = get_node_or_null("/root/Main_tscn/GameHUD/ObjectTypePanel")

func _try_change_object_type() -> bool:
	# Проверяем, есть ли объект природы перед камерой
	space_state = get_world_3d().direct_space_state
	
	var forward = -transform.basis.z
	var ray_start = global_position
	var ray_end = global_position + forward * interaction_range
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 0xFFFFFFFF
	
	if zone != null:
		query.exclude = [zone]
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is MeshInstance3D:
		var hit_mesh = result.collider as MeshInstance3D
		# Проверяем, является ли это объектом природы
		if hit_mesh.is_in_group("nature_object"):
			# Показываем панель для изменения типа
			if type_panel and type_panel.has_method("show_for_object"):
				type_panel.show_for_object(hit_mesh)
				return true
		# Если у объекта нет скрипта nature_object, добавляем его
		elif hit_mesh.get_script() == null:
			# Можно добавить скрипт динамически, но проще сделать через nature_spawner
			pass
	
	return false
