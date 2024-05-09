extends Node2D

var activated = false
var disabled = false

func _physics_process(_delta):
	if (disabled):
		$checkSprite.frame = 1

func _on_area_2d_body_entered(body):
	if (body.name == "player" and !disabled):
		$checkSprite.frame = 1
		if (!activated):
			body.checkPoint(global_position)
			activate()
			$CheckHit.play()

func activate():
	activated = true
	for checkpoint in get_tree().get_nodes_in_group("checkpointGroup"):
		if checkpoint.get_index() < self.get_index():
			checkpoint.set_deferred("disabled", true)


func _on_visible_on_screen_notifier_2d_screen_entered():
	$Area2D/CollisionShape2D.set_deferred("disabled", false)
	$checkSprite.show()

func _on_visible_on_screen_notifier_2d_screen_exited():
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	$checkSprite.hide()
