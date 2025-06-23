extends Node

func _init(modLoader = ModLoader):
	print("Installing extensions...")
	# In this script you must write any scripts you want to extend from the original game.
	# For example if you want to create a mod that modifies the menu buttons to do vine booms
	# you must create new script that extends whatever script handles the buttons
	# and then add the logic to play your sound.
	# Template code:
	# modLoader.installScriptExtension("res://YourMod/your_script.gd")
	
	# The tool will automatically generate the extension for character_loader if you add custom characters
