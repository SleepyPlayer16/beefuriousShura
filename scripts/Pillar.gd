extends Node2D

var screamDestruct = false
var activateDestruction = false
var gotDestroyed = false

func _ready():
	CutsceneHandler.bossScream.connect(bossScreamExplode)
	if (FinalBossManager.bossDefeated):
		hide()
		
func removeTexturesFromSprites(node):
	if Engine.time_scale == 1:
		Hitstun(0.2, 0.05)
	if (!screamDestruct):
		gotDestroyed = true
		$Break.play()
		$Break2.play()


	for i in range(node.get_child_count() - 1, -1, -1):
		var child = node.get_child(i)

		if child is Sprite2D:
#			print(child.name)
			child.get_node("CPUParticles2D").emitting = true
			gotDestroyed = true
			child.texture = null
		removeTexturesFromSprites(child)
			
func Hitstun(timeScale, duration):
	Engine.time_scale = timeScale
	await get_tree().create_timer(duration).timeout
	Engine.time_scale = 1

func bossScreamExplode():
	screamDestruct = true
	removeTexturesFromSprites(self)
	

func _on_area_2d_body_entered(body):
	if (body.name == "player" and !gotDestroyed):
		if (abs(body.velocity.x) > 360):
			if (!activateDestruction):
				removeTexturesFromSprites(self)
				activateDestruction = true
				body.playerSprite.visible = true
				if body.niShield != null:
					body.niShield.forceBreak()
				body.state = body.states.HITSTUN
				body.floorSplatSfx.play()
				body.camera.zoom.x = 2.5
				body.camera.zoom.y = 2.5
				if (body.is_on_floor()):
					body.knockback = -300
				else:
					body.velocity.x = 300
				body.velocity.y = -400
				body.shake(0.2, 2)
