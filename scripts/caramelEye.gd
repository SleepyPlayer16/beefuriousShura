extends CharacterBody2D

var spawning = true
var vsp = 0.0
var hsp = 0.0
var speed = 360
var attackTimer = 2
var attackStep = 0
var curAttack = null
var lastAttack = null
var isAttacking = false
var attckNumbLoop = 0
var active = true
var difficulty = 0

#HomingAttack variables
var homingTimer = 0.3
var rotates = false
var homingAtckRepetition = 1
var playerPos

#LaserSpinAttack variables
var spinSpeed = 1
var duration = 5
var caramelBeenadoAtck = false
var randomNumb = RandomNumberGenerator.new()
var lastPhase = false

#grabAttack variables
var launchedPlayer = false

@onready var parent = null
@onready var bombExp = preload("res://scenes/boss_attacks/EyeBomb.tscn")
@onready var laser = preload("res://scenes/boss_attacks/laser.tscn")
@onready var afterImage = preload("res://scenes/afterImage.tscn")
@onready var pillar = preload("res://scenes/boss_attacks/eyePillar.tscn")
@onready var player = get_parent().get_node_or_null("player")
@onready var bossSprite = $bossSprite
@onready var laserShootPos = $bossSprite/LaserShootPos
@onready var afterImageTimer = $AfterImageTimer
@onready var laserShootTimer = $LaserShootTimer
@onready var hitbox = $blastZone/Area2D/CollisionShape2D

@onready var wallClickSfx = $WallClick
@onready var dashSfx = $Dash
@onready var dashPrepareSfx = $DashPrepare
@onready var dashSfx2 = $Dash2
@onready var deflectSfx = $LaserPew2


enum attacks{
	HOMING,
	SPIN,
	GRAB,
	TIRED
}

func _ready():
	dashPrepareSfx.play()
	velocity.y += 20


func _physics_process(delta):
	if (player.state != player.states.GAMEOVER):
		if (parent != null):
			if (parent.defeated and active):
				active = false
			if (parent.inThirdPhase and difficulty != 2):
				$blastZone.belongsToEye = true
				lastPhase = true
				difficulty = 2

		if (active):
			if (player.is_on_floor() and launchedPlayer):
				playAnim("Attack_LaserSpinEnd")
				launchedPlayer = false
				resetAttackStuff()
			if !(spawning):
				if (!isAttacking):
					vsp = lerpf(vsp, - 100.0 + (float(player.global_position.y) - float(global_position.y)), (0.2*60)*delta)
					look_at(player.position*bossSprite.scale.x)
					followPlayer(delta)
					velocity.y = vsp
			else:
				velocity.y -= (2*60)*delta
				velocity.x += ((-3*bossSprite.scale.x)*60)*delta
			
			attackPick(delta)
			move_and_slide()
		else:
			if (visible):
				hide()
	
func attackPick(delta):
	if (!launchedPlayer):
		if (attackTimer > 0):
			attackTimer -= delta
		else:
			if (!isAttacking):
				isAttacking = true
				match(attckNumbLoop):
					0:
						dashPrepareSfx.play()
						curAttack = attacks.HOMING
					1:
						curAttack = attacks.SPIN
					2:
						curAttack = attacks.GRAB
					3:
						curAttack = attacks.TIRED

	attackBehavior(delta)
	
func attackBehavior(_delta):
	if (isAttacking):
		match(curAttack):
			attacks.HOMING: 
				attackHoming(_delta)
			attacks.SPIN:
				attackRotateLaser(_delta, true, 100.0, 0.2)
			attacks.GRAB:
				if (difficulty >= 2 and !lastPhase):
					attackGrabLogic(_delta)
				else:
					curAttack = attacks.TIRED
			attacks.TIRED:
				tiredStuff(_delta)

func tiredStuff(_delta):
	if (getAnim() != "Tired"):
		parent.onHold = false
		playAnim("Tired")
	velocity.x = lerp(velocity.x, 0.0, (0.02 * 60) * _delta)
	velocity.y = lerp(velocity.y, 0.0, (0.02 * 60) * _delta)
	rotation_degrees += (0.2 * 60) * _delta
	parent.tiredLogic(_delta)

func attackGrabLogic(_delta):
	if (parent.attackStep == 0):
		if (!launchedPlayer):
			duration = 9999
			parent.attackStep += 1
			parent.bossSprite.play("Attack_Throw")
			parent.tpSfx.play()
	if (parent.attackStep == 1):
		if (parent.bossSprite.get_animation() == "Attack_Throw"):
			if (parent.bossSprite.frame >= 4):
				parent.tp2Sfx.play()
				parent.attackStep += 1
	if (parent.attackStep == 2):
		parent.velocity.y = 0
		parent.velocity.x = 0
		parent.hsp = 0
		parent.vsp = 0
		parent.z_index = player.z_index + 1
		parent.global_position.x = player.global_position.x - 30
		parent.global_position.y = player.global_position.y - 5
		if (parent.bossSprite.get_animation() == "Attack_Throw"):
			if (parent.bossSprite.frame >= 12):
				player.velocity.x = 0
				player.velocity.y = 0
				player.current_emotion = player.emotions.SAD
				player.state = player.states.THROWN
				parent.attackStep += 1
	if (parent.attackStep == 3):
		parent.velocity.y = 0
		parent.velocity.x = 0
		parent.hsp = 0
		parent.vsp = 0
		if (parent.bossSprite.get_animation() == "Attack_Throw"):
			if (parent.bossSprite.frame >= 17):
				player.global_position.y -= 10
				player.forcefullyAirborne = true
				player.velocity.y -= 985
				player.current_jump = 2
				player.state = player.states.IDLE
				parent.attackStep += 1
				launchedPlayer = true
				parent.attackStep = 0
	if (launchedPlayer and difficulty >= 3):
		attackRotateLaser(_delta, false, -190.0, 0.1)

#	if (attackStep == 3):
#		if (parent.bossSprite.getAnim() == "Attack_Throw"):
#			if (parent.bossSprite.frame >= 12):

func attackRotateLaser(_delta, spawnWalls, direction, speedLimit):
	if (attackStep == 0):
		rotation_degrees = 0
		vsp = 0.0
		hsp = 0.0
		velocity.y = 0.0
		velocity.x = 0.0
		attackStep += 1
		playAnim("Attack_LaserSpin")
		if (spawnWalls and difficulty >= 1):
			wallClickSfx.play()
			instantiatePillar(80)
			instantiatePillar(-80)
	if (attackStep == 2):
		if (difficulty >= 2):
			if (!caramelBeenadoAtck):
				parent.attackStep = 0
				caramelBeenadoAtck = true
				parent.bossSprite.play("Attack_beeNado")
		parent.attackLogicBeenado()
		if (duration > 0):
			duration -= _delta
			if (laserShootTimer.wait_time > speedLimit):
				if (!lastPhase):
					laserShootTimer.wait_time -= (0.002 * 60) * _delta
				else:
					laserShootTimer.wait_time -= (0.05 * 60) * _delta
			if (!lastPhase):
				spinSpeed += (0.02 * 60) * _delta
			else:
				spinSpeed += (0.01 * 60) * _delta
			var randSpeed = randomNumb.randf_range(0.1, 0.8)
			if (!lastPhase):
				rotation_degrees += ((randSpeed + spinSpeed) * 60) * _delta
			else:
				look_at(player.position*bossSprite.scale.x)
			vsp = lerpf(vsp, - direction + (float(player.global_position.y) - float(global_position.y)), (0.2*60)*_delta)
			followPlayer(_delta)
			velocity.y = vsp
			speed = 560
		else:
			if (!launchedPlayer):
				attackStep += 1

	if (attackStep == 3):
		if (getAnim() != "Attack_LaserSpinEnd"):
			lastAttack = curAttack
			playAnim("Attack_LaserSpinEnd")
		rotation_degrees = lerp(rotation_degrees, 0.0, (0.5 * 60) * _delta)
#			resetAttackStuff()

func attackHoming(_delta):
	if (attackStep == 0):
		afterImageTimer.stop()
		hitbox.set_deferred("disabled", true)
		speed = 250
		vsp = 0.0
		hsp = 0.0
		if (position.y < player.position.y):
			vsp = lerpf(vsp, (float(player.global_position.y) - float(global_position.y)), (0.2*60)*_delta)

		if (position.x <= player.position.x):
			hsp = lerpf(hsp, + 500.0 + (float(player.global_position.x) - float(global_position.x)), (0.2*60)*_delta)
		else:
			hsp = lerpf(hsp, - 500.0 + (float(player.global_position.x) - float(global_position.x)), (0.2*60)*_delta)
		followPlayer(_delta)
		velocity.y = vsp
		velocity.x = hsp
		if (homingAtckRepetition == 1):
			playAnim("Attack_HomingStartup")
		else:
			playAnim("Spawn")
		var direction = (player.global_position - global_position).normalized()
		playerPos = direction
	if (attackStep == 1):
		attackStep += 1
		if (homingAtckRepetition == 1 or homingAtckRepetition == 3 or homingAtckRepetition == 5) and (difficulty >= 1):
			spawnBomb()
		dashSfx.play()
		dashSfx2.play()
		hitbox.set_deferred("disabled", false)
		look_at(player.position*bossSprite.scale.x)
		if (!lastPhase):
			velocity.x = ((playerPos[0] * 700) * 60) * _delta
			velocity.y = ((playerPos[1] * 700) * 60) * _delta
		else:
			velocity.x = ((playerPos[0] * 1720) * 60) * _delta
			velocity.y = ((playerPos[1] * 1720) * 60) * _delta
	if (attackStep == 2):
		homingTimer -= _delta
		if (homingTimer <= 0):
			if (homingAtckRepetition != 5):
				if (homingAtckRepetition == 2):
					if (difficulty >= 2):
						parent.bossSprite.play("Attack_ShootingStar")
				attackStep = 0
				velocity.x = 0.0
				velocity.y = 0.0
				playerPos = null
				homingAtckRepetition += 1
				dashPrepareSfx.play()
				if (!lastPhase):
					homingTimer = 0.4
				else:
					homingTimer = 0.2
			else:
				lastAttack = curAttack
				resetAttackStuff()
#				print("GGRRRAHHHHH")
				if (attckNumbLoop == 3):
					attckNumbLoop = 0
				else:
					attckNumbLoop += 1
		else:
			if (afterImageTimer.is_stopped()):
				afterImageTimer.start()

func instantiateAfterImage():
	var id = afterImage.instantiate()
	id.texture = bossSprite.sprite_frames.get_frame_texture(bossSprite.get_animation(), bossSprite.frame)
	add_child(id)
	id.modulate = id.colors[1]
	id.scale.x = bossSprite.scale.x
	id.rotation_degrees = rotation_degrees
	id.z_index = z_index
	id.global_position = global_position

func instantiateLaser():
	var laserId = laser.instantiate()
	laserId.dir = ($bossSprite/LaserShootPos.global_position - global_position).normalized()
	laserId.global_position = $bossSprite/LaserShootPos.global_position
	laserId.rotation_degrees = rotation_degrees
	get_tree().current_scene.add_child(laserId)

func instantiatePillar(playerOffset):
	var pillarId = pillar.instantiate()
	get_tree().current_scene.add_child(pillarId)
	pillarId.position.x = player.position.x - playerOffset
	pillarId.position.y = player.groundLvl + 15
func resetAttackStuff():
	spinSpeed = 1
	duration = 5
	velocity.x = 0.0
	velocity.y = 0.0
	vsp = 0.0
	hsp = 0.0
	speed = 360
	attackStep = 0
	isAttacking = false
	curAttack = null
	attackTimer = 2
	homingAtckRepetition = 1
	homingTimer = 0.3
	hitbox.set_deferred("disabled", true)
	afterImageTimer.stop()
	laserShootTimer.stop()
	laserShootTimer.wait_time = 0.4
	parent.attackStep = 0
	parent.bossSprite.play("AirIdleNoEye")
	caramelBeenadoAtck = false

func attackSpin(_delta):
	pass

func spawnBomb():
	var id = bombExp.instantiate()
	add_child(id)
	id.top_level = true
	id.global_position = global_position
	id.z_index = z_index

func followPlayer(_delta):
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()

	if distance > 20:
		velocity = direction * speed

func _on_boss_sprite_animation_finished():
	if (getAnim() == "Spawn" or getAnim() == "Attack_HomingStartup"):
		if (!isAttacking):
			spawning = false
			velocity.y = 0.0
			velocity.x = 0.0
			bossSprite.scale.x = 1
			bossSprite.material.set("shader_parameter/line_color", Color(1, 0.85, 0.25, 1.0))
			playAnim("Idle")
		else:
			attackStep = 1
			playAnim("Idle")

	if (getAnim() == "Attack_LaserSpin"):
		attackStep += 1
		laserShootTimer.start()
	if (getAnim() == "Attack_LaserSpinEnd"):
		resetAttackStuff()
		parent.attackStep = 0
		playAnim("Idle")
		if (attckNumbLoop == 3):
			attckNumbLoop = 0
		else:
			attckNumbLoop += 1

func getAnim():
	return bossSprite.get_animation()

func playAnim(animName: String):
	bossSprite.play(animName)

func _on_after_image_timer_timeout():
	instantiateAfterImage()

func _on_laser_shoot_timer_timeout():
	if (attackStep == 2):
		instantiateLaser()
