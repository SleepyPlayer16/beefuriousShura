extends AnimatedSprite2D

var player
var timerBeforeDeath = 2
var touchedPlayer = false
var playerIn = false

func _process(delta):
	if (touchedPlayer):
		if (timerBeforeDeath == 2):
			if (!String(name).begins_with("hpReplenisher")):
				$kachin.play()
				player.hudHpBar.value = 100
				player.current_jump = 0
			else:
				$hp.play()
				if (player.hp != 0):
					player.hp -= 1
			play("none")
			$CPUParticles2D.emitting = true
			$Area2D/CollisionShape2D.set_deferred("disabled", true)
		timerBeforeDeath -= delta
		if (timerBeforeDeath <= 0):
			if (!String(name).begins_with("hpReplenisher")):
				$Area2D/CollisionShape2D.set_deferred("disabled", false)
				touchedPlayer = false
				timerBeforeDeath = 2
				play("default")
			else:
				queue_free()

func _on_area_2d_body_entered(body):
	if (body.name == "player" and !touchedPlayer):
		player = body
		playerIn = true
		touchedPlayer = true

func _on_area_2d_body_exited(body):
	if (body.name == "player"):
		playerIn = false


func _on_visible_on_screen_notifier_2d_screen_entered():
	$Area2D/CollisionShape2D.set_deferred("disabled", false)

func _on_visible_on_screen_notifier_2d_screen_exited():
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
