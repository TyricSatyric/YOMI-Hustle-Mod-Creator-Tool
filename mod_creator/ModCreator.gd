tool
extends MarginContainer

onready var creation_screen = $"%CreationScreen"
onready var editing_screen = $"%EditingScreen"
onready var mod_list = $"%ModList"
var data: Dictionary
var data_path = "res://addons/mod_creator/user_data.json"
var file = File.new()
var dir = Directory.new()
var mods_path
var steam_mods_path = ""
var changes_made_on_load = false

var editor_interface : EditorInterface

signal finished_updating_filesystem

func setup(interface: EditorInterface) -> void:
	editor_interface = interface

func update_file_system():
	var fs = editor_interface.get_resource_filesystem()
#	fs.disconnect("filesystem_changed", self, "_on_filesystem_changed", true)
	fs.connect("filesystem_changed", self, "_on_filesystem_changed", [], CONNECT_ONESHOT)
	fs.scan()
	
func _on_filesystem_changed():
	emit_signal("finished_updating_filesystem")
	$"%Compile manually".disabled = false
	$"%Compile steam manually".disabled = false

func _ready():
#	$"%ModList".show()
#	$"%CreationScreen".hide()
#	$"%EditingScreen".hide()
	if file.file_exists(data_path):
		if file.open(data_path, File.READ) == OK:
			var content = file.get_as_text()
			file.close()

			var result = JSON.parse(content)
			if result.error == OK and typeof(result.result) == TYPE_DICTIONARY:
				data = result.result
				if !data.has("mods_path"):
					mods_path = ProjectSettings.globalize_path("res://../mods")
					mods_path = normalize_path(mods_path)
					if !dir.dir_exists(mods_path):
						dir.make_dir(mods_path)
					data["mods_path"] = mods_path
					changes_made_on_load = true
				else:
					mods_path = data["mods_path"]
					if !dir.dir_exists(mods_path):
						dir.make_dir(mods_path)
				if data.has("steam_mods_path"):
					steam_mods_path = data["steam_mods_path"]
				else:
					data["steam_mods_path"] = "None"
					changes_made_on_load = true
				if !data.has("mods"):
					data["is_empty"] = true
					changes_made_on_load = true
				if changes_made_on_load:
					save_data()
				check_for_folders()
				
			else:
				mods_path = ProjectSettings.globalize_path("res://../mods")
				mods_path = normalize_path(mods_path)
				if !dir.dir_exists(mods_path):
					dir.make_dir(mods_path)
				data = {
					"is_empty": true,
					"mods_path": mods_path
				}
				save_data()
	else:
		mods_path = ProjectSettings.globalize_path("res://../mods")
		mods_path = normalize_path(mods_path)
		if !dir.dir_exists(mods_path):
			dir.make_dir(mods_path)
		data = {
			"is_empty": true,
			"mods_path": mods_path
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
		
func save_metadata(new_metadata: Dictionary, old_identifier: String, new_folder_name: String = "", consistent_name = true):
	if new_folder_name == "":
		new_folder_name = old_identifier
	var path = data["mods"][old_identifier]["path"]+"/_metadata"
	var old_path = data["mods"][old_identifier]["path"]
	var new_path = path
	var erase_old = false
	if consistent_name:
		 new_path = "res://"+new_metadata["name"]
	else:
		new_path = "res://"+new_folder_name
	print(old_path)
	print(consistent_name)
	if new_metadata["name"] != old_identifier:
		erase_old = true
		data["mods"][new_metadata["name"]] = data["mods"][old_identifier].duplicate(true)
		data["mods"][new_metadata["name"]]["name"] = new_metadata["name"]
	data["mods"][new_metadata["name"]]["path"] = new_path
	data["mods"][new_metadata["name"]]["author"] = new_metadata["author"]
	data["mods"][new_metadata["name"]]["friendly_name"] = new_metadata["friendly_name"]
	data["mods"][new_metadata["name"]]["version"] = new_metadata["version"]
	data["mods"][new_metadata["name"]]["consistent_folder"] = consistent_name
	
	if file.file_exists(old_path+"/_metadata"):
		file.open(old_path+"/_metadata", File.WRITE)
		file.store_string(to_pretty_json(new_metadata))
		file.close()
		
	if new_metadata["name"] != old_identifier and consistent_name:
		rename_folder(old_path, new_path)
		mod_list.edit_mod(new_metadata, old_identifier)
	elif !consistent_name and "res://"+new_folder_name != old_path:
		rename_folder(old_path, "res://"+new_folder_name)
	elif consistent_name and old_path != "res://"+new_metadata["name"]:
		rename_folder(old_path, "res://"+new_metadata["name"])
	if erase_old:
		data["mods"].erase(old_identifier)
	save_data()
	update_file_system()
	$"%Cancel".disabled = true
	connect("finished_updating_filesystem", self, "_on_done_scanning", [], CONNECT_ONESHOT)

func _on_done_scanning():
	$"%Cancel".disabled = false
	mod_list._on_Update_pressed()
	pass

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
			save_metadata(metadata, mod, data["mods"][mod]["path"].replace("res://", ""), data["mods"][mod]["consistent_folder"])
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

func normalize_path(path: String) -> String:
	var parts = path.split("/")
	var stack = []
	for part in parts:
		if part == "" or part == ".":
			continue
		elif part == "..":
			if stack.size() > 0:
				stack.pop_back()
		else:
			stack.append(part)
	return "/".join(stack)


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

# Zipping functions start

func compile_mod(identifier: String, for_steam: bool):
	var source_path = data["mods"][identifier]["path"]
	var zip_path = ""
	if for_steam:
		zip_path = data["steam_mods_path"]+"/"+identifier+".zip"
	else:
		zip_path = data["mods_path"]+"/"+identifier+".zip"
	if OS.get_name() == "Windows":
		zip_windows(source_path, zip_path)
	else:
		zip_other(source_path, zip_path)

func zip_windows(source_path, zip_path):
	source_path = ProjectSettings.globalize_path(source_path)
	var command = "Compress-Archive -Path '%s' -DestinationPath '%s' -Force" % [
		source_path,
		zip_path.replace("/", "\\")
	]
	OS.execute("powershell", ["-Command", command])

func zip_other(source_path, zip_path):
	var args = ["-r", zip_path, "."]
	OS.execute("zip", args, true, source_path)

# Zipping functions end



