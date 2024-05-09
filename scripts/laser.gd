extends Node2D

var dir = Vector2.RIGHT
var speed = 260

@onready var player = get_parent().get_node_or_null("player")
@onready var deflectSfx = $LaserPew2
@onready var col = $blastZone/Area2D/CollisionShape2D

func _ready():
	$blastZone.isLaser = true

func _process(delta):
	translate(dir.normalized() * speed * delta)
	var distance_to_player = global_position.distance_to(player.global_position)
	if (distance_to_player < 20):
		col.set_deferred("disabled", false)
	else:
		col.set_deferred("disabled", true)

func _on_timer_timeout():
	queue_free()
