extends Node2D

var shouldDisappear = false
var disappearTimer = 1
func _process(delta):
	position.y -= (1.2 * 60) * delta
	if (shouldDisappear):
		$Texts.modulate.a -= (0.1 * 60) * delta
		disappearTimer -= delta
		if (disappearTimer <= 0):
			queue_free()

func _on_timer_timeout():
	shouldDisappear = true
