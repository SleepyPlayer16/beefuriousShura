extends Node2D

var returnToMenuTimer = 9
var returnToMenu = false
var sSkipTimer = 4.25
var skipped = false
var goToNextSceneTimer = 1.25
var protectSecretEnding = false

@onready var skipColorRect = $SkipColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
	DiscordRPC.state = "Créditos"
	DiscordRPC.refresh()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (sSkipTimer > 0):
		sSkipTimer -= delta
	if (sSkipTimer <= 0):
		$SprSToSkip.modulate.a -= (0.02 * 60) * delta
	
	if (Input.is_action_just_pressed("skipCutscene") and !skipped):
		Conductor.stop()
		Conductor.resetEVERYTHINGGGGG()
		skipped = true
		skipColorRect.show()
	
	if (skipped):
		goToNextSceneTimer -= delta
		if (goToNextSceneTimer <= 0):
			if (protectSecretEnding):
				get_tree().change_scene_to_file("res://scenes/OctaveLogo.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/other/endingE.tscn")

	if (!skipped):
		if ($ColorRect2.modulate.a > 0):
			$ColorRect2.modulate.a -= (0.01 * 60 ) * delta
		if ($RichTextLabel.position.y <= -2754):
			if (!returnToMenu):
				returnToMenu = true
			$ColorRect.modulate.a += (0.005 * 60) * delta
		if (returnToMenu):
			returnToMenuTimer -= delta
			if (returnToMenuTimer <= 0):
				if (protectSecretEnding):
					get_tree().change_scene_to_file("res://scenes/OctaveLogo.tscn")
				else:
					get_tree().change_scene_to_file("res://scenes/other/endingE.tscn")
				Conductor.resetEVERYTHINGGGGG()
			$Shura.position.x -= (0.8*320)*delta
			$Pantcakes.position.x -= (0.6*320)*delta
			$Pantcakes2.position.x -= (0.5*320)*delta
			$Pantcakes3.position.x -= (0.35*320)*delta
		$RichTextLabel.position.y -= (0.73*60)*delta
		$CanvasLayer/Ground/ParallaxLayer.motion_offset.x += (3.5* 60) * delta
		$CanvasLayer/ParallaxBackground4/ParallaxLayer.motion_offset.x += (0.2 * 60) * delta
		$CanvasLayer/ParallaxBackground3/ParallaxLayer.motion_offset.x += (0.5 * 60) * delta
		$CanvasLayer/ParallaxBackground2/ParallaxLayer.motion_offset.x += (0.8 * 60) * delta
