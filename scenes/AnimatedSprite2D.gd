extends AnimatedSprite2D

var cycle = 0
@onready var sfx = get_node("../AudioStreamPlayer")
func _ready():
	Conductor.beatSignalBPM.connect(stepSync)
#	Conductor.songToLoad(360, -4, load("res://music/snowLevelMaybe.ogg"))
	Conductor.songToLoad(150, -4, load("res://music/mus_lastStraw_section1.ogg"))
	if Conductor.songToStream != null:
		var secondsPerBeat = 0.7 / Conductor.crotchet
		speed_scale = (4 / (10.5 * Conductor.crotchet))


func stepSync():
	if (cycle == 0):
		cycle = 2
	elif cycle == 2:
		cycle = 0
		
	frame = cycle
	play("WalkStep1")
	sfx.play()
