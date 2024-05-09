extends Node

var fullscreen = false
var sfxVolume = 0.0
var musVolume = 0.0
var vsync = true
var current_level = 0
var level2_unlocked = false
var level3_unlocked = false
var secret_lab_unlocked = false

var path = "user://data.json"
var pathDisclaimer = "user://ADVERTENCIA.txt"

var data = {}

func _ready():
	if (!FileAccess.file_exists(path)):
		create_saveFile()
	else:
		data = load_saveData()
		if (data != {}):
			var val = linear_to_db(data["settings_data"]["sfxVolume"])
			var val2 = linear_to_db(data["settings_data"]["musVolume"])
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), val)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), val2)
			if (data["settings_data"]["fullscreen"] == 0):
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
				
			if (data["settings_data"]["vsync"] == 0):
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			#var val = linear_to_db(data["settings_data"]["sfxVolume"])
			#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), val)

func save_data(content):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(content))
	file.close()
	file = null
	
func load_saveData():
	var file = FileAccess.open(path, FileAccess.READ)
	var content = JSON.parse_string(file.get_as_text())
	return content

func create_saveFile():
	var file = FileAccess.open("res://scripts/default_settings.json", FileAccess.READ)
	var content = JSON.parse_string(file.get_as_text())
	data = content;
	exportAsTXT()
	save_data(content)
	var val = linear_to_db(data["settings_data"]["sfxVolume"])
	var val2 = linear_to_db(data["settings_data"]["musVolume"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), val)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), val2)

func exportAsTXT():
	var file = FileAccess.open(pathDisclaimer,FileAccess.WRITE)
	file.store_line(str("No edites el archivo de guardado, podrías causar que el juego deje de abrir o se congele. En caso de que eso pase, borra el archivo para que el juego genere uno nuevo al iniciar."))
