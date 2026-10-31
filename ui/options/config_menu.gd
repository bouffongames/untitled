extends Control

@export var resource: ConfigResource
@export var control_rules: Array[ConfigMenuControlRule] = []

@export var reset_button: Button


func _ready() -> void:
	_load()

	if is_instance_valid(reset_button):
		reset_button.button_down.connect(
			func() -> void:
				resource.reset_to_default()
				resource.save()
				resource.apply()
				_load()
		)
	visibility_changed.connect(
		func() -> void:
			if is_visible_in_tree():
				_load()
	)


func _on_slider_control_value_changed(target: BaseControl, new_value: float) -> void:
	resource.set_value(target.key, new_value / 100.0)
	resource.apply()
	resource.save()
	_load()


func _on_value_spinner_control_value_changed(target: BaseControl, new_value: Variant) -> void:
	resource.set_value(target.key, new_value)
	resource.apply()
	resource.save()
	_load()


func _on_rebind_control_value_changed(_target: RebindControl, _new_value: Variant) -> void:
	for node: Node in get_children():
		var control: RebindControl = node as RebindControl
		if is_instance_valid(control):
			resource.set_value(control.key, control.value)
	resource.apply()
	resource.save()
	_load()


func _on_rebind_control_rebind_started(target: RebindControl) -> void:
	for node: Node in get_children():
		var control: RebindControl = node as RebindControl
		if is_instance_valid(control):
			if control != target:
				control.waiting_for_input = false


func _load() -> void:
	for node: Node in get_children():
		if node is ValueSpinnerControl:
			var control: ValueSpinnerControl = node as ValueSpinnerControl
			var prop: Variant = resource.get_value(control.key)
			if prop == null:
				continue
			control.value = prop
			if not control.value_changed.is_connected(_on_value_spinner_control_value_changed):
				control.value_changed.connect(_on_value_spinner_control_value_changed)
		elif node is SliderControl:
			var control: SliderControl = node as SliderControl
			var prop: Variant = resource.get_value(control.key)
			if prop == null:
				continue
			control.value = prop * 100
			if not control.value_changed.is_connected(_on_slider_control_value_changed):
				control.value_changed.connect(_on_slider_control_value_changed)
		elif node is RebindControl:
			var control: RebindControl = node as RebindControl
			var prop: Variant = resource.get_value(control.key)
			control.value = prop
			if not control.value_changed.is_connected(_on_rebind_control_value_changed):
				control.value_changed.connect(_on_rebind_control_value_changed)
			if not control.rebind_started.is_connected(_on_rebind_control_rebind_started):
				control.rebind_started.connect(_on_rebind_control_rebind_started)

	_apply_control_rules()


func _apply_control_rules() -> void:
	for rule: ConfigMenuControlRule in control_rules:
		if not is_instance_valid(rule):
			continue

		var source_value: Variant = resource.get_value(rule.source_key)
		var is_match: bool = rule.expected_values.has(source_value)
		var target_control: BaseControl = _find_control_rule_by_key(rule.target_key)

		if not is_instance_valid(target_control):
			continue

		target_control.disabled = is_match if rule.disable_when_matched else not is_match


func _find_control_rule_by_key(key: String) -> BaseControl:
	for node: Node in get_children():
		var control: BaseControl = node as BaseControl
		if is_instance_valid(control) and control.key == key:
			return control

	return null
