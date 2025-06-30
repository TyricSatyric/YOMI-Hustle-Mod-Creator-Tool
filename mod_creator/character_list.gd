tool
extends Panel

func can_drop_data(position, data):
	if typeof(data) == TYPE_DICTIONARY and "files" in data:
		for file_path in data["files"]:
			if file_path.ends_with(".tscn"):
				return true
	return false

func drop_data(position, data):
	for file_path in data["files"]:
		if file_path.ends_with(".tscn"):
			print("Scene: ", file_path)
			_handle_scene_file(file_path)

func _handle_scene_file(path):
	var scene: PackedScene = load(path)
	var instance = scene.instance()
	if instance is Fighter:
		$"%Simple Character Creator".add_character(path)
	else:
		print("Scene is NOT a character!")
