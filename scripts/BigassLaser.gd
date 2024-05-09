extends Node2D

var deleteTimer = 5

func _process(delta):
	deleteTimer -= delta
	if (deleteTimer <= 0):
		queue_free()

func _on_animated_sprite_2d_animation_finished():
	if ($AnimatedSprite2D.get_animation() == "default"):
		$AnimatedSprite2D.play("Loop")
