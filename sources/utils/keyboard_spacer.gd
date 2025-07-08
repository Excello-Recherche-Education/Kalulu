class_name KeyboardSpacer
extends MarginContainer

var screen_scale: float
var last_margin: int = -1


func _ready() -> void:
	screen_scale = DisplayServer.screen_get_scale()
	set_process(OS.has_feature("mobile"))


func _process(_delta: float) -> void:
	if OS.has_feature("mobile"):
		var margin: int = DisplayServer.virtual_keyboard_get_height()
		if OS.get_name() == "Android":
			margin = int(margin * screen_scale)
		add_theme_constant_override("margin_bottom", maxi(floori(margin), 0))