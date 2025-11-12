# Godot 4.x API Reference для GDScript

Этот файл содержит справочную информацию по API Godot 4.x для улучшения автодополнения и понимания контекста в Cursor.

## Основные классы Node

### Node
Базовый класс для всех узлов в сцене.

**Основные методы:**
- `_ready()` - вызывается когда узел готов к использованию
- `_process(delta: float)` - вызывается каждый кадр
- `_physics_process(delta: float)` - вызывается с фиксированной частотой (обычно 60 FPS)
- `_input(event: InputEvent)` - обработка ввода
- `get_tree() -> SceneTree` - получить дерево сцены
- `get_viewport() -> Viewport` - получить viewport
- `queue_free()` - удалить узел в следующем кадре
- `get_node(path: NodePath) -> Node` - получить дочерний узел
- `get_node_or_null(path: NodePath) -> Node` - получить узел или null

**Сигналы:**
- `ready` - когда узел готов

### Node3D
3D узел с позицией, поворотом и масштабом.

**Свойства:**
- `position: Vector3` - локальная позиция
- `global_position: Vector3` - глобальная позиция
- `rotation: Vector3` - углы поворота (в радианах)
- `global_rotation: Vector3` - глобальные углы поворота
- `transform: Transform3D` - локальная трансформация
- `global_transform: Transform3D` - глобальная трансформация
- `basis: Basis` - матрица поворота/масштаба
- `scale: Vector3` - масштаб

**Методы:**
- `look_at(target: Vector3, up: Vector3 = Vector3.UP)` - повернуть к цели
- `to_local(global_point: Vector3) -> Vector3` - преобразовать глобальную точку в локальную
- `to_global(local_point: Vector3) -> Vector3` - преобразовать локальную точку в глобальную

### Camera3D
3D камера для отображения сцены.

**Свойства:**
- `fov: float` - поле зрения (в градусах)
- `near: float` - ближняя плоскость отсечения
- `far: float` - дальняя плоскость отсечения
- `projection: ProjectionType` - тип проекции (PERSPECTIVE, ORTHOGONAL)

**Методы:**
- `get_camera_transform() -> Transform3D` - получить трансформацию камеры
- `project_ray_origin(screen_point: Vector2) -> Vector3` - получить начало луча из экранной точки
- `project_ray_normal(screen_point: Vector2) -> Vector3` - получить направление луча

**Статические методы:**
- `get_viewport().get_camera_3d() -> Camera3D` - получить активную камеру

## Физика и коллизии

### Area3D
Область для обнаружения объектов без физического взаимодействия.

**Свойства:**
- `monitoring: bool` - включено ли обнаружение
- `monitorable: bool` - может ли быть обнаружена другими Area3D

**Методы:**
- `get_overlapping_bodies() -> Array[RigidBody3D]` - получить все перекрывающиеся RigidBody3D
- `get_overlapping_areas() -> Array[Area3D]` - получить все перекрывающиеся Area3D
- `has_overlapping_bodies() -> bool` - есть ли перекрывающиеся тела
- `has_overlapping_areas() -> bool` - есть ли перекрывающиеся области

**Сигналы:**
- `body_entered(body: Node3D)` - тело вошло в область
- `body_exited(body: Node3D)` - тело вышло из области
- `area_entered(area: Area3D)` - область вошла
- `area_exited(area: Area3D)` - область вышла

### RigidBody3D
Физическое тело с динамической симуляцией.

**Свойства:**
- `gravity_scale: float` - множитель гравитации
- `linear_velocity: Vector3` - линейная скорость
- `angular_velocity: Vector3` - угловая скорость
- `mass: float` - масса
- `freeze: bool` - заморозить тело

**Методы:**
- `apply_force(force: Vector3, position: Vector3 = Vector3.ZERO)` - применить силу
- `apply_impulse(impulse: Vector3, position: Vector3 = Vector3.ZERO)` - применить импульс
- `set_axis_velocity(velocity: Vector3)` - установить скорость по оси

**Сигналы:**
- `body_entered(body: Node3D)` - столкновение с телом
- `body_exited(body: Node3D)` - конец столкновения

### CollisionShape3D
Форма коллизии для Area3D, RigidBody3D и т.д.

**Свойства:**
- `shape: Shape3D` - форма коллизии (BoxShape3D, SphereShape3D, CapsuleShape3D и т.д.)

**Типы форм:**
- `BoxShape3D` - коробка
  - `size: Vector3` - размер коробки
- `SphereShape3D` - сфера
  - `radius: float` - радиус
- `CapsuleShape3D` - капсула
  - `radius: float` - радиус
  - `height: float` - высота

## Ввод (Input)

### Input
Глобальный класс для работы с вводом.

**Методы:**
- `is_action_pressed(action: StringName) -> bool` - нажата ли action
- `is_action_just_pressed(action: StringName) -> bool` - только что нажата
- `is_action_just_released(action: StringName) -> bool` - только что отпущена
- `get_action_strength(action: StringName) -> float` - сила действия (0.0-1.0)
- `set_mouse_mode(mode: MouseMode)` - установить режим мыши
  - `Input.MOUSE_MODE_VISIBLE` - видимый курсор
  - `Input.MOUSE_MODE_CAPTURED` - захваченный курсор
  - `Input.MOUSE_MODE_CONFINED` - ограниченный курсор
  - `Input.MOUSE_MODE_HIDDEN` - скрытый курсор

### InputEvent
Базовый класс для событий ввода.

**Типы:**
- `InputEventKey` - событие клавиатуры
  - `keycode: Key` - код клавиши (KEY_E, KEY_ESCAPE и т.д.)
  - `pressed: bool` - нажата ли клавиша
  - `is_action(action: StringName) -> bool` - соответствует ли action
- `InputEventMouseMotion` - движение мыши
  - `relative: Vector2` - относительное движение
  - `position: Vector2` - позиция мыши
- `InputEventMouseButton` - кнопка мыши
  - `button_index: MouseButton` - индекс кнопки
  - `pressed: bool` - нажата ли кнопка

## Сцены и ресурсы

### SceneTree
Дерево сцены игры.

**Свойства:**
- `current_scene: Node` - текущая активная сцена

**Методы:**
- `change_scene_to_file(path: String)` - загрузить сцену из файла
- `change_scene_to_packed(scene: PackedScene)` - загрузить упакованную сцену
- `reload_current_scene()` - перезагрузить текущую сцену

### PackedScene
Упакованная сцена для инстанцирования.

**Методы:**
- `instantiate() -> Node` - создать экземпляр сцены

### Resource
Базовый класс для ресурсов.

**Методы:**
- `duplicate() -> Resource` - создать копию ресурса

## Viewport

### Viewport
Окно просмотра для рендеринга.

**Методы:**
- `get_camera_3d() -> Camera3D` - получить активную 3D камеру
- `get_camera_2d() -> Camera2D` - получить активную 2D камеру

## Математика

### Vector3
3D вектор.

**Константы:**
- `Vector3.ZERO` - нулевой вектор
- `Vector3.ONE` - (1, 1, 1)
- `Vector3.UP` - (0, 1, 0)
- `Vector3.DOWN` - (0, -1, 0)
- `Vector3.LEFT` - (-1, 0, 0)
- `Vector3.RIGHT` - (1, 0, 0)
- `Vector3.FORWARD` - (0, 0, -1)
- `Vector3.BACK` - (0, 0, 1)

**Методы:**
- `distance_to(to: Vector3) -> float` - расстояние до точки
- `distance_squared_to(to: Vector3) -> float` - квадрат расстояния
- `normalized() -> Vector3` - нормализованный вектор
- `length() -> float` - длина вектора
- `dot(b: Vector3) -> float` - скалярное произведение
- `cross(b: Vector3) -> Vector3` - векторное произведение
- `clamp(min: Vector3, max: Vector3) -> Vector3` - ограничить значения

### Vector2
2D вектор.

**Константы:**
- `Vector2.ZERO` - нулевой вектор
- `Vector2.ONE` - (1, 1)
- `Vector2.UP` - (0, -1)
- `Vector2.DOWN` - (0, 1)
- `Vector2.LEFT` - (-1, 0)
- `Vector2.RIGHT` - (1, 0)

### Transform3D
3D трансформация (позиция, поворот, масштаб).

**Свойства:**
- `origin: Vector3` - позиция
- `basis: Basis` - поворот и масштаб

**Методы:**
- `translated(offset: Vector3) -> Transform3D` - создать трансформацию со смещением
- `rotated(axis: Vector3, angle: float) -> Transform3D` - создать трансформацию с поворотом
- `scaled(scale: Vector3) -> Transform3D` - создать трансформацию с масштабом

## Утилиты

### Math
Математические функции.

**Методы:**
- `clamp(value: float, min: float, max: float) -> float` - ограничить значение
- `lerp(from: float, to: float, weight: float) -> float` - линейная интерполяция
- `lerpf(from: float, to: float, weight: float) -> float` - то же самое
- `deg_to_rad(deg: float) -> float` - градусы в радианы
- `rad_to_deg(rad: float) -> float` - радианы в градусы
- `max(a: float, b: float) -> float` - максимум
- `min(a: float, b: float) -> float` - минимум
- `abs(x: float) -> float` - модуль
- `sqrt(x: float) -> float` - квадратный корень
- `sin(x: float) -> float` - синус
- `cos(x: float) -> float` - косинус
- `tan(x: float) -> float` - тангенс

### print()
Вывод в консоль.

**Использование:**
```gdscript
print("Hello, world!")
print("Value: ", some_value)
```

### push_warning()
Вывести предупреждение.

**Использование:**
```gdscript
push_warning("This is a warning message")
```

## GDScript синтаксис

### Ключевые слова и аннотации

- `extends` - наследование класса
- `class_name` - имя класса для авто-загрузки
- `@export` - экспорт переменной в редактор
- `@onready` - инициализация при готовности узла
- `@export_group()` - группа экспортируемых переменных
- `@export_category()` - категория экспортируемых переменных
- `signal` - объявление сигнала
- `func` - объявление функции
- `var` - объявление переменной
- `const` - объявление константы
- `enum` - перечисление
- `static` - статическая функция

### Типы данных

- `int` - целое число
- `float` - число с плавающей точкой
- `bool` - булево значение
- `String` - строка
- `StringName` - именованная строка (быстрее для сравнения)
- `Array` - массив
- `Array[T]` - типизированный массив (Array[int], Array[String] и т.д.)
- `Dictionary` - словарь
- `Dictionary[K, V]` - типизированный словарь
- `Vector2` - 2D вектор
- `Vector3` - 3D вектор
- `Transform2D` - 2D трансформация
- `Transform3D` - 3D трансформация
- `NodePath` - путь к узлу
- `PackedScene` - упакованная сцена

### Специальные функции

- `_ready()` - вызывается когда узел готов
- `_process(delta: float)` - вызывается каждый кадр
- `_physics_process(delta: float)` - вызывается с фиксированной частотой
- `_input(event: InputEvent)` - обработка ввода
- `_unhandled_input(event: InputEvent)` - необработанный ввод
- `_unhandled_key_input(event: InputEventKey)` - необработанная клавиша

### Группы узлов

**Методы:**
- `add_to_group(name: String)` - добавить в группу
- `remove_from_group(name: String)` - удалить из группы
- `is_in_group(name: String) -> bool` - проверить принадлежность
- `get_tree().get_nodes_in_group(name: String) -> Array[Node]` - получить все узлы группы

### Сигналы

**Объявление:**
```gdscript
signal my_signal(param1: int, param2: String)
```

**Вызов:**
```gdscript
my_signal.emit(42, "hello")
```

**Подключение:**
```gdscript
node.my_signal.connect(_on_my_signal)
# или
node.my_signal.connect(func(param1, param2): print(param1, param2))
```

## Паттерны для VR проекта

### Работа с Area3D для зон взаимодействия
```gdscript
extends Node3D
@export var use_zone: Area3D

func _ready():
    if not use_zone:
        use_zone = $UseZone
    use_zone.body_entered.connect(_on_body_entered)
    use_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
    if body.is_in_group("player"):
        # игрок вошёл в зону
        pass
```

### Проверка расстояния до камеры
```gdscript
var cam := get_viewport().get_camera_3d()
if cam:
    var distance := cam.global_position.distance_to(global_position)
    if distance <= interaction_range:
        # можно взаимодействовать
        pass
```

### Работа с RigidBody3D для подбора предметов
```gdscript
func _collect_nearest():
    var zone: Area3D = $GrabZone
    var bodies := zone.get_overlapping_bodies()
    
    var nearest: RigidBody3D = null
    var best_distance := INF
    
    for body in bodies:
        if body is RigidBody3D and body.is_in_group("pickup"):
            var distance := global_position.distance_to(body.global_position)
            if distance < best_distance:
                best_distance = distance
                nearest = body
    
    if nearest:
        # подобрать предмет
        nearest.queue_free()
```

### Инстанцирование сцен
```gdscript
var scene: PackedScene = preload("res://path/to/scene.tscn")
var instance := scene.instantiate()
get_tree().current_scene.add_child(instance)
instance.global_position = spawn_position
```

## Полезные константы

### Key (коды клавиш)
- `KEY_E`, `KEY_F`, `KEY_R`, `KEY_ESCAPE`, `KEY_SPACE`, `KEY_ENTER` и т.д.

### MouseButton (кнопки мыши)
- `MOUSE_BUTTON_LEFT`, `MOUSE_BUTTON_RIGHT`, `MOUSE_BUTTON_MIDDLE`

### ProjectionType (типы проекции камеры)
- `PROJECTION_PERSPECTIVE` - перспективная
- `PROJECTION_ORTHOGONAL` - ортогональная

