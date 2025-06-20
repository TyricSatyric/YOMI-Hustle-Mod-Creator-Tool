tool
extends Control

var template = preload("res://addons/mod_creator/assets/Mod Template.tscn")
var data: Dictionary
var mods: Dictionary
onready var holder = $"%ModsHolder"
onready var no_mods = $"%NoMods?"
var mod_to_delete
var mod_arr = []
onready var mod_creator = get_parent().get_parent()


func create_mods(mods_data):
	data = mods_data
	if data["is_empty"]:
		no_mods.show()
		return
	no_mods.hide()
	
	mods = data["mods"]
	for key in mods.keys():
		var listed_mod = template.instance()
		holder.add_child(listed_mod)
		listed_mod.mod_name.bbcode_text = mods[key]["friendly_name"] + " [color=#777777]" + mods[key]["name"] + " V. " +mods[key]["version"] + "[/color]"
		listed_mod.author.bbcode_text = "[right]By: " + mods[key]["author"]+ "[/right]"
		listed_mod.identifier = mods[key]["name"]
		
		var icon_tex = ResourceLoader.load(mods[key]["path"]+"/editor_icon.png", "Texture", true)
		listed_mod.icon.texture = icon_tex
		
		mod_arr.append(key)

func edit_mod(new_data, old_identifier):
	var mod_index = mod_arr.find(old_identifier)
	var listed_mod = holder.get_child(mod_index)
	listed_mod.mod_name.bbcode_text = new_data["friendly_name"] + " [color=#777777]" +  new_data["name"] + " V. "+ new_data["version"] + "[/color]"
	listed_mod.author.bbcode_text = "[right]By: " + new_data["author"]+ "[/right]"
	listed_mod.identifier = new_data["name"]
	
	var icon_tex = ResourceLoader.load(mods[new_data["name"]]["path"]+"/editor_icon.png", "Texture", true)
	listed_mod.icon.texture = icon_tex
	mod_arr[mod_index] = new_data["name"]

func add_new_mod(mod_data, new_mods_data):
	no_mods.hide()
	data = new_mods_data
	mods = data["mods"]
	var listed_mod = template.instance()
	holder.add_child(listed_mod)
	listed_mod.mod_name.bbcode_text = mod_data["friendly_name"] + " [color=#777777]" + mod_data["name"] + " V. " + mod_data["version"] + "[/color]"
	listed_mod.author.bbcode_text = "[right]By: " + mod_data["author"]+ "[/right]"
	listed_mod.identifier = mod_data["name"]
	
	var icon_tex = ResourceLoader.load(mod_data["path"]+"/editor_icon.png", "Texture", true)
	listed_mod.icon.texture = icon_tex
	mod_arr.append((mod_data["name"]))
		
	
func delete(identifier):
	print("delete mod: " + identifier)
	mod_to_delete = identifier
	$"%ConfirmDelete".disabled = true
	$"%TimerLabel".reset_timer()
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
	if dir.open(mod_dir) != OK:
		print("No se pudo abrir el directorio:", mod_dir)
		return
	
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
	
	# Finalmente, eliminar el propio directorio
	dir.remove(mod_dir)




func _on_CancelDelete_pressed():
	$"%DeletePopup".hide()


func _on_TimerLabel_timer_finished():
	$"%ConfirmDelete".disabled = false


func _on_Update_pressed():
	for child in holder.get_children():
		child.queue_free()
	mod_arr = []
	create_mods(data)
