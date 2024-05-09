extends Node2D

@onready var chuwa = get_parent().get_node("player")

func _process(delta):
#	if (global_position.distance_to(chuwa.global_position) > 150):
#		$AnimatedSprite2D.visible = false
#	else:
#		$AnimatedSprite2D.visible = true
	if (chuwa.state == chuwa.states.DEATH):
		if ($AnimatedSprite2D.get_animation() != "kill"):
			$AnimatedSprite2D.play("kill")
	if (chuwa.state != chuwa.states.DEATH):
		if (chuwa.followSteps[20] != null):
			if (global_position.distance_to(chuwa.global_position) > 150):
				position = chuwa.followSteps[10]
				if ($AnimatedSprite2D.get_animation() != "default"):
					$AnimatedSprite2D.play("default")
			else:
				position.x = lerp(position.x, chuwa.followSteps[10][0], (0.5 * 60) * delta)
				position.y = lerp(position.y, chuwa.followSteps[10][1], (0.5 * 60) * delta)
				if ($AnimatedSprite2D.get_animation() != "default"):
							$AnimatedSprite2D.play("default")
		if (chuwa.facingSteps[20] != null):
			$AnimatedSprite2D.scale.x = chuwa.facingSteps[10]*-1
