extends CanvasLayer

@export var boss = 1
@export var finalBoss = false

var curScene
var introPlayed = false

func _ready():
	introPlayed = FinalBossManager.introPlayed
	curScene = get_tree().current_scene.name
	if (boss == 1):
		$CreaturasVsScreen.show()
		$AnimationPlayer.play("Spawn")
	else:
		$AnimationPlayer2.play("finalBossIntro")
		DiscordRPC.state = "Jefe Final"
		DiscordRPC.refresh()
		$CaramelConfident.show()

func _process(_delta):
	if (curScene == "finalB_tstScn"):
		if (introPlayed):
			call_deferred("queue_free")

	if $AnimationPlayer.is_playing():
		if ($AnimationPlayer.current_animation == "Spawn" or $AnimationPlayer.current_animation == "Spawn_2" ) and $AnimationPlayer.current_animation_position >= 2.5:
			if (CutsceneHandler.inCutscene):
				if (get_tree().current_scene.name == "level2"):
					get_tree().get_current_scene().bossHP.visible = true
				else:
					get_parent().arenaTeleport()
				CutsceneHandler.inCutscene = false
	if ($AnimationPlayer.current_animation == "Spawn_2"):
		if $AnimationPlayer.current_animation_position >= 2.5:
			CutsceneHandler.inCutscene = false
			FinalBossManager.introPlayed = true


func _on_animation_player_animation_finished(anim_name):
	if (anim_name == "Spawn" or anim_name == "Spawn_2"):
		CutsceneHandler.emit_signal("finalBossBeginSignal")
		queue_free()

func playVsAnim():
	$AnimationPlayer.play("Spawn_2")
