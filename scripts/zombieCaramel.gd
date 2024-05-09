extends AnimatedSprite2D

@onready var dash1 = $Dash
@onready var dash2 = $Dash2
@onready var clashSong = preload("res://music/mus_takeover.ogg")
@onready var shakeTimer = $Timer

var clashedWithPlayer = false
var mashingDone = false
var explosionSoundPlayed = false
var timerStarted = false
var initialCoords = 0
var timerStart = false
var timer = 0.02
var mashBegin = false
var mashBeginTimer = 2

func _process(delta):
	if (mashBeginTimer > 0 and mashBegin):
		mashBeginTimer -= delta
	if (timerStart):
		timer -= delta
		if (timer <= 0):
			timer = 0.01
			if (get_parent().player.state != get_parent().player.states.GAMEOVER):
				get_parent().player.shake(0.2, 10)

	if (mashBeginTimer <= 0):
		get_parent().player.buttonMash.modulate.a = lerp(get_parent().player.buttonMash.modulate.a, 1.0, (0.05 * 60) * delta)
		get_parent().player.clash_hp.modulate.a = lerp(get_parent().player.clash_hp.modulate.a, 1.0, (0.05 * 60) * delta)
		
		if (clashedWithPlayer and !mashingDone):
			get_parent().player.clash_hp.value += (0.70 * 10) * delta
			get_parent().player.global_position.x += (0.7 * 10) * delta
			if (Input.is_action_just_pressed("buttonMash1") or Input.is_action_just_pressed("buttonMash2")):
				get_parent().player.clash_hp.value -= 1.15
				get_parent().player.global_position.x -= 1.1
			if (get_parent().player.clash_hp.value <= 0):
				mashingDone = true
				Conductor.resetEVERYTHINGGGGG()
				Conductor.stop()
				get_parent().player.buttonMash.visible = false
				get_parent().player.clash_hp.visible = false
		if (mashingDone):
			if (!explosionSoundPlayed):
				explosionSoundPlayed = true
				$Boom.play()

			if (get_parent().whiteFade.modulate.a < 1):
				get_parent().whiteFade.modulate.a += (0.2 * 60) * delta
			else:
				if (!timerStarted):
					get_parent().caramelSpeechTimer.start()
					get_parent().secondDiagTrigger = true
					timerStarted = true

func _on_area_2d_body_entered(body):
	if (body.name == "player" and !clashedWithPlayer):
		if (CutsceneHandler.inCutscene and !mashingDone):
			clashedWithPlayer = true
			get_parent().pantcake.play("scared")
			setUp(body)
				
func setUp(body):
	body.hp = 0
	if (initialCoords == 0):
		initialCoords = body.global_position.x
	body.global_position.x = initialCoords - 40.0
	body.camera.offset.x = 0.0
	body.camera.offset.y = 4
	body.playerSprite.offset.y -= 12
	body.camera.zoom.x = 4
	body.camera.zoom.y = 4
	body.playerSprite.play("Clash")
	body.playerSprite.scale.x *= -1
	visible = false
	body.buttonMash.visible = true
	body.clash_hp.visible = true
	body.shockWaveAnimPlay.play("cutsceneWhiteFadeOut")
	body.cutsceneStep += 1
	timerStart = true
	mashBegin = true
	Conductor.shouldLoop = true
	Conductor.resetEVERYTHINGGGGG()
	Conductor.songToLoad(157, -5, clashSong)
	Conductor.volume_db = -5
	Conductor.play()


func _on_timer_timeout():
	pass
