extends CanvasLayer

var inBossFight = false
@onready var finalBHP = preload("res://sprites/hud/spr_shuraHPExtended.png")
@onready var shuraHp = $SprShuraHp

# Called when the node enters the scene tree for the first time.
func _ready():
#	$SprShuraHp.visible = true
#	if (get_tree().current_scene.name == "finalB_tstScn"):
	$SprShuraHp.texture = finalBHP
	$SprShuraHp.hframes = 8

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (get_parent().current_jump == 0):
		$EmotionsTest/SprJumpIndicatorSingleJump.frame = 0
	else:
		$EmotionsTest/SprJumpIndicatorSingleJump.frame = 1

	if $ShockWaveDelete.modulate.a > 0:
		$ShockWaveDelete.modulate.a -= (0.05 * 60) * delta
		for node in get_tree().get_nodes_in_group("shockwave"):
			node.remove_from_group("shockwave")
			node.queue_free()
	if (CutsceneHandler.inCutscene):
		if ($ProgressBar.visible):
			$ProgressBar.visible = false
			$EmotionsTest.visible = false
			$SprShuraHp.visible = false
		$ColorRect.modulate.a = clamp($ColorRect.modulate.a + delta * 5, $ColorRect.modulate.a, 1)
	else:
		if (!$ProgressBar.visible):
			$ProgressBar.visible = true
			$EmotionsTest.visible = true
			if (inBossFight):
				$SprShuraHp.visible = true
		$ColorRect.modulate.a = clamp($ColorRect.modulate.a - delta * 5, $ColorRect.modulate.a, 0)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "fadeIn":
		CutsceneHandler.playerHasDied = false
		CutsceneHandler.bossPhase = 0
		Conductor.signature = 4
		Conductor.songUnload()
		Conductor.volume_db = 0
		Conductor.resetEVERYTHINGGGGG()
		get_tree().change_scene_to_file("res://stages/level3.tscn")


func _on_spr_eru_hud_element_animation_finished():
	if ($SprShuraHp/SprEruHudElement.get_animation() == "Charging"):
		$SprShuraHp/SprEruHudElement.play("Full")

func _on_spr_nisha_hud_element_animation_finished():
	if ($SprShuraHp/SprNishaHudElement.get_animation() == "Charging"):
		$SprShuraHp/SprNishaHudElement.play("Full")

func _on_spr_meica_hud_element_animation_finished():
	if ($SprShuraHp/SprMeicaHudElement.get_animation() == "Charging"):
		$SprShuraHp/SprMeicaHudElement.play("Full")
