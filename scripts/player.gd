extends CharacterBody2D


const SPEED = 120.0
const JUMP_VELOCITY = -300.0
const ACCELERATION = 35.0
const DELERATION = 15.0
const GRAVITY = 1100
const MAX_FALLSPEED = 300

var currentlyResetting = false
var current_emotion = emotions.HAPPY
var state = states.IDLE
var lastState = null
var speedBoost = 200
var jumpBoost = 0
var angry_boost = 0
var happy_boost = 0
var emotionPowerActive = false
var angry = false
var happy = false
var sad = false
var pauseEVERY_GO_DAMN_THING = true
var fallTimer = 0
var maxFallTimeAllowed = 0.8
var moveKeyPressed = false
var current_jump = 0
var startedMoving = false
var forcefullyAirborne = false
var max_jumps = 1
var cycle = 0
var lockout = 50 #frames before player can be hit again
var lastHitBy = null #prevents player from getting hit by the same attack multiple times in a row
var hasFallen = false
var onHitstun = false
var dedTimer = 45
var knockback = 0
var checkpointCoords
var justEnteredTheFUCKINGScene = true
var damageMode = damageModes.LEVEL
var talking = false
var invinFrames = 75
var zoomEffect = false
var isInvincible = false
var rng = RandomNumberGenerator.new()
var hp = 0
var maxHP = 7
var steppedLeft = true
var shouldFUCKINGplaythestockexplosionanim = false
var dir = 1
var steppedRight = true
var inBossFight = false
var deathTimerBeforeReset = 3
var originalAudioVolume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
var escapeToTheRight = false
var groundLvl = 0
var playedFadeIn = false
var isShielded = false
var goToNextLevelTimer = 5.5
var niShield = null
var inYukineCutscene = false
var hitCounter = 0 #prevents getting stunlocked if hit too many times in the air
var stopCameraOffset = false
var followSteps = []
var facingSteps = []
var followStepsMaxSize = 30
var shouldChangeOffset = false
var form = ""
var superSpeed = 0.0
var cutsceneStep = 0
var cutsceneSpecificTimer = 1.1
var death = "Normal"
var lostClash = false
var showGameOver = false
var inGameOver = false
var gameOverOption = 0
var gmOptionSelected = false


enum damageModes{
	LEVEL,
	BOSS,
	INVINCIBLE
}

enum states{
	IDLE,
	WALK,
	JUMP,
	FALLING,
	DEATH,
	GAMEOVER,
	HITSTUN,
	GRABBED,
	THROWN,
	VICTORY
}

enum emotions{
	HAPPY,
	ANGRY,
	SAD,
	TERRIFIED,
	UOOGHHH,
	HOPEFUL
}

@onready var shockWaveAnimPlay = $Shockwave/AnimationPlayer
@onready var hudEmotions = $hud/EmotionsTest
@onready var hud = $hud
@onready var hudHpBar = $hud/ProgressBar
@onready var hudLifeBar = $hud/SprShuraHp
@onready var playerSprite = $Smoothing2D/playerSprite
@onready var fireSprite = $Smoothing2D/fireSprite
@onready var camera = $Smoothing2D/Camera2D
@onready var emotionEffects = $Smoothing2D/emotionEffects
@onready var afterImage = preload("res://scenes/afterImage.tscn")
@onready var fren = preload("res://scenes/assists/eru.tscn")
@onready var frenNisha = preload("res://scenes/assists/nisha.tscn")
@onready var frenMeica = preload("res://scenes/assists/meica.tscn")
@onready var happySfx = $HappyTrigger
@onready var angrySfx = $AngryTrigger
@onready var pissedOffSfx = $PissedOffTrigger
@onready var sadSfx = $SadTrigger
@onready var jumpBigSfx = $JumpBig
@onready var jumpSfx = $Jump
@onready var hitDelaySfx = $HitDelay
@onready var stepSfx = $Step
@onready var afterImageTimer = $Timer
@onready var explosionSfx = $Explosion
@onready var fallSfx = $Fall
@onready var floorSplatSfx = $FloorSplat
@onready var sfxSuspense = $Suspense
@onready var sfxTransformation = $Transformation
@onready var portrait = preload("res://sprites/shura/ShuraNormal.png")
@onready var shadow = $Smoothing2D/shadow
@onready var hitEffectManager = preload("res://scenes/FX/HitEffectManager.tscn")
@onready var buttonMash = $hud/buttonMash
@onready var clash_hp = $hud/buttonMashHP
@onready var shakeTimer = $ShakeTimer
@onready var epicArrow = $hud/EpicArrow
@onready var gameOverScreen = $CanvasLayer2/GameOverScreen

@export var initialDir = 1


func _ready():
	followSteps.resize(followStepsMaxSize)
	facingSteps.resize(followStepsMaxSize)
	if (get_tree().current_scene.name == "level2"):
		hp = 0
		hudLifeBar.frame = hp
	Engine.time_scale = 1
	shockWaveAnimPlay.play("RESET")
#	Conductor.volume_db = Conductor.targetVolume
	CutsceneHandler.inCutscene = false
	checkpointCoords = position
#	Conductor.volume_db = 0
	CutsceneHandler.playerCamActive = true
	rng.randomize()
	CutsceneHandler.dialogueEndedSignal.connect(stopTalk)
	CutsceneHandler.cutsceneDialogueEndedSignal.connect(afterBossTriggerCutscene)
	CutsceneHandler.shockWaveSignal.connect(shockWaveEffect)
	Conductor.beatSignalBPM.connect(stepSync)
	Conductor.beatSignalBPMDouble.connect(angyStepSync)
	match (get_tree().current_scene.name):
		"level3":
			CutsceneHandler.inCutscene = true
		"finalB_tstScn":
			inBossFight = true
			hud.visible = true
	if (CutsceneHandler.playerHasDied or CutsceneHandler.playerContinued):
		if (get_tree().current_scene.name != "level4"):
			position = CutsceneHandler.lastCheckpoint
	else:
		CutsceneHandler.lastCheckpoint = position
	groundLvl = global_position.y
	originalAudioVolume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	
	playerSprite.scale.x *= initialDir

func _physics_process(delta):
	if (showGameOver and !$GameOver.playing):
		$GameOver.play()
	if (showGameOver):
		if (gmOptionSelected):
			deathTimerBeforeReset -= (0.04 * 60) * delta
			playerSprite.modulate.a -= (0.05 * 20) * delta
			gameOverScreen.modulate.a -= (0.05 * 20) * delta
			$GameOver.volume_db -= (0.5 * 60) * delta
		
		if (Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")) and !gmOptionSelected:
			Conductor.menuMove.play()
			if (gameOverOption == 0):
				gameOverOption = 1
			else:
				gameOverOption = 0
			gameOverScreen.frame = gameOverOption
		
		if (Input.is_action_just_pressed("ui_select") and !gmOptionSelected):
			gmOptionSelected = true
			Conductor.menuSelect.play()

		if (gameOverScreen.modulate.a < 1 and !gmOptionSelected):
			gameOverScreen.modulate.a = lerp(gameOverScreen.modulate.a, 1.0, (0.05 * 60) * delta)

	if (clash_hp.value >= 100):
		if (!lostClash):
			$Boom.play()
			death = "Punch"
			playerSprite.scale.x = -1
			shake(1,6)
			camera.zoom.x = 2
			camera.zoom.y = 2
			camera.offset.y = 0
			camera.offset.y = 0
			playerSprite.scale.x = -1
			lostClash = true
			hp = maxHP
			Conductor.resetEVERYTHINGGGGG()
			Conductor.songUnload()
			Conductor.stop()

	if (form == "Super"):
		if (emotionEffects.currentEmotion != emotionEffects.emotions.HOPEFUL):
			fireSprite.play("hopeful")
			$Smoothing2D/emotionEffects.visible = true
			$Smoothing2D/emotionEffects.active = true
			emotionEffects.currentEmotion = emotionEffects.emotions.HOPEFUL
			
		fireSprite.modulate.a = lerp(fireSprite.modulate.a, 0.7, delta*12)
		fireSprite.rotation = (atan2(velocity.y/3, velocity.x))

	if ((velocity.x == 0 or is_on_wall()) and fireSprite.modulate.a != 0):
		
		if (playerSprite.scale.x == -1) and is_on_floor():
			fireSprite.rotation = 3.1416 #piiiiiiiiiiiiiiiiiiiii tinnitus

	if (is_on_floor() and get_tree().current_scene.name == "finalB_tstScn"):
		groundLvl = global_position.y
		
	if (get_tree().current_scene.name == "finalB_tstScn" and get_parent().bossDefeated):
		finalCutscene(delta)

	if (form == "Super"):
		happy_boost = 260
	#if (Input.is_action_just_pressed("dieInstantly")):
		#hp = maxHP
	#if (Input.is_action_just_pressed("reset")):
		#get_tree().call_deferred("reload_current_scene")
		
	if (get_tree().current_scene.name == "level4"):
		stepSave()
#	if (Input.is_action_just_pressed("activateBossFight")):
#		inBossFight = true
	if (lastHitBy != null):
		lockout -= (60*delta)
		if (lockout <= 0):
			lockout = 50
			lastHitBy = null
	if (get_tree().current_scene.name == "finalB_tstScn.tscn"):
		shadow.texture = playerSprite.sprite_frames.get_frame_texture(playerSprite.get_animation(), playerSprite.frame)
		shadow.position.y = ((-position.y + 1) * 2)
		shadow.scale.x = playerSprite.scale.x

	if (forcefullyAirborne):
		current_jump = 2
	if (velocity.y == 0 and forcefullyAirborne and is_on_floor()):
		forcefullyAirborne = false

	if Input.is_action_just_pressed("testSectionChange"):
		Conductor.goToNextSection = true
	vertical_corner_correction(12)
	if (zoomEffect):
		playerSprite.play("WalkAngry")
		if (dir >= 1 or dir <= -1):
			playerSprite.scale.x = dir
		var sfx_index= AudioServer.get_bus_index("Music")
		var vol = lerp(AudioServer.get_bus_volume_db(sfx_index), -25.0, (0.5 * 60) * delta)
		AudioServer.set_bus_volume_db(sfx_index, vol)
		camera.zoom.x = lerp(camera.zoom.x, 4.0, (0.12 * 60) * delta)
		camera.zoom.y = camera.zoom.x
		
	if (camera.zoom.x != 2):
		if (playerSprite.get_animation() != "Clash"):
			var blend = pow(0.6, delta * 8)
			camera.zoom.x = lerp(2.0, camera.zoom.x, blend)
			camera.zoom.y = camera.zoom.x

	if escapeToTheRight:
		$Step.volume_db -= (0.1 * 60) * delta
		if (!playedFadeIn):
			playedFadeIn = true
			$hud/AnimationPlayer.play("fadeIn")
		fireSprite.rotation = (atan2(velocity.y/3, velocity.x))
		hudHpBar.value = 100
		current_emotion = emotions.ANGRY
		emotionPowerActive = true
		angry_boost = speedBoost
		state = states.WALK
		if (playerSprite.get_animation() != "WalkAngry"):
			playerSprite.play("WalkAngry")
		fireSprite.visible = true
		fireSprite.modulate.a = 1
		playerSprite.scale.x = 1
		velocity.x = move_toward(velocity.x, 1 * (SPEED + angry_boost), ACCELERATION)
#	print(states.keys()[state])
	if CutsceneHandler.inCutscene:
		if is_on_floor():
			match (get_tree().current_scene.name):
				"level2":
					if (!inYukineCutscene):
						if (state == states.IDLE):
							playerSprite.play("Idle" + form)
						if !(get_parent().encounterCutscenePlayed):
							playerSprite.scale.x = 1
							get_parent().encounterCutscenePlayed = true
							if (playerSprite.get_animation() != "Idle" + form):
								playerSprite.play("Idle" + form)
						if zoomEffect == false:
							moveCameraByAmount(100, 0, 100)
						turnEmotionOff()
						inBossFight = true
						hud.inBossFight = inBossFight
					else:
						if zoomEffect == false:
							if (!stopCameraOffset):
								moveCameraByAmount(100, 0, 100)

				"level3":
					if (CutsceneHandler.bossPhase == 1):
						if (playerSprite.get_animation() != "Idle" + form):
							playerSprite.play("Idle" + form)
						if zoomEffect == false:
							moveCameraByAmount(190, -50, 100)
						turnEmotionOff()
						inBossFight = true
					if CutsceneHandler.bossPhase == 0:
						CutsceneHandler.inCutscene = false

	if (get_tree().current_scene.name == "finalB_tstScn" and playerSprite.get_animation() != "Clash"):
		if (!forcefullyAirborne):
			if (camera.offset.y != -50):
				camera.offset.y = lerp(camera.offset.y, -50.0, (0.08*60)*delta)
		else:
#			print("what the FUCKKKKKK")
			if (camera.offset.y != 0):
				camera.offset.y = lerp(camera.offset.y, 50.0, (0.08*60)*delta)

#	if (Input.is_action_just_pressed("reset")):
#		Conductor.songReset()
#		get_tree().reload_current_scene()
	if (hitCounter >= 2):
		playerSprite.modulate.a = 0.65

	if (is_on_floor() and onHitstun):
		onHitstun = false
		if (hitCounter != 0):
			hitCounter = 0
			playerSprite.modulate.a = 1
		state = states.IDLE
		isInvincible = true
		
	if (isInvincible):
		
		invinFrames -= 60 * delta
		var curFrame = fmod(invinFrames, 12)
		if (!CutsceneHandler.inCutscene):
			playerSprite.modulate.a = 0.8
			if (curFrame == 0):
				if (playerSprite.visible):
					playerSprite.visible = false
				else:
					playerSprite.visible = true
		else:
			if (!playerSprite.visible):
				playerSprite.modulate.a = 1
				playerSprite.visible = true
		if invinFrames <= 0:
			isInvincible = false
			playerSprite.visible = true
			playerSprite.modulate.a = 1
			invinFrames = 75
	
	if hp == maxHP:
		if !(state == states.GAMEOVER or state == states.VICTORY):
			if (niShield != null):
				niShield.forceBreak()
			hud.visible = false
			get_parent().bossHP.visible = false
			playerSprite.speed_scale = 1.5
			$Smoothing2D/emotionEffects.visible = false
			Engine.time_scale = 1
			playerSprite.visible = true
			playerSprite.modulate.a = 1
			state = states.GAMEOVER
			CutsceneHandler.shouldSkipCutscene = true
	
	if (state == states.VICTORY):
		velocity.x = move_toward(velocity.x, 0.0, (14*60)*delta)
		hud.visible = true
		CutsceneHandler.inCutscene = true
		if (is_on_floor()):
			if (shouldChangeOffset and playerSprite.offset.y != -14):
				playerSprite.offset.y = -14
			GameDataManager.levelCleared = true
			camera.zoom.x = lerp(camera.zoom.x, 6.0, (0.02*60)*delta)
			camera.zoom.y = camera.zoom.x
			camera.offset.x = lerp(camera.offset.x, -60.0, (0.08*60)*delta)
			if (goToNextLevelTimer > 0):
				goToNextLevelTimer -= delta
			else:
				if ($CanvasLayer2/ColorRect2.modulate.a < 1):
					$CanvasLayer2/ColorRect2.modulate.a += (0.03 * 60) * delta
			if (playerSprite.get_animation() != "Goal"):
				$Shockwave/AnimationPlayer.play("LevelDone")
				turnEmotionOff()
				disableAll(delta)
				emotionPowerActive = false
				playerSprite.play("Goal")

	if (state == states.GAMEOVER):
		if (FinalBossManager.truePhase == 2):
			#print("FUCK YOUUUUUUUUUUUUUUUUUUUUU")
			FinalBossManager.lastPhase = 2
		if (!currentlyResetting):
			currentlyResetting = true
			Conductor.songReset()
		camera.enabled = true
		CutsceneHandler.inCutscene = false
		camera.offset.x = 0
		camera.offset.y = 0
		$ColorRect.z_index = 200
		$CutsceneColorRect.z_index = 591
		playerSprite.z_index = 590
		hitCounter = 0

		if get_tree().current_scene.name == "level2":
			get_parent().stopExe = true
			get_parent().bossHP.visible = false
		CutsceneHandler.playerHasDied = true
		if (deathTimerBeforeReset < -1):
			
			if (get_tree().current_scene.name == "level4"):
				GameDataManager.deaths += 1
			if (gameOverOption == 0):
				get_tree().call_deferred("reload_current_scene")
			else:
				get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")

		Conductor.volume_db = -80
		velocity.y = 0
		velocity.x = 0
		$CollisionShape2D.set_deferred("disabled", true)
		camera.position_smoothing_enabled = false
		if (!inGameOver):
			inGameOver = true
			match(death):
				"Normal":
					playerSprite.play("GameOver")
				"Punch":
					playerSprite.play("GameOverPunch")
				"Thrown":
					playerSprite.play("GameOverThrown")
				"Explosion":
					playerSprite.play("GameOverExplosion")
				"Homerun":
					playerSprite.play("GameOverHomerun")

		$ColorRect.visible = true
	if !(talking or state == states.GAMEOVER or state == states.VICTORY):
		match (state):
			states.THROWN:
				playerSprite.play("FallScared")
				$Smoothing2D/emotionEffects.currentEmotion = null
				$Smoothing2D/emotionEffects.active = true
				disableAll(delta)
				turnEmotionOff()
			states.GRABBED:
				playerSprite.visible = false
				hasFallen = false
				fallTimer = 0
				$Smoothing2D/emotionEffects.currentEmotion = null
				$Smoothing2D/emotionEffects.active = true
				disableAll(delta)
				turnEmotionOff()
			states.HITSTUN:
				hasFallen = false
				fallTimer = 0
				if !(onHitstun):
					$Smoothing2D/emotionEffects.currentEmotion = null
					$Smoothing2D/emotionEffects.active = true
					onHitstun = true
					velocity.y = 0
					velocity.x = 0
					velocity.y -= 300
					velocity.x -= knockback
				disableAll(delta)
				turnEmotionOff()
				playerSprite.play("FallScared")
			states.DEATH:
				playerSprite.speed_scale = 1.5
				$Smoothing2D/emotionEffects.currentEmotion = null
				$Smoothing2D/emotionEffects.active = true
				$Smoothing2D/PointLight2D.visible = false
				turnEmotionOff()
				fireSprite.modulate.a = 0
				velocity.x = 0
				velocity.y = 0
				fallSfx.stop()
				if (!hasFallen):
					playerSprite.play("DedAlt")
				else:
					#esta madre no sirve si no hago esto quien sabe xq alv
					if (is_on_floor()):
						if playerSprite.get_animation() != "Ded":
							playerSprite.play("Ded")
							if (inBossFight):
								if (hp == maxHP-1):
									death = "Thrown"
								hp += 1
								hudLifeBar.frame = hp
						hasFallen = true
					else:
						playerSprite.play("DedAlt")
						
				dedTimer -= (60*delta)
				if dedTimer <= 0:
					fallTimer = 0
					dedTimer = 45
					state = states.IDLE
					hudHpBar.value = 100
					hasFallen = false
					if (!inBossFight):
						position = checkpointCoords
						followSteps.clear()
						facingSteps.clear()
						followSteps.resize(followStepsMaxSize)
						facingSteps.resize(followStepsMaxSize)
						followSteps.push_front(position)
						followSteps.pop_back()
					else:
						isInvincible = true
						state = states.IDLE
						if (!CutsceneHandler.inCutscene):
							playerSprite.play("Idle" + form)
			states.IDLE:
#				print("hello bitches")
				
				if (is_on_floor()):
					fallTimer = 0
					if (!CutsceneHandler.inCutscene):
						if current_emotion == emotions.SAD and emotionPowerActive:
							playerSprite.play("IdleSad")
							print("wtf")
						elif current_emotion == emotions.ANGRY and emotionPowerActive:
							playerSprite.play("IdleAngry")
						else:
							playerSprite.play("Idle" + form)
				else:
					if (current_emotion == emotions.SAD and emotionPowerActive):
						if (velocity.y < 0):
							playerSprite.play("JumpSad")
						else:
							playerSprite.play("FallSad")
					else:
						if (velocity.y < 0):
							playerSprite.play("Jump" + form)
						else:
							playerSprite.play("Fall" + form)
				playerSprite.speed_scale = 1.5
				if (form != "Super"):
					fireSprite.modulate.a = lerp(fireSprite.modulate.a, 0.0, delta*12)
					$Smoothing2D/PointLight2D.visible = false
			states.FALLING:
				disableAll(delta)
				$Smoothing2D/emotionEffects.currentEmotion = null
				$Smoothing2D/emotionEffects.active = true
				if (!hasFallen):
					playerSprite.play("DedAlt")
					playerSprite.play("FallScared")
					hasFallen = true
					fallSfx.play()

				if (is_on_floor()):
					floorSplatSfx.play()
					switchState(state, states.DEATH)
					fallTimer = 0
			states.WALK:
				if (emotionPowerActive):
					if current_emotion == emotions.ANGRY:
	#					var speed_scl = velocity.length() / (SPEED + angry_boost)
	#					playerSprite.speed_scale = speed_scl
						if get_tree().current_scene.name == "level3" or get_tree().current_scene.name == "level4":
							$Smoothing2D/PointLight2D.visible = true
						if !talking:
							fireSprite.modulate.a = lerp(fireSprite.modulate.a, 0.8, delta*12)
						if !(is_on_wall() and is_on_floor()):
							fireSprite.rotation = (atan2(velocity.y/3, velocity.x))
						if (is_on_floor()):
							fallTimer = 0
							playerSprite.play("WalkAngry")
						else:
							if (velocity.y < 0):
								playerSprite.play("JumpAngry")
							else:
								playerSprite.play("FallAngry")
					elif current_emotion == emotions.SAD:
						if (is_on_floor()):
							fallTimer = 0
						else:
							if (velocity.y < 0):
								playerSprite.play("JumpSad")
							else:
								playerSprite.play("FallSad")
					else:
						fireSprite.modulate.a = lerp(fireSprite.modulate.a, 0.0, delta*12)
						$Smoothing2D/PointLight2D.visible = false
						if (is_on_floor()):
							fallTimer = 0
							playerSprite.play("Walk" + form)
						else:
							if (velocity.y < 0):
								playerSprite.play("Jump" + form)
							else:
								playerSprite.play("Fall" + form)
				else:
					if (form != "Super"):
						fireSprite.modulate.a = lerp(fireSprite.modulate.a, 0.0, delta*12)
						$Smoothing2D/PointLight2D.visible = false
					afterImageTimer.stop()
					if (is_on_floor()):
						fallTimer = 0
						
					else:
						if (velocity.y < 0):
							playerSprite.play("Jump" + form)
						else:
							playerSprite.play("Fall" + form)
	else:
		fireSprite.modulate.a = lerp(fireSprite.modulate.a, 0.0, delta*12)

	match (current_emotion):
		emotions.HAPPY:
			switchEmotionFunc(emotions.ANGRY)
			hudEmotions.frame = 0
		emotions.ANGRY:
			switchEmotionFunc(emotions.SAD)
			hudEmotions.frame = 2
		emotions.SAD:
			switchEmotionFunc(emotions.HAPPY)
			hudEmotions.frame = 1

	applyGravity(delta)
	
#	if (Input.is_action_just_pressed("assist")) and damageMode == damageModes.BOSS:
#		instantiateFren()
	if (Engine.time_scale == 1):
		if (inBossFight and !(talking or state == states.DEATH or state == states.GAMEOVER or state == states.VICTORY or  CutsceneHandler.inCutscene)):
			if (Input.is_action_just_pressed("assist") and is_on_floor()):
				if $hud/SprShuraHp/SprEruHudElement.get_animation() == "Full":
					$hud/SprShuraHp/SprEruHudElement.play("Charging")
					instantiateFren("Eru")
			if (Input.is_action_just_pressed("assistNisha")):
				if $hud/SprShuraHp/SprNishaHudElement.get_animation() == "Full":
					$hud/SprShuraHp/SprNishaHudElement.play("Charging")
					instantiateFren("Nisha")

			if (Input.is_action_just_pressed("assistMeica") and is_on_floor()):
				if $hud/SprShuraHp/SprMeicaHudElement.get_animation() == "Full":
					$hud/SprShuraHp/SprMeicaHudElement.play("Charging")
					instantiateFren("Meica")
	if (!inYukineCutscene):
		if (emotionPowerActive and !talking):
			match(current_emotion):
				emotions.HAPPY:
					hudHpBar.value -= 20 * delta
				emotions.SAD:
					hudHpBar.value -= 10 * delta
				emotions.ANGRY:
					hudHpBar.value -= 25 * delta
	
	if (Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right")):
		if !(talking or state == states.DEATH or state == states.GAMEOVER or state == states.VICTORY or !is_on_floor() or onHitstun or CutsceneHandler.inCutscene or state == states.GRABBED or state == states.THROWN):
			cycle = 0
			if (!startedMoving):
				startedMoving = true
			if (!hasFallen):
				if (emotionPowerActive):
					match(current_emotion):
						emotions.HAPPY:
							playerSprite.play("Walk" + form)
						emotions.SAD:
							playerSprite.play("WalkSad")
						emotions.ANGRY:
							playerSprite.play("WalkAngry")
				else:
					playerSprite.play("Walk" + form)
	if !(talking or state == states.DEATH or state == states.GAMEOVER or state == states.VICTORY or state == states.GRABBED or state == states.THROWN or onHitstun or zoomEffect or escapeToTheRight):

		var direction = Input.get_axis("left", "right")
		if (direction == 1 or direction == -1):
			dir = direction
		else: 
			dir = 0
		emotionEffects.dir = direction
		if (direction) and !(CutsceneHandler.inCutscene or state == states.DEATH or hasFallen):
			if (direction > 0):
				playerSprite.scale.x = 1
			else:
				playerSprite.scale.x = -1
			if (is_on_floor()):
				if playerSprite.get_animation().begins_with("Fall"):
					if (emotionPowerActive):
						match(current_emotion):
							emotions.HAPPY:
								playerSprite.play("Walk" + form)
							emotions.SAD:
								playerSprite.play("WalkSad")
							emotions.ANGRY:
								playerSprite.play("WalkAngry")
					else:
						playerSprite.play("Walk" + form)
					playerSprite.speed_scale = 0
					playerSprite.frame = cycle + 1
				if (direction > 0):
					velocity.x = move_toward(velocity.x, 1 * ((SPEED  + superSpeed) + angry_boost), ACCELERATION)
				else:
					velocity.x = move_toward(velocity.x, -1 * ((SPEED  + superSpeed) + angry_boost), ACCELERATION)
			else:
				if (direction > 0):
					velocity.x = move_toward(velocity.x, 1 * ((SPEED  + superSpeed) + angry_boost), ACCELERATION)
				else:
					velocity.x = move_toward(velocity.x, -1 * ((SPEED  + superSpeed) + angry_boost), ACCELERATION)
			if !is_on_wall() and state != states.FALLING:
				switchState(state, states.WALK)

		else:
			if (!escapeToTheRight):
				steppedLeft = true
				if (is_on_floor()):
					velocity.x = move_toward(velocity.x, 0, DELERATION)
					if abs(velocity.x) <= 0 and !hasFallen:
						switchState(state, states.IDLE)
	if (!inGameOver):
		move_and_slide()

func switchEmotionFunc(emotion):
	if !(state == states.GAMEOVER or state == states.VICTORY) and form != "Super":
		if (fallTimer < maxFallTimeAllowed):
			if !(CutsceneHandler.inCutscene or state == states.DEATH or state == states.VICTORY or state == states.THROWN or state == states.GRABBED or talking or onHitstun or zoomEffect):
				if (Input.is_action_just_pressed("cancelEmotion") and is_on_floor()):
					turnEmotionOff()
					
				if current_emotion != emotions.ANGRY:
					var direction = Input.get_axis("left", "right")
					if !direction:
						angry_boost = 0
						jumpBoost = 0
				else:
					if Input.is_action_just_pressed("emotionAction") and hudHpBar.value == 100:
						if !emotionPowerActive and !(sad and happy):
							emotionEffects.currentEmotion = emotionEffects.emotions.ANGRY
							emotionPowerActive = true
							angrySfx.play()
							angry = true
							afterImageTimer.start()
							angry_boost = speedBoost
							jumpBoost = speedBoost / 2.5
							emotionEffects.active = true

				if current_emotion == emotions.SAD:
					if Input.is_action_just_pressed("emotionAction") and hudHpBar.value == 100:
						if !emotionPowerActive and !(angry and happy):
							emotionEffects.currentEmotion = emotionEffects.emotions.SAD
							emotionPowerActive = true
							sadSfx.play()
							sad = true
							cycle = 0
							afterImageTimer.start()
							emotionEffects.active = true
							
				if current_emotion == emotions.HAPPY:
					if Input.is_action_just_pressed("emotionAction") and hudHpBar.value == 100:
						if !emotionPowerActive and !(angry and sad):
							emotionEffects.currentEmotion = emotionEffects.emotions.HAPPY
							emotionPowerActive = true
							happySfx.play()
							happy = true
							afterImageTimer.start()
							playerSprite.speed_scale = 1.5
							happy_boost = 260
							emotionEffects.active = true

				if Input.is_action_just_pressed("emotionSwitch") and !emotionPowerActive:
					current_emotion = emotion
					
		else:
			if (state != states.DEATH):
				if (!CutsceneHandler.inCutscene):
					switchState(state, states.FALLING)

func applyGravity(delta):
	if !(state == states.DEATH or state == states.GAMEOVER or state == states.THROWN):
		if not is_on_floor():
			if (current_emotion == emotions.SAD and emotionPowerActive and sad):
				if (velocity.y > 0):
					if velocity.y < MAX_FALLSPEED / 4:
						velocity.y += (GRAVITY * delta) / 4
					else:
						velocity.y = (MAX_FALLSPEED / 4)-1
				else:
					if velocity.y < MAX_FALLSPEED:
						velocity.y += (GRAVITY * delta)

			else:
				if velocity.y < MAX_FALLSPEED:
					velocity.y += GRAVITY * delta
				else:
					if (get_tree().current_scene.name == "finalB_tstScn"):
						if (get_parent().caramelDed):
							pass
						else:
							fallTimer += delta
					else:
						fallTimer += delta
		else:
			if (current_jump > 0):
				current_jump = 0

			if (!emotionPowerActive):
				angry_boost = 0
				jumpBoost = 0
		if (emotionPowerActive):
			if hudHpBar.value <= 1:
				happy = false
				sad = false
				angry = false
				happy_boost = 0
				emotionPowerActive = false
				$Smoothing2D/emotionEffects.currentEmotion = null
				$Smoothing2D/emotionEffects.active = true
		else:
			hudHpBar.value += 40 * delta

	if Input.is_action_just_pressed("jump") and !(CutsceneHandler.inCutscene or state == states.DEATH or state == states.GAMEOVER or state == states.VICTORY):
		if !(talking or hasFallen or onHitstun or state == states.GRABBED or state == states.THROWN):
			if (current_jump < max_jumps):
				current_jump += 1
				velocity.y = (JUMP_VELOCITY - jumpBoost) - happy_boost
				if (happy):
					jumpBigSfx.play()
				else:
					jumpSfx.play()

func switchState(oldState, newState):
	lastState = oldState
	state = newState
	
func disableAll(delta):
	jumpBoost = 0
	angry_boost = 0
	angry = false
	sad = false
	happy = false
	playerSprite.speed_scale = 1.5
	fireSprite.modulate.a = lerp(fireSprite.modulate.a, 0.0, delta*12)
	$Smoothing2D/PointLight2D.visible = false
	emotionPowerActive = false
	
func moveCameraByAmount(_amountX, _amountY, _speed):
	camera.offset.x = clamp(camera.offset.x + _speed * get_physics_process_delta_time(), camera.offset.x, _amountX)
	if _amountY > camera.offset.y:
		camera.offset.y = lerp(camera.offset.y, float(_amountY), _speed * get_physics_process_delta_time())
	else:
		camera.offset.y = lerp(camera.offset.y, float(_amountY), _speed / 8 * get_physics_process_delta_time())
#
func shake(duration: float, amplitude: float):
	if (get_tree().current_scene.name == "finalB_tstScn"):
		camera.position_smoothing_enabled = false
	var timerS = get_tree().create_timer(duration)
	while timerS.time_left > 0:
		camera.position = Vector2(0, 0) + Vector2(randf_range(floor(-amplitude), floor(amplitude)), randf_range(floor(-amplitude), floor(amplitude)))
		await(get_tree().process_frame)
	camera.position_smoothing_enabled = true

#func shake(duration: float, shake_amplitude: float):
	#if (get_tree().current_scene.name == "finalB_tstScn"):
		#camera.position_smoothing_enabled = false
	#shakeTimer.wait_time = duration
	#if (!shakeTimer.is_stopped()):
		#camera.position = Vector2(0, 0) + Vector2(randf_range(floor(-shake_amplitude), floor(shake_amplitude)), randf_range(floor(-shake_amplitude), floor(shake_amplitude)))
	#camera.position_smoothing_enabled = true

func instantiateAfterImage():
	var id = afterImage.instantiate()
	id.texture = playerSprite.sprite_frames.get_frame_texture(playerSprite.get_animation(), playerSprite.frame)
	add_child(id)
	if happy:
		id.modulate = id.colors[0]
	elif angry:
		id.modulate = id.colors[1]
	else: 
		id.modulate = id.colors[2]
	id.scale.x = playerSprite.scale.x
	id.global_position = global_position

func stepSave():
	if (dir != 0):
		facingSteps.push_front(dir)
		facingSteps.pop_back()
	followSteps.push_front(position)
	followSteps.pop_back()

func angyStepSync():
	if (!GameDataManager.paused):
		if (!zoomEffect):
			if (cycle == 0):
				cycle = 2
			elif cycle == 2:
				cycle = 0
			if (!talking):
				if ( state == states.WALK and current_emotion == emotions.ANGRY and is_on_floor() and emotionPowerActive) or (escapeToTheRight):
					playerSprite.frame = cycle
					playerSprite.speed_scale = (4 / (10.5 * (Conductor.crotchet * 1.5)))
					stepSfx.play()
		else:
			if state != states.DEATH:
				playerSprite.frame = 0
	
func stepSync():
	if (!GameDataManager.paused):
		if (!escapeToTheRight):
			if !(state == states.WALK):
				if (cycle == 0):
					cycle = 2
				elif cycle == 2:
					cycle = 0
			if !(state != states.WALK or !is_on_floor() or !emotionPowerActive or talking):
				match(current_emotion):
					emotions.SAD:
						if emotionPowerActive:
							playerSprite.speed_scale = (4 / (10.5 * (Conductor.crotchet))) / 2
							if Conductor.currentBeat % 2 == 0:
								if (cycle == 2):
									cycle = 0
									playerSprite.frame = cycle
								elif cycle == 0:
									cycle = 2
									playerSprite.frame = cycle
								
								stepSfx.play()
								playerSprite.play("WalkSad")
						else:
							playerSprite.speed_scale = (4 / (10.5 * Conductor.crotchet))
							stepSfx.play()
					emotions.HAPPY:
						if (cycle == 0):
							cycle = 2
						elif cycle == 2:
							cycle = 0
						playerSprite.frame = cycle
						playerSprite.speed_scale = (4 / (10.5 * Conductor.crotchet))
						stepSfx.play()
			elif state != states.WALK and is_on_floor():
				if (cycle == 2):
					cycle = 0
				elif cycle == 3:
					cycle = 2
			if !emotionPowerActive and is_on_floor() and state == states.WALK:
				if (cycle == 0):
					cycle = 2
				elif cycle == 2:
					cycle = 0
				playerSprite.play("Walk" + form)
				playerSprite.frame = cycle
				playerSprite.speed_scale = (4 / (10.5 * Conductor.crotchet))
				stepSfx.play()
		
func instantiateFren(assistToInstantiate):
	var id
	if (assistToInstantiate == "Eru"):
		id = fren.instantiate()
	elif (assistToInstantiate == "Nisha"):
		id = frenNisha.instantiate()
	elif (assistToInstantiate == "Meica"):
		id = frenMeica.instantiate()
		id.dir = playerSprite.scale.x
	add_child(id)
	id.global_position = global_position
	id.eruSpr.scale.x = playerSprite.scale.x
	id.position.x = (position.x - (20 * playerSprite.scale.x))
	if (assistToInstantiate == "Nisha"):
		id.position.y = (position.y - 50)

func stopTalk():
	talking = false

func afterBossTriggerCutscene(_idk):
	if CutsceneHandler.bossPhase == 2:
		if (!escapeToTheRight):
			isInvincible = true
			invinFrames = 99999999
			escapeToTheRight = true
			angrySfx.play()

func checkPoint(coords):
	CutsceneHandler.lastCheckpoint = coords
	checkpointCoords = coords

func hitStop(timeScale, duration, _object):
	var start = Time.get_ticks_usec()
	Engine.time_scale = timeScale
	if (get_tree().current_scene.name == "level2"):
		get_parent().cam.enabled = false
	else:
		_object.get_parent().bossSprite.play("GotHitStartup")
	if (!zoomEffect):
		camera.enabled = true
		zoomEffect = true
		isInvincible = false
		playerSprite.visible = true
		playerSprite.modulate.a = 1
		invinFrames = 75
		sfxSuspense.play()
		if CutsceneHandler.bossPhase == 1 and get_tree().current_scene.name != "finalB_tstScn":
			camera.offset.x = -100
	while Time.get_ticks_usec() - start < (duration/2) * 1000000:
		await get_tree().process_frame
	Engine.time_scale = 1
	$HitDelay.play()
	camera.offset.y = 0
	camera.offset.x = 0
	camera.zoom.x = 2
	camera.zoom.y = 2
	zoomEffect = false
	invinFrames = 120
	isInvincible = true
	if (get_tree().current_scene.name == "level2"):
		var curScene = get_tree().get_current_scene()
		camera.enabled = false
		if (_object.get_parent().hits <= 1):
			_object.get_parent().gotHitSounds[0].play()
		get_parent().cam.enabled = true
		if (curScene.bossHP.frame != 10):
			curScene.bossHP.frame += 1
	else:
		var curScene = get_tree().get_current_scene()
		_object.get_parent().gotHitSfx.play()
		if (_object.get_parent().name != "caramel"):
			_object.get_parent().eyeObject.difficulty += 1
		hitEffectSpawn("0")
		if !(_object.get_parent().inThirdPhase):
			if (curScene.bossHP.frame != 1 and curScene.bossHP.frame != 6) and (curScene.bossHP.frame != 10):
				curScene.bossHP.frame += 1
			else:
				switchPhase(_object)
		else:
			if (curScene.bossHP.frame != 10):
				curScene.bossHP.frame += 1
			else:
				pass
				#print("ayo what the fuck")

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), originalAudioVolume)

func switchPhase(_object):
	if (get_tree().current_scene.name != "level3"):
		var scene = get_tree().get_current_scene()
		if (scene.bossHP.frame < 4):
			Conductor.goToNextSection = true
			Conductor.fourthBeat = 4
			Conductor.waitUp = false
		dir = 1
		playerSprite.scale.x = dir
		camera.offset.x += 40
		shockWaveAnimPlay.play("cutsceneWhiteFadeOut")
		global_position = scene.shuraPosMarker.global_position
		_object.get_parent().global_position = scene.caramelPosMarker.global_position
		_object.get_parent().global_position.y -= 15
		if scene.bossHP.frame != 10:
			scene.bossHP.frame += 1
		disableAll(get_physics_process_delta_time())
		turnEmotionOff()
		velocity.x = 0
		invinFrames = 900000000
		isInvincible = true
		velocity.y = 0
		_object.get_parent().active = false
		CutsceneHandler.inCutscene = true

func hitEffectSpawn(fxID):
	var effectId = hitEffectManager.instantiate()
	add_child(effectId)
	effectId.top_level = true
	effectId.position = position
	effectId.playAnim(fxID)

func shockWaveEffect():
	$hud/ShockWaveDelete.modulate.a = 0.5

func turnEmotionOff():
	sad = false
	happy = false
	angry = false
	jumpBoost = 0
	angry_boost = 0
	happy_boost = 0
	fallTimer = 0
	emotionPowerActive = false
	$Smoothing2D/emotionEffects.currentEmotion = null
	$Smoothing2D/emotionEffects.active = true

func vertical_corner_correction(amount: int):
	if velocity.y < 0:
		var delta = get_physics_process_delta_time()
		if velocity.y < 0 and test_move(global_transform, 
		Vector2(0,velocity.y*delta)):
			for i in range(1,amount*2+1):
				for j in [-1.0,1.0]:
					if !test_move(global_transform.translated(Vector2(i*j/2,0)),
						Vector2(0,velocity.y*delta)):
						translate(Vector2(i*j/2,0))
						if velocity.x * j < 0: velocity.x = 0
						#print("ayo")
						return

func _on_timer_timeout():
	if (emotionPowerActive):
		instantiateAfterImage()

func _on_hitbox_area_entered(area):
	if (form == "Super" and area.name == "BossHurtbox"):
		if area.get_parent().gotStruck:
			if !(area.get_parent().gotHit):
				hitStop(0.05, 2, area)
				area.get_parent().tiredTimer = 3
				area.get_parent().gotHit = true
	if (form != "Super" ):
		if (area.name == "BossHurtbox" and (current_emotion == emotions.ANGRY) and emotionPowerActive and velocity.x != 0):
			if area.get_parent().gotStruck:
				if !(area.get_parent().gotHit):
					hitStop(0.05, 2, area)
					area.get_parent().tiredTimer = 3
					area.get_parent().gotHit = true


func _on_area_2d_body_entered(body):
	#player is probably stuck inside a wall, if true, then kill the player
	if (state != states.GRABBED):
		if !(body.name == self.name or state == states.GAMEOVER):
			if (!body.name.begins_with("oneWay")):
				state = states.DEATH
				explosionSfx.play()


func _on_player_sprite_animation_finished():
	if (playerSprite.get_animation() == "TransformationStep_1"):
		playerSprite.play("TransformationStep_2")
	if (playerSprite.get_animation() == "TransformationStep_3"):
		playerSprite.play("TransformationStep_4")
	if (playerSprite.get_animation() == "ChuwaPunch"):
		CutsceneHandler.inCutscene = false
		get_parent().bossHP.visible = true
		state = states.IDLE
		
	match(playerSprite.get_animation()):
		"GameOver":
			showGameOver = true
		"GameOverExplosion":
			showGameOver = true
		"GameOverPunch":
			showGameOver = true
		"GameOverThrown":
			showGameOver = true
		"GameOverHomerun":
			showGameOver = true

func finalCutscene(delta):
	if (is_on_floor() and !get_parent().preVirusCutscene) and cutsceneStep == 0:
		get_parent().preVirusCutscene = true
		cutsceneStep += 1
		velocity.x = 0
		turnEmotionOff()
		disableAll(delta)
		emotionPowerActive = false

	if (!is_on_floor() and cutsceneStep == 0):
		velocity.x = 0
		turnEmotionOff()
		disableAll(delta)
		emotionPowerActive = false

	if (cutsceneStep == 1):
		if (cutsceneSpecificTimer <= 0):
			cutsceneStep += 1
			state = states.IDLE
			cutsceneSpecificTimer = 1
			if (playerSprite.get_animation() != "Idle"):
				playerSprite.play("Idle")
		else:
			cutsceneSpecificTimer -= delta
			
		state = states.WALK
		if (playerSprite.get_animation() != "Walk" and cutsceneSpecificTimer > 0):
			playerSprite.play("Walk")
		playerSprite.scale.x = 1
		velocity.x = move_toward(velocity.x, 1 * (SPEED + angry_boost), ACCELERATION)
	if (cutsceneStep == 2):
		state = states.IDLE
		if (playerSprite.get_animation() != "Idle"):
			playerSprite.play("Idle")

		if (cutsceneSpecificTimer <= 0):
			get_parent().zombieCaramel.show()
			get_parent().spawnDialogue(true)
			cutsceneStep += 1
		else:
			cutsceneSpecificTimer -= delta
	if (cutsceneStep == 4):
		playerSprite.scale.x = -1
		camera.offset.x = lerp(camera.offset.x, -110.0, (0.02*60)*delta)
		
		if (cutsceneSpecificTimer <= 1):
			if (playerSprite.get_animation() != "Scared1"):
				playerSprite.play("Scared1")
			
		if (cutsceneSpecificTimer <= 0):
			get_parent().zombieCaramel.play("attack")
			get_parent().zombieCaramel.dash1.play()
			get_parent().zombieCaramel.dash2.play()
			cutsceneStep += 1
		else:
			cutsceneSpecificTimer -= delta
	if (cutsceneStep == 5):
		get_parent().zombieCaramel.global_position.x += (10 * 50) * delta


func _on_shake_timer_timeout():
	camera.position_smoothing_enabled = true
