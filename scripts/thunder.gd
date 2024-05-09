extends Sprite2D

signal thunderSignal

var rng = RandomNumberGenerator.new()
var positonDefault = 1
var curScene
var parent

func _ready():
	curScene = get_tree().current_scene.name
	parent = get_tree().current_scene
	Conductor.beatSignal.connect(triggerThunder)
	Conductor.triggerThunder.connect(triggerFUCKINGthunder)

func triggerFUCKINGthunder():
	if (!GameDataManager.paused):
		var my_random_number = int(rng.randf_range(0, 10.0))
		var my_randomPos_number = int(rng.randf_range(0, 10.0))
		if curScene != "01_tst":
			emit_signal("thunderSignal")
	#		print(Conductor.currentBeat)
			if (Conductor.currentBeat == 6):
				position.x = positonDefault * (6 * 50)
			else:
				position.x = (positonDefault * (my_randomPos_number * 50))
			$AnimationPlayer.play("thunderStruck")
			$thunder.play()
		else:
			if my_random_number <= 4 or Conductor.currentBeat == 6 or Conductor.currentBeat == 1:
				emit_signal("thunderSignal")
		#		print(Conductor.currentBeat)
				if (Conductor.currentBeat == 6):
					position.x = positonDefault * (6 * 50)
				else:
					position.x = (positonDefault * (my_randomPos_number * 50))
				$AnimationPlayer.play("thunderStruck")
				$thunder.play()


func triggerThunder():
	if (!GameDataManager.paused):
		var my_random_number = int(rng.randf_range(0, 10.0))
		var my_randomPos_number = int(rng.randf_range(0, 10.0))
		if curScene != "01_tst":
			if !parent.songHasChanged:
				if my_random_number <= 4 or Conductor.currentBeat == 6 or Conductor.currentBeat == 1:
					emit_signal("thunderSignal")
			#		print(Conductor.currentBeat)
					if (Conductor.currentBeat == 6):
						position.x = positonDefault * (6 * 50)
					else:
						position.x = (positonDefault * (my_randomPos_number * 50))
					$AnimationPlayer.play("thunderStruck")
					$thunder.play()
		else:
			if my_random_number <= 4 or Conductor.currentBeat == 6 or Conductor.currentBeat == 1:
				emit_signal("thunderSignal")
		#		print(Conductor.currentBeat)
				if (Conductor.currentBeat == 6):
					position.x = positonDefault * (6 * 50)
				else:
					position.x = (positonDefault * (my_randomPos_number * 50))
				$AnimationPlayer.play("thunderStruck")
				$thunder.play()
