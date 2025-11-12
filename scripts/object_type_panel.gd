# res://scripts/object_type_panel.gd
extends Control

signal type_selected(type: int)
signal closed

@onready var tree_button: Button = $VBoxContainer/TreeButton
@onready var rock_button: Button = $VBoxContainer/RockButton
@onready var mushroom_button: Button = $VBoxContainer/MushroomButton
@onready var grass_button: Button = $VBoxContainer/GrassButton
@onready var structure_button: Button = $VBoxContainer/StructureButton
@onready var decoration_button: Button = $VBoxContainer/DecorationButton
@onready var effect_button: Button = $VBoxContainer/EffectButton
@onready var tool_button: Button = $VBoxContainer/ToolButton
@onready var other_button: Button = $VBoxContainer/OtherButton
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var object_name_label: Label = $VBoxContainer/ObjectNameLabel

var target_object: MeshInstance3D = null

func _ready():
	# Подключаем сигналы кнопок
	tree_button.pressed.connect(_on_tree_pressed)
	rock_button.pressed.connect(_on_rock_pressed)
	mushroom_button.pressed.connect(_on_mushroom_pressed)
	grass_button.pressed.connect(_on_grass_pressed)
	structure_button.pressed.connect(_on_structure_pressed)
	decoration_button.pressed.connect(_on_decoration_pressed)
	effect_button.pressed.connect(_on_effect_pressed)
	tool_button.pressed.connect(_on_tool_pressed)
	other_button.pressed.connect(_on_other_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Скрываем панель по умолчанию
	visible = false
	
	# Обработка Escape для закрытия
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		_on_close_pressed()
		get_viewport().set_input_as_handled()

func show_for_object(obj: MeshInstance3D):
	target_object = obj
	if obj:
		object_name_label.text = "Объект: " + obj.name
		# Позиционируем панель в центре экрана
		var viewport_size = get_viewport().get_visible_rect().size
		position = (viewport_size - size) / 2.0
	visible = true

func _on_tree_pressed():
	_select_type(0)  # ObjectType.TREE

func _on_rock_pressed():
	_select_type(1)  # ObjectType.ROCK

func _on_mushroom_pressed():
	_select_type(2)  # ObjectType.MUSHROOM

func _on_grass_pressed():
	_select_type(3)  # ObjectType.GRASS

func _on_structure_pressed():
	_select_type(5)  # ObjectType.STRUCTURE

func _on_decoration_pressed():
	_select_type(6)  # ObjectType.DECORATION

func _on_effect_pressed():
	_select_type(7)  # ObjectType.EFFECT

func _on_tool_pressed():
	_select_type(8)  # ObjectType.TOOL

func _on_other_pressed():
	_select_type(4)  # ObjectType.OTHER

func _on_close_pressed():
	visible = false
	closed.emit()

func _select_type(type: int):
	if target_object:
		# Проверяем, есть ли у объекта скрипт nature_object
		if target_object.has_method("set_object_type"):
			target_object.set_object_type(type)
			print("Установлен тип для ", target_object.name, ": ", type, " (", _get_type_name(type), ")")
		else:
			# Если скрипта нет, добавляем его
			var script = load("res://scripts/nature_object.gd")
			if script:
				target_object.set_script(script)
				# Вызываем _ready вручную для инициализации
				if target_object.has_method("_ready"):
					target_object._ready()
				# Устанавливаем тип
				if target_object.has_method("set_object_type"):
					target_object.set_object_type(type)
					print("Добавлен скрипт и установлен тип для ", target_object.name, ": ", type)
	type_selected.emit(type)
	visible = false

func _get_type_name(type: int) -> String:
	match type:
		0: return "Дерево"
		1: return "Камень"
		2: return "Гриб"
		3: return "Трава"
		5: return "Строение"
		6: return "Декор"
		7: return "Эффект"
		8: return "Инструмент"
		_: return "Другое"

