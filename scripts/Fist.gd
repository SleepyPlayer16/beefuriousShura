extends Area2D

@export var frame = 0

@onready var parent = null

var canBeActivated = false
var playerInside = false

@onready var fistSprite = $SprFist
@onready var animPlayer = $AnimationPlayer
@onready var hitbox = $FistCollisionShape/blastZone/Area2D/CollisionShape2D

func _ready():
	hitbox.set_deferred("disabled", true)
	fistSprite.frame = frame

func _process(_delta):
	if (parent != null and canBeActivated):
		if (!parent.dead):
			if (animPlayer.current_animation == "Hit" and animPlayer.current_animation_position >= 0.8):
				if (!hitbox.disabled):
					hitbox.set_deferred("disabled", true)
			if !(parent.attackChosen == parent.states.MOLE or parent.attackChosen == parent.states.DAMAGED or parent.attackChosen == parent.states.TIRED):
				if (parent.attackLoop <= 3):
					if (animPlayer.current_animation):
						if (animPlayer.current_animation_position >= 1.6 and playerInside):
							hitbox.set_deferred("disabled", false)
							animPlayer.play("Hit")
							playerInside = true
					else:
						if (playerInside):
							hitbox.set_deferred("disabled", false)
							animPlayer.play("Hit")
							playerInside = true

func _on_body_entered(body):
	if (parent != null):
		if (body.name == "player" and canBeActivated):
			playerInside = true

func _on_body_exited(body):
	if (body.name == "player" and canBeActivated):
		playerInside = false
