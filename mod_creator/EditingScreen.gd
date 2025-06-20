tool
extends Control

onready var mod_name = $"%EdFriendlyName"
onready var identifier = $"%EdIdentifier"
onready var author = $"%EdAuthor"
onready var description = $"%EdDescription"
onready var client = $"%EdClientSide"
onready var version = $"%Version"
onready var icon = $"%EdIconSelect"
onready var mod_creator = get_parent().get_parent()
onready var requirements = $"%Requirements"
onready var id = $"%ID"
onready var priority = $"%Priority"
var old_identifier
var mod_metadata
var selected_texture


func load_mod_data(_identifier):
	var metadata_path = mod_creator.data["mods"][_identifier]["path"] + "/_metadata"
	var file = File.new()
	if file.open(metadata_path, File.READ) == OK:
		var content = file.get_as_text()
		file.close()
		var result = JSON.parse(content)
		mod_metadata = result.result
	
	print(description)
	if !mod_metadata.has("friendly_name") or !mod_metadata.has("name") or !mod_metadata.has("author"):
		$"%Cancel".disabled = true
		$"%Cancel".hint_tooltip = "Some mandatory values are missing, please fix them!"
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
	
	icon.reset_icon()
	
	var icon_path = mod_creator.data["mods"][_identifier]["path"] + "/editor_icon.png"
	if !File.new().file_exists(icon_path):
		icon_path = "res://addons/mod_creator/assets/default_icon.png"
	print(icon_path)
	icon.icon_picker.edited_resource = ResourceLoader.load(icon_path, "", true)
	$"%AdvancedMetadata".hide()

func show_error(message: String):
	$"%ErrorMessage".bbcode_text = "[center][color=#fa7878]"+message+"[/color][/center]"

func _on_Toogle_advanced_metadata_pressed():
	if $"%AdvancedMetadata".visible:
		$"%AdvancedMetadata".hide()
	else:
		$"%AdvancedMetadata".show()

var characters_for_id = "1234567890"
func generate_id():
	var generated_id: String
	for i in 32:
		generated_id += characters_for_id[round(rand_range(0, characters_for_id.length()-1))]
	return generated_id

func _on_Save_pressed():
	$"%Cancel".disabled = false
	$"%Save".disabled = true
	$"%Save".hint_tooltip = "All values have been saved"
	old_identifier = mod_metadata["name"]
	mod_metadata["friendly_name"] = mod_name.text.strip_edges()
	mod_metadata["name"] = identifier.text.strip_edges()
	mod_metadata["author"] = author.text.strip_edges()
	mod_metadata["description"] = description.text.strip_edges()
	mod_metadata["version"] = version.text.strip_edges()
	mod_metadata["client_side"] = client.pressed
	mod_metadata["requires"] = requirements.get_array()
	mod_metadata["id"] = id.text.strip_edges()
	mod_metadata["priority"] = priority.text.strip_edges().to_int()
	selected_texture = icon.selected_texture
	if selected_texture == null:
		selected_texture = load("res://addons/mod_creator/assets/default_icon.png")
	
	if mod_metadata["author"] == "" or mod_metadata["friendly_name"] == "" or mod_metadata["name"] == "" or mod_metadata["version"] == "" or String(mod_metadata["priority"]) == "" or mod_metadata["id"] == "":
		$"%Cancel".disabled = true
		$"%Save".disabled = false
		$"%Save".hint_tooltip = "There are unsaved changes.\nPress here to save them."
		$"%Cancel".hint_tooltip = "Some mandatory values are missing, please fix them!"
		show_error("Error: There are unnassigned values! Mandatory values contain an asterisk \"*\"")
		return
	
	var image = selected_texture.get_data()
	if image:
		image.lock()
		var img_path = "res://"+old_identifier+"/editor_icon.png"
		image.save_png(img_path)
		image.unlock()
	mod_creator.save_metadata(mod_metadata, old_identifier)
	old_identifier = mod_metadata["name"]
	
func _on_any_value_change():
	$"%Save".disabled = false
	$"%Save".hint_tooltip = "There are unsaved changes.\nPress here to save them."


func _on_Requirements_array_changed(new_array):
	_on_any_value_change()


func _on_EdIdentifier_text_changed(new_text: String):
	_on_any_value_change()
	var line_edit := $"%EdIdentifier"
	var old_pos = line_edit.caret_position
	var processed_text := new_text.replace(" ", "_").to_lower()

	line_edit.disconnect("text_changed", self, "_on_EdIdentifier_text_changed")
	line_edit.text = processed_text

	var diff := processed_text.length() - new_text.length()
	line_edit.caret_position = old_pos + diff

	line_edit.connect("text_changed", self, "_on_EdIdentifier_text_changed")
