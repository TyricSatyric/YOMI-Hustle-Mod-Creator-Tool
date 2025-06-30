tool

extends Node

onready var editing_screen = $"%EditingScreen"
onready var list = $"%CharacterList"
onready var creationScreen = $"%CharCreationScreen"
onready var char_name = $"%CreateCharName"
onready var no_characters = $"%NoCharacters?"
onready var holder = $"%CharactersHolder"
onready var template = preload("res://addons/mod_creator/assets/Character Template.tscn")
var character_template = 'addCustomChar("CHARACTER", "SCENE_PATH")'
var character_template_path = "res://addons/mod_creator/assets/CharacterSelect_template.gd"
var mod_main_template = 'modLoader.installScriptExtension("SCRIPT_PATH")'
var file = File.new()
var dir = Directory.new()
var folder_path

func load_characters():
	for child in holder.get_children():
		child.queue_free()
	folder_path = editing_screen.mod_creator.data["mods"][editing_screen.mod_metadata["name"]]["path"]
	if file.file_exists(folder_path+"/CharacterSelect.gd"):
		file.open(folder_path+"/CharacterSelect.gd", File.READ)
		var code = file.get_as_text()
		file.close()
		var characters = extract_characters(code)
		print("creating characters")
		print(characters)
		if characters.size() == 0:
			no_characters.show()
		else:
			no_characters.hide()
		for character in characters:
			var character_name = character[0]
			var scene = character[1]
			var char_preview = template.instance()
			char_preview.creator = self
			holder.add_child(char_preview)
			char_preview.set_values(scene, character_name)
		

func delete_character(scene_path, chara_name):
	print(folder_path+"/CharacterSelect.gd")
	file.open(folder_path+"/CharacterSelect.gd", File.READ)
	var content = file.get_as_text()
	file.close()
	var original_line: String = character_template
	original_line = original_line.replace("CHARACTER", chara_name)
	original_line = original_line.replace("SCENE_PATH", scene_path)
	content = content.replace(original_line, "")
	file.open(folder_path+"/CharacterSelect.gd", File.WRITE)
	file.store_string(content)
	file.close()
	delete_char_files(folder_path+"/characters/"+chara_name)
	editing_screen.mod_creator.update_file_system()
	editing_screen.mod_creator.connect("finished_updating_filesystem", self, "load_characters", [], CONNECT_ONESHOT)

func add_character(path: String):
	if !file.file_exists(folder_path+"/CharacterSelect.gd"):
		file.open(character_template_path, File.READ)
		var default_code = file.get_as_text()
		file.close()
		
		file.open(folder_path+"/CharacterSelect.gd", File.WRITE)
		file.store_string(default_code)
		file.close()
		
		var char_script = mod_main_template
		char_script = char_script.replace("SCRIPT_PATH", folder_path+"/CharacterSelect.gd")
		file.open(folder_path+"/ModMain.gd", File.READ)
		var main_code = file.get_as_text()
		file.close()
		
		main_code = insert_line_into_init(main_code, char_script)
		file.open(folder_path+"/ModMain.gd", File.WRITE)
		file.store_string(main_code)
		
		file.close()
	var character_line = character_template
	character_line = character_line.replace("CHARACTER", path.get_file().replace(".tscn", ""))
	character_line = character_line.replace("SCENE_PATH", path)
	
	file.open(folder_path+"/CharacterSelect.gd", File.READ)
	var code = file.get_as_text()
	file.close()
	
	if code.find(character_line) == -1:
		code = insert_line_into_ready(code, character_line)
		file.open(folder_path+"/CharacterSelect.gd", File.WRITE)
		file.store_string(code)
		file.close()
	load_characters()

func delete_char_files(char_dir: String) -> void:
	var dir = Directory.new()
	dir.open(char_dir)
	
	dir.list_dir_begin(true, true) 
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = char_dir.plus_file(file_name)
		if dir.current_is_dir():
			delete_char_files(full_path)  
		else:
			var file = File.new()
			if file.file_exists(full_path):
				dir.remove(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	dir.remove(char_dir)

func _on_Reload_pressed():
	load_characters()

func _on_New_Character_pressed():
	list.hide()
	$"%CreateCharName".text = ""
	creationScreen.show()


func _on_Cancel_char_pressed():
	list.show()
	creationScreen.hide()


func _on_Create_new_char_pressed():
	
	if !dir.dir_exists(folder_path+"/characters"):
		dir.make_dir_recursive(folder_path+"/characters")
		
	if !file.file_exists(folder_path+"/CharacterSelect.gd"):
		file.open(character_template_path, File.READ)
		var default_code = file.get_as_text()
		file.close()
		
		file.open(folder_path+"/CharacterSelect.gd", File.WRITE)
		file.store_string(default_code)
		file.close()
		
		var char_script = mod_main_template
		char_script = char_script.replace("SCRIPT_PATH", folder_path+"/CharacterSelect.gd")
		file.open(folder_path+"/ModMain.gd", File.READ)
		var main_code = file.get_as_text()
		file.close()
		
		main_code = insert_line_into_init(main_code, char_script)
		file.open(folder_path+"/ModMain.gd", File.WRITE)
		file.store_string(main_code)
		file.close()
	
	var character_line = character_template
	character_line = character_line.replace("CHARACTER", char_name.text)
	character_line = character_line.replace("SCENE_PATH", folder_path+"/characters/"+char_name.text+"/"+char_name.text+".tscn")
	
	file.open(folder_path+"/CharacterSelect.gd", File.READ)
	var code = file.get_as_text()
	file.close()
	
	code = insert_line_into_ready(code, character_line)
	file.open(folder_path+"/CharacterSelect.gd", File.WRITE)
	file.store_string(code)
	file.close()
	
	copy_directory("res://addons/mod_creator/assets/BaseChar/", folder_path+"/characters/"+char_name.text, char_name.text)
	replace_paths_in_file(folder_path+"/characters/"+char_name.text+"/sprites/animations/spriteframes.tres", "res://addons/mod_creator/assets/BaseChar", folder_path+"/characters/"+char_name.text)
	
	file.open(folder_path+"/characters/"+char_name.text+"/"+char_name.text+".tscn", File.READ)
	var scene_content = file.get_as_text()
	file.close()
	
	scene_content = scene_content.replace('"res://addons/mod_creator/assets/BaseChar/BaseChar.gd"', '"'+folder_path+"/characters/"+char_name.text+"/"+char_name.text+'.gd"')
	scene_content = scene_content.replace('"res://addons/mod_creator/assets/BaseChar/sprites/animations/spriteframes.tres"', '"'+folder_path+"/characters/"+char_name.text+'/sprites/animations/spriteframes.tres"')
	scene_content = scene_content.replace('"res://addons/mod_creator/assets/BaseChar/sprites/Portrait.png"', '"'+folder_path+"/characters/"+char_name.text+'/sprites/Portrait.png"')
	
	print(scene_content)
	file.open(folder_path+"/characters/"+char_name.text+"/"+char_name.text+".tscn", File.WRITE)
	file.store_string(scene_content)
	file.close()
	
	list.show()
	creationScreen.hide()
	editing_screen.mod_creator.update_file_system()
	editing_screen.mod_creator.connect("finished_updating_filesystem", self, "_on_done_scanning", [], CONNECT_ONESHOT)

func _on_done_scanning():
	load_characters()

func replace_paths_in_file(file_path: String, old_base_path: String, new_base_path: String) -> void:
	var file := File.new()
	if not file.file_exists(file_path):
		return

	file.open(file_path, File.READ)
	var content := file.get_as_text()
	file.close()

	var updated_content := content.replace(old_base_path, new_base_path)

	file.open(file_path, File.WRITE)
	file.store_string(updated_content)
	file.close()

func extract_characters(code: String) -> Array:
	var pattern = "%s\\s*\\((.*?)\\)" % "addCustomChar"
	var regex = RegEx.new()
	regex.compile(pattern)

	var results = []
	for result in regex.search_all(code):
		var start = result.get_start()
		var line_start = code.rfind("\n", start)
		line_start = 0 if line_start == -1 else line_start + 1
		var line = code.substr(line_start, start - line_start)

		if "#" in line:
			var comment_index = line.find("#")
			if comment_index < line.length() and comment_index < (start - line_start):
				continue

		var args_string = result.get_string(1).strip_edges()
		var raw_args = args_string.split(",")
		var args = []
		for arg in raw_args:
			arg = arg.strip_edges()
			if (arg.begins_with("\"") and arg.ends_with("\"")) or (arg.begins_with("'") and arg.ends_with("'")):
				arg = arg.substr(1, arg.length() - 2)
			args.append(arg)
		results.append(args)

	return results


func parse_arguments(arg_string: String) -> Array:
	var args = []
	var current = ""
	var depth = 0
	var in_string = false

	for i in arg_string.length():
		var c = arg_string[i]

		if c == '"' or c == "'":
			in_string = !in_string

		if !in_string:
			if c == "," and depth == 0:
				args.append(current.strip_edges())
				current = ""
				continue
			elif c == "(" or c == "[":
				depth += 1
			elif c == ")" or c == "]":
				depth -= 1

		current += c

	if current.strip_edges() != "":
		args.append(current.strip_edges())

	return args



func insert_line_into_init(source_code: String, new_line: String) -> String:
	var lines := source_code.split("\n")
	var inside_init := false
	var init_indent := ""
	var insert_index := -1

	for i in range(lines.size()):
		var line := lines[i]
		var trimmed := line.strip_edges()
		
		if trimmed.begins_with("func _init"):
			inside_init = true
			init_indent = line.get_slice("func", 0)
			continue
		
		if inside_init:
			var line_indent := line.get_slice(line.strip_edges(), 0)
			if line_indent.length() <= init_indent.length() and trimmed != "":
				insert_index = i
				break

	if insert_index == -1:
		insert_index = lines.size()
	
	lines.insert(insert_index, init_indent + "\t" + new_line)
	return "\n".join(lines)

func insert_line_into_ready(source_code: String, new_line: String) -> String:
	var lines := source_code.split("\n")
	var inside_ready := false
	var ready_indent := ""
	var insert_index := -1

	for i in range(lines.size()):
		var line := lines[i]
		var trimmed := line.strip_edges()
		
		if trimmed.begins_with("func _ready"):
			inside_ready = true
			ready_indent = line.get_slice("func", 0)
			continue
		
		if inside_ready:
			var line_indent := line.get_slice(line.strip_edges(), 0)
			if line_indent.length() <= ready_indent.length() and trimmed != "":
				insert_index = i
				break

	if insert_index == -1:
		insert_index = lines.size()
	
	lines.insert(insert_index, ready_indent + "\t" + new_line)
	return "\n".join(lines)

func copy_directory(source_path: String, destination_path: String, char_name: String = "") -> void:
	var dir := Directory.new()

	if not dir.dir_exists(destination_path):
		dir.make_dir_recursive(destination_path)

	if dir.open(source_path) != OK:
		print("No se pudo abrir: ", source_path)
		return

	dir.list_dir_begin(true, true) 
	var file_name = dir.get_next()
	while file_name != "":
		var dest_name = file_name
		var extension = file_name.get_extension()
		if file_name == "BaseChar."+extension:
			print("equal")
			dest_name = char_name+"."+extension
		var source_file = source_path.plus_file(file_name)
		var dest_file = destination_path.plus_file(dest_name)

		if dir.current_is_dir():
			copy_directory(source_file, dest_file, char_name)
		else:
			var file := File.new()
			if file.open(source_file, File.READ) == OK:
				var data = file.get_buffer(file.get_len())
				file.close()

				var dest := File.new()
				if dest.open(dest_file, File.WRITE) == OK:
					dest.store_buffer(data)
					dest.close()
		file_name = dir.get_next()

	dir.list_dir_end()
	
	
	
	
	
	
	
	
	
	
	
	
	
	


