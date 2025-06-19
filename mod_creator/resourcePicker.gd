tool
extends Control

var icon_picker
var selected_texture

func _ready():
	icon_picker = EditorResourcePicker.new()
	icon_picker.set_base_type("Texture")

	add_child(icon_picker)
	reset_icon()
	icon_picker.connect("resource_changed", self, "_on_icon_selected")
	
func reset_icon():
	icon_picker.edited_resource = load("res://addons/mod_creator/assets/default_icon.png")

func _on_icon_selected(res):
	selected_texture = res
	print("Seleccionaste:", selected_texture)
