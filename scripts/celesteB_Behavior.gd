extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var introHasLanded = false
var introHasExploded = false
var tauntedPlayer = false
var spinSfxPlayed = false
var introDone = false
var canSpawnSlash = true
var isAttacking = false
var canAttack = false
var attackTimer = 2
var speedup = 1
var textTimer = 3
var myTurn = false
var groundLevel = 0
var canFall = true
var timer = 2
var onHold = false
var waitForTurn = false
var respawnDone = false
var slashesThrown = 0
var rng = RandomNumberGenerator.new()
var soundRng = RandomNumberGenerator.new()
var attackChosen = null
var attackStep = 0
var inAttackPhase = false
var homingSpeedTimerReduction = 0.010
var lastAttack = null
var warningSpriteTimer = 0.5
var inWarningState = false
var currentWarningNumber = 0
var playerLocation = null
var homingAttacks = 0
var attackLoop = 0 #should start at 0
var gotStruck = false
var explosions = 0
var is_shaking = false
var hitTimer = 2 
var gotHit = false
var dead = false
var isOffScreen = false
var tiredTimer = 3
var killCutsceneTimer = 1
var wentOffBounds = false
var hasSpawneDiag = false
var original_position = null
var hits = 0
var expTimerSpawn = 0.5
var atckGruntRotation = 0
var tauntTimer = 0.4
var playAClip = false

@onready var celesteMarker = get_parent().get_node("celesteMarkerInitialPos")
@onready var purpleSlash = preload("res://scenes/boss_attacks/purpleSlash.tscn")
@onready var ball = preload("res://scenes/boss_attacks/ball.tscn")
@onready var negative = preload("res://scenes/FX/invertionShockWave.tscn")

@onready var bossSprite = $AnimatedSprite2D
@onready var batSlashSfx = $BatSlash
@onready var warningIndicatorSpr = $SprAttackDangerIndicator
@onready var warningOneSfx = $warningSound1
@onready var warningTwoSfx = $warningSound2
@onready var jumpSfx = $Jump
@onready var smolJumpSfx = $SmolJump
@onready var landSnowSfx = $SnowLand
@onready var speenSfx = $Speeen
@onready var infiniteSpeenSfx = $InfiniteSpeen
@onready var homingAttackSfx = $HomingAttack
@onready var homingAttackOvershootSfx = $HomingAttackOverShoot
@onready var blastZone = $blastZone/Area2D/CollisionShape2D
@onready var ballMarker = $AnimatedSprite2D/BallMarker
@onready var ballHitSfx = $BallHit
@onready var screamSfx = $Scream
@onready var chargeBatSfx = $ChargeBat
@onready var superBallHitSfx = $BallHit2
@onready var atckGrunts = [$AttackGrunt1, $AttackGrunt2, $AttackGrunt3, $AttackGrunt4]
@onready var gotHitSounds = $GotHit1
@onready var tauntSounds = [$Taunt1, $Taunt2, $Taunt3]

@onready var stockExp = preload("res://scenes/FX/stockExplosion.tscn")
@onready var jumpDustFx = preload("res://scenes/FX/jumpDust.tscn")

@onready var player = get_parent().get_node_or_null("player")
@onready var portrait = preload("res://sprites/celeste/CelesteNormal.png")

enum states{
	PURPLESLASH,
	MOLE,
	DANGEROUS_ALLIANCE,
	TIRED,
	LIGHTSTRUCK,
	DAMAGED
}

func _ready():
	if (CutsceneHandler.playerHasDied):
		speedup = 2
	Conductor.fourthSignal.connect(playIdle)
	$AnimatedSprite2D.scale.x = -1
	$AnimatedSprite2D.speed_scale = 4 * speedup
	blastZone.set_deferred("disabled", true)
	$Fall.play()
	rng.randomize()

func _physics_process(delta):
	if (attackChosen != states.LIGHTSTRUCK):
		bossSprite.offset = Vector2(0, 0)
	if (player.state == player.states.GAMEOVER and !tauntedPlayer):
		tauntTimer -= delta
		if (tauntTimer <= 0 and myTurn):
			var rngSound = soundRng.randi_range(0,2)
			tauntSounds[rngSound].play()
			playAClip = true
			tauntedPlayer = true
		
	if (player.state != player.states.GAMEOVER):
		introStuff(delta)
		if (myTurn):
			if (!get_tree().current_scene.get_node("Fist2").canBeActivated):
				get_tree().current_scene.get_node("Fist2").canBeActivated = true
			attackWaitTime(delta)
			attackBehavior(delta)
		
		if !isAttacking and introDone:
			if bossSprite.get_animation() != "DamageTaken":
				if (get_parent().get_node("player").position.x <= position.x):
					bossSprite.scale.x = 1
				else:
					bossSprite.scale.x = -1

		if bossSprite.get_animation() == "GroundRise":
			if bossSprite.frame == 18:
				if (!smolJumpSfx.playing):
					smolJumpSfx.play()
			if bossSprite.frame == 22:
				if (!landSnowSfx.playing):
					landSnowSfx.play()

		move_and_slide()

	if ($CanvasLayer/RichTextLabel.visible):
		if (player.state != player.states.GAMEOVER):
			if (!CutsceneHandler.inCutscene):
				Conductor.volume_db = -8
		textTimer -= delta
		if (textTimer <= 0):
			textTimer = 3
			$CanvasLayer/RichTextLabel.visible = false
	else:
		if (!CutsceneHandler.inCutscene and player.state != player.states.GAMEOVER):
			Conductor.volume_db = Conductor.musVolume
	if (playAClip):
		playAClip = false
		textTimer = 3
		if (tauntSounds[0].playing):
			$CanvasLayer/RichTextLabel.text = "[center] No puedo creer que mi hermana perdió contra ti. [/center]"
		elif (tauntSounds[1].playing):
			$CanvasLayer/RichTextLabel.text = "[center] ¿Alguna vez jugaste béisbol? Sí... Yo tampoco. [/center]"
		elif (tauntSounds[2].playing):
			$CanvasLayer/RichTextLabel.text = "[center] Vamos gata, ¡incluso mi abuela puede esquivar eso! [/center]"
		elif (gotHitSounds.playing):
			$CanvasLayer/RichTextLabel.text = "[center] ¡Tiene que ser una broma! [/center]"
		elif (screamSfx.playing):
			$CanvasLayer/RichTextLabel.text = "[center] ¡¡Ese tipo calvo pagará por esto!! [/center]"
		$CanvasLayer/RichTextLabel.visible = true

func purpleSlashLogic():
	$AnimatedSprite2D.speed_scale = 5.5
	if (get_parent().get_node("player").position.x <= position.x):
		bossSprite.scale.x = 1
	else:
		bossSprite.scale.x = -1
	canSpawnSlash = true
	isAttacking = true
	atckGrunts[atckGruntRotation].play()
	if (atckGruntRotation != 3):
		atckGruntRotation += 1
	else:
		atckGruntRotation = 0
	bossSprite.play("Attack_Purple")
	#chargeBatSfx.play()
	canAttack = false
	attackTimer = 1

func moleLogic(delta):
	if (attackStep == 0):
		wentOffBounds = false
		isAttacking = true
		attackStep += 1
		bossSprite.play("Attrack_GroundHide_1")
	if (attackStep == 2):
		if (bossSprite.frame >= 6):
			if (!speenSfx.playing):
				speenSfx.play()
	if (attackStep == 3):
		wentOffBounds = false
		if (inWarningState and currentWarningNumber < 2):
			position.x = get_parent().get_node("player").position.x
		if (warningSpriteTimer <= 0):
			warningSpriteTimer = 1
		if (warningSpriteTimer == 1):
			inWarningState = true
			if currentWarningNumber == 0:
				position.x = get_parent().get_node("player").position.x
			warningIndicatorSpr.visible = true
			currentWarningNumber += 1
			if (currentWarningNumber == 2):
				warningTwoSfx.play()
			elif currentWarningNumber < 3:
				warningOneSfx.play()
			else:
				currentWarningNumber = 0
				attackStep = 4
				warningIndicatorSpr.visible = false
				warningSpriteTimer = 1
		if (warningSpriteTimer <= 0.5):
			warningIndicatorSpr.visible = false
		warningSpriteTimer -= ((homingSpeedTimerReduction * 60) * delta)
	if (attackStep == 4):
		position.y = groundLevel + 1
		attackStep += 1
		canFall = true
		createJumpDust(0)
		bossSprite.play("Attack_GroundHide_2")
		blastZone.set_deferred("disabled", false)
		jumpSfx.play()
		if (homingSpeedTimerReduction == 0.010):
			velocity.y -= 380 
		else:
			velocity.y -= (380 * (homingSpeedTimerReduction * 30))
	if (attackStep == 5):
		if bossSprite.frame >= 6:
			if (!infiniteSpeenSfx.playing):
				infiniteSpeenSfx.play()
			velocity.y = 0
			canFall = false
	if (attackStep == 6):
		infiniteSpeenSfx.stop()
		if (velocity.y <= 0):
			if (!wentOffBounds):
				atckGrunts[atckGruntRotation].play()
				if (atckGruntRotation != 3):
					atckGruntRotation += 1
				else:
					atckGruntRotation = 0
				wentOffBounds = true
				homingAttackOvershootSfx.play()
		else:
			if (!wentOffBounds):
				wentOffBounds = true
				homingAttackSfx.play()
		
		velocity.x = ((playerLocation[0] * 550) * 60) * delta
		velocity.y = ((playerLocation[1] * 550) * 60) * delta
		if position.y >= groundLevel + 6 or position.distance_to( get_parent().get_node("player").position ) > 1000:
			attackStep += 1
			velocity.x = 0
			velocity.y = 0
			blastZone.set_deferred("disabled", true)
			homingSpeedTimerReduction += 0.020
			$AnimatedSprite2D.speed_scale *= 1.45
			position.y = groundLevel - 15
			bossSprite.rotation_degrees = 0
			bossSprite.scale.y = 1
			bossSprite.scale.x = 1
			bossSprite.play("GroundHide")
	if (attackStep == 7):
		warningSpriteTimer -= delta
		if warningSpriteTimer <= 0:
			if (homingAttacks < 4):
				homingAttacks += 1
				warningSpriteTimer = 0
				attackStep = 3
				bossSprite.rotation_degrees = 0
				bossSprite.scale.y = 1
				bossSprite.scale.x = 1
			else:
				attackStep = 8
				bossSprite.rotation_degrees = 0
				bossSprite.scale.y = 1
				bossSprite.scale.x = 1
				position.x = celesteMarker.global_position.x
				$AnimatedSprite2D.speed_scale = 4
	if (attackStep == 8):
		attackStep += 1
		blastZone.set_deferred("disabled", true)
		position.y = groundLevel
		bossSprite.play("GroundRise")
	if (attackStep == 9):
		if bossSprite.frame == 18:
			if (!smolJumpSfx.playing):
				smolJumpSfx.play()
		if bossSprite.frame == 22:
			if (!landSnowSfx.playing):
				landSnowSfx.play()

func moleAttack():
	if (bossSprite.get_animation() == "Attrack_GroundHide_1") and attackStep == 1 and bossSprite.frame != 0:
		attackStep += 1
		canFall = true
		createJumpDust(0)
		bossSprite.play("Attack_GroundHide_2")
		velocity.y -= 360
		jumpSfx.play()
		
	if (bossSprite.get_animation() == "Attack_GroundHide_2") and attackStep == 2 and bossSprite.frame != 0:
		canFall = false
		bossSprite.play("Attack_GroundHide_3")
		velocity.y = 0
		position.y = groundLevel - 15
		attackStep += 1

	if (bossSprite.get_animation() == "Attack_GroundHide_2") and attackStep == 5:
		attackStep += 1
		bossSprite.play("Attack_Homing")
		if (get_parent().get_node("player").position.x <= position.x):
			bossSprite.scale.x = 1
			bossSprite.scale.y = -1
		else:
			bossSprite.scale.x = 1
			bossSprite.scale.y = 1
		var direction = (get_parent().get_node("player").global_position - global_position).normalized()
		playerLocation = direction
		var rotation_angle = atan2(direction.y, direction.x)
		bossSprite.rotation_degrees = rotation_angle * 180 / PI
	
	if (bossSprite.get_animation() == "GroundRise" and attackStep == 9 and bossSprite.frame != 0):
		lastAttack = states.MOLE
		reset_abunchaShit()

func dangerousAllianceLogic():
	if (attackStep == 0):
		isAttacking = true
		attackStep += 1
		bossSprite.play("Attack_BallPrepare")
		chargeBatSfx.play()
	if (attackStep == 4):
		bossSprite.play("GroundRise")
		attackStep += 1
	if (attackStep == 5):
		if bossSprite.frame == 18:
			if (!smolJumpSfx.playing):
				smolJumpSfx.play()
		if bossSprite.frame == 22:
			if (!landSnowSfx.playing):
				landSnowSfx.play()

func dangerousAllianceAttack():
	if (bossSprite.get_animation() == "Attack_BallPrepare"):
		attackStep += 1
		bossSprite.play("Attack_BallHit")
		ballHitSfx.play()
		superBallHitSfx.play()
		batSlashSfx.play()
		spawnBall()
	if (bossSprite.get_animation() == "Attack_BallHit") and bossSprite.frame != 0:
		attackStep += 1
		bossSprite.play("Attack_BallHide")
	if (bossSprite.get_animation() == "GroundRise" and attackStep == 5 and bossSprite.frame != 0):
		lastAttack = states.DANGEROUS_ALLIANCE
		reset_abunchaShit()
	
func attackWaitTime(delta):
	if dead:
		expTimerSpawn -= (0.09 * 60) * delta
		if expTimerSpawn <= 0:
#			print("no faking wei")
			expTimerSpawn = 0.5
			if explosions < 8:
				createExplosion()
				
		move_and_slide()
		velocity.x = 200 * scale.x
		bossSprite.rotation_degrees += (12 * 60) * delta
	
	if (!dead):
		if (gotStruck and attackLoop > 3):
			shake(1.4)
			if (!gotHit):
				attackChosen = states.LIGHTSTRUCK
			else:
				if (attackChosen != states.DAMAGED):
					hits += 1
					if hits == 2:
						dead = true
					gotStruck = false
					gotHit = false
					attackChosen = states.DAMAGED
					bossSprite.play("DamageTaken")
					canFall = true
					velocity.y = 0
					velocity.x = 0
					velocity.y += (300 * -scale.x)
					velocity.x = 200 * bossSprite.scale.x
	if (attackLoop > 3):
		if attackChosen == states.DAMAGED:
			hitLogic()

		if attackChosen == states.LIGHTSTRUCK:
			lightStruckLogic()
#	print("FUCKING ATTACK CHOSEN:", attackChosen)
	if (!CutsceneHandler.inCutscene):
		if attackChosen != states.TIRED:
			if (!onHold):
				attackOpportunity(delta)
		elif attackChosen == states.TIRED:
			tiredLogic()
	
func tiredLogic():
	onHold = true
#	print("GRAAAAAAHHHHHHHHHHH")
	position.y = groundLevel
	tiredTimer -= get_physics_process_delta_time()
	if tiredTimer <= 0:
		gotStruck = false
		onHold = false
		attackTimer = 2
		isAttacking = false
		tiredTimer = 3
		attackLoop = 0
		reset_abunchaShit()
		bossSprite.play("Idle")
	else:
		bossSprite.play("Tired")
	
func lightStruckLogic():
	tiredTimer -= get_physics_process_delta_time()
	if tiredTimer <= 0:
		gotStruck = false
		onHold = false
		attackTimer = 2
		isAttacking = false
		tiredTimer = 3
		attackLoop = 0
		reset_abunchaShit()
		bossSprite.play("Idle")
	else:
		if (bossSprite.get_animation() != "LightStruck"):
			tiredTimer = 3
			bossSprite.play("LightStruck")

func attackOpportunity(delta):
	if (!canAttack):
		attackTimer -= delta
	if (attackTimer <= 0):
		speedup = 1
		
		if (!canAttack):
			#if for some go damn reason the intro variable hasn't been changed to done, then FCKING do it
			introDone = true
			if (!inAttackPhase):
				$AnimatedSprite2D.speed_scale = 4 * speedup
				inAttackPhase = true
				gravity *= 2
			canAttack = true
			if (!isAttacking):
				attackLoop += 1
			await get_tree().create_timer(0.1).timeout
			if (attackLoop <= 3):
				if (attackChosen == states.PURPLESLASH) and attackStep < 2:
					attackChosen = states.PURPLESLASH
				else:
					var randAttckNumber = rng.randi_range(0,2)
					match (randAttckNumber):
						0:
							attackChosen = states.MOLE #mole
						1:
							attackChosen = states.PURPLESLASH
						2:
							attackChosen = states.DANGEROUS_ALLIANCE #dangAlliance
			else:
#				print("WHAT THE FUCCKKKKKKKK")
				attackChosen = states.TIRED
				
func attackBehavior(delta):
	if (canAttack):
		#avoid repetition of attacks
		if (attackChosen == lastAttack):
			match(lastAttack):
				states.PURPLESLASH:
					var randAttckNumber = rng.randi_range(0,1)
					match (randAttckNumber):
						0:
							attackChosen = states.DANGEROUS_ALLIANCE
						1:
							attackChosen = states.MOLE
				states.MOLE:
					var randAttckNumber = rng.randi_range(0,1)
					match (randAttckNumber):
						0:
							attackChosen = states.DANGEROUS_ALLIANCE
						1:
							attackChosen = states.PURPLESLASH
				states.DANGEROUS_ALLIANCE:
					var randAttckNumber = rng.randi_range(0,1)
					match (randAttckNumber):
						0:
							attackChosen = states.PURPLESLASH
						1:
							attackChosen = states.MOLE

		if (!onHold):
			match (attackChosen):
				states.PURPLESLASH:
					if (get_parent().get_node("player").position.x <= position.x):
						bossSprite.scale.x = 1
					else:
						bossSprite.scale.x = -1
					purpleSlashLogic()
				states.MOLE:
					moleLogic(delta)
				states.DANGEROUS_ALLIANCE:
					dangerousAllianceLogic()
	match(attackChosen):
		states.PURPLESLASH:
			if (bossSprite.get_animation() == "Attack_Purple"):
				if bossSprite.frame >= 6 and canSpawnSlash and slashesThrown < 2:
					canSpawnSlash = false
					#batSlashSfx.play()
					slashesThrown += 1
					if (attackStep < 2):
						attackStep += 1
					else:
						isAttacking = false
						attackStep = 0
					atckGrunts[atckGruntRotation].play()
					if (atckGruntRotation != 3):
						atckGruntRotation += 1
					else:
						atckGruntRotation = 0
					spawnPurpleSlash()
				if slashesThrown >= 2:
					attackChosen = null
					slashesThrown = 0
					attackStep = 0
					isAttacking = false
					attackTimer = 3
					$AnimatedSprite2D.speed_scale = 4
					lastAttack = states.PURPLESLASH
					
func spawnNegativeZone():
	if ((get_parent().get_node("player").state != get_parent().get_node("player").states.GAMEOVER)):
		var negativeZone = negative.instantiate()
		negativeZone.position.y -= 32
		add_child(negativeZone)

func spawnBall():
	var ballId = ball.instantiate()
	ballId.position.y -= 32
	ballId.hDir = bossSprite.scale.x
	ballId.anticipationTimer = 2
	spawnNegativeZone()
	ballId.highSpeedBall = true
	add_child(ballId)

func spawnPurpleSlash():
	var slashId = purpleSlash.instantiate()
	slashId.dir = $AnimatedSprite2D.scale.x
	slashId.damageType = 1
	slashId.type = 1
	var rando = rng.randi_range(0,1)
	if rando == 0:
		slashId.sinVerticalSartPos = 1
	else:
		slashId.sinVerticalSartPos = -1

	if ($AnimatedSprite2D.scale.x == 1):
		slashId.global_position = $Marker2D.global_position
	else:
		slashId.global_position = $Marker2D.global_position
		slashId.global_position.x += 64
	add_child(slashId)

		
func shake(shaking_intensity):
	var random_offset = randf_range(-shaking_intensity, shaking_intensity)
	var randomNum = randi_range(-1, 1)
	bossSprite.offset.x = 0 + (random_offset)
	bossSprite.offset.y = 0 + (random_offset*randomNum)

func createJumpDust(extraPx):
	var id = jumpDustFx.instantiate()
	id.top_level = true
	id.global_position = global_position
	id.global_position.y -= (3 - extraPx)
	call_deferred("add_child", id)

func createExplosion():
	var idExp = stockExp.instantiate()
	if explosions == 1:
		screamSfx.play()
		playAClip = true
	if explosions == 2 or explosions == 5 or explosions == 7:
		$Explosion.play()
	if explosions <= 6:
		idExp.scale.x = 2
		idExp.scale.y = 2
	else:
		bossSprite.visible = false
		idExp.scale.x = 6
		idExp.scale.y = 6
	explosions += 1
	idExp.global_position = global_position
	add_child(idExp)

func introStuff(delta):
	if (get_parent().bossHP.frame == 2):
		if (!myTurn):
			if (!CutsceneHandler.bossPhase == 1):
				CutsceneHandler.bossPhase = 1
			myTurn = true
			bossSprite.scale.x = -1
			velocity.y = 0
			velocity.x = 0
			position.y = groundLevel
			position.x = celesteMarker.global_position.x
			bossSprite.play("GroundRise")
			
	if (!CutsceneHandler.inCutscene):
		
		if !(myTurn and !waitForTurn):
			if get_parent().bossHP.frame == 0:
				isOffScreen = true
				bossSprite.play("NotMyTurnYet")
				if (bossSprite.frame >= 4):
					timer -= delta
					if timer <= 0:
						waitForTurn = true
					velocity.y = -((370 * 60) * delta)
	
	if not is_on_floor() and canFall:
		velocity.y += (((gravity * speedup) / 4) * delta)
		if !introHasLanded:
			bossSprite.play("Falling")
	else:
		if (!introHasLanded):
			$Fall.stop()
			$Explosion.play()
			bossSprite.play("LandExplosion")
			introHasLanded = true
			groundLevel = position.y
	if bossSprite.get_animation() == "Recover" and (bossSprite.frame >= 3 and bossSprite.frame < 10):
		if (!spinSfxPlayed):
			spinSfxPlayed = true
			$Spin.play()
	if bossSprite.get_animation() == "Recover" and (bossSprite.frame >= 10):
		if (spinSfxPlayed):
			spinSfxPlayed = false
			$Spin.stop()
			$Sparkle.play()	

func playIdle():
	if ((is_on_floor() or !canFall) and introDone) and !isAttacking:
		if !onHold:
			if !(!respawnDone and isOffScreen):
				if tiredTimer != 3:
					tiredTimer = 3
				bossSprite.play("Idle")

func hitLogic():
	hitTimer -= get_physics_process_delta_time()
	if hitTimer <= 0:
		if (get_parent().bossHP.frame != 4):
			bossSprite.offset.x = 0
			bossSprite.offset.y = 0
			velocity.y = 0
			velocity.x = 0
			bossSprite.play("GroundRise")
			attackChosen = null
			position.x = celesteMarker.global_position.x
			position.y = groundLevel
			canFall = false
			canAttack = true
			hitTimer = 2
			attackLoop = 0
			reset_abunchaShit()
		else:
			#stay dead
			velocity.x = 0
			velocity.y = 0
			dead = true
			CutsceneHandler.bossPhase = 2
			CutsceneHandler.inCutscene = true
			Conductor.volume_db = -80
			killCutsceneTimer -= get_process_delta_time()
			if killCutsceneTimer <= 0:
				if (!hasSpawneDiag):
					hasSpawneDiag = true
					get_parent().spawnBossKillDialogue(true)
#		print("BRO WHAT THE FUCKKCKCKCKCKCKCKCK")
#		if bossSprite.frame >= 26:
#			onHold = false
		

func reset_abunchaShit():
	bossSprite.offset.x = 0
	bossSprite.offset.y = 0
	attackChosen = null
	attackStep = 0
	isAttacking = false
	canAttack = false
	attackTimer = 3
	inWarningState = false
	currentWarningNumber = 0
	warningSpriteTimer = 0.5
	homingSpeedTimerReduction = 0.010
	homingAttacks = 0
	position.y = groundLevel

func _on_animated_sprite_2d_animation_finished():
	moleAttack()
	dangerousAllianceAttack()

	if (bossSprite.get_animation() == "LandExplosion" and introHasLanded):
		bossSprite.play("Recover")
		
	if (bossSprite.get_animation() == "GroundRise" and introHasLanded and bossSprite.frame > 1):
		respawnDone = true
		onHold = false
	if (bossSprite.get_animation() == "Recover" and bossSprite.frame > 1):
		$AnimatedSprite2D.scale.x = 1
		$AnimatedSprite2D.speed_scale = 4
		canFall = false
		$CollisionShape2D.set_deferred("disabled", true)
		introDone = true
