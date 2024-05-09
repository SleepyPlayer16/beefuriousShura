extends CharacterBody2D

var curPhase = 1
var timerToTriggerDialogue = 4
var dialogueTimerDone = false
var introDone = false
var readyToAttack = false
var canAttack = false
var currentlyAttacking = false
var attackLoop = 0
var attackStep = 0
var rng = RandomNumberGenerator.new()
var posRNG = RandomNumberGenerator.new()
var voiceRNG = RandomNumberGenerator.new()
var target_distance = 50
var speed = 360
var smoothness = 0.7
var isFlying = false
var waitUntilLeap = 0.5
var catchedPlayer = false
var isJumping = false
var lastAttack
var attackChosen = null
var onHold = false
var tiredTimer = 5
var attackTimer = 2
var gotStruck = false
var vsp = 0.0
var hsp = 0.0
var playAClip = false
var clipTimer = 20
var textTimer = 3
var spawnedPurleBullshit = false
var changeUpAttack = false
var gotHit = false
var active = true
var transformationStep = 0
var shakeInt = 0
var difficulty = 0
var currScene
var inThirdPhase = false
var shouldGoIntoPhase2 = false

@onready var voiceLines = [$"WhoopsBroke-EN", $"CuteShield-EN", $"Bubble-EN"]
@onready var player = get_parent().get_node_or_null("player")
@onready var bossSprite = $AnimatedSprite2D
@onready var sfx_bigPunch = $TelePunchHit
@onready var telePunchHitbox = $telePunchHitbox
@onready var hurtBox = $BossHurtbox/CollisionShape2D
@onready var gotHitSfx = $GotHit
@onready var quakeWave = preload("res://scenes/boss_attacks/quakeWave.tscn")
@onready var phase2 = preload("res://scenes/bosses/caramel_phase2.tscn")

enum states{
	TELEPUNCH,
	EARTHQUAKE,
	SCARF,
	TIRED,
	LIGHTSTRUCK
}

func _ready():
	currScene = get_tree().current_scene.name
	player.maxHP = 7
	CutsceneHandler.finalBossBeginSignal.connect(fightStart)
	rng.randomize()
	if (get_tree().current_scene.name == "finalB_tstScn"):
		introDone = true
		readyToAttack = true 

	if (FinalBossManager.bossDefeated):
		bossSprite.visible = false

func _physics_process(delta):
	#if (currScene == "level3"):
		#print("WHAT THE FUCKKKKKKKKKKKKKKK")
		
	if (player.state != player.states.GAMEOVER and !FinalBossManager.bossDefeated):
		if (FinalBossManager.introPlayed) or currScene == "level3":
			if (get_tree().current_scene.name == "finalB_tstScn"):
				if (FinalBossManager.lastPhase == 2):
					FinalBossManager.lastPhase += 1
					shake(1.4)
					bossSprite.play("GotHit")
					transformationStep = 3
					player.switchPhase(bossSprite)
					await get_tree().create_timer(0.1).timeout
					player.playerSprite.play("Idle")
					Conductor.stop()
					Conductor.play(7.71)

			if (!active):
				transformationLogic()
			if (active):	
				if (attackChosen != states.SCARF):
					$ScarfGrab/col.set_deferred("disabled", true)

				if player.state == player.states.GAMEOVER:
					z_index = 0
				if (introDone):
					if (waitUntilLeap > 0):
						waitUntilLeap -= delta

				if (currScene == "finalB_tstScn"):
					if ($CanvasLayer/RichTextLabel.visible):
						if (player.state != player.states.GAMEOVER):
							if (!CutsceneHandler.inCutscene):
								Conductor.volume_db = -8
						textTimer -= delta
						if (textTimer <= 0):
							textTimer = 3
							$CanvasLayer/RichTextLabel.visible = false
					else:
						if (!CutsceneHandler.inCutscene):
							Conductor.volume_db = Conductor.musVolume
					if (playAClip):
						clipTimer -= (60*delta)
						if (clipTimer <= 0):
							playAClip = false
							clipTimer = 20
							var randClip = voiceRNG.randi_range(0, 2)
							if (randClip == 0):
								$CanvasLayer/RichTextLabel.text = "[center] ¡Oops, rompí tu escudo! [/center]"
							elif (randClip == 1):
								$CanvasLayer/RichTextLabel.text = "[center] ¡Lindo escudo, pero muy débil! [/center]"
							else:
								textTimer = 5
								$CanvasLayer/RichTextLabel.text = "[center] !Pensé que el escudo te haría rebotar como una pelota, lastima![/center]"
							$CanvasLayer/RichTextLabel.visible = true
							voiceLines[randClip].play()

				if (!readyToAttack):
					if (!introDone and CutsceneHandler.inCutscene):
						if (player.is_on_floor()):
							timerToTriggerDialogue -= delta
						if (timerToTriggerDialogue <= 0 and !dialogueTimerDone):
							dialogueTimerDone = true
							get_parent().spawnDialogue(true)
					if (CutsceneHandler.timer > 0 and bossSprite.get_animation() == "Waiting"):
						bossSprite.play("TurningAround")

				if (isFlying):
					currentlyAttacking = false
					if (player.global_position.x < global_position.x):
						bossSprite.scale.x = 1
						telePunchHitbox.position.x = -22
					else:
						bossSprite.scale.x = -1
						telePunchHitbox.position.x = 22

				if (waitUntilLeap <= 0):
					if (!isJumping):
						isJumping = true
						if (attackStep == 0):
							bossSprite.offset.y = -13
							if (!player.inBossFight):
								player.inBossFight = true
							bossSprite.play("Leap")
					if (!canAttack):
						if (player != null and readyToAttack):
							if (isFlying):
								if (onHold):
									onHold = false
								vsp = lerpf(vsp, - 100.0 + (float(player.global_position.y) - float(global_position.y)), (0.2*60)*delta)
								followPlayer(delta)
							else:
								leapAnim(delta)
				attackOpportunity(delta)
				if (!canAttack):
					velocity.y = vsp
				move_and_slide()

func attackOpportunity(delta):
	if (!canAttack and isFlying):
		attackTimer -= delta
		if (attackTimer <= 0):
			attackTimer = 2
			canAttack = true
	if canAttack:
		
#		print("print the FUCKING random attack number: ", randAttckNumber)
		if (attackLoop == 3):
			attackChosen = states.TIRED
			tiredLogic(get_physics_process_delta_time())
		if (attackLoop < 3):
			
			if (!currentlyAttacking):
				var randAttckNumber = rng.randi_range(0,2)
				if (attackChosen == null):
					match (randAttckNumber):
						0:
							attackChosen = states.TELEPUNCH
							attackPicker()
						1:
							attackChosen = states.EARTHQUAKE
							attackPicker()
						2:
							attackChosen = states.SCARF
							attackPicker()
			attackBehavior()
		

func attackBehavior():
	if (canAttack):
		if (!onHold and !currentlyAttacking):
			match (attackChosen):
				states.TELEPUNCH:
					telepunchLogic()
				states.EARTHQUAKE:
					quakeLogic()
				states.SCARF:
					scarfLogic()

func tiredLogic(delta):
	if (player.is_on_floor()) or (bossSprite.get_animation() == "GotHit"):
		tiredTimer -= get_physics_process_delta_time()
	if tiredTimer <= 0:
		reset_abunchaShit()
	if (!gotHit):
		if (!gotStruck):
			if (!onHold):
				bossSprite.play("TiredIntro")
				onHold = true
		#	print("GRAAAAAAHHHHHHHHHHH")
			vsp = lerpf(vsp, - 50.0 + (float(player.global_position.y) - float(global_position.y)), (0.2*60)*delta)
			followPlayer(delta)
			velocity.y = vsp
		else:
			shake(1.4)
			if (bossSprite.get_animation() != "LightStruck"):
				velocity.x = 0
				velocity.y = 0
				tiredTimer = 5
				$LightStruck.play()
				bossSprite.play("LightStruck")
	else:
		shake(3.4)
		vsp = 0
		hsp = 0
		velocity.x = 0
		velocity.y = 0
			

func shake(shaking_intensity):
	var random_offset = randf_range(-shaking_intensity, shaking_intensity)
	var randomNum = randi_range(-1, 1)
	bossSprite.offset.x = 0 + (random_offset)
	bossSprite.offset.y = 0 + (random_offset*randomNum)
#	if (bossSprite.get_animation() == "GotHit"):
#		bossSprite.scale.x = 1  + (random_offset) / 4
#		bossSprite.scale.y = 1  + (random_offset*randomNum) / 4

func reset_abunchaShit():
	gotStruck = false
	attackTimer = 2
	currentlyAttacking = false
	tiredTimer = 5
	attackLoop = 0
	lastAttack = null
	attackChosen = null
	attackStep = 0
	gotHit = false
	attackTimer = 2
	z_index = 0
	isFlying = true
	canAttack = false
	bossSprite.play("AirIdle")

func attackPicker():
	if (attackChosen == lastAttack):
		match(lastAttack):
			states.TELEPUNCH:
				var randAttckNumber = rng.randi_range(0,1)
				match (randAttckNumber):
					0:
						attackChosen = states.EARTHQUAKE
					1:
						attackChosen = states.SCARF
			states.EARTHQUAKE:
				var randAttckNumber = rng.randi_range(0,1)
				match (randAttckNumber):
					0:
						attackChosen = states.TELEPUNCH
					1:
						attackChosen = states.SCARF
			states.SCARF:
				var randAttckNumber = rng.randi_range(0,1)
				match (randAttckNumber):
					0:
						attackChosen = states.EARTHQUAKE
					1:
						attackChosen = states.TELEPUNCH
		

func telepunchLogic():
	if (isFlying):
		lastAttack = states.TELEPUNCH
		$ScarfGrab/col.set_deferred("disabled", true)
		isFlying = false
		$Teleport.play()
		$AtckGrunt2.play()
		bossSprite.play("Attack_TelePunch")
	vsp = 0
	velocity.x = 0
	velocity.y = 0
	if !player.is_on_floor():
		if bossSprite.get_animation() == "Attack_TelePunch" and (bossSprite.frame >= 6 and bossSprite.frame <= 8):
			bossSprite.pause()
	else:
		if bossSprite.get_animation() == "Attack_TelePunch":
			if (!bossSprite.is_playing()):
				bossSprite.play()

				global_position.y = player.global_position.y
	if (bossSprite.frame >= 5 and bossSprite.frame <= 13):
		if (z_index != 106):
			$Reappear.play()
			bossSprite.scale.x = 1
			telePunchHitbox.position.x = -22
			if player.state != player.states.GAMEOVER:
				z_index = 106
			global_position.y = player.global_position.y
		global_position.x = player.global_position.x + 30
	if bossSprite.frame == 14:
		if (telePunchHitbox.lifeTime <= 0):
			changeUpAttack = false
			$telePunchHitbox/Area2D/CollisionShape2D.set_deferred("disabled", false)
			#print("shouldAppearNow")
			telePunchHitbox.lifeTime = 13
	if bossSprite.frame > 17:
		$telePunchHitbox/Area2D/CollisionShape2D.set_deferred("disabled", true)

func scarfLogic():
	if (attackChosen == states.SCARF):
#		print("?????????????????")
		if (attackStep == 0):
			if (isFlying):
				lastAttack = states.SCARF
#				print("the fuck?")
				bossSprite.offset.y = -40.5

				global_position.y -= 20
				isFlying = false
				$Teleport.play()
				$AtckGrunt1.play()
				bossSprite.play("Attack_ScarfThrow_Startup")
			vsp = 0
			velocity.x = 0
			velocity.y = 0
			if !player.is_on_floor():
				if bossSprite.get_animation() == "Attack_ScarfThrow_Startup" and (bossSprite.frame >= 5 and bossSprite.frame < 6):
					bossSprite.pause()
			else:
				if bossSprite.get_animation() == "Attack_ScarfThrow_Startup":
					if bossSprite.frame >= 21:
						$ScarfGrab/col.set_deferred("disabled", true)
						bossSprite.play("Attack_ScarfThrow_Miss")
					if (!bossSprite.is_playing()):
						z_index = 0
						bossSprite.play()
						global_position.y = player.global_position.y - 13.5
			
			if (bossSprite.frame >= 5 and bossSprite.frame <= 13):
				if (z_index != 106):
					$Reappear.play()
					bossSprite.scale.x = 1
					telePunchHitbox.position.x = -22
					if player.state != player.states.GAMEOVER:
						z_index = 106
					global_position.y = player.global_position.y - 13.5
					var position_rand = randi_range(0, 1)
					if (get_parent().side == "center"):
						if (position_rand == 0):
							global_position.x = player.global_position.x + 100
							bossSprite.scale.x = 1
							$ScarfGrab/col.position.x = -80
	#						print("tf2")
						else:
	#						print("tf")
							bossSprite.scale.x = -1
							$ScarfGrab/col.position.x = 80
							global_position.x = player.global_position.x - 100
					if (get_parent().side == "left"):
							global_position.x = player.global_position.x + 100
							bossSprite.scale.x = 1
							$ScarfGrab/col.position.x = -80
					if (get_parent().side == "right"):
							bossSprite.scale.x = -1
							$ScarfGrab/col.position.x = 80
							global_position.x = player.global_position.x - 100
			if (bossSprite.frame >= 18):
				$ScarfGrab/col.set_deferred("disabled", false)
				if (catchedPlayer):
					attackStep += 1
					bossSprite.play("Attack_ScarfThrow_Hit")
		if (attackStep == 1):
			if (bossSprite.frame < 2):
				$ScarfGrab/col.set_deferred("disabled", true)
				player.velocity.x = 0.0
				player.velocity.y = 0.0
				player.global_position.x = lerpf(player.global_position.x, global_position.x-(132*bossSprite.scale.x), (0.5*60)*get_physics_process_delta_time())
			if (bossSprite.frame >= 2 and bossSprite.frame <= 4):
				player.velocity.x = 0.0
				player.velocity.y = 0.0
				player.global_position.x = lerpf(player.global_position.x, global_position.x-(80*bossSprite.scale.x), (0.4*60)*get_physics_process_delta_time())
				player.global_position.y = lerpf(player.global_position.y, global_position.y-70, (0.4*60)*get_physics_process_delta_time())
			if (bossSprite.frame >= 5):
				player.global_position.x = global_position.x+(132*bossSprite.scale.x)
				player.global_position.y = player.groundLvl
				player.camera.offset.y += 40
				player.shake(0.7, 2)
				Hitstun(0.15, 0.1)
				if (player.hp == player.maxHP-1):
					player.death = "Thrown"
				playerDamageHandler(1, 2)
				player.camera.zoom.x = 4
				player.camera.zoom.y = 4
				player.knockback = 100 * bossSprite.scale.x
				if player.niShield != null:
					if (player.niShield.frame >= 3):
						playAClip = true
						player.niShield.forceBreak()
					
				player.playerSprite.visible = true
				player.state = player.states.HITSTUN
				attackStep += 1
		if (attackStep == 2):
			changeUpAttack = true
			if (bossSprite.frame >= 10):
				if (z_index != 0):
					z_index = 0
					bossSprite.play("Leap")
					bossSprite.offset.y = -13
					global_position.y = player.groundLvl
				canAttack = false
				currentlyAttacking = false
				catchedPlayer = false
				changeUpAttack = false
				isJumping = false
				attackChosen = null

func quakeLogic():
	if (attackStep == 0):
		if (isFlying):
			lastAttack = states.EARTHQUAKE
			$ScarfGrab/col.set_deferred("disabled", true)
			vsp = 0
			velocity.y = 0
			velocity.x = 0
			isFlying = false
			bossSprite.play("Attack_Quake")
			attackStep += 1
	if (attackStep == 1):
		if (bossSprite.frame >= 9 and bossSprite.frame <= 14):
			global_position.y = lerp(global_position.y, float(player.groundLvl), (0.4*60)*get_physics_process_delta_time()) 
		if (bossSprite.frame > 14):
			attackStep += 1
			spawnedPurleBullshit = false
			
		if (bossSprite.frame == 11):
			if !(spawnedPurleBullshit):
				player.shake(1.1, 3)
				if player.is_on_floor():
					player.global_position.y -= 10
					player.forcefullyAirborne = true
					player.velocity.y -= 1000
					player.current_jump = 2
				spawnedPurleBullshit = true
				changeUpAttack = false
				spawnQuakeWave(-1)
				spawnQuakeWave(1)
	if (attackStep == 2):
		if (bossSprite.frame >= 24 and bossSprite.frame < 25):
			vsp -= (80*60) * get_physics_process_delta_time()
			velocity.y = vsp
			velocity.y += (0.5 * 60) *  get_physics_process_delta_time()
			changeUpAttack = true

func spawnQuakeWave(direction):
	var id = quakeWave.instantiate()
	id.dir = direction
	id.damageType = 1
	id.damage = 1
	add_child(id)
	id.global_position.x += global_position.x - (16*direction)
	id.global_position.y = player.groundLvl - 13
	

func playerDamageHandler(shieldMinus, damage):
	if damage > 1:
		player.hitDelaySfx.play()
		player.shockWaveAnimPlay.play("shockwave")
	else:
		player.floorSplatSfx.play()
	
	if (player.hp != player.maxHP):
		if (player.hp == 5):
			player.hp = 6
			player.hudLifeBar.frame = player.hp
		else:
			if player.hp == 6:
				player.hp += 1
				player.hudLifeBar.frame = player.hp
			else:
				if player.niShield != null:
					player.hp += damage - shieldMinus
				else:
					player.hp += damage
				player.hudLifeBar.frame = player.hp

func Hitstun(timeScale, duration):
	Engine.time_scale = timeScale
	await get_tree().create_timer(duration).timeout
	Engine.time_scale = 1

func fightStart():
	introDone = true
	readyToAttack = true

func spawnPhase2Instance():
	var id = phase2.instantiate()
	get_parent().add_child(id)
	id.global_position = global_position

func transformationLogic():
	if (!active):
		if (transformationStep == 0):
			transformationStep += 1
			FinalBossManager.truePhase = 2
			player.playerSprite.modulate.a = 1
			player.playerSprite.play("Idle")
			bossSprite.scale.x = 1
			bossSprite.offset.y = 0
			attackChosen = null
		if (transformationStep == 1):
			bossSprite.offset.y = 0
			if (player.playerSprite.get_animation() != "Idle"):
				player.playerSprite.play("Idle")
			if (Conductor.get_playback_position() >= 2.35 and Conductor.currSection == 2):
				bossSprite.play("Transformation1")
				transformationStep += 1
		if (transformationStep == 2):
			if (Conductor.get_playback_position() >= 4.82):
				bossSprite.play("Transformation2")
				player.playerSprite.play("Scared1")
				transformationStep += 1
		if (transformationStep == 3):
			shakeInt += 0.5 * get_physics_process_delta_time()
			shake(shakeInt)
			if (Conductor.get_playback_position() >= 7.71):
				bossSprite.play("Transformation3")
				transformationStep += 1
		if (transformationStep == 4 and Conductor.stream.resource_path == "res://music/finalBoss/mus_buzzEncount_section2.ogg" ):
			player.playerSprite.play("Scared2")
			transformationStep += 1
			bossSprite.play("GotHit")
			player.shake(1.7, 1.4)
			$TransformationScream.play()
			player.shockWaveAnimPlay.play("cutsceneWhiteFadeOut")
			Conductor.emit_signal("triggerThunder")
			player.shadow.visible = true
			player.invinFrames = 60
			player.isInvincible = false
			get_parent().songHasChanged = false
			CutsceneHandler.emit_signal("bossScream")
		if (transformationStep == 5):
			if (Conductor.get_playback_position() >= 1.80):
				player.camera.offset.x = lerp(player.camera.offset.x, 0.0, (0.1*60)*get_physics_process_delta_time())
			if (Conductor.get_playback_position() >= 2.40):
				get_parent().bossHP.frame += 1
				switchToPhase2()

func switchToPhase2():
	CutsceneHandler.inCutscene = false
	player.invinFrames = 0
	player.hud.shuraHp.visible = true
	player.isInvincible = true
	player.invinFrames = 1
	transformationStep += 1
	gotHit = false
	spawnPhase2Instance()
	gotStruck = false
	global_position.x = 9999999999
	global_position.y = 9999999999
	visible = false
	$Timer.start()
	#should be 3
	get_parent().bossHP.frame = 3

func followPlayer(_delta):
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()

	if distance > 20:
		velocity = direction * speed

func leapAnim(delta):
	if (bossSprite.get_animation() == "Leap" and bossSprite.frame >= 2):
		if vsp == 0:
			vsp -= (500*60) * delta
		else:
			vsp += (15*60) * delta

func _on_animated_sprite_2d_animation_finished():
	if (bossSprite.get_animation() == "GotHitStartup"):
		bossSprite.play("GotHit")
	if (bossSprite.get_animation() == "TiredIntro"):
		bossSprite.play("Tired")
	if (bossSprite.frame > 1):
		if (bossSprite.get_animation() == "Leap"):
			attackStep = 0
			canAttack = false
			currentlyAttacking = false
			isFlying = true
			bossSprite.play("AirIdle")
		if (bossSprite.get_animation() == "Attack_TelePunch"):
			z_index = 0
			isFlying = true
			canAttack = false
			attackChosen = null
			currentlyAttacking = false
			bossSprite.offset.y = -13
			bossSprite.play("AirIdle")
			attackLoop += 1

		if (bossSprite.get_animation() == "Attack_ScarfThrow_Miss"):
			if (z_index != 0):
				z_index = 0
				attackLoop += 1
				bossSprite.play("Leap")
				bossSprite.offset.y = -13
				global_position.y = player.groundLvl
			canAttack = false
			currentlyAttacking = false
			catchedPlayer = false
			attackChosen = null
			isJumping = false

		if (bossSprite.get_animation() == "Attack_Quake"):
			attackLoop += 1
			attackStep = 0
			canAttack = false
			currentlyAttacking = false
			bossSprite.offset.y = -13
			isFlying = true
			bossSprite.play("AirIdle")
			attackChosen = null

func _on_scarf_grab_body_entered(body):
	if (body.name == "player"):
#		print("?????")
		body.onHitstun = false
		body.invinFrames = 12
		body.isInvincible = true
		body.state = body.states.GRABBED
		catchedPlayer = true

func _on_timer_timeout():
	pass
#	queue_free()
