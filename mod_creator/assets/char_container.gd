tool
extends Control

onready var icon = $"%Icon"
onready var char_name = $"%CharName"
var creator
var char_name_string
var char_path

func set_values(scene_path: String, character_name: String):
	char_name.text = character_name
	char_name_string = character_name
	char_path = scene_path
	var scene = load(scene_path)
	var chara = scene.instance()
	icon.texture = chara.character_portrait
	chara.queue_free()


func _on_Yes_pressed():
	print(char_path)
	print(char_name_string)
	creator.delete_character(char_path, char_name_string)


func _on_No_pressed():
	$"%Are you sure".hide()


func _on_Delete_pressed():
	$"%Timer".reset_timer()
	$"%Yes".disabled = true
	$"%Are you sure".show()


func _on_Timer_timer_finished():
	$"%Yes".disabled = false
