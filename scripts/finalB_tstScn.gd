extends Node2D

var rainTransparency = 0.3333
var songHasChanged = true
var ilumValue = 0.18
var globalLightEnergy = 0.35
var runTimer = false
var bossIntroTimer = 1
var firedBossIntro = false
var introDone = false
var bossDefeated = false
var caramelDed = false
var preVirusCutscene = false
var secondDiagTrigger = false
var triggerLvlChange = false
var lvlEscapeTimer = 2.5
var side = "center"

@onready var bossHP = $CanvasLayer2/caramelHP
@onready var shuraPosMarker = $shuraFightBeginMarker
@onready var caramelPosMarker = $caramelFightBeginMarker

@onready var thunder = $Backs/Thunderrrr/ParallaxLayer/thunder
@onready var darkEffect = $Backs/ParallaxBackground9/ParallaxLayer/DarkEffect
@onready var globalIlum = $DirectionalLight2D
@onready var cloudsOne = $Backs/ParallaxBackground5/ParallaxLayer
@onready var cloudsTwo = $Backs/ParallaxBackground6/ParallaxLayer

@onready var player = $player
@onready var vsScreen = preload("res://scenes/hud/vsScreen.tscn")
@onready var rainBack = $Backs/RainBack
@onready var dialogueScene = preload("res://scenes/hud/dialogue_handler.tscn")
@onready var pantcake = $Pantcake
@onready var pantcakeTrigger = $pantcakeCutsceneTrigger/CollisionShape2D
@onready var pantCol = $RightwALL/CollisionShape2D
@onready var whiteFade = $CanvasLayer2/whiteFade
@onready var zombieCaramel = $ZombieCaramel
@onready var caramelSpeechTimer = $CanvasLayer2/CaramelSpeech/Timer

func _ready():
	SaveDataManager.data["game_data"]["finalBoss_unlocked"] = true
	Conductor.curScene = "finalB_tstScn"
	thunder.thunderSignal.connect(thunderLightFlash)
	CutsceneHandler.cutsceneDialogueEndedSignal.connect(bossPreparationTrigger)
	Conductor.resetEVERYTHINGGGGG()
	
	if (FinalBossManager.bossDefeated):
		CutsceneHandler.inCutscene = false
		player.inBossFight = false
		player.hudHpBar.visible = false
		player.epicArrow.play("Go")
		bossHP.hide()
		Conductor.resetEVERYTHINGGGGG()
		Conductor.songToGet("finalB_tstScn")
		songHasChanged = false
		pantcakeTrigger.set_deferred("disabled", false)
		Conductor.volume_db = -80
		$SprHiveBack3.visible = true
		pantcake.play("free")
		darkEffect.visible = true
		$SprHiveBack.visible = false
	else:
		Conductor.songToGet("finalB_tstScn")
	
	if (FinalBossManager.lastPhase == 2) and !FinalBossManager.bossDefeated:
		bossHP.frame += 1
		CutsceneHandler.inCutscene = true
	if (!FinalBossManager.bossDefeated):
		player.hudLifeBar.visible = true

func _process(delta):
	if (!FinalBossManager.bossDefeated):
		if (!player.hudLifeBar.visible and !caramelDed):
			if (!CutsceneHandler.inCutscene):
				player.hudLifeBar.visible = true

		if (caramelDed and player.hudLifeBar.visible):
			player.hudLifeBar.visible = false

	if (caramelDed):
		if (pantcakeTrigger.disabled):
			pantcakeTrigger.set_deferred("disabled", false)

	if (triggerLvlChange):
		lvlEscapeTimer -= delta
		if (lvlEscapeTimer <= 0):
			FinalBossManager.introPlayed = false
			FinalBossManager.bossDefeated = false
			FinalBossManager.lastPhase = 1
			FinalBossManager.truePhase = 1
			Conductor.resetEVERYTHINGGGGG()
			Conductor.songReset()
			Conductor.songUnload()
			Conductor.shouldLoop = true
			get_tree().change_scene_to_file("res://stages/level4.tscn")

	if (!FinalBossManager.introPlayed):
		CutsceneHandler.inCutscene = true
	else:
		if (!introDone):
			introDone = true
			if (FinalBossManager.lastPhase == 1):
				CutsceneHandler.inCutscene = false

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
		if cloudsOne.visible:
			cloudsOne.visible = false
			cloudsTwo.visible = false
	else:
		if !cloudsOne.visible:
			cloudsOne.visible = true
			cloudsTwo.visible = true
			darkEffect.visible = true
			$SprHiveBack.visible = false
			$SprHiveBack3.visible = true

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
	dialogueInstance.dialogPath = "res://dialog/dialog_finalBossLvlShuraPantcake.json"
	add_child(dialogueInstance)
	if (isCutscene):
		dialogueInstance.isCutsceneDialogue = true
	else:
		dialogueInstance.isNpcDialogue = true

func thunderLightFlash():
	if !songHasChanged:
		ilumValue = 0.0
		globalLightEnergy = 0.2
		
func arenaTeleport():
	player.camera.position_smoothing_enabled = false
	player.camera.offset.x = 0
	player.camera.offset.y = -70
	player.position = $shuraFightBeginMarker.position
	get_node("caramel").position = $caramelFightBeginMarker.position

func bossPreparationTrigger(_speedMultiplier):
	if (!secondDiagTrigger):
		player.cutsceneSpecificTimer = 3
		player.cutsceneStep += 1
	else:
		triggerLvlChange = true

func spawnVsScreen():
	var vsScreenInstance = vsScreen.instantiate()
	vsScreenInstance.boss = 2
	add_child(vsScreenInstance)

func _on_song_change_trigger_body_entered(body):
	if (body.name == "player"):
		if (!songHasChanged):
			songHasChanged = true
			Conductor.goToNextSection = true


func _on_pantcake_cutscene_trigger_body_entered(body):
	if (body.name == "player"):
		pantCol.set_deferred("disabled", true)
		bossDefeated = true
		CutsceneHandler.inCutscene = true

func _on_left_side_body_entered(body):
	if (body.name == "player"):
		side = "left"

func _on_right_side_body_entered(body):
	if (body.name == "player"):
		side = "right"

func _on_right_side_body_exited(body):
	if (body.name == "player"):
		side = "center"

func _on_left_side_body_exited(body):
	if (body.name == "player"):
		side = "center"
