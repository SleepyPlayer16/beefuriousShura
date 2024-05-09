extends Node2D

signal dialogueEndedSignal
signal cutsceneDialogueEndedSignal
signal cutsceneSkipSignal
signal shockWaveSignal
signal pauseEndedSignal
signal finalBossBeginSignal
signal bossScream
signal TriggerAnimationChange

var inCutscene = false
var snowCutscene = false
var arenaPreparation = false
var leftPressed = false
var rightPressed = false
var jumpPress = false
var volumeTimer = 3
var npcCurrentlySpeaking = ""
var shouldSkipCutscene = false
var playerContinued = false
var lastCheckpoint 
var playerHasDied = false
var playerCamActive = true
var bossPhase = 0
var signalEmitted = false
var bossCheckpointCoords = Vector2(12864, 400)
var timer = -5

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (Input.is_action_just_pressed("takeScreen")):
		take_screenshot()
	
	if (inCutscene):
		if snowCutscene:
			SnowAreaCutscene()
	if (arenaPreparation):
		arenaPreparationFunc()

	if (timer > 0):
		timer -= _delta
	elif timer > -5 and timer <= 0:
		if !signalEmitted:
			signalEmitted = true
			emit_signal("pauseEndedSignal")

func SnowAreaCutscene():
	if (!inCutscene):
		inCutscene = true
	else:
		if volumeTimer > 0:
			Conductor.volume_db -= get_process_delta_time() * 60
			volumeTimer -= get_process_delta_time()

func finalBossFirstCutscene():
	if (!inCutscene):
		inCutscene = true

func fireMidDialoguePause(pauseTime):
	timer = pauseTime

func arenaPreparationFunc():
	if volumeTimer > 0:
		Conductor.volume_db -= get_process_delta_time() * 60
		volumeTimer -= get_process_delta_time()	
		
func resetAll():
	inCutscene = false
	snowCutscene = false
	arenaPreparation = false
	leftPressed = false
	rightPressed = false
	jumpPress = false
	volumeTimer = 3
	npcCurrentlySpeaking = ""
	shouldSkipCutscene = false
	lastCheckpoint = null
	playerHasDied = false
	playerCamActive = true
	bossPhase = 0
	signalEmitted = false
	timer = -5

func take_screenshot():
	var screenshot = get_viewport().get_texture().get_image()
	var unix_time: float = Time.get_unix_time_from_system()
	var unix_time_int: float = unix_time #change back to int
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(float(unix_time))
	var ms: float = (unix_time - unix_time_int) * 1000.0 #change back to INT
	screenshot.save_png("user://screenshot"+ str(dt.second) + str(ms) +".png")
