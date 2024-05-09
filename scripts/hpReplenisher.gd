extends CharacterBody2D

var player
var timerBeforeDeath = 2
var touchedPlayer = false
var playerIn = false
var gravity = 200
var currLvl = ""
var dir = 0

@onready var spr = $hpReplenisher

func _ready():
	currLvl = get_tree().current_scene.name
	velocity.y -= 140
	if (dir == 0):
		velocity.x = 55
	if (dir == 1):
		velocity.x = -55
	if (dir == 2):
		velocity.x = 0 

func _process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = 0.0

	if (velocity.x != 0):
		velocity.x -= 0
	#if (velocity.x < 0):
		#velocity.x = 0
	move_and_slide()
	if (touchedPlayer):
		if (timerBeforeDeath == 2):
			$hp.play()
			if (player.hp != 0):
				#if (currLvl == "level2"):
					#if (player.hp != 3):
						#player.hp -= 1
				#else:
				player.hp -= 1
				player.hudLifeBar.frame = player.hp
			spr.play("none")
			$CPUParticles2D.emitting = true
			$Area2D/CollisionShape2D.set_deferred("disabled", true)
		timerBeforeDeath -= delta
		if (timerBeforeDeath <= 0):
			queue_free()

func _on_area_2d_body_entered(body):
	if (body.name == "player" and !touchedPlayer):
		player = body
		playerIn = true
		touchedPlayer = true

func _on_area_2d_body_exited(body):
	if (body.name == "player"):
		playerIn = false
