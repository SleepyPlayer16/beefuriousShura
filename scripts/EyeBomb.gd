extends Node2D

func _ready():
	$blastZone.isBomb = true

func _process(_delta):
	if ($AnimatedSprite2D.get_animation() == "Explosion"):
		if ($AnimatedSprite2D.frame >= 4):
			$blastZone/Area2D/CollisionShape2D.set_deferred("disabled", true)

func _on_timer_timeout():
	$blastZone/Area2D/CollisionShape2D.set_deferred("disabled", false)
	$AnimatedSprite2D.play("Explosion")
	$Exp.play()


func _on_animated_sprite_2d_animation_finished():
	if ($AnimatedSprite2D.get_animation() == "Explosion"):
		queue_free()
