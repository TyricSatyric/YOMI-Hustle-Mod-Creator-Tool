tool
extends Control

var characters_for_id = "1234567890"
var author: String
var client: bool
var description: String
var mod_name: String
var identifier: String
var id: String
var selected_texture
onready var mod_creator = get_parent().get_parent()



func _on_Create_pressed():
	show_error("")
	print("Creating mod")
	author = $"%Author".text
	client = $"%ClientSide".pressed
	description = $"%Description".text
	mod_name = $"%FriendlyName".text
	identifier = $"%Identifier".text
	selected_texture = $"%IconSelect".selected_texture
	if selected_texture == null:
		selected_texture = load("res://addons/mod_creator/assets/default_icon.png")
	
	author = author.strip_edges()
	description = description.strip_edges()
	mod_name = mod_name.strip_edges()
	identifier = identifier.strip_edges()
	
	if author == "" or mod_name == "" or identifier == "":
		show_error("Error: There are unnassigned values! Mandatory values contain an asterisk \"*\"")
		return
		
	id = generate_id()
	print(author)
	print(client)
	print(description)
	print(mod_name)
	print(identifier)
	print(id)
	
	var metadata = {
		"friendly_name": mod_name,
		"name": identifier,
		"author": author,
		"description": description,
		"client_side": client,
		"id": id,
		"version": "1.0",
		"link": "",
		"overwrites": false,
		"requires": [],
		"priority": 0
	}
	var file = File.new()
	var dir = Directory.new()
	var path = "res://" + identifier
	var file_path = path + "/_metadata"
	if dir.dir_exists(path):
		show_error("Error: This mod already exists!")
		return
		
	dir.make_dir(path)
	var image = selected_texture.get_data()
	if image:
		image.lock()
		var img_path = path+"/editor_icon.png"
		image.save_png(img_path)
		image.unlock()
		
	if file.open(file_path, File.WRITE) == OK:
		file.store_string(mod_creator.to_pretty_json(metadata))
		file.close()
		
	reset_values()
	
	if mod_creator.data["is_empty"]:
		mod_creator.data["is_empty"] = false
		mod_creator.data["mods"] = {}
	var created_mod_data = {
		"path": "res://"+identifier,
		"author": author,
		"friendly_name": mod_name,
		"name": identifier,
		"version": "1.0"
	}
	mod_creator.data["mods"][identifier] = created_mod_data
	mod_creator.save_data()
	mod_creator.mod_list.add_new_mod(created_mod_data, mod_creator.data)
	mod_creator.update_file_system()
	mod_creator.open_mod_list()

func show_error(message: String):
	$"%ErrorMessage".bbcode_text = "[center][color=#fa7878]"+message+"[/color][/center]"

func generate_id():
	var generated_id: String
	for i in 32:
		generated_id += characters_for_id[round(rand_range(0, characters_for_id.length()-1))]
	return generated_id

func reset_values():
	show_error("")
	$"%Author".text = ""
	$"%ClientSide".pressed = false
	$"%Description".text = ""
	$"%FriendlyName".text = ""
	$"%Identifier".text = ""
	$"%IconSelect".reset_icon()
	

func _on_Identifier_text_changed(new_text: String):
	var line_edit := $"%Identifier"
	var old_pos = line_edit.caret_position
	var processed_text := new_text.replace(" ", "_").to_lower()

	line_edit.disconnect("text_changed", self, "_on_Identifier_text_changed")
	line_edit.text = processed_text

	var diff := processed_text.length() - new_text.length()
	line_edit.caret_position = old_pos + diff

	line_edit.connect("text_changed", self, "_on_Identifier_text_changed")



