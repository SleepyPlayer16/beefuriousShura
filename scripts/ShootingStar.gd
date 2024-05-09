extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var gravity = 650
var hasExploded = false

func _ready():
	$blastZone.isBomb = true

func _physics_process(delta):

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if ($AnimatedSprite2D.get_animation() != "Explode"):
			$AnimatedSprite2D.play("Explode")
		else:
			if ($AnimatedSprite2D.frame >= 5 and !hasExploded):
				hasExploded = true
				$Explode.play()
				$blastZone/Area2D/CollisionShape2D.set_deferred("disabled", false)
			if ($AnimatedSprite2D.frame > 7  and hasExploded):
				$blastZone/Area2D/CollisionShape2D.set_deferred("disabled", true)
	move_and_slide()


func _on_animated_sprite_2d_animation_finished():
	if ($AnimatedSprite2D.get_animation() == "Explode"):
		queue_free()
