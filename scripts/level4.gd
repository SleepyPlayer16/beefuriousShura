extends Node2D

var rainTransparency = 0.3333
var songHasChanged = true
var ilumValue = 0.18
var globalLightEnergy = 0.35
var runTimer = false
var bossIntroTimer = 1
var timeElapsed = 270
var firedBossIntro = false
var playerLost = false
var talkedToKaru = false

@onready var thunder = $CanvasLayer/Thunderrrr/ParallaxLayer/thunder
@onready var darkEffect = $CanvasLayer/ParallaxBackground9/ParallaxLayer/DarkEffect
@onready var globalIlum = $DirectionalLight2D
@onready var cloudsOne = $CanvasLayer/ParallaxBackground5/ParallaxLayer
@onready var cloudsTwo = $CanvasLayer/ParallaxBackground6/ParallaxLayer
@onready var player = $player
@onready var vsScreen = preload("res://scenes/hud/vsScreen.tscn")
@onready var rainFront = $CanvasLayer/RainFront/ParallaxLayer/ColorRect
@onready var rainBack = $CanvasLayer/RainBack
@onready var dialogueScene = preload("res://scenes/hud/dialogue_handler.tscn")
@onready var bossHP = $caramelHP


func _ready():
	GameDataManager.levelCleared = false
	SaveDataManager.data["game_data"]["level4_unlocked"] = true
	Conductor.curScene = "level4"
	CutsceneHandler.resetAll()
	Conductor.shouldLoop = true
	Conductor.curScene = get_tree().current_scene.name
	FinalBossManager.introPlayed = false
	FinalBossManager.bossDefeated = false
	FinalBossManager.lastPhase = 1
	FinalBossManager.truePhase = 1
	
	SaveDataManager.data["game_data"]["level3_unlocked"] = true
	SaveDataManager.save_data(SaveDataManager.data)
	Conductor.resetEVERYTHINGGGGG()
	Conductor.songToGet("level4")
	Conductor.volume_db = -2
	Conductor.beatSignalBPM.connect(timerDeduct)
	thunder.thunderSignal.connect(thunderLightFlash)
	CutsceneHandler.cutsceneDialogueEndedSignal.connect(bossPreparationTrigger)
#	Conductor.songReset()
	GameDataManager.emit_signal("debrisSignal")
	$Quake.play()
	if (GameDataManager.deaths >= 2 and GameDataManager.deaths < 4): # a lil' help
		timeElapsed = 360
	if (GameDataManager.deaths >= 4): #come on bro u can do it
		timeElapsed = 450
	if (GameDataManager.deaths >= 6): #u WILL finish this level no matter how bad u are at the game
		timeElapsed = 900
	DiscordRPC.state = "Nivel 4"
	DiscordRPC.refresh()
	if (!Conductor.playing):
		Conductor.play()
		Conductor.volume_db = -2

func _process(delta):
	if (timeElapsed < 0 and !playerLost):
		playerLost = true
		Conductor.volume_db = -80
		Conductor.resetEVERYTHINGGGGG()
		Conductor.songUnload()
		Conductor.shouldLoop = false
		Conductor.stop()
		player.hp = player.maxHP
		$CanvasLayer/RichTextLabel.hide()

	$CanvasLayer/RichTextLabel.text = "[center]" + str(GameDataManager._format_seconds(timeElapsed, false)) + "[/center]"
	if (runTimer):
		bossIntroTimer -= delta
	if (bossIntroTimer <= 0 and !firedBossIntro):
		Conductor.currSection = 0
		firedBossIntro = true
		Conductor.highTensionSong.stop()
		Conductor.songReset()
		spawnVsScreen()
		Conductor.loopSongReload()
	
	if (songHasChanged):
		$CanvasLayer/Thunderrrr.visible = false
		if cloudsOne.visible:
			cloudsOne.visible = false
			cloudsTwo.visible = false
			rainBack.visible = false
		rainTransparency = lerp (rainTransparency, 0.0, (0.03 * 60) * delta)
		rainFront.material.set("shader_parameter/rain_color", Color(0.4549, 0.8902, 0.8235, rainTransparency))
	else:
		$CanvasLayer/Thunderrrr.visible = true
		if cloudsOne.visible:
			cloudsOne.visible = true
			cloudsTwo.visible = true
			rainBack.visible = true
		rainTransparency = lerp (rainTransparency, 0.3, (0.03 * 60) * delta)
		rainFront.material.set("shader_parameter/rain_color", Color(0.4549, 0.8902, 0.8235, rainTransparency))

	cloudsOne.motion_offset.x -= 35*delta
	cloudsTwo.motion_offset.x -= 15*delta


	if (ilumValue != 0.18):
		ilumValue = lerp(ilumValue, 0.18, (0.03*60)*delta)
	darkEffect.color = Color(37,63,65, ilumValue)

	if (globalLightEnergy != 0.35):
		globalLightEnergy = lerp(globalLightEnergy, 0.35, (0.02*60)*delta)
	globalIlum.energy = globalLightEnergy

func spawnDialogue(isCutscene):
	var dialogueInstance = dialogueScene.instantiate()
	dialogueInstance.dialogPath = "res://dialog/dialog_finalBossLvl.json"
	add_child(dialogueInstance)
	if (isCutscene):
		dialogueInstance.isCutsceneDialogue = true
	else:
		dialogueInstance.isNpcDialogue = true

func thunderLightFlash():
	if !songHasChanged:
		ilumValue = 0.0
		globalLightEnergy = 0.2

func timerDeduct():
	if (!GameDataManager.paused):
		if Conductor.currentBeat % 2 == 0 or Conductor.currentBeat == 1 or Conductor.currentBeat == 0:
			if !(player.talking or player.state == player.states.VICTORY):
				timeElapsed -= 1

func arenaTeleport():
	player.camera.position_smoothing_enabled = false
	player.camera.offset.x = 0
	player.camera.offset.y = -70
	player.position = $shuraFightBeginMarker.position
	get_node("caramel").position = $caramelFightBeginMarker.position

func bossPreparationTrigger(_speedMultiplier):
	runTimer = true

func spawnVsScreen():
	var vsScreenInstance = vsScreen.instantiate()
	vsScreenInstance.boss = 2
	add_child(vsScreenInstance)

#func _on_song_change_trigger_body_entered(body):
	#if (body.name == "player"):
		#if (!songHasChanged):
			#songHasChanged = true
			#Conductor.goToNextSection = true

func _on_timer_timeout():
	GameDataManager.emit_signal("debrisSignal")
	if !(player.state == player.states.VICTORY or player.state == player.states.GAMEOVER):
		player.shake(2, 15.6) #gang
		$Quake.play()

func _on_activate_rain_body_entered(body):
	if (body.name == "player"):
		songHasChanged = false
