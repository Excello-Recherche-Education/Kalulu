class_name Water
extends TextureRect

const WATER_RING_SCENE: PackedScene = preload("res://sources/utils/fx/water_ring.tscn")

@export var ring_color: Color


func spawn_water_ring(pos: Vector2) -> void:
	var water_ring_effect: WaterRingFX = WATER_RING_SCENE.instantiate()
	water_ring_effect.position = pos
	water_ring_effect.modulate = ring_color
	add_child(water_ring_effect)
	await water_ring_effect.play()
	water_ring_effect.queue_free()
