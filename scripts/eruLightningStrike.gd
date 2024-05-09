extends Node2D

var bosses = []
var original_position = Vector2(0, 0)
var shaking_duration = 0.5
var shaking_intensity = 1.0
var is_shaking = true
var hasStruck = false
var foundEnemy = true
var shake_timer = 0.0
var lightningFoundEnemy = false

func _ready():
	original_position = position
	bosses = get_tree().get_nodes_in_group("Bosses")

func _process(delta: float):
	if (find_closest_enemy() != null):
		if (!hasStruck):
			var bossClosest = get_tree().get_current_scene().get_node(str(find_closest_enemy().name))
			if bossClosest.attackChosen == bossClosest.states.TIRED:
				if (!visible):
					if (get_parent().get_node("eruA").get_animation() != "AssistNothingFound"):
						lightningFoundEnemy = true
						global_position = bossClosest.global_position
						original_position = bossClosest.global_position
						visible = true
						$AudioStreamPlayer.play()
						$Electricity.play()
			else:
				if !lightningFoundEnemy:
					noEnemyFound()
	else:
		noEnemyFound()
	
	if is_shaking:
		shake_timer += delta
		if shake_timer >= 0.3:
			modulate.a -= 1.2 * delta
		var random_offset = randf_range(-shaking_intensity, shaking_intensity)
		$Sprite2D.offset.x = 0 + random_offset
		$Sprite2D.offset.y = 0 + random_offset
	if (modulate.a <= 0 and !$AudioStreamPlayer.playing):
		queue_free()

func find_closest_enemy():
	var closest_distance = 999999
	var closest_enemy = null

	for boss in bosses:
		var distance = boss.global_position.distance_to(global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = boss

	return closest_enemy

func noEnemyFound():
	if (foundEnemy):
		foundEnemy = false
		get_parent().get_node("AudioStreamPlayer2").play()
		get_parent().get_node("eruA").play("AssistNothingFound")
		get_parent().get_node("eruA").frame = 5

# Call this function to start the sprite shaking
func start_shake():
	if !is_shaking:
		original_position = position
		is_shaking = true
		shake_timer = 0.0


func _on_lightning_area_entered(area):
	if (area.name == "BossHurtbox"):
		if area.get_parent().attackChosen == area.get_parent().states.TIRED:
			area.get_parent().gotStruck = true
