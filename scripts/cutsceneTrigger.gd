extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_area_2d_body_entered(body):
	if (body.name == "player"):
		body.velocity.x = 0
		if (get_tree().current_scene.name == "level2"):
			get_parent().spawnBoss()
			CutsceneHandler.snowCutscene = true
			CutsceneHandler.SnowAreaCutscene()
		else:
			if CutsceneHandler.bossPhase == 0:
				CutsceneHandler.bossPhase = 1
			CutsceneHandler.finalBossFirstCutscene()
