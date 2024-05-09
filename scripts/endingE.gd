extends Node2D

var lowerVolume = false
var cutsceneStep = 0
var sSkipTimer = 4.25
var skipped = false
var goToNextSceneTimer = 1.25

@onready var skipColorRect = $SkipColorRect
	

func _process(delta):
	if (sSkipTimer > 0):
		sSkipTimer -= delta
	if (sSkipTimer <= 0):
		$SprSToSkip.modulate.a -= (0.02 * 60) * delta

	if (Input.is_action_just_pressed("skipCutscene") and !skipped):
		Conductor.stop()
		Conductor.resetEVERYTHINGGGGG()
		$sfxGlitch.stop()
		$sfxStatic.stop()
		$mus.stop()
		skipped = true
		skipColorRect.show()
	
	if (skipped):
		goToNextSceneTimer -= delta
		if (goToNextSceneTimer <= 0):
			get_tree().change_scene_to_file("res://scenes/OctaveLogo.tscn")

	if (!skipped):
		if (!$sfxStatic.playing):
			$sfxStatic.play()
			
		if (lowerVolume):
			$sfxStatic.volume_db = lerp($sfxStatic.volume_db, -14.0, (0.04 * 60) * delta)
			$Static.modulate.a = lerp($Static.modulate.a, 0.1, (0.04 * 60) * delta)
		if (!$mus.playing and cutsceneStep > 2):
			$sfxStatic.stop()
			$sfxGlitch.stop()
			if ($Static.visible):
				$ColorRect2.visible = true
				$Static.visible = false
				$Timer3.start()


func _on_timer_timeout():
	if (!skipped):
		lowerVolume = true
		$Timer2.start()
		$mus.play()


func _on_timer_2_timeout():
	if (!skipped):
		$AnimationPlayer.play("Transition")
		await get_tree().create_timer(0.1).timeout
		if (cutsceneStep == 0):
			$AnimatedSprite2D.play("caramelDead")
		if (cutsceneStep == 1):
			$AnimatedSprite2D.play("caramel_what")
		if (cutsceneStep == 2):
			$AnimatedSprite2D.play("AngelTech_Virus")
			$AngelTech_Virus.visible = true
			$sfxGlitch.play()
		$Timer2.start()	
		cutsceneStep += 1
	


func _on_timer_3_timeout():
	get_tree().change_scene_to_file("res://scenes/OctaveLogo.tscn")
