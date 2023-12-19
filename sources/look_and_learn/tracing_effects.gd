extends Node2D

@onready var particles_effect: = $TracingParticles
@onready var sound_effect: = $TracingAudioStreamPlayer
@onready var timer: = $Timer


func _ready() -> void:
	particles_effect.emitting = false
	sound_effect.playing = false


func play() -> void:
	if not sound_effect.playing:
		sound_effect.playing = true
	
	if not particles_effect.emitting:
		particles_effect.emitting = true
	
	if not timer.is_stopped():
		timer.stop()


func set_pitch_scale(pitch_scale: float) -> void:
	sound_effect.pitch_scale = pitch_scale


func stop() -> void:
	if (particles_effect.emitting or sound_effect.playing) and timer.is_stopped():
		timer.start()


func _on_Timer_timeout() -> void:
	particles_effect.emitting = false
	sound_effect.playing = false