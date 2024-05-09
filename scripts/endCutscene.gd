extends Node2D

var shakeImage = false
var sSkipTimer = 4.25
var skipped = false
var goToNextSceneTimer = 1.25
var protectSecretEnding = false

@onready var skipColorRect = $SkipColorRect
@onready var endingSong = preload("res://music/mus_departure.ogg")

func _ready():
	Conductor.shouldLoop = true
	Conductor.resetEVERYTHINGGGGG()
	DiscordRPC.state = "Créditos"
	DiscordRPC.refresh()
	
func _process(delta):
	if (sSkipTimer > 0):
		sSkipTimer -= delta
	if (sSkipTimer <= 0):
		$SprSToSkip.modulate.a -= (0.02 * 60) * delta
	
	if (Input.is_action_just_pressed("skipCutscene") and !skipped):
		Conductor.stop()
		Conductor.resetEVERYTHINGGGGG()
		$Explosion.stop()
		$AudioStreamPlayer.stop()
		skipped = true
		skipColorRect.show()
	
	if (skipped):
		goToNextSceneTimer -= delta
		if (goToNextSceneTimer <= 0):
			if (protectSecretEnding):
				get_tree().change_scene_to_file("res://scenes/OctaveLogo.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/other/endingE.tscn")

	if (!skipped):
		if (Conductor.get_playback_position() >= 36.57 and shakeImage):
			get_tree().change_scene_to_file("res://scenes/other/Credits.tscn")
		if ($Explosion.playing):
			if (!shakeImage):
				shakeImage = true
				shake(99999, 2.2)


func shake(duration: float, amplitude: float):
	var timerS = get_tree().create_timer(duration)
	while timerS.time_left > 0:
		$SprHiveExplosion.offset = Vector2(0, 0) + Vector2(randf_range(floor(-amplitude), floor(amplitude)), randf_range(floor(-amplitude), floor(amplitude)))
		await(get_tree().process_frame)


func _on_animation_player_animation_finished(anim_name):
	if (!skipped):
		if (anim_name == "scene_01"):
			Conductor.resetEVERYTHINGGGGG()
			Conductor.songUnload()
			Conductor.songToLoad(105, 0, endingSong)
			$EndCutscene2.play("0")
			Conductor.play()
