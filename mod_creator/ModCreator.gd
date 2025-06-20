tool
extends MarginContainer

onready var creation_screen = $"%CreationScreen"
onready var editing_screen = $"%EditingScreen"
onready var mod_list = $"%ModList"
var data: Dictionary
var data_path = "res://addons/mod_creator/user_data.json"
var file = File.new()

var editor_interface : EditorInterface

func setup(interface: EditorInterface) -> void:
	editor_interface = interface

func update_file_system():
	editor_interface.get_resource_filesystem().scan()

func _ready():
	$"%ModList".show()
	$"%CreationScreen".hide()
	$"%EditingScreen".hide()
	if file.file_exists(data_path):
		if file.open(data_path, File.READ) == OK:
			var content = file.get_as_text()
			file.close()

			var result = JSON.parse(content)
			if result.error == OK and typeof(result.result) == TYPE_DICTIONARY:
				data = result.result
				check_for_folders()
				
			else:
				data = {
					"is_empty": true
				}
	else:
		data = {
			"is_empty": true
			}
		save_data()

	if data["is_empty"]:
		print("empty")
	mod_list.create_mods(data)


func save_data():
	if file.open(data_path, File.WRITE) == OK:
		file.store_string(to_pretty_json(data))
		file.close()
	update_file_system()
		
func save_metadata(new_metadata: Dictionary, old_identifier: String):
	var path = data["mods"][old_identifier]["path"]+"/_metadata"
	var old_path = data["mods"][old_identifier]["path"]
	if new_metadata["name"] != old_identifier:
		var new_path = "res://"+new_metadata["name"]
		data["mods"][new_metadata["name"]] = data["mods"][old_identifier].duplicate(true)
		data["mods"][new_metadata["name"]]["path"] = new_path
		data["mods"][new_metadata["name"]]["name"] = new_metadata["name"]
		path = new_path
	data["mods"][new_metadata["name"]]["author"] = new_metadata["author"]
	data["mods"][new_metadata["name"]]["friendly_name"] = new_metadata["friendly_name"]
	data["mods"][new_metadata["name"]]["version"] = new_metadata["version"]
	
	if file.file_exists(old_path+"/_metadata"):
		file.open(old_path+"/_metadata", File.WRITE)
		file.store_string(to_pretty_json(new_metadata))
		file.close()
		
	if new_metadata["name"] != old_identifier:
		var success = data["mods"].erase(old_identifier)
		rename_folder(old_path, path)
		mod_list.edit_mod(new_metadata, old_identifier)
		save_data()
	update_file_system()

func check_for_folders():
	var missing_identifiers = false
	if not data.has("mods"):
		return
	for mod in data["mods"].keys():
		print(mod)
		var metadata_path = data["mods"][mod]["path"]+"/_metadata"
		file.open(metadata_path, File.READ)
		var content = file.get_as_text()
		file.close()
		var result = JSON.parse(content)
		var metadata = result.result
		if not metadata.has("name") or metadata["name"] != mod:
			metadata["name"] = mod
			save_metadata(metadata, mod)
			missing_identifiers = true
	if missing_identifiers:
		show_error("Some mods had missing identifiers, automatic ones were created based on the folders' name")


func show_error(message: String):
	$"%ErrorMessage".bbcode_text = "[center][color=#fa7878]"+message+"[/color][/center]"

func open_creation_screen():
	mod_list.hide()
	editing_screen.hide()
	creation_screen.show()
	
func open_mod_list():
	creation_screen.hide()
	editing_screen.hide()
	mod_list.show()
	
func open_editing_screen():
	creation_screen.hide()
	mod_list.hide()
	editing_screen.show()
	


func _on_Return_from_creation_button_down():
	creation_screen.reset_values()
	open_mod_list()


func _on_Create_new_button_down():
	open_creation_screen()

func _on_Cancel_pressed():
	open_mod_list()


func rename_folder(old_path: String, new_path: String) -> void:
	var dir := Directory.new()

	if not dir.dir_exists(old_path):
		push_error("Folder doesn't exist: " + old_path)
		return

	if dir.make_dir(new_path) != OK:
		push_error("Could not create new folder: " + new_path)
		return

	if dir.open(old_path) != OK:
		push_error("Could not open the folder: " + old_path)
		return

	dir.list_dir_begin(true, true) 
	var file_name = dir.get_next()

	while file_name != "":
		var old_file_path = old_path.plus_file(file_name)
		var new_file_path = new_path.plus_file(file_name)
		if dir.current_is_dir():
			rename_folder(old_file_path, new_file_path)
		else:
			dir.copy(old_file_path, new_file_path)
			dir.remove(old_file_path)
		file_name = dir.get_next()

	dir.list_dir_end()

	dir.remove(old_path)


func to_pretty_json(data, indent_level := 0) -> String:
	var indent = repeat_string("    ", indent_level)
	var next_indent = repeat_string("    ", indent_level+1)
	if typeof(data) == TYPE_DICTIONARY:
		var keys = data.keys()
		var parts = []
		for k in keys:
			var value_str = to_pretty_json(data[k], indent_level + 1)
			parts.append(next_indent + "\"" + str(k) + "\": " + value_str)
		return "{\n" + ",\n".join(parts) + "\n" + indent + "}"
	elif typeof(data) == TYPE_ARRAY:
		var parts = []
		for item in data:
			parts.append(next_indent + to_pretty_json(item, indent_level + 1))
		return "[\n" + ",\n".join(parts) + "\n" + indent + "]"
	elif typeof(data) == TYPE_STRING:
		return "\"" + data.replace("\"", "\\\"") + "\""
	elif typeof(data) == TYPE_BOOL:
		return "true" if data else "false"
	elif typeof(data) == TYPE_NIL:
		return "null"
	else:
		return str(data)

func repeat_string(s: String, times: int) -> String:
	var result := ""
	for i in range(times):
		result += s
	return result



