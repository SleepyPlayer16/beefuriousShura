extends StaticBody2D

var hasBeenBroken = false
var timer = 2

func _process(delta):
	if (hasBeenBroken):
		$CollisionShape2D.set_deferred("disabled", true)
		timer -= delta
		if (timer <= 0):
			queue_free()

func _on_area_2d_body_entered(body):
	if body.name == "player":
		if (!hasBeenBroken):
			hasBeenBroken = true
			$BreakableBlock.visible = false
			$AudioStreamPlayer.play()
			$CPUParticles2D.emitting = true
