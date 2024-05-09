extends Node2D

var skipped = false

func _ready():
	DiscordRPC.state = "Menú principal."
	DiscordRPC.refresh()
	
func _process(_delta):
	if (Input.is_action_just_pressed("ui_select") and !skipped):
		skipped = true
		$AnimationPlayer.stop()
		$AudioStreamPlayer.stop()
		$ColorRect.modulate.a = 1
		$Timer.start()
		

func changeScene():
	get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")


func _on_timer_timeout():
	changeScene()
