extends Node2D

@onready var beeScene = preload("res://scenes/boss_attacks/smolBee.tscn")
@onready var player = get_parent().get_node_or_null("player")

var hasBeenPulled = false
var beeSpeed = 5000
var playerIn = false
var explodeRng = RandomNumberGenerator.new()
var pulled = false
var spawnbees = false
var resetTimer = 6
var canBeActivated = true
var hasChanceToExplode = false
var prepareForDeletion = false

func _ready():
#	if (name == "beeBomb2"):
	if (FinalBossManager.bossDefeated):
		prepareForDeletion = true
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		hide()
#		print(name)
	CutsceneHandler.bossScream.connect(bossScreamExplode)

func _process(delta):
#	if (Input.is_action_just_pressed("jump")):
#		beeSpawn()

	if (!prepareForDeletion):
		if ($AnimatedSprite2D.get_animation() == "Explosion" and $AnimatedSprite2D.frame >= 3):
			if (!spawnbees):
				spawnbees = true
				beeSpawn()

		if ($AnimatedSprite2D.get_animation() == "Explosion" and $AnimatedSprite2D.frame >= 6):
			modulate.a = 0
		else:
			modulate.a = lerp(modulate.a, 1.0, (0.08*60)*delta)
		if (pulled and resetTimer > 0):
			resetTimer -= delta
			if (resetTimer <= 0):
				$AnimatedSprite2D.play("Idle")
				$AnimatedSprite2D/AnimatedSprite2D.play("Idle")
				resetTimer = 5
				spawnbees = false
				pulled = false
				playerIn = false
				hasChanceToExplode = false

		if (playerIn and player != null):
			if !pulled:
				pulled = true
				$AudioStreamPlayer2D.play()
				$AnimatedSprite2D.play("Explosion")
				$AnimatedSprite2D/AnimatedSprite2D.play("Pull")
		if (player.forcefullyAirborne):
			if (!hasChanceToExplode):
				var explosionChance = explodeRng.randi_range(-10, 10)
				hasChanceToExplode = true
				if (explosionChance >= 5):
					if !pulled:
						pulled = true
#						if (name == "beeBomb"):
#							$AudioStreamPlayer2D.play()
						$AnimatedSprite2D.play("Explosion")
						$AnimatedSprite2D/AnimatedSprite2D.play("Pull")

func bossScreamExplode():
	if (name == "beeBomb2"):
		$AudioStreamPlayer.play()
	$AnimatedSprite2D.play("Explosion")
	$AnimatedSprite2D/AnimatedSprite2D.play("Pull")
	prepareForDeletion = true
	$Timer.start()

func beeSpawn():
	createBee(0,-beeSpeed,-90,position)
	createBee(beeSpeed/1.5,-beeSpeed/1.5,-45,position)
	createBee(beeSpeed,0,0,position)
	createBee(beeSpeed/1.5,beeSpeed/1.5, 45,position)
	createBee(0,beeSpeed,90,position)
	createBee(-beeSpeed/1.5,beeSpeed/1.5, 135,position)
	createBee(-beeSpeed,0, -180,position)
	createBee(-beeSpeed/1.5,-beeSpeed/1.5, -135,position)

func createBee(hsp, vsp, ang, pos):
	var b = beeScene.instantiate()
	b.hsp = hsp
	b.vsp = vsp
	b.ang = ang
	b.position = pos
	add_child(b)

func _on_area_2d_body_entered(body):
	if (body.name == "player" or body.name == "caramel"):
		if (canBeActivated):
			playerIn = true


func _on_area_2d_area_entered(area):
	if area.name == "bombActivation":
		if area.get_parent().isFlying:
			if (canBeActivated):
				if !pulled:
					pulled = true
					$AudioStreamPlayer2D.play()
					$AnimatedSprite2D.play("Explosion")
					$AnimatedSprite2D/AnimatedSprite2D.play("Pull")


func _on_timer_timeout():
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered():
	$Area2D/CollisionShape2D.set_deferred("disabled", false)
	$AnimatedSprite2D.show()


func _on_visible_on_screen_notifier_2d_screen_exited():
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.hide()
