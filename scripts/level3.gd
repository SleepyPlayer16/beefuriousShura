extends Node2D

var rainTransparency = 0.3333
var songHasChanged = false
var ilumValue = 0.18
var globalLightEnergy = 0.35
var runTimer = false
var bossIntroTimer = 1
var firedBossIntro = false

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
	Conductor.curScene = "level3"
	SaveDataManager.data["game_data"]["level3_unlocked"] = true
	SaveDataManager.save_data(SaveDataManager.data)
	Conductor.resetEVERYTHINGGGGG()
	Conductor.songToGet("level3")
	thunder.thunderSignal.connect(thunderLightFlash)
	CutsceneHandler.cutsceneDialogueEndedSignal.connect(bossPreparationTrigger)
#	Conductor.songReset()
	DiscordRPC.state = "Nivel 3"
	DiscordRPC.refresh()

func _process(delta):
	if (runTimer):
		bossIntroTimer -= delta
	if (bossIntroTimer <= 0 and !firedBossIntro):
		Conductor.currSection = 0
		firedBossIntro = true
		Conductor.highTensionSong.stop()
		Conductor.songReset()
		get_tree().change_scene_to_file("res://scenes/finalB_tstScn.tscn")
		
		#Conductor.loopSongReload()
		
	
	if (songHasChanged):
		if cloudsOne.visible:
			cloudsOne.visible = false
			cloudsTwo.visible = false
			rainBack.visible = false
		rainTransparency = lerp (rainTransparency, 0.0, (0.03 * 60) * delta)
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

func _on_song_change_trigger_body_entered(body):
	if (body.name == "player"):
		if (!songHasChanged):
			songHasChanged = true
			Conductor.goToNextSection = true
			DiscordRPC.state = "Nivel 3 - Sección 2"
			DiscordRPC.refresh()
