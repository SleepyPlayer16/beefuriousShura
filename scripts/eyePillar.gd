extends StaticBody2D

func _on_timer_timeout():
	$AnimatedSprite2D.play("Despawn")

func _on_animated_sprite_2d_animation_finished():
	if ($AnimatedSprite2D.get_animation() == "Despawn"):
		queue_free()
