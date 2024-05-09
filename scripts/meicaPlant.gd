extends CharacterBody2D

var spawnedHp = false
var spawns = 0
var dir = 0

@onready var hpGenTimer = $Timer
@onready var hpSpawnSfx = $hpSpawn
@onready var hp = preload("res://scenes/other/hpReplenisher.tscn")

#	velocity.y -= 20
#	velocity.x = 20

func _physics_process(_delta):
	if (spawns < 3):
		if ($plantSpr.get_animation() == "GenerateHP" and $plantSpr.frame >= 5):
			if (!spawnedHp):
				createHP()
				hpSpawnSfx.play()
				spawnedHp = true
				spawns += 1
#	if not is_on_floor():
#		velocity.y += gravity * delta
#	if (velocity.x != 0):
#		velocity.x -= (0.5*60)*delta
#	move_and_slide()
func createHP():
	var id = hp.instantiate()
	id.dir = dir
	get_tree().current_scene.add_child(id)
	id.global_position = global_position
	id.global_position.y -= 15
	dir += 1

func _on_timer_timeout():
	if ($plantSpr.get_animation() == "Spawn"):
		spawnedHp = false
		$plantSpr.play("GenerateHP")

func _on_plant_spr_animation_finished():
	if ($plantSpr.get_animation() == "GenerateHP"):
		if (spawns < 3):
			$plantSpr.play("Spawn")
			$plantSpr.frame = 2
			hpGenTimer.wait_time = 5
			hpGenTimer.start()
		else:
			$plantSpr.play("Despawn")
	if ($plantSpr.get_animation() == "Despawn" and $plantSpr.frame != 0):
		queue_free()
