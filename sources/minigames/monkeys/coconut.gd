extends Node2D

@onready var highlight_fx: HighlightFX = $HighlightFX
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: DynamicFontSizeLabel = $Sprite2D/DynamicFontSizeLabel
@onready var broken_coconut_fx: BrokenCoconutFX = $BrokenCoconutFX

var text: String :
	set(value):
		text = value
		if label:
			label.text = text
			label._update_font_size()


func highlight() -> void:
	highlight_fx.play()


func explode() -> void:
	highlight_fx.stop()
	sprite.hide()
	label.hide()
	
	await broken_coconut_fx.play()
	
	queue_free()
