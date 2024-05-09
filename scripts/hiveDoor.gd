extends StaticBody2D

var playerCollided = false


func _on_area_2d_body_entered(body):
	if (body.name == "player" and !playerCollided):
		playerCollided = true
		$CollisionShape2D.set_deferred("disabled", false)
		$hiveDoor.play("default")
		$Door.play()
