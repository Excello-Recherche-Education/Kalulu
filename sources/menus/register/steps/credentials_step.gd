extends Step

@onready var api_email_field_error: Label = %APIEmailFieldError

func _on_validate_button_pressed():
	api_email_field_error.visible = false
	
	# Validate the fields
	if not form_validator.validate():
		push_warning("Validation failed (" + str(self) + ")")
		return
	
	# Writes data in object
	if not form_binder.write():
		push_warning("Impossible to write data in object (" + str(self) + ")")
		return
	
	var res = await ServerManager.check_email(data.email)
	if res.code != 200:
		api_email_field_error.visible = true
		return
	
	if _on_next():
		next.emit(self)