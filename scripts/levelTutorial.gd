extends Node2D

var talkedToKaru = false

func _ready():
	Conductor.songToGet(get_tree().current_scene.name)
