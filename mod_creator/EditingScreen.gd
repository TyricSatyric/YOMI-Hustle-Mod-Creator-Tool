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
var mod_metadata


func load_mod_data(identifier):
	$"%AdvancedMetadata".hide()
	var metadata_path = mod_creator.data["mods"][identifier]["path"] + "/_metadata"
	var file = File.new()
	if file.open(metadata_path, File.READ) == OK:
		var content = file.get_as_text()
		file.close()
		var result = JSON.parse(content)
		mod_metadata = result.result


func _on_Toogle_advanced_metadata_pressed():
	if $"%AdvancedMetadata".visible:
		$"%AdvancedMetadata".hide()
	else:
		$"%AdvancedMetadata".show()


func _on_Save_pressed():
	# save
	mod_creator.open_mod_list()
