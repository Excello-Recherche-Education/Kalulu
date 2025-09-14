class_name SpitVFX
extends Control

@onready var particles: GPUParticles2D = $Particles


func play() -> void:
	particles.amount = randi_range(5, 8)
	particles.restart()
