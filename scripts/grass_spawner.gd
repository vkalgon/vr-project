extends Node3D

@export var grass_scene: PackedScene      # сюда укажем scenes/Grass.tscn
@export var count: int = 200              # сколько пучков (увеличено для карты 100x100)
@export var area_size: Vector2 = Vector2(100, 100)  # размер поля по XZ
@export var y: float = 0.0                # высота над полом

func _ready():
	randomize()
	for i in count:
		var g := grass_scene.instantiate()
		var x := randf_range(-area_size.x/2.0, area_size.x/2.0)
		var z := randf_range(-area_size.y/2.0, area_size.y/2.0)
		g.position = Vector3(x, y, z)
		g.rotate_y(randf_range(0.0, TAU))
		add_child(g)
