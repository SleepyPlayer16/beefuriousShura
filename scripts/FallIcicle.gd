extends Node2D

var originalPos
var falling = false
var nextBeat
var ground
var spd = 0
var falltime
var speedMultiplier = 2.0
var duration = 0.2
var movementSpeed = 0.0
var initialPosition = null
var touchedGrass = false
var timer = 1
var initialTimer = 1

@export var beat = 1

@onready var audioPlayer = $AudioStreamPlayer2D

func _ready():
	Conductor.fourthSignal.connect(triggerFall)
	Conductor.resetSignal.connect(reset)
	originalPos = position.x
	initialPosition = $FallingIcicle.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (initialTimer > 0):
		initialTimer -= _delta
	if touchedGrass:
		timer -= 60 * _delta
		if timer <= 0:
			touchedGrass = false
			timer = 1
	if ($FallingIcicle.position == initialPosition):
		touchedGrass = false

	if falling:
		var timeSinceLastBeat = Conductor.songPosition - (nextBeat)
		var normalizedTime = timeSinceLastBeat / (Conductor.crotchet)
		if movementSpeed == 0:
			if !$FallingIcicle.visible:
				$FallingIcicle.play("default")
#				$DeathArea/deathCol.set_deferred("disabled", true)
				$FallingIcicle.visible = true

		var t = ease(normalizedTime, (2 - sqrt(1 - pow(1, 2))))
		movementSpeed = speedMultiplier * t
		if (!touchedGrass):
			$FallingIcicle.position.y = (movementSpeed*0.1) * 128*(5.9)
			$CPUParticles2D.position.y = $FallingIcicle.position.y
#		$DeathArea.position.y = $FallingIcicle.position.y

func _on_area_2d_body_entered(body):
#	$DeathArea/deathCol.set_deferred("disabled", false)
	if movementSpeed != 0:
		#print_debug("what the fuck do you mean disabled is null")
		if (body.name == "player"):
			body.state = body.states.DEATH
			body.explosionSfx.play()

		if body.name != "PlayerObject":
			$CPUParticles2D.emitting = true
			if $FallingIcicle.visible:
				if (initialTimer <= 0):
					$AudioStreamPlayer2D.play()
				$FallingIcicle.visible = false
				touchedGrass = true

func triggerFall():
	nextBeat = (Conductor.lastBeat + (Conductor.crotchet*beat)) 
	falling = true

func reset():
	if (initialTimer <= 0):
		if beat == 3:
			nextBeat = Conductor.crotchet
		if beat == 2:
			nextBeat = 0
		if beat == 1:
			if $FallingIcicle.visible:
				$CPUParticles2D.emitting = true
				audioPlayer.play()
				$FallingIcicle.visible = false
			

#func _on_death_area_body_entered(body):
#
#	if body.name == "PlayerObject":
#		$AudioStreamPlayer2D.play()
##		$CPUParticles2D.emitting = true
#		$FallingIcicle.visible = false
#		print("this SHOUYLD Work, why is this shit not working")
#		if (body.stateMachine.state != body.stateMachine.states.parry):
#			body.die = true
