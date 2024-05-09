extends Node2D

var lifeTime = 0
var waitUntilTimerIsDone = false
var smolBee = false
var isLaser = false
var playerInside = false
var belongsToEye = false
var isBomb = false

@onready var player

@export var damage = 0
@export var damageType = 0
@export var hitboxType = 0
@export var knockback = 0.1

enum damageTypes {
	INSTANT_DEATH,
	BOSS_DAMAGE
}

func _process(delta):
	if (get_parent().name == "FistCollisionShape"):
		if (playerInside and player != null):
			doAttackShi(player)

	if (hitboxType != 0):
		lifeTime -= 60 * delta
		if (!smolBee and !isLaser) and self.name != "telePunchHitbox":
			if (lifeTime <= 0):
				$SprSpikeBall/Area2D/CollisionShape2D.set_deferred("disabled", true)
			else:
				$SprSpikeBall/Area2D/CollisionShape2D.set_deferred("disabled", false)

func _on_area_2d_body_entered(body):
	if (get_parent().name == "FistCollisionShape"):
		player = body
		playerInside = true
	else:
		doAttackShi(body)
	

func doAttackShi(body):
	if (body.name == "player"):
		if (belongsToEye):
			get_parent().velocity.x *= -1
			get_parent().velocity.y *= -1
			get_parent().rotation_degrees *= -1
			get_parent().deflectSfx.play()
		if (isLaser and body.form == "Super"):
			get_parent().speed *= -1
			get_parent().deflectSfx.play()
		if ((body.lastHitBy != name and body.lockout == 50) and body.visible) and body.state != body.states.GRABBED:
			body.lastHitBy = name
			if (hitboxType == 0):
				if (damageType == 0):
					body.state = body.states.DEATH
					body.explosionSfx.play()
				else:
					#fuck it we ball
					if !(body.isInvincible or body.form == "Super"):
						if (!body.isShielded):
							if (body.hitCounter < 2):
								body.onHitstun = false
								body.hitCounter += 1
								if (body.hp == body.maxHP-1):
									if (get_parent().name == "ball"):
										if get_parent().highSpeedBall:
											body.death = "Punch"
										else:
											if (body.is_on_floor()):
												body.death = "Homerun"
											else:
												body.death = "Normal"
									if (get_parent().name == "caramelEye"):
										body.death = "Homerun"
									if (isBomb):
										body.death = "Explosion"
								playerDamageHandler(body, 0)
								body.knockback = 100 * body.playerSprite.scale.x
								body.state = body.states.HITSTUN
						else:
#							if (naem.begins_with("laser")):
#								print("AJUAAAA")
							if get_parent().name == "caramelEye" or isLaser:
								if body.niShield != null:
									body.niShield.forceBreak()
									Hitstun(0.15, 0.1)
									body.camera.zoom.x = 4
									body.camera.zoom.y = 4
									body.shake(0.7, 2)
							$Hit.play()
			else:
				if !body.isInvincible:
					if (!body.isShielded):
						body.shake(0.7, 2)
						get_parent().sfx_bigPunch.play()
						if (body.hp == body.maxHP-1):
							body.death = "Punch"
							body.playerSprite.scale.x = 1
						Hitstun(0.15, 0.1)
						playerDamageHandler(body, 0)
						body.knockback = (100 * knockback) * get_parent().bossSprite.scale.x
						body.camera.zoom.x = 4
						body.camera.zoom.y = 4
						body.state = body.states.HITSTUN
					else:
						body.shake(0.7, 2)
						if (body.hp == body.maxHP-1):
							body.playerSprite.scale.x = 1
							body.death = "Punch"
						get_parent().sfx_bigPunch.play()
						$Hit.play()
						Hitstun(0.15, 0.1)
						playerDamageHandler(body, 1)
						body.camera.zoom.x = 4
						body.camera.zoom.y = 4
						body.knockback = (100 * knockback) * get_parent().bossSprite.scale.x
						if body.niShield != null:
							if (body.niShield.frame >= 3):
								get_parent().playAClip = true
								body.niShield.forceBreak()
						body.state = body.states.HITSTUN
			if (smolBee and !body.isInvincible):
				get_parent().queue_free()

func playerDamageHandler(_playa, shieldMinus):
	if damage > 1:
		_playa.hitDelaySfx.play()
		_playa.shockWaveAnimPlay.play("shockwave")
	else:
		_playa.floorSplatSfx.play()
	
	if (_playa.hp != _playa.maxHP):
		if (_playa.hp == 5):
			_playa.hp = 6
			_playa.hudLifeBar.frame = _playa.hp
		else:
			if _playa.hp == 6:
				_playa.hp += 1
				_playa.hudLifeBar.frame = _playa.hp
			else:
				_playa.hp += damage - shieldMinus
				_playa.hudLifeBar.frame = _playa.hp

func Hitstun(timeScale, duration):
	waitUntilTimerIsDone = true
	Engine.time_scale = timeScale
	await get_tree().create_timer(duration).timeout
	waitUntilTimerIsDone = false
	Engine.time_scale = 1


func _on_visible_on_screen_notifier_2d_screen_entered():
	if (!smolBee and !isLaser) and self.name != "telePunchHitbox":
		$SprSpikeBall/Area2D/CollisionShape2D.set_deferred("disabled", false)
		$SprSpikeBall.show()

func _on_visible_on_screen_notifier_2d_screen_exited():
	if (!smolBee and !isLaser) and self.name != "telePunchHitbox":
		$SprSpikeBall/Area2D/CollisionShape2D.set_deferred("disabled", true)
		$SprSpikeBall.hide()

func _on_area_2d_body_exited(_body):
	playerInside = false
