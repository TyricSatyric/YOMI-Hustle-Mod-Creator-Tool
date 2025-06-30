tool
extends Control

var mod_info: Dictionary
onready var icon = $"%Icon"
onready var mod_name = $"%ModName"
onready var author = $"%Author"
var identifier
onready var list = get_parent().get_parent().get_parent().get_parent().get_parent()
	
func set_variables(info, texture):
	mod_info = info
	icon.texture = texture

func _on_Edit_button_down():
	list.edit(identifier)

func _on_Delete_button_down():
	list.delete(identifier)


func _on_Delist_button_down():
	list.delist(identifier)
