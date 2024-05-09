extends Node2D

@export var teleportTo = "none"

@onready var player = get_parent().get_node_or_null("player")

var transitionActive = false
var wait = false

func _process(delta):
	if (transitionActive):
		$CanvasLayer/ColorRect.modulate.a = lerp($CanvasLayer/ColorRect.modulate.a, 1.1, (0.4 * 60) * delta)
		if ($CanvasLayer/ColorRect.modulate.a >= 1.0):
			if (!get_parent().entered_abandonedHouse):
				if (!wait):
					wait = true
					playerTP(true)
			else:
				if (!wait):
					wait = true
					playerTP(false)
	else:
		if ($CanvasLayer/ColorRect.modulate.a > 0.0):
			$CanvasLayer/ColorRect.modulate.a = lerp($CanvasLayer/ColorRect.modulate.a, 0.0, (0.2 * 60) * delta)

func playerTP(entered):
	player.camera.position_smoothing_enabled = false
	player.velocity.y = 0
	player.velocity.x = 0
	player.state = player.states.IDLE
	player.global_position = get_parent().get_node(teleportTo).global_position
	get_parent().entered_abandonedHouse = entered
	player.camera.position_smoothing_enabled = true

func _input(event):
	if (get_parent().canTeleport):
		if (event.is_action_pressed("ui_up") and player != null):
			if ($Timer.is_stopped()):
				if (player.is_on_floor()):
					if (global_position.distance_to(player.global_position) <= 20):
						$AudioStreamPlayer.play()
						transitionActive = true
						$Timer.start()
						player.talking = true
						get_parent().canTeleport = false

func _on_timer_timeout():
	wait = false
	$AudioStreamPlayer.play()
	get_parent().tpTimer.start()
	player.talking = false
	transitionActive = false
	
