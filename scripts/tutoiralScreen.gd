extends Node2D

@export var signText = ""

var playerEntered = false
var playerObject = null

@onready var txtLabel = $CanvasLayer/ColorRect/RichTextLabel
# Called when the node enters the scene tree for the first time.
func _ready():
	txtLabel.text = signText

func _process(delta):
	if playerEntered:
		$CanvasLayer/ColorRect.modulate.a = clamp($CanvasLayer/ColorRect.modulate.a + ((0.09*60)*delta), 0, 1)
	else:
		$CanvasLayer/ColorRect.modulate.a = clamp($CanvasLayer/ColorRect.modulate.a - ((0.09*60)*delta), 0, 1)

func _on_area_2d_body_entered(body):
	if (body.name == "player"):
		playerEntered = true
		playerObject = body

func _on_area_2d_body_exited(body):
	if (body.name == "player"):
		playerEntered = false
