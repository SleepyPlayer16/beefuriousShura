extends Node2D

@export var currentChara = ""

var hasLanded = false
var dir = 1
var hasAttacked = false
var hasSummonedShield = false
var prepareToDelete = false
var deleteTimer = 3
var spawnedPlant = false

@onready var eruSpr = $eruA
@onready var plant = preload("res://scenes/other/meicaPlant.tscn")
@onready var lightningStrike = preload("res://scenes/assists/eruLightningStrike.tscn")
@onready var shield = preload("res://scenes/assists/nishield.tscn")

enum character {
	ERU,
	MEICA,
	NISHA
}

func _ready():
	if currentChara == "Eru" or currentChara == "Meica":
		$AudioStreamPlayer.play()
	if currentChara == "Nisha":
		$ShowUpNisha.play()
	#print(dir)
	if (currentChara == "Meica"):
		$Marker2D.global_position.x *= dir

func _process(delta):
	if currentChara == "Eru":
		eruLogic(delta)
	elif currentChara == "Nisha":
		nishaLogic(delta)
	elif currentChara == "Meica":
		meicaLogic(delta)

func eruLogic(delta):
	if (eruSpr.get_animation() == "Assist"):
		if eruSpr.frame >= 4:
			if (!hasAttacked):
				spawnLightnignStrike()
				hasAttacked = true
	if (prepareToDelete):
		deleteTimer -= delta
		if (deleteTimer <= 0):
			queue_free()

func nishaLogic(_delta):
	if (eruSpr.get_animation() == "Assist"):
		if eruSpr.frame >= 2:
			if (!hasSummonedShield):
				hasSummonedShield = true
				spawnShield()

func meicaLogic(_delta):
	if (eruSpr.frame <= 6):
		eruSpr.speed_scale = 1.35
	else:
		eruSpr.speed_scale = 1
	if (eruSpr.frame >= 21 and !spawnedPlant):
		spawnedPlant = true
		spawnPlant()

func _on_area_2d_body_entered(_body):
	pass

func spawnLightnignStrike():
	var lightning = lightningStrike.instantiate()
	add_child(lightning)
	
func spawnShield():
	var shieldNisha = shield.instantiate()
	get_parent().add_child(shieldNisha)
	get_parent().isShielded = true

func spawnPlant():
	var plantId = plant.instantiate()
	add_child(plantId)
	plantId.global_position = $Marker2D.global_position

func _on_eru_a_animation_finished():
	if currentChara == "Eru":
		if !hasLanded:
			hasLanded = true
			$eruA.play("Land")
		if eruSpr.get_animation() == "Land" and !eruSpr.is_playing():
			$eruA.play("Assist")
		if ( eruSpr.get_animation() == "Assist" or eruSpr.get_animation() == "AssistNothingFound") and eruSpr.frame != 0:
			eruSpr.play("GoAway")
		if eruSpr.get_animation() == "GoAway" and eruSpr.frame != 0:
			prepareToDelete = true
	elif currentChara == "Nisha":
		if eruSpr.get_animation() == "Appear":
			eruSpr.play("Assist")
		if eruSpr.get_animation() == "Assist" and eruSpr.frame > 0:
			queue_free()
