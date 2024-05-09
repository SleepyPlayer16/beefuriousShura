extends CharacterBody2D

var hsp = 0.0
var vsp = 0.0
var ang = 0
var colTimer = 10
var hitPlayer = false

func _ready():
	rotation_degrees = ang
	$blastZone.smolBee = true
	if (get_tree().current_scene.name == "level3") or (get_tree().current_scene.name == "level4"):
		$blastZone.damage = 0
		$blastZone.damageType = 0

func _physics_process(delta):
	if (CutsceneHandler.inCutscene):
		queue_free()
	colTimer -= 1
#	if (colTimer <= 0):
#		if ($CollisionShape2D.disabled):
#			$CollisionShape2D.disabled = false

	velocity.x = (hsp * 2) * delta
	velocity.y = (vsp * 2) * delta
#	if velocity.x < 0:
#		print("jifd")
#		$AnimatedSprite2D.scale.x = -1

	if is_on_ceiling():
		position.y += 10
		vsp *= -1
		colTimer = 10
#		$CollisionShape2D.disabled = true
		rotation_degrees *= -1


	if is_on_floor():
		position.y -= 10
		vsp *= -1
		colTimer = 10
#		$CollisionShape2D.disabled = true
		rotation_degrees *= -1
				
	if is_on_wall():
		if hsp > 0:
			position.x -= 10
		else:
			position.x += 10
		hsp *= -1
		
		colTimer = 10
#		$CollisionShape2D.disabled = true
		rotation_degrees *= -1

	move_and_slide()

func _on_timer_timeout():
	queue_free()
