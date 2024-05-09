extends CanvasLayer

var goingBack = false
var prepareForUnpause = false
var preventAudioFuckery = 1

@onready var player = get_parent()

func _process(delta):
	if (get_tree().current_scene.name == "level4"):
		if (Conductor.process_mode != Node.PROCESS_MODE_ALWAYS):
			Conductor.process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		if (Conductor.process_mode != Node.PROCESS_MODE_INHERIT):
			Conductor.process_mode = Node.PROCESS_MODE_INHERIT

	if (preventAudioFuckery <= 0):
		if (goingBack):
			$PauseSong.volume_db = lerp($PauseSong.volume_db, -80.0, (0.06 * 60) * delta)
			if ($ColorRect.modulate.a < 1):
				$ColorRect.modulate.a += (0.05 * 60) * delta
			else:
				if ($GoBackTimer.is_stopped()):
					$GoBackTimer.start()

		if (GameDataManager.paused):
			if !(goingBack or prepareForUnpause):
				$PauseSong.volume_db = lerp($PauseSong.volume_db, 0.8, (0.4 * 60) * delta)
			else:
				$PauseSong.volume_db = lerp($PauseSong.volume_db, -80.0, (0.02 * 60) * delta)
			if (!prepareForUnpause):
				$SprPauseOptions.position.y = lerp($SprPauseOptions.position.y, 32.0, (0.4 * 60) * delta)
			else:
				$SprPauseOptions.position.y = lerp($SprPauseOptions.position.y, 552.0, (0.4 * 60) * delta)
		else:
			$PauseSong.volume_db = lerp($PauseSong.volume_db, -80.0, (0.4 * 60) * delta)
			$SprPauseOptions.position.y = lerp($SprPauseOptions.position.y, 552.0, (0.4 * 60) * delta)
	else:
		preventAudioFuckery -= delta

func _input(event):
	if (!goingBack):
		if (preventAudioFuckery <= 0 and !CutsceneHandler.inCutscene and Engine.time_scale == 1):
			if (!player.talking) and !(player.state == player.states.GAMEOVER or player.state == player.states.DEATH or player.state == player.states.VICTORY):
				if !(CutsceneHandler.inCutscene):
					if (event.is_action_pressed("pause") and $Timer.is_stopped()):
						if (!GameDataManager.paused):
							$Timer.start()
							GameDataManager.paused = true
							get_tree().paused = true
							if (get_tree().current_scene.name != "level4"):
								$PauseSong.play()
						else:
							unpause()
					if (GameDataManager.paused):
						if (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")):
							$MenuMove.play()
							if ($SprPauseOptions.frame == 0):
								$SprPauseOptions.frame = 1
							else:
								$SprPauseOptions.frame = 0
								
						if (event.is_action_pressed("pauseSelect")):
							if ($SprPauseOptions.frame == 0):
								unpause()
							else:
								$MenuSelect.play()
								goingBack = true

func unpause():
	if ($Timer.is_stopped()):
		$Timer.start()
		if (!prepareForUnpause):
			prepareForUnpause = true
			$MenuSelect.play()

func _on_go_back_timer_timeout():
	prepareForUnpause = false
	$PauseSong.stop()
	$PauseSong.volume_db = -60
	GameDataManager.paused = false
	get_tree().paused = false
	Conductor.stop()
	Conductor.resetEVERYTHINGGGGG()
	$SprPauseOptions.frame = 0
	CutsceneHandler.inCutscene = false
	FinalBossManager.introPlayed = false
	FinalBossManager.lastPhase = 1
	FinalBossManager.truePhase = 1
	AudioServer.set_bus_effect_enabled(2, 0, false)
	get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")


func _on_timer_timeout():
	if (prepareForUnpause):
		prepareForUnpause = false
		$PauseSong.stop()
		$PauseSong.volume_db = -60
		GameDataManager.paused = false
		get_tree().paused = false
		$SprPauseOptions.frame = 0
