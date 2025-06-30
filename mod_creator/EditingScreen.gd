tool
extends Control

onready var mod_name = $"%EdFriendlyName"
onready var identifier = $"%EdIdentifier"
onready var author = $"%EdAuthor"
onready var description = $"%EdDescription"
onready var client = $"%EdClientSide"
onready var version = $"%Version"
onready var icon = $"%EdIconSelect"
onready var mod_creator = get_parent().get_parent().get_parent()
onready var requirements = $"%Requirements"
onready var id = $"%ID"
onready var priority = $"%Priority"
onready var mods_path = $"%ModsPath"
onready var steam_mods_path = $"%SteamModsPath"
onready var consistent_folder = $"%EdConsistent Folder"
onready var folder_name = $"%EdFolder name"
onready var project_compile = $"%ProjectCompile"
onready var steam_compile = $"%SteamCompile"
var auto_compile = true
var auto_steam_compile = false
var old_identifier
var mod_metadata
var selected_texture


func load_mod_data(_identifier):
	$"%Save".disabled = true
	$"%Save".hint_tooltip = "All values have been saved"
	var metadata_path = mod_creator.data["mods"][_identifier]["path"] + "/_metadata"
	var file = File.new()
	file.open(metadata_path, File.READ)
	var content = file.get_as_text()
	file.close()
	var result = JSON.parse(content)
	mod_metadata = result.result
	
	print(description)
	if !mod_metadata.has("friendly_name") or !mod_metadata.has("name") or !mod_metadata.has("author"):
		$"%Cancel".disabled = true
		$"%Leave".get_child(0).disabled = true
		$"%Cancel".hint_tooltip = "Some mandatory values are missing, please fix them!"
		$"%Leave".get_child(0).hint_tooltip = "Some mandatory values are missing, please fix them!"
		show_error("Some mandatory values are missing from the metadata, please fix them.")
	
	mod_name.text = mod_metadata.get("friendly_name", "")
	identifier.text = mod_metadata.get("name", "")
	author.text = mod_metadata.get("author", "")
	description.text = mod_metadata.get("description", "")
	version.text = mod_metadata.get("version", "1.0")
	client.pressed = mod_metadata.get("client_side", false)
	requirements.set_array(mod_metadata.get("requires", []))
	id.text = String(mod_metadata.get("id", generate_id()))
	priority.text = String(mod_metadata.get("priority", 0))
	mods_path.text = mod_creator.data["mods_path"]
	steam_mods_path.text = mod_creator.data["steam_mods_path"]
	consistent_folder.pressed = mod_creator.data["mods"][identifier.text]["consistent_folder"]
	auto_compile = mod_creator.data["mods"][identifier.text]["auto_compile"]
	auto_steam_compile = mod_creator.data["mods"][identifier.text]["auto_steam_compile"]
	project_compile.select(1 if auto_compile else 0)
	steam_compile.select(1 if auto_steam_compile else 0)
	folder_name.text = mod_creator.data["mods"][identifier.text]["path"].replace("res://","")
	folder_name.editable = !consistent_folder.pressed
	if mod_creator.data["mods"][identifier.text]["imported"]:
		lock_imported_data()
	else:
		unlock_imported_data()
	
	icon.reset_icon()
	
	var icon_path = mod_creator.data["mods"][_identifier]["path"] + "/editor_icon.png"
	if !file.file_exists(icon_path):
		icon_path = "res://addons/mod_creator/assets/default_icon.png"
	print(icon_path)
	icon.icon_picker.edited_resource = ResourceLoader.load(icon_path, "", true)
	$"%AdvancedMetadata".hide()
	$"%Simple Character Creator".load_characters()

func lock_imported_data():
	$"%ImportedMod".show()
	mod_name.editable = false
	identifier.editable = false
	author.editable = false
	description.readonly = true
	client.disabled = true
	version.editable = false
	requirements.disable()
	id.editable = false
	priority.editable = false
	consistent_folder.disabled = true
	folder_name.editable = false
	project_compile.disabled = true
	steam_compile.disabled = true
	$"%Compile manually".disabled = true
	$"%Compile steam manually".disabled = true
	$"%Cancel".disabled = false
	$"%Leave".get_child(0).disabled = false
	
func unlock_imported_data():
	$"%ImportedMod".hide()
	mod_name.editable = true
	identifier.editable = true
	author.editable = true
	description.readonly = false
	client.disabled = false
	version.editable = true
	requirements.enable()
	id.editable = true
	priority.editable = true
	consistent_folder.disabled = false
	project_compile.disabled = false
	steam_compile.disabled = false
	$"%Compile manually".disabled = false
	$"%Compile steam manually".disabled = false

func show_error(message: String):
	$"%ErrorMessage".bbcode_text = "[center][color=#fa7878]"+message+"[/color][/center]"

func _on_Toogle_advanced_metadata_pressed():
	if $"%AdvancedMetadata".visible:
		$"%AdvancedMetadata".hide()
		$"%Metadata".rect_min_size = Vector2(0, 600)
	else:
		$"%AdvancedMetadata".show()
		$"%Metadata".rect_min_size = Vector2(0, 650)

var characters_for_id = "1234567890"
func generate_id():
	var generated_id: String
	for i in 32:
		generated_id += characters_for_id[round(rand_range(0, characters_for_id.length()-1))]
	return generated_id

func _on_Save_pressed():
	$"%Cancel".disabled = false
	$"%Leave".get_child(0).disabled = false
	$"%Save".disabled = true
	$"%Save".hint_tooltip = "All values have been saved"
	old_identifier = mod_metadata["name"]
	var old_folder = mod_creator.data["mods"][old_identifier]["path"]
	print(old_folder)
	mod_metadata["friendly_name"] = mod_name.text.strip_edges()
	mod_metadata["name"] = identifier.text.strip_edges()
	mod_metadata["author"] = author.text.strip_edges()
	mod_metadata["description"] = description.text.strip_edges()
	mod_metadata["version"] = version.text.strip_edges()
	mod_metadata["client_side"] = client.pressed
	mod_metadata["requires"] = requirements.get_array()
	mod_metadata["id"] = id.text.strip_edges()
	mod_metadata["priority"] = priority.text.strip_edges().to_int()
	mod_creator.data["mods"][old_identifier]["auto_compile"] = auto_compile
	mod_creator.data["mods"][old_identifier]["auto_steam_compile"] = auto_steam_compile
	folder_name.text = folder_name.text.strip_edges()
	selected_texture = icon.selected_texture
	if selected_texture == null:
		selected_texture = load("res://addons/mod_creator/assets/default_icon.png")
	
	if folder_name.text == "" or mod_metadata["author"] == "" or mod_metadata["friendly_name"] == "" or mod_metadata["name"] == "" or mod_metadata["version"] == "" or String(mod_metadata["priority"]) == "" or mod_metadata["id"] == "":
		$"%Cancel".disabled = true
		$"%Leave".get_child(0).disabled = true
		$"%Save".disabled = false
		$"%Save".hint_tooltip = "There are unsaved changes.\nPress here to save them."
		$"%Cancel".hint_tooltip = "Some mandatory values are missing, please fix them!"
		$"%Leave".get_child(0).hint_tooltip = "Some mandatory values are missing, please fix them!"
		show_error("Error: There are unnassigned values! Mandatory values contain an asterisk \"*\"")
		return
	
	var image = selected_texture.get_data()
	if image:
		image.lock()
		var img_path = old_folder+"/editor_icon.png"
		image.save_png(img_path)
		image.unlock()
	mod_creator.save_metadata(mod_metadata, old_identifier, folder_name.text, consistent_folder.pressed)
	mod_creator.save_data()
	old_identifier = mod_metadata["name"]
	if mod_creator.data["mods"][identifier.text]["imported"]:
		lock_imported_data()
	else:
		unlock_imported_data()
	
func _on_any_value_change(any = null):
	$"%Save".disabled = false
	$"%Save".hint_tooltip = "There are unsaved changes.\nPress here to save them."
	$"%Compile manually".disabled = true
	$"%Compile steam manually".disabled = true


func _on_Requirements_array_changed(new_array):
	_on_any_value_change()


func _on_EdIdentifier_text_changed(new_text: String):
	_on_any_value_change()
	var line_edit = identifier
	var old_pos = line_edit.caret_position
	var processed_text := new_text.replace(" ", "_").to_lower()

	line_edit.disconnect("text_changed", self, "_on_EdIdentifier_text_changed")
	line_edit.text = processed_text

	var diff := processed_text.length() - new_text.length()
	line_edit.caret_position = old_pos + diff
	if consistent_folder.pressed:
		folder_name.text = processed_text

	line_edit.connect("text_changed", self, "_on_EdIdentifier_text_changed")


func _on_Browse_project_button_down():
	$"%Project select".current_path = mods_path.text
	$"%Project select".popup_centered()
	


func _on_Browse_steam_button_down():
	$"%Steam select".current_path = steam_mods_path.text if steam_mods_path.text != "None" else $"%Steam select".current_path
	$"%Steam select".popup_centered()


func _on_Project_select_dir_selected(dir):
	mods_path.text = dir
	mod_creator.data["mods_path"] = dir
	mod_creator.save_data()


func _on_Steam_select_dir_selected(dir):
	steam_mods_path.text = dir
	mod_creator.data["steam_mods_path"] = dir
	mod_creator.save_data()


func _on_EdConsistent_Folder_pressed():
	_on_any_value_change()
	folder_name.editable = !consistent_folder.pressed
	if consistent_folder.pressed:
		folder_name.text = identifier.text


func _on_SteamCompile_item_selected(index):
	auto_steam_compile = index == 1
	_on_any_value_change()


func _on_ProjectCompile_item_selected(index):
	auto_compile = index == 1
	_on_any_value_change()


func _on_Compile_manually_pressed():
	mod_creator.compile_mod(identifier.text, false)


func _on_Compile_steam_manually_pressed():
	mod_creator.compile_mod(identifier.text, true)


func _on_Tabs_tab_changed(tab):
	if tab == 2:
		$"%Save and Cancel".hide()
		$"%Leave".show()
	else:
		$"%Save and Cancel".show()
		$"%Leave".hide()


func _on_Unlock_Imported_pressed():
	mod_creator.data["mods"][identifier.text]["imported"] = false
	mod_creator.save_data()
	unlock_imported_data()
