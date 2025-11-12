# res://scripts/fx_spawn.gd
# Вспомогательный спавнер для визуальных эффектов
extends Node

var FX_SPARKS := preload("res://effects/pickup_sparks.tscn")

func spawn_pickup_fx(pos: Vector3):
	var fx = FX_SPARKS.instantiate()
	fx.global_position = pos
	# Добавляем в текущую сцену
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(fx)
	else:
		# Если current_scene не доступен, используем root
		get_tree().root.add_child(fx)

