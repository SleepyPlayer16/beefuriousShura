extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var greenSlash = preload("res://scenes/boss_attacks/greenSlash.tscn")
@onready var ball = preload("res://scenes/boss_attacks/ball.tscn")

@onready var bossSprite = $AnimatedSprite2D
@onready var chargeBatSfx = $ChargeBat
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
@onready var ballHitSfx = $BallHit
@onready var superBallHitSfx = $BallHit
@onready var screamSfx = $Scream
@onready var atckGrunts = [$AttackGrunt1, $AttackGrunt2, $AttackGrunt3, $AttackGrunt4]
@onready var gotHitSounds = [$GotHit1, $GotHit2]
@onready var hideSfx = $Hide
@onready var moleAttackSfx = $MoleAttack


@onready var rosaMarker = get_parent().get_node("rosaMarkerInitialPos")
@onready var blastZone = $blastZone/Area2D/CollisionShape2D
@onready var ballMarker = $AnimatedSprite2D/BallMarker
@onready var stockExp = preload("res://scenes/FX/stockExplosion.tscn")
@onready var jumpDustFx = preload("res://scenes/FX/jumpDust.tscn")

var expTimerSpawn = 0

var boss = true
var introHasLanded = false
var introHasExploded = false
var spinSfxPlayed = false
var introDone = false
var canSpawnSlash = true
var isAttacking = false
var canAttack = false
var attackTimer = 2
var textTimer = 3
var slashesThrown = 0
var speedup = 1
var attackChosen = null
var rng = RandomNumberGenerator.new()
var hits = 0
var attackStep = 0
var groundLevel = 0.0
var canFall = true
var inAttackPhase = false
var homingSpeedTimerReduction = 0
var wentOffBounds = false
var lastAttack = null
var warningSpriteTimer = 0.5
var inWarningState = false
var currentWarningNumber = 0
var playerLocation = null
var homingAttacks = 0
var attackLoop = 0 #should start at 0
var tiredTimer = 5
var gotStruck = false
var onHold = false
var is_shaking = false
var hitTimer = 2
var gotHit = false
var hp = 2 #change back to 2
var explosions = 0
var dead = false
var doNOTFUCKIGNplayANYSOUNDS = false
var original_position = null
var playAClip = false
var atckGruntRotation = 0

@onready var player = get_parent().get_node_or_null("player")
@onready var portrait = preload("res://sprites/rosa/RosaNormal.png")

enum states{
	GREENSLASH,
	MOLE,
	DANGEROUS_ALLIANCE,
	TIRED,
	LIGHTSTRUCK,
	DAMAGED
}

func _ready():
	if (CutsceneHandler.bossPhase == 1):
		doNOTFUCKIGNplayANYSOUNDS = true
		visible = false
		get_parent().bossHP.frame = 2
	if (CutsceneHandler.playerHasDied):
		speedup = 2
	Conductor.beatSignal.connect(playIdle)
	$AnimatedSprite2D.speed_scale = 4 * speedup
	if (CutsceneHandler.bossPhase != 1):
		$Fall.play()
	blastZone.set_deferred("disabled", true)
	rng.randomize()

func _physics_process(delta):
	if (attackChosen != states.LIGHTSTRUCK):
		bossSprite.offset = Vector2(0, 0)

	if (player.state != player.states.GAMEOVER):

		if (attackChosen == states.DAMAGED or attackChosen == states.TIRED or attackChosen == states.LIGHTSTRUCK):
			if (!blastZone.disabled):
				blastZone.set_deferred("disabled", true)
		if (bossSprite.get_animation() == "Idle"):
			if (blastZone.disabled):
				blastZone.set_deferred("disabled", false)
		if !isAttacking and introDone:
			if bossSprite.get_animation() != "DamageTaken":
				if (get_parent().get_node("player").position.x <= position.x):
					bossSprite.scale.x = 1
				else:
					bossSprite.scale.x = -1
		if dead:
			if !doNOTFUCKIGNplayANYSOUNDS:
				expTimerSpawn -= (0.09 * 60) * delta
				if expTimerSpawn <= 0 and explosions < 8:
					expTimerSpawn = 0.5
					if explosions < 8:
						createExplosion()
					
			move_and_slide()
			velocity.x = 200 * scale.x
			bossSprite.rotation_degrees += (12 * 60) * delta
		if (CutsceneHandler.bossPhase == 1 and introDone):
			if (attackChosen != states.DAMAGED):
				gotStruck = false
				gotHit = false
				attackChosen = states.DAMAGED
				bossSprite.play("DamageTaken")
				canFall = true
				dead = true
				velocity.y = 0
				velocity.x = 0
				velocity.y -= 300
				velocity.x = 200 * -bossSprite.scale.x
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
						velocity.y -= 300
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


			if (canAttack):
				#avoid repetition of attacks
				if (attackChosen == lastAttack):
					match(lastAttack):
						states.GREENSLASH:
							var randAttckNumber = rng.randi_range(0,1)
							match (randAttckNumber):
								0:
									attackChosen = states.MOLE
								1:
									attackChosen = states.DANGEROUS_ALLIANCE
						states.MOLE:
							var randAttckNumber = rng.randi_range(0,1)
							match (randAttckNumber):
								0:
									attackChosen = states.GREENSLASH
								1:
									attackChosen = states.DANGEROUS_ALLIANCE
						states.DANGEROUS_ALLIANCE:
							var randAttckNumber = rng.randi_range(0,1)
							match (randAttckNumber):
								0:
									attackChosen = states.MOLE
								1:
									attackChosen = states.GREENSLASH

				if (!onHold):
					match (attackChosen):
						states.GREENSLASH:
							greenSlashLogic()
						states.MOLE:
							moleLogic(delta)
						states.DANGEROUS_ALLIANCE:
							dangerousAllianceLogic()

			match(attackChosen):
				states.GREENSLASH:
					if (bossSprite.get_animation() == "Attack_Green"):
						if (get_parent().get_node("player").position.x <= position.x):
							bossSprite.scale.x = 1
						else:
							bossSprite.scale.x = -1

						if bossSprite.frame >= 11 and canSpawnSlash and slashesThrown < 2:
							canSpawnSlash = false
							atckGrunts[atckGruntRotation].play()
							if (atckGruntRotation != 3):
								atckGruntRotation += 1
							else:
								atckGruntRotation = 0
							batSlashSfx.play()
							slashesThrown += 1
							if (attackStep < 2):
								attackStep += 1
							else:
								isAttacking = false
								attackStep = 0
							spawnGreenSlash()
						if slashesThrown >= 2:
							attackChosen = null
							slashesThrown = 0
							attackStep = 0
							isAttacking = false
							attackTimer = 3
							lastAttack = states.GREENSLASH

			if not is_on_floor():
				if (canFall):
					if (!dead):
						velocity.y += (((gravity * speedup) / 4) * delta)

				if !introHasLanded:
					bossSprite.play("Falling")
			else:
				if (!introHasLanded):
					$Fall.stop()
					if (CutsceneHandler.bossPhase != 1):
						$Explosion.play()
					bossSprite.play("LandExplosion")
					canFall = false
					$CollisionShape2D.set_deferred("disabled", true)
					introHasLanded = true
					groundLevel = position.y
					position.y = groundLevel + 1
			if bossSprite.get_animation() == "Recover" and (bossSprite.frame >= 3 and bossSprite.frame < 10):
				if (!spinSfxPlayed and CutsceneHandler.bossPhase != 1):
					spinSfxPlayed = true
					$Spin.play()
			if bossSprite.get_animation() == "Recover" and (bossSprite.frame >= 10):
				if (spinSfxPlayed):
					spinSfxPlayed = false
					$Spin.stop()
					$Sparkle.play()

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
		if (hideSfx.playing):
			$CanvasLayer/RichTextLabel.text = "[center] ¡Oops, debo esconderme! [/center]"
		elif (moleAttackSfx.playing):
			$CanvasLayer/RichTextLabel.text = "[center] ¡Wahoo, ahí voy! [/center]"
		elif (screamSfx.playing):
			$CanvasLayer/RichTextLabel.text = "[center] ¡Ahhh! !Véngame, Celeste![/center]"
		$CanvasLayer/RichTextLabel.visible = true

func playIdle():
	if ((is_on_floor() or !canFall) and introDone) and !isAttacking:
		position.y = groundLevel
		if !onHold:
			if tiredTimer != 5:
				tiredTimer = 5
			bossSprite.play("Idle")
		
func shake(shaking_intensity):
	var random_offset = randf_range(-shaking_intensity, shaking_intensity)
	var randomNum = randi_range(-1, 1)
	bossSprite.offset.x = 0 + (random_offset)
	bossSprite.offset.y = 0 + (random_offset*randomNum)

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
	idExp.global_position = global_position
	explosions += 1
	add_child(idExp)
	
func createJumpDust(extraPx):
	var id = jumpDustFx.instantiate()
	id.top_level = true
	id.global_position = global_position
	id.global_position.y -= (3 - extraPx)
	call_deferred("add_child", id)

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
				if (attackChosen == states.GREENSLASH) and attackStep < 2:
					attackChosen = states.GREENSLASH
				else:
					var randAttckNumber = rng.randi_range(0,2)
					match (randAttckNumber):
						0:
							attackChosen = states.MOLE
						1:
							attackChosen = states.GREENSLASH
						2:
							attackChosen = states.DANGEROUS_ALLIANCE
			else:
#				print("WHAT THE FUCCKKKKKKKK")
				attackChosen = states.TIRED

func spawnGreenSlash():
	var slashId = greenSlash.instantiate()
	slashId.dir = $AnimatedSprite2D.scale.x
	slashId.damageType = 1
	add_child(slashId)
	if ($AnimatedSprite2D.scale.x == 1):
		slashId.global_position = $Marker2D.global_position
	else:
		slashId.global_position = $Marker2D.global_position
		slashId.global_position.x += 64

func spawnBall():
	var ballId = ball.instantiate()
	ballId.position.y -= 32
	ballId.hDir = bossSprite.scale.x

	add_child(ballId)

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
		tiredTimer = 5
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
		tiredTimer = 5
		attackLoop = 0
		reset_abunchaShit()
		bossSprite.play("Idle")
	else:
		if (bossSprite.get_animation() != "LightStruck"):
			tiredTimer = 5
			gotHitSounds[1].play()
			bossSprite.play("LightStruck")

func hitLogic():
	hitTimer -= get_physics_process_delta_time()
	if hitTimer <= 0:
		if (get_parent().bossHP.frame != 2):
			bossSprite.offset.x = 0
			bossSprite.offset.y = 0
			velocity.y = 0
			velocity.x = 0
			bossSprite.play("GroundRise")
			attackChosen = null
			position.x = rosaMarker.global_position.x
			position.y = groundLevel
			canFall = false
			hitTimer = 2
			attackLoop = 0
			reset_abunchaShit()
		else:
			#stay dead
			velocity.x = 0
			velocity.y = 0
			dead = true
#		print("BRO WHAT THE FUCKKCKCKCKCKCKCKCK")
#		if bossSprite.frame >= 26:
#			onHold = false
		
	
func greenSlashLogic():
	if (get_parent().get_node("player").position.x <= position.x):
		bossSprite.scale.x = 1
	else:
		bossSprite.scale.x = -1
	canSpawnSlash = true
	isAttacking = true
	bossSprite.play("Attack_Green")
	atckGrunts[atckGruntRotation].play()
	if (atckGruntRotation != 3):
		atckGruntRotation += 1
	else:
		atckGruntRotation = 0
	chargeBatSfx.play()
	canAttack = false
	attackTimer = 2

func dangerousAllianceLogic():
	if (attackStep == 0):
		blastZone.set_deferred("disabled", true)
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

func moleLogic(delta):
	if (attackStep == 0):
		blastZone.set_deferred("disabled", true)
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
		if (inWarningState and currentWarningNumber < 4):
			position.x = get_parent().get_node("player").position.x
		if (warningSpriteTimer <= 0):
			warningSpriteTimer = 1
		if (warningSpriteTimer == 1):
			inWarningState = true
			if currentWarningNumber == 0:
				position.x = get_parent().get_node("player").position.x
			warningIndicatorSpr.visible = true
			currentWarningNumber += 1
			if (currentWarningNumber == 4):
				warningTwoSfx.play()
			elif currentWarningNumber < 4:
				warningOneSfx.play()
			else:
				currentWarningNumber = 0
				attackStep = 4
				warningIndicatorSpr.visible = false
				warningSpriteTimer = 1
		if (warningSpriteTimer <= 0.5):
			warningIndicatorSpr.visible = false
		warningSpriteTimer -= (homingSpeedTimerReduction + delta)
	if (attackStep == 4):
		position.y = groundLevel + 1
		attackStep += 1
		canFall = true
		createJumpDust(0)
		$JumpDust.play("default")
		bossSprite.play("Attack_GroundHide_2")
		blastZone.set_deferred("disabled", false)
		jumpSfx.play()
		if (homingSpeedTimerReduction == 0):
			velocity.y -= 280 
		else:
			velocity.y -= (280 * (homingSpeedTimerReduction * 75))
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
				wentOffBounds = true
				atckGrunts[atckGruntRotation].play()
				if (atckGruntRotation != 3):
					atckGruntRotation += 1
				else:
					atckGruntRotation = 0	
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
			homingSpeedTimerReduction += 0.02
			$AnimatedSprite2D.speed_scale *= 2
			position.y = groundLevel - 15
			bossSprite.rotation_degrees = 0
			bossSprite.scale.y = 1
			bossSprite.scale.x = 1
			bossSprite.play("GroundHide")
	if (attackStep == 7):
		warningSpriteTimer -= delta
		if warningSpriteTimer <= 0:
			if (homingAttacks < 2):
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
				position.x = rosaMarker.global_position.x
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

func dangerousAllianceAttack():
	if (bossSprite.get_animation() == "Attack_BallPrepare"):
		attackStep += 1
		bossSprite.play("Attack_BallHit")
		ballHitSfx.play()
		batSlashSfx.play()
		spawnBall()
	if (bossSprite.get_animation() == "Attack_BallHit") and bossSprite.frame != 0:
		attackStep += 1
		hideSfx.play()
		playAClip = true
		bossSprite.play("Attack_BallHide")
	if (bossSprite.get_animation() == "GroundRise" and attackStep == 5 and bossSprite.frame != 0):
		lastAttack = states.DANGEROUS_ALLIANCE
		reset_abunchaShit()
		
func moleAttack():
	if (bossSprite.get_animation() == "Attrack_GroundHide_1") and attackStep == 1 and bossSprite.frame != 0:
		attackStep += 1
		moleAttackSfx.play()
		playAClip = true
		canFall = true
		createJumpDust(0)
		$JumpDust.play("default")
		bossSprite.play("Attack_GroundHide_2")
		velocity.y -= 360
		jumpSfx.play()
		
	if (bossSprite.get_animation() == "Attack_GroundHide_2") and attackStep == 2 and bossSprite.frame != 0:
		canFall = false
		bossSprite.play("Attack_GroundHide_3")
		velocity.y = 0
		position.y = groundLevel - 15
		attackStep += 1
		$JumpDust.play("default")

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
		
func reset_abunchaShit():
	attackChosen = null
	attackStep = 0
	isAttacking = false
	canAttack = false
	attackTimer = 3
	inWarningState = false
	currentWarningNumber = 0
	warningSpriteTimer = 0.5
	homingSpeedTimerReduction = 0
	homingAttacks = 0
	position.y = groundLevel

func _on_animated_sprite_2d_animation_finished():
	if (!dead):
		moleAttack()
		dangerousAllianceAttack()
		
		if (bossSprite.get_animation() == "GroundRise" and bossSprite.frame > 1 and onHold):
			onHold = false

		if (bossSprite.get_animation() == "LandExplosion" and introHasLanded):
			bossSprite.play("Recover")
		if (bossSprite.get_animation() == "Recover" and bossSprite.frame > 1):
			introDone = true
			if !CutsceneHandler.shouldSkipCutscene:
				Conductor.songUnload()
				Conductor.volume_db = 0
				Conductor.signature = 3
				Conductor.songToLoad(90, 1, load("res://music/mus_creatureArrival.ogg"))
				get_parent().spawnDialogue(true)
			else:
				get_parent().bossArenaPreparationTrigger(2)
			$AnimatedSprite2D.speed_scale = 4

		
