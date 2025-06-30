extends MarginContainer
class_name KeyboardSpacer

var screen_scale: float

func _ready() -> void:
	screen_scale = DisplayServer.screen_get_scale()


func _process(_delta: float) -> void:
	if OS.has_feature("mobile"):
		var margin: int = DisplayServer.virtual_keyboard_get_height()
		if OS.get_name() == "Android":
			margin = int(margin * screen_scale)
		self["theme_override_constants/margin_bottom"] = maxi(floori(margin), 0)
