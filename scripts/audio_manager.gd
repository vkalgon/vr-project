# res://scripts/audio_manager.gd
# Менеджер звуков для игры
extends Node

# Звуки UI
var ui_click: AudioStream = preload("res://assets/400 Sounds Pack/UI/click_double_on.wav")
var ui_select: AudioStream = preload("res://assets/400 Sounds Pack/UI/select_1.wav")
var ui_hover: AudioStream = preload("res://assets/400 Sounds Pack/UI/sci_fi_hover.wav")
var ui_cancel: AudioStream = preload("res://assets/400 Sounds Pack/UI/cancel.wav")
var ui_confirm: AudioStream = preload("res://assets/400 Sounds Pack/UI/sci_fi_confirm.wav")

# Звуки подбора предметов
var pickup_sound: AudioStream = preload("res://assets/400 Sounds Pack/Retro/coin.wav")
var pickup_sounds: Array[AudioStream] = [
	preload("res://assets/400 Sounds Pack/Retro/coin.wav"),
	preload("res://assets/400 Sounds Pack/Retro/coin_2.wav"),
	preload("res://assets/400 Sounds Pack/Retro/coin_3.wav"),
	preload("res://assets/400 Sounds Pack/Retro/coin_4.wav"),
	preload("res://assets/400 Sounds Pack/Items/coin_collect.wav"),
	preload("res://assets/400 Sounds Pack/Items/gem_collect.wav")
]

# Звуки крафта
var craft_success: AudioStream = preload("res://assets/400 Sounds Pack/Musical Effects/xylophone_chime_positive.wav")
var craft_fail: AudioStream = preload("res://assets/400 Sounds Pack/UI/synth_error.wav")
var craft_work: AudioStream = preload("res://assets/400 Sounds Pack/Materials/wood_small_gather.wav")

# Звуки шагов
var footstep_sounds: Array[AudioStream] = [
	preload("res://assets/400 Sounds Pack/Footsteps/digital/digital_footstep_grass_1.wav"),
	preload("res://assets/400 Sounds Pack/Footsteps/digital/digital_footstep_grass_2.wav"),
	preload("res://assets/400 Sounds Pack/Footsteps/digital/digital_footstep_grass_3.wav"),
	preload("res://assets/400 Sounds Pack/Footsteps/digital/digital_footstep_grass_4.wav")
]

# Фоновая музыка
var background_music: AudioStream = preload("res://assets/soundtrack.wav")

# Громкость
@export var master_volume: float = 1.0
@export var ui_volume: float = 0.8
@export var sfx_volume: float = 1.0
@export var music_volume: float = 0.6

# AudioStreamPlayer для разных типов звуков
var ui_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []  # Для множественных звуков
var footstep_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

func _ready():
	# Создаем AudioStreamPlayer для UI
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	add_child(ui_player)
	
	# Создаем AudioStreamPlayer для SFX
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	add_child(sfx_player)
	
	# Создаем дополнительные игроки для множественных звуков
	for i in range(5):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_" + str(i)
		add_child(player)
		sfx_players.append(player)
	
	# Создаем AudioStreamPlayer для шагов
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepPlayer"
	add_child(footstep_player)
	
	# Создаем AudioStreamPlayer для фоновой музыки
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.stream = background_music
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	music_player.autoplay = false
	add_child(music_player)

func play_ui_click():
	if ui_player:
		ui_player.stream = ui_click
		ui_player.volume_db = linear_to_db(ui_volume * master_volume)
		ui_player.play()

func play_ui_select():
	if ui_player:
		ui_player.stream = ui_select
		ui_player.volume_db = linear_to_db(ui_volume * master_volume)
		ui_player.play()

func play_ui_hover():
	if ui_player:
		ui_player.stream = ui_hover
		ui_player.volume_db = linear_to_db(ui_volume * master_volume * 0.6)  # Тише для hover
		ui_player.play()

func play_ui_cancel():
	if ui_player:
		ui_player.stream = ui_cancel
		ui_player.volume_db = linear_to_db(ui_volume * master_volume)
		ui_player.play()

func play_ui_confirm():
	if ui_player:
		ui_player.stream = ui_confirm
		ui_player.volume_db = linear_to_db(ui_volume * master_volume)
		ui_player.play()

func play_pickup():
	# Играем случайный звук подбора
	var sound = pickup_sounds[randi() % pickup_sounds.size()]
	play_sfx(sound)

func play_craft_success():
	play_sfx(craft_success)

func play_craft_fail():
	play_sfx(craft_fail)

func play_craft_work():
	play_sfx(craft_work)

func play_sfx(stream: AudioStream, volume_multiplier: float = 1.0):
	# Ищем свободный игрок или используем основной
	var player: AudioStreamPlayer = null
	for p in sfx_players:
		if not p.playing:
			player = p
			break
	
	if player == null:
		player = sfx_player
	
	if player:
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume * master_volume * volume_multiplier)
		player.play()

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)

func set_ui_volume(volume: float):
	ui_volume = clamp(volume, 0.0, 1.0)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)

func play_footstep():
	# Играем случайный звук шага
	if footstep_player and not footstep_player.playing:
		var sound = footstep_sounds[randi() % footstep_sounds.size()]
		footstep_player.stream = sound
		footstep_player.volume_db = linear_to_db(sfx_volume * master_volume * 0.5)  # Шаги тише
		footstep_player.play()

func play_background_music():
	# Запускаем фоновую музыку с зацикливанием
	if music_player and background_music:
		# Останавливаем музыку, если она уже играет
		if music_player.playing:
			music_player.stop()
		
		music_player.stream = background_music
		# Устанавливаем зацикливание для AudioStream
		if background_music is AudioStreamWAV:
			var wav_stream = background_music as AudioStreamWAV
			wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif background_music is AudioStreamOggVorbis:
			var ogg_stream = background_music as AudioStreamOggVorbis
			ogg_stream.loop = true
		music_player.volume_db = linear_to_db(music_volume * master_volume)
		# Запускаем с начала
		music_player.play()

func stop_background_music():
	if music_player:
		music_player.stop()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)

