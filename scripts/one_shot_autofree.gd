# res://scripts/one_shot_autofree.gd
# Скрипт для автоматического удаления одноразовых эффектов
extends Node3D

@onready var p: GPUParticles3D = $GPUParticles3D

func _ready():
	p.emitting = true
	await get_tree().create_timer(p.lifetime + 0.3).timeout
	queue_free()

