extends AnimatedSprite2D

var timer = 6
var aboutToBreak = false
var breakShield = false
var forcedToBreak = false
var scale_speed = 5
var squash_scale = Vector2(1.0, 1.5) 
var stretch_scale = Vector2(1.2, 0.9)  
var oldPosX
var oldPosY
var tmer = 0.0
func _ready():
	get_parent().niShield = self

func _process(delta):
	if (get_parent().state != get_parent().states.GAMEOVER):
		timer -= delta
		tmer += 1
		rotation_degrees = lerp(rotation_degrees, 0.0, (0.05 * 60) * delta)
		scale_speed = 0.01

		if timer <= -3:
			get_parent().niShield = null
			queue_free()

		if timer <= 0 and !forcedToBreak:
			if oldPosX != null:
				shake(4, 6)
			if (!breakShield):
				var scale_factor = 2 + sin(Time.get_ticks_msec() * scale_speed) * 35
				scale = lerp(squash_scale, stretch_scale, (scale_factor)*delta) 

			if (!aboutToBreak):
				aboutToBreak = true
				oldPosX = position.x
				oldPosY = position.y
				$BubbleBreak.play()

		if $BubbleBreak.get_playback_position() >= 0.7:
			if (!breakShield):
				play("null")
				get_parent().isShielded = false
				breakShield = true
				$CPUParticles2D.emitting = true
				$CPUParticles2D2.emitting = true
	else:
		forceBreak()

func shake(duration, amplitude):
	var timerS = get_tree().create_timer(duration)
	while timerS.time_left > 0:
		position.x = oldPosX + randf_range(floor(-amplitude), floor(amplitude))
		position.y = oldPosY + randf_range(floor(-amplitude), floor(amplitude))
		await(get_tree().process_frame)

func forceBreak():
	if (!breakShield):
		forcedToBreak = true
		timer = 0
		if $BubbleBreak.playing:
			if ($BubbleBreak.get_playback_position() < 0.7):
				$BubbleBreak.play(0.7)
		else:
			$BubbleBreak.play(0.7)
			$BubbleBreak.seek(0.7)
		play("null")
		get_parent().isShielded = false
		breakShield = true
		$CPUParticles2D.emitting = true
		$CPUParticles2D2.emitting = true
