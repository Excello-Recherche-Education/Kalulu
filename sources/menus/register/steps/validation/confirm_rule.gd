@tool
extends ValidatorRule
class_name ConfirmRule

@export_node_path("Control") var confirm_control_path

func _init() -> void:
	fail_message = "Value must be the same in both fields."


func apply(control: Control, value) -> RuleResult:
	var result = RuleResult.new()
	if confirm_control_path && value is String:
		var confirm_control = control.get_child(0).get_node(confirm_control_path)
		result.passed = confirm_control && Validation.find_validator(control).get_value(confirm_control) == value
	if not result.passed:
		result.message = fail_message
	return result