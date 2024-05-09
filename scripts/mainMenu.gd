extends Node2D

const LEVEL_SELECT_POSITION = [56, 128, 208, 280, 352, 424]

var cur_menu = 0
var cur_option = 0
var moving = false
var canMove = true
var multiplier = 1
var changeChara = false
var preventSpam = 0.5
var inOptionsMenu = false
var curOptionMenu2 = 1
var volDB = 100
var volDBMus = 100
var unlockedLevels = 1
var curLevelOption = 1

var goToIntroCutscene = false
var continueGame = false


@onready var animationPlayer = $title/AnimationPlayer
@onready var audioPlayer = $AudioStreamPlayer
@onready var backCharas = $mainmenu/BackCharas
@onready var hSlider1 = $SprOptionsMenu/HSlider1
@onready var hSlider2 = $SprOptionsMenu/HSlider2
@onready var hSliderTimer = $HSliderTimer

@onready var textNotifier = preload("res://scenes/other/textNotifier.tscn")

@onready var options = [
	$mainmenu/options/SprJugar,
	$mainmenu/options/SprSalir,
	$mainmenu/options/SprContinuar,
	$mainmenu/options/SprOpciones,
]

@onready var menuMoveSfx = $MenuMove
@onready var menuSelectSfx = $MenuSelect
@onready var menuGoBackSfx = $MenuGoBack

var start_pos = Vector2(0,0)
var arc_height: float = 200.0
var duration: float = 0
var current_time: float = 0.0
var jugarPos
var salirPos
var continuarPos
var opcionesPos
var positions = [Vector2(0,8), Vector2(256,256), Vector2(-8, 528), Vector2(-264,256)]
var canInteract = false
var bpm = 140
var lastBeatDouble = 0
var doublecrotchet = 60/float(bpm)
var newGameAsk = false
var currentBeat = 1

func _ready():
	GameDataManager.deaths = 0
	Conductor.curScene = ""
	CutsceneHandler.playerContinued = false
	CutsceneHandler.lastCheckpoint = null
	CutsceneHandler.playerContinued = false
	GameDataManager.levelCleared = false
	GameDataManager.paused = false
	FinalBossManager.introPlayed = false
	FinalBossManager.lastPhase = 1
	FinalBossManager.truePhase = 1
	FinalBossManager.bossDefeated = false
	CutsceneHandler.resetAll()
	jugarPos = options[0].position 
	salirPos = options[1].position
	continuarPos = options[2].position
	opcionesPos = options[3].position
	hSlider1.value = SaveDataManager.data["settings_data"]["sfxVolume"]
	hSlider2.value = SaveDataManager.data["settings_data"]["musVolume"]
	#print(hSlider1.value)
	$SprOptionsMenu/SprCheck.frame = SaveDataManager.data["settings_data"]["fullscreen"]
	$SprOptionsMenu/SprCheck4.frame = SaveDataManager.data["settings_data"]["vsync"]
	
	if (SaveDataManager.data["game_data"]["level2_unlocked"]):
		if (!SaveDataManager.data["game_data"]["creaturas_unlocked"]):
			unlockedLevels = 2
		else:
			unlockedLevels = 3

	if (SaveDataManager.data["game_data"]["level3_unlocked"]):
		if (!SaveDataManager.data["game_data"]["finalBoss_unlocked"]):
			unlockedLevels = 4
		else:
			unlockedLevels = 5

	if (unlockedLevels == 5 and SaveDataManager.data["game_data"]["level4_unlocked"]):
		unlockedLevels = 6
	$SprNiveles.frame = unlockedLevels-1
	#if (!SaveDataManager.data["game_data"]["level2_unlocked"] and SaveDataManager.data["game_data"]["level3_unlocked"]):
		#SaveDataManager.data["game_data"]["level3_unlocked"] = false
		#SaveDataManager.save_data(SaveDataManager.data) #nope bitch

	DiscordRPC.details = ""
	DiscordRPC.state = "Menú Principal"
	DiscordRPC.refresh()
func _process(delta):
	if ($Camera2D.zoom.x != 1):
		$Camera2D.zoom.x = lerp($Camera2D.zoom.x, 1.0, (0.1*60)*delta)
		$Camera2D.zoom.y = $Camera2D.zoom.x
	var songPosition = audioPlayer.get_playback_position() + AudioServer.get_time_since_last_mix()
	if ( songPosition  > lastBeatDouble + (doublecrotchet)) and audioPlayer.playing:
		lastBeatDouble += doublecrotchet
		currentBeat += 1
		if (currentBeat % 4 == 0):
			$Camera2D.zoom.x = 1.02
			$Camera2D.zoom.y = 1.02
		$WhiteLineMenu.show()
		$whiteLineAnimPlayer.play("whiteLine")
		$whiteLineAnimPlayer.seek(0.0)
	
	
	
	if audioPlayer.get_playback_position() >= 1.28 and !changeChara and audioPlayer.get_playback_position() < 30.44:
		currentBeat = 1
		lastBeatDouble = 0
		changeChara = true
		canInteract = true
		backCharas.visible = true
		backCharas.play("1")

	if audioPlayer.get_playback_position() >= 30.44 and changeChara and audioPlayer.get_playback_position() < 57.85:
		changeChara = false
		backCharas.play("2")

	if audioPlayer.get_playback_position() >= 57.85 and !changeChara and audioPlayer.get_playback_position() < 71.57:
		changeChara = true
		backCharas.play("1")

	if audioPlayer.get_playback_position() >= 71.57 and changeChara:
		changeChara = false
		backCharas.play("2")

	if (inOptionsMenu):
		#incorrect way of coding volume stuff but damn i kinda dont care
		#nvm fixed i think
		if (Input.is_action_pressed("ui_left") and curOptionMenu2 == 2):
			if (hSliderTimer.is_stopped()):
				hSliderTimer.start()
				menuMoveSfx.play()
				if (hSlider1.value > 0.1):
					hSlider1.value -= 0.1
					var val = linear_to_db(hSlider1.value)
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), val)
					SaveDataManager.data["settings_data"]["sfxVolume"] = hSlider1.value

		if (Input.is_action_pressed("ui_right") and curOptionMenu2 == 2):
			if (hSliderTimer.is_stopped()):
				hSliderTimer.start()
				menuMoveSfx.play()
				hSlider1.value += 0.1
				#print(hSlider1.value)
				var val = linear_to_db(hSlider1.value)
				AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), val)
				SaveDataManager.data["settings_data"]["sfxVolume"] = hSlider1.value

		if (Input.is_action_pressed("ui_left") and curOptionMenu2 == 3):
			if (hSliderTimer.is_stopped()):
				hSliderTimer.start()
				menuMoveSfx.play()
				if (hSlider2.value > 0.1):
					hSlider2.value -= 0.1
					var val = linear_to_db(hSlider2.value)
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), val)
					SaveDataManager.data["settings_data"]["musVolume"] = hSlider2.value
		
		if (Input.is_action_pressed("ui_right") and curOptionMenu2 ==3):
			if (hSliderTimer.is_stopped()):
				hSliderTimer.start()
				menuMoveSfx.play()
				hSlider2.value += 0.1
				var val = linear_to_db(hSlider2.value)
				AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), val)
				SaveDataManager.data["settings_data"]["musVolume"] = hSlider2.value
	
		if (Input.is_action_just_pressed("ui_select")):
			if (curOptionMenu2 == 1 and $spamTimer.is_stopped()):
				$spamTimer.start()
				if ($SprOptionsMenu/SprCheck.frame == 0):
					menuSelectSfx.play()
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
					$SprOptionsMenu/SprCheck.frame = 1
				else:
					menuGoBackSfx.play()
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
					$SprOptionsMenu/SprCheck.frame = 0
			SaveDataManager.data["settings_data"]["fullscreen"] = $SprOptionsMenu/SprCheck.frame
			
			if (curOptionMenu2 == 4 and $spamTimer.is_stopped()):
				$spamTimer.start()
				if ($SprOptionsMenu/SprCheck4.frame == 1):
					menuGoBackSfx.play()
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
					$SprOptionsMenu/SprCheck4.frame = 0
				else:
					menuSelectSfx.play()
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
					$SprOptionsMenu/SprCheck4.frame = 1
			SaveDataManager.data["settings_data"]["vsync"] = $SprOptionsMenu/SprCheck4.frame

		if (Input.is_action_just_pressed("ui_cancel") or (Input.is_action_just_pressed("ui_select") and curOptionMenu2 == 5)):
			$spamTimer.start()
			SaveDataManager.save_data(SaveDataManager.data)
			inOptionsMenu = false
			curOptionMenu2 = 1
			$SprOptionsMenu.frame = curOptionMenu2-1
			menuGoBackSfx.play()

		if (Input.is_action_just_pressed("ui_down")):
			menuMoveSfx.play()
			if (curOptionMenu2 < 5):
				curOptionMenu2 += 1
			else:
				curOptionMenu2 = 1
			$SprOptionsMenu.frame = curOptionMenu2-1
		if (Input.is_action_just_pressed("ui_up")):
			menuMoveSfx.play()
			if (curOptionMenu2 != 1):
				curOptionMenu2 -= 1
			else:
				curOptionMenu2 = 5
			$SprOptionsMenu.frame = curOptionMenu2-1
			
		$SprOptionsMenu.position.y = lerp($SprOptionsMenu.position.y, 280.0, (0.4 * 60) * delta)
	else:
		$SprOptionsMenu.position.y = lerp($SprOptionsMenu.position.y, 824.0, (0.4 * 60) * delta)
		
	menu2(delta)
	menu3(delta)
	
	if (newGameAsk and cur_menu == 1):
		if (Input.is_action_just_pressed("ui_select")):
			$spamTimer.start()
			if ($SprNuevaPartidaQuestion.frame == 0):
				SaveDataManager.data["game_data"]["level2_unlocked"] = false
				SaveDataManager.data["game_data"]["creaturas_unlocked"] = false
				SaveDataManager.data["game_data"]["level3_unlocked"] = false
				SaveDataManager.data["game_data"]["finalBoss_unlocked"] = false
				SaveDataManager.data["game_data"]["level4_unlocked"] = false
				SaveDataManager.data["game_data"]["secret_lab_unlocked"] = false
				SaveDataManager.data["game_data"]["current_level"] = "1"
				SaveDataManager.save_data(SaveDataManager.data)
				goToIntroCutscene = true
				$SceneSwitchTimer.start()
				cur_menu = 2
				menuSelectSfx.play()
			else:
				newGameAsk = false
				menuGoBackSfx.play()
		if (Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")):
			menuMoveSfx.play()
			if ($SprNuevaPartidaQuestion.frame == 0):
				$SprNuevaPartidaQuestion.frame = 1
			else:
				$SprNuevaPartidaQuestion.frame = 0
				
		$SprNuevaPartidaQuestion.modulate.a = lerp($SprNuevaPartidaQuestion.modulate.a, 1.0, (0.3 * 60) * delta)
	else:
		$SprNuevaPartidaQuestion.modulate.a = lerp($SprNuevaPartidaQuestion.modulate.a, 0.0, (0.3 * 60) * delta)
	if cur_menu == 1:
		if $FakeAudio.pitch_scale > 0.12:
			$FakeAudio.pitch_scale -= (0.012*60)*delta
		else:
			if ($FakeAudio.playing):
				$FakeAudio.stop()
				
		if !moving:
			$mainmenu/options.modulate.a = lerp($mainmenu/options.modulate.a, 1.0, (0.3 * 60) * delta)
			$mainmenu/SprTire.position.x = lerp($mainmenu/SprTire.position.x, 0.0, (0.2 * 60) * delta)
			if (canInteract and !newGameAsk):
				if !inOptionsMenu and $spamTimer.is_stopped():
					if (Input.is_action_just_pressed("ui_select")):
						menuSelectSfx.play()
						
						if (cur_option == 0 and $spamTimer.is_stopped()):
							$spamTimer.start()
							newGameAsk = true
						if (cur_option == 1):
							if (SaveDataManager.data["game_data"]["current_level"]) == "none":
#								print("no save data found")
								if ($spamTimer.is_stopped()):
									$spamTimer.start()
									createText()
							else:
								cur_menu = 3
						if (cur_option == 2):
							if (!inOptionsMenu):
								inOptionsMenu = true
						if (cur_option == 3):
							get_tree().quit()
					if Input.is_action_just_pressed("ui_up"):
						menuMoveSfx.play()
						duration = 0.2
						current_time = 0.0
						cur_option = (cur_option - 1 + 4) % 4
						multiplier = 1
						animationPlayer.play("MoveOption_2")
						
					elif Input.is_action_just_pressed(("ui_down")):
						menuMoveSfx.play()
						duration = 0.2
						current_time = 0.0
						cur_option = (cur_option + 1) % 4
						multiplier = -1
						animationPlayer.play("MoveOption")

		if current_time < duration:
			current_time += delta
			var t = current_time / duration
			if !moving:
				jugarPos = options[0].position 
				salirPos = options[1].position
				continuarPos = options[2].position
				opcionesPos = options[3].position
				moving = true
			match cur_option:
				0:
					options[0].position = bezier(jugarPos, jugarPos + Vector2(arc_height*1.15, arc_height/2), positions[1], t)
					options[1].position = bezier(salirPos, salirPos + Vector2(0, -arc_height), positions[0], t)
					options[2].position = bezier(continuarPos, continuarPos + Vector2(0, arc_height), positions[2], t)
					options[3].position = bezier(opcionesPos, opcionesPos + Vector2(0, arc_height*multiplier), positions[3], t)
				1:
					options[0].position = bezier(jugarPos, jugarPos + Vector2(0, -arc_height), positions[0], t)
					options[1].position = bezier(salirPos, salirPos + Vector2(0, arc_height*multiplier), positions[3], t)
					options[2].position = bezier(continuarPos, continuarPos + Vector2(arc_height, arc_height/2), positions[1], t)
					options[3].position = bezier(opcionesPos, opcionesPos + Vector2(-arc_height, arc_height), positions[2], t)
				2:
					options[0].position = bezier(jugarPos, jugarPos + Vector2(0, arc_height*multiplier), positions[3], t)
					options[1].position = bezier(salirPos, salirPos + Vector2(0, arc_height), positions[2], t)
					options[2].position = bezier(continuarPos, continuarPos + Vector2(0, arc_height*multiplier), positions[0], t)
					options[3].position = bezier(opcionesPos, opcionesPos + Vector2(arc_height, arc_height/2), positions[1], t)
				3:
					options[0].position = bezier(jugarPos, jugarPos + Vector2(0, +arc_height), positions[2], t)
					options[1].position = bezier(salirPos, salirPos + Vector2(+arc_height, arc_height/2), positions[1], t)
					options[2].position = bezier(continuarPos, continuarPos + Vector2(0, arc_height*multiplier), positions[3], t)
					options[3].position = bezier(opcionesPos, opcionesPos + Vector2(0, arc_height*multiplier), positions[0], t)
		else:
			moving = false
			match cur_option:
				0:
					options[0].position = positions[1]
					options[1].position = positions[0]
					options[2].position = positions[2]
					options[3].position = positions[3]
				1:
					options[0].position = positions[0]
					options[1].position = positions[3]
					options[2].position = positions[1]
					options[3].position = positions[2]
				2:
					options[0].position = positions[3]
					options[1].position = positions[2]
					options[2].position = positions[0]
					options[3].position = positions[1]
				3:
					options[0].position = positions[2]
					options[1].position = positions[1]
					options[2].position = positions[3]
					options[3].position = positions[0]

func menu2(delta):
	if (cur_menu == 2):
		$mainmenu/options.modulate.a = lerp($mainmenu/options.modulate.a, 0.0, (0.3 * 60) * delta)
		$mainmenu/SprTire.position.x = lerp($mainmenu/SprTire.position.x, -272.0, (0.2 * 60) * delta)
		$ColorRect2.modulate.a = lerp($ColorRect2.modulate.a, 1.0, (0.08 * 60) * delta)
		$AudioStreamPlayer.volume_db -= (0.6 * 60) * delta
		
#		if (Input.is_action_just_pressed("ui_cancel")):
#			menuGoBackSfx.play()
#			newGameAsk = false
#			cur_menu = 1

func menu3(delta):
	if (cur_menu == 3):
		if (continueGame):
			$ColorRect2.modulate.a = lerp($ColorRect2.modulate.a, 1.0, (0.4 * 60) * delta)
			$AudioStreamPlayer.volume_db -= (0.2 * 60) * delta
		if (Input.is_action_just_pressed("ui_select")):
			if ($SceneSwitchTimer.is_stopped()):
				$SceneSwitchTimer.start()
				goToIntroCutscene = false
				continueGame = true
				menuSelectSfx.play()

		if ($SceneSwitchTimer.is_stopped()):
			if (Input.is_action_just_pressed("ui_cancel")):
				cur_menu = 1
				menuGoBackSfx.play()
			
			if (Input.is_action_just_pressed("ui_down")):
				menuMoveSfx.play()
				if (curLevelOption != unlockedLevels):
					curLevelOption += 1
				else:
					curLevelOption = 1
				$SprLevelSelectBack.frame = curLevelOption-1
				$SprSelector.position.y = LEVEL_SELECT_POSITION[curLevelOption-1]
			if (Input.is_action_just_pressed("ui_up")):
				menuMoveSfx.play()
				if (curLevelOption != 1):
					curLevelOption -= 1
				else:
					curLevelOption = unlockedLevels
				$SprLevelSelectBack.frame = curLevelOption-1
				$SprSelector.position.y = LEVEL_SELECT_POSITION[curLevelOption-1]

			$SprLevelSelectBack.modulate.a = lerp($SprLevelSelectBack.modulate.a, 1.0, (0.3 * 60) * delta)
			$SprNiveles.position.x = lerp($SprNiveles.position.x, 0.0, (0.3 * 60) * delta)
			$SprSelector.position.x = lerp($SprSelector.position.x, 320.0, (0.3 * 60) * delta)
			#if (SaveDataManager.data["game_data"]["level2_unlocked"]):
				#if (!SaveDataManager.data["game_data"]["level3_unlocked"]):
					#$SprNiveles.frame = 1
				#else:
					#$SprNiveles.frame = 2
	else:
		$SprLevelSelectBack.modulate.a = lerp($SprLevelSelectBack.modulate.a, 0.0, (0.3 * 60) * delta)
		$SprNiveles.position.x = lerp($SprNiveles.position.x, -296.0, (0.6 * 60) * delta)
		$SprSelector.position.x = lerp($SprSelector.position.x, -40.0, (0.6 * 60) * delta)

func bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u = 1.0 - t
	var tt = t * t
	var uu = u * u
	var uuu = uu * u
	var ttt = tt * t

	var p = uuu * p0
	p += 3 * uu * t * p1
	p += 3 * u * tt * p2
	p += ttt * p2

	return p

func createText():
	var id = textNotifier.instantiate()
	id.position.x = 256
	id.position.y = 256
	add_child(id)

func dBToPercentage(dB: float) -> float:
	var percentage = pow(10, dB/10);
	return percentage

func db_to_percent(db: float) -> float:
	return 100 * pow(10, db / 20)

func logWithBase(value, base): 
	return log(value) / log(base)

#func percent_to_db(percent: float) -> float:
#	return 20 * log10(percent / 100)

func _input(event):
	if (event is InputEventKey) or (event is InputEventJoypadButton):
		if event.pressed and Input.is_action_pressed("pressEnter"):
			if cur_menu == 0 and ($Timer.is_stopped()):
				cur_menu = 1
				audioPlayer.play()
				animationPlayer.play("EnterMainMenu")


func _on_scene_switch_timer_timeout():
	if (goToIntroCutscene):
		get_tree().change_scene_to_file("res://stages/levelTutorial.tscn")
	if (continueGame):
		Conductor.resetEVERYTHINGGGGG()
		Conductor.songUnload()
		Conductor.songReset()
		Conductor.stop()
		match(curLevelOption):
			1:
				get_tree().change_scene_to_file("res://stages/level1.tscn")
			2:
				get_tree().change_scene_to_file("res://stages/level2.tscn")
			3:
				CutsceneHandler.playerContinued = true
				CutsceneHandler.lastCheckpoint = CutsceneHandler.bossCheckpointCoords
				Conductor.shouldLoop = true
				Conductor.resetEVERYTHINGGGGG()
				Conductor.songUnload()
				get_tree().change_scene_to_file("res://stages/level2.tscn")
			4:
				get_tree().change_scene_to_file("res://stages/level3.tscn")
			5:
				get_tree().change_scene_to_file("res://scenes/finalB_tstScn.tscn")
			6:
				get_tree().change_scene_to_file("res://stages/level4.tscn")
			


func _on_timer_timeout():
	$SprNiveles.visible = true
	$SprSelector.visible = true
