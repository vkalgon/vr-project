# res://addons/create_nature_scenes_plugin/plugin.gd
@tool
extends EditorPlugin

func _enter_tree():
	# Добавляем кнопку в меню Project → Tools
	add_tool_menu_item("Create Nature Object Scenes", _create_scenes)

func _exit_tree():
	# Удаляем кнопку при выгрузке плагина
	remove_tool_menu_item("Create Nature Object Scenes")

func _create_scenes():
	print("Creating individual scenes for each nature object...")
	
	# Путь к импортированной сцене
	var nature_scene_path = "res://.godot/imported/NaturePack_AllModels.fbx-32b326b5cb41483963e05eb421cf1b60.scn"
	
	# Загружаем сцену
	var nature_scene = load(nature_scene_path) as PackedScene
	if nature_scene == null:
		push_error("Failed to load nature scene from: " + nature_scene_path)
		return
	
	# Инстанцируем сцену
	var nature_root = nature_scene.instantiate()
	if nature_root == null:
		push_error("Failed to instantiate nature scene!")
		return
	
	# Собираем все меши
	var all_meshes: Array[MeshInstance3D] = []
	_collect_meshes(nature_root, all_meshes)
	
	# Создаем папку для сцен объектов природы
	var scenes_dir = "res://scenes/nature_objects/"
	var dir = DirAccess.open("res://")
	if dir == null:
		push_error("Failed to open res:// directory")
		return
	
	# Создаем папку, если её нет
	var scenes_path = "scenes/nature_objects"
	if not dir.dir_exists(scenes_path):
		var result = dir.make_dir_recursive(scenes_path)
		if result != OK:
			push_error("Failed to create directory: " + scenes_dir)
			return
		print("Created directory: ", scenes_dir)
	
	# Создаем отдельную сцену для каждого меша
	var created_count = 0
	for mesh in all_meshes:
		var mesh_name = mesh.name
		
		# Пропускаем фоны
		if "bg" in mesh_name.to_lower():
			continue
		
		# Создаем новую сцену
		var new_scene = PackedScene.new()
		var root_node = mesh.duplicate() as MeshInstance3D
		
		# Устанавливаем имя
		root_node.name = mesh_name
		
		# Добавляем скрипт nature_object
		var script = load("res://scripts/nature_object.gd")
		if script:
			root_node.set_script(script)
			root_node.set_meta("source_name", mesh_name)
		
		# Упаковываем сцену
		var result = new_scene.pack(root_node)
		if result == OK:
			# Сохраняем сцену
			var scene_path = scenes_dir + mesh_name + ".tscn"
			var save_result = ResourceSaver.save(new_scene, scene_path)
			if save_result == OK:
				print("Created scene: ", scene_path)
				created_count += 1
			else:
				push_error("Failed to save scene: " + scene_path)
		else:
			push_error("Failed to pack scene for: " + mesh_name)
		
		# Очищаем
		root_node.queue_free()
	
	# Удаляем временный корневой узел
	nature_root.queue_free()
	
	# Обновляем файловую систему
	EditorInterface.get_resource_filesystem().scan()
	
	print("Created ", created_count, " individual scenes in ", scenes_dir)
	print("Done! You can now use these scenes in the editor.")

func _collect_meshes(node: Node, meshes: Array):
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	
	for child in node.get_children():
		_collect_meshes(child, meshes)

