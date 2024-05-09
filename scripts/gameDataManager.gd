extends Node

signal debrisSignal

var globalVolume = 0
var paused = false
var deaths = 0
var levelCleared = false

func _ready():
	globalVolume = AudioServer.get_bus_volume_db(0)

func _format_seconds(time : float, use_milliseconds : bool) -> String:
	var minutes := time / 60
	var seconds := fmod(time, 60)
	if not use_milliseconds:
		return "%02d:%02d" % [minutes, seconds]
	var milliseconds := fmod(time, 1) * 100
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]
