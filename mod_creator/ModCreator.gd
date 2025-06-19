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



