extends AudioStreamPlayer

signal beatSignal
signal fourthSignal
signal beatSignalBPMDouble
signal beatSignalBPM
signal resetSignal
signal destroyNotes

signal just_Signal
signal miss_Signal
signal noteBeatSignal
signal triggerThunder

var songToStream = null
var songPosition = 0.0
var shouldLoop = true
var bpm = 135
var barBeats = 4
var crotchet = 60/float(bpm)
var doublecrotchet = 60/float(bpm*2)
var songReady = false
var lastBeat = 0
var lastBeatDouble = 0
var trueLastBeat = 0
var currentBeat = 1
var safeZoneDuration = 0.3
var safeZonePercent = 80.0
var safe = false
var comparer = 0.0
var comparer2  = 0.0
var securezone = true
var comparer_behind = 0.00
var comparer_front = 0.00
var safedata
var beatCounter = 0
var lastSongPos = 0.0
var lastFourBeats
var combo = 0
var physicsSpeedMultiplier = 1
var singleFramephysicsSpeedMultiplier = 1

var songSections = []
var signature = 4
var currSection = 0
var goToNextSection = false
var waitUp = false
var stopSoundEffects = false
var fourthBeat = 1
var bpm_changed = false
var targetVolume = 0.0
var targetHVolume = 0.0
var currentNote = 0
var musVolume = 0.0
var curScene
var chairTalkin = false

#this shit is a horrible way of handling music stuff don't do this
@onready var musLvlTutoiral = preload("res://music/mus_tutorial.ogg")
@onready var musLvlOne = preload("res://music/mus_levelOne.ogg")
@onready var musLvlOneSection2 = preload("res://music/mus_levelOneSection2.ogg")
@onready var musLvlTwo = preload("res://music/snowLevelMaybe.ogg")
@onready var musLvlThree = preload("res://music/mus_lastStraw_section1.ogg")
@onready var musLvlThreeSection2 = preload("res://music/mus_lastStraw_section2.ogg")
@onready var musLvlFour = preload("res://music/mus_letsDance.ogg")
@onready var highTensionSong = $AudioStreamPlayer2
@onready var goalSong = $goalJingle
@onready var menuMove = $menuMove
@onready var menuSelect = $MenuSelect

@onready var musLvlBossSection1 = preload("res://music/finalBoss/mus_buzzEncount_section1.ogg")
@onready var musLvlBossSection1T = preload("res://music/finalBoss/mus_buzzEncount_section1Transition.ogg")
@onready var musLvlBossSection2 = preload("res://music/finalBoss/mus_buzzEncount_section2.ogg")
@onready var musLvlBossSection2T = preload("res://music/finalBoss/mus_buzzEncount_section2Transition.ogg")
@onready var musLvlBossSection3 = preload("res://music/finalBoss/mus_buzzEncount_section3.ogg")
@onready var musLvlBossOutro = preload("res://music/finalBoss/mus_buzzEncount_outro.ogg")

func _ready():
	curScene = get_tree().current_scene.name

func _process(_delta):

	#if for some reason the current section of the song is bigger than the number of sections in 
	#the song's array, then FUCKING set it back to that size
	if (!GameDataManager.levelCleared):
		if (curScene == "level4"): #TODO: fix this shit in godot 4.2 it crashes the game
			if (GameDataManager.paused):
				volume_db = -10
			else:
				if (!chairTalkin):
					volume_db = musVolume
				else:
					volume_db = -12

	if (currSection > songSections.size()-1):
		currSection = songSections.size()-1
	if (songReady and !playing) and !(get_tree().paused and curScene != "level4"):
		if !goToNextSection:
			loopSongReload()
		else:
			currSection += 1
			loopSongReload()
#	if (Input.is_action_just_pressed("jump")):
#		goToNextSection = true

	songPosition = get_playback_position() + AudioServer.get_time_since_last_mix()
	if ( songPosition  > lastBeatDouble + (doublecrotchet)) and playing:
		lastBeatDouble += doublecrotchet
		emit_signal("beatSignalBPMDouble")
		
	if ( songPosition  > lastBeat + crotchet) and playing:
		if (!songSections.is_empty()):
			if (fourthBeat == 4 and goToNextSection):
				if !waitUp:
					if (currSection != songSections.size()-1):
						currSection += 1
					goToNextSection = false
					loopSongReload()
		lastBeat += crotchet
		trueLastBeat += crotchet
		currentBeat += 1
		beatCounter += 1
		fourthBeat += 1 

		if fourthBeat >= signature + 1:
			waitUp = false
			fourthBeat = 1
		if beatCounter > signature*2:
			beatCounter = 1
		emit_signal("beatSignalBPM")
		if (signature == 3):
			if (currentBeat % signature == 0):
				emit_signal("fourthSignal")
		else:
			if (currentBeat % signature == 0):
				emit_signal("fourthSignal")
		if (currentBeat % signature-2 == 0):
			emit_signal("beatSignal")
	
func songToLoad(songBpm, volume, song):
	songToStream = song
	bpm = songBpm
	crotchet = 60/float(songBpm)
	doublecrotchet = 60/float(songBpm * 2)
	trueLastBeat = -crotchet
	songReady = true
	musVolume = volume
	volume_db = volume

func songUnload():
	stop()
	songToStream = null
	currentBeat = 1
	songReady = false
	lastBeat = 0
	lastBeatDouble = 0
	trueLastBeat = 0
	comparer_behind = 0.00
	comparer_front = 0.00
	beatCounter = 0
	safe = false
	comparer = 0.0
	comparer2  = 0.0

func songToGet(sceneName):
	match (sceneName):
		"levelTutorial":
			songToLoad(160, -2, musLvlTutoiral)
		"01_tst":
			songToLoad(130, -80, musLvlOne)
		"bosstestArena":
			songToLoad(130, -80, musLvlOne)
		"level1":
			songSections = [musLvlOne, musLvlOneSection2]
			songToLoad(130, -3, songSections[0])
		"level2":
			songToLoad(180, -4, musLvlTwo)
		"level3":
			if (CutsceneHandler.bossPhase == 0):
				songSections = [musLvlThree, musLvlThreeSection2]
				songToLoad(150, -1, songSections[0])
			else:
				songSections = [
					musLvlBossSection1,
					musLvlBossSection1T,
					musLvlBossSection2,
					musLvlBossSection2T,
					musLvlBossSection3,
					musLvlBossOutro
				]
				songToLoad(200, -2, songSections[0])
		"level4":
			songToLoad(200, -2, musLvlFour)
		"finalB_tstScn":
			songSections = [
				musLvlBossSection1,
				musLvlBossSection1T,
				musLvlBossSection2,
				musLvlBossSection2T,
				musLvlBossSection3,
				musLvlBossOutro
			]
			songToLoad(200, -2.5, songSections[0])

func songReset():
	songToGet("")
	stop()
	crotchet = 60/float(bpm)
	doublecrotchet = 60/float(bpm * 2)
	combo = 0
	fourthBeat = 1
	currentBeat = 1
	lastSongPos = 0.0
	lastBeat = 0
	lastBeatDouble = 0
	trueLastBeat = 0
	comparer_behind = 0.00
	comparer_front = 0.00
	beatCounter = 0
	safe = false
	musVolume = 0.0
	comparer = 0.0
	comparer2  = 0.0

func loopSongReload():
	
	if songSections.is_empty():
		#si no hay secciones loopear la canción normalmente de inicio a fin
		set_stream(songToStream)
	else:
		#la sección se va a loopear hasta que la variable goToNextSection sea true o el archivo que 
		#se esté reproduciendo sea un intro o una transición, así que no hay necesidad
		#de cambiar esta parte
		
		if (currSection > songSections.size()-1):
			currSection = songSections.size()-1
		set_stream(songSections[currSection])
		var strimpath = songSections[currSection].resource_path
		if (goToNextSection) or ((strimpath.ends_with("intro.ogg") or strimpath.ends_with("Transition.ogg"))):
			if (currSection != songSections.size()-1):
				currSection += 1
			goToNextSection = false
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), GameDataManager.globalVolume)
	
	lastBeat = 0
	lastBeatDouble = 0
	trueLastBeat = -crotchet
	emit_signal("beatSignal")
	emit_signal("beatSignalBPM")
	emit_signal("beatSignalBPMDouble")
	currentBeat = 1
	fourthBeat = 1
	currentBeat += 1
	beatCounter += 1
	if beatCounter > signature*2:
		beatCounter = 1
	if (!shouldLoop):
		volume_db = -80.0
	emit_signal("resetSignal")
	play()

func _exit_tree():
	queue_free()

func resetEVERYTHINGGGGG():
	Conductor.stream = null
	songToStream = null
	songPosition = 0.0
	bpm = 135
	barBeats = 4
	crotchet = 60/float(bpm)
	doublecrotchet = 60/float(bpm*2)
	songReady = false
	lastBeat = 0
	lastBeatDouble = 0
	trueLastBeat = 0
	currentBeat = 1
	safeZoneDuration = 0.3
	safeZonePercent = 80.0
	safe = false
	comparer = 0.0
	comparer2  = 0.0
	securezone = true
	comparer_behind = 0.00
	comparer_front = 0.00
	beatCounter = 0
	lastSongPos = 0.0

	songSections = []
	signature = 4
	currSection = 0
	goToNextSection = false
	waitUp = false
	stopSoundEffects = false
	fourthBeat = 1
	bpm_changed = false
	musVolume = 0.0
	targetVolume = 0.0
	targetHVolume = 0.0
	currentNote = 0
