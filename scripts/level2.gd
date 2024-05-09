extends Node2D

var shouldSpawnSecondBoss = false
var timer = 0.4
var pillarsMoving = false
var anticipateVSScreen = false
var reAdjustCam = false
var talkedToKaru = false
var pillarMoveSpeedMultiplier = 1
var start_pos = null
var stopExe = false
var moveTheGODDAMNCAMERAGODFUCKINGDAMMIT = false
var soundhasplayed = false
var songPlayin = false
var timerr = 1
var encounterCutscenePlayed = false
var showStarted = false
var entered_abandonedHouse = false
var originalAudioVolume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
var miniChuwa_apparition = false
var canTeleport = true
var inYukineCutscene = false
var talkedToYukine = false
var cutsceneStep = 0
var cutsceneTimer = 0.0


@onready var rosaBoss = preload("res://scenes/bosses/rosa.tscn")
@onready var celesteBoss = preload("res://scenes/bosses/celeste.tscn")
@onready var dialogueScene = preload("res://scenes/hud/dialogue_handler.tscn")
@onready var bossTheme = preload("res://music/mus_lasCreaturas.ogg")
@onready var vsScreen = preload("res://scenes/hud/vsScreen.tscn")
@onready var rosaSpawnMarker = $RosaSpawnMarker
@onready var celesteSpawnMarker = $CelecesteSpawnMarker
@onready var stadiumPillars = $StadiumPillars
@onready var stadiumPillarMoveSfx = $PillarMove
@onready var stadiumPillarClickSfx = $PillarClick
@onready var cam = $Camera2D
@onready var player = $player/Smoothing2D/Camera2D #why the fuck did i name this player?
@onready var realPlayer = $player
@onready var bossHP = $CanvasLayer2/creatureHP
@onready var colLimit = $StadiumPillars/nopeUcannotGoOut
@onready var anticipationTimer = 1
@onready var boombox = $AnimatedSprite2D
@onready var tpTimer = $TpTimer
@onready var fist1 = $Fist
@onready var fist2 = $Fist2

var rng = RandomNumberGenerator.new()

func _ready():
	SaveDataManager.data["game_data"]["level2_unlocked"] = true
	SaveDataManager.save_data(SaveDataManager.data)
	Conductor.curScene = "level2"
	Conductor.resetEVERYTHINGGGGG()
	Conductor.songToGet("level2")
	start_pos = cam.offset
	CutsceneHandler.cutsceneDialogueEndedSignal.connect(bossArenaPreparationTrigger)
	CutsceneHandler.cutsceneDialogueEndedSignal.connect(yukineCutsceneDialogueEnd)
	Conductor.beatSignalBPM.connect(playBoombox)
	originalAudioVolume = Conductor.volume_db
	DiscordRPC.state = "Nivel 2"
	DiscordRPC.refresh()

func _process(delta):
#	print(cam.position.x)
	if (miniChuwa_apparition):
		$SprMiniChuwa.position.x -= (10 * 60) * delta
	if (inYukineCutscene):
		if (cutsceneStep == 0):
			if (realPlayer.is_on_floor()):
				if (realPlayer.playerSprite.get_animation() != "Idle"):
					realPlayer.playerSprite.scale.x = 1
					realPlayer.state = realPlayer.states.IDLE
					realPlayer.playerSprite.play("Idle")
			cutsceneTimer += delta
			if (cutsceneTimer >= 3 ):
				cutsceneStep += 1
				cutsceneTimer = 0
				$"evil_laugh".play()
				$EvilDude.play("Laugh")
		if (cutsceneStep == 1):
			cutsceneTimer += delta
			if (cutsceneTimer >= 2 ):
				cutsceneTimer = 0
				cutsceneStep += 1
				realPlayer.playerSprite.play("IdleAngry")
				realPlayer.emotionEffects.currentEmotion = realPlayer.emotionEffects.emotions.ANGRY
				realPlayer.emotionPowerActive = true
				realPlayer.angrySfx.play()
				realPlayer.angry = true
				realPlayer.afterImageTimer.start()
				realPlayer.angry_boost = realPlayer.speedBoost
				realPlayer.jumpBoost = realPlayer.speedBoost / 2.5
				realPlayer.emotionEffects.active = true
		if (cutsceneStep == 2):
			cutsceneTimer += delta
			if (cutsceneTimer >= 2 ):
				cutsceneStep += 1
				spawnDialogue(true)
		if (cutsceneStep == 4):
			cutsceneTimer += delta
			if (cutsceneTimer >= 1.5):
				realPlayer.velocity.x = 400
				realPlayer.velocity.y = -265
				realPlayer.jumpSfx.play()
				realPlayer.playerSprite.play("Kick")
				cutsceneStep += 1
				cutsceneTimer = 0
		if (cutsceneStep == 6):
			if (realPlayer.is_on_floor()):
				cutsceneStep += 1
			realPlayer.velocity.x = -100
			if ($EvilDude.get_animation() != "GotHit"):
				$EvilDude.play("GotHit")
				Engine.time_scale = 0.2
			await get_tree().create_timer(0.1).timeout
			Engine.time_scale = 1

		if (cutsceneStep == 7):
			cutsceneTimer = 0
			realPlayer.velocity.x = 0
			realPlayer.playerSprite.play("Idle")
			realPlayer.turnEmotionOff()
			realPlayer.disableAll(get_physics_process_delta_time())
			cutsceneStep += 1
		if (cutsceneStep == 8):
			
			cutsceneTimer += delta
			if (cutsceneTimer >= 1):
				cutsceneTimer = 0
				cutsceneStep += 1
				realPlayer.explosionSfx.play()
				$EvilDude.play("Kill")
				$evil_scream.play()
				$EvilDudeHurtbox/CollisionShape2D.set_deferred("disabled", true)
				$Area2D/CollisionShape2D.set_deferred("disabled", true)
				realPlayer.stopCameraOffset = true
		if (cutsceneStep == 9):
			cutsceneTimer += delta
			if (cutsceneTimer >= 4):
				realPlayer.talking = false
				CutsceneHandler.inCutscene = false
				inYukineCutscene = false
				realPlayer.inYukineCutscene = false
				realPlayer.stopCameraOffset = false
				realPlayer.camera.offset.x = 0.0
				$MiniChuwaTrigger/CollisionShape2D.set_deferred("disabled", false)
				$SprMiniChuwa.visible = true
			if (cutsceneTimer >= 2):
				realPlayer.camera.offset.x = lerp(realPlayer.camera.offset.x, 0.0, (0.05 * 60) * delta)

	if (entered_abandonedHouse):
		Conductor.volume_db = -80
		if (inYukineCutscene):
			$just_in_time.volume_db -= (0.5 * 60) * delta
			
		if (!$just_in_time.playing):
			AudioServer.set_bus_effect_enabled(2, 0, true)
			var effect : AudioEffectReverb = AudioServer.get_bus_effect(2, 0)
			effect.room_size = 0.5
			effect.wet  = 0.15
			$just_in_time.play()
	else:
		$just_in_time.stop()
		AudioServer.set_bus_effect_enabled(2, 0, false)
		if (!CutsceneHandler.inCutscene):
			Conductor.volume_db = lerp(Conductor.volume_db, float(originalAudioVolume), (0.2 * 60) * delta)
	if moveTheGODDAMNCAMERAGODFUCKINGDAMMIT:
#		cam.position.x = lerp(cam.position.x, 13311.0, ((0.01 * pillarMoveSpeedMultiplier) * delta) )
#		cam.position.y = lerp(cam.position.y, 360.0, ((0.01 * pillarMoveSpeedMultiplier) * delta) )
		cam.position.x = lerp(cam.position.x, 13311.0, (0.08 * 60) * delta)
		cam.position.y = lerp(cam.position.y, 360.0, (0.08 * 60) * delta)
	if CutsceneHandler.bossPhase != 2:
		if (shouldSpawnSecondBoss):
			timer -= delta
			if (timer <= 0):
				spawnCelesteBoss()
				shouldSpawnSecondBoss = false
		if (!stopExe):
			if (pillarsMoving):
				shake(0.01, 1)
				if (stadiumPillars.position.y > 2):
					if (player.enabled):
						reAdjustCam = true
						cam.position.x = 13411
						cam.global_position.y = player.global_position.y
						player.enabled = false
						cam.enabled = true
						CutsceneHandler.playerCamActive = false
					
					if (!moveTheGODDAMNCAMERAGODFUCKINGDAMMIT):
#						print("jijiji toy loco jiji toi desquiciao")
						moveTheGODDAMNCAMERAGODFUCKINGDAMMIT = true
					if (!soundhasplayed):
						soundhasplayed = true
						stadiumPillarMoveSfx.play()
					stadiumPillars.position.y -= ((120 * pillarMoveSpeedMultiplier)*delta)

				else:
					if (pillarsMoving):
						pillarsMoving = false
						anticipateVSScreen = true
						stadiumPillarClickSfx.play()
						colLimit.set_deferred("disabled", false)
						stadiumPillarMoveSfx.stop()
						stadiumPillars.position.y += 2
						shake(0.3, 0.6)
					else:
						cam.offset.x = 0
						cam.offset.y = cam.offset.x
		else:
			cam.enabled = false
		if (anticipateVSScreen):
			anticipationTimer -= delta
			if (timer <= 0):
				$cutsceneTrigger/Area2D/CollisionShape2D.set_deferred("disabled", true)
				anticipateVSScreen = false
				spawnVsScreen()
				CutsceneHandler.arenaPreparation = false
				CutsceneHandler.snowCutscene = false
				Conductor.signature = 4
				Conductor.songUnload()
				Conductor.volume_db = 0
				Conductor.songToLoad(130, -4, load("res://music/mus_lasCreaturas.ogg"))


func spawnBoss():
	SaveDataManager.data["game_data"]["creaturas_unlocked"] = true
	shouldSpawnSecondBoss = true
	var rosaInstance = rosaBoss.instantiate()
	rosaInstance.global_position = rosaSpawnMarker.global_position
	call_deferred("add_child", rosaInstance)
	$Fist.parent = rosaInstance
	
func shake(duration: float, amplitude: float):
	reAdjustCam = false
	var timerS = get_tree().create_timer(duration)
	while timerS.time_left > 0:
		cam.offset = start_pos + Vector2(randf_range(floor(-amplitude), floor(amplitude)), randf_range(floor(-amplitude), floor(amplitude)))
		await(get_tree().process_frame)

func yukineCutsceneDialogueEnd(_bitch):
	if (inYukineCutscene):
		cutsceneStep += 1

func bossArenaPreparationTrigger(speedMultiplier):
	if (!inYukineCutscene):
		pillarsMoving = true
		pillarMoveSpeedMultiplier = speedMultiplier
		if CutsceneHandler.bossPhase != 2:
			CutsceneHandler.arenaPreparationFunc()
			CutsceneHandler.volumeTimer = 3

func spawnCelesteBoss():
	var celesteInstance = celesteBoss.instantiate()
	celesteInstance.global_position = celesteSpawnMarker.global_position
	add_child(celesteInstance)
	$Fist2.parent = celesteInstance
	
func spawnVsScreen():
	var vsScreenInstance = vsScreen.instantiate()
	DiscordRPC.state = "Nivel 2 - Jefe"
	DiscordRPC.refresh()
	fist1.show()
	fist1.canBeActivated = true
	fist2.show()
	add_child(vsScreenInstance)

func spawnDialogue(isCutscene):
	showStarted = true
	var dialogueInstance = dialogueScene.instantiate()
	if (!inYukineCutscene):
		dialogueInstance.dialogPath = "res://dialog/dialog_snowLvl.json"
	else:
		dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlShura.json"
	add_child(dialogueInstance)
	if (isCutscene):
		dialogueInstance.isCutsceneDialogue = true
	else:
		dialogueInstance.isNpcDialogue = true

func playBoombox():
	if (showStarted):
		$AnimatedSprite2D.frame = 0
		$AnimatedSprite2D.play("On")

func spawnBossKillDialogue(isCutscene):
	showStarted = false
	CutsceneHandler.lastCheckpoint = null
	CutsceneHandler.playerContinued = false	
	$StadiumPillars/CollisionShape2D.set_deferred("disabled", true)
	$StadiumPillars/CollisionShape2D2.set_deferred("disabled", true)
	var dialogueInstance = dialogueScene.instantiate()
	dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlBossKill.json"
	add_child(dialogueInstance)
	if (isCutscene):
		dialogueInstance.isCutsceneDialogue = true
	else:
		dialogueInstance.isNpcDialogue = true	


func _on_tp_timer_timeout():
	canTeleport = true

func _on_area_2d_body_entered(body):
	if (body.name == "player"):
		realPlayer.velocity.x = 0
		realPlayer.turnEmotionOff()
		realPlayer.disableAll(get_physics_process_delta_time())
		realPlayer.dir = 1
		realPlayer.emotionEffects.dir = 1
		realPlayer.playerSprite.scale.x = 1
		realPlayer.hudHpBar.value = 100
		realPlayer.talking = true
		inYukineCutscene = true 
		realPlayer.inYukineCutscene = true
		CutsceneHandler.inCutscene = true

func _on_evil_dude_hurtbox_body_entered(body):
	if (body.name == "player"):
		realPlayer.shake(0.3, 0.6)
		realPlayer.velocity.y = -315
		realPlayer.camera.zoom.x = 4
		realPlayer.camera.zoom.y = 4
		realPlayer.floorSplatSfx.play()
		cutsceneStep += 1


func _on_mini_chuwa_trigger_body_entered(body):
	if (body.name == "player"):
		miniChuwa_apparition = true
		$minichuwaLaugh.play()
		$MiniChuwaTrigger/CollisionShape2D.call_deferred("set_disabled", true)
