class_name FlowerVFX
extends Control

@export var sounds: Array[AudioStream] = []

@onready var particles: Array[GPUParticles2D] = [
	$Particles,
	$Particles2,
	$Particles3
]
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


func play() -> void:
	audio_stream_player.stream = sounds.pick_random()
	audio_stream_player.play()
	
	for particle: GPUParticles2D in particles:
		particle.amount = randi_range(10, 16)
		particle.restart()
		await get_tree().create_timer(randf_range(0.1, 0.2)).timeout
