extends Node2D

@export var intensity = 0.8
# Called when the node enters the scene tree for the first time.
func _ready():
	$PointLight2D.energy = intensity
