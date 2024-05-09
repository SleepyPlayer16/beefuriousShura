extends CharacterBody2D

var attackLoop = 0
var canAttack = false
var wasStruck = false
var firstAttack = null
var lastAttack
var attackStep = 0
var attackChosen = null
var attackTimer = 2
var vsp = 0.0
var hsp = 0.0
var speed = 360
var shouldFollowPlayer = true
var beeSpeed = 5000
var rng = RandomNumberGenerator.new()
var eyeObject = null
var curSound = 0
var state = null
var active = true
var transformationStep = 0
var lightStruckTimer = 2.5
var shakeInt = 0
var laserSoundPitch = 1
var laserChargeTimer = 3
var transitionTimer = 1
var scaredTimer = 2
var inThirdPhase = false
var inHitStun = false
var sentFlyinTimer = 2
var hitStunTimer = 0
var defeated = false
var disappearTimer = 2
var wasSentFlying = false
var defeatStep = 0

#attack variables
var eyeOut = false

#tired variables
var gotHit = false
var onHold = false
var gotStruck = false
var tiredTimer = 5
var canDoShi = true

@onready var attackGrunts = [$AtckGrunt1, $AtckGrunt2, $AtckGrunt3]
@onready var eyeSpawnMarker = $Boss_Sprite/EyeSpawnMarker
@onready var beeSpawnMarker = $Boss_Sprite/BeeSpawnMarker
@onready var bossSprite = $Boss_Sprite
@onready var snapSfx = $Snap
@onready var gotHitSfx = $GotHit
@onready var hurtBox = $BossHurtbox/CollisionShape2D
@onready var whiteFade = $CanvasLayer/ColorRect
@onready var tpSfx = $Teleport
@onready var tp2Sfx = $Reappear

@onready var player = get_parent().get_node_or_null("player")
@onready var eye = preload("res://scenes/bosses/caramelEye.tscn")
@onready var star = preload("res://scenes/boss_attacks/ShootingStar.tscn")
@onready var beeScene = preload("res://scenes/boss_attacks/smolBee.tscn")
@onready var laser = preload("res://scenes/boss_attacks/BigassLaser.tscn")
@onready var dust = preload("res://scenes/FX/dust.tscn")

enum states{
	EYE_ATTACK,
	TIRED,
	LIGHTSTRUCK
}

func _process(delta):
	if (defeated):
		defeatCutsceneLogic(delta)		
	if (player.state != player.states.GAMEOVER) and !FinalBossManager.bossDefeated:
		if (!inThirdPhase):
			if (active):
				if (canDoShi):
					normalLogic(delta)
			else:
				if (eyeObject.active):
					eyeObject.active = false
				phaseSwitchLogic(delta)
		else:
			if (!defeated and get_parent().bossHP.frame == 10):
				defeated = true
				defeatedLogic(delta)
				Conductor.goToNextSection = true
				Conductor.fourthBeat = 4
				Conductor.waitUp = false

			#if (defeated):
				#defeatCutsceneLogic(delta)
				#print("oohjhggh oooghhh ooohhh")
				#defeatedLogic(delta)

			if (!defeated):
				sentFlyinTimer -= delta
				if (sentFlyinTimer <= 0):

					if (gotHit and wasSentFlying):
						attackTimer = 2
						attackStep = 0
						eyeOut = false
						attackLoop = 0
						attackChosen = null
						firstAttack = states.EYE_ATTACK
						bossSprite.play("Attack_EyeAttack")
						gotHit = false
						wasSentFlying = false
					normalLogic(delta)
				else:
					if (!inHitStun):
						move_and_slide()
					else:
						if (hitStunTimer > 0):
							hitStunTimer -= 60 * delta
						else:
							inHitStun = false

func normalLogic(delta):
	if (!gotHit):
		if (shouldFollowPlayer):
			vsp = lerpf(vsp, - 100.0 + (float(player.global_position.y) - float(global_position.y)), (0.2*60)*delta)
			followPlayer(delta)
			velocity.y = vsp
			move_and_slide()
		else:
			vsp = lerpf(vsp, - 160.0 + (float(player.global_position.y) - float(global_position.y)), (0.2*60)*delta)
			followPlayer(delta)
			velocity.y = vsp
			move_and_slide()
	facingAt()
	attackPick(delta)
	#AttackLogic
	attackLogicRun()

func attackPick(delta):
	if (attackTimer > 0):
		attackTimer -= delta
	else:
		#The first attack ALWAYS has to be the eye attack.
		if (firstAttack == null):
			firstAttack = states.EYE_ATTACK
			bossSprite.play("Attack_EyeAttack")

func attackLogicBeenado():
	if (attackStep == 0):
		if (getAnim() == "Attack_beeNado"):
			if (bossSprite.frame >= 8):
				if (curSound < 2):
					curSound += 1
				else:
					curSound = 0
				attackGrunts[curSound].play()
				$BeeSpawn.play()
				attackStep += 1
				beeSpawn()
	if (attackStep == 1):
		if (getAnim() == "Attack_beeNado"):
			if (bossSprite.frame == 0):
				attackStep = 0

func attackLogicRun():
	if !(firstAttack == null and eyeOut):
		eyeSpawnLogic()
	shootingStarAttackLogic()

func shake(shaking_intensity):
	var random_offset = randf_range(-shaking_intensity, shaking_intensity)
	var randomNum = randi_range(-1, 1)
	bossSprite.offset.x = 0 + (random_offset)
	bossSprite.offset.y = 0 + (random_offset*randomNum)

func defeatCutsceneLogic(delta):
	if (defeatStep == 0):
		player.playerSprite.play("IdleSuper")
		player.hud.shuraHp.visible = false
		get_parent().caramelDed = true
		if (global_position.y < player.groundLvl):
			global_position.y += 2
		else:
			defeatStep += 1
			Conductor.shouldLoop = false
			$BossHurtbox/CollisionShape2D.set_deferred("disabled", true)
			bossSprite.play("Defeated2")
			$AnimatedSprite2D.play("default")
			shake(6)
	if (defeatStep == 1):
		if ($AnimatedSprite2D.frame >= 10 and !player.sfxTransformation.playing):
			player.sfxTransformation.play() 
	if (defeatStep == 2):
		player.shake(3, 2)
		$CanvasLayer/ColorRect.modulate.a += (0.02 * 60) * delta
		if ($CanvasLayer/ColorRect.modulate.a  >= 1 and bossSprite.visible):
			bossSprite.visible = false
			$AnimatedSprite2D.visible = false
			player.playerSprite.play("Idle")
			player.inBossFight = false
			player.form = ""
			player.emotionEffects.active = false
			player.emotionEffects.currentEmotion = null
			player.fireSprite.play("default")
			player.superSpeed = 0.0
			player.isInvincible = false
			player.happy_boost = 0.0
			FinalBossManager.bossDefeated = true
			get_parent().pantcake.play("free")
			get_parent().pantCol.set_deferred("disabled", false)
		disappearTimer -= delta
		if (disappearTimer <= 0):
			defeatStep += 1
	if (defeatStep == 3):
		$CanvasLayer/ColorRect.modulate.a -= (0.02 * 60) * delta
		disappearTimer -= delta
		if (disappearTimer <= -2):
			player.camera.offset.x = lerp(player.camera.offset.x, 0.0, (0.1*60)*delta)
		if (disappearTimer <= -5.5):
			defeatStep += 1
			player.epicArrow.play("Go")
			CutsceneHandler.inCutscene = false

func tiredLogic(delta):
	if (!inThirdPhase):
		if (player.is_on_floor()) or (bossSprite.get_animation() == "GotHit"):
			tiredTimer -= delta
	else:
		tiredTimer -= delta
	if tiredTimer <= 0:
		attackChosen = null
		bossSprite.play("AirIdleNoEye")
		gotHit = false
		tiredTimer = 5
		onHold = false
		gotStruck = false
		eyeObject.attckNumbLoop = 0
		eyeObject.resetAttackStuff()
		eyeObject.bossSprite.play("Idle")
		velocity.x = 0
		hsp = 0
		velocity.y = 0
		vsp = 0
	else:
		if (!gotHit):
			if (!gotStruck):
				if (!onHold):
					attackChosen = states.TIRED
					bossSprite.play("TiredIntro")
					onHold = true
			#	print("GRAAAAAAHHHHHHHHHHH")
				
				vsp = lerpf(vsp, - 10.0 + (float(player.global_position.y) - float(global_position.y)), (0.2*60)*delta)
				followPlayer(delta)
				velocity.y = vsp
			else:
				vsp = lerpf(vsp, + 1.0 + (float(player.global_position.y) - float(global_position.y)), (0.75*60)*delta)
				followPlayer(delta)
				velocity.y = vsp
				shake(1.4)
				if (bossSprite.get_animation() != "LightStruck"):
					velocity.x = 0
					velocity.y = 0
					tiredTimer = 5
					$LightStruck.play()
					#print("WHY THE FUCKKKKKKKKKKK ARE YOU TRIGGERING WHEJFNFJDSBNKGNSD")
					bossSprite.play("LightStruck")
		else:
			shake(3.4)
			vsp = 0
			hsp = 0
			velocity.x = 0
			velocity.y = 0

func defeatedLogic(_delta):
	player.dir = 1
	player.playerSprite.scale.x = player.dir
	player.camera.offset.x += 40
	player.shockWaveAnimPlay.play("cutsceneWhiteFadeOut")
	player.global_position = get_parent().shuraPosMarker.global_position
	global_position = get_parent().caramelPosMarker.global_position
	global_position.y -= 120
	player.disableAll(get_physics_process_delta_time())
	player.turnEmotionOff()
	player.velocity.x = 0
	player.velocity.y = 0
	player.invinFrames = 900000000
	player.isInvincible = true
	player.state = player.states.IDLE
	player.playerSprite.play("IdleSuper")
	bossSprite.play("Defeated1")
	CutsceneHandler.inCutscene = true

func phaseSwitchLogic(_delta):
	#why am i like this
	if (transformationStep == 0):
		transformationStep += 1
		player.playerSprite.modulate.a = 1
		player.playerSprite.play("Idle")
		bossSprite.play("LightStruck")
		if player.niShield != null:
			player.niShield.forceBreak()
		bossSprite.scale.x = 1
		bossSprite.offset.y = 0
		attackChosen = null
	if (transformationStep == 1):
		player.playerSprite.play("Idle")
		lightStruckTimer -= _delta
		if (lightStruckTimer <= 0):
			bossSprite.play("Attack_Laser_Startup")
			transformationStep += 1
		else:
			shake(1.5)
	if (transformationStep == 2):
		if (getAnim() == "Attack_Laser_Startup"):
			if (bossSprite.frame >= 19 and !$AtckLaserLoop.playing):
				$AtckLaserLoop.play()
		if getAnim() == "Attack_Laser_Charge":
			transformationStep += 1
			player.playerSprite.play("Scared1")
			player.instantiateFren("Nisha")
	if (transformationStep == 3):
		laserChargeTimer -= _delta
		if (laserChargeTimer <= 0):
			bossSprite.play("Attack_Laser_Shoot")
			transformationStep += 1
			player.shadow.hide()
			if player.niShield != null:
				player.niShield.forceBreak()
				player.camera.zoom.x = 4
				player.camera.zoom.y = 4
			$AtckLaserLoop.stop()
			bigAssLaserSpawnLogic()
			Engine.time_scale = 0.15
			await get_tree().create_timer(0.1).timeout
			Engine.time_scale = 1
		shakeInt += 1.5 * _delta
		player.camera.zoom.x = lerp(player.camera.zoom.x, 2.5, (0.05 * 60) * _delta)
		player.camera.zoom.y = player.camera.zoom.x
		shake(shakeInt)
	if (transformationStep == 4):
		transitionTimer -= _delta
		if (transitionTimer <= 0):
			if ($CanvasLayer/ColorRect.modulate.a < 1):
				$CanvasLayer/ColorRect.modulate.a += (0.02 * 20) * _delta
			var vol = AudioServer.get_bus_volume_db(0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), vol-(0.22 * 60) * _delta) 
		player.camera.zoom.x = lerp(player.camera.zoom.x, 2.5, (0.05 * 60) * _delta)
		player.camera.zoom.y = player.camera.zoom.x
		player.shake(3, 2)
		if (transitionTimer <= -5):
			Conductor.goToNextSection = true
			Conductor.fourthBeat = 4
			Conductor.waitUp = false
			transformationStep += 1
			player.global_position.x -= 80
			bossSprite.play("AirIdle")
			player.playerSprite.play("Transformation_tired")
			player.shadow.show()
			dustSpawn()
	if (transformationStep == 5):
		if ($CanvasLayer/ColorRect.modulate.a > 0):
			$CanvasLayer/ColorRect.modulate.a -= (0.02 * 20) * _delta
		if (Conductor.get_playback_position() >= 4.80 and $CanvasLayer/ColorRect.modulate.a <= 0):
			transformationStep += 1
			player.sfxTransformation.play()
			player.playerSprite.play("TransformationStep_1")
	if (transformationStep == 6):
		player.shake(3, 2)
		if (Conductor.get_playback_position() >= 8.40):
			transformationStep += 1
			player.playerSprite.play("TransformationStep_3")
	if (transformationStep == 7):
		scaredTimer -= _delta
		if (scaredTimer <= 0):
			if (bossSprite.get_animation() != "Scared"):
				bossSprite.play("Scared")
		if (Conductor.get_playback_position() >= 12.00):
			transformationStep += 1
			player.velocity.x = 245
			player.playerSprite.play("TransformationStep_5")
	if (transformationStep == 8):
		if ($CanvasLayer/ColorRect.modulate.a < 1 and Conductor.get_playback_position() <  14.40 ):
			player.velocity.x = 245
		if (Conductor.get_playback_position() >= 12.60 and Conductor.get_playback_position() < 14.40):
			player.camera.zoom.x = lerp(player.camera.zoom.x, 4.5, (0.3 * 60) * _delta)
			player.camera.zoom.y = player.camera.zoom.x
			player.camera.offset.y = lerp(player.camera.offset.y, 12.5, (0.3 * 60) * _delta)
			
			Engine.time_scale = 0.12
		if (Conductor.get_playback_position() >= 13.20):
			if ($CanvasLayer/ColorRect.modulate.a < 1):
				$CanvasLayer/ColorRect.modulate.a += (0.15 * 60) * _delta
		if (Conductor.get_playback_position() >= 14.40 and Conductor.get_playback_position() < 16.20):
			Engine.time_scale = 1
			player.camera.offset.y = 0
			player.camera.zoom.x = 1
			player.camera.zoom.y = 1
			player.velocity.x = 0
			player.velocity.y = 0
			if ($CanvasLayer/ShuraCaramelHit.modulate.a  < 1):
				$CanvasLayer/ShuraCaramelHit.modulate.a += (0.15 * 60) * _delta
		if (Conductor.get_playback_position() >= 16.20):
			if ($CanvasLayer/ShuraCaramelHit.modulate.a  > 0):
				$CanvasLayer/ShuraCaramelHit.modulate.a -= (0.15 * 60) * _delta
		
		if (Conductor.get_playback_position() >= 16.77):
			$CanvasLayer/ColorRect.modulate.a = 0
			$BigHit.play()
			get_parent().bossHP.visible = false
			get_parent().bossHP.frame = 8
			player.shake(3, 2)
			bossSprite.play("GotHit")
			player.playerSprite.play("ChuwaPunch")
			player.camera.offset.y = 0
			player.camera.offset.x = 0
			player.hitEffectSpawn("0")
			player.form = "Super"
			player.isInvincible = false
			player.superSpeed = 180.0
			velocity.x = 500
			velocity.y = -50
			transformationStep += 1
			wasSentFlying = true
			inThirdPhase = true
			#gotHit = false
			#tiredTimer = 5
			#onHold = false
			gotStruck = false
	if (transformationStep == 9):
		player.velocity.x = 0
	if ($AtckLaserLoop.playing):
		laserSoundPitch += (0.005 * 60) * _delta
		$AtckLaserLoop.pitch_scale = laserSoundPitch

func eyeSpawnLogic():
	if (getAnim() == "Attack_EyeAttack" and bossSprite.frame == 5 and !eyeOut):
		eyeOut = true
		shouldFollowPlayer = false
		
		var eyeId = eye.instantiate()
		get_parent().add_child(eyeId)
		eyeObject = eyeId
		eyeId.parent = self
		eyeId.global_position = eyeSpawnMarker.global_position
		eyeId.bossSprite.scale.x = bossSprite.scale.x

func dustSpawn():
	var dustId = dust.instantiate()
	get_parent().add_child(dustId)

func beeSpawn():
	createBee(0,-beeSpeed,-90, beeSpawnMarker.global_position)
	createBee(beeSpeed/1.5,-beeSpeed/1.5,-45, beeSpawnMarker.global_position)
	createBee(beeSpeed,0,0,position)
	createBee(beeSpeed/1.5,beeSpeed/1.5, 45, beeSpawnMarker.global_position)
	createBee(0,beeSpeed,90,position)
	createBee(-beeSpeed/1.5,beeSpeed/1.5, 135, beeSpawnMarker.global_position)
	createBee(-beeSpeed,0, -180,position)
	createBee(-beeSpeed/1.5,-beeSpeed/1.5, -135, beeSpawnMarker.global_position)

func createBee(hspe, vspe, ang, pos):
	var b = beeScene.instantiate()
	b.hsp = hspe
	b.vsp = vspe
	b.ang = ang
	b.global_position = pos
	b.z_index = z_index+1
	get_tree().current_scene.add_child(b)

func shootingStarAttackLogic():
	if (getAnim() == "Attack_ShootingStar" and bossSprite.frame >= 5 and attackStep == 0):
		attackStep += 1
		snapSfx.play()
		shootingStarSpawnLogic(0)
		shootingStarSpawnLogic(100)
		shootingStarSpawnLogic(-100)
	
func shootingStarSpawnLogic(starOffset):
	var starId = star.instantiate()
	get_parent().add_child(starId)
	starId.global_position.x = player.global_position.x - starOffset
	starId.global_position.y -= 400

func bigAssLaserSpawnLogic():
	var laserId = laser.instantiate()
	get_parent().add_child(laserId)
	laserId.global_position = $Boss_Sprite/LaserSpawnMarker.global_position

func facingAt():
	if (player.global_position.x < global_position.x):
		bossSprite.scale.x = 1
	else:
		bossSprite.scale.x = -1

func followPlayer(_delta):
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()

	if distance > 20:
		velocity = direction * speed

func _on_boss_sprite_animation_finished():
	if (getAnim() == "Attack_EyeAttack"):
		bossSprite.play("AirIdleNoEye")
	if (getAnim() == "Attack_ShootingStar"):
		attackStep = 0
		bossSprite.play("AirIdleNoEye")
	if (getAnim() == "Attack_beeNado"):
		bossSprite.play("AirIdleNoEye")
		attackStep = 0
	if (getAnim() == "Attack_Throw"):
		bossSprite.play("AirIdleNoEye")
	if (getAnim() == "TiredIntro"):
		bossSprite.play("Tired")
	if (getAnim() == "Attack_Laser_Startup"):
		bossSprite.play("Attack_Laser_Charge")
#		if (eyeObject.attckNumbLoop == 2):
#			eyeObject.attckNumbLoop = 0
#			eyeObject.resetAttackStuff()
#		else:
#			eyeObject.attckNumbLoop += 1

func getAnim():
	return bossSprite.get_animation()


func _on_animated_sprite_2d_animation_finished():
	if ($AnimatedSprite2D.get_animation() == "default" and $AnimatedSprite2D.frame > 1):
		$BigExplosion.play()
		defeatStep += 1
