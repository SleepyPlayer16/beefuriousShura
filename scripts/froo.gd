extends Node2D

@onready var dialogueScene = preload("res://scenes/hud/dialogue_handler.tscn")
@onready var player = get_parent().get_node("player")
@export var character = ""
@export var scared = false

var canBeTalkedTo = false
var talking = false
var dialogueCreated = false
var activateRun = false


func _ready():
	if (!scared):
		$AnimatedSprite2D.play("default")
	CutsceneHandler.dialogueEndedSignal.connect(stopTalk)
	Conductor.beatSignal.connect(idleSync)

func stopTalk():
	if (character == "Karu" and CutsceneHandler.npcCurrentlySpeaking == character):
		scale.x = 1
		get_parent().talkedToKaru = true
		$AnimatedSprite2D.play("runnnnn")
		activateRun = true
	if (character == "Yukine" and CutsceneHandler.npcCurrentlySpeaking == character):
		#print("wtf")
		scale.x = 1
		get_parent().talkedToYukine = true
		$AnimatedSprite2D.play("runnnnn")
		activateRun = true
	talking = false
	dialogueCreated = false


func _process(delta):
	if (!activateRun):
		if player.position.x < position.x:
			if (character != "eru"):
				scale.x = 1
			else:
				scale.x = -1
		else:
			if !(character == "eru" or character == "nisha" or character == "meica" or character == "yukine"):
				scale.x = -1
			else:
				scale.x = 1
		if (Input.is_action_just_pressed("ui_up") and canBeTalkedTo):
			if (!talking and player.is_on_floor()):
				if !(player.state == player.states.GAMEOVER or player.state == player.states.DEATH):
					CutsceneHandler.npcCurrentlySpeaking = character
					if (scared):
						scared = false
					talking = true
					player.disableAll(get_physics_process_delta_time())
					player.turnEmotionOff()
					player.playerSprite.scale.x = scale.x
		if (talking):
			if (!player.talking):
				player.state = player.states.IDLE
				player.talking = talking
				player.playerSprite.play("Walk")
				player.velocity.x = 0
				
				
			player.position.x = move_toward(player.global_position.x, $Area2D.global_position.x - (24 * scale.x), 30 * delta)
			if player.position.x == $Area2D.global_position.x - (24 * scale.x):
				if !(dialogueCreated):
					dialogueCreated = true
					spawnDialogue(false)
					player.playerSprite.play("Idle")
	else:
		position.x -= (10 * 60) * delta
		if (character == "Yukine"):
			position.y -= (2 * 60 ) * delta

func spawnDialogue(isCutscene):
	#TODO: change this with match or sum shit idk
	#edit: done
	var dialogueInstance = dialogueScene.instantiate()
	match(character):
		"Froo":
			if (get_parent().talkedToKaru):
				dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlFrooSecond.json"
			else:
				dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlFroo.json"
		"Karu":
			dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlKaru.json"
		"Shroo":
			dialogueInstance.dialogPath = "res://dialog/dialog_forestLvlShroo.json"
		"Mai":
			dialogueInstance.dialogPath = "res://dialog/dialog_forestLvlMai.json"
		"Condesa":
			dialogueInstance.dialogPath = "res://dialog/dialog_forestLvlCondesa.json"
		"Eiwy":
			dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlEiwy.json"
		"Eru":
			dialogueInstance.dialogPath = "res://dialog/dialog_tutorialLvlEru.json"
		"Nisha":
			dialogueInstance.dialogPath = "res://dialog/dialog_tutorialLvlNisha.json"
		"Meica":
			dialogueInstance.dialogPath = "res://dialog/dialog_tutorialLvlMeica.json"
		"Haise":
			dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlHaise.json"
		"Yukine":
			dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlYukine.json"
		"ChairGTables":
			dialogueInstance.dialogPath = "res://dialog/dialog_lastLvlChairGTables.json"
		"Liz":
			dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlLiz.json"
		"Cowokie":
			dialogueInstance.dialogPath = "res://dialog/dialog_snowLvlCowokie.json"

	add_child(dialogueInstance)
	if (isCutscene):
		dialogueInstance.isCutsceneDialogue = true
	else:
		dialogueInstance.isNpcDialogue = true

func _on_area_2d_body_entered(body):
	if (body.name == "player"):
		canBeTalkedTo = true

func idleSync():
	if (!activateRun):
		if (get_parent().talkedToKaru and character == "Froo"):
			$AnimatedSprite2D.offset.x = -32
			$AnimatedSprite2D.play("idleWKaru")
		elif (character == "Liz"):
			if ($AnimatedSprite2D.get_animation() == "default"):
				$AnimatedSprite2D.play("default2")
			else:
				$AnimatedSprite2D.play("default")
		elif !(character == "Froo" or character == "Liz"):
			if (!scared):
				$AnimatedSprite2D.play("default")

func _on_area_2d_body_exited(body):
	if (body.name == "player"):
		canBeTalkedTo = false
