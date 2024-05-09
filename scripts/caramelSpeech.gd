extends Node2D

var txtStep = 0
var txtEnd = false
@onready var tmer = $Timer
@onready var txtLabel = $RichTextLabel
@onready var dialogueScene = preload("res://scenes/hud/dialogue_handler.tscn")

func _process(delta):
	if (txtStep == 1):
		txtLabel.visible = true

	if (txtStep == 2):
		txtLabel.text = "[center][shake rate=20.0 level=5 connected=1] ¡Ojalá tengas la misma suerte para escapar de este lugar con vida! [/shake][/center]"

	if (txtStep == 3):
		txtLabel.modulate.a -= (0.02 * 50) * delta

	if (txtStep == 4):
		if (!txtEnd):
			txtEnd = true
			spawnDialogue(true)

func spawnDialogue(isCutscene):
	var dialogueInstance = dialogueScene.instantiate()
	dialogueInstance.dialogPath = "res://dialog/dialog_finalBossLvlShuraPantcakeTwo.json"
	add_child(dialogueInstance)
	if (isCutscene):
		dialogueInstance.isCutsceneDialogue = true
	else:
		dialogueInstance.isNpcDialogue = true

func _on_timer_timeout():
	if (!txtEnd):
		tmer.wait_time = 4
		if (txtStep == 1):
			tmer.wait_time = 6
		tmer.start()
		txtStep += 1
