extends Camera3D

var speed := 5.0
var mouse_sensitivity := 0.002
var yaw := 0.0
var pitch := 0.0

@onready var zone: Area3D = $GrabZone
var local_inv := {"cao": 0}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
		_collect_nearest()

func _process(delta):
	var dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += transform.basis.x
	if Input.is_action_pressed("move_up"):      dir += transform.basis.y
	if Input.is_action_pressed("move_down"):    dir -= transform.basis.y
	position += dir.normalized() * speed * delta

func _collect_nearest():
	if zone == null:
		push_warning("Camera has no GrabZone child!")
		return

	var bodies := zone.get_overlapping_bodies()
	# print("overlap:", bodies.size())  # можно включить для отладки

	var nearest: RigidBody3D = null
	var best := INF

	for b in bodies:
		if b is RigidBody3D and b.is_in_group("pickup"):
			var d := global_position.distance_to(b.global_position)
			if d < best:
				best = d
				nearest = b

	if nearest:
		var id = nearest.get("item_id")        # безопасно: вернёт null, если нет свойства
		if id == null: id = "cao"              # запасной вариант
		
		# Добавляем в локальный инвентарь (для отладки)
		local_inv[id] = local_inv.get(id, 0) + 1
		
		# Добавляем в глобальный GameState для крафта
		if GameState:
			GameState.add_item(id, 1)
		
		nearest.queue_free()
		print("Picked:", id, " local_inv:", local_inv, " GameState.inv:", GameState.inv if GameState else "N/A")
