extends StaticBody2D

var steppedOn = false
var onTop = false
var player = null
var timeBeforeFallInitialValue =15
var timeBeforeFall = 15
var timerSpeed = 120
var gravity = 0
var isFalling = false
var repositionTimer = 3
var originalPosition = null

func _ready():
	originalPosition = $Sprite2D.position.y

func _process(delta):
	if (isFalling):
		repositionTimer -= delta

	if (repositionTimer <= 0):
		isFalling = false
		onTop = false
		timeBeforeFall = timeBeforeFallInitialValue
		steppedOn = false
		repositionTimer = 3
		$CollisionShape2D.set_deferred("disabled", false)
		gravity = 0
		$Sprite2D.position.y = originalPosition
	
	if (player != null):
		if (steppedOn):
			if (player.emotionPowerActive):
				if (player.current_emotion == player.emotions.UOOGHHH):
					onTop = false
				else:
					onTop = true
			else:
				if (!onTop):
					timeBeforeFall = timeBeforeFallInitialValue
					onTop = true

		if (onTop):
			if (timeBeforeFall > 1):
				$AnimationPlayer.play("TooHeavy")
			timeBeforeFall -= timerSpeed * delta
		else:
			timeBeforeFall += timerSpeed * delta
			if (timeBeforeFall > 1):
				$AnimationPlayer.play("Normal")

	if (timeBeforeFall <= 0 and !isFalling):
		isFalling = true
		$AudioStreamPlayer2.play()

	if (isFalling):
		$CollisionShape2D.set_deferred("disabled", true)
		gravity += 10 * delta
		$AnimationPlayer.play("Fall")
		$Sprite2D.position.y += gravity

func _on_area_2d_body_entered(body):
	if (body.name == "player" and !isFalling) and !steppedOn:
		player = body
		steppedOn = true
		$AudioStreamPlayer.play()
		timeBeforeFall = timeBeforeFallInitialValue

func _on_area_2d_body_exited(body):
	if (body.name == "player" and !isFalling):
		if (!isFalling):
			timeBeforeFall = timeBeforeFallInitialValue

