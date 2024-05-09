extends Node2D

var rng = RandomNumberGenerator.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	GameDataManager.debrisSignal.connect(emitParticles)

func emitParticles():
	if (get_tree().current_scene.songHasChanged):
		var _randNumb = rng.randi_range(0, 1)
		$CPUParticles2D.emitting = true
