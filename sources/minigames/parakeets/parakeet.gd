@tool
class_name Parakeet
extends Node2D

signal pressed()

enum Colors {
	Red,
	Green,
	Yellow,
}

const INSTANCE_SCENE: String = "res://sources/minigames/parakeets/parakeet.tscn"
const ANIMATIONS: Array[SpriteFrames] = [
	preload("res://sources/minigames/parakeets/red_parakeet_animations.tres"),
	preload("res://sources/minigames/parakeets/green_parakeet_animations.tres"),
	preload("res://sources/minigames/parakeets/yellow_parakeet_animation.tres")
]

@export var sad_duration: float = 2.0
@export var color: Colors = Colors.Red:
	set(value):
		color = value
		if animated_sprite:
			animated_sprite.sprite_frames = ANIMATIONS[color]
@export var uppercase: bool = true:
	set(value):
		uppercase = value
		if label:
			label.text = label.text.to_upper() if uppercase else label.text.to_lower()

var stimulus: Dictionary = {}:
	set(value):
		stimulus = value
		var grapheme: String = value.Grapheme as String
		label.text = grapheme.to_upper() if uppercase else grapheme

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label
@onready var right_FX: RightFX = $RightFX
@onready var wrong_FX: WrongFX = $WrongFX


static func instantiate() -> Parakeet:
	return (load(INSTANCE_SCENE) as PackedScene).instantiate()


func _ready() -> void:
	color = color
	animated_sprite.play("idle_front")


func _on_button_pressed() -> void:
	pressed.emit()


func turn_to_back() -> void:
	animated_sprite.play("turn_to_back")
	label.hide()
	await animated_sprite.animation_finished
	animated_sprite.play("back")


func turn_to_front() -> void:
	animated_sprite.play_backwards("turn_to_back")
	await animated_sprite.animation_finished
	label.show()
	animated_sprite.play("idle_front")


func _on_animated_sprite_2d_animation_looped() -> void:
	if animated_sprite.animation == "idle_front":
		if randi() % 4 == 0:
			animated_sprite.play("idle_front_blink")
	elif animated_sprite.animation == "idle_front_blink":
		animated_sprite.play("idle_front")


func fly_to(target: Vector2, duration: float) -> void:
	animated_sprite.play("fly")
	label.position.y = -195
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", target, duration)
	await tween.finished


func happy() -> void:
	animated_sprite.play("happy")


func idle() -> void:
	animated_sprite.play("idle_front")
	label.position.y = -166


func sad() -> void:
	animated_sprite.play("sad")
	await get_tree().create_timer(sad_duration).timeout


func right() -> void:
	right_FX.play()
	await right_FX.finished


func wrong() -> void:
	wrong_FX.play()
	await wrong_FX.finished
