tool
extends VBoxContainer

signal array_changed(new_array)

var string_array := []
var item_list := ItemList.new()
var input := LineEdit.new()
var add_button := Button.new()
var delete_button := Button.new()
var enabled = true


func _init():
	for child in get_children():
		child.queue_free()
	
	var hbox := HBoxContainer.new()
	delete_button.text = "Delete selected mod"
	delete_button.disabled = true
	hbox.add_child(delete_button)
	add_button.text = "Add requirement"
	hbox.add_child(add_button)
	hbox.add_child(input)
	input.size_flags_horizontal = 7
	input.placeholder_text = "_required_mod"
	add_child(hbox)
	hbox.alignment = BoxContainer.ALIGN_CENTER
	item_list.allow_reselect = true
	item_list.select_mode = ItemList.SELECT_SINGLE
	add_child(item_list)
	item_list.size_flags_horizontal = 7
	item_list.size_flags_vertical = 7
	
	add_button.connect("pressed", self, "_on_add_pressed")
	input.connect("text_entered", self, "_on_add_pressed")
	delete_button.connect("pressed", self, "_on_delete_pressed")
	item_list.connect("item_selected", self, "_on_item_selected")

	item_list.connect("item_activated", self, "_on_item_remove")

func _on_add_pressed(_text = ""):
	var text = input.text.strip_edges()
	if text == "":
		return
	string_array.append(text)
	item_list.add_item(text)
	input.text = ""
	emit_signal("array_changed", string_array)

func disable():
	enabled = false
	input.editable = false
	add_button.disabled = true
	delete_button.disabled = true
func enable():
	enabled = true
	input.editable = true
	add_button.disabled = false
	delete_button.disabled = false

func _on_item_remove(index):
	if enabled:
		string_array.remove(index)
		item_list.remove_item(index)
		delete_button.disabled = true
		emit_signal("array_changed", string_array)

func _on_item_selected(index):
	if enabled:
		delete_button.disabled = false

func _on_delete_pressed():
	var index = item_list.get_selected_items()
	if index.size() > 0:
		var i = index[0]
		string_array.remove(i)
		item_list.remove_item(i)
		delete_button.disabled = true
		emit_signal("array_changed", string_array)

func set_array(arr):
	string_array = arr.duplicate()
	item_list.clear()
	for val in string_array:
		item_list.add_item(str(val))

func get_array():
	return string_array.duplicate()
