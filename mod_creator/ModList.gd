tool
extends Control

var template = preload("res://addons/mod_creator/assets/Mod Template.tscn")
var data: Dictionary
onready var holder = $"%ModsHolder"
onready var no_mods = $"%NoMods?"
var mod_to_delete
var mod_arr = []
var file = File.new()
var imported_mod_folder_name
onready var mod_creator = get_parent().get_parent().get_parent()


func create_mods(mods_data):
	data = mods_data
	if data["is_empty"]:
		no_mods.show()
		return
	no_mods.hide()
	
	var mods = data["mods"]
	for key in mods.keys():
		var listed_mod = template.instance()
		holder.add_child(listed_mod)
		listed_mod.mod_name.bbcode_text = mods[key]["friendly_name"] + " [color=#777777]" + mods[key]["name"] + " V. " +mods[key]["version"] + "[/color]"
		listed_mod.author.bbcode_text = "[right]By: " + mods[key]["author"]+ "[/right]"
		listed_mod.identifier = mods[key]["name"]
		
		var icon_tex
		if file.file_exists(mods[key]["path"]+"/editor_icon.png"):
			icon_tex = ResourceLoader.load(mods[key]["path"]+"/editor_icon.png", "Texture", true)
		else:
			icon_tex = ResourceLoader.load("res://addons/mod_creator/assets/default_icon.png", "Texture", true)
		listed_mod.icon.texture = icon_tex
		
		mod_arr.append(key)

func edit_mod(new_data, old_identifier):
	var mod_index = mod_arr.find(old_identifier)
	var listed_mod = holder.get_child(mod_index)
	listed_mod.mod_name.bbcode_text = new_data["friendly_name"] + " [color=#777777]" +  new_data["name"] + " V. "+ new_data["version"] + "[/color]"
	listed_mod.author.bbcode_text = "[right]By: " + new_data["author"]+ "[/right]"
	listed_mod.identifier = new_data["name"]
	
	var icon_tex
	var mods = data["mods"]
	if file.file_exists(mods[new_data["name"]]["path"]+"/editor_icon.png"):
		icon_tex = ResourceLoader.load(mods[new_data["name"]]["path"]+"/editor_icon.png", "Texture", true)
	else:
		icon_tex = ResourceLoader.load("res://addons/mod_creator/assets/default_icon.png", "Texture", true)
	listed_mod.icon.texture = icon_tex
	mod_arr[mod_index] = new_data["name"]

func add_new_mod(mod_data, new_mods_data):
	no_mods.hide()
	data = new_mods_data
	var mods = data["mods"]
	var listed_mod = template.instance()
	holder.add_child(listed_mod)
	listed_mod.mod_name.bbcode_text = mod_data["friendly_name"] + " [color=#777777]" + mod_data["name"] + " V. " + mod_data["version"] + "[/color]"
	listed_mod.author.bbcode_text = "[right]By: " + mod_data["author"]+ "[/right]"
	listed_mod.identifier = mod_data["name"]
	var icon_tex
	if file.file_exists(mod_data["path"]+"/editor_icon.png"):
		icon_tex = ResourceLoader.load(mod_data["path"]+"/editor_icon.png", "Texture", true)
	else:
		icon_tex = ResourceLoader.load("res://addons/mod_creator/assets/default_icon.png", "Texture", true)
	listed_mod.icon.texture = icon_tex
	mod_arr.append((mod_data["name"]))
		
	
func delete(identifier):
	print("delete mod: " + identifier)
	mod_to_delete = identifier
	$"%ConfirmDelete".disabled = true
	$"%TimerLabel".reset_timer()
	var mods = data["mods"]
	$"%DeleteLabel".text = "Are you sure you want to delete " + mods[identifier]["friendly_name"]+"? \nThis will delete ALL FILES of the mod except for the latest build \nThis action CANNOT be undone"
	$"%DeletePopup".show()

func edit(identifier):
	print("edit mod: " + identifier)
	mod_creator.editing_screen.load_mod_data(identifier)
	mod_creator.open_editing_screen()

func _on_ConfirmDelete_pressed():
	$"%DeletePopup".hide()
	var mod_index = mod_arr.find(mod_to_delete)
	var dir = Directory.new()
	var mods = data["mods"]
	delete_mod(mods[mod_to_delete]["path"])
	holder.get_child(mod_index).queue_free()
	mod_arr.remove(mod_index)
	mods.erase(mod_to_delete)
	if mods.empty():
		print("empty mods")
		data["is_empty"] = true
		no_mods.show()
	data["mods"] = mods
	mod_creator.data = data
	mod_creator.update_file_system()
	mod_creator.save_data()
	
	
func delete_mod(mod_dir: String) -> void:
	var dir = Directory.new()
	dir.open(mod_dir)
	
	dir.list_dir_begin(true, true) 
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = mod_dir.plus_file(file_name)
		print(full_path)
		if dir.current_is_dir():
			delete_mod(full_path)  
		else:
			var file = File.new()
			if file.file_exists(full_path):
				dir.remove(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	dir.remove(mod_dir)

func delist(identifier: String):
	var mod_index = mod_arr.find(identifier)
	holder.get_child(mod_index).queue_free()
	mod_arr.remove(mod_index)
	var mods = data["mods"]
	mods.erase(identifier)
	data["mods"] = mods
	mod_creator.data = data
	mod_creator.save_data()


func _on_CancelDelete_pressed():
	$"%DeletePopup".hide()


func _on_TimerLabel_timer_finished():
	$"%ConfirmDelete".disabled = false


func _on_Update_pressed():
	for child in holder.get_children():
		child.queue_free()
	mod_arr = []
	create_mods(data)


func _on_Import_pressed():
	$"%ImportZip".popup_centered()


func _on_AutoDetect_pressed():
	var dir = Directory.new()
	dir.open("res://")
	dir.list_dir_begin(true, true)
	var dir_name = dir.get_next()
	var old_data = data.duplicate(true)
	while dir_name != "":
		if dir.current_is_dir():
			if file.file_exists(dir_name+"/_metadata"):
				file.open("res://"+dir_name+"/_metadata", File.READ)
				var new_mod_metadata = {}
				var content = file.get_as_text()
				file.close()
				if content.strip_edges() != "":
					var result = JSON.parse(content)
					new_mod_metadata = result.result
				if !new_mod_metadata.has("name"):
					new_mod_metadata["name"] = dir_name.get_file()
				if not data["mods"].has(new_mod_metadata["name"]):
					register_mod(new_mod_metadata, "res://"+dir_name)
		dir_name = dir.get_next()
	if old_data != data:
		mod_creator.save_data()
	

func register_mod(metadata: Dictionary, path: String):
	if !file.file_exists(path+"/editor_icon.png"):
		var icon = load("res://addons/mod_creator/assets/default_icon.png")
		var image = icon.get_data()
		if image:
			image.lock()
			var img_path = path+"/editor_icon.png"
			image.save_png(img_path)
			image.unlock()
	var new_data = {
		"path": path,
		"author": metadata.get("author", ""),
		"friendly_name": metadata.get("friendly_name", ""),
		"name": metadata["name"],
		"version": metadata.get("version", "1.0"),
		"consistent_folder": metadata["name"] == path.get_file(),
		"auto_compile": false,
		"auto_steam_compile": false,
		"imported": true
	}
	var old_metadata = metadata.duplicate()
	metadata = mod_creator.add_missing_values(metadata)
	data["mods"][metadata["name"]] = new_data
	add_new_mod(new_data, data)
	var content = ""
	if not file.file_exists(path+"/ModMain.gd"):
		file.open("res://addons/mod_creator/assets/Mod_main_template.gd", file.READ)
		content = file.get_as_text()
		file.close()
		file.open(path+"/ModMain.gd", File.WRITE)
		file.store_string(content)
		file.close()
	file.open(path+"/ModMain.gd", File.READ)
	content = file.get_as_text()
	file.close()
	var dir = Directory.new()
	if dir.dir_exists(path+"/characters"):
		if not file.file_exists(path+"/CharacterSelect.gd"):
			file.open("res://addons/mod_creator/assets/CharacterSelect_template.gd", File.READ)
			var char_select = file.get_as_text()
			file.close()
			file.open(path+"/CharacterSelect.gd", File.WRITE)
			file.store_string(char_select)
			file.close()
		var line_to_add = 'modLoader.installScriptExtension("SCRIPT_PATH")'
		line_to_add = line_to_add.replace("SCRIPT_PATH", path+"/CharacterSelect.gd")
		print(line_to_add)
		print(content.find(line_to_add))
		if content.find(line_to_add) == -1:
			content = $"%Simple Character Creator".insert_line_into_init(content, line_to_add)
			file.open(path+"/ModMain.gd", File.WRITE)
			file.store_string(content)
			file.close()
	var changes_were_made = false
	for key in metadata:
		if metadata.get(key, "") != old_metadata.get(key, ""):
			changes_were_made = true
	if !changes_were_made:
		if metadata["name"] == "" or metadata["author"] == "" or metadata["friendly_name"] == "" or String(metadata["id"]) == "" or String(metadata["priority"]) == "" or metadata["version"] == "":
			changes_were_made = true
	if changes_were_made:
		print("hi" + metadata["name"])
		data["mods"][metadata["name"]]["imported"] = false
		mod_creator.save_metadata(metadata, metadata["name"], path.get_file(), metadata["name"] == path.get_file())


func _on_ImportZip_file_selected(path):
	if zip_has_single_root_folder(path):
		var dir = Directory.new()
		dir.open("res://")
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		var stop_import = false
		while file_name != "":
			if file_name == imported_mod_folder_name:
				mod_creator.show_error("Mod folder already exists.")
				stop_import = true
				break
			file_name = dir.get_next()
		if not stop_import:
			var extract_path = ProjectSettings.globalize_path("res://")
			unzip(path, extract_path)
			
			mod_creator.update_file_system()
			mod_creator.connect("finished_updating_filesystem", self, "get_imported_mod_data", [path], CONNECT_ONESHOT)
	else:
		mod_creator.show_error("Selected zip doesn't fit the requirements.")

func get_imported_mod_data(path):
	var create_metadata = false
	if !file.file_exists("res://"+imported_mod_folder_name+"/editor_icon.png"):
		var icon = load("res://addons/mod_creator/assets/default_icon.png")
		var image = icon.get_data()
		if image:
			image.lock()
			var img_path = "res://"+imported_mod_folder_name+"/editor_icon.png"
			image.save_png(img_path)
			image.unlock()
	var metadata = {}
	if file.file_exists("res://"+imported_mod_folder_name+"/_metadata"):
		file.open("res://"+imported_mod_folder_name+"/_metadata", File.READ)
		var content = file.get_as_text()
		var result = JSON.parse(content)
		metadata = result.result
		file.close()
		file.close()
		if !file.file_exists(data["mods_path"]+path.get_file()):
			file.open(path, File.READ)
			var og_zip = file.get_buffer(file.get_len())
			file.close()
	else:
		create_metadata = true
	var consistent_folder
	if metadata.has("name"): 
		consistent_folder = imported_mod_folder_name == metadata["name"]
	else:
		metadata["name"] = imported_mod_folder_name
		consistent_folder = true
	var new_data = {
		"path": "res://"+imported_mod_folder_name,
		"author": metadata.get("author", ""),
		"friendly_name": metadata.get("friendly_name", ""),
		"name": metadata["name"],
		"version": metadata.get("version", "1.0"),
		"consistent_folder": consistent_folder,
		"auto_compile": false,
		"auto_steam_compile": false,
		"imported": true
	}
	
	data["mods"][metadata["name"]] = new_data
	add_new_mod(new_data, data)
	mod_creator.data = data
	if create_metadata:
		metadata = mod_creator.add_missing_values(metadata)
		mod_creator.save_metadata(metadata, metadata["name"], imported_mod_folder_name, true)
	mod_creator.save_data()

func unzip(path, destination):
	if OS.get_name() == "Windows":
		var cmd = 'powershell -Command "Expand-Archive -Path \'' + path + '\' -DestinationPath \'' + destination + '\' -Force"'
		OS.execute("cmd", ["/c", cmd])
	else:
		OS.execute("unzip", [path, "-d", destination])

func zip_has_single_root_folder(zip_path: String) -> bool:
	if OS.get_name() == "Windows":
		return zip_has_single_root_folder_windows(zip_path)
	else:
		return zip_has_single_root_folder_other(zip_path)

func zip_has_single_root_folder_windows(zip_path: String) -> bool:
	var output = []
	var command = 'Add-Type -AssemblyName System.IO.Compression.FileSystem; ' + '$entries = [System.IO.Compression.ZipFile]::OpenRead(\'' + zip_path + '\').Entries; ' + '$entries.FullName | ForEach-Object { $_ }'

	var exit_code = OS.execute("powershell", ["-Command", command], true, output)

	if exit_code != 0:
		printerr("Error reading zip.")
		return false

	var root_folders = []
	for line in output:
		var path = line.strip_edges()
		if path == "":
			continue
		var parts = path.split("/")
		if parts.size() > 1:
			var root = parts[0]
			if not root_folders.has(root):
				root_folders.append(root)
		else:
			return false

	imported_mod_folder_name = root_folders[0]
	return root_folders.size() == 1
	
func zip_has_single_root_folder_other(zip_path: String) -> bool:
	var output := []
	var exit_code := OS.execute("unzip", ["-l", zip_path], true, output)

	if exit_code != 0:
		printerr("Error reading zip")
		return false

	var root_folders := []
	for line in output:
		line = line.strip_edges()
		if line == "" or line.begins_with("Length") or line.begins_with("------"):
			continue

		var parts = line.split(" ")
		var filtered = []
		for p in parts:
			if p != "":
				filtered.append(p)
		parts = filtered

		if parts.size() < 4:
			continue

		var file_path = parts[3]
		var sub_parts = file_path.split("/")
		if sub_parts.size() == 1:
			return false

		var root = sub_parts[0]
		if not root_folders.has(root):
			root_folders.append(root)
	imported_mod_folder_name = root_folders[0]
	return root_folders.size() == 1

