tool
extends EditorPlugin

const MainPanel = preload("res://addons/mod_creator/CreationPanel.tscn")

var main_panel_instance
var was_playing := false
var data_path = "res://addons/mod_creator/user_data.json"
var data: Dictionary

func _enter_tree():
	main_panel_instance = MainPanel.instance()
	main_panel_instance.setup(get_editor_interface())
	get_editor_interface().get_editor_viewport().add_child(main_panel_instance)
	make_visible(false)


func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()


func build():
	var file = File.new()
	if file.file_exists(data_path):
		file.open(data_path, File.READ)
		var content = file.get_as_text()
		file.close()
		var result = JSON.parse(content)
		data = result.result
		if data.has("mods"):
			for key in data["mods"].keys():
				if data["mods"][key]["auto_compile"]:
					compile_mod(key, false)

				if data["mods"][key]["auto_steam_compile"]:
					compile_mod(key, true)

	return true
	
	
func has_main_screen():
	return true


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
	var command = "Compress-Archive -Path '%s\\*' -DestinationPath '%s' -Force" % [source_path, zip_path]
	OS.execute("powershell", ["-Command", command])

func zip_other(source_path, zip_path):
	var args = ["-r", zip_path, "."]
	OS.execute("zip", args, true, source_path)

# Zipping functions end


func make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func get_plugin_name():
	return "Mod Creator"



func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
