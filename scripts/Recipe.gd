class_name Recipe
extends Resource

@export var name: String = ""                 # название в игре
@export var glyph_hint: String = ""           # подсказка/иероглиф
@export var cost: Dictionary = {}             # напр. {"cao":3} или {"mu":2}
@export var out_scene: PackedScene            # что спавним
