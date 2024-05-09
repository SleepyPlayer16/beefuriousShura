extends CharacterBody2D

signal ballDone

@onready var afterImageTimer = $Timer
@onready var afterImage = preload("res://scenes/afterImage.tscn")
@onready var scene = get_tree().get_current_scene()
@onready var wallCollideSfx = $WallCollide
@onready var shockwave = preload("res://scenes/FX/invertionShockWave.tscn")
@onready var player = get_tree().current_scene.get_node_or_null("player")

var hDir = 1
var anticipationTimer = 0
var vDir = 1

var highSpeedBall = false
var speed = -40
var speedVertical = 40
var speedIncrease = 400
var rng = RandomNumberGenerator.new()
var timer = 7
var spawnSecondShockWave = false

func _ready():
	
	rng.randomize()
	afterImageTimer.start()
	#randomize the horizontal speed a lil bit just to avoid repetitive patterns as much as possible
	var randoSpeedo = rng.randi_range(15, 40)
	speed = -randoSpeedo * hDir
	if (highSpeedBall):
		timer = 5.55

func _process(delta):
	if (anticipationTimer > 0):
		anticipationTimer -= delta
		scene.shake(0.02, 1)
	else:
		if (!highSpeedBall):
			timer -= delta
			if timer <= 0:
				if !$CollisionShape2D.disabled:
					$CollisionShape2D.set_deferred("disabled", true)
					get_parent().attackStep += 1
			speedIncrease += (280 * delta)
			if (scale.x < 4):
				scale.x += (0.5)*delta
				scale.y = scale.x
			velocity.x = (speed * speedIncrease) / 115
			velocity.y = (speedVertical * speedIncrease) / 115
		else:
			if (!spawnSecondShockWave):
				spawnSecondShockWave = true
				scene.cam.offset.x = 0
				scene.cam.offset.y = 0
				CutsceneHandler.emit_signal("shockWaveSignal")
				
			timer -= delta
			if timer <= 0:
				if !$CollisionShape2D.disabled:
					$CollisionShape2D.set_deferred("disabled", true)
					get_parent().attackStep += 1
			speedIncrease += (30 * delta)
			if (scale.x < 12):
				scale.x += (0.03 * 60)*delta
				scale.y = scale.x
			var rngSpd = rng.randf_range(1, 200)
			velocity.x = (speed * (speedIncrease * 8) + rngSpd) / 110
			velocity.y = (speedVertical * speedIncrease  * 8 + rngSpd) / 110

	move_and_slide()
	
	if (player.state != player.states.GAMEOVER):
		if (is_on_floor()):
			scene.shake(0.02, 1)
			speedVertical *= -1
			wallCollideSfx.play()
		if (is_on_ceiling()):
			speedVertical *= -1
			scene.shake(0.02, 1)
			wallCollideSfx.play()
		if (is_on_wall()):
			speed *= -1
			scene.shake(0.02, 1)
			wallCollideSfx.play()
	else:
		get_parent().superBallHitSfx.stop()
		get_parent().ballHitSfx.stop()
	
#	if (rcBottom.is_colliding() and vDir == 1):
#		if rcBottom.get_collider().name != "player":
#			vDir = -1
#			speedVertical *= -1
#	if (rcTop.is_colliding() and vDir == -1):
#		if rcTop.get_collider().name != "player":
#			vDir = 1
#			speedVertical *= -1
#	if (rcLeft.is_colliding() and hDir == 1):
#		if rcLeft.get_collider().name != "player":
#			hDir = -1
#			speed *= -1
#	if (rcRight.is_colliding() and hDir == -1):
#		if rcRight.get_collider().name != "player":
#			hDir = 1
#			speed *= -1

func spawnNegativeZone():
	var negativeZone = shockwave.instantiate()
	negativeZone.top_level = true
	negativeZone.global_position = global_position
	negativeZone.expansionSpeed = 120
	add_child(negativeZone)

func _on_area_2d_body_entered(body):
	if !(body.name == "player" and body.name == "rosa" and body.name == "celeste"):
		pass

func instantiateAfterImage():
	var id = afterImage.instantiate()
	id.texture = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.get_animation(), $AnimatedSprite2D.frame)
	id.modulate = id.colors[3]
	id.scale.x = scale.x
	id.scale.y = scale.y
	add_child(id)
	
	id.global_position = global_position

func _on_timer_timeout():
	instantiateAfterImage()
