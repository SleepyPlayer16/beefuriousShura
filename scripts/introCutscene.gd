extends Node2D

var cutsceneStep = 0
var prepareSceneSwitch = false
var sSkipTimer = 4.25
var skipped = false
var goToNextSceneTimer = 0.5

@onready var dialogueScene = preload("res://scenes/hud/dialogue_handler.tscn")
@onready var skipColorRect = $CanvasLayer/SkipColorRect
# Called when the node enters the scene tree for the first time.
func _ready():
	CutsceneHandler.cutsceneDialogueEndedSignal.connect(goToCaramelSection)
	CutsceneHandler.TriggerAnimationChange.connect(animChange)
	DiscordRPC.state = "Nivel 1"
	DiscordRPC.refresh()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (sSkipTimer > 0):
		sSkipTimer -= delta
	if (sSkipTimer <= 0):
		$CanvasLayer/SprSToSkip.modulate.a -= (0.02 * 60) * delta
	
	if (Input.is_action_just_pressed("skipCutscene") and !skipped):
		skipped = true
		skipColorRect.show()
		$motodia.stop()
		$Misunderstanding.stop()
		$caramel.stop()

	if (skipped):
		goToNextSceneTimer -= delta
		if (goToNextSceneTimer <= 0):
			get_tree().change_scene_to_file("res://stages/level1.tscn")

	if (!skipped):
		if (cutsceneStep == 1):
			if ($motodia.get_playback_position() < 5.14):
				$CanvasLayer/RichTextLabel.modulate.a = lerp($CanvasLayer/RichTextLabel.modulate.a, 1.0, (0.03 * 60) * delta)
		
			if ($motodia.get_playback_position() >= 5.14):
				$CanvasLayer/RichTextLabel.modulate.a = lerp($CanvasLayer/RichTextLabel.modulate.a, 0.0, (0.08 * 60) * delta)

			if ($motodia.get_playback_position() >= 6.85):
				cutsceneStep += 1
				$CanvasLayer/RichTextLabel.text = "[center]Desafortunadamente... Todo se volvió una pesadilla en un abrir y cerrar de ojos...[/center]"			

		if (cutsceneStep == 2):
			if ($motodia.get_playback_position() >= 11.14):
				$CanvasLayer/ColorRect.modulate.a -= (0.02 * 60) * delta
				$CanvasLayer/RichTextLabel.modulate.a -= (0.008 * 60) * delta
			else:
				$CanvasLayer/RichTextLabel.modulate.a = lerp($CanvasLayer/RichTextLabel.modulate.a, 1.0, (0.03 * 60) * delta)
			if ($motodia.get_playback_position() >= 13.71):
				if ($Camera2D.position.y < 656):
					$Camera2D.position.y += (2 * 60) * delta
			if ($motodia.get_playback_position() >= 13.71 and $motodia.get_playback_position() < 18.00):
				$CanvasLayer/SprLogo.modulate.a = lerp($CanvasLayer/SprLogo.modulate.a, 1.0, (0.03 * 60) * delta)
			if ($motodia.get_playback_position() >= 18.00):
				$CanvasLayer/SprLogo.modulate.a = lerp($CanvasLayer/SprLogo.modulate.a, 0.0, (0.03 * 60) * delta)
			if ($motodia.get_playback_position() >= 24.00):
				cutsceneStep += 1
		if (cutsceneStep == 3):
			spawnDialogue(true, "res://dialog/dialog_introCutscene.json")
			cutsceneStep += 1
		if (cutsceneStep == 5):
			$CanvasLayer/ColorRect.modulate.a = lerp($CanvasLayer/ColorRect.modulate.a, 1.0, (0.05 * 60) * get_process_delta_time())
			$motodia.volume_db -= (0.35 * 60) * delta
			if ($Timer.is_stopped()):
				$Timer.start()
		if (cutsceneStep == 6):
			cutsceneStep += 1
			$Camera2D.position.y -= 900
			$AnimatedSprite2D.visible = false
			$SprIntroCutsceneBack.visible = false
			$Caramel.visible = true
			$Caramel.position.y -= 400
			$motodia.stop()
			$caramel.play()
		if (cutsceneStep >= 7 and cutsceneStep <= 10):
			moveBackground()
		if (cutsceneStep == 7):
			if ($Timer.is_stopped()):
				$Timer.start()
		if (cutsceneStep == 8):
			spawnDialogue(true, "res://dialog/dialog_introCaramel.json")
			cutsceneStep += 1
		if (cutsceneStep == 10):
			if ($Timer.is_stopped()):
				$Timer.start()
			$Caramel.position.x -= (8 * 60) * delta
			$Caramel.position.y += (8 * 60) * delta
			$caramel.volume_db -= (0.5 * 60) * delta
		if (cutsceneStep == 11):
			if ($Camera2D.position.y >= 598):
				cutsceneStep += 1
				$Caramel.scale.x = -2
				$Caramel.global_position = $caramelTeleportMarker.global_position
			$Camera2D.position.y = lerp($Camera2D.position.y, 600.0, (0.03 * 60) * delta)
		if (cutsceneStep == 12):
			if ($Caramel.position.y < $pantcakeMarker.position.y):
				$Caramel.position.x += (10 * 60) * delta
				$Caramel.position.y += (11 * 60) * delta
			else:
				cutsceneStep += 1
				$AnimationPlayer.play("sheStoleThePantcakeNoWay")
		if (cutsceneStep == 14):
			$Caramel.position.x += (10 * 60) * delta
			$Caramel.position.y -= (11 * 60) * delta
			$CanvasLayer/IntrocutsceneImg.modulate.a = lerp($CanvasLayer/IntrocutsceneImg.modulate.a, 0.0, (0.2 * 60) * delta)
		if (cutsceneStep == 16):
			if ($idlewait.is_stopped()):
				$idlewait.start()
			$Shura.position.x += (8 * 60) * delta
		if (cutsceneStep == 17):
			if ($Shura.get_animation() != "jump"):
				$Shura.play("jump")
				$genericTimer.start()
			$Shura.position.x += (5 * 60) * delta
			$Shura.position.y -= (11 * 60) * delta
		if (cutsceneStep == 18):
			if ($genericTimer.is_stopped()):
				$genericTimer.start()
		if (cutsceneStep == 19):
			$Shura.position.x -= (9 * 60) * delta
			$Shura.position.y += (16 * 60) * delta
			if ($Shura.position.y >= 612):
				$Shura.position.y = 612
				$Shura.play("Rip")
				$Shura/Fire.visible = false
				cutsceneStep += 1
		if (cutsceneStep == 20):
			$Shura.position.x -= (10 * 60) * delta
		if (cutsceneStep == 22):
			$Shura.position.x += (8 * 60) * delta
			$CanvasLayer/ColorRect.modulate.a += (0.02 * 30) * delta

func moveBackground():
	var delta = get_process_delta_time()
	$CanvasLayer/ParallaxBackground4/ParallaxLayer.motion_offset.x += (0.1 * 100) * delta
	$CanvasLayer/ParallaxBackground3/ParallaxLayer.motion_offset.x += (0.3 * 100) * delta
	$CanvasLayer/ParallaxBackground2/ParallaxLayer.motion_offset.x += (0.7 * 100) * delta
	$CanvasLayer/ColorRect.modulate.a = lerp($CanvasLayer/ColorRect.modulate.a, 0.0, (0.05 * 60) * delta)

func spawnDialogue(isCutscene, path):
	var dialogueInstance = dialogueScene.instantiate()
	dialogueInstance.dialogPath = path
	add_child(dialogueInstance)
	if (isCutscene):
		dialogueInstance.isCutsceneDialogue = true
	else:
		dialogueInstance.isNpcDialogue = true

func goToCaramelSection(_anything):
	if !(skipped):
		$CanvasLayer/ColorRect.modulate.a = 0
		cutsceneStep += 1

func animChange():
	if !(skipped):
		$Timer.wait_time = 1.5
		$Caramel.play("found")

func _on_timer_timeout():
	if !(skipped):
		if (cutsceneStep == 10):
			$AnimatedSprite2D.visible = true
			$SprIntroCutsceneBack.visible = true
			$caramel.stop()
			$Misunderstanding.play()
		cutsceneStep += 1
		$Timer.wait_time = 3.5
		if (prepareSceneSwitch):
			get_tree().change_scene_to_file("res://stages/level1.tscn")

func _on_misunderstanding_finished():
	if !(skipped):
		prepareSceneSwitch = true
		$Timer.start()


func _on_animation_player_animation_finished(anim_name):
	if !(skipped):
		if (anim_name == "sheStoleThePantcakeNoWay"):
			$Caramel.play("runaway")
			$AnimatedSprite2D.play("empty")
			$Shura.play("surprised")
			cutsceneStep += 1

func _on_shura_animation_finished():
	if !(skipped):
		if ($Shura.get_animation() == "surprised"):
			$AngryTrigger.play()
			$Shura/Fire.visible = true
			$idlewait.start()
			$Shura.play("idle")
			cutsceneStep += 1
		if ($Shura.get_animation() == "gettingUp"):
			$Shura/Fire.visible = true
			$Shura/Fire.rotation_degrees = 0
			$AngryTrigger.play()
			$Shura.play("Run")
			cutsceneStep += 1
		if ($Shura.get_animation() == "Rip"):
			$Shura.play("gettingUp")

func _on_idlewait_timeout():
	if !(skipped):
		$Shura.play("Run")
		if (cutsceneStep == 16):
			$Shura/Fire.rotation_degrees = -45
			$JumpBig.play()
		cutsceneStep += 1

func _on_generic_timer_timeout():
	if !(skipped):
		if (cutsceneStep == 17):
			$Shura/Fire.visible = false
			$AtckGrunt3.play()
		if (cutsceneStep == 18):
			$lasersfx.play()
			$Laser.play("LaserShoot")
			$Shura.play("Launched")
			$Shura.global_position = $ShuraHitMarker.global_position
		cutsceneStep += 1


func _on_tree_col_area_entered(area):
	if !(skipped):
		if (area.name == "Area2D2"):
			cutsceneStep += 1
