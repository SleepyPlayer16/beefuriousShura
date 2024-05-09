extends Node2D

var playerEntered = false
var targetVolume = 0.0  # The target volume you want to reach
var volumeChangeSpeed = 5.0  # Adjust this value to control the speed of the volume change
var curVolume
var curHVolume

func _ready():
	# Initialize the volume to its initial level
	curVolume = Conductor.volume_db

func _process(delta):
# If the player has entered the area, smoothly adjust the volume towards the target
	if playerEntered:
		if abs(curVolume - Conductor.targetVolume) > 0.1:
			# Gradually decrease the volume towards the target
			if curVolume > Conductor.targetVolume:
				curVolume -= volumeChangeSpeed * delta
				curHVolume += volumeChangeSpeed * delta
			# Gradually increase the volume towards the target
			else:
				curVolume += volumeChangeSpeed * delta
				curHVolume += volumeChangeSpeed * delta
				
			# Apply the new volume to your audio source (Conductor in this case)
			Conductor.volume_db = curVolume
			Conductor.highTensionSong.volume_db = curHVolume

func _on_area_2d_body_entered(body):
	if body.name == "player" and !playerEntered:
		curVolume = Conductor.volume_db
		curHVolume = Conductor.highTensionSong.volume_db
		Conductor.targetVolume -= 10
		Conductor.targetHVolume += 5
		playerEntered = true
