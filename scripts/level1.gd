extends Node2D

var songHasChanged = false
var talkedToKaru = false
func _ready():
	Conductor.curScene = "level1"
	Conductor.resetEVERYTHINGGGGG()
	Conductor.songToGet("level1")
	DiscordRPC.state = "Nivel 1"
	DiscordRPC.refresh()

func _on_area_2d_body_entered(body):
	if (body.name == "player"):
		if (!songHasChanged):
			songHasChanged = true
			Conductor.goToNextSection = true
