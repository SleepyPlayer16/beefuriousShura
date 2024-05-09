extends Node2D

var currentEmotion = null
var active = false
var dir = 1

@onready var particleGroup = [$Angry, $Sad, $Happy, $Hopeful]

enum emotions{
	ANGRY,
	SAD,
	HAPPY,
	HOPEFUL,
}

func _process(_delta):
	if (active):
		for i in range(4):
			particleGroup[i].emitting = i == currentEmotion
		active = false
	if (currentEmotion == null):
		for e in range(4):
			particleGroup[e].emitting = false
		
	if (dir == 1):
		particleGroup[0].gravity.x = -500
		particleGroup[0].position.x = 54
	elif (dir == -1):
		particleGroup[0].gravity.x = 500
		particleGroup[0].position.x = -54
	else:
		particleGroup[0].position.x = 4
		particleGroup[0].position.y = -4
