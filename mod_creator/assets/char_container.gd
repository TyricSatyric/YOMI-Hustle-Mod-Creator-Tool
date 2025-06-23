tool
extends Control

onready var icon = $"%Icon"
onready var char_name = $"%CharName"
onready var creator = get_parent().get_parent().get_parent().get_parent().get_parent()
var character_name
var char_path

func set_values(scene_path: String, character_name: String):
	char_name.text = character_name
	self.character_name = character_name
	char_path = scene_path
	var scene = load(scene_path)
	var chara = scene.instance()
	icon.texture = chara.character_portrait
	chara.queue_free()


func _on_Yes_pressed():
	creator.delete_character(char_path, character_name)


func _on_No_pressed():
	$"%Are you sure".hide()


func _on_Delete_pressed():
	$"%Are you sure".show()
