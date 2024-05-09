extends Node2D

var playerEntered = false
var timer = 0
var goalSongPlayed = false
var player = null
var timerStarted = false
var songUnloaded = false
var sceneName = ""

func _ready():
	sceneName = get_tree().current_scene.name
	if (sceneName == "levelTutorial"):
		$Timer.wait_time = 11

func _process(delta):
	if (playerEntered):
		if (player != null):
			if (player.is_on_floor()):
				if (!timerStarted):
					timerStarted = true
					$Timer.start()
		timer += 60 * delta
		if (timer >= 60):
			if (!goalSongPlayed):
				goalSongPlayed = true
				Conductor.goalSong.play()
		Conductor.volume_db -= (0.2 * 60) * delta
		if (Conductor.volume_db <= -80):
			if (!songUnloaded):
				songUnloaded = true
				Conductor.songUnload()

func _on_area_2d_body_entered(body):
	if (body.name == "player"):
		playerEntered = true
		player = body
		body.shouldChangeOffset = true
		body.state = body.states.VICTORY


func _on_timer_timeout():
	if (sceneName == "levelTutorial"):
		get_tree().change_scene_to_file("res://scenes/other/introCutscene.tscn")
	if (sceneName == "level1"):
		get_tree().change_scene_to_file("res://stages/level2.tscn")
		Conductor.volume_db = 0
	if (sceneName == "level4"):
		get_tree().change_scene_to_file("res://scenes/other/endCutscene.tscn")
		Conductor.volume_db = 0
