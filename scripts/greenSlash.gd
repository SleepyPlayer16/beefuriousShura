extends Node2D

var dir = -1
var spd = -160
var damageType = 0
var damage = 1
var speedIncrease = 0
var amplitude = 2
var frequency = 2
var speed = 100
var type = 0
var rotation_amplitude := 60.0  # Adjust the rotation amplitude
var starting_position: Vector2
var horizontal_position = 0.0  # To store the horizontal position
var sinVerticalSartPos = 1
var timer = 1
var globalPos
var deletTimer = 8
# Called when the node enters the scene tree for the first time.
func _ready():
	deletTimer = 8
	$AnimatedSprite2D.scale.x = dir
	starting_position = position
	horizontal_position = global_position.x
#	if (name == "quakeWave"):
#		$AnimatedSprite2D/blastZone.damageType = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	deletTimer -= delta
	if (deletTimer <= 0):
		queue_free()
	if (type == 0):
		position.x += (spd * ($AnimatedSprite2D.scale.x)) * delta
#		speedIncrease += ((100 * delta) * ($AnimatedSprite2D.scale.x * -1 ))
#		print((((spd - speedIncrease) * ($AnimatedSprite2D.scale.x * -1)) * delta))
	else:
		horizontal_position += ((speed * (dir*-1)) * delta)
		var new_y = (sin(Time.get_ticks_msec() / 1000.0 * frequency) * amplitude) * sinVerticalSartPos
		new_y += global_position.y
		position.y = new_y
		
		var rotation_angle = sin((Time.get_ticks_msec() / 1000.0) * frequency) * rotation_amplitude
		rotation_degrees = (rotation_angle * sinVerticalSartPos) * (dir*-1)
		if (dir == 1):
			$AnimatedSprite2D.scale.y = -1
		position.x = horizontal_position

	$AnimatedSprite2D/blastZone.damageType = damageType
	$AnimatedSprite2D/blastZone.damage = damage

func _on_animated_sprite_2d_animation_finished():
	if ($AnimatedSprite2D.get_animation() == "Spawn"):
		$AnimatedSprite2D.play("Default")
