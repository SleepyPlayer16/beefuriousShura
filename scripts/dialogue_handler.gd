extends Control

@export var dialogPath = ""
@export var textSpeed = 0.025

var dialog
var phraseNum = 0
var finished = false
var paused = false
var curSceneName = ""
var audioPlayed = false
var curScene
var doNothin = false

@onready var charaName = $CanvasLayer/TextBox/Name
@onready var charaText = $CanvasLayer/TextBox/Text
@onready var timer = $CanvasLayer/Timer
@onready var portraitLeft = $CanvasLayer/A
@onready var portraitRight = $CanvasLayer/B
@onready var portraitRightSecond = $CanvasLayer/B/C
@onready var animPlayer = $AnimationPlayer
@onready var dialogueDone = false
@onready var deletionTimer = 0.2
@onready var isNpcDialogue = false
@onready var isCutsceneDialogue = false

func _ready():
	curSceneName = get_tree().current_scene.name
	if (curSceneName == "level4"):
		$VoiceBeep.volume_db = -80
		Conductor.chairTalkin = true
	timer.wait_time = textSpeed
	dialog = getDialog()
	assert(dialog, "No se encontró ningún dialogo, avisarme si te ocurre en una sección importante del juego")
	nextPhrase()
	CutsceneHandler.pauseEndedSignal.connect(unPauseDialogue)
	

func _process(delta):
	if (curSceneName == "introCutscene"):
		if (get_parent().skipped):
			doNothin = true
			$CanvasLayer.visible = false
			
	if (Input.is_action_just_pressed("ui_accept")):
		if finished:
			audioPlayed = false
			nextPhrase()
		else:
			charaText.visible_characters = len(charaText.text)
	if (dialogueDone):
		deletionTimer -= delta
		if (deletionTimer <= 0):
			if (isNpcDialogue):
				CutsceneHandler.emit_signal("dialogueEndedSignal")
			elif (isCutsceneDialogue):
				CutsceneHandler.emit_signal("cutsceneDialogueEndedSignal", 1)
			queue_free()

func getDialog():
	var file = FileAccess.open(dialogPath, FileAccess.READ)
	var parsedResult = JSON.parse_string(file.get_as_text())
	
	if (parsedResult is Array):
		return parsedResult
	else:
		print("hijo de su perra mdre algo falló aaaaaaaaa")
		return {}

func nextPhrase() -> void:
	if (!doNothin):
		if phraseNum >= len(dialog):
			animPlayer.speed_scale *= 2
			dialogueDone = true
			animPlayer.play_backwards("In")
			Conductor.chairTalkin = false
			return

		if (dialogPath == "res://dialog/dialog_lastLvlChairGTables.json"):
			if (!audioPlayed):
				if (phraseNum == 0):
					$ChairDiag1.play()
				if (phraseNum == 2):
					$ChairDiag1.stop()
					$ChairDiag2.play()
				if (phraseNum == 3):
					$ChairDiag2.stop()
					$ChairDiag3.play()
				if (phraseNum == 4):
					$ChairDiag3.stop()
					$ChairDiag4.play()
				if (phraseNum == 5):
					$ChairDiag4.stop()
					$VoiceBeep.volume_db = -2
				audioPlayed = true

		finished = false
		if (phraseNum == 0):
			portraitLeft.texture = load("res://sprites/" + dialog[phraseNum]["CharacterLeft"].to_lower() + "/" + dialog[phraseNum]["CharacterLeft"] + "Normal.png")
			if dialog[phraseNum]["CharacterRight"] != "":
				portraitRight.visible = true
				portraitRight.texture = load("res://sprites/" + dialog[phraseNum]["CharacterRight"].to_lower() + "/" + dialog[phraseNum]["CharacterRight"] + "Normal.png")
			else:
				portraitRight.visible = false
			phraseNum += 1
		
		if !(dialog[phraseNum]["SecondaryName"] == "TriggerAnimationEvent" or dialog[phraseNum]["SecondaryName"] == "TriggerEvent"):
			if (dialog[phraseNum]["SecondaryName"]  != ""):
				charaName.text = dialog[phraseNum]["Name"] + " y " + dialog[phraseNum]["SecondaryName"]
			else:
				charaName.text = dialog[phraseNum]["Name"]
			charaText.text = dialog[phraseNum]["Text"]
		else:
			if (dialog[phraseNum]["SecondaryName"] == "TriggerAnimationEvent"):
				$CanvasLayer.visible = false
				paused = true
				if get_tree().current_scene.name == "level3":
					CutsceneHandler.fireMidDialoguePause(2.2)
			if (dialog[phraseNum]["SecondaryName"] == "TriggerEvent"):
				charaName.text = dialog[phraseNum]["Name"]
				charaText.text = dialog[phraseNum]["Text"]
				CutsceneHandler.emit_signal("TriggerAnimationChange")
			
		if !paused:
			charaText.visible_characters = 0
			var img = "res://sprites/" + dialog[phraseNum]["Name"].to_lower() + "/" + dialog[phraseNum]["Name"] + dialog[phraseNum]["Emotion"] + ".png"
			var portraitToChange = dialog[phraseNum]["Side"]
			
			if (portraitToChange == "Left"):
				portraitLeft.modulate.a = 1
				portraitLeft.texture = load(img)
				portraitRight.modulate.a = 0.5
			elif (portraitToChange == "Right"):
				portraitRight.modulate.a = 1
				portraitRight.texture = load(img)
				portraitLeft.modulate.a = 0.5
			elif (portraitToChange == "Right-second"):
				var offset = int(dialog[phraseNum]["SecondaryOffset"])
				var imgSecondary = "res://sprites/" + dialog[phraseNum]["SecondaryName"].to_lower() + "/" + dialog[phraseNum]["SecondaryName"] + dialog[phraseNum]["Emotion"] + ".png"
				portraitRight.modulate.a = 1
				portraitRightSecond.modulate.a = 1
				portraitRightSecond.texture = load(imgSecondary)
				portraitRightSecond.offset.x -= offset
				portraitLeft.modulate.a = 0.5
			
			while charaText.visible_characters < len(charaText.text):
				$CanvasLayer/TextBox/AnimatedSprite2D.visible = false
				charaText.visible_characters += 1
				if !doNothin:
					$VoiceBeep.play()
				$VoiceBeep.pitch_scale = 1 + randf_range(-0.1,0.1)
				timer.start()
				await timer.timeout
			if (charaText.visible_characters == len(charaText.text)):
				$CanvasLayer/TextBox/AnimatedSprite2D.visible = true
			
			finished = true
			phraseNum += 1
			return

func unPauseDialogue():
	animPlayer.play("In")
	finished = true
	phraseNum += 1
	paused = false
	nextPhrase()
	$CanvasLayer.visible = true
 
